//
//  BackendWorkoutService.swift
//  Flowmate
//
//  Created on 2025-09-10
//

import Foundation

@MainActor
final class BackendWorkoutService: ObservableObject {
    static let shared = BackendWorkoutService()
    private init() {}
    
    private let baseURL = URL(string: "https://fitflow-production.up.railway.app")!
    
    struct CreateSessionRequest: Codable {
        let title: String
        let occurred_at: String
        let duration_seconds: Int
        let exercises: [CompletedExercise]
        let muscle_groups: [String]
        let calories_burned: Int?
        let average_heart_rate: Int?
    }
    
    struct SessionDTO: Codable, Identifiable {
        let id: UUID
        let title: String
        let occurred_at: Date
        let duration_seconds: Int
        let exercises: [CompletedExercise]
        let muscle_groups: [String]
        let calories_burned: Int?
        let average_heart_rate: Int?
    }
    
    struct ListResponse: Codable {
        let sessions: [SessionDTO]
    }
    
    func postSession(_ session: WorkoutSession) async throws {
        let url = baseURL.appendingPathComponent("/v1/progress/sessions")
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if let token = UserDefaults.standard.string(forKey: "auth_access_token") {
            req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        let iso = ISO8601DateFormatter()
        let payload = CreateSessionRequest(
            title: session.title,
            occurred_at: iso.string(from: session.date),
            duration_seconds: Int(session.duration),
            exercises: session.exercises,
            muscle_groups: session.muscleGroups.map { $0.rawValue },
            calories_burned: session.caloriesBurned,
            average_heart_rate: session.averageHeartRate
        )
        let enc = JSONEncoder()
        req.httpBody = try enc.encode(payload)
        let (_, resp) = try await URLSession.shared.data(for: req)
        guard let http = resp as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            throw URLError(.badServerResponse)
        }
    }
    
    func fetchSessions(limit: Int = 50) async throws -> [WorkoutSession] {
        let url = baseURL.appendingPathComponent("/v1/progress/sessions")
        var comps = URLComponents(url: url, resolvingAgainstBaseURL: false)!
        comps.queryItems = [URLQueryItem(name: "limit", value: String(limit))]
        var req = URLRequest(url: comps.url!)
        req.httpMethod = "GET"
        req.setValue("application/json", forHTTPHeaderField: "Accept")
        if let token = UserDefaults.standard.string(forKey: "auth_access_token") {
            req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        let (data, resp) = try await URLSession.shared.data(for: req)
        guard let http = resp as? HTTPURLResponse, http.statusCode == 200 else { throw URLError(.badServerResponse) }
        let dec = JSONDecoder()
        dec.dateDecodingStrategy = .iso8601
        let list = try dec.decode(ListResponse.self, from: data)
        return list.sessions.map { dto in
            WorkoutSession(
                id: dto.id,
                title: dto.title,
                date: dto.occurred_at,
                duration: TimeInterval(dto.duration_seconds),
                exercises: dto.exercises,
                muscleGroups: dto.muscle_groups.compactMap { MuscleGroup(rawValue: $0) },
                caloriesBurned: dto.calories_burned ?? 0,
                averageHeartRate: dto.average_heart_rate ?? 0
            )
        }
    }
}
