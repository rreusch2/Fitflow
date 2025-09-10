//
//  ProgressTrackerView.swift
//  Flowmate
//
//  Created on 2025-01-13
//

import SwiftUI

struct ProgressTrackerView: View {
    @EnvironmentObject var themeProvider: ThemeProvider
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var progressService = FitnessProgressService.shared
    @State private var selectedTimeframe: TimeFrame = .week
    
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    progressHeader
                    
                    // Timeframe Selector
                    timeframeSelector
                    
                    // Progress Charts
                    progressCharts
                    
                    // Achievement Badges
                    achievementSection
                    
                    // Weekly Summary
                    weeklySummary
                }
                .padding(.bottom, 100)
            }
            .background(ThemedBackground().environmentObject(themeProvider))
            .navigationTitle("Progress Tracker")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                    .foregroundColor(themeProvider.theme.accent)
                }
                
                // Removed demo data injection; real data is persisted to Supabase
            }
        }
    }
    
    private var progressHeader: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Your Progress")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(themeProvider.theme.textPrimary)
                    
                    Text("Keep up the amazing work!")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(themeProvider.theme.textSecondary)
                }
                
                Spacer()
                
                VStack(spacing: 4) {
                    Text(progressService.streakCount > 0 ? "🔥" : "🎯")
                        .font(.system(size: 32))
                    Text(progressService.streakCount > 0 ? "\(progressService.streakCount) days" : "Start")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(themeProvider.theme.accent)
                }
            }
            .padding(.horizontal, 20)
        }
    }
    
    private var timeframeSelector: some View {
        HStack(spacing: 0) {
            ForEach(TimeFrame.allCases, id: \.self) { timeframe in
                Button {
                    selectedTimeframe = timeframe
                } label: {
                    Text(timeframe.rawValue)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(selectedTimeframe == timeframe ? .white : themeProvider.theme.textSecondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(selectedTimeframe == timeframe ? themeProvider.theme.accent : Color.clear)
                        )
                }
            }
        }
        .padding(4)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(themeProvider.theme.backgroundSecondary)
        )
        .padding(.horizontal, 20)
    }
    
    private var progressCharts: some View {
        VStack(spacing: 16) {
            // Workout Frequency Chart
            ProgressChart(
                title: "Workout Frequency",
                value: String(format: "%.1f", progressService.getWorkoutFrequency(for: selectedTimeframe)),
                unit: "workouts/week",
                progress: min(progressService.getWorkoutFrequency(for: selectedTimeframe) / 5.0, 1.0),
                color: themeProvider.theme.accent
            )
            
            // Strength Progress
            ProgressChart(
                title: "Strength Gains",
                value: progressService.getStrengthProgress(for: selectedTimeframe).formattedProgress,
                unit: selectedTimeframe.rawValue.lowercased(),
                progress: (progressService.getStrengthProgress(for: selectedTimeframe) + 0.5),
                color: Color.orange
            )
            
            // Consistency Score
            ProgressChart(
                title: "Consistency",
                value: progressService.getConsistencyScore(for: selectedTimeframe).formattedPercentage,
                unit: "adherence",
                progress: progressService.getConsistencyScore(for: selectedTimeframe),
                color: Color.green
            )
        }
        .padding(.horizontal, 20)
    }
    
    private var achievementSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Achievements")
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(themeProvider.theme.textPrimary)
                .padding(.horizontal, 20)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    AchievementBadge(
                        title: "Getting Started",
                        description: "Complete first workout",
                        emoji: "🚀",
                        isUnlocked: progressService.hasFirstWorkout
                    )
                    
                    AchievementBadge(
                        title: "Week Warrior",
                        description: "5 workouts in a week",
                        emoji: "🔥",
                        isUnlocked: progressService.hasWeekWarrior
                    )
                    
                    AchievementBadge(
                        title: "Consistency King",
                        description: "30 day streak",
                        emoji: "👑",
                        isUnlocked: progressService.hasConsistencyKing
                    )
                }
                .padding(.horizontal, 20)
            }
        }
    }
    
    private var weeklySummary: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("\(selectedTimeframe.rawValue)'s Summary")
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(themeProvider.theme.textPrimary)
                .padding(.horizontal, 20)
            
            VStack(spacing: 12) {
                SummaryRow(
                    icon: "figure.strengthtraining.traditional", 
                    title: "Workouts Completed", 
                    value: getWorkoutsCompletedText()
                )
                SummaryRow(
                    icon: "clock.fill", 
                    title: "Total Time", 
                    value: progressService.getTotalWorkoutTime(for: selectedTimeframe).formattedWorkoutTime
                )
                SummaryRow(
                    icon: "flame.fill", 
                    title: "Estimated Calories", 
                    value: "\(progressService.getTotalCaloriesBurned(for: selectedTimeframe))"
                )
                SummaryRow(
                    icon: "heart.fill", 
                    title: "Est. Avg Heart Rate", 
                    value: progressService.getAverageHeartRate(for: selectedTimeframe) > 0 ? "\(progressService.getAverageHeartRate(for: selectedTimeframe)) bpm" : "N/A"
                )
            }
            .padding(.horizontal, 20)
        }
    }
    
    private func getWorkoutsCompletedText() -> String {
        let calendar = Calendar.current
        let now = Date()
        
        let startDate: Date
        let targetWorkouts: Int
        
        switch selectedTimeframe {
        case .week:
            startDate = calendar.startOfWeek(for: now)
            targetWorkouts = 4
        case .month:
            startDate = calendar.startOfMonth(for: now)
            targetWorkouts = 16
        case .year:
            startDate = calendar.startOfYear(for: now)
            targetWorkouts = 200
        }
        
        let completed = progressService.workoutHistory.filter { $0.date >= startDate }.count
        return "\(completed)/\(targetWorkouts)"
    }
}

