//
//  EnhancedTabViews.swift
//  Flowmate
//
//  Created on 2025-01-13
//

import SwiftUI

// MARK: - Enhanced Fitness View with AI Agent

struct EnhancedFitnessView: View {
    @EnvironmentObject var themeProvider: ThemeProvider
    @EnvironmentObject var authService: AuthenticationService
    @StateObject private var agentManager = AIAgentManager.shared
    
    @State private var agentContent: AIAgentContent?
    @State private var isLoadingContent = false
    @State private var showingWorkoutGenerator = false
    @State private var dailyWorkout: String?
    
    private var fitnessAgent: FitnessAIAgent {
        agentManager.getFitnessAgent()
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // AI-Powered Header
                    VStack(spacing: 16) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Fitness Coach")
                                    .font(.system(size: 28, weight: .bold))
                                    .foregroundStyle(themeProvider.theme.gradientTextPrimary)
                                
                                Text(fitnessAgent.expertise)
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(themeProvider.theme.textSecondary)
                            }
                            
                            Spacer()
                            
                            // AI Status Indicator
                            AIStatusIndicator(isActive: agentContent != nil)
                        }
                        
                        if let content = agentContent {
                            AIInsightCard(content: content)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    
                    // Quick AI Actions
                    AIQuickActionsGrid(
                        actions: fitnessAgent.getQuickActions(for: authService.currentUser!),
                        onActionTap: { action in
                            handleQuickAction(action)
                        }
                    )
                    
                    // AI-Generated Daily Workout
                    if let workout = dailyWorkout {
                        AIGeneratedWorkoutCard(workout: workout)
                    }
                    
                    // Fitness Progress with AI Insights
                    FitnessProgressWithAI()
                    
                    // AI Recommendations
                    if let content = agentContent {
                        AIRecommendationsSection(recommendations: content.recommendations)
                    }
                }
                .padding(.bottom, 100) // Space for floating coach
            }
            .background(ThemedBackground().environmentObject(themeProvider))
            .navigationTitle("Fitness")
            .refreshable {
                await loadAIContent()
            }
            .task {
                await loadAIContent()
            }
        }
        .overlay(
            // Floating Coach integrated
            FloatingCoach()
                .environmentObject(themeProvider)
                .environmentObject(authService)
        )
    }
    
    private func loadAIContent() async {
        guard let user = authService.currentUser else { return }
        
        isLoadingContent = true
        do {
            agentContent = try await fitnessAgent.generatePersonalizedContent(for: user)
        } catch {
            print("Failed to load AI content: \(error)")
        }
        isLoadingContent = false
    }
    
    private func handleQuickAction(_ action: AIQuickAction) {
        if action.title == "Generate Workout" {
            generateDailyWorkout()
        }
        // Handle other actions...
    }
    
    private func generateDailyWorkout() {
        Task {
            guard let user = authService.currentUser else { return }
            do {
                dailyWorkout = try await fitnessAgent.processUserQuery("Generate a personalized workout for today", for: user)
            } catch {
                print("Failed to generate workout: \(error)")
            }
        }
    }
}

// MARK: - Enhanced Business View with AI Agent

struct EnhancedBusinessView: View {
    @EnvironmentObject var themeProvider: ThemeProvider
    @EnvironmentObject var authService: AuthenticationService
    @StateObject private var agentManager = AIAgentManager.shared
    
    @State private var agentContent: AIAgentContent?
    @State private var isLoadingContent = false
    @State private var dailyStrategy: String?
    
    private var businessAgent: BusinessAIAgent {
        agentManager.getBusinessAgent()
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // AI-Powered Business Header
                    VStack(spacing: 16) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Business Strategist")
                                    .font(.system(size: 28, weight: .bold))
                                    .foregroundStyle(themeProvider.theme.gradientTextPrimary)
                                
                                Text(businessAgent.expertise)
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(themeProvider.theme.textSecondary)
                            }
                            
                            Spacer()
                            
