//
//  NutritionService.swift
//  Flowmate
//
//  Comprehensive nutrition service with database integration
//

import Foundation
import Combine

@MainActor
final class NutritionService: ObservableObject {
    static let shared = NutritionService()
    
    @Published var goals: NutritionGoals?
    @Published var todaySummary: NutritionSummary?
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private var cancellables = Set<AnyCancellable>()
    private let database = DatabaseService.shared
    private let auth = AuthenticationService.shared
    
    private init() {
        setupObservers()
    }

// DTOs to ensure Codable conformance for nested types
struct MealLogItemDTO: Codable {
    let foodId: UUID?
    let name: String
    let amount: Double
    let unit: String
    let calories: Int
    let macros: MacroBreakdown
    
    enum CodingKeys: String, CodingKey {
        case foodId = "food_id", name, amount, unit, calories, macros
    }
}

struct NutritionTotalsDTO: Codable {
    let calories: Double
    let protein: Double
    let carbs: Double
    let fat: Double
    let fiber: Double
}
    
    private func setupObservers() {
        // Listen for authentication changes
        auth.$currentUser
            .compactMap { $0 }
            .sink { [weak self] _ in
                Task { await self?.loadUserData() }
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Data Models
    
    struct NutritionGoals: Codable {
        var targetCalories: Int?
        var targetMacros: TargetMacros?
        var dietPreferences: DietPreferences?
        var exclusions: [String]
        var optInDailyAI: Bool
        var preferredAITime: Date?
        var timezone: String?
        
        struct TargetMacros: Codable {
            var protein: Double?
            var carbs: Double?
            var fat: Double?
        }
        
        struct DietPreferences: Codable {
            var dietType: String? // "vegetarian", "vegan", "keto", etc.
            var allergies: [String]
            var dislikes: [String]
            var cuisinePreferences: [String]
        }
    }
    
    struct NutritionSummary {
        var calories: Double
        var protein: Double
        var carbs: Double
        var fat: Double
        var fiber: Double
        var sugar: Double
        var sodium: Double
        var mealsLogged: Int
        var lastUpdated: Date
    }
    
    struct MealLog {
        let id: UUID
        let userId: UUID
        let loggedAt: Date
        let mealType: MealType
        let items: [MealLogItem]
        let totals: NutritionTotals
        let source: String
        let notes: String?
        
        struct MealLogItem {
            let foodId: UUID?
            let name: String
            let amount: Double
            let unit: String
            let calories: Int
            let macros: MacroBreakdown
        }
        
        struct NutritionTotals {
            let calories: Double
            let protein: Double
            let carbs: Double
            let fat: Double
            let fiber: Double
        }
    }
    
    // MARK: - Public Methods
    
    func loadUserData() async {
        guard auth.currentUser != nil else { return }
        
        isLoading = true
        defer { isLoading = false }
        
        do {
            async let goalsTask = fetchGoals()
            async let summaryTask = getTodaySummary()
            
            let (goals, summary) = await (goalsTask, summaryTask)
            self.goals = goals
            self.todaySummary = summary
            
        } catch {
            errorMessage = "Failed to load nutrition data: \(error.localizedDescription)"
        }
    }
    
    func fetchGoals() async -> NutritionGoals? {
        guard let user = auth.currentUser else { return nil }
        do {
            let data = try await database.restSelect(
                path: "nutrition_goals",
                query: [
                    URLQueryItem(name: "select", value: "*"),
                    URLQueryItem(name: "user_id", value: "eq.\(user.id.uuidString)"),
                    URLQueryItem(name: "limit", value: "1")
                ]
            )
            let rows = try JSONDecoder().decode([NutritionGoalsResponse].self, from: data)
            if let row = rows.first { return row.toNutritionGoals() }
            return createDefaultGoals(for: user)
        } catch {
            return createDefaultGoals(for: user)
        }
    }
    
    func updateGoals(_ goals: NutritionGoals) async throws {
        guard let user = auth.currentUser else { throw NutritionError.userNotAuthenticated }
        isLoading = true
        defer { isLoading = false }
        let goalsData = NutritionGoalsRequest(from: goals, userId: user.id)
        let encoder = JSONEncoder(); encoder.dateEncodingStrategy = .iso8601
        let body = try encoder.encode([goalsData])
        _ = try await database.restUpsert(path: "nutrition_goals", body: body)
        self.goals = goals
    }
    
    func getTodaySummary() async -> NutritionSummary? {
        return await getSummary(start: Calendar.current.startOfDay(for: Date()), end: Date())
    }
    
    func getSummary(start: Date, end: Date) async -> NutritionSummary? {
        guard let user = auth.currentUser else { return nil }
        do {
            let iso = ISO8601DateFormatter()
            let data = try await database.callRPC(
                "get_nutrition_summary",
                payload: [
                    "user_id": user.id.uuidString,
                    "start_date": iso.string(from: start),
                    "end_date": iso.string(from: end)
                ]
            )
            return try JSONDecoder().decode(NutritionSummaryResponse.self, from: data).toNutritionSummary()
        } catch {
            print("Error fetching nutrition summary: \(error)")
            return nil
        }
    }
    
    func logMeal(mealType: MealType, items: [Ingredient], source: String = "manual", notes: String? = nil) async throws -> Bool {
        guard let user = auth.currentUser else { throw NutritionError.userNotAuthenticated }
        
        isLoading = true
        defer { isLoading = false }
        
        // Calculate totals
        let totals = calculateTotals(from: items)
        
        // Convert ingredients to meal log items
        let logItems = items.map { ingredient in
            MealLogItemDTO(
                foodId: ingredient.id,
                name: ingredient.name,
                amount: ingredient.amount,
                unit: ingredient.unit,
                calories: ingredient.calories,
                macros: ingredient.macros
            )
        }
        
        let mealLogData = MealLogRequest(
            userId: user.id,
            loggedAt: Date(),
            mealType: mealType.rawValue,
            items: logItems,
            totals: NutritionTotalsDTO(
                calories: totals.calories,
                protein: totals.protein,
                carbs: totals.carbs,
                fat: totals.fat,
                fiber: totals.fiber
            ),
            source: source,
            notes: notes
        )
        
        let encoder = JSONEncoder(); encoder.dateEncodingStrategy = .iso8601
        let body = try encoder.encode([mealLogData])
        _ = try await database.restInsert(path: "meal_logs", body: body)
        
        // Refresh today's summary
        todaySummary = await getTodaySummary()
        
        return true
    }
    
    func savePlan(for date: Date, meals: [Meal]) async throws -> Bool {
        guard let user = auth.currentUser else { throw NutritionError.userNotAuthenticated }
        
        isLoading = true
        defer { isLoading = false }
        
        let mealPlanData = MealPlanDayRequest(
            userId: user.id,
            date: date,
            meals: meals.map { meal in
                MealPlanMeal(
                    id: meal.id,
                    type: meal.type.rawValue,
                    name: meal.name,
                    description: meal.description,
                    calories: meal.calories,
                    macros: meal.macros,
                    ingredients: meal.ingredients
                )
            }
        )
        
        let encoder = JSONEncoder(); encoder.dateEncodingStrategy = .iso8601
        let body = try encoder.encode([mealPlanData])
        _ = try await database.restUpsert(path: "meal_plan_days", body: body)
        
        return true
    }
    
    func getMealPlan(for date: Date) async -> [Meal]? {
        guard let user = auth.currentUser else { return nil }
        
        do {
            let df = DateFormatter(); df.dateFormat = "yyyy-MM-dd"
            let data = try await database.restSelect(
                path: "meal_plan_days",
                query: [
                    URLQueryItem(name: "select", value: "meals"),
                    URLQueryItem(name: "user_id", value: "eq.\(user.id.uuidString)"),
                    URLQueryItem(name: "date", value: "eq.\(df.string(from: date))"),
                    URLQueryItem(name: "limit", value: "1")
                ]
            )
            let rows = try JSONDecoder().decode([MealPlanDayResponse].self, from: data)
            guard let mealPlanResponse = rows.first else { return [] }
            return mealPlanResponse.meals.compactMap { $0.toMeal() }
            
        } catch {
            print("Error fetching meal plan: \(error)")
            return nil
        }
    }
    
    func searchFoodItems(query: String) async -> [FoodItem] {
        guard let user = auth.currentUser else { return [] }
        do {
            let data = try await database.restSelect(
                path: "food_items",
                query: [
                    URLQueryItem(name: "select", value: "*"),
                    URLQueryItem(name: "or", value: "name.ilike.%\(query)%,brand.ilike.%\(query)%"),
                    URLQueryItem(name: "or", value: "user_id.is.null,user_id.eq.\(user.id.uuidString)"),
                    URLQueryItem(name: "limit", value: "20")
                ]
            )
            return try JSONDecoder().decode([FoodItemResponse].self, from: data).map { $0.toFoodItem() }
        } catch {
            print("Error searching food items: \(error)")
            return []
        }
    }
    
    // MARK: - Private Methods
    
    private func createDefaultGoals(for user: User) -> NutritionGoals {
        // Calculate basic TDEE-based goals
        let baseCalories = calculateBaseTDEE(for: user)
        let protein = Double(baseCalories) * 0.3 / 4 // 30% of calories from protein
        let carbs = Double(baseCalories) * 0.4 / 4 // 40% from carbs
        let fat = Double(baseCalories) * 0.3 / 9 // 30% from fat
        
        return NutritionGoals(
            targetCalories: baseCalories,
            targetMacros: NutritionGoals.TargetMacros(
                protein: protein,
                carbs: carbs,
                fat: fat
            ),
            dietPreferences: nil,
            exclusions: [],
            optInDailyAI: true,
            preferredAITime: nil,
            timezone: TimeZone.current.identifier
        )
    }
    
    private func calculateBaseTDEE(for user: User) -> Int {
        // Simple TDEE calculation - can be enhanced with health profile data
        return user.preferences?.fitness.level == .beginner ? 2000 : 2200
    }
    
    private func calculateTotals(from items: [Ingredient]) -> MealLog.NutritionTotals {
        let calories = items.reduce(0.0) { $0 + Double($1.calories) }
        let protein = items.reduce(0.0) { $0 + Double($1.macros.protein) }
        let carbs = items.reduce(0.0) { $0 + Double($1.macros.carbs) }
        let fat = items.reduce(0.0) { $0 + Double($1.macros.fat) }
        let fiber = items.reduce(0.0) { $0 + Double($1.macros.fiber) }
        
        return MealLog.NutritionTotals(
            calories: calories,
            protein: protein,
            carbs: carbs,
            fat: fat,
            fiber: fiber
        )
    }
}

// MARK: - Data Transfer Objects

struct NutritionGoalsResponse: Codable {
    let targetCalories: Int?
    let targetMacros: [String: Double]?
    let dietPreferences: [String: String]?
    let exclusions: [String]?
    let optInDailyAI: Bool?
    let preferredAITimeLocal: String?
    let preferredTimezone: String?
    
    enum CodingKeys: String, CodingKey {
        case targetCalories = "target_calories"
        case targetMacros = "target_macros"
        case dietPreferences = "diet_preferences"
        case exclusions
        case optInDailyAI = "opt_in_daily_ai"
        case preferredAITimeLocal = "preferred_ai_time_local"
        case preferredTimezone = "preferred_timezone"
    }
    
    func toNutritionGoals() -> NutritionService.NutritionGoals {
        let macros = targetMacros.map {
            NutritionService.NutritionGoals.TargetMacros(
                protein: $0["protein"],
                carbs: $0["carbs"],
                fat: $0["fat"]
            )
        }
        
        return NutritionService.NutritionGoals(
            targetCalories: targetCalories,
            targetMacros: macros,
            dietPreferences: nil, // TODO: Parse diet preferences JSON
            exclusions: exclusions ?? [],
            optInDailyAI: optInDailyAI ?? true,
            preferredAITime: nil, // TODO: Parse time string
            timezone: preferredTimezone
        )
    }
}

struct NutritionGoalsRequest: Codable {
    let userId: UUID
    let targetCalories: Int?
    let targetMacros: [String: Double]?
    let dietPreferences: [String: String]
    let exclusions: [String]
    let optInDailyAI: Bool
    let preferredAITimeLocal: String?
    let preferredTimezone: String?
    
    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case targetCalories = "target_calories"
        case targetMacros = "target_macros"
        case dietPreferences = "diet_preferences"
        case exclusions
        case optInDailyAI = "opt_in_daily_ai"
        case preferredAITimeLocal = "preferred_ai_time_local"
        case preferredTimezone = "preferred_timezone"
    }
    
    init(from goals: NutritionService.NutritionGoals, userId: UUID) {
        self.userId = userId
        self.targetCalories = goals.targetCalories
        self.targetMacros = goals.targetMacros.map { macros in
            return [
                "protein": macros.protein ?? 0,
                "carbs": macros.carbs ?? 0,
                "fat": macros.fat ?? 0
            ]
        }
        self.dietPreferences = [:] // TODO: Convert diet preferences
        self.exclusions = goals.exclusions
        self.optInDailyAI = goals.optInDailyAI
        self.preferredAITimeLocal = nil // TODO: Convert time to string
        self.preferredTimezone = goals.timezone
    }
}


struct NutritionSummaryResponse: Codable {
    let calories: Double
    let protein: Double
    let carbs: Double
    let fat: Double
    let fiber: Double
    let sugar: Double
    let sodium: Double
    let mealsLogged: Int
    let lastUpdated: String
    
