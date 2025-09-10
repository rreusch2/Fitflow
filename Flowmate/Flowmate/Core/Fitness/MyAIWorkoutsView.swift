//
//  MyAIWorkoutsView.swift
//  Flowmate
//
//  Created on 2025-09-10
//

import SwiftUI

struct MyAIWorkoutsView: View {
    @EnvironmentObject var themeProvider: ThemeProvider
    @Environment(\.dismiss) private var dismiss
    @StateObject private var library = WorkoutLibraryService.shared
    @State private var selectedPlan: WorkoutPlanResponse?
    
    var body: some View {
        NavigationStack {
            Group {
                if library.isLoading {
                    VStack(spacing: 12) {
                        ProgressView()
                        Text("Loading your AI workouts...")
                            .foregroundColor(themeProvider.theme.textSecondary)
                            .font(.subheadline)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if library.plans.isEmpty {
                    emptyState
                } else {
                    List {
                        ForEach(library.plans) { plan in
                            Button {
                                selectedPlan = plan
                            } label: {
                                WorkoutRow(plan: plan)
                                    .environmentObject(themeProvider)
                            }
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button(role: .destructive) {
                                    Task { _ = await library.deletePlan(id: plan.id) }
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                        }
                    }
                    .listStyle(.insetGrouped)
                    .refreshable { await library.fetchPlans() }
                }
            }
            .task { await library.fetchPlans() }
            .navigationTitle("My AI Workouts")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close") { dismiss() }
                        .foregroundColor(themeProvider.theme.accent)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    if !library.isLoading {
                        Button {
                            Task { await library.fetchPlans() }
                        } label: {
                            Image(systemName: "arrow.clockwise")
                                .foregroundColor(themeProvider.theme.accent)
                        }
                    }
                }
            }
            .background(ThemedBackground().environmentObject(themeProvider))
        }
        .sheet(item: $selectedPlan) { plan in
            AIWorkoutPlanView(workout: plan)
                .environmentObject(themeProvider)
        }
    }
    
    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "sparkles")
                .font(.system(size: 36, weight: .semibold))
                .foregroundColor(themeProvider.theme.accent)
            Text("No AI workouts yet")
                .font(.title3).bold()
                .foregroundColor(themeProvider.theme.textPrimary)
            Text("Generate a workout from the Fitness tab, and it will appear here for quick access.")
                .multilineTextAlignment(.center)
                .foregroundColor(themeProvider.theme.textSecondary)
                .padding(.horizontal)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Row
private struct WorkoutRow: View {
    let plan: WorkoutPlanResponse
    @EnvironmentObject var themeProvider: ThemeProvider
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(plan.title)
                    .font(.headline)
                    .foregroundColor(themeProvider.theme.textPrimary)
                Spacer()
            }
            
            HStack(spacing: 8) {
                Chip(icon: "clock.fill", text: "\(plan.estimated_duration)m")
                Chip(icon: "flame.fill", text: plan.difficulty_level.capitalized)
                Chip(icon: "list.bullet", text: "\(plan.exercises.count) ex")
            }
            
            Text(plan.description)
                .font(.subheadline)
                .foregroundColor(themeProvider.theme.textSecondary)
                .lineLimit(2)
        }
        .padding(.vertical, 8)
    }
}

private struct Chip: View {
    let icon: String
    let text: String
    @EnvironmentObject var themeProvider: ThemeProvider
    
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 11, weight: .semibold))
            Text(text)
                .font(.system(size: 11, weight: .semibold))
        }
        .foregroundColor(themeProvider.theme.accent)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            Capsule()
                .fill(themeProvider.theme.accent.opacity(0.1))
        )
    }
}

#Preview {
    MyAIWorkoutsView()
        .environmentObject(ThemeProvider())
}
