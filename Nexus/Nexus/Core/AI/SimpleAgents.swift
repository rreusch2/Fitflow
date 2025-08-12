//
//  SimpleAgents.swift
//  Flowmate
//
//  Created on 2025-01-13
//

import Foundation

// MARK: - Simple AI Agent Protocol

protocol SimpleAIAgent {
    var name: String { get }
    var expertise: String { get }
    
    func generateQuickInsight(for user: User) async throws -> String
    func getQuickActions() -> [String]
}

// MARK: - Fitness Agent (Working Version)

class SimpleFitnessAgent: SimpleAIAgent {
    let name = "Fitness Coach"
    let expertise = "Personalized Workouts & Physical Wellness"
    private let aiService = AIService.shared
    
    func generateQuickInsight(for user: User) async throws -> String {
        return try await aiService.generateMotivationalMessage(
            for: user, 
            trigger: .preWorkout
        )
    }
    
    func getQuickActions() -> [String] {
        return [
            "Generate Today's Workout",
            "Nutrition Advice", 
            "Track Progress",
            "Motivation Boost"
        ]
    }
}

// MARK: - Business Agent (Working Version)

class SimpleBusinessAgent: SimpleAIAgent {
    let name = "Business Strategist"
    let expertise = "Growth Strategy & Professional Development"
    private let aiService = AIService.shared
    
    func generateQuickInsight(for user: User) async throws -> String {
        return try await aiService.generateMotivationalMessage(
            for: user, 
            trigger: .goalReminder
        )
    }
    
    func getQuickActions() -> [String] {
        return [
            "Strategic Planning",
            "Market Analysis",
            "Goal Setting",
            "Productivity Tips"
        ]
    }
}

// MARK: - Wealth Agent (Working Version)

class SimpleWealthAgent: SimpleAIAgent {
    let name = "Wealth Advisor" 
    let expertise = "Financial Growth & Investment Strategy"
    private let aiService = AIService.shared
    
    func generateQuickInsight(for user: User) async throws -> String {
        return try await aiService.generateMotivationalMessage(
            for: user, 
            trigger: .goalReminder
        )
    }
    
    func getQuickActions() -> [String] {
        return [
            "Portfolio Review",
            "Investment Ideas",
            "Budget Optimization",
            "Passive Income Strategies"
        ]
    }
}

// MARK: - Mindset Agent (Working Version)

class SimpleMindsetAgent: SimpleAIAgent {
    let name = "Mindset Coach"
    let expertise = "Mental Resilience & Personal Growth"
    private let aiService = AIService.shared
    
    func generateQuickInsight(for user: User) async throws -> String {
        return try await aiService.generateMotivationalMessage(
            for: user, 
            trigger: .morningBoost
        )
    }
    
    func getQuickActions() -> [String] {
        return [
            "Mindful Moment",
            "Goal Reflection", 
            "Stress Relief",
            "Confidence Boost"
        ]
    }
}

// MARK: - Simple Agent Manager

@MainActor
class SimpleAgentManager: ObservableObject {
    static let shared = SimpleAgentManager()
    
    @Published var isLoading = false
    @Published var currentInsight: String?
    
    private let fitnessAgent = SimpleFitnessAgent()
    private let businessAgent = SimpleBusinessAgent()
    private let wealthAgent = SimpleWealthAgent()
    private let mindsetAgent = SimpleMindsetAgent()
    
    private init() {}
    
    func getAgent(for interest: UserInterest) -> SimpleAIAgent {
        switch interest {
        case .fitness: return fitnessAgent
        case .business: return businessAgent
        case .wealth: return wealthAgent
        case .mindset: return mindsetAgent
        default: return mindsetAgent // Default to mindset for other interests
        }
    }
    
    func generateInsight(for interest: UserInterest, user: User) async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            let agent = getAgent(for: interest)
            currentInsight = try await agent.generateQuickInsight(for: user)
        } catch {
            currentInsight = "Ready to transform your \(interest.rawValue) journey! Let's unlock your potential together."
        }
    }
}

// MARK: - AI Quick Action Model

struct AIQuickActionSimple: Identifiable {
    let id = UUID()
    let title: String
    let icon: String
    let color: String
    
    init(title: String, icon: String = "sparkles", color: String = "blue") {
        self.title = title
        self.icon = icon
        self.color = color
    }
}
