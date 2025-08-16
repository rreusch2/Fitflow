//  NutritionService.swift
//  Flowmate
//
//  Complete nutrition tracking service with Supabase integration

import Foundation
import Combine
import Supabase

final class NutritionService: ObservableObject {
    static let shared = NutritionService()
    private let supabase = DatabaseService.shared.client
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Models
    struct NutritionGoals: Codable {
        var targetCalories: Int?
        var targetMacros: TargetMacros?
        var dietPreferences: DietPreferences?
        var exclusions: [String]?
        var optInDailyAI: Bool = true
        var preferredAITimeLocal: String? // "08:00" format
        var preferredTimezone: String?
        
        struct TargetMacros: Codable {
            var protein: Double?
            var carbs: Double?
            var fat: Double?
            var fiber: Double?
        }
        
        struct DietPreferences: Codable {
            var type: String? // vegan, vegetarian, keto, paleo, etc.
            var allergies: [String]?
            var intolerances: [String]?
            var cuisinePreferences: [String]?
        }
    }
    
    struct NutritionSummary {
        var calories: Double
        var protein: Double
        var carbs: Double
        var fat: Double
        var fiber: Double
        var mealCount: Int
        var date: Date
    }
    
    struct MealLog: Codable {
        let id: UUID
        let userId: UUID
        let loggedAt: Date
        let mealType: String
        let items: [LoggedItem]
        let totals: MacroTotals
        let source: String
        let notes: String?
        
        struct LoggedItem: Codable {
            let name: String
            let brand: String?
            let amount: Double
            let unit: String
            let calories: Int
            let macros: MacroTotals
        }
        
        struct MacroTotals: Codable {
            let calories: Int
            let protein: Double
            let carbs: Double
            let fat: Double
            let fiber: Double?
        }
    }
    
    struct QuickAddFood: Codable {
        let name: String
        let brand: String?
        let barcode: String?
        let calories: Int
        let serving: String
        let macros: MacroBreakdown
    }
    
    // MARK: - Published Properties
    @Published var goals: NutritionGoals?
    @Published var todaySummary: NutritionSummary?
    @Published var weekSummary: [NutritionSummary] = []
    @Published var recentMeals: [MealLog] = []
    @Published var savedFoods: [QuickAddFood] = []
    @Published var isLoading = false
    @Published var error: Error?
    
    private init() {
        setupRealtimeSubscriptions()
    }
    
    // MARK: - Goals Management
    func fetchGoals() async {
        guard let userId = await DatabaseService.shared.getCurrentUserId() else { return }
        
        do {
            let response = try await supabase
                .from("nutrition_goals")
                .select()
                .eq("user_id", value: userId)
                .single()
                .execute()
            
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            
            if let data = response.data {
                let goals = try decoder.decode(NutritionGoals.self, from: data)
                await MainActor.run {
                    self.goals = goals
                }
            }
        } catch {
            print("Error fetching nutrition goals: \(error)")
            // Set default goals if none exist
            await MainActor.run {
                self.goals = NutritionGoals(
                    targetCalories: 2000,
                    targetMacros: .init(protein: 150, carbs: 200, fat: 65, fiber: 25)
                )
            }
        }
    }
    
    func updateGoals(_ goals: NutritionGoals) async throws {
        guard let userId = await DatabaseService.shared.getCurrentUserId() else { return }
        
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        let goalsData = try encoder.encode(goals)
        
        _ = try await supabase
            .from("nutrition_goals")
            .upsert(goalsData)
            .eq("user_id", value: userId)
            .execute()
        
        await MainActor.run {
            self.goals = goals
        }
    }
    
    // MARK: - Meal Logging
    func logMeal(mealType: MealType, items: [Ingredient], source: String = "manual", notes: String? = nil) async throws -> Bool {
        guard let userId = await DatabaseService.shared.getCurrentUserId() else { return false }
        
        let loggedItems = items.map { ingredient in
            MealLog.LoggedItem(
                name: ingredient.name,
                brand: nil,
                amount: ingredient.amount,
                unit: ingredient.unit,
                calories: ingredient.calories,
                macros: MealLog.MacroTotals(
                    calories: ingredient.calories,
                    protein: Double(ingredient.macros.protein),
                    carbs: Double(ingredient.macros.carbs),
                    fat: Double(ingredient.macros.fat),
                    fiber: Double(ingredient.macros.fiber)
                )
            )
        }
        
        let totalCalories = items.reduce(0) { $0 + $1.calories }
        let totalProtein = items.reduce(0.0) { $0 + Double($1.macros.protein) }
        let totalCarbs = items.reduce(0.0) { $0 + Double($1.macros.carbs) }
        let totalFat = items.reduce(0.0) { $0 + Double($1.macros.fat) }
        let totalFiber = items.reduce(0.0) { $0 + Double($1.macros.fiber) }
        
        let mealLog = [
            "user_id": userId.uuidString,
            "meal_type": mealType.rawValue,
            "items": loggedItems.map { item in
                [
                    "name": item.name,
                    "brand": item.brand ?? "",
                    "amount": item.amount,
                    "unit": item.unit,
                    "calories": item.calories,
                    "macros": [
                        "calories": item.macros.calories,
                        "protein": item.macros.protein,
                        "carbs": item.macros.carbs,
                        "fat": item.macros.fat,
                        "fiber": item.macros.fiber ?? 0
                    ]
                ] as [String : Any]
            },
            "totals": [
                "calories": totalCalories,
                "protein": totalProtein,
                "carbs": totalCarbs,
                "fat": totalFat,
                "fiber": totalFiber
            ],
            "source": source,
            "notes": notes ?? ""
        ] as [String : Any]
        
        _ = try await supabase
            .from("meal_logs")
            .insert(mealLog)
            .execute()
        
        // Refresh today's summary
        await fetchTodaySummary()
        
        return true
    }
    
