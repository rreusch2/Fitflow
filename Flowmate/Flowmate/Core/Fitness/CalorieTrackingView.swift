//
//  CalorieTrackingView.swift
//  Flowmate
//
//  Comprehensive calorie tracking with daily, weekly, and monthly views
//

import SwiftUI
import Charts

struct CalorieTrackingView: View {
    @EnvironmentObject var themeProvider: ThemeProvider
    @Environment(\.dismiss) private var dismiss
    @StateObject private var nutritionService = NutritionService.shared
    
    @State private var selectedPeriod: TrackingPeriod = .daily
    @State private var selectedDate = Date()
    @State private var showingAddMeal = false
    @State private var showingMealDetail: Meal?
    
    enum TrackingPeriod: String, CaseIterable {
        case daily = "Daily"
        case weekly = "Weekly"
        case monthly = "Monthly"
        case yearly = "Yearly"
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Period Selector
                periodSelector
                
                // Main Content
                ScrollView {
                    VStack(spacing: 24) {
                        // Summary Cards
                        summarySection
                        
                        // Chart Section
                        chartSection
                        
                        // Detailed Breakdown
                        if selectedPeriod == .daily {
                            dailyMealsSection
                        } else {
                            periodicBreakdownSection
                        }
                    }
                    .padding(.bottom, 100)
                }
            }
            .background(ThemedBackground().environmentObject(themeProvider))
            .navigationTitle("Calorie Tracking")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                    .foregroundColor(themeProvider.theme.accent)
                }
                
                if selectedPeriod == .daily {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            showingAddMeal = true
                        } label: {
                            Image(systemName: "plus")
                                .foregroundColor(themeProvider.theme.accent)
                        }
                    }
                }
            }
        }
        .sheet(isPresented: $showingAddMeal) {
            AddMealView()
        }
        .sheet(item: $showingMealDetail) { meal in
            MealDetailView(meal: meal)
        }
        .task {
            await nutritionService.loadUserData()
        }
    }
    
    private var periodSelector: some View {
        HStack(spacing: 0) {
            ForEach(TrackingPeriod.allCases, id: \.self) { period in
                Button {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        selectedPeriod = period
                    }
                } label: {
                    Text(period.rawValue)
                        .font(.system(size: 16, weight: selectedPeriod == period ? .semibold : .medium))
                        .foregroundColor(selectedPeriod == period ? themeProvider.theme.accent : themeProvider.theme.textSecondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            Rectangle()
                                .fill(selectedPeriod == period ? themeProvider.theme.accent.opacity(0.1) : Color.clear)
                        )
                }
            }
        }
        .background(themeProvider.theme.backgroundSecondary)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
    }
    
    private var summarySection: some View {
        HStack(spacing: 16) {
            CalorieSummaryCard(
                title: "Consumed",
                value: currentCalories,
                target: targetCalories,
                color: .blue,
                unit: "cal"
            )
            
            CalorieSummaryCard(
                title: "Remaining",
                value: max(targetCalories - currentCalories, 0),
                target: targetCalories,
                color: .green,
                unit: "cal"
            )
            
            CalorieSummaryCard(
                title: "Progress",
                value: min((currentCalories / targetCalories) * 100, 100),
                target: 100,
                color: progressColor,
                unit: "%"
            )
        }
        .padding(.horizontal, 20)
    }
    
    private var chartSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Calorie Trends")
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(themeProvider.theme.textPrimary)
                .padding(.horizontal, 20)
            
            Chart(chartData, id: \.date) { dataPoint in
                LineMark(
                    x: .value("Date", dataPoint.date),
                    y: .value("Calories", dataPoint.calories)
                )
                .foregroundStyle(themeProvider.theme.accent)
                .lineStyle(StrokeStyle(lineWidth: 3))
                
                PointMark(
                    x: .value("Date", dataPoint.date),
                    y: .value("Calories", dataPoint.calories)
                )
                .foregroundStyle(themeProvider.theme.accent)
                .symbolSize(80)
                
                // Target line
                RuleMark(y: .value("Target", targetCalories))
                    .foregroundStyle(.gray.opacity(0.5))
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [5]))
            }
            .frame(height: 200)
            .chartXAxis {
                AxisMarks(values: .automatic) { _ in
                    AxisGridLine()
                    AxisTick()
                    AxisValueLabel(format: .dateTime.month(.abbreviated).day())
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading)
            }
            .padding(.horizontal, 20)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(themeProvider.theme.backgroundSecondary)
                    .shadow(color: Color.black.opacity(0.05), radius: 6, x: 0, y: 3)
            )
            .padding(.horizontal, 20)
        }
    }
    
    private var dailyMealsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Today's Meals")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(themeProvider.theme.textPrimary)
                
                Spacer()
                
                Button {
                    showingAddMeal = true
                } label: {
                    Text("Add Meal")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(themeProvider.theme.accent)
                }
            }
            .padding(.horizontal, 20)
            
            VStack(spacing: 12) {
                ForEach(todaysMeals, id: \.id) { meal in
                    Button {
                        showingMealDetail = meal
                    } label: {
                        MealTrackingCard(meal: meal)
                    }
                }
                
                if todaysMeals.isEmpty {
                    EmptyMealsView {
                        showingAddMeal = true
                    }
                }
            }
            .padding(.horizontal, 20)
        }
    }
    
    private var periodicBreakdownSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("\(selectedPeriod.rawValue) Breakdown")
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(themeProvider.theme.textPrimary)
                .padding(.horizontal, 20)
            
            VStack(spacing: 12) {
                MacroBreakdownCard(
                    title: "Average Daily Calories",
                    current: averageCalories,
                    target: targetCalories,
                    color: .blue
                )
                
                MacroBreakdownCard(
                    title: "Average Protein",
                    current: averageProtein,
                    target: targetProtein,
                    color: .red
                )
                
                MacroBreakdownCard(
                    title: "Average Carbs",
                    current: averageCarbs,
                    target: targetCarbs,
                    color: .orange
                )
                
                MacroBreakdownCard(
                    title: "Average Fat",
                    current: averageFat,
                    target: targetFat,
                    color: .green
                )
            }
            .padding(.horizontal, 20)
        }
    }
    
    // MARK: - Computed Properties
    
    private var currentCalories: Double {
        todaysMeals.reduce(0) { $0 + Double($1.calories) }
    }
    
    private var targetCalories: Double {
        Double(nutritionService.goals?.targetCalories ?? 2000)
    }
    
    private var progressColor: Color {
        let progress = currentCalories / targetCalories
        if progress < 0.5 { return .red }
        if progress < 0.8 { return .orange }
        if progress <= 1.0 { return .green }
        return .blue
    }
    
    private var todaysMeals: [Meal] {
        // This would be fetched from nutritionService
        []
    }
    
    private var chartData: [CalorieDataPoint] {
        // Generate sample data based on selected period
        let calendar = Calendar.current
        let endDate = selectedDate
        let startDate: Date
        
        switch selectedPeriod {
        case .daily:
            startDate = calendar.date(byAdding: .day, value: -7, to: endDate) ?? endDate
        case .weekly:
            startDate = calendar.date(byAdding: .weekOfYear, value: -8, to: endDate) ?? endDate
        case .monthly:
            startDate = calendar.date(byAdding: .month, value: -6, to: endDate) ?? endDate
        case .yearly:
            startDate = calendar.date(byAdding: .year, value: -3, to: endDate) ?? endDate
        }
        
        return generateSampleData(from: startDate, to: endDate)
    }
    
    private var averageCalories: Double { 2150 }
    private var averageProtein: Double { 125 }
    private var averageCarbs: Double { 220 }
    private var averageFat: Double { 85 }
    
    private var targetProtein: Double { nutritionService.goals?.targetMacros?.protein ?? 120 }
    private var targetCarbs: Double { nutritionService.goals?.targetMacros?.carbs ?? 250 }
    private var targetFat: Double { nutritionService.goals?.targetMacros?.fat ?? 70 }
    
    private func generateSampleData(from startDate: Date, to endDate: Date) -> [CalorieDataPoint] {
        var data: [CalorieDataPoint] = []
        let calendar = Calendar.current
        var currentDate = startDate
        
        while currentDate <= endDate {
            let calories = Double.random(in: 1800...2400)
            data.append(CalorieDataPoint(date: currentDate, calories: calories))
            currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate) ?? currentDate
        }
        
        return data
    }
}

