//
//  SpecializedAgents.swift
//  Flowmate
//
//  Created on 2025-01-13
//

import Foundation

// MARK: - Fitness AI Agent

class FitnessAIAgent: AIAgent {
    let name = "Fitness Coach"
    let expertise = "Personalized Workouts, Nutrition, and Physical Wellness"
    private let aiService: AIService
    
    init(aiService: AIService) {
        self.aiService = aiService
    }
    
    var systemPrompt: String {
        return """
        You are an elite Fitness Coach AI specializing in personalized workout plans, nutrition guidance, and physical wellness optimization. 
        
        Your expertise includes:
        - Creating custom workout routines based on user's fitness level, goals, and preferences
        - Providing nutrition advice and meal planning
        - Injury prevention and recovery strategies
        - Motivation and accountability coaching
        - Progress tracking and adaptation
        
        Always consider the user's current fitness level, available equipment, time constraints, and personal goals. 
        Be encouraging, supportive, and scientifically accurate. Provide actionable, specific recommendations.
        """
    }
    
    func generatePersonalizedContent(for user: User) async throws -> AIAgentContent {
        guard let fitnessPrefs = user.preferences?.fitness else {
            throw AIError.missingUserPreferences
        }
        
        let prompt = """
        \(systemPrompt)
        
        User Profile:
        - Fitness Level: \(fitnessPrefs.level.rawValue)
        - Preferred Activities: \(fitnessPrefs.preferredActivities.map(\.rawValue).joined(separator: ", "))
        - Available Equipment: \(fitnessPrefs.availableEquipment.map(\.rawValue).joined(separator: ", "))
        - Workout Duration: \(fitnessPrefs.workoutDuration.rawValue)
        - Workout Frequency: \(fitnessPrefs.workoutFrequency.rawValue)
        
        Generate personalized fitness content including:
        1. Today's workout focus
        2. 3 key fitness insights
        3. 3 actionable recommendations
        4. Motivational message
        """
        
        let response = try await aiService.generateMotivationalMessage(for: user, trigger: .preWorkout)
        return parseAIResponse(response, for: .fitness)
    }
    
    func getQuickActions(for user: User) -> [AIQuickAction] {
        return [
            AIQuickAction(title: "Generate Workout", description: "Create today's custom workout", icon: "figure.run", action: {}),
            AIQuickAction(title: "Meal Plan", description: "Get nutrition recommendations", icon: "fork.knife", action: {}),
            AIQuickAction(title: "Progress Check", description: "Review your fitness journey", icon: "chart.line.uptrend.xyaxis", action: {})
        ]
    }
    
    func processUserQuery(_ query: String, for user: User) async throws -> String {
        let contextualPrompt = """
        \(systemPrompt)
        
        User's Fitness Profile:
        \(getFitnessContext(for: user))
        
        User Question: \(query)
        
        Provide a helpful, personalized response based on their fitness profile and goals.
        """
        
        return try await aiService.callGrokAPI(prompt: contextualPrompt, type: .motivation)
    }
    
    private func getFitnessContext(for user: User) -> String {
        guard let fitnessPrefs = user.preferences?.fitness else { return "No fitness preferences set" }
        
        return """
        Level: \(fitnessPrefs.level.rawValue)
        Activities: \(fitnessPrefs.preferredActivities.map(\.rawValue).joined(separator: ", "))
        Equipment: \(fitnessPrefs.availableEquipment.map(\.rawValue).joined(separator: ", "))
        """
    }
}

// MARK: - Business AI Agent

class BusinessAIAgent: AIAgent {
    let name = "Business Strategist"
    let expertise = "Entrepreneurship, Strategy, and Professional Growth"
    private let aiService: AIService
    
    init(aiService: AIService) {
        self.aiService = aiService
    }
    
