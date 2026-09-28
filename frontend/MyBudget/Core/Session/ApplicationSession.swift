import Foundation
import Observation

@MainActor
@Observable
final class ApplicationSession {
    enum IdentityState {
        case loading
        case signedOut
        case signedIn
    }

    enum SyncState: Equatable {
        case idle
        case syncing
        case offline
        case error(String)
    }

    private(set) var identityState: IdentityState = .loading
    private(set) var username: String?
    private(set) var syncState: SyncState = .idle
    private(set) var lastSyncedAt: Date?

    let serverURLString = ApplicationSession.serverURL

    private let store: LocalStore
    private let rates: ExchangeRates
    private let tokens: TokenStore
    private let api: APIClient

    private var pushTask: Task<Void, Never>?
    private var syncTask: Task<Void, Never>?
    private var base: SyncBase?
    private var isDemo = false

    init(store: LocalStore, rates: ExchangeRates, tokens: TokenStore, api: APIClient) {
        self.store = store
        self.rates = rates
        self.tokens = tokens
        self.api = api
        self.username = UserDefaults.standard.string(forKey: Keys.username)
        self.base = SyncBase.load()
        api.setBaseURL(URL(string: serverURLString))
    }

    func bootstrap() async {
        guard tokens.hasTokens else {
            identityState = .signedOut
            return
        }
        identityState = .signedIn
        wireLocalChanges()
        refreshRates()
        await reconcile()
        repriceRecentOperations()
    }

    func signIn(username: String, password: String) async throws {
        let me = try await api.login(username: username, password: password)

        self.username = me.username
        UserDefaults.standard.set(me.username, forKey: Keys.username)

        identityState = .signedIn
        wireLocalChanges()
        refreshRates()
        await reconcile()
        repriceRecentOperations()
    }

    func signOut() async {
        pushTask?.cancel()
        store.onChange = nil
        await api.logout()
        tokens.clear()
        base = nil
        SyncBase.clear()
        username = nil
        syncState = .idle
        lastSyncedAt = nil
        identityState = .signedOut
    }

    func syncNow() async {
        guard identityState == .signedIn, !isDemo else { return }
        await push()
    }

    /// Picks up what was written elsewhere while the app sat in the background — in the web interface, say —
    /// before anything is pushed, so coming back to the app never erases it.
    func applicationBecameActive() {
        guard identityState == .signedIn, !isDemo else { return }
        refreshRates()

        Task {
            await reconcile()
            repriceRecentOperations()
        }
    }

    #if DEBUG
    func enterDemo() {
        isDemo = true
        username = UserDefaults.standard.string(forKey: Keys.username) ?? "Demo"
        identityState = .signedIn
    }
    #endif

    /// Re-prices recent operations at the rate published for their own date. An operation entered before the
    /// ECB publishes — around 16:00 CET — is stored at the previous day's rate, because at that moment no
    /// rate for its own day exists yet. This corrects it once that day is out.
    ///
    /// A day with no rate of its own resolves to the last one published before it, so a Saturday purchase
    /// settles on Friday's rate and stays there. The sweep is idempotent either way: once an operation matches
    /// what its day resolves to, later passes find nothing to do.
    private func repriceRecentOperations() {
        guard !isDemo else { return }

        Task { [store, rates] in
            guard let horizon = Calendar.current.date(byAdding: .day, value: -Self.repriceWindowDays, to: .now) else { return }

            let candidates = store.operations.filter { $0.date >= horizon && $0.currencyCode != Currency.euro.code }

            guard !candidates.isEmpty else { return }

            for day in Set(candidates.map { ExchangeRates.day(from: $0.date) }) {
                await rates.load(day: day)
            }

            var corrected: [String: Double] = [:]

            for operation in candidates {
                let day = ExchangeRates.day(from: operation.date)

                guard let published = rates.rate(code: operation.currencyCode, on: day),
                      abs(published - operation.rateToEuro) > Self.rateEpsilon else { continue }

                corrected[operation.id] = published
            }

            store.reprice(corrected)
        }
    }

    /// Tops up the exchange rates in the background. It never blocks a sync: a stale rate still
    /// renders, and `ExchangeRates` keeps the last known values when the server can't be reached.
    private func refreshRates() {
        guard !isDemo else { return }

        Task { [rates] in
            await rates.refreshIfNeeded()
        }
    }