                            AIStatusIndicator(isActive: agentContent != nil)
                        }
                        
                        if let content = agentContent {
                            AIInsightCard(content: content)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    
                    // Business AI Actions
                    AIQuickActionsGrid(
                        actions: businessAgent.getQuickActions(for: authService.currentUser!),
                        onActionTap: { action in
                            handleBusinessAction(action)
                        }
                    )
                    
                    // AI-Generated Business Strategy
                    if let strategy = dailyStrategy {
                        AIBusinessStrategyCard(strategy: strategy)
                    }
                    
                    // Business Metrics with AI Analysis
                    BusinessMetricsWithAI()
                    
                    // Market Opportunities (AI-Powered)
                    AIMarketOpportunitiesSection()
                }
                .padding(.bottom, 100)
            }
            .background(ThemedBackground().environmentObject(themeProvider))
            .navigationTitle("Business")
            .refreshable {
                await loadAIContent()
            }
            .task {
                await loadAIContent()
            }
        }
        .overlay(
            FloatingCoach()
                .environmentObject(themeProvider)
                .environmentObject(authService)
        )
    }
    
    private func loadAIContent() async {
        guard let user = authService.currentUser else { return }
        
        isLoadingContent = true
        do {
            agentContent = try await businessAgent.generatePersonalizedContent(for: user)
        } catch {
            print("Failed to load AI content: \(error)")
        }
        isLoadingContent = false
    }
    
    private func handleBusinessAction(_ action: AIQuickAction) {
        if action.title == "Strategy Session" {
            generateDailyStrategy()
        }
    }
    
    private func generateDailyStrategy() {
        Task {
            guard let user = authService.currentUser else { return }
            do {
                dailyStrategy = try await businessAgent.processUserQuery("What should be my strategic priority today?", for: user)
            } catch {
                print("Failed to generate strategy: \(error)")
            }
        }
    }
}

// MARK: - Enhanced Wealth View with AI Agent

struct EnhancedWealthView: View {
    @EnvironmentObject var themeProvider: ThemeProvider
    @EnvironmentObject var authService: AuthenticationService
    @StateObject private var agentManager = AIAgentManager.shared
    
    @State private var agentContent: AIAgentContent?
    @State private var portfolioAnalysis: String?
    @State private var investmentIdeas: [String] = []
    
    private var wealthAgent: WealthAIAgent {
        agentManager.getWealthAgent()
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // AI Wealth Advisor Header
                    VStack(spacing: 16) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Wealth Advisor")
                                    .font(.system(size: 28, weight: .bold))
                                    .foregroundStyle(themeProvider.theme.gradientTextPrimary)
                                
                                Text(wealthAgent.expertise)
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(themeProvider.theme.textSecondary)
                            }
                            
                            Spacer()
                            
                            AIStatusIndicator(isActive: agentContent != nil)
                        }
                        
                        if let content = agentContent {
                            AIInsightCard(content: content)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    
                    // Wealth Building Actions
                    AIQuickActionsGrid(
                        actions: wealthAgent.getQuickActions(for: authService.currentUser!),
                        onActionTap: { action in
                            handleWealthAction(action)
                        }
                    )
                    
                    // AI Portfolio Analysis
                    if let analysis = portfolioAnalysis {
                        AIPortfolioAnalysisCard(analysis: analysis)
                    }
                    
                    // AI Investment Ideas
                    if !investmentIdeas.isEmpty {
                        AIInvestmentIdeasSection(ideas: investmentIdeas)
                    }
                    
                    // Wealth Tracking with AI Insights
                    WealthTrackingWithAI()
                }
                .padding(.bottom, 100)
            }
            .background(ThemedBackground().environmentObject(themeProvider))
            .navigationTitle("Wealth")
            .refreshable {
                await loadAIContent()
            }
            .task {
                await loadAIContent()
            }
        }
        .overlay(
            FloatingCoach()
                .environmentObject(themeProvider)
                .environmentObject(authService)
        )
    }
    
    private func loadAIContent() async {
        guard let user = authService.currentUser else { return }
        
        do {
            agentContent = try await wealthAgent.generatePersonalizedContent(for: user)
            await generateInvestmentIdeas()
        } catch {
            print("Failed to load AI content: \(error)")
        }
    }
    
    private func handleWealthAction(_ action: AIQuickAction) {
        if action.title == "Portfolio Review" {
            analyzePortfolio()
        }
    }
    
    private func analyzePortfolio() {
        Task {
            guard let user = authService.currentUser else { return }
            do {
                portfolioAnalysis = try await wealthAgent.processUserQuery("Analyze my investment portfolio and provide recommendations", for: user)
            } catch {
                print("Failed to analyze portfolio: \(error)")
            }
        }
    }
    
    private func generateInvestmentIdeas() async {
        guard let user = authService.currentUser else { return }
        do {
            let ideas = try await wealthAgent.processUserQuery("Give me 3 personalized investment ideas based on my risk tolerance and goals", for: user)
            investmentIdeas = ideas.components(separatedBy: "\n").filter { !$0.isEmpty }
        } catch {
            print("Failed to generate investment ideas: \(error)")
        }
    }
}