    func logQuickFood(_ food: QuickAddFood, mealType: MealType) async throws {
        let ingredient = Ingredient(
            id: UUID(),
            name: food.name,
            amount: 1,
            unit: food.serving,
            calories: food.calories,
            macros: food.macros,
            isOptional: false,
            substitutes: []
        )
        
        _ = try await logMeal(mealType: mealType, items: [ingredient], source: "quick_add")
    }
    
    // MARK: - Summary & Analytics
    func fetchTodaySummary() async {
        guard let userId = await DatabaseService.shared.getCurrentUserId() else { return }
        
        let today = Date()
        let startOfDay = Calendar.current.startOfDay(for: today)
        let endOfDay = Calendar.current.date(byAdding: .day, value: 1, to: startOfDay)!
        
        do {
            let response = try await supabase
                .from("meal_logs")
                .select("totals")
                .eq("user_id", value: userId)
                .gte("logged_at", value: startOfDay.ISO8601Format())
                .lt("logged_at", value: endOfDay.ISO8601Format())
                .execute()
            
            if let data = response.data {
                let logs = try JSONSerialization.jsonObject(with: data) as? [[String: Any]] ?? []
                
                var totalCalories = 0.0
                var totalProtein = 0.0
                var totalCarbs = 0.0
                var totalFat = 0.0
                var totalFiber = 0.0
                
                for log in logs {
                    if let totals = log["totals"] as? [String: Any] {
                        totalCalories += (totals["calories"] as? Double) ?? 0
                        totalProtein += (totals["protein"] as? Double) ?? 0
                        totalCarbs += (totals["carbs"] as? Double) ?? 0
                        totalFat += (totals["fat"] as? Double) ?? 0
                        totalFiber += (totals["fiber"] as? Double) ?? 0
                    }
                }
                
                await MainActor.run {
                    self.todaySummary = NutritionSummary(
                        calories: totalCalories,
                        protein: totalProtein,
                        carbs: totalCarbs,
                        fat: totalFat,
                        fiber: totalFiber,
                        mealCount: logs.count,
                        date: today
                    )
                }
            }
        } catch {
            print("Error fetching today's summary: \(error)")
        }
    }
    
    func getSummary(start: Date, end: Date) async throws -> NutritionSummary? {
        guard let userId = await DatabaseService.shared.getCurrentUserId() else { return nil }
        
        let response = try await supabase
            .from("meal_logs")
            .select("totals")
            .eq("user_id", value: userId)
            .gte("logged_at", value: start.ISO8601Format())
            .lte("logged_at", value: end.ISO8601Format())
            .execute()
        
        if let data = response.data {
            let logs = try JSONSerialization.jsonObject(with: data) as? [[String: Any]] ?? []
            
            var totalCalories = 0.0
            var totalProtein = 0.0
            var totalCarbs = 0.0
            var totalFat = 0.0
            var totalFiber = 0.0
            
            for log in logs {
                if let totals = log["totals"] as? [String: Any] {
                    totalCalories += (totals["calories"] as? Double) ?? 0
                    totalProtein += (totals["protein"] as? Double) ?? 0
                    totalCarbs += (totals["carbs"] as? Double) ?? 0
                    totalFat += (totals["fat"] as? Double) ?? 0
                    totalFiber += (totals["fiber"] as? Double) ?? 0
                }
            }
            
            return NutritionSummary(
                calories: totalCalories,
                protein: totalProtein,
                carbs: totalCarbs,
                fat: totalFat,
                fiber: totalFiber,
                mealCount: logs.count,
                date: start
            )
        }
        
        return nil
    }
    
