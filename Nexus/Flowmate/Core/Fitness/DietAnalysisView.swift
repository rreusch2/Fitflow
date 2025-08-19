//
//  DietAnalysisView.swift
//  Flowmate
//
//  Diet analysis display with AI insights and recommendations
//

import SwiftUI

struct DietAnalysisView: View {
    @EnvironmentObject var themeProvider: ThemeProvider
    @Environment(\.dismiss) private var dismiss
    let analysis: NutritionAIService.DietAnalysis
    @State private var selectedTab = 0
    
    var tabs = ["Overview", "Nutrients", "Recommendations"]
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Custom Tab Bar
                tabBar
                
                TabView(selection: $selectedTab) {
                    // Overview Tab
                    overviewTab
                        .tag(0)
                    
                    // Nutrients Tab
                    nutrientsTab
                        .tag(1)
                    
                    // Recommendations Tab
                    recommendationsTab
                        .foregroundColor(statusColor)
                        .padding(.vertical, 2)
                        .tag(2)
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            }
            .background(ThemedBackground().environmentObject(themeProvider))
            .navigationTitle("Diet Analysis")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                    .foregroundColor(themeProvider.theme.accent)
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        // Share analysis
                    } label: {
                        Image(systemName: "square.and.arrow.up")
                            .foregroundColor(themeProvider.theme.accent)
                    }
                }
            }
        }
    }
    
    private var tabBar: some View {
        HStack(spacing: 0) {
            ForEach(0..<tabs.count, id: \.self) { index in
                Button {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        selectedTab = index
                    }
                } label: {
                    VStack(spacing: 8) {
                        Text(tabs[index])
                            .font(.system(size: 16, weight: selectedTab == index ? .semibold : .medium))
                            .foregroundColor(selectedTab == index ? themeProvider.theme.accent : themeProvider.theme.textSecondary)
                        
                        Rectangle()
                            .fill(selectedTab == index ? themeProvider.theme.accent : Color.clear)
                            .frame(height: 3)
                            .animation(.easeInOut(duration: 0.3), value: selectedTab)
                    }
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding(.horizontal, 20)
        .background(themeProvider.theme.backgroundPrimary)
    }
    
    private var overviewTab: some View {
        ScrollView {
            VStack(spacing: 24) {
                headerSection
                scoreSection
                trendsSection
                habitInsightsSection
            }
            .padding(.vertical, 20)
        }
    }
    
    private var nutrientsTab: some View {
        ScrollView {
            VStack(spacing: 24) {
                macroBreakdownSection
                micronutrientSection
                hydrationSection
            }
            .padding(.vertical, 20)
        }
    }
    
    private var recommendationsTab: some View {
        ScrollView {
            VStack(spacing: 24) {
                priorityRecommendationsSection
                mealTimingSection
                supplementsSection
            }
            .padding(.vertical, 20)
        }
    }
    
    // MARK: - Overview Tab Sections
    
    private var headerSection: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Analysis Period")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(themeProvider.theme.textPrimary)
                    
                    Text(analysis.periodDescription)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(themeProvider.theme.textSecondary)
                }
                
                Spacer()
                
                VStack(spacing: 4) {
                    Text("📊")
                        .font(.system(size: 32))
                    Text("\(analysis.daysAnalyzed) Days")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(Color.blue)
                }
            }
        }
        .padding(.horizontal, 20)
    }
    
    private var scoreSection: some View {
        VStack(spacing: 16) {
            Text("Overall Diet Score")
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(themeProvider.theme.textPrimary)
                .padding(.horizontal, 20)
            
            ZStack {
                Circle()
                    .stroke(themeProvider.theme.backgroundSecondary, lineWidth: 12)
                    .frame(width: 120, height: 120)
                
                Circle()
                    .trim(from: 0, to: analysis.overallScore / 100)
                    .stroke(
                        LinearGradient(
                            colors: scoreGradientColors,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        style: StrokeStyle(lineWidth: 12, lineCap: .round)
                    )
                    .frame(width: 120, height: 120)
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 1.0), value: analysis.overallScore)
                
                VStack(spacing: 4) {
                    Text("\(Int(analysis.overallScore))")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(themeProvider.theme.textPrimary)
                    
                    Text("/ 100")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(themeProvider.theme.textSecondary)
                }
            }
            
            Text(scoreDescription)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(themeProvider.theme.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
        .padding(.vertical, 20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(themeProvider.theme.backgroundSecondary)
                .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
        )
        .padding(.horizontal, 20)
    }
    
    private var trendsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Key Trends")
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(themeProvider.theme.textPrimary)
                .padding(.horizontal, 20)
            
            VStack(spacing: 12) {
                ForEach(analysis.keyTrends, id: \.id) { trend in
                    TrendCard(trend: trend)
                }
            }
            .padding(.horizontal, 20)
        }
    }
    
    private var habitInsightsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Eating Habits")
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(themeProvider.theme.textPrimary)
                .padding(.horizontal, 20)
            
            VStack(spacing: 12) {
                ForEach(analysis.habitInsights, id: \.id) { insight in
                    HabitInsightCard(insight: insight)
                }
            }
            .padding(.horizontal, 20)
        }
    }
    
    // MARK: - Nutrients Tab Sections
    
    private var macroBreakdownSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Macronutrient Breakdown")
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(themeProvider.theme.textPrimary)
                .padding(.horizontal, 20)
            
            HStack(spacing: 16) {
                MacroCircle(
                    title: "Protein",
                    percentage: analysis.macroBreakdown.proteinPercent,
                    color: .red,
                    average: "\(Int(analysis.macroBreakdown.avgProtein))g"
                )
                MacroCircle(
                    title: "Carbs",
                    percentage: analysis.macroBreakdown.carbsPercent,
                    color: .orange,
                    average: "\(Int(analysis.macroBreakdown.avgCarbs))g"
                )
                MacroCircle(
                    title: "Fat",
                    percentage: analysis.macroBreakdown.fatPercent,
                    color: .green,
                    average: "\(Int(analysis.macroBreakdown.avgFat))g"
                )
            }
            .padding(.horizontal, 20)
        }
    }
    
    private var micronutrientSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Micronutrients")
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(themeProvider.theme.textPrimary)
                .padding(.horizontal, 20)
            
            VStack(spacing: 12) {
                ForEach(analysis.micronutrientStatus, id: \.nutrient) { status in
                    MicronutrientBar(status: status)
                }
            }
            .padding(.horizontal, 20)
        }
    }
    
    private var hydrationSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Hydration")
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(themeProvider.theme.textPrimary)
                .padding(.horizontal, 20)
            
            HStack(spacing: 16) {
                VStack(spacing: 8) {
                    Text("💧")
                        .font(.system(size: 32))
                    Text("Avg Daily")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(themeProvider.theme.textSecondary)
                    Text("\(analysis.avgDailyWater, specifier: "%.1f")L")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.blue)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.blue.opacity(0.1))
                )
                
                VStack(spacing: 8) {
                    Text(analysis.hydrationStatus.emoji)
                        .font(.system(size: 32))
                    Text("Status")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(themeProvider.theme.textSecondary)
                    Text(analysis.hydrationStatus.description)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(analysis.hydrationStatus.color)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(analysis.hydrationStatus.color.opacity(0.1))
                )
            }
            .padding(.horizontal, 20)
        }
    }
    
    // MARK: - Recommendations Tab Sections
    
    private var priorityRecommendationsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Priority Recommendations")
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(themeProvider.theme.textPrimary)
                .padding(.horizontal, 20)
            
            VStack(spacing: 12) {
                ForEach(analysis.recommendations.priority, id: \.id) { recommendation in
                    RecommendationCard(recommendation: recommendation, isPriority: true)
                }
            }
            .padding(.horizontal, 20)
        }
    }
    
    private var mealTimingSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Meal Timing Insights")
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(themeProvider.theme.textPrimary)
                .padding(.horizontal, 20)
            
            VStack(spacing: 12) {
                ForEach(analysis.recommendations.mealTiming, id: \.id) { recommendation in
                    RecommendationCard(recommendation: recommendation, isPriority: false)
                }
            }
            .padding(.horizontal, 20)
        }
    }
    
    private var supplementsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Supplement Suggestions")
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(themeProvider.theme.textPrimary)
                .padding(.horizontal, 20)
            
            VStack(spacing: 12) {
                ForEach(analysis.recommendations.supplements, id: \.id) { recommendation in
                    RecommendationCard(recommendation: recommendation, isPriority: false)
                }
            }
            .padding(.horizontal, 20)
        }
    }
    
    // MARK: - Computed Properties
    
    private var scoreGradientColors: [Color] {
        if analysis.overallScore >= 80 {
            return [.green, .blue]
        } else if analysis.overallScore >= 60 {
            return [.yellow, .orange]
        } else {
            return [.orange, .red]
        }
    }
    
    private var scoreDescription: String {
        if analysis.overallScore >= 80 {
            return "Excellent! Your diet is well-balanced and nutrient-rich."
        } else if analysis.overallScore >= 60 {
            return "Good foundation with room for improvement in some areas."
        } else {
            return "Several areas need attention to optimize your nutrition."
        }
    }
}

