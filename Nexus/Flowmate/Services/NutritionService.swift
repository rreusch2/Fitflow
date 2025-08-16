//
//  NutritionService.swift
//  Flowmate
//
//  Real nutrition service with backend API integration
//

import Foundation
import Combine

final class NutritionService: ObservableObject {
    static let shared = NutritionService()
    private let databaseService = DatabaseService.shared
    private init() {}
    
    // MARK: - Models used by the view
    struct NutritionGoals {
        var targetCalories: Int?
        var targetMacros: TargetMacros?
        
        struct TargetMacros {
            var protein: Double?
            var carbs: Double?
            var fat: Double?
        }
        
        init(targetCalories: Int? = nil, targetMacros: TargetMacros? = nil) {
            self.targetCalories = targetCalories
            self.targetMacros = targetMacros
        }
    }
    
    struct NutritionSummary {
        var calories: Double
        var protein: Double
        var carbs: Double
        var fat: Double
    }
    
    @Published var goals: NutritionGoals?
    @Published var todaySummary: NutritionSummary?
    @Published var isLoading = false
    @Published var error: String?
    
    // MARK: - API surface used by the view
    func fetchGoals() async {
        await MainActor.run { isLoading = true }
        
        do {
            let response: GoalsResponse = try await databaseService.request(
                endpoint: "/nutrition/goals",
                method: "GET"
            )
            
            await MainActor.run {
                if let goalsData = response.goals {
                    let targetMacros = goalsData.target_macros.map { macros in
                        NutritionGoals.TargetMacros(
                            protein: macros.protein,
                            carbs: macros.carbs,
                            fat: macros.fat
                        )
                    }
                    
                    self.goals = NutritionGoals(
                        targetCalories: goalsData.target_calories,
                        targetMacros: targetMacros
                    )
                } else {
                    // Set default goals
                    self.goals = NutritionGoals(
                        targetCalories: 2200,
                        targetMacros: .init(protein: 160, carbs: 220, fat: 70)
                    )
                }
                isLoading = false
            }
        } catch {
            await MainActor.run {
                self.error = error.localizedDescription
                // Use defaults on error
                self.goals = NutritionGoals(
                    targetCalories: 2200,
                    targetMacros: .init(protein: 160, carbs: 220, fat: 70)
                )
                isLoading = false
            }
        }
    }
    
    func getSummary(start: Date, end: Date) async throws -> NutritionSummary? {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        
        let response: SummaryResponse = try await databaseService.request(
            endpoint: "/nutrition/summary",
            method: "GET",
            queryItems: [
                URLQueryItem(name: "start_date", value: formatter.string(from: start)),
                URLQueryItem(name: "end_date", value: formatter.string(from: end))
            ]
        )
        
        let summary = NutritionSummary(
            calories: response.summary.calories,
            protein: response.summary.protein,
            carbs: response.summary.carbs,
            fat: response.summary.fat
        )
        
        await MainActor.run {
            self.todaySummary = summary
        }
        
        return summary
    }
    
    func savePlan(for date: Date, meals: [Meal]) async throws -> Bool {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        
        let body: [String: Any] = [
            "date": formatter.string(from: date),
            "meals": meals.map { meal in
                [
                    "id": meal.id.uuidString,
                    "type": meal.type.rawValue,
                    "name": meal.name,
                    "description": meal.description,
                    "calories": meal.calories,
                    "macros": [
                        "protein": meal.macros.protein,
                        "carbs": meal.macros.carbs,
                        "fat": meal.macros.fat,
                        "fiber": meal.macros.fiber
                    ],
                    "ingredients": meal.ingredients.map { ingredient in
                        [
                            "id": ingredient.id.uuidString,
                            "name": ingredient.name,
                            "amount": ingredient.amount,
                            "unit": ingredient.unit,
                            "calories": ingredient.calories,
                            "macros": [
                                "protein": ingredient.macros.protein,
                                "carbs": ingredient.macros.carbs,
                                "fat": ingredient.macros.fat,
                                "fiber": ingredient.macros.fiber
                            ]
                        ]
                    }
                ]
            }
        ]
        
        let _: PlanResponse = try await databaseService.request(
            endpoint: "/nutrition/plan/add",
            method: "POST",
            body: body
        )
        
        return true
    }
    
