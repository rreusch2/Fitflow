//
//  MainTabView.swift
//  NexusGPT
//
//  Created on 2025-01-13
//

import SwiftUI

struct MainTabView: View {
    @EnvironmentObject var authService: AuthenticationService
    @EnvironmentObject var themeProvider: ThemeProvider
    
    @State private var selectedTab: Int = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            FeedView()
                .tabItem {
                    Label("Feed", systemImage: "sparkles")
                }
                .tag(0)
            
            PlansView()
                .tabItem {
                    Label("Plans", systemImage: "list.bullet.rectangle")
                }
                .tag(1)
            
            ChatView()
                .tabItem {
                    Label("Coach", systemImage: "message.fill")
                }
                .tag(2)
            
            ProfileView()
                .tabItem {
                    Label("Profile", systemImage: "person.fill")
                }
                .tag(3)
        }
        .tint(themeProvider.theme.accent)
        .background(themeProvider.theme.backgroundPrimary.ignoresSafeArea())
    }
}

// MARK: - Stubs

private struct FeedView: View {
    @EnvironmentObject var themeProvider: ThemeProvider
    @EnvironmentObject var authService: AuthenticationService
    @StateObject private var feedService = FeedService.shared
    @State private var items: [FeedItem] = []
    @State private var isLoading: Bool = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Daily For You")
                        .font(.title2)
                        .foregroundStyle(themeProvider.theme.textPrimary)
                        .padding(.horizontal)
                        .padding(.top)
                    
                    if isLoading {
                        VStack(spacing: 12) {
                            ForEach(0..<3, id: \.self) { _ in
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color.backgroundTertiary)
                                    .frame(height: 220)
                                    .shimmer()
                                    .padding(.horizontal)
                            }
                        }
                        .padding(.bottom, 8)
                    } else {
                        ForEach(items) { item in
                            FeedCard(item: item)
                                .padding(.horizontal)
                        }
                        .padding(.bottom, 8)
                    }
                }
            }
            .background(themeProvider.theme.backgroundPrimary)
            .navigationTitle("Feed")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        Task { await refresh() }
                    } label: { Image(systemName: "arrow.clockwise") }
                }
            }
            .task { await refresh() }
        }
    }

    private func refresh() async {
        guard let user = authService.currentUser else { return }
        isLoading = true
        defer { isLoading = false }
        items = await feedService.getTodayFeed(for: user, desiredCount: 6)
    }
}

private struct PlansView: View {
    @EnvironmentObject var themeProvider: ThemeProvider
    @EnvironmentObject var authService: AuthenticationService
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                Button {
                    // Hook up AI plan generation
                } label: {
                    Text("Generate Workout Plan")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(PrimaryButtonStyle())
                .padding(.horizontal)
                
                Button {
                    // Hook up AI meal generation
                } label: {
                    Text("Generate Meal Plan")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(SecondaryButtonStyle())
                .padding(.horizontal)
                
                Spacer()
            }
            .background(themeProvider.theme.backgroundPrimary)
            .navigationTitle("Plans")
        }
    }
}

private struct ChatView: View {
    @EnvironmentObject var themeProvider: ThemeProvider
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                Text("AI Coach coming soon")
                    .foregroundStyle(themeProvider.theme.textSecondary)
                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(themeProvider.theme.backgroundPrimary)
            .navigationTitle("Coach")
        }
    }
}

private struct ProfileView: View {
    @EnvironmentObject var themeProvider: ThemeProvider
    @EnvironmentObject var authService: AuthenticationService
    
    var body: some View {
        NavigationStack {
            List {
                Section(header: Text("Theme").foregroundStyle(themeProvider.theme.textSecondary)) {
                    Picker("Style", selection: Binding(get: { themeProvider.style }, set: { themeProvider.setTheme(style: $0, accent: themeProvider.accentChoice) })) {
                        ForEach(ThemeStyle.allCases, id: \.self) { style in
                            Text(style.rawValue.capitalized)
                        }
                    }
                    Picker("Accent", selection: Binding(get: { themeProvider.accentChoice }, set: { themeProvider.setTheme(style: themeProvider.style, accent: $0) })) {
                        ForEach(AccentColorChoice.allCases, id: \.self) { choice in
                            Text(choice.rawValue.capitalized)
                        }
                    }
                }
                
                Section(header: Text("Account").foregroundStyle(themeProvider.theme.textSecondary)) {
                    Button(role: .destructive) {
                        authService.signOut()
                    } label: {
                        Text("Sign Out")
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(themeProvider.theme.backgroundPrimary)
            .navigationTitle("Profile")
        }
    }
}

// MARK: - Feed Card + Shimmer

private struct FeedCard: View {
    let item: FeedItem
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            AsyncImage(url: URL(string: item.imageUrl ?? "")) { phase in
                switch phase {
                case .empty:
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.backgroundTertiary)
                        .frame(height: 220)
                        .shimmer()
                case .success(let img):
                    img
                        .resizable()
                        .scaledToFill()
                        .frame(height: 220)
                        .clipped()
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                case .failure:
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.backgroundTertiary)
                        .frame(height: 220)
                @unknown default:
                    EmptyView()
                }
            }
            Text(item.text)
                .font(.headline)
                .foregroundStyle(Color.textPrimary)
                .padding(.horizontal, 4)
                .padding(.bottom, 8)
        }
    }
}

private extension View {
    func shimmer() -> some View { self.overlay(ShimmerView().clipShape(RoundedRectangle(cornerRadius: 16))) }
}

#Preview {
    MainTabView()
        .environmentObject(AuthenticationService())
        .environmentObject(ThemeProvider())
}
