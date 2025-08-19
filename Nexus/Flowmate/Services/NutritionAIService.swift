//
//  NutritionAIService.swift  
//  Flowmate
//
//  AI-powered nutrition service using backend APIs
//

import Foundation
import Combine

@MainActor
final class NutritionAIService: ObservableObject {
    static let shared = NutritionAIService()
    
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var lastRequestTime: Date?
    
    private let database = DatabaseService.shared
    private var cancellables = Set<AnyCancellable>()
    private let cache = ResponseCache()
    
    private init() {}
    
    // MARK: - Daily Meal Suggestions
    
    func getDailySuggestions(date: Date, goals: NutritionService.NutritionGoals?) async throws -> [Meal] {
        guard let user = database.user else { throw NutritionAIError.userNotAuthenticated }
        
        // Check cache first
        let cacheKey = "daily_suggestions_\(user.id)_\(dateString(from: date))"
        if let cached: [Meal] = cache.get(key: cacheKey) {
            return cached
        }
        
        isLoading = true
        defer { isLoading = false }
        
        do {
            let response = try await callBackendAPI(
                endpoint: "/ai/daily-meal-suggestions",
                body: DailySuggestionsRequest(
                    date: date,
                    goals: goals
                )
            )
            
            let suggestions = try JSONDecoder().decode(DailySuggestionsResponse.self, from: response)
            let meals = suggestions.suggestions.compactMap { $0.toMeal() }
            
            // Cache for 6 hours
            cache.set(key: cacheKey, value: meals, ttl: 21600)
            lastRequestTime = Date()
            
            return meals
            
        } catch {
            throw NutritionAIError.apiError(error.localizedDescription)
        }
    }
    
    // MARK: - Weekly Meal Plan Generation
    
    func generateWeeklyMealPlan(preferences: MealPlanPreferences) async throws -> WeeklyMealPlan {
        guard let user = database.user else { throw NutritionAIError.userNotAuthenticated }
        
        isLoading = true
        defer { isLoading = false }
        
        do {
            let response = try await callBackendAPI(
                endpoint: "/ai/weekly-meal-plan",
                body: WeeklyMealPlanRequest(
                    preferences: preferences,
                    startDate: Date()
                )
            )
            
            let mealPlan = try JSONDecoder().decode(WeeklyMealPlanResponse.self, from: response)
            lastRequestTime = Date()
            
            return mealPlan.toWeeklyMealPlan()
            
        } catch {
            throw NutritionAIError.apiError(error.localizedDescription)
        }
    }
    
    // MARK: - Diet Analysis
    
    func analyzeDiet(days: Int = 7) async throws -> DietAnalysis {
        guard let user = database.user else { throw NutritionAIError.userNotAuthenticated }
        
        isLoading = true
        defer { isLoading = false }
        
        do {
            let response = try await callBackendAPI(
                endpoint: "/ai/analyze-diet",
                body: DietAnalysisRequest(
                    userId: user.id,
                    days: days
                )
            )
            
            let analysis = try JSONDecoder().decode(DietAnalysisResponse.self, from: response)
            lastRequestTime = Date()
            
            return analysis.toDietAnalysis()
            
        } catch {
            throw NutritionAIError.apiError(error.localizedDescription)
        }
    }
    
    // MARK: - Personalized Tips
    
    func getPersonalizedTips() async throws -> [NutritionTip] {
        guard let user = database.user else { throw NutritionAIError.userNotAuthenticated }
        
        // Check cache first (refresh every 4 hours)
        let cacheKey = "nutrition_tips_\(user.id)"
        if let cached: [NutritionTip] = cache.get(key: cacheKey) {
            return cached
        }
        
        isLoading = true
        defer { isLoading = false }
        
        do {
            let response = try await callBackendAPI(
                endpoint: "/ai/nutrition-tips",
                body: PersonalizedTipsRequest(userId: user.id)
            )
            
            let tipsResponse = try JSONDecoder().decode(PersonalizedTipsResponse.self, from: response)
            let tips = tipsResponse.tips.map { $0.toNutritionTip() }
            
            // Cache for 4 hours
            cache.set(key: cacheKey, value: tips, ttl: 14400)
            lastRequestTime = Date()
            
            return tips
            
        } catch {
            throw NutritionAIError.apiError(error.localizedDescription)
        }
    }
    