    func logMeal(mealType: MealType, items: [Ingredient], source: String) async throws -> Bool {
        let body: [String: Any] = [
            "meal_type": mealType.rawValue,
            "source": source,
            "items": items.map { ingredient in
                [
                    "id": ingredient.id.uuidString,
                    "name": ingredient.name,
                    "amount": ingredient.amount,
                    "unit": ingredient.unit,
                    "calories": ingredient.calories,
                    "macros": [
                        "protein": ingredient.macros.protein,
                        "carbs": ingredient.macros.carbs,
                        "fat": ingredient.macros.fat,
                        "fiber": ingredient.macros.fiber
                    ]
                ]
            }
        ]
        
        let _: LogResponse = try await databaseService.request(
            endpoint: "/nutrition/log",
            method: "POST",
            body: body
        )
        
        return true
    }
    
    func updateGoals(targetCalories: Int, targetMacros: NutritionGoals.TargetMacros) async throws -> Bool {
        let body: [String: Any] = [
            "target_calories": targetCalories,
            "target_macros": [
                "protein": targetMacros.protein ?? 0,
                "carbs": targetMacros.carbs ?? 0,
                "fat": targetMacros.fat ?? 0
            ],
            "opt_in_daily_ai": true
        ]
        
        let _: GoalsResponse = try await databaseService.request(
            endpoint: "/nutrition/goals",
            method: "POST",
            body: body
        )
        
        return true
    }
}

// MARK: - Response Models
struct GoalsResponse: Codable {
    let goals: GoalsData?
    
    struct GoalsData: Codable {
        let target_calories: Int?
        let target_macros: TargetMacros?
        
        struct TargetMacros: Codable {
            let protein: Double?
            let carbs: Double?
            let fat: Double?
        }
    }
}

struct SummaryResponse: Codable {
    let summary: SummaryData
    
    struct SummaryData: Codable {
        let calories: Double
        let protein: Double
        let carbs: Double
        let fat: Double
        let fiber: Double
        let entries_count: Int
    }
}

struct PlanResponse: Codable {
    let plan: PlanData?
    
    struct PlanData: Codable {
        let id: String
        let date: String
    }
}

struct LogResponse: Codable {
    let log: LogData
    
    struct LogData: Codable {
        let id: String
        let meal_type: String
        let logged_at: String
    }
}

// MARK: - Nutrition Preferences Extension
extension NutritionService {
    func getNutritionPreferences() async throws -> NutritionPreferences? {
        do {
            let response: PreferencesResponse = try await databaseService.request(
                endpoint: "/nutrition/preferences",
                method: "GET",
                body: [:] as [String: Any]
            )
            return convertToNutritionPreferences(response.preferences)
        } catch {
            print("Failed to load nutrition preferences: \(error)")
            return nil
        }
    }
    
    func saveNutritionPreferences(_ preferences: NutritionPreferences) async throws {
        let requestBody: [String: Any] = [
            "dietary_restrictions": Array(preferences.dietaryRestrictions.map { $0.rawValue }),
            "preferred_cuisines": Array(preferences.preferredCuisines.map { $0.rawValue }),
            "disliked_foods": Array(preferences.dislikedFoods.map { $0.rawValue }),
            "meals_per_day": preferences.mealsPerDay,
            "max_prep_time": preferences.maxPrepTime.rawValue,
            "cooking_skill": preferences.cookingSkill.rawValue,
            "include_snacks": preferences.includeSnacks,
            "meal_prep_friendly": preferences.mealPrepFriendly,
            "budget_level": preferences.budgetLevel.rawValue,
            "prefer_local_seasonal": preferences.preferLocalSeasonal,
            "consider_workout_schedule": preferences.considerWorkoutSchedule,
            "optimize_for_recovery": preferences.optimizeForRecovery,
            "include_supplements": preferences.includeSupplements
        ]
        
        let _: PreferencesSaveResponse = try await databaseService.request(
            endpoint: "/nutrition/preferences",
            method: "POST",
            body: requestBody
        )
    }
    