    enum CodingKeys: String, CodingKey {
        case calories, protein, carbs, fat, fiber, sugar, sodium
        case mealsLogged = "meals_logged"
        case lastUpdated = "last_updated"
    }
    
    func toNutritionSummary() -> NutritionService.NutritionSummary {
        let formatter = ISO8601DateFormatter()
        let lastUpdate = formatter.date(from: lastUpdated) ?? Date()
        
        return NutritionService.NutritionSummary(
            calories: calories,
            protein: protein,
            carbs: carbs,
            fat: fat,
            fiber: fiber,
            sugar: sugar,
            sodium: sodium,
            mealsLogged: mealsLogged,
            lastUpdated: lastUpdate
        )
    }
}

struct MealLogRequest: Codable {
    let userId: UUID
    let loggedAt: Date
    let mealType: String
    let items: [NutritionService.MealLogItemDTO]
    let totals: NutritionService.NutritionTotalsDTO
    let source: String
    let notes: String?
    
    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case loggedAt = "logged_at"
        case mealType = "meal_type"
        case items, totals, source, notes
    }
}

struct MealPlanDayRequest: Codable {
    let userId: UUID
    let date: Date
    let meals: [MealPlanMeal]
    
    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case date, meals
    }
}

struct MealPlanMeal: Codable {
    let id: UUID
    let type: String
    let name: String
    let description: String?
    let calories: Int
    let macros: MacroBreakdown
    let ingredients: [Ingredient]
    
