//
//  NutritionAIService.swift
//  Flowmate
//
//  Real AI-powered nutrition service with backend integration
//

import Foundation
import SwiftUI
import Combine

final class NutritionAIService: ObservableObject {
    static let shared = NutritionAIService()
    private let databaseService = DatabaseService.shared
    @Published var isGenerating = false
    @Published var error: String?
    
    private init() {}
    
    // MARK: - Daily Meal Suggestions
    func getDailySuggestions(date: Date, goals: NutritionService.NutritionGoals?) async throws -> [Meal] {
        await MainActor.run { isGenerating = true }
        
        do {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            
            let response: MealSuggestionsResponse = try await databaseService.request(
                endpoint: "/ai/meal-suggestions",
                method: "POST",
                body: [
                    "date": formatter.string(from: date),
                    "force_regenerate": false
                ]
            )
            
            await MainActor.run { isGenerating = false }
            
            // Convert API response to Meal objects
            return convertSuggestionsToMeals(response.suggestions)
        } catch {
            await MainActor.run {
                self.error = error.localizedDescription
                isGenerating = false
            }
            // Return fallback meals on error
            return getFallbackMeals()
        }
    }
    
    // MARK: - Generate Weekly Meal Plan
    func generateWeeklyMealPlan(startDate: Date = Date()) async throws -> WeeklyMealPlan {
        await MainActor.run { isGenerating = true }
        
        do {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            
            let response: WeeklyPlanResponse = try await databaseService.request(
                endpoint: "/ai/weekly-meal-plan",
                method: "POST",
                body: [
                    "start_date": formatter.string(from: startDate)
                ]
            )
            
            await MainActor.run { isGenerating = false }
            
            return WeeklyMealPlan(
                id: UUID(uuidString: response.plan.id) ?? UUID(),
                title: response.plan.title,
                description: response.plan.description,
                targetCalories: response.plan.target_calories,
                macroBreakdown: MacroBreakdown(
                    protein: response.plan.macro_breakdown.protein,
                    carbs: response.plan.macro_breakdown.carbs,
                    fat: response.plan.macro_breakdown.fat,
                    fiber: response.plan.macro_breakdown.fiber
                ),
                dailyMeals: [:], // Would need to parse from response
                shoppingList: response.plan.shopping_list,
                prepTime: response.plan.prep_time,
                notes: response.plan.ai_generated_notes ?? ""
            )
        } catch {
            await MainActor.run {
                self.error = error.localizedDescription
                isGenerating = false
            }
            throw error
        }
    }
    
    // MARK: - Analyze Current Diet
    func analyzeDiet(daysBack: Int = 7) async throws -> DietAnalysis {
        await MainActor.run { isGenerating = true }
        
        do {
            let response: DietAnalysisResponse = try await databaseService.request(
                endpoint: "/ai/analyze-diet",
                method: "POST",
                body: ["days_back": daysBack]
            )
            
            await MainActor.run { isGenerating = false }
            
            return DietAnalysis(
                overallScore: response.analysis.overall_score,
                insights: response.analysis.insights,
                strengths: response.analysis.strengths,
                areasForImprovement: response.analysis.areas_for_improvement,
                recommendations: response.analysis.recommendations,
                macroAnalysis: MacroAnalysis(
                    protein: MacroStatus(
                        current: response.analysis.macro_analysis.protein.current,
                        target: response.analysis.macro_analysis.protein.target,
                        status: response.analysis.macro_analysis.protein.status
                    ),
                    carbs: MacroStatus(
                        current: response.analysis.macro_analysis.carbs.current,
                        target: response.analysis.macro_analysis.carbs.target,
                        status: response.analysis.macro_analysis.carbs.status
                    ),
                    fat: MacroStatus(
                        current: response.analysis.macro_analysis.fat.current,
                        target: response.analysis.macro_analysis.fat.target,
                        status: response.analysis.macro_analysis.fat.status
                    )
                ),
                calorieTrends: response.analysis.calorie_trends.map { trend in
                    CalorieTrend(date: trend.date, calories: trend.calories)
                }
            )
        } catch {
            await MainActor.run {
                self.error = error.localizedDescription
                isGenerating = false
            }
            throw error
        }
    }
    