// MARK: - Supporting Views

struct TrendCard: View {
    let trend: NutritionAIService.DietAnalysis.Trend
    @EnvironmentObject var themeProvider: ThemeProvider
    
    var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(trend.color)
                .frame(width: 12, height: 12)
            
            Text(trend.title)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(themeProvider.theme.textPrimary)
            
            Text("\(Int(trend.percentage))%")
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(trend.color)
            Image(systemName: trend.isPositive ? "arrow.up.right" : "arrow.down.right")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(trend.isPositive ? .green : .red)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(themeProvider.theme.backgroundSecondary)
                .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
        )
    }
}

struct HabitInsightCard: View {
    let insight: NutritionAIService.DietAnalysis.HabitInsight
    @EnvironmentObject var themeProvider: ThemeProvider
    
    var body: some View {
        HStack(spacing: 12) {
            Text(insight.emoji)
                .font(.system(size: 24))
            
            VStack(alignment: .leading, spacing: 4) {
                Text(insight.habit)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(themeProvider.theme.textPrimary)
                
                Text(insight.insight)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(themeProvider.theme.textSecondary)
                    .lineLimit(3)
            }
            
            Spacer()
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(themeProvider.theme.backgroundSecondary)
                .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
        )
    }
}

struct MacroCircle: View {
    let title: String
    let percentage: Double
    let color: Color
    let average: String
    @EnvironmentObject var themeProvider: ThemeProvider
    
    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .stroke(color.opacity(0.2), lineWidth: 8)
                    .frame(width: 80, height: 80)
                
