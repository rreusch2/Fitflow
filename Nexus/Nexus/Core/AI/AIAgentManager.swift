//
//  AIAgentManager.swift
//  Flowmate
//
//  Created on 2025-01-13
//

import Foundation
import Combine

@MainActor
class AIAgentManager: ObservableObject {
    static let shared = AIAgentManager()
    
    @Published var isLoading = false
    @Published var error: String?
    
    private let aiService = AIService.shared
    private var cancellables = Set<AnyCancellable>()
    
    private init() {}
    
    // MARK: - Specialized AI Agents
    
    func getFitnessAgent() -> FitnessAIAgent {
        return FitnessAIAgent(aiService: aiService)
    }
    
    func getBusinessAgent() -> BusinessAIAgent {
        return BusinessAIAgent(aiService: aiService)
    }
    
    func getMindsetAgent() -> MindsetAIAgent {
        return MindsetAIAgent(aiService: aiService)
    }
    
    func getWealthAgent() -> WealthAIAgent {
        return WealthAIAgent(aiService: aiService)
    }
    
    func getCreativityAgent() -> CreativityAIAgent {
        return CreativityAIAgent(aiService: aiService)
    }
    
    func getRelationshipsAgent() -> RelationshipsAIAgent {
        return RelationshipsAIAgent(aiService: aiService)
    }
    
    func getLearningAgent() -> LearningAIAgent {
        return LearningAIAgent(aiService: aiService)
    }
    
    func getSpiritualityAgent() -> SpiritualityAIAgent {
        return SpiritualityAIAgent(aiService: aiService)
    }
    
    func getAdventureAgent() -> AdventureAIAgent {
        return AdventureAIAgent(aiService: aiService)
    }
    
    func getLeadershipAgent() -> LeadershipAIAgent {
        return LeadershipAIAgent(aiService: aiService)
    }
    
    func getHealthAgent() -> HealthAIAgent {
        return HealthAIAgent(aiService: aiService)
    }
    
    func getFamilyAgent() -> FamilyAIAgent {
        return FamilyAIAgent(aiService: aiService)
    }
    
    func getCoachAgent() -> CoachAIAgent {
        return CoachAIAgent(aiService: aiService)
    }
    
    // MARK: - Universal Agent Methods
    
    func getAgentForInterest(_ interest: UserInterest) -> any AIAgent {
        switch interest {
        case .fitness: return getFitnessAgent()
        case .business: return getBusinessAgent()
        case .mindset: return getMindsetAgent()
        case .wealth: return getWealthAgent()
        case .creativity: return getCreativityAgent()
        case .relationships: return getRelationshipsAgent()
        case .learning: return getLearningAgent()
        case .spirituality: return getSpiritualityAgent()
        case .adventure: return getAdventureAgent()
        case .leadership: return getLeadershipAgent()
        case .health: return getHealthAgent()
        case .family: return getFamilyAgent()
        }
    }
}

// MARK: - AI Agent Protocol

protocol AIAgent {
    var name: String { get }
    var expertise: String { get }
    var systemPrompt: String { get }
    
    func generatePersonalizedContent(for user: User) async throws -> AIAgentContent
    func getQuickActions(for user: User) -> [AIQuickAction]
    func processUserQuery(_ query: String, for user: User) async throws -> String
}

// MARK: - AI Agent Models

struct AIAgentContent {
    let title: String
    let subtitle: String
    let mainContent: String
    let insights: [AIInsight]
    let recommendations: [AIRecommendation]
    let motivationalMessage: String
}

struct AIInsight {
    let title: String
    let description: String
    let icon: String
    let priority: InsightPriority
}

struct AIRecommendation {
    let title: String
    let description: String
    let actionType: RecommendationType
    let difficulty: DifficultyLevel
}

struct AIQuickAction {
    let title: String
    let description: String
    let icon: String
    let action: () -> Void
}

enum InsightPriority: String, CaseIterable {
    case low = "low"
    case medium = "medium"
    case high = "high"
    case critical = "critical"
}

enum RecommendationType: String, CaseIterable {
    case immediate = "immediate"
    case shortTerm = "short_term"
    case longTerm = "long_term"
    case habit = "habit"
}

enum DifficultyLevel: String, CaseIterable {
    case easy = "easy"
    case medium = "medium"
    case hard = "hard"
    case expert = "expert"
}