    private func convertToNutritionPreferences(_ data: PreferencesData) -> NutritionPreferences {
        var preferences = NutritionPreferences()
        
        // Convert arrays back to sets
        preferences.dietaryRestrictions = Set(data.dietary_restrictions?.compactMap { DietaryRestriction(rawValue: $0) } ?? [])
        preferences.preferredCuisines = Set(data.preferred_cuisines?.compactMap { CuisineType(rawValue: $0) } ?? [])
        preferences.dislikedFoods = Set(data.disliked_foods?.compactMap { CommonFood(rawValue: $0) } ?? [])
        
        preferences.mealsPerDay = data.meals_per_day ?? 3
        preferences.maxPrepTime = PrepTimePreference(rawValue: data.max_prep_time ?? "medium") ?? .medium
        preferences.cookingSkill = CookingSkill(rawValue: data.cooking_skill ?? "intermediate") ?? .intermediate
        preferences.includeSnacks = data.include_snacks ?? true
        preferences.mealPrepFriendly = data.meal_prep_friendly ?? false
        preferences.budgetLevel = BudgetLevel(rawValue: data.budget_level ?? "moderate") ?? .moderate
        preferences.preferLocalSeasonal = data.prefer_local_seasonal ?? false
        preferences.considerWorkoutSchedule = data.consider_workout_schedule ?? true
        preferences.optimizeForRecovery = data.optimize_for_recovery ?? false
        preferences.includeSupplements = data.include_supplements ?? false
        
        return preferences
    }
}

// MARK: - Preferences Response Models
struct PreferencesResponse: Codable {
    let preferences: PreferencesData
}

struct PreferencesData: Codable {
    let dietary_restrictions: [String]?
    let preferred_cuisines: [String]?
    let disliked_foods: [String]?
    let meals_per_day: Int?
    let max_prep_time: String?
    let cooking_skill: String?
    let include_snacks: Bool?
    let meal_prep_friendly: Bool?
    let budget_level: String?
    let prefer_local_seasonal: Bool?
    let consider_workout_schedule: Bool?
    let optimize_for_recovery: Bool?
    let include_supplements: Bool?
}

struct PreferencesSaveResponse: Codable {
    let success: Bool
    let message: String?
}

// MARK: - Quick Add Calories
extension NutritionService {
    func quickAddCalories(calories: Int, description: String?, mealType: MealType) async throws -> Bool {
        let requestBody: [String: Any] = [
            "calories": calories,
            "description": description ?? "Quick add - \(calories) calories",
            "meal_type": mealType.rawValue
        ]
        
        let response: QuickAddResponse = try await databaseService.request(
            endpoint: "/nutrition/quick-add",
            method: "POST",
            body: requestBody
        )
        
        // Refresh today's summary after adding calories
        await refreshTodaySummary()
        
        return response.success
    }
    
    private func refreshTodaySummary() async {
        do {
            let today = Date()
            let summary = try await getSummary(start: today, end: today)
            await MainActor.run {
                self.todaySummary = summary
            }
        } catch {
            print("Failed to refresh today's summary: \(error)")
        }
    }
}

struct QuickAddResponse: Codable {
    let success: Bool
    let log: QuickAddLogData?
    
    struct QuickAddLogData: Codable {
        let id: String
        let calories: Int
        let description: String
        let meal_type: String
        let logged_at: String
    }
}