    var systemPrompt: String {
        return """
        You are an elite Business Strategist AI specializing in entrepreneurship, business growth, and professional development.
        
        Your expertise includes:
        - Business strategy and planning
        - Market analysis and opportunity identification
        - Leadership and team management
        - Financial planning and revenue optimization
        - Productivity and time management
        - Networking and relationship building
        
        Always provide actionable business insights, practical strategies, and growth-focused recommendations.
        Be direct, results-oriented, and focused on value creation.
        """
    }
    
    func generatePersonalizedContent(for user: User) async throws -> AIAgentContent {
        guard let businessPrefs = user.preferences?.business else {
            throw AIError.missingUserPreferences
        }
        
        let prompt = """
        \(systemPrompt)
        
        User's Business Profile:
        - Focus: \(businessPrefs.focus.rawValue)
        - Work Style: \(businessPrefs.workStyle.rawValue)
        - Weekly Hours: \(businessPrefs.weeklyHours)
        
        Generate personalized business content including:
        1. Today's strategic priority
        2. 3 key business insights
        3. 3 actionable growth recommendations
        4. Motivational business message
        """
        
        let response = try await aiService.callGrokAPI(prompt: prompt, type: .businessPlan)
        return parseAIResponse(response, for: .business)
    }
    
    func getQuickActions(for user: User) -> [AIQuickAction] {
        return [
            AIQuickAction(title: "Strategy Session", description: "Get strategic recommendations", icon: "lightbulb.fill", action: {}),
            AIQuickAction(title: "Market Analysis", description: "Analyze opportunities", icon: "chart.bar.fill", action: {}),
            AIQuickAction(title: "Goal Planning", description: "Set business objectives", icon: "target", action: {})
        ]
    }
    
    func processUserQuery(_ query: String, for user: User) async throws -> String {
        let contextualPrompt = """
        \(systemPrompt)
        
        User's Business Context:
        \(getBusinessContext(for: user))
        
        User Question: \(query)
        
        Provide strategic, actionable business advice tailored to their profile and goals.
        """
        
        return try await aiService.callGrokAPI(prompt: contextualPrompt, type: .businessPlan)
    }
    
    private func getBusinessContext(for user: User) -> String {
        guard let businessPrefs = user.preferences?.business else { return "No business preferences set" }
        
        return """
        Focus: \(businessPrefs.focus.rawValue)
        Work Style: \(businessPrefs.workStyle.rawValue)
        Weekly Hours: \(businessPrefs.weeklyHours)
        """
    }
}

// MARK: - Wealth AI Agent

class WealthAIAgent: AIAgent {
    let name = "Wealth Advisor"
    let expertise = "Financial Growth, Investment Strategy, and Wealth Building"
    private let aiService: AIService
    
    init(aiService: AIService) {
        self.aiService = aiService
    }
    
    var systemPrompt: String {
        return """
        You are an elite Wealth Advisor AI specializing in financial growth, investment strategy, and wealth building.
        
        Your expertise includes:
        - Investment strategy and portfolio optimization
        - Personal finance management and budgeting
        - Passive income generation strategies
        - Tax optimization and financial planning
        - Real estate and alternative investments
        - Financial mindset and wealth psychology
        
        Always provide practical financial advice, evidence-based investment strategies, and wealth-building recommendations.
        Be conservative yet growth-focused, emphasizing long-term wealth creation and financial security.
        """
    }
    
    func generatePersonalizedContent(for user: User) async throws -> AIAgentContent {
        guard let wealthPrefs = user.preferences?.wealth else {
            throw AIError.missingUserPreferences
        }
        
        let prompt = """
        \(systemPrompt)
        
        User's Wealth Profile:
        - Goals: \(wealthPrefs.goals.map(\.rawValue).joined(separator: ", "))
        - Risk Tolerance: \(wealthPrefs.risk.rawValue)
        - Monthly Budget: $\(wealthPrefs.monthlyBudget)
        
        Generate personalized wealth content including:
        1. Today's financial focus
        2. 3 key wealth-building insights
        3. 3 actionable investment recommendations
        4. Motivational wealth message
        """
        
        let response = try await aiService.callGrokAPI(prompt: prompt, type: .businessPlan)
        return parseAIResponse(response, for: .wealth)
    }
    