    // MARK: - Backend API Communication
    
    private func callBackendAPI<T: Codable>(endpoint: String, body: T) async throws -> Data {
        guard let url = URL(string: "\(Config.API.baseURL)\(endpoint)") else {
            throw NutritionAIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Add authentication
        if let token = await database.getAuthToken() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        // Encode body
        request.httpBody = try JSONEncoder().encode(body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NutritionAIError.networkError
        }
        
        guard httpResponse.statusCode == 200 else {
            throw NutritionAIError.apiError("HTTP \(httpResponse.statusCode)")
        }
        
        return data
    }
    
    private func dateString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
}

// MARK: - Data Models

struct MealPlanPreferences {
    let targetCalories: Int?
    let dietType: String?
    let allergies: [String]
    let dislikes: [String]
    let cuisinePreferences: [String]
    let mealCount: Int // meals per day
    let prepTimePreference: Int // max prep time in minutes
}

struct WeeklyMealPlan {
    let id: UUID
    let startDate: Date
    let days: [DayMealPlan]
    let shoppingList: [ShoppingItem]
    let prepNotes: String
    let totalCost: Double?
    
    struct DayMealPlan {
        let date: Date
        let meals: [Meal]
        let dayTotals: MacroBreakdown
    }
    
    struct ShoppingItem {
        let name: String
        let quantity: String
        let category: String
        let estimatedCost: Double?
    }
}

struct DietAnalysis {
    let period: String
    let overview: String
    let macroTrends: MacroTrends
    let insights: [DietInsight]
    let recommendations: [DietRecommendation]
    let score: Int // 1-100
    
    struct MacroTrends {
        let averageCalories: Double
        let proteinTrend: String
        let carbsTrend: String
        let fatTrend: String
        let fiberAverage: Double
    }
    
    struct DietInsight {
        let type: InsightType
        let title: String
        let description: String
        let impact: String // "positive", "negative", "neutral"
    }
    
    struct DietRecommendation {
        let priority: String
        let action: String
        let reason: String
        let expectedBenefit: String
    }
}

struct NutritionTip {
    let id: UUID
    let type: InsightType
    let title: String
    let description: String
    let icon: String
    let priority: String
    let actionable: Bool
}

// MARK: - Request/Response Models

struct DailySuggestionsRequest: Codable {
    let date: Date
    let goals: NutritionService.NutritionGoals?
}

struct DailySuggestionsResponse: Codable {
    let suggestions: [MealSuggestion]
    
    struct MealSuggestion: Codable {
        let id: UUID
        let type: String
        let name: String
        let description: String
        let calories: Int
        let macros: MacroBreakdown
        let ingredients: [Ingredient]
        let instructions: [String]
        let prepTime: Int
        let cookTime: Int
        let tags: [String]
        
        func toMeal() -> Meal? {
            guard let mealType = MealType(rawValue: type) else { return nil }
            
            return Meal(
                id: id,
                type: mealType,
                name: name,
                description: description,
                calories: calories,
                macros: macros,
                ingredients: ingredients,
                instructions: instructions,
                prepTime: prepTime,
                cookTime: cookTime,
                servings: 1,
                difficulty: .beginner,
                tags: tags,
                imageUrl: nil
            )
        }
    }
}

struct WeeklyMealPlanRequest: Codable {
    let preferences: MealPlanPreferences
    let startDate: Date
}

struct WeeklyMealPlanResponse: Codable {
    let id: UUID
    let startDate: Date
    let days: [DayPlan]
    let shoppingList: [ShoppingItem]
    let prepNotes: String
    let totalCost: Double?
    
    struct DayPlan: Codable {
        let date: Date
        let meals: [DailySuggestionsResponse.MealSuggestion]
        let dayTotals: MacroBreakdown
    }
    
    struct ShoppingItem: Codable {
        let name: String
        let quantity: String
        let category: String
        let estimatedCost: Double?
    }
    
