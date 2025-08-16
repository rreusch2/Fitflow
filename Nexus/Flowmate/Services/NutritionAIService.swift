//  NutritionAIService.swift
//  Flowmate
//
//  AI-powered nutrition service with backend integration

import Foundation
import Combine
import Supabase

final class NutritionAIService: ObservableObject {
    static let shared = NutritionAIService()
    private let apiClient = CoachAPIClient.shared
    private let supabase = DatabaseService.shared.client
    
    @Published var isGenerating = false
    @Published var lastGeneratedDate: Date?
    @Published var cachedSuggestions: [Meal] = []
    @Published var personalizedTips: [NutritionTip] = []
    @Published var weeklyMealPlan: MealPlan?
    @Published var dietAnalysis: DietAnalysis?
    
    struct NutritionTip {
        let id = UUID()
        let text: String
        let type: TipType
        let icon: String
        let priority: Int
        
        enum TipType {
            case suggestion
            case positive
            case warning
            case tip
        }
    }
    
    struct DietAnalysis {
        let summary: String
        let strengths: [String]
        let improvements: [String]
        let recommendations: [String]
        let score: Int // 0-100
        let generatedAt: Date
    }
    
    private init() {}
    
    // MARK: - AI Meal Suggestions
    func getDailySuggestions(date: Date, goals: NutritionService.NutritionGoals?, forceRefresh: Bool = false) async throws -> [Meal] {
        // Check cache first (avoid excessive API calls)
        if !forceRefresh,
           let lastDate = lastGeneratedDate,
           Calendar.current.isDate(lastDate, inSameDayAs: date),
           !cachedSuggestions.isEmpty {
            return cachedSuggestions
        }
        
        // Check if we have saved suggestions in database
        if let saved = await fetchSavedSuggestions(for: date) {
            await MainActor.run {
                self.cachedSuggestions = saved
                self.lastGeneratedDate = date
            }
            return saved
        }
        
        // Generate new suggestions via AI
        await MainActor.run { self.isGenerating = true }
        
        do {
            let meals = try await generateAIMeals(date: date, goals: goals)
            
            // Save to database for future use
            await saveSuggestions(meals, for: date)
            
            await MainActor.run {
                self.cachedSuggestions = meals
                self.lastGeneratedDate = date
                self.isGenerating = false
            }
            
            return meals
        } catch {
            await MainActor.run { self.isGenerating = false }
            
            // Fallback to demo meals if AI fails
            return getDemoMeals()
        }
    }
    
    private func generateAIMeals(date: Date, goals: NutritionService.NutritionGoals?) async throws -> [Meal] {
        guard let userId = await DatabaseService.shared.getCurrentUserId() else {
            throw NSError(domain: "NutritionAI", code: 401, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])
        }
        
        // Prepare request with user preferences and goals
        var overrides: [String: Any] = [:]
        
        if let goals = goals {
            overrides["target_calories"] = goals.targetCalories ?? 2000
            
            if let macros = goals.targetMacros {
                overrides["target_macros"] = [
                    "protein": macros.protein ?? 150,
                    "carbs": macros.carbs ?? 200,
                    "fat": macros.fat ?? 65,
                    "fiber": macros.fiber ?? 25
                ]
            }
            
            if let prefs = goals.dietPreferences {
                overrides["diet_type"] = prefs.type ?? "balanced"
                overrides["allergies"] = prefs.allergies ?? []
                overrides["intolerances"] = prefs.intolerances ?? []
                overrides["cuisine_preferences"] = prefs.cuisinePreferences ?? []
            }
            
            overrides["exclusions"] = goals.exclusions ?? []
        }
        
        overrides["date"] = date.ISO8601Format()
        overrides["meal_types"] = ["breakfast", "lunch", "dinner", "snack"]
        
        // Call backend AI endpoint
        let response = try await apiClient.generateMealPlan(overrides: overrides)
        
        // Parse response into Meal objects
        guard let mealsData = response["meals"] as? [[String: Any]] else {
            throw NSError(domain: "NutritionAI", code: 500, userInfo: [NSLocalizedDescriptionKey: "Invalid AI response format"])
        }
        
