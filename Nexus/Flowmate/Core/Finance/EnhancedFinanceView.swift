//
//  EnhancedFinanceView.swift
//  Flowmate
//
//  Created on 2025-01-13
//

import SwiftUI

struct EnhancedFinanceView: View {
    @EnvironmentObject var themeProvider: ThemeProvider
    @EnvironmentObject var authService: AuthenticationService
    @StateObject private var financeAI = FinanceAIService.shared
    
    @State private var selectedStockSymbol = "AAPL"
    @State private var watchlistSymbols: [String] = ["AAPL", "MSFT", "GOOGL", "TSLA", "NVDA"]
    @State private var isAnalyzingStock = false
    @State private var isGeneratingIdeas = false
    @State private var currentAnalysis: AIStockAnalysis?
    @State private var analysisMarkdown: AttributedString?
    @State private var investmentIdeas: [AIStockAnalysis] = []
    @State private var portfolioInsights: [AIPortfolioInsight] = []
    @State private var marketNews: [StockNews] = []
    @State private var showStockAnalysis = false
    @State private var showInvestmentIdeas = false
    @State private var showPortfolioInsights = false
    @State private var showMarketNews = false
    @State private var showFinanceSettings = false
    @State private var portfolio: Portfolio? = nil
    
    // Real portfolio should be loaded from backend when available. No mock data.
    
