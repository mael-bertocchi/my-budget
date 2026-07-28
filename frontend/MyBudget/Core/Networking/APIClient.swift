import Foundation

struct IdentityTokens: Codable {
    var accessToken: String
    var refreshToken: String
}

struct MeResponse: Codable {
    var id: String
    var username: String
}

enum APIError: Error, LocalizedError {
    case notConfigured
    case unauthorized
    case server(status: Int, message: String)
    case transport(Error)
    case decoding(Error)

    var errorDescription: String? {
        switch self {
        case .notConfigured: return "No server is configured."
        case .unauthorized: return "Your session has expired."
        case .server(_, let message): return message
        case .transport: return "Can't reach the server."
        case .decoding: return "The server sent an unexpected response."
        }
    }

    var isOffline: Bool {
        if case .transport = self { return true }
        return false
    }
}

@MainActor
final class APIClient {
    private(set) var baseURL: URL?
    private let tokens: TokenStore
    private let session: URLSession
    private var refreshTask: Task<Void, Error>?

    init(tokens: TokenStore, baseURL: URL? = nil) {
        self.tokens = tokens
        self.baseURL = baseURL
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 20
        configuration.waitsForConnectivity = false
        self.session = URLSession(configuration: configuration)
    }

    func setBaseURL(_ url: URL?) {
        baseURL = url
    }

    private struct Envelope<T: Decodable>: Decodable {
        let data: T
    }

    private struct ErrorEnvelope: Decodable {
        let message: String
    }

    func login(username: String, password: String) async throws -> MeResponse {
        let tokens: IdentityTokens = try await send(
            "/v1/identity/login",
            method: "POST",
            body: ["username": username, "password": password],
            authorized: false
        )
        self.tokens.store(access: tokens.accessToken, refresh: tokens.refreshToken)
        return try await fetchMe()
    }

    func fetchMe() async throws -> MeResponse {
        try await send("/v1/identity/me", method: "GET")
    }

    func logout() async {
        guard let refreshToken = tokens.refreshToken else { return }
        let _: EmptyResponse? = try? await send(
            "/v1/identity/logout",
            method: "POST",
            body: ["refreshToken": refreshToken]
        )
    }

    func getState() async throws -> BudgetDocument {
        try await send("/v1/state", method: "GET")
    }

    @discardableResult
    func putState(_ document: BudgetDocument) async throws -> BudgetDocument {
        try await send("/v1/state", method: "PUT", body: document)
    }

    private struct EmptyResponse: Decodable {}

    private func send<Response: Decodable>(
        _ path: String,
        method: String,
        body: Encodable? = nil,
        authorized: Bool = true
    ) async throws -> Response {
        do {
            return try await perform(path, method: method, body: body, authorized: authorized)
        } catch APIError.unauthorized where authorized {
            try await refreshTokens()
            return try await perform(path, method: method, body: body, authorized: true)
        }
    }

    private func perform<Response: Decodable>(
        _ path: String,
        method: String,
        body: Encodable?,
        authorized: Bool
    ) async throws -> Response {
        guard let baseURL else { throw APIError.notConfigured }

        var request = URLRequest(url: baseURL.appending(path: path))
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        if let body {
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = try JSONCoding.encoder.encode(AnyEncodable(body))
        }

        if authorized, let accessToken = tokens.accessToken {
            request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        }

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(for: request)
        } catch {
            throw APIError.transport(error)
        }

        guard let http = response as? HTTPURLResponse else {
            throw APIError.server(status: 0, message: "Invalid response")
        }

        if http.statusCode == 401 {
            throw APIError.unauthorized
        }

        guard (200..<300).contains(http.statusCode) else {
            let message = (try? JSONCoding.decoder.decode(ErrorEnvelope.self, from: data))?.message ?? "Request failed"
            throw APIError.server(status: http.statusCode, message: message)
        }

        do {
            return try JSONCoding.decoder.decode(Envelope<Response>.self, from: data).data
        } catch {
            throw APIError.decoding(error)
        }
    }

    private func refreshTokens() async throws {
        if let refreshTask {
            try await refreshTask.value
            return
        }
        let task = Task<Void, Error> {
            defer { refreshTask = nil }
            guard let refreshToken = tokens.refreshToken else { throw APIError.unauthorized }
            do {
                let pair: IdentityTokens = try await perform(
                    "/v1/identity/refresh",
                    method: "POST",
                    body: ["refreshToken": refreshToken],
                    authorized: false
                )
                tokens.store(access: pair.accessToken, refresh: pair.refreshToken)
            } catch APIError.server, APIError.unauthorized {
                tokens.clear()
                throw APIError.unauthorized
            }
        }
        refreshTask = task
        try await task.value
    }
}

private struct AnyEncodable: Encodable {
    private let encode: (Encoder) throws -> Void

    init(_ wrapped: Encodable) {
        encode = wrapped.encode
    }

    func encode(to encoder: Encoder) throws {
        try encode(encoder)
    }
}
