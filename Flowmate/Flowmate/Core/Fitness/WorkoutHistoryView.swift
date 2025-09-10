//
//  WorkoutHistoryView.swift
//  Flowmate
//
//  Created on 2025-09-10
//

import SwiftUI

struct WorkoutHistoryView: View {
    @EnvironmentObject var themeProvider: ThemeProvider
    @Environment(\.dismiss) private var dismiss
    
    @State private var sessions: [WorkoutSession] = []
    @State private var isLoading = false
    @State private var errorText: String?
    
    var body: some View {
        NavigationStack {
            Group {
                if isLoading {
                    ProgressView("Loading...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let errorText {
                    VStack(spacing: 12) {
                        Image(systemName: "exclamationmark.triangle.fill").foregroundColor(.orange)
                        Text(errorText)
                            .foregroundColor(themeProvider.theme.textSecondary)
                        Button("Retry") { Task { await load() } }
                            .foregroundColor(themeProvider.theme.accent)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if sessions.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "list.bullet.rectangle.portrait.fill").font(.system(size: 40))
                            .foregroundColor(themeProvider.theme.accent)
                        Text("No workouts logged yet")
                            .foregroundColor(themeProvider.theme.textSecondary)
                        Button {
                            dismiss()
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: "square.and.pencil")
                                Text("Log your first workout")
                            }
                            .font(.system(size: 14, weight: .semibold))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(RoundedRectangle(cornerRadius: 10).fill(themeProvider.theme.accent))
                            .foregroundColor(.white)
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List {
                        ForEach(sessions) { s in
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Text(s.title)
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundColor(themeProvider.theme.textPrimary)
                                    Spacer()
                                    Text(s.date, style: .date)
                                        .font(.footnote)
                                        .foregroundColor(themeProvider.theme.textSecondary)
                                }
                                HStack(spacing: 12) {
                                    Label(s.formattedDuration, systemImage: "clock.fill")
                                    if !s.muscleGroups.isEmpty {
                                        Label(s.muscleGroupsString, systemImage: "bolt.heart.fill")
                                    }
                                }
                                .font(.caption)
                                .foregroundColor(themeProvider.theme.textSecondary)
                            }
                            .listRowBackground(themeProvider.theme.backgroundSecondary)
                        }
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .background(ThemedBackground().environmentObject(themeProvider))
            .navigationTitle("Workout History")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close") { dismiss() }
                        .foregroundColor(themeProvider.theme.accent)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        Task { await load() }
                    } label: {
                        Image(systemName: "arrow.clockwise")
                            .foregroundColor(themeProvider.theme.accent)
                    }
                }
            }
            .task { await load() }
        }
    }
    
    private func load() async {
        isLoading = true
        defer { isLoading = false }
        errorText = nil
        do {
            let list = try await BackendWorkoutService.shared.fetchSessions()
            sessions = list
            await FitnessProgressService.shared.reloadFromBackend()
        } catch {
            errorText = error.localizedDescription
        }
    }
}

#Preview {
    WorkoutHistoryView()
        .environmentObject(ThemeProvider())
}