    // MARK: - Get Personalized Nutrition Tips
    func getNutritionTips(goals: NutritionService.NutritionGoals?, recentMeals: [Meal]) async throws -> [NutritionTipModel] {
        await MainActor.run { isGenerating = true }
        
        do {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            
            let response: NutritionTipsResponse = try await databaseService.request(
                endpoint: "/ai/nutrition-tips",
                method: "GET"
            )
            
            await MainActor.run { isGenerating = false }
            
            return convertTipsToModels(response.tips)
        } catch {
            await MainActor.run {
                self.error = error.localizedDescription
            }
            // Return fallback tips
            return getFallbackTips()
        }
    }
    
    // MARK: - Helper Methods
    private func convertSuggestionsToMeals(_ suggestions: MealSuggestionsData) -> [Meal] {
        var meals: [Meal] = []
        
        if let breakfast = convertMealData(suggestions.breakfast, type: .breakfast) {
            meals.append(breakfast)
        }
        if let lunch = convertMealData(suggestions.lunch, type: .lunch) {
            meals.append(lunch)
        }
        if let dinner = convertMealData(suggestions.dinner, type: .dinner) {
            meals.append(dinner)
        }
        if let snack = convertMealData(suggestions.snack, type: .snack) {
            meals.append(snack)
        }
        
        return meals
    }
    
    private func convertMealData(_ mealData: MealData?, type: MealType) -> Meal? {
        guard let data = mealData else { return nil }
        
        return Meal(
            id: UUID(uuidString: data.id) ?? UUID(),
            type: type,
            name: data.name,
            description: data.description,
            calories: data.calories,
            macros: MacroBreakdown(
                protein: data.macros.protein,
                carbs: data.macros.carbs,
                fat: data.macros.fat,
                fiber: data.macros.fiber
            ),
            ingredients: data.ingredients?.map { ingredient in
                Ingredient(
                    id: UUID(uuidString: ingredient.id) ?? UUID(),
                    name: ingredient.name,
                    amount: ingredient.amount,
                    unit: ingredient.unit,
                    calories: ingredient.calories,
                    macros: MacroBreakdown(
                        protein: ingredient.macros.protein,
                        carbs: ingredient.macros.carbs,
                        fat: ingredient.macros.fat,
                        fiber: ingredient.macros.fiber
                    ),
                    isOptional: false,
                    substitutes: []
                )
            } ?? [],
            instructions: ["Prepare as suggested"],
            prepTime: data.prep_time ?? 10,
            cookTime: 0,
            servings: 1,
            difficulty: CookingSkill(rawValue: data.difficulty ?? "beginner") ?? .beginner,
            tags: data.tags ?? [],
            imageUrl: nil
        )
    }
    
