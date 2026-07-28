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
    private let tokens: TokenStore
    private let api: APIClient

    private var pushTask: Task<Void, Never>?
    private var isDemo = false

    init(store: LocalStore, tokens: TokenStore, api: APIClient) {
        self.store = store
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
        await initialSync()
    }

    func signIn(username: String, password: String) async throws {
        let me = try await api.login(username: username, password: password)

        self.username = me.username
        UserDefaults.standard.set(me.username, forKey: Keys.username)

        identityState = .signedIn
        wireLocalChanges()
        await initialSync()
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
        schedulePush()
    }

    #if DEBUG
    func enterDemo() {
        isDemo = true
        username = UserDefaults.standard.string(forKey: Keys.username) ?? "Demo"
        identityState = .signedIn
    }
    #endif

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

    private enum Keys {
        static let username = "session.username"
    }

    static let serverURL = "https://my-budget.mael-bertocchi.fr"
}