    // MARK: - Meal Plans
    func savePlan(for date: Date, meals: [Meal]) async throws -> Bool {
        guard let userId = await DatabaseService.shared.getCurrentUserId() else { return false }
        
        let mealPlanDay = [
            "user_id": userId.uuidString,
            "date": date.ISO8601Format().split(separator: "T")[0],
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
                    "ingredients": meal.ingredients.map { ing in
                        [
                            "name": ing.name,
                            "amount": ing.amount,
                            "unit": ing.unit,
                            "calories": ing.calories
                        ]
                    }
                ] as [String : Any]
            }
        ] as [String : Any]
        
        _ = try await supabase
            .from("meal_plan_days")
            .upsert(mealPlanDay)
            .execute()
        
        return true
    }
    
    func deleteMealFromPlan(mealId: UUID, date: Date) async throws {
        guard let userId = await DatabaseService.shared.getCurrentUserId() else { return }
        
        // Fetch current plan
        let dateString = date.ISO8601Format().split(separator: "T")[0]
        
        let response = try await supabase
            .from("meal_plan_days")
            .select()
            .eq("user_id", value: userId)
            .eq("date", value: dateString)
            .single()
            .execute()
        
        if let data = response.data,
           var planData = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           var meals = planData["meals"] as? [[String: Any]] {
            
            // Remove the meal with matching ID
            meals.removeAll { meal in
                (meal["id"] as? String) == mealId.uuidString
            }
            
            planData["meals"] = meals
            
            // Update the plan
            _ = try await supabase
                .from("meal_plan_days")
                .update(planData)
                .eq("user_id", value: userId)
                .eq("date", value: dateString)
                .execute()
        }
    }
    
    // MARK: - Food Database
    func searchFoods(query: String) async throws -> [QuickAddFood] {
        // Search in food_items table
        let response = try await supabase
            .from("food_items")
            .select()
            .ilike("name", value: "%\(query)%")
            .limit(20)
            .execute()
        
        if let data = response.data {
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            
            let foods = try JSONSerialization.jsonObject(with: data) as? [[String: Any]] ?? []
            return foods.compactMap { food in
                guard let name = food["name"] as? String,
                      let calories = food["calories"] as? Int else { return nil }
                
                let macros = food["macros"] as? [String: Any] ?? [:]
                
                return QuickAddFood(
                    name: name,
                    brand: food["brand"] as? String,
                    barcode: nil,
                    calories: calories,
                    serving: food["serving"] as? String ?? "1 serving",
                    macros: MacroBreakdown(
                        protein: Int(macros["protein"] as? Double ?? 0),
                        carbs: Int(macros["carbs"] as? Double ?? 0),
                        fat: Int(macros["fat"] as? Double ?? 0),
                        fiber: Int(macros["fiber"] as? Double ?? 0)
                    )
                )
            }
        }
        
        return []
    }
    
    func scanBarcode(_ barcode: String) async throws -> QuickAddFood? {
        // Check barcode index first
        let response = try await supabase
            .from("barcode_index")
            .select("*, food_items(*)")
            .eq("barcode", value: barcode)
            .single()
            .execute()
        
        if let data = response.data,
           let result = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let foodItem = result["food_items"] as? [String: Any],
           let name = foodItem["name"] as? String,
           let calories = foodItem["calories"] as? Int {
            
            let macros = foodItem["macros"] as? [String: Any] ?? [:]
            
            return QuickAddFood(
                name: name,
                brand: foodItem["brand"] as? String,
                barcode: barcode,
                calories: calories,
                serving: foodItem["serving"] as? String ?? "1 serving",
                macros: MacroBreakdown(
                    protein: Int(macros["protein"] as? Double ?? 0),
                    carbs: Int(macros["carbs"] as? Double ?? 0),
                    fat: Int(macros["fat"] as? Double ?? 0),
                    fiber: Int(macros["fiber"] as? Double ?? 0)
                )
            )
        }
        
        // If not found, could call external API here (OpenFoodFacts, etc.)
        return nil
    }
    
    // MARK: - Realtime Updates
    private func setupRealtimeSubscriptions() {
        Task {
            guard let userId = await DatabaseService.shared.getCurrentUserId() else { return }
            
            // Subscribe to meal log changes
            let channel = supabase.channel("nutrition_updates")
            
            channel.on(.postgres(.insert, schema: "public", table: "meal_logs", filter: "user_id=eq.\(userId.uuidString)")) { _ in
                Task {
                    await self.fetchTodaySummary()
                }
            }
            
            channel.on(.postgres(.update, schema: "public", table: "meal_logs", filter: "user_id=eq.\(userId.uuidString)")) { _ in
                Task {
                    await self.fetchTodaySummary()
                }
            }
            
            channel.on(.postgres(.delete, schema: "public", table: "meal_logs", filter: "user_id=eq.\(userId.uuidString)")) { _ in
                Task {
                    await self.fetchTodaySummary()
                }
            }
            
            await channel.subscribe()
        }
    }
}
