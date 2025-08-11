//
//  AIService.swift
//  Fitflow
//
//  Created on 2025-01-13
//

import Foundation
import Combine

@MainActor
class AIService: ObservableObject {
    static let shared = AIService()
    
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var dailyUsageCount = 0
    
    // Lightweight daily feed cache (image-based motivation)
    private var dailyFeedCache: [UUID: [FeedItem]] = [:]
    
    private var cancellables = Set<AnyCancellable>()
    private let cache = AIResponseCache()
    
    // Rate limiting
    private var requestCount = 0
    private var lastRequestTime = Date()
    private let rateLimitWindow: TimeInterval = 60 // 1 minute
    
    private init() {
        loadDailyUsage()
    }
    
    // MARK: - Workout Plan Generation
    
    func generateWorkoutPlan(for user: User) async throws -> WorkoutPlan {
        guard let preferences = user.preferences else {
            throw AIError.missingUserPreferences
        }
        
        try await checkRateLimit(for: user)
        
        let cacheKey = "workout_plan_\(user.id)_\(preferences.fitness.level.rawValue)"
        
        // Check cache first
        if let cachedPlan: WorkoutPlan = cache.get(key: cacheKey) {
            return cachedPlan
        }
        
        isLoading = true
        defer { isLoading = false }
        
        do {
            let prompt = createWorkoutPlanPrompt(preferences: preferences, healthProfile: user.healthProfile)
            let response = try await callAIAPI(prompt: prompt, type: .workoutGeneration)
            let workoutPlan = try parseWorkoutPlanResponse(response, userId: user.id)
            
            // Cache the result
            cache.set(key: cacheKey, value: workoutPlan, ttl: Config.Cache.workoutPlanTTL)
            
            // Update usage tracking
            incrementUsage()
            
            return workoutPlan
            
        } catch {
            errorMessage = handleAIError(error)
            throw error
        }
    }
    
    func generateCustomWorkoutPlan(
        for user: User,
        duration: Int,
        focusAreas: [MuscleGroup],
        equipment: [Equipment],
        difficulty: FitnessLevel
    ) async throws -> WorkoutPlan {
        try await checkRateLimit(for: user)
        
        isLoading = true
        defer { isLoading = false }
        
        do {
            let prompt = createCustomWorkoutPrompt(
                preferences: user.preferences,
                duration: duration,
                focusAreas: focusAreas,
                equipment: equipment,
                difficulty: difficulty
            )
            
            let response = try await callAIAPI(prompt: prompt, type: .workoutGeneration)
            let workoutPlan = try parseWorkoutPlanResponse(response, userId: user.id)
            
            incrementUsage()
            return workoutPlan
            
        } catch {
            errorMessage = handleAIError(error)
            throw error
        }
    }
    
    // MARK: - Meal Plan Generation
    
    func generateMealPlan(for user: User) async throws -> MealPlan {
        guard let preferences = user.preferences else {
            throw AIError.missingUserPreferences
        }
        
        try await checkRateLimit(for: user)
        
        let cacheKey = "meal_plan_\(user.id)_\(preferences.nutrition.calorieGoal.rawValue)"
        
        // Check cache first
        if let cachedPlan: MealPlan = cache.get(key: cacheKey) {
            return cachedPlan
        }
        
        isLoading = true
        defer { isLoading = false }
        
        do {
            let prompt = createMealPlanPrompt(preferences: preferences, healthProfile: user.healthProfile)
            let response = try await callAIAPI(prompt: prompt, type: .mealGeneration)
            let mealPlan = try parseMealPlanResponse(response, userId: user.id)
            
            // Cache the result
            cache.set(key: cacheKey, value: mealPlan, ttl: Config.Cache.mealPlanTTL)
            
            incrementUsage()
            return mealPlan
            
        } catch {
            errorMessage = handleAIError(error)
            throw error
        }
    }
    
    // MARK: - Chat Completion
    
    func generateChatResponse(
        messages: [ChatMessage],
        user: User,
        context: ChatContext = .general
    ) async throws -> String {
        try await checkRateLimit(for: user)
        
        isLoading = true
        defer { isLoading = false }
        
        do {
            let prompt = createChatPrompt(
                messages: messages,
                user: user,
                context: context
            )
            
            let response = try await callAIAPI(prompt: prompt, type: .chatCompletion)
            
            incrementUsage()
            return response
            
        } catch {
            errorMessage = handleAIError(error)
            throw error
        }
    }
    
    // MARK: - Motivational Content
    