    func getQuickActions(for user: User) -> [AIQuickAction] {
        return [
            AIQuickAction(title: "Portfolio Review", description: "Analyze investment strategy", icon: "chart.pie.fill", action: {}),
            AIQuickAction(title: "Budget Optimizer", description: "Optimize your finances", icon: "dollarsign.circle.fill", action: {}),
            AIQuickAction(title: "Income Ideas", description: "Passive income strategies", icon: "banknote.fill", action: {})
        ]
    }
    
    func processUserQuery(_ query: String, for user: User) async throws -> String {
        let contextualPrompt = """
        \(systemPrompt)
        
        User's Financial Context:
        \(getWealthContext(for: user))
        
        User Question: \(query)
        
        Provide personalized financial advice and wealth-building strategies based on their profile.
        """
        
        return try await aiService.callGrokAPI(prompt: contextualPrompt, type: .businessPlan)
    }
    
    private func getWealthContext(for user: User) -> String {
        guard let wealthPrefs = user.preferences?.wealth else { return "No wealth preferences set" }
        
        return """
        Goals: \(wealthPrefs.goals.map(\.rawValue).joined(separator: ", "))
        Risk Tolerance: \(wealthPrefs.risk.rawValue)
        Monthly Budget: $\(wealthPrefs.monthlyBudget)
        """
    }
}

// MARK: - Mindset AI Agent

class MindsetAIAgent: AIAgent {
    let name = "Mindset Coach"
    let expertise = "Mental Resilience, Personal Growth, and Mindful Living"
    private let aiService: AIService
    
    init(aiService: AIService) {
        self.aiService = aiService
    }
    
    var systemPrompt: String {
        return """
        You are an elite Mindset Coach AI specializing in mental resilience, personal growth, and mindful living.
        
        Your expertise includes:
        - Cognitive behavioral strategies and mental frameworks
        - Meditation and mindfulness practices
        - Goal setting and habit formation
        - Stress management and emotional regulation
        - Confidence building and self-development
        - Productivity and mental clarity optimization
        
        Always provide evidence-based mental strategies, practical mindfulness techniques, and growth-oriented advice.
        Be supportive, insightful, and focused on sustainable mental wellness and personal transformation.
        """
    }
    
    func generatePersonalizedContent(for user: User) async throws -> AIAgentContent {
        guard let mindsetPrefs = user.preferences?.mindset else {
            throw AIError.missingUserPreferences
        }
        
        let prompt = """
        \(systemPrompt)
        
        User's Mindset Profile:
        - Focus Areas: \(mindsetPrefs.focuses.map(\.rawValue).joined(separator: ", "))
        - Reflection Style: \(mindsetPrefs.reflection.rawValue)
        
        Generate personalized mindset content including:
        1. Today's mental focus
        2. 3 key mindset insights
        3. 3 actionable growth recommendations
        4. Motivational mindset message
        """
        
        let response = try await aiService.generateMotivationalMessage(for: user, trigger: .morningBoost)
        return parseAIResponse(response, for: .mindset)
    }
    
    func getQuickActions(for user: User) -> [AIQuickAction] {
        return [
            AIQuickAction(title: "Mindful Moment", description: "Quick meditation session", icon: "brain.head.profile", action: {}),
            AIQuickAction(title: "Goal Reflection", description: "Review your progress", icon: "target", action: {}),
            AIQuickAction(title: "Stress Relief", description: "Relaxation techniques", icon: "leaf.fill", action: {})
        ]
    }
    