    private func getFallbackMeals() -> [Meal] {
        let breakfast = Meal(
            id: UUID(),
            type: .breakfast,
            name: "Greek Yogurt Parfait",
            description: "High-protein parfait with berries and granola",
            calories: 420,
            macros: MacroBreakdown(protein: 30, carbs: 50, fat: 12, fiber: 6),
            ingredients: [
                Ingredient(id: UUID(), name: "Nonfat Greek Yogurt", amount: 200, unit: "g", calories: 130, macros: MacroBreakdown(protein: 23, carbs: 8, fat: 0, fiber: 0), isOptional: false, substitutes: []),
                Ingredient(id: UUID(), name: "Blueberries", amount: 100, unit: "g", calories: 57, macros: MacroBreakdown(protein: 1, carbs: 14, fat: 0, fiber: 2), isOptional: false, substitutes: ["Strawberries"]),
                Ingredient(id: UUID(), name: "Granola", amount: 40, unit: "g", calories: 200, macros: MacroBreakdown(protein: 4, carbs: 32, fat: 6, fiber: 4), isOptional: false, substitutes: ["Oats"])
            ],
            instructions: [
                "Layer yogurt in a bowl",
                "Top with berries and granola",
                "Optional: drizzle with honey"
            ],
            prepTime: 5,
            cookTime: 0,
            servings: 1,
            difficulty: .beginner,
            tags: ["high_protein", "quick"],
            imageUrl: nil
        )
        
        let lunch = Meal(
            id: UUID(),
            type: .lunch,
            name: "Chicken Rice Bowl",
            description: "Balanced bowl with grilled chicken, rice, veggies",
            calories: 650,
            macros: MacroBreakdown(protein: 45, carbs: 70, fat: 18, fiber: 7),
            ingredients: [
                Ingredient(id: UUID(), name: "Grilled Chicken Breast", amount: 170, unit: "g", calories: 280, macros: MacroBreakdown(protein: 50, carbs: 0, fat: 6, fiber: 0), isOptional: false, substitutes: ["Tofu"]),
                Ingredient(id: UUID(), name: "Cooked Jasmine Rice", amount: 200, unit: "g", calories: 260, macros: MacroBreakdown(protein: 5, carbs: 57, fat: 1, fiber: 1), isOptional: false, substitutes: ["Quinoa"]),
                Ingredient(id: UUID(), name: "Mixed Veggies", amount: 150, unit: "g", calories: 110, macros: MacroBreakdown(protein: 4, carbs: 13, fat: 4, fiber: 6), isOptional: false, substitutes: [])
            ],
            instructions: [
                "Assemble ingredients in a bowl",
                "Top with light teriyaki or salsa",
                "Serve warm"
            ],
            prepTime: 10,
            cookTime: 15,
            servings: 1,
            difficulty: .beginner,
            tags: ["balanced", "meal_prep"],
            imageUrl: nil
        )
        
        let dinner = Meal(
            id: UUID(),
            type: .dinner,
            name: "Salmon, Potatoes & Greens",
            description: "Omega-3 rich salmon with roasted potatoes and salad",
            calories: 700,
            macros: MacroBreakdown(protein: 42, carbs: 55, fat: 30, fiber: 6),
            ingredients: [
                Ingredient(id: UUID(), name: "Baked Salmon", amount: 170, unit: "g", calories: 367, macros: MacroBreakdown(protein: 34, carbs: 0, fat: 25, fiber: 0), isOptional: false, substitutes: ["Tilapia"]),
                Ingredient(id: UUID(), name: "Roasted Potatoes", amount: 200, unit: "g", calories: 208, macros: MacroBreakdown(protein: 5, carbs: 47, fat: 0, fiber: 4), isOptional: false, substitutes: ["Sweet Potato"]),
                Ingredient(id: UUID(), name: "Side Salad", amount: 100, unit: "g", calories: 80, macros: MacroBreakdown(protein: 3, carbs: 8, fat: 5, fiber: 2), isOptional: false, substitutes: [])
            ],
            instructions: [
                "Bake salmon at 400°F for 12-15 min",
                "Roast potatoes until tender",
                "Serve with salad"
            ],
            prepTime: 10,
            cookTime: 25,
            servings: 1,
            difficulty: .beginner,
            tags: ["omega3", "whole_food"],
            imageUrl: nil
        )
        
        let snack = Meal(
            id: UUID(),
            type: .snack,
            name: "Apple & Peanut Butter",
            description: "Simple and satisfying snack",
            calories: 250,
            macros: MacroBreakdown(protein: 7, carbs: 24, fat: 14, fiber: 5),
            ingredients: [
                Ingredient(id: UUID(), name: "Apple", amount: 182, unit: "g", calories: 95, macros: MacroBreakdown(protein: 0, carbs: 25, fat: 0, fiber: 4), isOptional: false, substitutes: []),
                Ingredient(id: UUID(), name: "Peanut Butter", amount: 32, unit: "g", calories: 188, macros: MacroBreakdown(protein: 7, carbs: 6, fat: 16, fiber: 1), isOptional: false, substitutes: ["Almond Butter"])
            ],
            instructions: [
                "Slice apple",
                "Serve with peanut butter"
            ],
            prepTime: 3,
            cookTime: 0,
            servings: 1,
            difficulty: .beginner,
            tags: ["snack", "balanced"],
            imageUrl: nil
        )
        
        return [breakfast, lunch, dinner, snack]
    }
    
    private func getFallbackTips() -> [NutritionTipModel] {
        return [
            NutritionTipModel(
                category: .general,
                content: "Focus on meeting your protein targets to support muscle growth and recovery.",
                priority: 1
            ),
            NutritionTipModel(
                category: .general,
                content: "You're doing well with consistent meal tracking. Keep it up!",
                priority: 1
            ),
            NutritionTipModel(
                category: .general,
                content: "Try meal prepping on Sundays to stay on track during busy weekdays.",
                priority: 1
            )
        ]
    }
    