    func generateMotivationalMessage(
        for user: User,
        trigger: MotivationTrigger,
        context: [String: Any] = [:]
    ) async throws -> String {
        guard let preferences = user.preferences else {
            throw AIError.missingUserPreferences
        }
        
        try await checkRateLimit(for: user)
        
        let cacheKey = "motivation_\(user.id)_\(trigger.rawValue)_\(Date().timeIntervalSince1970 / 3600)" // Cache per hour
        
        if let cachedMessage: String = cache.get(key: cacheKey) {
            return cachedMessage
        }
        
        isLoading = true
        defer { isLoading = false }
        
        do {
            let prompt = createMotivationPrompt(
                preferences: preferences,
                trigger: trigger,
                context: context
            )
            
            let response = try await callAIAPI(prompt: prompt, type: .motivation)
            
            // Cache for shorter duration
            cache.set(key: cacheKey, value: response, ttl: 3600) // 1 hour
            
            incrementUsage()
            return response
            
        } catch {
            errorMessage = handleAIError(error)
            throw error
        }
    }
    
    // MARK: - Daily Image Motivation (feed)
    
    func generateDailyFeedItems(for user: User, count: Int = 6) async throws -> [FeedItem] {
        try await checkRateLimit(for: user)
        let calendar = Calendar.current
        let todayStart = calendar.startOfDay(for: Date())
        
        // Serve from in-memory cache for this run if available
        if let cached = dailyFeedCache[user.id], let first = cached.first,
           calendar.isDate(first.date, inSameDayAs: todayStart), cached.count >= count {
            return cached
        }
        
        isLoading = true
        defer { isLoading = false }
        
        // Build short, personal prompts for images and captions
        let topics = deriveTopTopics(from: user)
        // Respect tier caps
        let maxItems: Int
        switch user.subscriptionTier {
        case .free: maxItems = min(count, 2)
        case .pro, .lifetime: maxItems = min(count, 10)
        }

        var items: [FeedItem] = []
        for idx in 0..<maxItems {
            let topic = topics[idx % max(1, topics.count)]
            let text = try await generateMotivationalMessage(
                for: user,
                trigger: .goalReminder,
                context: ["topic": topic]
            )
            // Placeholder image URL; backend will replace with generated images later
            let placeholder = "https://picsum.photos/seed/\(user.id.uuidString.prefix(8))\(idx)/1024/1024"
            let item = FeedItem(
                id: UUID(),
                userId: user.id,
                date: todayStart,
                kind: .image,
                title: nil,
                text: text,
                imageUrl: placeholder,
                videoUrl: nil,
                topicTags: [topic],
                style: user.preferences?.motivation.communicationStyle.rawValue,
                createdAt: Date()
            )
            items.append(item)
        }
        
        dailyFeedCache[user.id] = items
        incrementUsage()
        return items
    }
    
    private func deriveTopTopics(from user: User) -> [String] {
        guard let prefs = user.preferences else { return ["mindset"] }
        var topics: [String] = []
        // Seed with requested verticals
        topics.append("mindset")
        topics.append("business")
        topics.append("relationships")
        // Add activity hints
        let activities = prefs.fitness.preferredActivities.map { $0.displayName.lowercased() }
        topics.append(contentsOf: activities.prefix(2))
        return Array(Set(topics))
    }
    
    // MARK: - Progress Analysis
    
    func analyzeProgress(
        entries: [ProgressEntry],
        user: User
    ) async throws -> ProgressAnalysis {
        try await checkRateLimit(for: user)
        
        isLoading = true
        defer { isLoading = false }
        
        do {
            let prompt = createProgressAnalysisPrompt(entries: entries, user: user)
            let response = try await callAIAPI(prompt: prompt, type: .progressAnalysis)
            let analysis = try parseProgressAnalysisResponse(response)
            
            incrementUsage()
            return analysis
            
        } catch {
            errorMessage = handleAIError(error)
            throw error
        }
    }
    
    // MARK: - AI API Communication
    
    private func callAIAPI(prompt: String, type: AIRequestType) async throws -> String {
        // Try Grok API first
        do {
            return try await callGrokAPI(prompt: prompt, type: type)
        } catch {
            // Fallback to OpenAI if Grok fails
            print("Grok API failed, falling back to OpenAI: \(error)")
            return try await callOpenAIAPI(prompt: prompt, type: type)
        }
    }
    
