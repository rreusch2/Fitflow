//
//  NutritionAIService.swift
//  Flowmate
//
//  Created on 2025-08-14
//

import Foundation
import Combine

@MainActor
final class NutritionAIService: ObservableObject {
    static let shared = NutritionAIService()
    
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var suggestionsByDate: [String: [NutritionMeal]] = [:] // ISO date -> meals
    
    private var cancellables = Set<AnyCancellable>()
    
    private init() {}
    
    // MARK: - Public API
    
    func getDailySuggestions(date: Date, goals: NutritionGoals?) async throws -> [NutritionMeal] {
        let key = isoDayString(date)
        if let cached = suggestionsByDate[key] {
            return cached
        }
        isLoading = true
        defer { isLoading = false }
        do {
            let overrides = createMealPlanPayload(date: date, goals: goals)
            let planData = try await CoachAPIClient.shared.generateMealPlan(overrides: overrides)
            let meals = try parseMealPlan(from: planData)
            suggestionsByDate[key] = meals
            return meals
        } catch {
            self.errorMessage = "Failed to get meal suggestions: \(error.localizedDescription)"
            throw error
        }
    }
    
    // MARK: - Backend Integration
    private func createMealPlanPayload(date: Date, goals: NutritionGoals?) -> [String: Any] {
        let dateStr = ISO8601DateFormatter().string(from: date)
        let calories = goals?.targetCalories ?? 2200
        let p = goals?.targetMacros?.protein ?? 150
        let c = goals?.targetMacros?.carbs ?? 200
        let f = goals?.targetMacros?.fat ?? 70
        let exclusions = goals?.exclusions ?? []
        var dietPrefs: [String: Any] = [:]
        if let prefs = goals?.dietPreferences, !prefs.isEmpty {
            for (key, value) in prefs {
                dietPrefs[key] = value.value
            }
        }
        
        return [
            "date": dateStr,
            "targetCalories": calories,
            "targetProtein": p,
            "targetCarbs": c,
            "targetFat": f,
            "exclusions": exclusions,
            "dietPreferences": dietPrefs,
            "mealTypes": ["breakfast", "lunch", "dinner", "snack"]
        ]
    }
    
    private func parseMealPlan(from planData: [String: Any]) throws -> [NutritionMeal] {
        guard let mealsArray = planData["meals"] as? [[String: Any]] else {
            return []
        }
        
        return mealsArray.compactMap { mealData in
            guard let title = mealData["title"] as? String,
                  let mealTypeStr = mealData["mealType"] as? String,
                  let itemsArray = mealData["items"] as? [[String: Any]] else {
                return nil
            }
            
            let items: [NutritionMealItem] = itemsArray.compactMap { itemData in
                guard let name = itemData["name"] as? String,
                      let calories = itemData["calories"] as? Int else {
                    return nil
                }
                let serving = itemData["serving"] as? String
                var macros: Macros?
                if let macrosData = itemData["macros"] as? [String: Any] {
                    let protein = macrosData["protein"] as? Double
                    let carbs = macrosData["carbs"] as? Double
                    let fat = macrosData["fat"] as? Double
                    macros = Macros(protein: protein, carbs: carbs, fat: fat)
                }
                return NutritionMealItem(id: nil, name: name, serving: serving, calories: calories, macros: macros)
            }
            
            let mealType = NutritionMealType(rawValue: mealTypeStr.lowercased()) ?? .lunch
            return NutritionMeal(title: title, mealType: mealType, items: items)
        }
    }
    
    // MARK: - Utils
    private func isoDayString(_ date: Date) -> String {
        let cal = Calendar(identifier: .gregorian)
        let comps = cal.dateComponents([.year, .month, .day], from: date)
        let d = cal.date(from: comps) ?? date
        let f = DateFormatter()
        f.calendar = cal
        f.locale = Locale(identifier: "en_US_POSIX")
        f.timeZone = TimeZone(secondsFromGMT: 0)
        f.dateFormat = "yyyy-MM-dd"
        return f.string(from: d)
    }
}
