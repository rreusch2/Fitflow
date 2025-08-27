//
//  FinanceUIComponents.swift
//  Flowmate
//
//  Created on 2025-01-13
//

import SwiftUI

// MARK: - Market Index Card

struct MarketIndexCard: View {
    let index: MarketIndex
    @EnvironmentObject var themeProvider: ThemeProvider
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(index.symbol)
                    .font(.system(size: 14, weight: .bold, design: .monospaced))
                    .foregroundColor(themeProvider.theme.textPrimary)
                
                Spacer()
                
                Image(systemName: index.isPositive ? "arrow.up.circle.fill" : "arrow.down.circle.fill")
                    .font(.system(size: 16))
                    .foregroundColor(index.isPositive ? .green : .red)
            }
            
            Text(index.formattedValue)
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundColor(themeProvider.theme.textPrimary)
            
            Text(index.formattedChange)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(index.isPositive ? .green : .red)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(themeProvider.theme.backgroundSecondary)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke((index.isPositive ? Color.green : Color.red).opacity(0.2), lineWidth: 1)
                )
        )
    }
}

// MARK: - Investment Idea Card

struct InvestmentIdeaCard: View {
    let analysis: AIStockAnalysis
    @EnvironmentObject var themeProvider: ThemeProvider
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(analysis.symbol)
                        .font(.system(size: 20, weight: .bold, design: .monospaced))
                        .foregroundColor(themeProvider.theme.textPrimary)
                    
                    HStack(spacing: 8) {
                        Text(analysis.rating.emoji)
                            .font(.system(size: 16))
                        
                        Text(analysis.rating.displayName)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(Color(analysis.rating.color))
                    }
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    if let targetPrice = analysis.targetPrice {
                        Text("$" + String(format: "%.2f", targetPrice))
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .foregroundColor(themeProvider.theme.textPrimary)
                        
                        Text("Target")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(themeProvider.theme.textSecondary)
                    }
                }
            }
            
            // Key Points
            VStack(alignment: .leading, spacing: 8) {
                Text("Key Points:")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(themeProvider.theme.textPrimary)
                
                ForEach(analysis.keyPoints.prefix(3), id: \.self) { point in
                    HStack(alignment: .top, spacing: 8) {
                        Text("•")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(themeProvider.theme.accent)
                        
                        Text(point)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(themeProvider.theme.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
            
            // Confidence & Timeframe
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "chart.bar.fill")
                        .font(.system(size: 12))
                        .foregroundColor(themeProvider.theme.accent)
                    
                    Text("\(Int(analysis.confidence))% confidence")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(themeProvider.theme.textSecondary)
                }
                
                Spacer()
                
                Text(analysis.timeframe.displayName)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(themeProvider.theme.accent)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(themeProvider.theme.backgroundSecondary)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color(analysis.rating.color).opacity(0.3), lineWidth: 1)
                )
        )
    }
}

// MARK: - Portfolio Insight Card

struct PortfolioInsightCard: View {
    let insight: AIPortfolioInsight
    @EnvironmentObject var themeProvider: ThemeProvider
    
    var body: some View {
        HStack(spacing: 16) {
            // Icon
            VStack {
                Image(systemName: insight.insightType.icon)
                    .font(.system(size: 24))
                    .foregroundColor(Color(insight.insightType.color))
                    .frame(width: 44, height: 44)
                    .background(
                        Circle()
                            .fill(Color(insight.insightType.color).opacity(0.1))
                    )
            }
            
            // Content
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(insight.title)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(themeProvider.theme.textPrimary)
                    
                    Spacer()
                    
                    Text(insight.priority.rawValue.capitalized)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(Color(insight.priority.color))
                        )
                }
                
                Text(insight.description)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(themeProvider.theme.textSecondary)
                    .lineLimit(2)
                
                if insight.actionable && !insight.suggestedActions.isEmpty {
                    Text("💡 \(insight.suggestedActions.first ?? "")")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(themeProvider.theme.accent)
                        .lineLimit(1)
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(themeProvider.theme.backgroundSecondary)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color(insight.insightType.color).opacity(0.2), lineWidth: 1)
                )
        )
    }
}

// MARK: - Stock Analysis Detail View