    func toWeeklyMealPlan() -> WeeklyMealPlan {
        return WeeklyMealPlan(
            id: id,
            startDate: startDate,
            days: days.compactMap { day in
                guard let meals = day.meals.compactMap({ $0.toMeal() }) as [Meal]? else { return nil }
                return WeeklyMealPlan.DayMealPlan(
                    date: day.date,
                    meals: meals,
                    dayTotals: day.dayTotals
                )
            },
            shoppingList: shoppingList.map {
                WeeklyMealPlan.ShoppingItem(
                    name: $0.name,
                    quantity: $0.quantity,
                    category: $0.category,
                    estimatedCost: $0.estimatedCost
                )
            },
            prepNotes: prepNotes,
            totalCost: totalCost
        )
    }
}

struct DietAnalysisRequest: Codable {
    let userId: UUID
    let days: Int
}

struct DietAnalysisResponse: Codable {
    let period: String
    let overview: String
    let macroTrends: MacroTrendsResponse
    let insights: [InsightResponse]
    let recommendations: [RecommendationResponse]
    let score: Int
    
    struct MacroTrendsResponse: Codable {
        let averageCalories: Double
        let proteinTrend: String
        let carbsTrend: String
        let fatTrend: String
        let fiberAverage: Double
    }
    
    struct InsightResponse: Codable {
        let type: String
        let title: String
        let description: String
        let impact: String
    }
    
    struct RecommendationResponse: Codable {
        let priority: String
        let action: String
        let reason: String
        let expectedBenefit: String
    }
    
    func toDietAnalysis() -> DietAnalysis {
        return DietAnalysis(
            period: period,
            overview: overview,
            macroTrends: DietAnalysis.MacroTrends(
                averageCalories: macroTrends.averageCalories,
                proteinTrend: macroTrends.proteinTrend,
                carbsTrend: macroTrends.carbsTrend,
                fatTrend: macroTrends.fatTrend,
                fiberAverage: macroTrends.fiberAverage
            ),
            insights: insights.map {
                DietAnalysis.DietInsight(
                    type: InsightType(rawValue: $0.type) ?? .tip,
                    title: $0.title,
                    description: $0.description,
                    impact: $0.impact
                )
            },
            recommendations: recommendations.map {
                DietAnalysis.DietRecommendation(
                    priority: $0.priority,
                    action: $0.action,
                    reason: $0.reason,
                    expectedBenefit: $0.expectedBenefit
                )
            },
            score: score
        )
    }
}

struct PersonalizedTipsRequest: Codable {
    let userId: UUID
}

struct PersonalizedTipsResponse: Codable {
    let tips: [TipResponse]
    
    struct TipResponse: Codable {
        let id: UUID
        let type: String
        let title: String
        let description: String
        let icon: String
        let priority: String
        let actionable: Bool
        
        func toNutritionTip() -> NutritionTip {
            return NutritionTip(
                id: id,
                type: InsightType(rawValue: type) ?? .tip,
                title: title,
                description: description,
                icon: icon,
                priority: priority,
                actionable: actionable
            )
        }
    }
}

// MARK: - Response Cache

class ResponseCache {
    private var cache: [String: CacheItem] = [:]
    private let queue = DispatchQueue(label: "nutrition.cache.queue", attributes: .concurrent)
    
    func get<T: Codable>(key: String) -> T? {
        return queue.sync {
            guard let item = cache[key],
                  item.expirationDate > Date(),
                  let object = try? JSONDecoder().decode(T.self, from: item.data) else {
                return nil
            }
            return object
        }
    }
    
    func set<T: Codable>(key: String, value: T, ttl: TimeInterval) {
        queue.async(flags: .barrier) {
            guard let data = try? JSONEncoder().encode(value) else { return }
            let expirationDate = Date().addingTimeInterval(ttl)
            self.cache[key] = CacheItem(data: data, expirationDate: expirationDate)
        }
    }
    
    private struct CacheItem {
        let data: Data
        let expirationDate: Date
    }
}

// MARK: - Errors

enum NutritionAIError: LocalizedError {
    case userNotAuthenticated
    case invalidURL
    case networkError
    case apiError(String)
    case parsingError
    
    var errorDescription: String? {
        switch self {
        case .userNotAuthenticated:
            return "User authentication required"
        case .invalidURL:
            return "Invalid API URL"
        case .networkError:
            return "Network connection error"
        case .apiError(let message):
            return "API error: \(message)"
        case .parsingError:
            return "Failed to parse response"
        }
    }
}
