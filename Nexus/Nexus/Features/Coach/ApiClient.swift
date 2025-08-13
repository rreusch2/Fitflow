import Foundation

struct CoachAPIClient {
    static let shared = CoachAPIClient()
    private let jsonDecoder = JSONDecoder()
    private let jsonEncoder = JSONEncoder()
    private var baseURL: URL { URL(string: Config.Environment.current.baseURL)!.appendingPathComponent("v1/public") }

    // MARK: - Chat
    func chat(message: String) async throws -> String {
        let url = baseURL.appendingPathComponent("chat")
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let body = ["message": message]
        req.httpBody = try jsonEncoder.encode(body)

        let (data, resp) = try await URLSession.shared.data(for: req)
        guard let http = resp as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw URLError(.badServerResponse)
        }
        struct ChatResponse: Decodable { let message: String }
        let res = try jsonDecoder.decode(ChatResponse.self, from: data)
        return res.message
    }

    // MARK: - Workout Plan
    func generateWorkoutPlan(overrides: [String: Any] = [:]) async throws -> [String: Any] {
        let url = baseURL.appendingPathComponent("workout-plan")
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.httpBody = try JSONSerialization.data(withJSONObject: overrides, options: [])
        let (data, resp) = try await URLSession.shared.data(for: req)
        guard let http = resp as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw URLError(.badServerResponse)
        }
        let obj = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        return obj?["plan"] as? [String: Any] ?? [:]
    }

    // MARK: - Meal Plan
    func generateMealPlan(overrides: [String: Any] = [:]) async throws -> [String: Any] {
        let url = baseURL.appendingPathComponent("meal-plan")
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.httpBody = try JSONSerialization.data(withJSONObject: overrides, options: [])
        let (data, resp) = try await URLSession.shared.data(for: req)
        guard let http = resp as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw URLError(.badServerResponse)
        }
        let obj = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        return obj?["plan"] as? [String: Any] ?? [:]
    }

    // MARK: - Feed
    func dailyFeed() async throws -> [[String: Any]] {
        let url = baseURL.appendingPathComponent("feed")
        let (data, resp) = try await URLSession.shared.data(from: url)
        guard let http = resp as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw URLError(.badServerResponse)
        }
        let obj = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        return obj?["items"] as? [[String: Any]] ?? []
    }

    // MARK: - Progress
    func analyzeProgress(entries: [[String: Any]], goals: [[String: Any]] = []) async throws -> [String: Any] {
        let url = baseURL.appendingPathComponent("progress/analyze")
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let body: [String: Any] = ["entries": entries, "goals": goals]
        req.httpBody = try JSONSerialization.data(withJSONObject: body)
        let (data, resp) = try await URLSession.shared.data(for: req)
        guard let http = resp as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw URLError(.badServerResponse)
        }
        let obj = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        return obj ?? [:]
    }
}