        return mealsData.compactMap { parseMeal(from: $0) }
    }
    
    private func getDemoMeals() -> [Meal] {
        // Fallback demo meals
        return [
            Meal(
                id: UUID(),
                type: .breakfast,
                name: "Greek Yogurt Parfait",
                description: "High-protein parfait with berries and granola",
                calories: 420,
                macros: MacroBreakdown(protein: 30, carbs: 50, fat: 12, fiber: 6),
                ingredients: [],
                instructions: ["Layer yogurt in a bowl", "Top with berries and granola"],
                prepTime: 5,
                cookTime: 0,
                servings: 1,
                difficulty: .beginner,
                tags: ["high_protein", "quick"],
                imageUrl: nil
            ),
            Meal(
                id: UUID(),
                type: .lunch,
                name: "Chicken Rice Bowl",
                description: "Balanced bowl with grilled chicken, rice, veggies",
                calories: 650,
                macros: MacroBreakdown(protein: 45, carbs: 70, fat: 18, fiber: 7),
                ingredients: [],
                instructions: ["Assemble ingredients in a bowl", "Serve warm"],
                prepTime: 10,
                cookTime: 15,
                servings: 1,
                difficulty: .beginner,
                tags: ["balanced", "meal_prep"],
                imageUrl: nil
            ),
            Meal(
                id: UUID(),
                type: .dinner,
                name: "Salmon & Vegetables",
                description: "Omega-3 rich salmon with roasted vegetables",
                calories: 700,
                macros: MacroBreakdown(protein: 42, carbs: 55, fat: 30, fiber: 6),
                ingredients: [],
                instructions: ["Bake salmon at 400°F", "Roast vegetables"],
                prepTime: 10,
                cookTime: 25,
                servings: 1,
                difficulty: .beginner,
                tags: ["omega3", "whole_food"],
                imageUrl: nil
            ),
            Meal(
                id: UUID(),
                type: .snack,
                name: "Apple & Peanut Butter",
                description: "Simple and satisfying snack",
                calories: 250,
                macros: MacroBreakdown(protein: 7, carbs: 24, fat: 14, fiber: 5),
                ingredients: [],
                instructions: ["Slice apple", "Serve with peanut butter"],
                prepTime: 3,
                cookTime: 0,
                servings: 1,
                difficulty: .beginner,
                tags: ["snack", "balanced"],
                imageUrl: nil
            )
        ]
    }
    
    // MARK: - Parsing Helpers
    private func parseMeal(from data: [String: Any]) -> Meal? {
        guard let typeStr = data["type"] as? String,
              let type = MealType(rawValue: typeStr),
              let name = data["name"] as? String,
              let calories = data["calories"] as? Int else {
            return nil
        }
        
        let description = data["description"] as? String ?? ""
        
        // Parse macros
        let macrosData = data["macros"] as? [String: Any] ?? [:]
        let macros = MacroBreakdown(
            protein: Int(macrosData["protein"] as? Double ?? 0),
            carbs: Int(macrosData["carbs"] as? Double ?? 0),
            fat: Int(macrosData["fat"] as? Double ?? 0),
            fiber: Int(macrosData["fiber"] as? Double ?? 0)
        )
        
        // Parse ingredients
        let ingredientsData = data["ingredients"] as? [[String: Any]] ?? []
        let ingredients = ingredientsData.compactMap { parseIngredient(from: $0) }
        
        // Parse instructions
        let instructions = data["instructions"] as? [String] ?? []
        
        return Meal(
            id: UUID(),
            type: type,
            name: name,
            description: description,
            calories: calories,
            macros: macros,
            ingredients: ingredients,
            instructions: instructions,
            prepTime: data["prep_time"] as? Int ?? 10,
            cookTime: data["cook_time"] as? Int ?? 15,
            servings: data["servings"] as? Int ?? 1,
            difficulty: .beginner,
            tags: data["tags"] as? [String] ?? [],
            imageUrl: data["image_url"] as? String
        )
    }
    
    private func parseIngredient(from data: [String: Any]) -> Ingredient? {
        guard let name = data["name"] as? String,
              let amount = data["amount"] as? Double,
              let unit = data["unit"] as? String,
              let calories = data["calories"] as? Int else {
            return nil
        }
        
        let macrosData = data["macros"] as? [String: Any] ?? [:]
        let macros = MacroBreakdown(
            protein: Int(macrosData["protein"] as? Double ?? 0),
            carbs: Int(macrosData["carbs"] as? Double ?? 0),
            fat: Int(macrosData["fat"] as? Double ?? 0),
            fiber: Int(macrosData["fiber"] as? Double ?? 0)
        )
        
        return Ingredient(
            id: UUID(),
            name: name,
            amount: amount,
            unit: unit,
            calories: calories,
            macros: macros,
            isOptional: data["is_optional"] as? Bool ?? false,
            substitutes: data["substitutes"] as? [String] ?? []
        )
    }
    
    // MARK: - Personalized Tips
    func generatePersonalizedTips(summary: NutritionService.NutritionSummary?, goals: NutritionService.NutritionGoals?) async throws -> [NutritionTip] {
        guard let summary = summary, let goals = goals else {
            return getDefaultTips()
        }
        
        var tips: [NutritionTip] = []
        
        // Calculate progress
        let calorieProgress = goals.targetCalories.map { Double(summary.calories) / Double($0) } ?? 0
        let proteinProgress = goals.targetMacros?.protein.map { summary.protein / $0 } ?? 0
        let carbProgress = goals.targetMacros?.carbs.map { summary.carbs / $0 } ?? 0
        let fatProgress = goals.targetMacros?.fat.map { summary.fat / $0 } ?? 0
        
        // Generate contextual tips based on progress
        if calorieProgress < 0.5 && Calendar.current.component(.hour, from: Date()) > 14 {
            tips.append(NutritionTip(
                text: "You're at \(Int(calorieProgress * 100))% of your calorie goal. Consider a nutrient-dense snack to boost energy.",
                type: .suggestion,
                icon: "fork.knife",
                priority: 1
            ))
        }
        
        if proteinProgress < 0.7 {
            let needed = Int((goals.targetMacros?.protein ?? 150) - summary.protein)
            tips.append(NutritionTip(
                text: "Add \(needed)g more protein to reach your daily goal. Try Greek yogurt, lean meats, or a protein shake.",
                type: .suggestion,
                icon: "target",
                priority: 2
            ))
        } else if proteinProgress >= 0.9 {
            tips.append(NutritionTip(
                text: "Excellent protein intake! You're at \(Int(proteinProgress * 100))% of your goal.",
                type: .positive,
                icon: "checkmark.circle.fill",
                priority: 3
            ))
        }
        
        // Hydration reminder
        if Calendar.current.component(.hour, from: Date()) % 3 == 0 {
            tips.append(NutritionTip(
                text: "Remember to stay hydrated! Aim for 8-10 glasses of water throughout the day.",
                type: .tip,
                icon: "drop.fill",
                priority: 4
            ))
        }
        
        // Meal timing tips
        let hour = Calendar.current.component(.hour, from: Date())
        if hour >= 6 && hour < 9 && summary.mealCount == 0 {
            tips.append(NutritionTip(
                text: "Start your day with a balanced breakfast to fuel your morning.",
                type: .suggestion,
                icon: "sunrise.fill",
                priority: 1
            ))
        }
        
        // Fiber tip
        if let fiberGoal = goals.targetMacros?.fiber, summary.fiber < fiberGoal * 0.5 {
            tips.append(NutritionTip(
                text: "Increase fiber intake with whole grains, fruits, and vegetables for better digestion.",
                type: .tip,
                icon: "leaf.fill",
                priority: 5
            ))
        }
        
        // Sort by priority and take top 3
        tips.sort { $0.priority < $1.priority }
        let topTips = Array(tips.prefix(3))
        
        await MainActor.run {
            self.personalizedTips = topTips
        }
        
        return topTips
    }
    
    private func getDefaultTips() -> [NutritionTip] {
        return [
            NutritionTip(
                text: "Track your meals consistently for better insights into your nutrition.",
                type: .tip,
                icon: "pencil.circle",
                priority: 1
            ),
            NutritionTip(
                text: "Focus on whole foods and minimize processed items for optimal health.",
                type: .tip,
                icon: "leaf.fill",
                priority: 2
            ),
            NutritionTip(
                text: "Stay hydrated throughout the day for better energy and focus.",
                type: .tip,
                icon: "drop.fill",
                priority: 3
            )
        ]
    }
    
    // MARK: - Database Helpers
    private func fetchSavedSuggestions(for date: Date) async -> [Meal]? {
        guard let userId = await DatabaseService.shared.getCurrentUserId() else { return nil }
        
        let dateString = date.ISO8601Format().split(separator: "T")[0]
        
        do {
            let response = try await supabase
                .from("ai_meal_suggestions")
                .select()
                .eq("user_id", value: userId)
                .eq("date", value: dateString)
                .single()
                .execute()
            
            if let data = response.data,
               let result = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let mealsData = result["meals"] as? [[String: Any]] {
                return mealsData.compactMap { parseMeal(from: $0) }
            }
        } catch {
            // No saved suggestions, will generate new ones
        }
        
        return nil
    }
    
    private func saveSuggestions(_ meals: [Meal], for date: Date) async {
        guard let userId = await DatabaseService.shared.getCurrentUserId() else { return }
        
        let dateString = date.ISO8601Format().split(separator: "T")[0]
        
        let mealsData = meals.map { meal in
            [
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
                "ingredients": meal.ingredients.map { ing in
                    [
                        "name": ing.name,
                        "amount": ing.amount,
                        "unit": ing.unit,
                        "calories": ing.calories,
                        "macros": [
                            "protein": ing.macros.protein,
                            "carbs": ing.macros.carbs,
                            "fat": ing.macros.fat,
                            "fiber": ing.macros.fiber
                        ]
                    ]
                },
                "instructions": meal.instructions,
                "prep_time": meal.prepTime,
                "cook_time": meal.cookTime,
                "tags": meal.tags
            ] as [String : Any]
        }
        
        let suggestion = [
            "user_id": userId.uuidString,
            "date": dateString,
            "meals": mealsData,
            "provider": "grok"
        ] as [String : Any]
        
        _ = try? await supabase
            .from("ai_meal_suggestions")
            .upsert(suggestion)
            .execute()
    }
    
    // MARK: - Weekly Meal Plan
    func generateWeeklyMealPlan(goals: NutritionService.NutritionGoals?) async throws -> MealPlan {
        await MainActor.run { self.isGenerating = true }
        
        do {
            // Prepare comprehensive request
            var overrides: [String: Any] = [:]
            
            if let goals = goals {
                overrides["target_calories"] = goals.targetCalories ?? 2000
                
                if let macros = goals.targetMacros {
                    overrides["macro_breakdown"] = [
                        "protein": Int(macros.protein ?? 150),
                        "carbs": Int(macros.carbs ?? 200),
                        "fat": Int(macros.fat ?? 65),
                        "fiber": Int(macros.fiber ?? 25)
                    ]
                }
                
                if let prefs = goals.dietPreferences {
                    overrides["diet_preferences"] = [
                        "type": prefs.type ?? "balanced",
                        "allergies": prefs.allergies ?? [],
                        "intolerances": prefs.intolerances ?? [],
                        "cuisines": prefs.cuisinePreferences ?? []
                    ]
                }
            }
            
            overrides["duration"] = "weekly"
            overrides["include_shopping_list"] = true
            overrides["include_prep_instructions"] = true
            
            let response = try await apiClient.generateMealPlan(overrides: overrides)
            
            // Parse the response into a MealPlan
            let plan = try parseMealPlan(from: response)
            
            await MainActor.run {
                self.weeklyMealPlan = plan
                self.isGenerating = false
            }
            
            return plan
        } catch {
            await MainActor.run { self.isGenerating = false }
            throw error
        }
    }
    
    private func parseMealPlan(from response: [String: Any]) -> MealPlan throws {
        guard let plan = response["plan"] as? [String: Any] else {
            // Try direct response format
            let title = response["title"] as? String ?? "Weekly Meal Plan"
            let description = response["description"] as? String ?? "AI-generated meal plan"
            let targetCalories = response["target_calories"] as? Int ?? 2000
            
            // Parse macro breakdown
            let macroData = response["macro_breakdown"] as? [String: Any] ?? [:]
            let macros = MacroBreakdown(
                protein: macroData["protein"] as? Int ?? 150,
                carbs: macroData["carbs"] as? Int ?? 200,
                fat: macroData["fat"] as? Int ?? 65,
                fiber: macroData["fiber"] as? Int ?? 25
            )
            
            // Parse meals
            let mealsData = response["meals"] as? [[String: Any]] ?? []
            let meals = mealsData.compactMap { parseMeal(from: $0) }
            
            // Parse shopping list
            let shoppingList = response["shopping_list"] as? [String] ?? []
            
            return MealPlan(
                id: UUID(),
                userId: UUID(), // Will be set when saving
                title: title,
                description: description,
                targetCalories: targetCalories,
                macroBreakdown: macros,
                meals: meals,
                shoppingList: shoppingList,
                prepTime: response["prep_time"] as? Int ?? 120,
                aiGeneratedNotes: response["ai_generated_notes"] as? String,
                createdAt: Date(),
                updatedAt: Date()
            )
        }
        
        // Parse nested plan format
        let title = plan["title"] as? String ?? "Weekly Meal Plan"
        let description = plan["description"] as? String ?? "AI-generated meal plan"
        let targetCalories = plan["target_calories"] as? Int ?? 2000
        
        // Parse macro breakdown
        let macroData = plan["macro_breakdown"] as? [String: Any] ?? [:]
        let macros = MacroBreakdown(
            protein: macroData["protein"] as? Int ?? 150,
            carbs: macroData["carbs"] as? Int ?? 200,
            fat: macroData["fat"] as? Int ?? 65,
            fiber: macroData["fiber"] as? Int ?? 25
        )
        
        // Parse meals
        let mealsData = plan["meals"] as? [[String: Any]] ?? []
        let meals = mealsData.compactMap { parseMeal(from: $0) }
        
        // Parse shopping list
        let shoppingList = plan["shopping_list"] as? [String] ?? []
        
        return MealPlan(
            id: UUID(),
            userId: UUID(), // Will be set when saving
            title: title,
            description: description,
            targetCalories: targetCalories,
            macroBreakdown: macros,
            meals: meals,
            shoppingList: shoppingList,
            prepTime: plan["prep_time"] as? Int ?? 120,
            aiGeneratedNotes: plan["ai_generated_notes"] as? String,
            createdAt: Date(),
            updatedAt: Date()
        )
    }
    
    // MARK: - Diet Analysis
    func analyzeDiet(recentMeals: [NutritionService.MealLog], goals: NutritionService.NutritionGoals?) async throws -> DietAnalysis {
        // Prepare data for AI analysis
        let mealData = recentMeals.map { log in
            [
                "date": log.loggedAt.ISO8601Format(),
                "type": log.mealType,
                "totals": [
                    "calories": log.totals.calories,
                    "protein": log.totals.protein,
                    "carbs": log.totals.carbs,
                    "fat": log.totals.fat,
                    "fiber": log.totals.fiber ?? 0
                ]
            ]
        }
        
        let request: [String: Any] = [
            "action": "analyze_diet",
            "meals": mealData,
            "goals": [
                "calories": goals?.targetCalories ?? 2000,
                "protein": goals?.targetMacros?.protein ?? 150,
                "carbs": goals?.targetMacros?.carbs ?? 200,
                "fat": goals?.targetMacros?.fat ?? 65,
                "fiber": goals?.targetMacros?.fiber ?? 25
            ],
            "preferences": goals?.dietPreferences ?? [:]
        ]
        
        let response = try await apiClient.sendRequest(endpoint: "/ai/nutrition-analysis", body: request)
        
        guard let analysis = response["analysis"] as? [String: Any] else {
            // Fallback to basic analysis
            return DietAnalysis(
                summary: "Based on your recent meals, you're making good progress toward your nutrition goals.",
                strengths: ["Consistent meal tracking", "Balanced macronutrient distribution"],
                improvements: ["Consider adding more fiber-rich foods", "Increase water intake"],
                recommendations: ["Try meal prepping on Sundays", "Add more colorful vegetables to meals"],
                score: 75,
                generatedAt: Date()
            )
        }
        
        let dietAnalysis = DietAnalysis(
            summary: analysis["summary"] as? String ?? "No analysis available",
            strengths: analysis["strengths"] as? [String] ?? [],
            improvements: analysis["improvements"] as? [String] ?? [],
            recommendations: analysis["recommendations"] as? [String] ?? [],
            score: analysis["score"] as? Int ?? 0,
            generatedAt: Date()
        )
        
        await MainActor.run {
            self.dietAnalysis = dietAnalysis
        }
        
        return dietAnalysis
    }
}
