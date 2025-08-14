//
//  MemoryModels.swift
//  Flowmate
//
//  Created for the AI Coach Memory Feature
//

import Foundation

// MARK: - Memory Category
enum MemoryCategory: String, Codable, CaseIterable {
    case breakthrough = "breakthrough"
    case goalAchieved = "goal_achieved"
    case personalRecord = "personal_record"
    case mindsetShift = "mindset_shift"
    case habitFormed = "habit_formed"
    case milestone = "milestone"
    case insight = "insight"
    case motivation = "motivation"
    case strategy = "strategy"
    case custom = "custom"
    
    var displayName: String {
        switch self {
        case .breakthrough: return "Breakthrough"
        case .goalAchieved: return "Goal Achieved"
        case .personalRecord: return "Personal Record"
        case .mindsetShift: return "Mindset Shift"
        case .habitFormed: return "Habit Formed"
        case .milestone: return "Milestone"
        case .insight: return "Insight"
        case .motivation: return "Motivation"
        case .strategy: return "Strategy"
        case .custom: return "Custom"
        }
    }
    
    var defaultEmoji: String {
        switch self {
        case .breakthrough: return "🚀"
        case .goalAchieved: return "🎯"
        case .personalRecord: return "🏆"
        case .mindsetShift: return "🧠"
        case .habitFormed: return "🔄"
        case .milestone: return "🏁"
        case .insight: return "💡"
        case .motivation: return "🔥"
        case .strategy: return "📋"
        case .custom: return "✨"
        }
    }
    
    var gradientColors: [String] {
        switch self {
        case .breakthrough: return ["#FF6B6B", "#FF8E53"]
        case .goalAchieved: return ["#4ECDC4", "#44A08D"]
        case .personalRecord: return ["#FFD93D", "#FFB347"]
        case .mindsetShift: return ["#6C5CE7", "#A29BFE"]
        case .habitFormed: return ["#00D2FF", "#3A7BD5"]
        case .milestone: return ["#FF4757", "#FF6348"]
        case .insight: return ["#FFA502", "#FF6348"]
        case .motivation: return ["#FF6B9D", "#C44569"]
        case .strategy: return ["#38ADA9", "#78E08F"]
        case .custom: return ["#9B59B6", "#E74C3C"]
        }
    }
}

// MARK: - User Memory
struct UserMemory: Codable, Identifiable {
    let id: UUID
    let userId: UUID
    var title: String
    var content: String
    var category: MemoryCategory
    var tags: [String]
    var context: MemoryContext?
    var emoji: String
    var isFavorite: Bool
    let createdAt: Date
    var updatedAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case title
        case content
        case category
        case tags
        case context
        case emoji
        case isFavorite = "is_favorite"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
    
    init(
        id: UUID = UUID(),
        userId: UUID,
        title: String,
        content: String,
        category: MemoryCategory = .insight,
        tags: [String] = [],
        context: MemoryContext? = nil,
        emoji: String? = nil,
        isFavorite: Bool = false
    ) {
        self.id = id
        self.userId = userId
        self.title = title
        self.content = content
        self.category = category
        self.tags = tags
        self.context = context
        self.emoji = emoji ?? category.defaultEmoji
        self.isFavorite = isFavorite
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}

// MARK: - Memory Context
struct MemoryContext: Codable {
    var workoutPlanId: UUID?
    var mealPlanId: UUID?
    var progressId: UUID?
    var chatSessionId: UUID?
    var originalPrompt: String?
    var aiResponse: String?
    
    enum CodingKeys: String, CodingKey {
        case workoutPlanId = "workout_plan_id"
        case mealPlanId = "meal_plan_id"
        case progressId = "progress_id"
        case chatSessionId = "chat_session_id"
        case originalPrompt = "original_prompt"
        case aiResponse = "ai_response"
    }
}