                Circle()
                    .trim(from: 0, to: percentage / 100)
                    .stroke(color, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                    .frame(width: 80, height: 80)
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 1.0), value: percentage)
                
                Text("\(Int(percentage))%")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(themeProvider.theme.textPrimary)
            }
            
            Text(title)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(themeProvider.theme.textPrimary)
            
            Text(average)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(themeProvider.theme.textSecondary)
        }
        .frame(maxWidth: .infinity)
    }
}

struct MicronutrientBar: View {
    let status: NutritionAIService.DietAnalysis.MicronutrientStatus
    @EnvironmentObject var themeProvider: ThemeProvider
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(status.nutrient)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(themeProvider.theme.textPrimary)
                
                Spacer()
                
                Text(status.statusText)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(status.statusColor)
            }
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(themeProvider.theme.backgroundSecondary)
                        .frame(height: 6)
                        .clipShape(Capsule())
                    
                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: [status.statusColor.opacity(0.7), status.statusColor],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geometry.size.width * (status.adequacyPercent / 100), height: 6)
                        .clipShape(Capsule())
                        .animation(.easeInOut(duration: 1.0), value: status.adequacyPercent)
                }
            }
            .frame(height: 6)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(themeProvider.theme.backgroundSecondary)
                .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
        )
    }
}

struct RecommendationCard: View {
    let recommendation: NutritionAIService.DietAnalysis.Recommendation
    let isPriority: Bool
    @EnvironmentObject var themeProvider: ThemeProvider
    
    var body: some View {
        HStack(spacing: 12) {
            if isPriority {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 20))
                    .foregroundColor(.orange)
            } else {
                Text(recommendationEmoji)
                    .font(.system(size: 24))
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(recommendation.title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(themeProvider.theme.textPrimary)
                
                Text(recommendation.description)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(themeProvider.theme.textSecondary)
                    .lineLimit(3)
            }
            
            Spacer()
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(isPriority ? Color.orange.opacity(0.05) : themeProvider.theme.backgroundSecondary)
                .stroke(isPriority ? Color.orange.opacity(0.3) : Color.clear, lineWidth: 1)
                .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
        )
    }
    
    private var recommendationEmoji: String {
        switch recommendation.category.lowercased() {
        case "timing": return "⏰"
        case "supplements": return "💊"
        case "hydration": return "💧"
        case "portions": return "🥄"
        default: return "💡"
        }
    }
}

#Preview {
    DietAnalysisView(analysis: NutritionAIService.DietAnalysis(
        id: UUID(),
        daysAnalyzed: 7,
        overallScore: 78.5,
        periodDescription: "Last 7 days",
        keyTrends: [],
        habitInsights: [],
        macroBreakdown: NutritionAIService.DietAnalysis.MacroBreakdown(
            proteinPercent: 25,
            carbsPercent: 45,
            fatPercent: 30,
            avgProtein: 120,
            avgCarbs: 225,
            avgFat: 75
        ),
        micronutrientStatus: [],
        avgDailyWater: 2.1,
        hydrationStatus: NutritionAIService.DietAnalysis.HydrationStatus(
            description: "Good",
            emoji: "💧",
            color: "blue"
        ),
        recommendations: NutritionAIService.DietAnalysis.Recommendations(
            priority: [],
            mealTiming: [],
            supplements: []
        )
    ))
    .environmentObject(ThemeProvider())
}