struct StockAnalysisDetailView: View {
    let analysis: AIStockAnalysis
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var themeProvider: ThemeProvider
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 16) {
                        HStack {
                            Text(analysis.symbol)
                                .font(.system(size: 36, weight: .bold, design: .monospaced))
                                .foregroundColor(themeProvider.theme.textPrimary)
                            
                            Spacer()
                            
                            VStack(alignment: .trailing, spacing: 4) {
                                HStack(spacing: 8) {
                                    Text(analysis.rating.emoji)
                                        .font(.system(size: 24))
                                    
                                    Text(analysis.rating.displayName)
                                        .font(.system(size: 18, weight: .bold))
                                        .foregroundColor(Color(analysis.rating.color))
                                }
                                
                                if let targetPrice = analysis.targetPrice {
                                    Text("Target: $" + String(format: "%.2f", targetPrice))
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundColor(themeProvider.theme.accent)
                                }
                            }
                        }
                        
                        // Analysis Type & Confidence
                        HStack {
                            HStack(spacing: 8) {
                                Image(systemName: analysis.analysisType.icon)
                                    .font(.system(size: 16))
                                    .foregroundColor(themeProvider.theme.accent)
                                
                                Text(analysis.analysisType.displayName)
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(themeProvider.theme.textPrimary)
                            }
                            
                            Spacer()
                            
                            HStack(spacing: 6) {
                                ProgressView(value: analysis.confidence / 100)
                                    .frame(width: 60)
                                    .tint(themeProvider.theme.accent)
                                
                                Text("\(Int(analysis.confidence))%")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(themeProvider.theme.accent)
                            }
                        }
                    }
                    .padding(24)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(themeProvider.theme.backgroundSecondary)
                    )
                    
                    // Reasoning
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Analysis Summary")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(themeProvider.theme.textPrimary)
                        
                        Text(analysis.reasoning)
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(themeProvider.theme.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(20)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(themeProvider.theme.backgroundSecondary)
                    )
                    
                    // Key Points
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Key Investment Points")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(themeProvider.theme.textPrimary)
                        
                        ForEach(analysis.keyPoints, id: \.self) { point in
                            HStack(alignment: .top, spacing: 12) {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 16))
                                    .foregroundColor(.green)
                                
                                Text(point)
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(themeProvider.theme.textSecondary)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(20)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(themeProvider.theme.backgroundSecondary)
                    )
                    
                    // Risk Factors
                    if !analysis.riskFactors.isEmpty {
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Risk Factors")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(themeProvider.theme.textPrimary)
                            
                            ForEach(analysis.riskFactors, id: \.self) { risk in
                                HStack(alignment: .top, spacing: 12) {
                                    Image(systemName: "exclamationmark.triangle.fill")
                                        .font(.system(size: 16))
                                        .foregroundColor(.orange)
                                    
                                    Text(risk)
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundColor(themeProvider.theme.textSecondary)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(20)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(themeProvider.theme.backgroundSecondary)
                        )
                    }
                    
                    // Timeframe
                    HStack {
                        Text("Investment Timeframe:")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(themeProvider.theme.textPrimary)
                        
                        Spacer()
                        
                        Text(analysis.timeframe.displayName)
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(themeProvider.theme.accent)
                    }
                    .padding(20)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(themeProvider.theme.backgroundSecondary)
                    )
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            }
            .background(ThemedBackground().environmentObject(themeProvider))
            .navigationTitle("Stock Analysis")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(themeProvider.theme.accent)
                }
            }
        }
    }
}

// MARK: - Investment Ideas View

struct InvestmentIdeasView: View {
    let ideas: [AIStockAnalysis]
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var themeProvider: ThemeProvider
    
    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 16) {
                    ForEach(ideas) { idea in
                        InvestmentIdeaCard(analysis: idea)
                            .environmentObject(themeProvider)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
            }
            .background(ThemedBackground().environmentObject(themeProvider))
            .navigationTitle("Investment Ideas")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(themeProvider.theme.accent)
                }
            }
        }
    }
}

// MARK: - Portfolio Insights View

