import Foundation

enum TastyAPIError: LocalizedError {
    case invalidResponse
    case server(status: Int, message: String)
    case decoding

    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            "服务器返回了无法识别的响应。"
        case let .server(status, message):
            "服务器错误 \(status)：\(message)"
        case .decoding:
            "服务器数据格式不正确。"
        }
    }

    var isUnauthorized: Bool {
        if case let .server(status, _) = self {
            return status == 401
        }
        return false
    }
}

struct TastyAPIClient: Sendable {
    let baseURL: URL
    private let session: URLSession

    init(baseURL: URL = AppConfig.apiBaseURL, session: URLSession = .shared) {
        self.baseURL = baseURL
        self.session = session
    }

    func login(email: String, password: String) async throws -> AuthResponse {
        let body = try JSONEncoder().encode(
            LoginRequest(identity: email, password: password)
        )
        return try await perform(
            path: "api/collections/users/auth-with-password",
            method: "POST",
            body: body
        )
    }

    func refresh(token: String) async throws -> AuthResponse {
        try await perform(
            path: "api/collections/users/auth-refresh",
            method: "POST",
            token: token
        )
    }

    func fetchAllPlaces(token: String) async throws -> [RemotePlace] {
        var page = 1
        var places: [RemotePlace] = []

        while true {
            var components = URLComponents(
                url: endpoint("api/collections/places/records"),
                resolvingAgainstBaseURL: false
            )
            components?.queryItems = [
                URLQueryItem(name: "page", value: String(page)),
                URLQueryItem(name: "perPage", value: "200"),
                URLQueryItem(name: "sort", value: "updated"),
            ]

            guard let url = components?.url else {
                throw TastyAPIError.invalidResponse
            }

            let response: PlaceListResponse = try await perform(
                url: url,
                method: "GET",
                token: token
            )
            places.append(contentsOf: response.items)

            if page >= response.totalPages || response.items.isEmpty {
                break
            }
            page += 1
        }

        return places
    }

    func createPlace(_ mutation: PlaceMutation, token: String) async throws -> RemotePlace {
        let body = try JSONEncoder().encode(mutation)
        return try await perform(
            path: "api/collections/places/records",
            method: "POST",
            token: token,
            body: body
        )
    }

    func updatePlace(
        remoteID: String,
        mutation: PlaceMutation,
        token: String
    ) async throws -> RemotePlace {
        let body = try JSONEncoder().encode(mutation)
        return try await perform(
            path: "api/collections/places/records/\(remoteID)",
            method: "PATCH",
            token: token,
            body: body
        )
    }

    private func endpoint(_ path: String) -> URL {
        path
            .split(separator: "/")
            .reduce(baseURL) { partial, component in
                partial.appendingPathComponent(String(component))
            }
    }

    private func perform<Response: Decodable>(
        path: String,
        method: String,
        token: String? = nil,
        body: Data? = nil
    ) async throws -> Response {
        try await perform(
            url: endpoint(path),
            method: method,
            token: token,
            body: body
        )
    }

    private func perform<Response: Decodable>(
        url: URL,
        method: String,
        token: String? = nil,
        body: Data? = nil
    ) async throws -> Response {
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.timeoutInterval = 30
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        if let token {
            request.setValue(token, forHTTPHeaderField: "Authorization")
        }
        if let body {
            request.httpBody = body
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }

        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw TastyAPIError.invalidResponse
        }

        guard (200..<300).contains(httpResponse.statusCode) else {
            let envelope = try? JSONDecoder().decode(
                PocketBaseErrorEnvelope.self,
                from: data
            )
            throw TastyAPIError.server(
                status: httpResponse.statusCode,
                message: envelope?.message ?? "请求失败"
            )
        }

        do {
            return try JSONDecoder().decode(Response.self, from: data)
        } catch {
            throw TastyAPIError.decoding
        }
    }
}