    private func convertTipsToModels(_ tips: [NutritionTipData]) -> [NutritionTipModel] {
        return tips.compactMap { tipData in
            let category = mapTypeToCategory(tipData.type)
            
            return NutritionTipModel(
                category: category,
                content: tipData.content,
                priority: 1
            )
        }
    }
    
    private func mapTypeToCategory(_ type: String) -> NutritionTipModel.TipCategory {
        switch type.lowercased() {
        case "protein": return .protein
        case "hydration": return .hydration
        case "timing": return .timing
        case "recovery": return .recovery
        default: return .general
        }
    }
}

// MARK: - Response Models
struct MealSuggestionsResponse: Codable {
    let suggestions: MealSuggestionsData
    let cached: Bool?
}

struct MealSuggestionsData: Codable {
    let breakfast: MealData?
    let lunch: MealData?
    let dinner: MealData?
    let snack: MealData?
}

struct MealData: Codable {
    let id: String
    let name: String
    let description: String
    let calories: Int
    let macros: MacroData
    let ingredients: [IngredientData]?
    let prep_time: Int?
    let difficulty: String?
    let tags: [String]?
}

struct MacroData: Codable {
    let protein: Int
    let carbs: Int
    let fat: Int
    let fiber: Int
}

struct IngredientData: Codable {
    let id: String
    let name: String
    let amount: Double
    let unit: String
    let calories: Int
    let macros: MacroData
}

struct WeeklyPlanResponse: Codable {
    let plan: WeeklyPlanData
}

struct WeeklyPlanData: Codable {
    let id: String
    let title: String
    let description: String
    let target_calories: Int
    let macro_breakdown: MacroData
    let shopping_list: [String]
    let prep_time: Int
    let ai_generated_notes: String?
}

struct DietAnalysisResponse: Codable {
    let analysis: DietAnalysisData
}

struct DietAnalysisData: Codable {
    let overall_score: Int
    let insights: [String]
    let strengths: [String]
    let areas_for_improvement: [String]
    let recommendations: [String]
    let macro_analysis: MacroAnalysisData
    let calorie_trends: [CalorieTrendData]
}

struct MacroAnalysisData: Codable {
    let protein: MacroStatusData
    let carbs: MacroStatusData
    let fat: MacroStatusData
}

struct MacroStatusData: Codable {
    let current: Double
    let target: Double
    let status: String
}

struct CalorieTrendData: Codable {
    let date: String
    let calories: Int
}

struct NutritionTipsResponse: Codable {
    let tips: [NutritionTipData]
}

struct NutritionTipData: Codable {
    let type: String
    let icon: String
    let title: String
    let content: String
}

// MARK: - Domain Models
struct WeeklyMealPlan {
    let id: UUID
    let title: String
    let description: String
    let targetCalories: Int
    let macroBreakdown: MacroBreakdown
    let dailyMeals: [String: [Meal]] // Day of week -> meals
    let shoppingList: [String]
    let prepTime: Int
    let notes: String
}

struct DietAnalysis {
    let overallScore: Int
    let insights: [String]
    let strengths: [String]
    let areasForImprovement: [String]
    let recommendations: [String]
    let macroAnalysis: MacroAnalysis
    let calorieTrends: [CalorieTrend]
}

struct MacroAnalysis {
    let protein: MacroStatus
    let carbs: MacroStatus
    let fat: MacroStatus
}

struct MacroStatus {
    let current: Double
    let target: Double
    let status: String // "low", "good", "high"
}

struct CalorieTrend {
    let date: String
    let calories: Int
}

struct NutritionTipModel {
    let id = UUID()
    let category: TipCategory
    let content: String
    let priority: Int
    
    enum TipCategory {
        case protein, hydration, timing, recovery, general
        
        var displayName: String {
            switch self {
            case .protein: return "Protein"
            case .hydration: return "Hydration"
            case .timing: return "Timing"
            case .recovery: return "Recovery"
            case .general: return "General"
            }
        }
        
        var icon: String {
            switch self {
            case .protein: return "leaf.fill"
            case .hydration: return "drop.fill"
            case .timing: return "clock.fill"
            case .recovery: return "heart.fill"
            case .general: return "lightbulb.fill"
            }
        }
        
        var color: Color {
            switch self {
            case .protein: return .green
            case .hydration: return .blue
            case .timing: return .orange
            case .recovery: return .purple
            case .general: return .gray
            }
        }
    }
}