    func processUserQuery(_ query: String, for user: User) async throws -> String {
        let contextualPrompt = """
        \(systemPrompt)
        
        User's Mindset Context:
        \(getMindsetContext(for: user))
        
        User Question: \(query)
        
        Provide personalized mindset coaching and mental wellness strategies based on their profile.
        """
        
        return try await aiService.callGrokAPI(prompt: contextualPrompt, type: .motivation)
    }
    
    private func getMindsetContext(for user: User) -> String {
        guard let mindsetPrefs = user.preferences?.mindset else { return "No mindset preferences set" }
        
        return """
        Focus Areas: \(mindsetPrefs.focuses.map(\.rawValue).joined(separator: ", "))
        Reflection Style: \(mindsetPrefs.reflection.rawValue)
        """
    }
}

// MARK: - Additional Specialized Agents (Simplified for brevity)

class CreativityAIAgent: AIAgent {
    let name = "Creativity Catalyst"
    let expertise = "Creative Expression, Innovation, and Artistic Growth"
    private let aiService: AIService
    
    init(aiService: AIService) { self.aiService = aiService }
    
    var systemPrompt: String {
        return "You are a Creativity Catalyst AI specializing in artistic expression, innovation, and creative problem-solving. Help users unlock their creative potential and develop their artistic skills."
    }
    
    func generatePersonalizedContent(for user: User) async throws -> AIAgentContent {
        let response = try await aiService.generateMotivationalMessage(for: user, trigger: .morningBoost)
        return parseAIResponse(response, for: .creativity)
    }
    
    func getQuickActions(for user: User) -> [AIQuickAction] {
        return [
            AIQuickAction(title: "Creative Spark", description: "Get inspiration", icon: "paintbrush.fill", action: {}),
            AIQuickAction(title: "Art Challenge", description: "Daily creative exercise", icon: "pencil.and.outline", action: {}),
            AIQuickAction(title: "Innovation Lab", description: "Brainstorm ideas", icon: "lightbulb.max.fill", action: {})
        ]
    }
    
    func processUserQuery(_ query: String, for user: User) async throws -> String {
        return try await aiService.callGrokAPI(prompt: systemPrompt + " User question: \(query)", type: .motivation)
    }
}

class RelationshipsAIAgent: AIAgent {
    let name = "Connection Coach"
    let expertise = "Relationship Building, Communication, and Social Skills"
    private let aiService: AIService
    
    init(aiService: AIService) { self.aiService = aiService }
    
    var systemPrompt: String {
        return "You are a Connection Coach AI specializing in relationship building, effective communication, and social skills development. Help users strengthen their connections and build meaningful relationships."
    }
    
    func generatePersonalizedContent(for user: User) async throws -> AIAgentContent {
        let response = try await aiService.generateMotivationalMessage(for: user, trigger: .morningBoost)
        return parseAIResponse(response, for: .relationships)
    }
    
    func getQuickActions(for user: User) -> [AIQuickAction] {
        return [
            AIQuickAction(title: "Communication Tips", description: "Improve conversations", icon: "bubble.left.and.bubble.right.fill", action: {}),
            AIQuickAction(title: "Relationship Check", description: "Strengthen connections", icon: "heart.fill", action: {}),
            AIQuickAction(title: "Social Skills", description: "Build confidence", icon: "person.2.fill", action: {})
        ]
    }
    
    func processUserQuery(_ query: String, for user: User) async throws -> String {
        return try await aiService.callGrokAPI(prompt: systemPrompt + " User question: \(query)", type: .motivation)
    }
}

// Continue with other agents (Learning, Spirituality, Adventure, Leadership, Health, Family)...

class LearningAIAgent: AIAgent {
    let name = "Learning Accelerator"
    let expertise = "Knowledge Acquisition, Skill Development, and Education"
    private let aiService: AIService
    
    init(aiService: AIService) { self.aiService = aiService }
    