struct ProgressChart: View {
    let title: String
    let value: String
    let unit: String
    let progress: Double
    let color: Color
    @EnvironmentObject var themeProvider: ThemeProvider
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(themeProvider.theme.textPrimary)
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    Text(value)
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(color)
                    
                    Text(unit)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(themeProvider.theme.textSecondary)
                }
            }
            
            // Progress Bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(color.opacity(0.2))
                        .frame(height: 8)
                    
                    RoundedRectangle(cornerRadius: 4)
                        .fill(color)
                        .frame(width: geometry.size.width * progress, height: 8)
                        .animation(.spring(response: 0.6, dampingFraction: 0.8), value: progress)
                }
            }
            .frame(height: 8)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(themeProvider.theme.backgroundSecondary)
                .shadow(color: Color.black.opacity(0.05), radius: 6, x: 0, y: 3)
        )
    }
}

struct AchievementBadge: View {
    let title: String
    let description: String
    let emoji: String
    let isUnlocked: Bool
    @EnvironmentObject var themeProvider: ThemeProvider
    
    var body: some View {
        VStack(spacing: 8) {
            Text(emoji)
                .font(.system(size: 32))
                .opacity(isUnlocked ? 1.0 : 0.3)
            
            VStack(spacing: 4) {
                Text(title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(isUnlocked ? themeProvider.theme.textPrimary : themeProvider.theme.textSecondary)
                
                Text(description)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(themeProvider.theme.textSecondary)
            }
        }
        .frame(width: 100, height: 100)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(themeProvider.theme.backgroundSecondary)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(
                            isUnlocked ? themeProvider.theme.accent.opacity(0.3) : Color.gray.opacity(0.2),
                            lineWidth: 1
                        )
                )
                .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
        )
        .scaleEffect(isUnlocked ? 1.0 : 0.95)
    }
}

struct SummaryRow: View {
    let icon: String
    let title: String
    let value: String
    @EnvironmentObject var themeProvider: ThemeProvider
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(themeProvider.theme.accent)
                .frame(width: 24)
            
            Text(title)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(themeProvider.theme.textPrimary)
            
            Spacer()
            
            Text(value)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(themeProvider.theme.accent)
        }
        .padding(.vertical, 8)
    }
}

#Preview {
    ProgressTrackerView()
        .environmentObject(ThemeProvider())
}
