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

    // MARK: - Generic authorized requests
    func get(path: String) async throws -> (Data, HTTPURLResponse) {
        var req = try authorizedRequest(path: path, method: "GET", body: nil)
        var (data, resp) = try await URLSession.shared.data(for: req)
        if let http = resp as? HTTPURLResponse, http.statusCode == 401, let _ = try await refreshAuthTokenIfPossible() {
            // retry once with fresh token
            req = try authorizedRequest(path: path, method: "GET", body: nil)
            (data, resp) = try await URLSession.shared.data(for: req)
        }
        guard let http = resp as? HTTPURLResponse else { throw URLError(.badServerResponse) }
        return (data, http)
    }

    func sendJSON(path: String, method: String = "POST", json: [String: Any]) async throws -> (Data, HTTPURLResponse) {
        let body = try JSONSerialization.data(withJSONObject: json, options: [])
        var req = try authorizedRequest(path: path, method: method, body: body)
        var (data, resp) = try await URLSession.shared.data(for: req)
        if let http = resp as? HTTPURLResponse, http.statusCode == 401, let _ = try await refreshAuthTokenIfPossible() {
            // retry once with fresh token
            req = try authorizedRequest(path: path, method: method, body: body)
            (data, resp) = try await URLSession.shared.data(for: req)
        }
        guard let http = resp as? HTTPURLResponse else { throw URLError(.badServerResponse) }
        return (data, http)
    }

    // Attempt to refresh token via Supabase refresh token stored in UserDefaults. Returns new token if refreshed.
    private func refreshAuthTokenIfPossible() async throws -> String? {
        guard let refresh = UserDefaults.standard.string(forKey: "auth_refresh_token"), !refresh.isEmpty else {
            return nil
        }
        do {
            let session = try await DatabaseService.shared.authRefresh(refreshToken: refresh)
            if let token = session.access_token {
                UserDefaults.standard.set(token, forKey: "auth_access_token")
                DatabaseService.shared.setAuthToken(token)
            }
            if let newRefresh = session.refresh_token {
                UserDefaults.standard.set(newRefresh, forKey: "auth_refresh_token")
            }
            return session.access_token
        } catch {
            return nil
        }
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

    // Helper: update motivation triggers only (schema-compliant)
    // Backend expects an object for motivation, not an array.
    // Shape: { "motivation": { "motivation_triggers": ["morning_boost", ...] } }
    func updateMotivationTriggers(_ triggers: [String]) async throws {
        _ = try await updatePreferences(["motivation": ["motivation_triggers": triggers]])
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