struct PortfolioInsightsView: View {
    let insights: [AIPortfolioInsight]
    let portfolio: Portfolio
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var themeProvider: ThemeProvider
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Portfolio Summary
                    VStack(spacing: 16) {
                        HStack {
                            Text("Portfolio Overview")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(themeProvider.theme.textPrimary)
                            
                            Spacer()
                        }
                        
                        HStack(spacing: 20) {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Total Value")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(themeProvider.theme.textSecondary)
                                
                                Text(portfolio.formattedTotalValue)
                                    .font(.system(size: 24, weight: .bold, design: .rounded))
                                    .foregroundColor(themeProvider.theme.textPrimary)
                            }
                            
                            Spacer()
                            
                            VStack(spacing: 12) {
                                HStack {
                                    Text("Risk: \(Int(portfolio.riskScore))/100")
                                        .font(.system(size: 12, weight: .semibold))
                                        .foregroundColor(.orange)
                                }
                                
                                HStack {
                                    Text("Diversification: \(Int(portfolio.diversificationScore))/100")
                                        .font(.system(size: 12, weight: .semibold))
                                        .foregroundColor(.blue)
                                }
                            }
                        }
                    }
                    .padding(20)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(themeProvider.theme.backgroundSecondary)
                    )
                    
                    // Insights
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Text("AI Insights")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(themeProvider.theme.textPrimary)
                            
                            Spacer()
                            
                            Text("\(insights.count) insights")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(themeProvider.theme.accent)
                        }
                        
                        ForEach(insights) { insight in
                            ExpandedInsightCard(insight: insight)
                                .environmentObject(themeProvider)
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
            }
            .background(ThemedBackground().environmentObject(themeProvider))
            .navigationTitle("Portfolio Insights")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(themeProvider.theme.accent)
                }
            }
        }
    }
}

// MARK: - Expanded Insight Card

struct ExpandedInsightCard: View {
    let insight: AIPortfolioInsight
    @EnvironmentObject var themeProvider: ThemeProvider
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                HStack(spacing: 12) {
                    Image(systemName: insight.insightType.icon)
                        .font(.system(size: 20))
                        .foregroundColor(Color(insight.insightType.color))
                    
                    Text(insight.title)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(themeProvider.theme.textPrimary)
                }
                
                Spacer()
                
                Text(insight.priority.rawValue.capitalized)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(Color(insight.priority.color))
                    )
            }
            
            // Description
            Text(insight.description)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(themeProvider.theme.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
            
            // Suggested Actions
            if insight.actionable && !insight.suggestedActions.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Suggested Actions:")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(themeProvider.theme.textPrimary)
                    
                    ForEach(insight.suggestedActions, id: \.self) { action in
                        HStack(alignment: .top, spacing: 10) {
                            Text("→")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(themeProvider.theme.accent)
                            
                            Text(action)
                                .font(.system(size: 15, weight: .medium))
                                .foregroundColor(themeProvider.theme.textSecondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
            }
            
            // Potential Impact
            if !insight.potentialImpact.isEmpty {
                HStack(spacing: 10) {
                    Image(systemName: "target")
                        .font(.system(size: 16))
                        .foregroundColor(themeProvider.theme.accent)
                    
                    Text("Expected Impact: \(insight.potentialImpact)")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(themeProvider.theme.accent)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(themeProvider.theme.backgroundSecondary)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color(insight.insightType.color).opacity(0.3), lineWidth: 1)
                )
        )
    }
}

// MARK: - Market News View

struct MarketNewsView: View {
    let news: [StockNews]
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var themeProvider: ThemeProvider
    
    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 16) {
                    ForEach(news) { article in
                        NewsCard(article: article)
                            .environmentObject(themeProvider)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
            }
            .background(ThemedBackground().environmentObject(themeProvider))
            .navigationTitle("Market News")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(themeProvider.theme.accent)
                }
            }
        }
    }
}

// MARK: - News Card

struct NewsCard: View {
    let article: StockNews
    @EnvironmentObject var themeProvider: ThemeProvider
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                HStack(spacing: 8) {
                    Text(article.sentiment.emoji)
                        .font(.system(size: 16))
                    
                    Text(article.sentiment.rawValue.capitalized)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(Color(article.sentiment.color))
                }
                
                Spacer()
                
                Text(article.source)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(themeProvider.theme.textSecondary)
            }
            
            // Headline
            Text(article.headline)
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(themeProvider.theme.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
            
            // Summary
            Text(article.summary)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(themeProvider.theme.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
            
            // Related Stocks & Date
            HStack {
                if !article.relatedStocks.isEmpty {
                    HStack(spacing: 6) {
                        ForEach(article.relatedStocks.prefix(3), id: \.self) { stock in
                            Text(stock)
                                .font(.system(size: 10, weight: .bold, design: .monospaced))
                                .foregroundColor(.white)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(
                                    Capsule()
                                        .fill(themeProvider.theme.accent)
                                )
                        }
                    }
                }
                
                Spacer()
                
                Text(article.publishedDate, style: .relative)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(themeProvider.theme.textSecondary)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(themeProvider.theme.backgroundSecondary)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color(article.sentiment.color).opacity(0.2), lineWidth: 1)
                )
        )
    }
}