    private var financePrefs: FinancePreferences {
        // Convert WealthPreferences to FinancePreferences or use default
        if let wealthPrefs = authService.currentUser?.preferences?.wealth {
            // Convert existing wealth preferences to finance preferences
            return FinancePreferences(
                riskTolerance: .moderate, // Default for now
                investmentGoals: [.wealth],
                preferredSectors: [],
                portfolioSize: .medium,
                tradingExperience: .intermediate
            )
        }
        return FinancePreferences()
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Enhanced Header with Portfolio Stats
                    headerSection
                    
                    // Professional Portfolio Stats Grid
                    if portfolio != nil {
                        enhancedStatsGrid
                    } else {
                        connectPortfolioCTA
                    }
                    
                    // AI Stock Research Hub
                    aiStockResearchSection
                    
                    // Market Overview
                    marketOverviewSection
                    
                    // Investment Ideas Generator
                    investmentIdeasSection
                    
                    // Portfolio Insights
                    portfolioInsightsSection
                    
                    // Quick Actions
                    quickActionsSection
                    
                    // AI Finance Coach Integration
                    aiFinanceCoachSection
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 100) // Account for tab bar
            }
            .background(ThemedBackground().environmentObject(themeProvider))
            .navigationTitle("Finance")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showFinanceSettings = true
                    } label: {
                        Image(systemName: "gearshape.fill")
                            .foregroundColor(themeProvider.theme.accent)
                    }
                }
            }
            .sheet(isPresented: $showStockAnalysis) {
                if let analysis = currentAnalysis {
                    StockAnalysisDetailView(analysis: analysis)
                        .environmentObject(themeProvider)
                }
            }
            .sheet(isPresented: $showInvestmentIdeas) {
                InvestmentIdeasView(ideas: investmentIdeas)
                    .environmentObject(themeProvider)
            }
            .sheet(isPresented: $showPortfolioInsights) {
                if let p = portfolio {
                    PortfolioInsightsView(insights: portfolioInsights, portfolio: p)
                        .environmentObject(themeProvider)
                }
            }
            .sheet(isPresented: $showMarketNews) {
                MarketNewsView(news: marketNews)
                    .environmentObject(themeProvider)
            }
            .sheet(isPresented: $showFinanceSettings) {
                FinanceSettingsView()
                    .environmentObject(themeProvider)
                    .environmentObject(authService)
            }
        }
        .task { await loadInitialData() }
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Your Financial Journey")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundColor(themeProvider.theme.textPrimary)
                    
                    Text("Powered by AI • Personalized insights")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(themeProvider.theme.accent)
                }
                
                Spacer()
                
                // Performance indicator
                VStack(spacing: 4) {
                    Text(portfolio?.isPositive ?? false ? "📈" : "📉")
                        .font(.system(size: 24))
                    Text("Portfolio")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(themeProvider.theme.accent)
                }
                .padding(12)
                .background(
                    Circle()
                        .fill(themeProvider.theme.accent.opacity(0.1))
                )
            }
            
            // Portfolio Performance Card
            HStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Portfolio Value")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(themeProvider.theme.textSecondary)
                    
                    Text(portfolio?.formattedTotalValue ?? "—")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(themeProvider.theme.textPrimary)
                    
                    HStack(spacing: 8) {
                        if let p = portfolio {
                            Text(p.formattedDailyChange)
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(p.isPositive ? .green : .red)
                            Text(p.formattedDailyChangePercent)
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(p.isPositive ? .green : .red)
                        }
                    }
                }
                
                Spacer()
                
                // Mini chart placeholder
                VStack {
                    Image(systemName: (portfolio?.isPositive ?? false) ? "chart.line.uptrend.xyaxis" : "chart.line.downtrend.xyaxis")
                        .font(.system(size: 32))
                        .foregroundColor((portfolio?.isPositive ?? false) ? .green : .red)
                    
                    Text("Today")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(themeProvider.theme.textSecondary)
                }
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(themeProvider.theme.backgroundSecondary)
                    .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
            )
        }
    }
    
    // MARK: - Enhanced Stats Grid
    private var enhancedStatsGrid: some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: 16) {
            if let p = portfolio {
                FinanceStatCard(
                    title: "Portfolio Value",
                    value: p.formattedTotalValue,
                    subtitle: "Total Holdings",
                    icon: "dollarsign.circle.fill",
                    color: .green
                )
                
                FinanceStatCard(
                    title: "Daily P&L",
                    value: p.formattedDailyChange,
                    subtitle: p.formattedDailyChangePercent,
                    icon: p.isPositive ? "arrow.up.circle.fill" : "arrow.down.circle.fill",
                    color: p.isPositive ? .green : .red
                )
                
                FinanceStatCard(
                    title: "Risk Score",
                    value: "\(Int(p.riskScore))/100",
                    subtitle: "Portfolio Risk",
                    icon: "shield.checkered",
                    color: .orange
                )
                
                FinanceStatCard(
                    title: "Diversification",
                    value: "\(Int(p.diversificationScore))/100",
                    subtitle: "Sector Spread",
                    icon: "chart.pie.fill",
                    color: .blue
                )
            }
        }
    }
    
    // MARK: - Connect Portfolio CTA
    private var connectPortfolioCTA: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Portfolio not connected")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(themeProvider.theme.textPrimary)
            Text("Open Finance Settings to set your preferences and connect your portfolio.")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(themeProvider.theme.textSecondary)
            Button {
                showFinanceSettings = true
            } label: {
                Text("Open Settings")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(RoundedRectangle(cornerRadius: 10).fill(themeProvider.theme.accent))
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(themeProvider.theme.backgroundSecondary)
        )
    }
    
    // MARK: - AI Stock Research Section
    private var aiStockResearchSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("AI Stock Research")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(themeProvider.theme.textPrimary)
                    
                    Text("Real-time analysis powered by AI")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(themeProvider.theme.textSecondary)
                }
                
                Spacer()
                
                Image(systemName: "brain.head.profile")
                    .font(.system(size: 24))
                    .foregroundColor(themeProvider.theme.accent)
            }
            
            // Stock Symbol Input
            VStack(alignment: .leading, spacing: 16) {
                Text("Enter Stock Symbol")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(themeProvider.theme.textPrimary)
                
                HStack(spacing: 12) {
                    TextField("AAPL", text: $selectedStockSymbol)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .textCase(.uppercase)
                        .font(.system(size: 16, weight: .semibold, design: .monospaced))
                    
                    Button {
                        analyzeSelectedStock()
                    } label: {
                        HStack(spacing: 8) {
                            if isAnalyzingStock {
                                ProgressView()
                                    .scaleEffect(0.8)
                            } else {
                                Image(systemName: "magnifyingglass")
                            }
                            Text("Analyze")
                        }
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(themeProvider.theme.accent)
                        )
                    }
                    .disabled(isAnalyzingStock || selectedStockSymbol.isEmpty)
                }
                
                // Quick Stock Buttons
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 12) {
                    ForEach(watchlistSymbols, id: \.self) { symbol in
                        Button {
                            selectedStockSymbol = symbol
                            analyzeSelectedStock()
                        } label: {
                            Text(symbol)
                                .font(.system(size: 14, weight: .semibold, design: .monospaced))
                                .foregroundColor(themeProvider.theme.accent)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(themeProvider.theme.accent.opacity(0.1))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 8)
                                                .stroke(themeProvider.theme.accent.opacity(0.3), lineWidth: 1)
                                        )
                                )
                        }
                        .scaleEffect(isAnalyzingStock ? 0.95 : 1.0)
                        .animation(.easeInOut(duration: 0.1), value: isAnalyzingStock)
                    }
                }
                
                // Inline Markdown Report
                if let md = analysisMarkdown {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("AI Report")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(themeProvider.theme.textPrimary)
                        Text(md)
                            .foregroundColor(themeProvider.theme.textSecondary)
                        Button {
                            showStockAnalysis = true
                        } label: {
                            Text("Open Full Report")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(themeProvider.theme.accent)
                        }
                    }
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(themeProvider.theme.backgroundPrimary)
                    )
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(themeProvider.theme.backgroundSecondary)
                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
        )
    }
    
    // MARK: - Market Overview Section
    private var marketOverviewSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Market Overview")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(themeProvider.theme.textPrimary)
                
                Spacer()
                
                if financeAI.isLoading {
                    ProgressView()
                        .scaleEffect(0.8)
                }
            }
            
            if let overview = financeAI.marketOverview {
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 12) {
                    ForEach(overview.indices) { index in
                        MarketIndexCard(index: index)
                            .environmentObject(themeProvider)
                    }
                }
                
                // Market Sentiment
                HStack {
                    Text("Market Sentiment:")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(themeProvider.theme.textSecondary)
                    
                    HStack(spacing: 8) {
                        Text(overview.marketSentiment.emoji)
                            .font(.system(size: 18))
                        
                        Text(overview.marketSentiment.displayName)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(Color(overview.marketSentiment.color))
                    }
                    
                    Spacer()
                }
                .padding(.top, 8)
            } else {
                Text("Loading market data...")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(themeProvider.theme.textSecondary)
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(themeProvider.theme.backgroundSecondary)
                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
        )
    }
    
    // MARK: - Investment Ideas Section
    private var investmentIdeasSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("AI Investment Ideas")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(themeProvider.theme.textPrimary)
                    
                    Text("Personalized for your profile")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(themeProvider.theme.textSecondary)
                }
                
                Spacer()
                
                Button {
                    generateInvestmentIdeas()
                } label: {
                    HStack(spacing: 8) {
                        if isGeneratingIdeas {
                            ProgressView()
                                .scaleEffect(0.8)
                        } else {
                            Image(systemName: "lightbulb.fill")
                        }
                        Text("Generate Ideas")
                    }
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(themeProvider.theme.accent)
                    )
                }
                .disabled(isGeneratingIdeas)
            }
            
            if !investmentIdeas.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 16) {
                        ForEach(investmentIdeas.prefix(3)) { idea in
                            InvestmentIdeaCard(analysis: idea)
                                .environmentObject(themeProvider)
                                .frame(width: 280)
                        }
                    }
                    .padding(.horizontal, 2)
                }
                
                if investmentIdeas.count > 3 {
                    Button {
                        showInvestmentIdeas = true
                    } label: {
                        Text("View All Ideas (\(investmentIdeas.count))")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(themeProvider.theme.accent)
                    }
                    .padding(.top, 8)
                }
            } else {
                Text("Tap 'Generate Ideas' to get personalized investment suggestions")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(themeProvider.theme.textSecondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(themeProvider.theme.backgroundSecondary)
                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
        )
    }
    
    // MARK: - Portfolio Insights Section
    private var portfolioInsightsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Portfolio Insights")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(themeProvider.theme.textPrimary)
                
                Spacer()
                
                Button {
                    showPortfolioInsights = true
                } label: {
                    Image(systemName: "arrow.up.right")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(themeProvider.theme.accent)
                }
            }
            
            if !portfolioInsights.isEmpty {
                ForEach(portfolioInsights.prefix(2)) { insight in
                    PortfolioInsightCard(insight: insight)
                        .environmentObject(themeProvider)
                }
            } else {
                Text("AI is analyzing your portfolio...")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(themeProvider.theme.textSecondary)
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(themeProvider.theme.backgroundSecondary)
                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
        )
    }
    
    // MARK: - Quick Actions
    private var quickActionsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Quick Actions")
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(themeProvider.theme.textPrimary)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                ActionCard(
                    title: "Market News",
                    subtitle: "Latest updates",
                    icon: "newspaper.fill",
                    color: .blue
                ) {
                    loadMarketNews()
                }
                
                ActionCard(
                    title: "Watchlist",
                    subtitle: "Track favorites",
                    icon: "star.fill",
                    color: .yellow
                ) {
                    // Handle watchlist action
                }
                
                ActionCard(
                    title: "Trade Log",
                    subtitle: "Record trades",
                    icon: "book.fill",
                    color: .green
                ) {
                    // Handle trade log action
                }
                
                ActionCard(
                    title: "Research",
                    subtitle: "Deep analysis",
                    icon: "chart.bar.doc.horizontal.fill",
                    color: .purple
                ) {
                    // Handle research action
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(themeProvider.theme.backgroundSecondary)
                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
        )
    }
    
    // MARK: - AI Finance Coach Section
    private var aiFinanceCoachSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("AI Finance Coach")
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(themeProvider.theme.textPrimary)
            
            HStack(spacing: 16) {
                VStack {
                    Circle()
                        .fill(themeProvider.theme.accent.opacity(0.2))
                        .frame(width: 60, height: 60)
                        .overlay(
                            Image(systemName: "brain.head.profile")
                                .font(.system(size: 24))
                                .foregroundColor(themeProvider.theme.accent)
                        )
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Get personalized financial advice")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(themeProvider.theme.textPrimary)
                    
                    Text("Ask about investments, portfolio strategy, market insights, and more")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(themeProvider.theme.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                
                Spacer()
                
                Button {
                    // Open AI Coach with finance context
                } label: {
                    Image(systemName: "message.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.white)
                        .padding(12)
                        .background(
                            Circle()
                                .fill(themeProvider.theme.accent)
                        )
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(themeProvider.theme.backgroundSecondary)
                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
        )
    }
    
    // MARK: - Actions
    
    private func loadInitialData() async {
        do {
            // Load market overview
            _ = try await financeAI.getMarketOverview()
        } catch {
            print("Error loading initial data: \(error)")
        }
    }
    
    private func analyzeSelectedStock() {
        guard !selectedStockSymbol.isEmpty else { return }
        
        isAnalyzingStock = true
        analysisMarkdown = nil
        
        Task {
            do {
                let analysis = try await financeAI.analyzeStock(
                    symbol: selectedStockSymbol.uppercased(),
                    analysisType: .comprehensive,
                    userPreferences: financePrefs
                )
                
                await MainActor.run {
                    currentAnalysis = analysis
                    showStockAnalysis = true
                    isAnalyzingStock = false
                    analysisMarkdown = try? AttributedString(markdown: buildMarkdown(from: analysis))
                }
            } catch {
                await MainActor.run {
                    financeAI.errorMessage = "Failed to analyze \(selectedStockSymbol): \(error.localizedDescription)"
                    isAnalyzingStock = false
                }
            }
        }
    }

    // MARK: - Markdown Builder
    private func buildMarkdown(from analysis: AIStockAnalysis) -> String {
        var lines: [String] = []
        lines.append("# \(analysis.symbol) — \(analysis.analysisType.displayName)")
        lines.append("")
        lines.append("**Rating:** \(analysis.rating.displayName)")
        if let tp = analysis.targetPrice {
            let fmt = NumberFormatter()
            fmt.numberStyle = .currency
            let tpStr = fmt.string(from: NSNumber(value: tp)) ?? "$\(tp)"
            lines.append("**Target Price:** \(tpStr)")
        }
        lines.append("**Timeframe:** \(analysis.timeframe.rawValue.capitalized)")
        lines.append("**Confidence:** \(Int(analysis.confidence))%")
        lines.append("")
        if !analysis.keyPoints.isEmpty {
            lines.append("## Key Points")
            for kp in analysis.keyPoints { lines.append("- \(kp)") }
            lines.append("")
        }
        if !analysis.riskFactors.isEmpty {
            lines.append("## Risks")
            for r in analysis.riskFactors { lines.append("- \(r)") }
            lines.append("")
        }
        lines.append("## Analysis")
        lines.append(analysis.reasoning)
        lines.append("")
        lines.append("_Generated: \(formatShort(analysis.generatedAt))_")
        return lines.joined(separator: "\n")
    }

    private func formatShort(_ date: Date) -> String {
        let df = DateFormatter()
        df.dateStyle = .short
        df.timeStyle = .short
        return df.string(from: date)
    }
    
    private func generateInvestmentIdeas() {
        isGeneratingIdeas = true
        
        Task {
            do {
                let ideas = try await financeAI.generateInvestmentIdeas(
                    userPreferences: financePrefs,
                    portfolio: portfolio
                )
                
                await MainActor.run {
                    investmentIdeas = ideas
                    isGeneratingIdeas = false
                }
            } catch {
                await MainActor.run {
                    financeAI.errorMessage = "Failed to generate investment ideas: \(error.localizedDescription)"
                    isGeneratingIdeas = false
                }
            }
        }
    }
    
    private func loadMarketNews() {
        Task {
            do {
                let news = try await financeAI.getMarketNews(symbols: watchlistSymbols)
                await MainActor.run {
                    marketNews = news
                    showMarketNews = true
                }
            } catch {
                await MainActor.run {
                    financeAI.errorMessage = "Failed to load market news: \(error.localizedDescription)"
                }
            }
        }
    }
}

// MARK: - Supporting Views

struct FinanceStatCard: View {
    let title: String
    let value: String
    let subtitle: String
    let icon: String
    let color: Color
    
    @EnvironmentObject var themeProvider: ThemeProvider
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(color)
                
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(value)
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(themeProvider.theme.textPrimary)
                
                Text(title)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(themeProvider.theme.textSecondary)
                
                Text(subtitle)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(color)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(themeProvider.theme.backgroundSecondary)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(color.opacity(0.2), lineWidth: 1)
                )
        )
    }
}

struct ActionCard: View {
    let title: String
    let subtitle: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    @EnvironmentObject var themeProvider: ThemeProvider
    
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: icon)
                        .font(.system(size: 20))
                        .foregroundColor(color)
                    
                    Spacer()
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(themeProvider.theme.textPrimary)
                    
                    Text(subtitle)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(themeProvider.theme.textSecondary)
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(themeProvider.theme.backgroundSecondary)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(color.opacity(0.2), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(ScaledButtonStyle())
    }
}

struct ScaledButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

#Preview {
    EnhancedFinanceView()
        .environmentObject(ThemeProvider())
        .environmentObject(AuthenticationService())
}