// MARK: - AI Component Views

struct AIStatusIndicator: View {
    let isActive: Bool
    @EnvironmentObject var themeProvider: ThemeProvider
    @State private var pulseScale: CGFloat = 1.0
    
    var body: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(isActive ? Color.green : Color.gray)
                .frame(width: 8, height: 8)
                .scaleEffect(pulseScale)
                .onAppear {
                    if isActive {
                        withAnimation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
                            pulseScale = 1.3
                        }
                    }
                }
            
            Text(isActive ? "AI Active" : "AI Loading")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(themeProvider.theme.textSecondary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(themeProvider.theme.cardBackground.opacity(0.6))
        )
    }
}

struct AIInsightCard: View {
    let content: AIAgentContent
    @EnvironmentObject var themeProvider: ThemeProvider
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "brain.head.profile")
                    .font(.system(size: 20))
                    .foregroundColor(themeProvider.theme.accent)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(content.title)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(themeProvider.theme.textPrimary)
                    
                    Text(content.subtitle)
                        .font(.system(size: 14))
                        .foregroundColor(themeProvider.theme.textSecondary)
                }
                
                Spacer()
            }
            
            Text(content.motivationalMessage)
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(themeProvider.theme.gradientTextPrimary)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(themeProvider.theme.accent.opacity(0.1))
                )
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(themeProvider.theme.cardBackground)
                .shadow(color: themeProvider.theme.accent.opacity(0.1), radius: 8, x: 0, y: 4)
        )
    }
}

struct AIQuickActionsGrid: View {
    let actions: [AIQuickAction]
    let onActionTap: (AIQuickAction) -> Void
    
    @EnvironmentObject var themeProvider: ThemeProvider
    
    var body: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 16) {
            ForEach(Array(actions.enumerated()), id: \.offset) { index, action in
                Button(action: { onActionTap(action) }) {
                    VStack(spacing: 12) {
                        Image(systemName: action.icon)
                            .font(.system(size: 24))
                            .foregroundColor(themeProvider.theme.accent)
                        
                        VStack(spacing: 4) {
                            Text(action.title)
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(themeProvider.theme.textPrimary)
                            
                            Text(action.description)
                                .font(.system(size: 12))
                                .foregroundColor(themeProvider.theme.textSecondary)
                                .multilineTextAlignment(.center)
                        }
                    }
                    .padding()
                    .frame(height: 120)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(themeProvider.theme.cardBackground)
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(themeProvider.theme.accent.opacity(0.2), lineWidth: 1)
                            )
                    )
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(.horizontal, 20)
    }
}

struct AIGeneratedWorkoutCard: View {
    let workout: String
    @EnvironmentObject var themeProvider: ThemeProvider
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "figure.run")
                    .font(.system(size: 20))
                    .foregroundColor(themeProvider.theme.accent)
                
                Text("AI-Generated Workout")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(themeProvider.theme.textPrimary)
                
                Spacer()
                
                Text("Today")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(themeProvider.theme.textSecondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(themeProvider.theme.accent.opacity(0.2))
                    )
            }
            
            Text(workout)
                .font(.system(size: 15))
                .foregroundColor(themeProvider.theme.textPrimary)
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(themeProvider.theme.accent.opacity(0.05))
                )
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(themeProvider.theme.cardBackground)
                .shadow(color: themeProvider.theme.accent.opacity(0.1), radius: 8, x: 0, y: 4)
        )
        .padding(.horizontal, 20)
    }
}