    private func callGrokAPI(prompt: String, type: AIRequestType) async throws -> String {
        let url = URL(string: "\(Config.AI.grokBaseURL)/chat/completions")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(Config.AI.grokAPIKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let requestBody = GrokAPIRequest(
            model: Config.AI.grokModel,
            messages: [
                GrokMessage(role: "system", content: getSystemPrompt(for: type)),
                GrokMessage(role: "user", content: prompt)
            ],
            temperature: getTemperature(for: type),
            maxTokens: getMaxTokens(for: type)
        )
        
        request.httpBody = try JSONEncoder().encode(requestBody)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw AIError.networkError
        }
        
        guard httpResponse.statusCode == 200 else {
            throw AIError.apiError("Grok API returned status code: \(httpResponse.statusCode)")
        }
        
        let apiResponse = try JSONDecoder().decode(GrokAPIResponse.self, from: data)
        
        guard let content = apiResponse.choices.first?.message.content else {
            throw AIError.invalidResponse
        }
        
        return content
    }
    
    private func callOpenAIAPI(prompt: String, type: AIRequestType) async throws -> String {
        let url = URL(string: "\(Config.AI.openAIBaseURL)/chat/completions")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(Config.AI.openAIAPIKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let requestBody = OpenAIAPIRequest(
            model: Config.AI.openAIModel,
            messages: [
                OpenAIMessage(role: "system", content: getSystemPrompt(for: type)),
                OpenAIMessage(role: "user", content: prompt)
            ],
            temperature: getTemperature(for: type),
            maxTokens: getMaxTokens(for: type)
        )
        
        request.httpBody = try JSONEncoder().encode(requestBody)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw AIError.networkError
        }
        
        guard httpResponse.statusCode == 200 else {
            throw AIError.apiError("OpenAI API returned status code: \(httpResponse.statusCode)")
        }
        
        let apiResponse = try JSONDecoder().decode(OpenAIAPIResponse.self, from: data)
        
        guard let content = apiResponse.choices.first?.message.content else {
            throw AIError.invalidResponse
        }
        
        return content
    }
    
    // MARK: - Rate Limiting
    
    private func checkRateLimit(for user: User) async throws {
        let now = Date()
        
        // Reset daily count if it's a new day
        if !Calendar.current.isDate(lastRequestTime, inSameDayAs: now) {
            dailyUsageCount = 0
        }
        
        // Check daily limits
        let dailyLimit = user.subscriptionTier == .free ? Config.AI.freeUserDailyLimit : Config.AI.proUserDailyLimit
        
        if dailyLimit > 0 && dailyUsageCount >= dailyLimit {
            throw AIError.dailyLimitExceeded
        }
        
        // Check rate limiting (requests per minute)
        if now.timeIntervalSince(lastRequestTime) < rateLimitWindow {
            if requestCount >= Config.AI.maxRequestsPerMinute {
                let waitTime = rateLimitWindow - now.timeIntervalSince(lastRequestTime)
                throw AIError.rateLimitExceeded(waitTime: waitTime)
            }
        } else {
            requestCount = 0
        }
        
        requestCount += 1
        lastRequestTime = now
    }
    
    private func incrementUsage() {
        dailyUsageCount += 1
        saveDailyUsage()
    }
    
    private func loadDailyUsage() {
        let today = DateFormatter().string(from: Date())
        let key = "daily_usage_\(today)"
        dailyUsageCount = UserDefaults.standard.integer(forKey: key)
    }
    
    private func saveDailyUsage() {
        let today = DateFormatter().string(from: Date())
        let key = "daily_usage_\(today)"
        UserDefaults.standard.set(dailyUsageCount, forKey: key)
    }
    
    // MARK: - Helper Methods
    
    private func getSystemPrompt(for type: AIRequestType) -> String {
        switch type {
        case .workoutGeneration:
            return """
            You are a certified personal trainer and fitness expert. Generate safe, effective workout plans based on user preferences and fitness level. Always include proper form instructions, safety tips, and modifications. Format your response as valid JSON matching the WorkoutPlan structure.
            """
        case .mealGeneration:
            return """
            You are a registered dietitian and nutrition expert. Create balanced, healthy meal plans that meet the user's dietary requirements and goals. Include accurate nutritional information and practical cooking instructions. Format your response as valid JSON matching the MealPlan structure.
            """
        case .chatCompletion:
            return """
            You are an AI fitness and wellness assistant. Provide helpful, motivating, and accurate information about fitness, nutrition, and wellness. Adapt your communication style to match the user's preferences. Be encouraging but realistic.
            """
        case .motivation:
            return """
            You are a motivational fitness coach. Generate inspiring, personalized messages that encourage users to stay committed to their fitness goals. Match the user's preferred communication style and be authentic.
            """
        case .progressAnalysis:
            return """
            You are a fitness data analyst. Analyze user progress data and provide insights, trends, and recommendations. Be objective but encouraging, highlighting both achievements and areas for improvement.
            """
        }
    }
    
