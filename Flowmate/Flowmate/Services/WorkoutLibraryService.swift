//
//  WorkoutLibraryService.swift
//  Flowmate
//
//  Created on 2025-09-10
//

import Foundation
import Combine

@MainActor
class WorkoutLibraryService: ObservableObject {
    static let shared = WorkoutLibraryService()
    
    @Published var plans: [WorkoutPlanResponse] = []
    @Published var isLoading: Bool = false
    @Published var lastError: String?
    
    private let baseURL = "https://fitflow-production.up.railway.app"
    
    private init() {}
    
    struct WorkoutPlansListResponse: Codable {
        let plans: [WorkoutPlanResponse]
    }
    
    func fetchPlans() async {
        isLoading = true
        defer { isLoading = false }
        lastError = nil
        
        guard let url = URL(string: "\(baseURL)/v1/ai/workout-plans") else {
            lastError = "Invalid URL"
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        if let token = UserDefaults.standard.string(forKey: "auth_access_token") {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse else {
                lastError = "Invalid response"
                return
            }
            if http.statusCode != 200 {
                lastError = "Failed to fetch plans (\(http.statusCode))"
                return
            }
            let decoded = try JSONDecoder().decode(WorkoutPlansListResponse.self, from: data)
            self.plans = decoded.plans
        } catch {
            lastError = error.localizedDescription
        }
    }
    
    func deletePlan(id: String) async -> Bool {
        guard let url = URL(string: "\(baseURL)/v1/ai/workout-plans/\(id)") else {
            lastError = "Invalid URL"
            return false
        }
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        if let token = UserDefaults.standard.string(forKey: "auth_access_token") {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        do {
            let (_, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse else { return false }
            if (200...299).contains(http.statusCode) {
                // Update local list
                if let idx = self.plans.firstIndex(where: { $0.id == id }) {
                    self.plans.remove(at: idx)
                }
                return true
            } else {
                lastError = "Delete failed (\(http.statusCode))"
                return false
            }
        } catch {
            lastError = error.localizedDescription
            return false
        }
    }
}