struct AIBusinessStrategyCard: View {
    let strategy: String
    @EnvironmentObject var themeProvider: ThemeProvider
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "lightbulb.fill")
                    .font(.system(size: 20))
                    .foregroundColor(themeProvider.theme.accent)
                
                Text("Strategic Priority")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(themeProvider.theme.textPrimary)
                
                Spacer()
            }
            
            Text(strategy)
                .font(.system(size: 15))
                .foregroundColor(themeProvider.theme.textPrimary)
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(themeProvider.theme.accent.opacity(0.05))
                )
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(themeProvider.theme.cardBackground)
                .shadow(color: themeProvider.theme.accent.opacity(0.1), radius: 8, x: 0, y: 4)
        )
        .padding(.horizontal, 20)
    }
}

struct AIPortfolioAnalysisCard: View {
    let analysis: String
    @EnvironmentObject var themeProvider: ThemeProvider
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "chart.pie.fill")
                    .font(.system(size: 20))
                    .foregroundColor(themeProvider.theme.accent)
                
                Text("Portfolio Analysis")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(themeProvider.theme.textPrimary)
                
                Spacer()
            }
            
            Text(analysis)
                .font(.system(size: 15))
                .foregroundColor(themeProvider.theme.textPrimary)
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(themeProvider.theme.accent.opacity(0.05))
                )
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(themeProvider.theme.cardBackground)
                .shadow(color: themeProvider.theme.accent.opacity(0.1), radius: 8, x: 0, y: 4)
        )
        .padding(.horizontal, 20)
    }
}

struct AIRecommendationsSection: View {
    let recommendations: [AIRecommendation]
    @EnvironmentObject var themeProvider: ThemeProvider
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("AI Recommendations")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(themeProvider.theme.textPrimary)
                
                Spacer()
            }
            .padding(.horizontal, 20)
            
            ForEach(Array(recommendations.enumerated()), id: \.offset) { index, recommendation in
                AIRecommendationCard(recommendation: recommendation)
            }
        }
    }
}

struct AIRecommendationCard: View {
    let recommendation: AIRecommendation
    @EnvironmentObject var themeProvider: ThemeProvider
    
    var body: some View {
        HStack(spacing: 16) {
            // Priority indicator
            Circle()
                .fill(priorityColor)
                .frame(width: 12, height: 12)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(recommendation.title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(themeProvider.theme.textPrimary)
                
                Text(recommendation.description)
                    .font(.system(size: 14))
                    .foregroundColor(themeProvider.theme.textSecondary)
            }
            
            Spacer()
            
            Text(recommendation.difficulty.rawValue.capitalized)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(themeProvider.theme.textSecondary)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(themeProvider.theme.accent.opacity(0.2))
                )
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(themeProvider.theme.cardBackground)
        )
        .padding(.horizontal, 20)
    }
    
    private var priorityColor: Color {
        switch recommendation.actionType {
        case .immediate: return .red
        case .shortTerm: return .orange
        case .longTerm: return .green
        case .habit: return .blue
        }
    }
}

// MARK: - Placeholder Views (you can implement these with real functionality)

struct FitnessProgressWithAI: View {
    var body: some View {
        // Implement fitness progress tracking with AI insights
        EmptyView()
    }
}

struct BusinessMetricsWithAI: View {
    var body: some View {
        // Implement business metrics with AI analysis
        EmptyView()
    }
}

struct AIMarketOpportunitiesSection: View {
    var body: some View {
        // Implement AI-powered market opportunities
        EmptyView()
    }
}

struct WealthTrackingWithAI: View {
    var body: some View {
        // Implement wealth tracking with AI insights
        EmptyView()
    }
}

struct AIInvestmentIdeasSection: View {
    let ideas: [String]
    
    var body: some View {
        // Implement AI investment ideas display
        EmptyView()
    }
}
