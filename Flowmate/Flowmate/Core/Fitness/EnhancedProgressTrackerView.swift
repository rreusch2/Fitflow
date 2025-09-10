//
//  EnhancedProgressTrackerView.swift  
//  Flowmate
//
//  Created on 2025-09-10
//

import SwiftUI

struct EnhancedProgressTrackerView: View {
    @EnvironmentObject var themeProvider: ThemeProvider
    @Environment(\.dismiss) private var dismiss
    @StateObject private var workoutService = WorkoutSessionService.shared
    @State private var selectedTimeframe: TimeFrame = .week
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Header with Streak
                    progressHeader
                    
                    // Timeframe Selector
                    timeframeSelector
                    
                    // Key Metrics
                    keyMetrics
                    
                    // Favorite Muscle Groups
                    favoriteMuscleGroups
                    
                    // Recent Sessions
                    recentSessions
                }
                .padding(.bottom, 100)
            }
            .background(ThemedBackground().environmentObject(themeProvider))
            .navigationTitle("Progress Tracker")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close") { dismiss() }
                        .foregroundColor(themeProvider.theme.accent)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        Task { await workoutService.fetchWeeklyStats() }
                    } label: {
                        Image(systemName: "arrow.clockwise")
                            .foregroundColor(themeProvider.theme.accent)
                    }
                }
            }
        }
        .task {
            await workoutService.fetchRecentSessions()
            await workoutService.fetchWeeklyStats()
        }
    }
    
    private var progressHeader: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Your Progress")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(themeProvider.theme.textPrimary)
                    
                    Text("Based on actual workout data")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(themeProvider.theme.textSecondary)
                }
                
                Spacer()
                
                VStack(spacing: 4) {
                    Text(workoutService.currentStreak > 0 ? "🔥" : "🎯")
                        .font(.system(size: 32))
                    Text(workoutService.currentStreak > 0 ? "\(workoutService.currentStreak) day streak" : "Start today")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(themeProvider.theme.accent)
                        .multilineTextAlignment(.center)
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
    
    private var keyMetrics: some View {
        VStack(spacing: 16) {
            HStack(spacing: 12) {
                MetricCard(
                    title: "Workouts",
                    value: "\(workoutService.weeklyStats?.workoutsCompleted ?? 0)",
                    subtitle: "this week",
                    icon: "figure.strengthtraining.traditional",
                    color: themeProvider.theme.accent
                )
                
                MetricCard(
                    title: "Total Time",
                    value: formatMinutes(workoutService.weeklyStats?.totalTimeMinutes ?? 0),
                    subtitle: "this week",
                    icon: "clock.fill",
                    color: Color.blue
                )
            }
            
            HStack(spacing: 12) {
                MetricCard(
                    title: "Avg Duration",
                    value: formatMinutes(workoutService.weeklyStats?.averageDuration ?? 0),
                    subtitle: "per workout",
                    icon: "timer",
                    color: Color.green
                )
                
                MetricCard(
                    title: "All Sessions",
                    value: "\(workoutService.sessions.count)",
                    subtitle: "total logged",
                    icon: "chart.line.uptrend.xyaxis",
                    color: Color.orange
                )
            }
        }
        .padding(.horizontal, 20)
    }
    
    private var favoriteMuscleGroups: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Top Muscle Groups")
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(themeProvider.theme.textPrimary)
                .padding(.horizontal, 20)
            
            if let favorites = workoutService.weeklyStats?.favoritesMuscleGroups, !favorites.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(Array(favorites.enumerated()), id: \.offset) { index, group in
                            MuscleGroupChip(
                                name: group.capitalized,
                                rank: index + 1,
                                themeProvider: themeProvider
                            )
                        }
                    }
                    .padding(.horizontal, 20)
                }
            } else {
                Text("Complete more workouts to see your favorites")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(themeProvider.theme.textSecondary)
                    .padding(.horizontal, 20)
            }
        }
    }
    
    private var recentSessions: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Recent Workouts")
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(themeProvider.theme.textPrimary)
                .padding(.horizontal, 20)
            
            if workoutService.sessions.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "figure.strengthtraining.traditional")
                        .font(.system(size: 32, weight: .medium))
                        .foregroundColor(themeProvider.theme.textSecondary)
                    Text("No workouts logged yet")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(themeProvider.theme.textSecondary)
                    Text("Start by generating an AI workout or logging a manual session")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(themeProvider.theme.textSecondary.opacity(0.8))
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 32)
            } else {
                LazyVStack(spacing: 8) {
                    ForEach(Array(workoutService.sessions.prefix(10).enumerated()), id: \.element.id) { index, session in
                        WorkoutSessionRow(session: session, themeProvider: themeProvider)
                            .padding(.horizontal, 20)
                    }
                }
            }
        }
    }
    
    private func formatMinutes(_ minutes: Int) -> String {
        if minutes < 60 {
            return "\(minutes)m"
        } else {
            let hours = minutes / 60
            let remainingMinutes = minutes % 60
            return remainingMinutes > 0 ? "\(hours)h \(remainingMinutes)m" : "\(hours)h"
        }
    }
}

