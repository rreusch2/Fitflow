//
//  NutritionService.swift
//  Flowmate
//
//  Created on 2025-08-14
//

import Foundation
import Combine

@MainActor
final class NutritionService: ObservableObject {
    static let shared = NutritionService()
    
    @Published var goals: NutritionGoals?
    @Published var todaySummary: NutritionSummaryDay?
    @Published var plannedMeals: NutritionPlannedMeals?
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private var cancellables = Set<AnyCancellable>()
    
    private let db = DatabaseService.shared
    private let jsonEncoder: JSONEncoder = {
        let e = JSONEncoder()
        e.dateEncodingStrategy = .iso8601
        return e
    }()
    private let jsonDecoder: JSONDecoder = {
        let d = JSONDecoder()
        d.dateDecodingStrategy = .iso8601
        return d
    }()
    
    private init() {}
    
    // MARK: - Public API (to be backed by Supabase RPCs)
    
    func fetchGoals() async {
        isLoading = true
        defer { isLoading = false }
        do {
            let data = try await dbValueForRPC(name: "get_nutrition_goals", payload: [:])
            if data.isEmpty { return }
            let g = try jsonDecoder.decode(NutritionGoals.self, from: data)
            self.goals = g
        } catch {
            self.errorMessage = "Failed to fetch goals: \(error.localizedDescription)"
        }
    }
    
    func upsertGoals(_ goals: NutritionGoals) async throws {
        isLoading = true
        defer { isLoading = false }
        let obj = try JSONSerialization.jsonObject(with: jsonEncoder.encode(goals), options: []) as? [String: Any] ?? [:]
        _ = try await dbValueForRPC(name: "upsert_nutrition_goals", payload: ["goals": obj])
        self.goals = goals
    }
    
    func setAIPreferences(timeHHmm: String, timezone: String, optIn: Bool) async throws {
        isLoading = true
        defer { isLoading = false }
        _ = try await dbValueForRPC(name: "set_ai_preferences", payload: [
            "time_hhmm": timeHHmm,
            "timezone": timezone,
            "opt_in": optIn
        ])
        var g = goals ?? NutritionGoals(targetCalories: nil, targetMacros: nil, dietPreferences: nil, exclusions: nil, optInDailyAI: optIn, preferredTimeLocal: timeHHmm + ":00", preferredTimezone: timezone)
        g.optInDailyAI = optIn
        g.preferredTimeLocal = timeHHmm + ":00"
        g.preferredTimezone = timezone
        self.goals = g
    }
    
    func logMeal(date: Date = Date(), mealType: NutritionMealType, items: [NutritionMealItem], source: String = "manual", notes: String? = nil) async throws -> NutritionMealLog {
        isLoading = true
        defer { isLoading = false }
        let itemsObj = try JSONSerialization.jsonObject(with: jsonEncoder.encode(items), options: [])
        let payload: [String: Any] = [
            "logged_at": ISO8601DateFormatter().string(from: date),
            "meal_type": mealType.rawValue,
            "items": itemsObj,
            "source": source,
            "notes": notes as Any
        ].compactMapValues { $0 }
        let data = try await dbValueForRPC(name: "log_meal", payload: payload)
        let log = try jsonDecoder.decode(NutritionMealLog.self, from: data)
        // Optimistic/UI update
        await updateTodaySummaryWith(log: log)
        return log
    }
    
    func getSummary(start: Date, end: Date) async throws -> [NutritionSummaryDay] {
        isLoading = true
        defer { isLoading = false }
        let payload: [String: Any] = [
            "start_date": ISO8601DateFormatter().string(from: start),
            "end_date": ISO8601DateFormatter().string(from: end)
        ]
        let data = try await dbValueForRPC(name: "get_nutrition_summary", payload: payload)
        let days = try jsonDecoder.decode([NutritionSummaryDay].self, from: data)
        if Calendar.current.isDateInToday(start), let today = days.first(where: { Calendar.current.isDateInToday($0.day) }) {
            self.todaySummary = today
        }
        return days
    }
    
    func savePlan(for date: Date, meals: [NutritionMeal]) async throws -> NutritionPlannedMeals {
        isLoading = true
        defer { isLoading = false }
        let mealsObj = try JSONSerialization.jsonObject(with: jsonEncoder.encode(meals), options: [])
        let payload: [String: Any] = [
            "day": ISO8601DateFormatter().string(from: date),
            "meals": mealsObj
        ]
        let data = try await dbValueForRPC(name: "save_plan_day", payload: payload)
        let plan = try jsonDecoder.decode(NutritionPlannedMeals.self, from: data)
        if Calendar.current.isDateInToday(plan.date) { plannedMeals = plan }
        return plan
    }
    
    func getPlannedMeals(start: Date, end: Date) async throws -> [NutritionPlannedMeals] {
        isLoading = true
        defer { isLoading = false }
        let payload: [String: Any] = [
            "start_date": ISO8601DateFormatter().string(from: start),
            "end_date": ISO8601DateFormatter().string(from: end)
        ]
        let data = try await dbValueForRPC(name: "get_planned_meals", payload: payload)
        let plans = try jsonDecoder.decode([NutritionPlannedMeals].self, from: data)
        if Calendar.current.isDateInToday(start), let today = plans.first(where: { Calendar.current.isDateInToday($0.date) }) {
            self.plannedMeals = today
        }
        return plans
    }
    
    func deletePlan(for date: Date) async throws {
        isLoading = true
        defer { isLoading = false }
        let payload: [String: Any] = ["day": ISO8601DateFormatter().string(from: date)]
        _ = try await dbValueForRPC(name: "delete_plan_day", payload: payload)
        if Calendar.current.isDateInToday(date) { plannedMeals = nil }
    }
    
    // MARK: - Helpers
    
    private func updateTodaySummaryWith(log: NutritionMealLog) async {
        let day = Calendar.current.startOfDay(for: Date())
        if todaySummary == nil {
            todaySummary = NutritionSummaryDay(day: day, calories: 0, protein: 0, carbs: 0, fat: 0)
        }
        guard var s = todaySummary else { return }
        s.calories += log.totals.calories
        s.protein += log.totals.protein
        s.carbs += log.totals.carbs
        s.fat += log.totals.fat
        todaySummary = s
    }
    
    // MARK: - RPC helper
    private func dbValueForRPC(name: String, payload: [String: Any]) async throws -> Data {
        try await db.rpc(name, payload: payload)
    }
}