    func toMeal() -> Meal? {
        guard let mealType = MealType(rawValue: type) else { return nil }
        
        return Meal(
            id: id,
            type: mealType,
            name: name,
            description: description ?? "",
            calories: calories,
            macros: macros,
            ingredients: ingredients,
            instructions: [],
            prepTime: 0,
            cookTime: 0,
            servings: 1,
            difficulty: .beginner,
            tags: [],
            imageUrl: nil
        )
    }
}

struct MealPlanDayResponse: Codable {
    let meals: [MealPlanMeal]
}

// NOTE: FoodItem is defined in shared models. Avoid redefining here to prevent type conflicts.

struct FoodItemResponse: Codable {
    let id: UUID
    let name: String
    let brand: String?
    let serving: String
    let calories: Int
    let macros: [String: Double]
    let tags: [String]
    let isPublic: Bool
    let source: String?
    
    enum CodingKeys: String, CodingKey {
        case id, name, brand, serving, calories, macros, tags, source
        case isPublic = "is_public"
    }
    
    func toFoodItem() -> FoodItem {
        let macroBreakdown = MacroBreakdown(
            protein: Int(macros["protein"] ?? 0),
            carbs: Int(macros["carbs"] ?? 0),
            fat: Int(macros["fat"] ?? 0),
            fiber: Int(macros["fiber"] ?? 0)
        )
        // Map API model to shared FoodItem (fill unknowns with sensible defaults)
        return FoodItem(
            id: id,
            name: name,
            brand: brand,
            calories: calories, // per 100g
            macros: macroBreakdown,
            micronutrients: nil,
            servingSize: 100.0,
            servingSizeUnit: "g",
            barcode: nil,
            verified: false,
            createdAt: Date(),
            updatedAt: Date()
        )
    }
}

// MARK: - Errors

enum NutritionError: LocalizedError {
    case userNotAuthenticated
    case invalidMealData
    case networkError
    case databaseError(String)
    
    var errorDescription: String? {
        switch self {
        case .userNotAuthenticated:
            return "User must be authenticated to access nutrition data"
        case .invalidMealData:
            return "Invalid meal data provided"
        case .networkError:
            return "Network error occurred"
        case .databaseError(let message):
            return "Database error: \(message)"
        }
    }
}