// MARK: - Finance Settings View

struct FinanceSettingsView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var themeProvider: ThemeProvider
    @EnvironmentObject var authService: AuthenticationService
    
    @State private var prefs = FinancePreferences()
    @State private var preferredSectorsInput: String = ""
    @State private var isSaving = false
    @State private var errorMessage: String?
    @State private var successMessage: String?
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Risk Tolerance
                    settingsSection(title: "Risk Tolerance") {
                        Picker("Risk Tolerance", selection: $prefs.riskTolerance) {
                            ForEach(FinancePreferences.RiskTolerance.allCases, id: \.self) { rt in
                                Text(rt.displayName).tag(rt)
                            }
                        }
                        .pickerStyle(.segmented)
                    }
                    
                    // Investment Goals
                    settingsSection(title: "Investment Goals") {
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                            ForEach(FinancePreferences.InvestmentGoal.allCases, id: \.self) { goal in
                                let isSelected = prefs.investmentGoals.contains(goal)
                                Button {
                                    toggleGoal(goal)
                                } label: {
                                    HStack {
                                        Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                                            .foregroundColor(isSelected ? themeProvider.theme.accent : themeProvider.theme.textSecondary)
                                        Text(goal.displayName)
                                            .foregroundColor(themeProvider.theme.textPrimary)
                                            .font(.system(size: 14, weight: .semibold))
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(10)
                                    .background(
                                        RoundedRectangle(cornerRadius: 10)
                                            .fill(themeProvider.theme.backgroundPrimary)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 10)
                                                    .stroke((isSelected ? themeProvider.theme.accent : themeProvider.theme.textSecondary).opacity(0.2), lineWidth: 1)
                                            )
                                    )
                                }
                            }
                        }
                    }
                    
                    // Preferred Sectors
                    settingsSection(title: "Preferred Sectors") {
                        VStack(alignment: .leading, spacing: 10) {
                            TextField("e.g. Technology, Healthcare, Energy", text: $preferredSectorsInput)
                                .textInputAutocapitalization(.words)
                                .disableAutocorrection(true)
                                .padding(12)
                                .background(
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(themeProvider.theme.backgroundPrimary)
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(themeProvider.theme.textSecondary.opacity(0.15), lineWidth: 1)
                                )
                            if !prefs.preferredSectors.isEmpty {
                                WrapHStack(spacing: 8, runSpacing: 8) {
                                    ForEach(prefs.preferredSectors, id: \.self) { sector in
                                        HStack(spacing: 6) {
                                            Text(sector)
                                                .font(.system(size: 12, weight: .semibold))
                                                .foregroundColor(themeProvider.theme.accent)
                                            Button(action: { removeSector(sector) }) {
                                                Image(systemName: "xmark.circle.fill")
                                                    .font(.system(size: 12))
                                                    .foregroundColor(themeProvider.theme.textSecondary)
                                            }
                                        }
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 6)
                                        .background(
                                            Capsule()
                                                .fill(themeProvider.theme.accent.opacity(0.12))
                                        )
                                    }
                                }
                            }
                            HStack {
                                Spacer()
                                Button {
                                    addSectorsFromInput()
                                } label: {
                                    Label("Add", systemImage: "plus")
                                }
                                .buttonStyle(.borderedProminent)
                                .tint(themeProvider.theme.accent)
                            }
                        }
                    }
                    
                    // Portfolio Size
                    settingsSection(title: "Portfolio Size") {
                        Picker("Portfolio Size", selection: $prefs.portfolioSize) {
                            ForEach(FinancePreferences.PortfolioSize.allCases, id: \.self) { size in
                                Text(size.displayName).tag(size)
                            }
                        }
                        .pickerStyle(.menu)
                    }
                    
                    // Trading Experience
                    settingsSection(title: "Trading Experience") {
                        Picker("Experience", selection: $prefs.tradingExperience) {
                            ForEach(FinancePreferences.TradingExperience.allCases, id: \.self) { level in
                                Text(level.displayName).tag(level)
                            }
                        }
                        .pickerStyle(.segmented)
                    }
                    
                    if let error = errorMessage {
                        Text(error)
                            .foregroundColor(.red)
                            .font(.system(size: 14, weight: .semibold))
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    if let ok = successMessage {
                        Text(ok)
                            .foregroundColor(.green)
                            .font(.system(size: 14, weight: .semibold))
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    
                    // Save Button
                    Button(action: saveSettings) {
                        HStack {
                            if isSaving { ProgressView().scaleEffect(0.9) }
                            Text(isSaving ? "Saving..." : "Save Settings")
                        }
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.vertical, 14)
                        .frame(maxWidth: .infinity)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(themeProvider.theme.accent)
                        )
                    }
                    .disabled(isSaving)
                }
                .padding(20)
            }
            .background(ThemedBackground().environmentObject(themeProvider))
            .navigationTitle("Finance Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundColor(themeProvider.theme.accent)
                }
            }
            .onAppear { loadExisting() }
        }
    }
    
    private func settingsSection<T: View>(title: String, @ViewBuilder content: () -> T) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(themeProvider.theme.textPrimary)
            content()
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(themeProvider.theme.backgroundSecondary)
        )
    }
    
    private func toggleGoal(_ goal: FinancePreferences.InvestmentGoal) {
        if let idx = prefs.investmentGoals.firstIndex(of: goal) {
            prefs.investmentGoals.remove(at: idx)
        } else {
            prefs.investmentGoals.append(goal)
        }
    }
    
    private func addSectorsFromInput() {
        let parts = preferredSectorsInput
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        guard !parts.isEmpty else { return }
        var set = Set(prefs.preferredSectors)
        for p in parts { set.insert(p) }
        prefs.preferredSectors = Array(set)
        preferredSectorsInput = ""
    }
    
    private func removeSector(_ sector: String) {
        prefs.preferredSectors.removeAll { $0.caseInsensitiveCompare(sector) == .orderedSame }
    }
    
    private func loadExisting() {
        // Map from existing wealth preferences if present
        if let wealth = authService.currentUser?.preferences?.wealth {
            prefs.riskTolerance = {
                switch wealth.risk {
                case .low: return .conservative
                case .moderate: return .moderate
                case .high: return .aggressive
                }
            }()
            var goals: [FinancePreferences.InvestmentGoal] = []
            for g in wealth.goals {
                switch g {
                case .saving, .debtFree: goals.append(.wealth)
                case .investing: goals.append(.wealth)
                case .income: goals.append(.income)
                }
            }
            prefs.investmentGoals = Array(Set(goals))
        }
    }
    
    private func saveSettings() {
        guard let _ = authService.currentUser else {
            errorMessage = "You must be signed in to save settings."
            return
        }
        errorMessage = nil
        successMessage = nil
        isSaving = true
        
        Task {
            defer { isSaving = false }
            do {
                // Persist via DatabaseService RPC (to be implemented server-side)
                try await DatabaseService.shared.updateFinancePreferences(preferences: prefs)
                await MainActor.run {
                    successMessage = "Preferences saved!"
                }
            } catch {
                await MainActor.run {
                    errorMessage = "Failed to save: \(error.localizedDescription)"
                }
            }
        }
    }
}

// Small helper for wrapping chips
struct WrapHStack<Content: View>: View {
    let spacing: CGFloat
    let runSpacing: CGFloat
    let content: () -> Content
    
    init(spacing: CGFloat = 8, runSpacing: CGFloat = 8, @ViewBuilder content: @escaping () -> Content) {
        self.spacing = spacing
        self.runSpacing = runSpacing
        self.content = content
    }
    
    var body: some View {
        GeometryReader { geometry in
            self.generateContent(in: geometry)
        }
        .frame(minHeight: 0)
    }
    
    private func generateContent(in g: GeometryProxy) -> some View {
        var width: CGFloat = 0
        var height: CGFloat = 0
        return ZStack(alignment: .topLeading) {
            content()
                .fixedSize()
                .alignmentGuide(.leading) { d in
                    if (abs(width - d.width) > g.size.width) {
                        width = 0
                        height -= d.height + runSpacing
                    }
                    let result = width
                    if content() is EmptyView { width = 0 } else { width -= d.width + spacing }
                    return result
                }
                .alignmentGuide(.top) { _ in height }
        }
    }
}