struct CalorieDataPoint {
    let date: Date
    let calories: Double
}

struct CalorieSummaryCard: View {
    let title: String
    let value: Double
    let target: Double
    let color: Color
    let unit: String
    @EnvironmentObject var themeProvider: ThemeProvider
    
    var body: some View {
        VStack(spacing: 8) {
            Text(title)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(themeProvider.theme.textSecondary)
            
            Text(formatValue(value))
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(color)
            
            if unit == "%" {
                ProgressView(value: value / 100)
                    .progressViewStyle(LinearProgressViewStyle(tint: color))
                    .scaleEffect(x: 1, y: 0.5)
            } else {
                Text("of \(formatValue(target))")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(themeProvider.theme.textSecondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(color.opacity(0.1))
                .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
        )
    }
    
    private func formatValue(_ value: Double) -> String {
        if unit == "%" {
            return String(format: "%.0f%%", value)
        } else {
            return String(format: "%.0f", value)
        }
    }
}

struct MealTrackingCard: View {
    let meal: Meal
    @EnvironmentObject var themeProvider: ThemeProvider
    
    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(meal.type.displayName)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Capsule().fill(meal.type.color))
                    
                    Spacer()
                    
                    Text("\(meal.calories) cal")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(themeProvider.theme.accent)
                }
                
