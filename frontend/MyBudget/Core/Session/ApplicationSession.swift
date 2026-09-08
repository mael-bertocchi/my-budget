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
    private var isDemo = false

    init(store: LocalStore, rates: ExchangeRates, tokens: TokenStore, api: APIClient) {
        self.store = store
        self.rates = rates
        self.tokens = tokens
        self.api = api
        self.username = UserDefaults.standard.string(forKey: Keys.username)
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
        await initialSync()
        repriceRecentOperations()
    }

    func signIn(username: String, password: String) async throws {
        let me = try await api.login(username: username, password: password)

        self.username = me.username
        UserDefaults.standard.set(me.username, forKey: Keys.username)

        identityState = .signedIn
        wireLocalChanges()
        refreshRates()
        await initialSync()
        repriceRecentOperations()
    }

    func signOut() async {
        pushTask?.cancel()
        store.onChange = nil
        await api.logout()
        tokens.clear()
        username = nil
        syncState = .idle
        lastSyncedAt = nil
        identityState = .signedOut
    }

    func syncNow() async {
        guard identityState == .signedIn, !isDemo else { return }
        await push()
    }

    func applicationBecameActive() {
        guard identityState == .signedIn, !isDemo else { return }
        refreshRates()
        repriceRecentOperations()
        schedulePush()
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

    private func initialSync() async {
        syncState = .syncing
        do {
            let remote = try await api.getState()
            if !remote.isEmpty {
                store.applyRemote(remote)
            } else if !store.document().isEmpty {
                try await api.putState(store.document())
            }
            syncState = .idle
            lastSyncedAt = .now
        } catch let error as APIError {
            handle(error)
        } catch {
            syncState = .error(error.localizedDescription)
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
        syncState = .syncing
        do {
            try await api.putState(store.document())
            syncState = .idle
            lastSyncedAt = .now
        } catch let error as APIError {
            handle(error)
        } catch {
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

    private enum Keys {
        static let username = "session.username"
    }

    static let serverURL = "https://my-budget.mael-bertocchi.fr"
}
