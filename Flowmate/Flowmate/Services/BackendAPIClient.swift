import Foundation

struct BackendAPIClient {
    static let shared = BackendAPIClient()
    private let jsonDecoder = JSONDecoder()
    private let jsonEncoder = JSONEncoder()
    private var baseURL: URL { URL(string: Config.Environment.current.baseURL)!.appendingPathComponent("v1") }

    private func authToken() -> String? {
        // AuthenticationService saves access token in UserDefaults under this key
        return UserDefaults.standard.string(forKey: "auth_access_token")
    }

    private func authorizedRequest(path: String, method: String = "GET", body: Data? = nil) throws -> URLRequest {
        let url = baseURL.appendingPathComponent(path)
        var req = URLRequest(url: url)
        req.httpMethod = method
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        guard let token = authToken(), !token.isEmpty else {
            throw URLError(.userAuthenticationRequired)
        }
        req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        req.httpBody = body
        return req
    }

    // MARK: - Preferences
    // Update preferences JSONB bucket. You can pass any partial preferences object.
    func updatePreferences(_ preferences: [String: Any]) async throws -> [String: Any] {
        let data = try JSONSerialization.data(withJSONObject: preferences, options: [])
        var req = try authorizedRequest(path: "preferences", method: "PUT", body: data)
        let (respData, resp) = try await URLSession.shared.data(for: req)
        guard let http = resp as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw URLError(.badServerResponse)
        }
        return (try JSONSerialization.jsonObject(with: respData) as? [String: Any]) ?? [:]
    }

    // Helper: update motivations only (array form)
    func updateMotivations(_ motivations: [String]) async throws {
        _ = try await updatePreferences(["motivation": motivations])
    }

    // Helper: update motivation weights (map form)
    func updateMotivationWeights(_ weights: [String: Double]) async throws {
        _ = try await updatePreferences(["motivation": weights])
    }

    // MARK: - Debug
    struct PersonalizationContextResponse: Decodable { let context: String }

    func getPersonalizationContext() async throws -> String {
        let req = try authorizedRequest(path: "personalization-context")
        let (data, resp) = try await URLSession.shared.data(for: req)
        guard let http = resp as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw URLError(.badServerResponse)
        }
        let res = try jsonDecoder.decode(PersonalizationContextResponse.self, from: data)
        return res.context
    }
}