    private func getTemperature(for type: AIRequestType) -> Double {
        switch type {
        case .workoutGeneration, .mealGeneration:
            return 0.3 // More deterministic for structured data
        case .chatCompletion, .motivation:
            return 0.7 // More creative for conversational responses
        case .progressAnalysis:
            return 0.2 // Very deterministic for analysis
        }
    }
    
    private func getMaxTokens(for type: AIRequestType) -> Int {
        switch type {
        case .workoutGeneration:
            return 2000
        case .mealGeneration:
            return 2500
        case .chatCompletion:
            return 1000
        case .motivation:
            return 300
        case .progressAnalysis:
            return 1500
        }
    }
    
    private func handleAIError(_ error: Error) -> String {
        if let aiError = error as? AIError {
            return aiError.localizedDescription
        } else {
            return Config.ErrorMessages.aiServiceError
        }
    }
}

// MARK: - AI Request Types

enum AIRequestType {
    case workoutGeneration
    case mealGeneration
    case chatCompletion
    case motivation
    case progressAnalysis
}

enum ChatContext {
    case general
    case workout
    case nutrition
    case motivation
    case progress
}

// MARK: - AI Errors

enum AIError: LocalizedError {
    case missingUserPreferences
    case dailyLimitExceeded
    case rateLimitExceeded(waitTime: TimeInterval)
    case networkError
    case apiError(String)
    case invalidResponse
    case parsingError(String)
    
    var errorDescription: String? {
        switch self {
        case .missingUserPreferences:
            return "User preferences are required to generate personalized content"
        case .dailyLimitExceeded:
            return "Daily AI usage limit exceeded. Upgrade to Pro for unlimited access."
        case .rateLimitExceeded(let waitTime):
            return "Too many requests. Please wait \(Int(waitTime)) seconds before trying again."
        case .networkError:
            return Config.ErrorMessages.networkError
        case .apiError(let message):
            return "AI service error: \(message)"
        case .invalidResponse:
            return "Invalid response from AI service"
        case .parsingError(let message):
            return "Failed to parse AI response: \(message)"
        }
    }
}

// MARK: - API Request/Response Models

struct GrokAPIRequest: Codable {
    let model: String
    let messages: [GrokMessage]
    let temperature: Double
    let maxTokens: Int
    
    enum CodingKeys: String, CodingKey {
        case model, messages, temperature
        case maxTokens = "max_tokens"
    }
}

struct GrokMessage: Codable {
    let role: String
    let content: String
}

struct GrokAPIResponse: Codable {
    let choices: [GrokChoice]
}

struct GrokChoice: Codable {
    let message: GrokMessage
}

struct OpenAIAPIRequest: Codable {
    let model: String
    let messages: [OpenAIMessage]
    let temperature: Double
    let maxTokens: Int
    
    enum CodingKeys: String, CodingKey {
        case model, messages, temperature
        case maxTokens = "max_tokens"
    }
}

struct OpenAIMessage: Codable {
    let role: String
    let content: String
}

struct OpenAIAPIResponse: Codable {
    let choices: [OpenAIChoice]
}

struct OpenAIChoice: Codable {
    let message: OpenAIMessage
}

// MARK: - Progress Analysis Model

struct ProgressAnalysis: Codable {
    let summary: String
    let trends: [ProgressTrend]
    let achievements: [Achievement]
    let recommendations: [Recommendation]
    let nextGoals: [String]
}

struct ProgressTrend: Codable {
    let metric: String
    let direction: TrendDirection
    let change: Double
    let description: String
}

enum TrendDirection: String, Codable {
    case improving = "improving"
    case declining = "declining"
    case stable = "stable"
}

struct Achievement: Codable {
    let title: String
    let description: String
    let date: Date
    let category: AchievementCategory
}

enum AchievementCategory: String, Codable {
    case workout = "workout"
    case nutrition = "nutrition"
    case consistency = "consistency"
    case milestone = "milestone"
}

struct Recommendation: Codable {
    let title: String
    let description: String
    let priority: RecommendationPriority
    let category: String
}

enum RecommendationPriority: String, Codable {
    case high = "high"
    case medium = "medium"
    case low = "low"
}

// MARK: - AI Response Cache

class AIResponseCache {
    private var cache: [String: CacheItem] = [:]
    private let queue = DispatchQueue(label: "ai.cache.queue", attributes: .concurrent)
    
    func get<T: Codable>(key: String) -> T? {
        return queue.sync {
            guard let item = cache[key],
                  item.expirationDate > Date(),
                  let data = item.data,
                  let object = try? JSONDecoder().decode(T.self, from: data) else {
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
    
    func clear() {
        queue.async(flags: .barrier) {
            self.cache.removeAll()
        }
    }
    
    private struct CacheItem {
        let data: Data
        let expirationDate: Date
    }
}