// MARK: - Supporting Views

struct MetricCard: View {
    let title: String
    let value: String
    let subtitle: String
    let icon: String
    let color: Color
    @EnvironmentObject var themeProvider: ThemeProvider
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 24, weight: .semibold))
                .foregroundColor(color)
            
            Text(value)
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(themeProvider.theme.textPrimary)
            
            VStack(spacing: 2) {
                Text(title)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(themeProvider.theme.textPrimary)
                Text(subtitle)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(themeProvider.theme.textSecondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(themeProvider.theme.backgroundSecondary)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(color.opacity(0.3), lineWidth: 1)
                )
                .shadow(color: Color.black.opacity(0.05), radius: 6, x: 0, y: 3)
        )
    }
}

struct MuscleGroupChip: View {
    let name: String
    let rank: Int
    let themeProvider: ThemeProvider
    
    var rankColor: Color {
        switch rank {
        case 1: return Color.yellow
        case 2: return Color.gray
        case 3: return Color.orange
        default: return themeProvider.theme.accent
        }
    }
    
    var rankEmoji: String {
        switch rank {
        case 1: return "🥇"
        case 2: return "🥈"
        case 3: return "🥉"
        default: return "#\(rank)"
        }
    }
    
    var body: some View {
        HStack(spacing: 8) {
            Text(rankEmoji)
                .font(.system(size: 16, weight: .semibold))
            Text(name)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(themeProvider.theme.textPrimary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            Capsule()
                .fill(rankColor.opacity(0.1))
                .overlay(
                    Capsule()
                        .stroke(rankColor.opacity(0.3), lineWidth: 1)
                )
        )
    }
}

struct WorkoutSessionRow: View {
    let session: WorkoutSessionService.WorkoutSession
    let themeProvider: ThemeProvider
    
    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(session.workoutType == "ai_generated" ? "AI Workout" : "Manual Workout")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(themeProvider.theme.textPrimary)
                
                HStack(spacing: 8) {
                    if let duration = session.durationMinutes {
                        Label("\(duration)m", systemImage: "clock.fill")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(themeProvider.theme.textSecondary)
                    }
                    
                    Label("\(session.exercisesCompleted.count) exercises", systemImage: "list.bullet")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(themeProvider.theme.textSecondary)
                }
            }
            
            Spacer()
            
            Text(timeAgo(from: session.completedAt))
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(themeProvider.theme.textSecondary)
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(themeProvider.theme.backgroundSecondary)
                .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
        )
    }
    
    private func timeAgo(from date: Date) -> String {
        let now = Date()
        let components = Calendar.current.dateComponents([.day, .hour, .minute], from: date, to: now)
        
        if let days = components.day, days > 0 {
            return days == 1 ? "1 day ago" : "\(days) days ago"
        } else if let hours = components.hour, hours > 0 {
            return hours == 1 ? "1 hour ago" : "\(hours) hours ago"
        } else if let minutes = components.minute, minutes > 0 {
            return minutes == 1 ? "1 min ago" : "\(minutes) mins ago"
        } else {
            return "Just now"
        }
    }
}


#Preview {
    EnhancedProgressTrackerView()
        .environmentObject(ThemeProvider())
}