                Text(meal.name)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(themeProvider.theme.textPrimary)
                
                HStack(spacing: 16) {
                    MacroIndicator(label: "P", value: Double(meal.macros.protein), color: .red)
                    MacroIndicator(label: "C", value: Double(meal.macros.carbs), color: .orange)
                    MacroIndicator(label: "F", value: Double(meal.macros.fat), color: .green)
                    
                    Spacer()
                    
                    Text("Today")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(themeProvider.theme.textSecondary)
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(themeProvider.theme.backgroundSecondary)
                .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
        )
    }
}

struct MacroIndicator: View {
    let label: String
    let value: Double
    let color: Color
    
    var body: some View {
        VStack(spacing: 2) {
            Text("\(Int(value))g")
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(color)
            Text(label)
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(color.opacity(0.7))
        }
    }
}

struct MacroBreakdownCard: View {
    let title: String
    let current: Double
    let target: Double
    let color: Color
    @EnvironmentObject var themeProvider: ThemeProvider
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(themeProvider.theme.textPrimary)
                
                Text("\(Int(current)) / \(Int(target))")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(themeProvider.theme.textSecondary)
            }
            
            Spacer()
            
            CircularProgressView(
                progress: min(current / target, 1.0),
                color: color,
                size: 50
            )
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(themeProvider.theme.backgroundSecondary)
                .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
        )
    }
}

struct CircularProgressView: View {
    let progress: Double
    let color: Color
    let size: CGFloat
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(color.opacity(0.2), lineWidth: 4)
                .frame(width: size, height: size)
            
            Circle()
                .trim(from: 0, to: progress)
                .stroke(color, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                .frame(width: size, height: size)
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 1.0), value: progress)
            
            Text("\(Int(progress * 100))%")
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(color)
        }
    }
}

struct EmptyMealsView: View {
    let onAddMeal: () -> Void
    @EnvironmentObject var themeProvider: ThemeProvider
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "fork.knife.circle")
                .font(.system(size: 48))
                .foregroundColor(themeProvider.theme.textSecondary.opacity(0.5))
            
            Text("No meals logged today")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(themeProvider.theme.textSecondary)
            
            Text("Start tracking your nutrition by adding your first meal")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(themeProvider.theme.textSecondary.opacity(0.7))
                .multilineTextAlignment(.center)
            
            Button {
                onAddMeal()
            } label: {
                HStack {
                    Image(systemName: "plus")
                    Text("Add Your First Meal")
                        .font(.system(size: 16, weight: .semibold))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(
                    LinearGradient(
                        colors: [themeProvider.theme.accent, themeProvider.theme.accent.opacity(0.8)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .clipShape(Capsule())
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .stroke(themeProvider.theme.textSecondary.opacity(0.2), lineWidth: 1)
                .fill(themeProvider.theme.backgroundSecondary.opacity(0.5))
        )
    }
}

#Preview {
    CalorieTrackingView()
        .environmentObject(ThemeProvider())
}