    private func wireLocalChanges() {
        store.onChange = { [weak self] in
            self?.schedulePush()
        }
    }

    private func schedulePush() {
        pushTask?.cancel()
        pushTask = Task { [weak self] in
            try? await Task.sleep(for: .seconds(0.8))
            guard !Task.isCancelled else { return }
            await self?.push()
        }
    }

    private func push() async {
        guard !isDemo else { return }
        await enqueueSync { [weak self] in await self?.performPush() }
    }

    private func reconcile() async {
        guard !isDemo else { return }
        await enqueueSync { [weak self] in await self?.performReconcile() }
    }

    /// Runs sync passes one after the other. A push and a reconcile interleaving at their awaits would each work
    /// from a base the other is about to replace.
    private func enqueueSync(_ work: @escaping @MainActor () async -> Void) async {
        let previous = syncTask
        let task = Task { @MainActor in
            await previous?.value
            await work()
        }
        syncTask = task
        await task.value
    }

    /// Sends the local document on top of the revision it was edited from. The server refuses it if someone else
    /// wrote in the meantime, and the push turns into a reconcile.
    private func performPush() async {
        guard let base else {
            await performReconcile()
            return
        }

        let document = store.document()

        guard !DocumentMerge.sameContent(document, base.document) else {
            markSynced()
            return
        }

        syncState = .syncing
        do {
            let stored = try await api.putState(document, revision: base.revision)
            commit(document, revision: stored.revision)
        } catch APIError.conflict {
            await performReconcile()
        } catch {
            fail(error)
        }
    }

    /// Pulls the server's document, merges it with the local one against the last agreed base, applies the result
    /// and sends it back if it holds anything the server lacks. Once merged in, the pulled document is the new base:
    /// the device now holds everything in it. Another writer landing between the pull and the push makes the server
    /// refuse it, and the pass starts over from a fresh pull.
    private func performReconcile() async {
        syncState = .syncing
        do {
            for _ in 0..<Self.reconcileAttempts {
                let remote = try await api.getState()
                let merged = resolve(remote)

                if !DocumentMerge.sameContent(merged, store.document()) {
                    store.applyRemote(merged)
                }

                adopt(remote.document, revision: remote.revision)

                let result = store.document()

                if DocumentMerge.sameContent(result, remote.document) {
                    markSynced()
                    return
                }

                do {
                    let stored = try await api.putState(result, revision: remote.revision)
                    commit(result, revision: stored.revision)
                    return
                } catch APIError.conflict {
                    continue
                }
            }
            syncState = .error(APIError.conflict.localizedDescription)
        } catch {
            fail(error)
        }
    }

    /// What the device should hold once it has seen the server's document. Without a base to measure edits against
    /// — a first sign-in, or a server whose revision went backwards because it was reset — the server wins unless
    /// it is empty, in which case the device's budget seeds it.
    private func resolve(_ remote: RemoteState) -> BudgetDocument {
        let local = store.document()

        guard let base, remote.revision >= base.revision else {
            return remote.document.isEmpty && !local.isEmpty ? local : remote.document
        }

        return DocumentMerge.merge(base: base.document, local: local, remote: remote.document)
    }

    private func commit(_ document: BudgetDocument, revision: Int) {
        adopt(document, revision: revision)
        markSynced()
    }

    private func adopt(_ document: BudgetDocument, revision: Int) {
        let synced = SyncBase(document: document, revision: revision)
        base = synced
        synced.save()
    }

    private func markSynced() {
        syncState = .idle
        lastSyncedAt = .now
    }

    private func fail(_ error: Error) {
        if let error = error as? APIError {
            handle(error)
        } else {
            syncState = .error(error.localizedDescription)
        }
    }

    private func handle(_ error: APIError) {
        switch error {
        case .unauthorized:
            Task { await signOut() }
        case .transport:
            syncState = .offline
        default:
            syncState = .error(error.localizedDescription)
        }
    }

    /// How far back the re-pricing sweep looks. Only recent operations can still be waiting on a publication.
    private static let repriceWindowDays = 7

    /// The smallest rate difference worth rewriting an operation for.
    private static let rateEpsilon = 1e-9

    /// How many pull-merge-push rounds a reconcile tries before giving up on a server that keeps changing under it.
    private static let reconcileAttempts = 3

    private enum Keys {
        static let username = "session.username"
    }

    static let serverURL = "https://my-budget.mael-bertocchi.fr"
}