    var systemPrompt: String { return "You are a Learning Accelerator AI focused on knowledge acquisition and skill development." }
    func generatePersonalizedContent(for user: User) async throws -> AIAgentContent { 
        let response = try await aiService.generateMotivationalMessage(for: user, trigger: .morningBoost)
        return parseAIResponse(response, for: .learning)
    }
    func getQuickActions(for user: User) -> [AIQuickAction] { return [] }
    func processUserQuery(_ query: String, for user: User) async throws -> String { 
        return try await aiService.callGrokAPI(prompt: systemPrompt + " \(query)", type: .motivation)
    }
}

class SpiritualityAIAgent: AIAgent {
    let name = "Spiritual Guide"
    let expertise = "Spiritual Growth, Inner Peace, and Purpose"
    private let aiService: AIService
    
    init(aiService: AIService) { self.aiService = aiService }
    
    var systemPrompt: String { return "You are a Spiritual Guide AI focused on inner growth and finding purpose." }
    func generatePersonalizedContent(for user: User) async throws -> AIAgentContent { 
        let response = try await aiService.generateMotivationalMessage(for: user, trigger: .morningBoost)
        return parseAIResponse(response, for: .spirituality)
    }
    func getQuickActions(for user: User) -> [AIQuickAction] { return [] }
    func processUserQuery(_ query: String, for user: User) async throws -> String { 
        return try await aiService.callGrokAPI(prompt: systemPrompt + " \(query)", type: .motivation)
    }
}

class AdventureAIAgent: AIAgent {
    let name = "Adventure Catalyst"
    let expertise = "Exploration, Travel, and Life Experiences"
    private let aiService: AIService
    
    init(aiService: AIService) { self.aiService = aiService }
    
    var systemPrompt: String { return "You are an Adventure Catalyst AI focused on exploration and enriching life experiences." }
    func generatePersonalizedContent(for user: User) async throws -> AIAgentContent { 
        let response = try await aiService.generateMotivationalMessage(for: user, trigger: .morningBoost)
        return parseAIResponse(response, for: .adventure)
    }
    func getQuickActions(for user: User) -> [AIQuickAction] { return [] }
    func processUserQuery(_ query: String, for user: User) async throws -> String { 
        return try await aiService.callGrokAPI(prompt: systemPrompt + " \(query)", type: .motivation)
    }
}

class LeadershipAIAgent: AIAgent {
    let name = "Leadership Mentor"
    let expertise = "Leadership Development, Team Management, and Influence"
    private let aiService: AIService
    
    init(aiService: AIService) { self.aiService = aiService }
    
    var systemPrompt: String { return "You are a Leadership Mentor AI focused on developing leadership skills and influence." }
    func generatePersonalizedContent(for user: User) async throws -> AIAgentContent { 
        let response = try await aiService.generateMotivationalMessage(for: user, trigger: .morningBoost)
        return parseAIResponse(response, for: .leadership)
    }
    func getQuickActions(for user: User) -> [AIQuickAction] { return [] }
    func processUserQuery(_ query: String, for user: User) async throws -> String { 
        return try await aiService.callGrokAPI(prompt: systemPrompt + " \(query)", type: .motivation)
    }
}

class HealthAIAgent: AIAgent {
    let name = "Health Optimizer"
    let expertise = "Holistic Health, Wellness, and Longevity"
    private let aiService: AIService
    
    init(aiService: AIService) { self.aiService = aiService }
    
    var systemPrompt: String { return "You are a Health Optimizer AI focused on holistic wellness and longevity." }
    func generatePersonalizedContent(for user: User) async throws -> AIAgentContent { 
        let response = try await aiService.generateMotivationalMessage(for: user, trigger: .morningBoost)
        return parseAIResponse(response, for: .health)
    }
    func getQuickActions(for user: User) -> [AIQuickAction] { return [] }
    func processUserQuery(_ query: String, for user: User) async throws -> String { 
        return try await aiService.callGrokAPI(prompt: systemPrompt + " \(query)", type: .motivation)
    }
}

class FamilyAIAgent: AIAgent {
    let name = "Family Guide"
    let expertise = "Family Relationships, Parenting, and Home Life"
    private let aiService: AIService
    
    init(aiService: AIService) { self.aiService = aiService }
    
    var systemPrompt: String { return "You are a Family Guide AI focused on strengthening family bonds and home life." }
    func generatePersonalizedContent(for user: User) async throws -> AIAgentContent { 
        let response = try await aiService.generateMotivationalMessage(for: user, trigger: .morningBoost)
        return parseAIResponse(response, for: .family)
    }
    func getQuickActions(for user: User) -> [AIQuickAction] { return [] }
    func processUserQuery(_ query: String, for user: User) async throws -> String { 
        return try await aiService.callGrokAPI(prompt: systemPrompt + " \(query)", type: .motivation)
    }
}

class CoachAIAgent: AIAgent {
    let name = "Flowmate Coach"
    let expertise = "Holistic Life Coaching and Personal Transformation"
    private let aiService: AIService
    
    init(aiService: AIService) { self.aiService = aiService }
    
    var systemPrompt: String {
        return """
        You are Flowmate Coach, a holistic life transformation AI that adapts to the user's unique interests and goals.
        You are supportive, insightful, and focused on helping users achieve their personal transformation across all areas of life.
        Provide encouraging, actionable advice that considers the user's full profile and interests.
        """
    }
    
    func generatePersonalizedContent(for user: User) async throws -> AIAgentContent {
        let response = try await aiService.generateMotivationalMessage(for: user, trigger: .morningBoost)
        return parseAIResponse(response, for: .mindset)
    }
    
    func getQuickActions(for user: User) -> [AIQuickAction] {
        return [
            AIQuickAction(title: "Life Review", description: "Assess your progress", icon: "checkmark.circle.fill", action: {}),
            AIQuickAction(title: "Goal Setting", description: "Plan your future", icon: "target", action: {}),
            AIQuickAction(title: "Motivation Boost", description: "Get inspired", icon: "bolt.fill", action: {})
        ]
    }
    
    func processUserQuery(_ query: String, for user: User) async throws -> String {
        let userContext = getUserContext(for: user)
        let contextualPrompt = """
        \(systemPrompt)
        
        User's Profile:
        \(userContext)
        
        User Question: \(query)
        
        Provide personalized life coaching advice considering their interests and goals.
        """
        
        return try await aiService.callGrokAPI(prompt: contextualPrompt, type: .motivation)
    }
    
    private func getUserContext(for user: User) -> String {
        guard let preferences = user.preferences else { return "No preferences set" }
        
        let interests = preferences.theme.selectedInterests.map(\.rawValue).joined(separator: ", ")
        return "Interests: \(interests)"
    }
}

// MARK: - Helper Functions

private func parseAIResponse(_ response: String, for interest: UserInterest) -> AIAgentContent {
    // For now, return a structured response - in production, you'd parse the AI response properly
    return AIAgentContent(
        title: "Personalized \(interest.rawValue.capitalized) Insights",
        subtitle: "AI-generated content tailored to your preferences",
        mainContent: response,
        insights: [
            AIInsight(title: "Daily Focus", description: "Your priority for today", icon: "target", priority: .high),
            AIInsight(title: "Key Insight", description: "Important discovery", icon: "lightbulb.fill", priority: .medium),
            AIInsight(title: "Growth Opportunity", description: "Area for development", icon: "arrow.up.right", priority: .medium)
        ],
        recommendations: [
            AIRecommendation(title: "Quick Win", description: "Easy action you can take now", actionType: .immediate, difficulty: .easy),
            AIRecommendation(title: "Weekly Goal", description: "Focus for this week", actionType: .shortTerm, difficulty: .medium),
            AIRecommendation(title: "Long-term Vision", description: "Big picture objective", actionType: .longTerm, difficulty: .hard)
        ],
        motivationalMessage: "You're on the right path to achieving your goals. Keep pushing forward!"
    )
}
