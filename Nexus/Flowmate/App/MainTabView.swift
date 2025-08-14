//
//  MainTabView.swift
//  Flowmate
//
//  Created on 2025-01-13
//

import SwiftUI
import AVKit

// MARK: - UserInterest helpers
// Note: `UserInterest` properties like `icon`, `title`, and `subtitle` are defined in
// `OnboardingContainerView.swift` and are reused here.

struct MainTabView: View {
    @EnvironmentObject var authService: AuthenticationService
    @EnvironmentObject var themeProvider: ThemeProvider
    
    @State private var selectedTab: Int = 0
    @State private var showCoach = false
    @State private var coachButtonPosition = CGPoint(x: UIScreen.main.bounds.width - 72, y: UIScreen.main.bounds.height - 160)
    
    private var userInterests: [UserInterest] {
        authService.currentUser?.preferences?.theme.selectedInterests ?? []
    }
    
    var body: some View {
        ZStack {
            TabView(selection: $selectedTab) {
            // Always show the main feed - TikTok Style Video Feed
            TikTokStyleVideoFeed()
                .tabItem {
                    Label("Flow", systemImage: "brain.head.profile")
                }
                .tag(0)
            
            // Dynamic tabs based on user interests
            ForEach(Array(dynamicTabs.enumerated()), id: \.offset) { index, tab in
                tab.view
                    .tabItem {
                        Label(tab.title, systemImage: tab.icon)
                    }
                    .tag(index + 1)
            }
            
            // Always show the AI coach
            FlowmateCoachView()
                .tabItem {
                    Label("Coach", systemImage: "message.fill")
                }
                .tag(dynamicTabs.count + 1)
            
            // Always show profile
            ProfileView()
                .tabItem {
                    Label("Profile", systemImage: "person.fill")
                }
                .tag(dynamicTabs.count + 2)
            }
            .tint(themeProvider.theme.accent)
            .background(ThemedBackground().environmentObject(themeProvider))

            // Floating Coach Button - positioned above nav bar
            DraggableSpinningCoachButton(
                position: $coachButtonPosition,
                color: themeProvider.theme.accent
            ) {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                    showCoach.toggle()
                }
            }

            // Coach Overlay
            if showCoach {
                CoachOverlay(isPresented: $showCoach) {
                    CoachChatView()
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .zIndex(1)
            }
        }
    }
    
    // Revolutionary intelligent tab system - respects user's custom tab management preferences
    private var dynamicTabs: [(title: String, icon: String, view: AnyView)] {
        // Check if user has custom tab management preferences
        if let tabVisibility = authService.currentUser?.preferences?.theme.tabVisibility {
            return getCustomizedTabs(from: tabVisibility)
        } else {
            // Fallback to intelligent default prioritization
            return getDefaultPrioritizedTabs()
        }
    }
    
    private func getCustomizedTabs(from tabVisibility: TabVisibilityPreferences) -> [(title: String, icon: String, view: AnyView)] {
        // Define all possible tabs
        // Only include tabs that have concrete implementations in this file to avoid build errors.
        let allPossibleTabs: [UserInterest: (title: String, icon: String, view: AnyView)] = [
            .fitness: ("Fitness", "figure.run", AnyView(EnhancedFitnessView())),
            .wealth: ("Finance", "chart.line.uptrend.xyaxis", AnyView(EnhancedFinanceView()))
        ]
        
        // Return tabs in user's preferred order and selection
        return tabVisibility.visibleTabs.compactMap { interest in
            guard let tab = allPossibleTabs[interest] else { return nil }
            return (title: tab.title, icon: tab.icon, view: tab.view)
        }
    }
    
    private func getDefaultPrioritizedTabs() -> [(title: String, icon: String, view: AnyView)] {
        let maxTabs = 4 // Perfect for navigation without overcrowding
        
        // Define all possible tabs with priority weights
        let allPossibleTabs: [(interest: UserInterest, title: String, icon: String, view: AnyView, weight: Int)] = [
            (.fitness, "Fitness", "figure.run", AnyView(FitnessView()), getInterestWeight(.fitness)),
            (.wealth, "Wealth", "dollarsign.circle.fill", AnyView(WealthView()), getInterestWeight(.wealth))
        ]
        
        // Filter to user's selected interests, sort by priority weight, and take top maxTabs
        let prioritizedTabs = allPossibleTabs
            .filter { userInterests.contains($0.interest) }
            .sorted { $0.weight > $1.weight }
            .prefix(maxTabs)
            .map { (title: $0.title, icon: $0.icon, view: $0.view) }
        
        return Array(prioritizedTabs)
    }
    
    // Intelligent priority weighting based on user preferences and common usage patterns
    private func getInterestWeight(_ interest: UserInterest) -> Int {
        guard let prefs = authService.currentUser?.preferences else { return 50 }
        
        var weight = 50 // Base weight
        
        // Boost weight based on detailed preferences provided
        switch interest {
        case .fitness:
            if !prefs.fitness.preferredActivities.isEmpty { weight += 30 }
            if prefs.fitness.workoutFrequency != .light { weight += 15 }
        case .business:
            if let businessPrefs = prefs.business {
                weight += 25
                if businessPrefs.weeklyHours > 10 { weight += 15 }
            }
        case .creativity:
            if let creativityPrefs = prefs.creativity {
                weight += 25
                if !creativityPrefs.mediums.isEmpty { weight += 20 }
            }
        case .mindset:
            if let mindsetPrefs = prefs.mindset {
                weight += 20
                if !mindsetPrefs.focuses.isEmpty { weight += 15 }
            }
        case .wealth:
            if let wealthPrefs = prefs.wealth {
                weight += 25
                if !wealthPrefs.goals.isEmpty { weight += 20 }
            }
        case .relationships:
            if let relationshipsPrefs = prefs.relationships {
                weight += 20
                if relationshipsPrefs.weeklySocialHours > 5 { weight += 10 }
            }
        default:
            // Learning, spirituality, adventure, leadership, health, family get base weight
            // Can be enhanced later with specific preference tracking
            break
        }
        
        // Core interests get slight boost for better balance
        switch interest {
        case .fitness, .business, .mindset: weight += 10
        default: break
        }
        
        return weight
    }
}

// MARK: - Revolutionary Dynamic Views

private struct PersonalizedFeedView: View {
    @EnvironmentObject var themeProvider: ThemeProvider
    @EnvironmentObject var authService: AuthenticationService
    
    private var userInterests: [UserInterest] {
        authService.currentUser?.preferences?.theme.selectedInterests ?? []
    }
    @StateObject private var feedService = FeedService.shared
    @State private var items: [FeedItem] = []
    @State private var isLoading: Bool = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Personalized Header
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Your Flow")
                                    .font(.system(size: 32, weight: .bold, design: .rounded))
                                    .foregroundColor(themeProvider.theme.gradientTextPrimary)
                                    .shadow(color: Color.black.opacity(0.3), radius: 1, x: 0, y: 1)
                                
                                Text(personalizedFeedSubtitle)
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(themeProvider.theme.gradientTextSecondary)
                                    .shadow(color: Color.black.opacity(0.2), radius: 1, x: 0, y: 1)
                            }
                            
                            Spacer()
                            
                            // Interest pills
                            HStack(spacing: 6) {
                                ForEach(userInterests.prefix(2), id: \.self) { interest in
                                    HStack(spacing: 4) {
                                        Image(systemName: interest.icon)
                                            .font(.caption2)
                                        Text(interest.title.components(separatedBy: " ").first ?? "")
                                            .font(.caption)
                                            .fontWeight(.medium)
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
                        }
                        .padding(.horizontal)
                        .padding(.top)
                    }
                    
                    if isLoading {
                        VStack(spacing: 16) {
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
                        // Enhanced feed cards with category headers
                        LazyVStack(spacing: 16) {
                            ForEach(groupedFeedItems.keys.sorted(), id: \.self) { category in
                                if let categoryItems = groupedFeedItems[category], !categoryItems.isEmpty {
                                    VStack(alignment: .leading, spacing: 12) {
                                        HStack {
                                            Image(systemName: categoryIcon(for: category))
                                                .foregroundColor(themeProvider.theme.accent)
                                                .font(.title3)
                                            
                                            Text(category)
                                                .font(.system(size: 18, weight: .semibold))
                                                .foregroundColor(themeProvider.theme.gradientTextPrimary)
                                                .shadow(color: Color.black.opacity(0.3), radius: 1, x: 0, y: 1)
                                            
                                            Spacer()
                                            
                                            Text("\(categoryItems.count)")
                                                .font(.caption)
                                                .foregroundColor(themeProvider.theme.gradientTextSecondary)
                                                .padding(.horizontal, 6)
                                                .padding(.vertical, 2)
                                                .background(
                                                    Capsule()
                                                        .fill(themeProvider.theme.backgroundSecondary)
                                                )
                                        }
                                        .padding(.horizontal)
                                        
                                        ForEach(categoryItems) { item in
                                            EnhancedFeedCard(item: item)
                                .padding(.horizontal)
                                        }
                                    }
                                }
                            }
                        }
                        .padding(.bottom, 8)
                    }
                }
            }
            .background(ThemedBackground().environmentObject(themeProvider))
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
    
    private var personalizedFeedSubtitle: String {
        let interestCount = userInterests.count
        if interestCount == 0 {
            return "Discover content tailored for you"
        } else if interestCount == 1 {
            return "Content curated for your \(userInterests.first?.title.lowercased() ?? "interests")"
        } else {
            return "Content curated for your \(interestCount) interests"
        }
    }
    
    private var groupedFeedItems: [String: [FeedItem]] {
        Dictionary(grouping: items) { item in
            // Group by first topic tag, or use a default category
            return item.topicTags.first?.capitalized ?? "Featured"
        }
    }
    
    private func categoryIcon(for category: String) -> String {
        switch category.lowercased() {
        case "fitness", "health": return "figure.run"
        case "business", "career": return "briefcase.fill"
        case "mindset", "growth": return "brain.head.profile"
        case "creativity", "arts": return "paintbrush.fill"
        case "wealth", "finance": return "dollarsign.circle.fill"
        case "relationships": return "heart.fill"
        case "learning": return "book.fill"
        case "spirituality": return "leaf.fill"
        case "adventure": return "mountain.2.fill"
        case "leadership": return "crown.fill"
        case "family": return "house.fill"
        default: return "sparkles"
        }
    }
}

// MARK: - Global Floating Coach Components

private struct DraggableSpinningCoachButton: View {
    @Binding var position: CGPoint
    let color: Color
    let action: () -> Void
    
    @State private var animate = false
    @State private var rotation: Double = 0
    @State private var isDragging = false
    @State private var startPosition: CGPoint = .zero
    
    var body: some View {
        ZStack {
            // Outer glow circle
            Circle()
                .fill(color.opacity(0.15))
                .frame(width: 62, height: 62)
                .scaleEffect(animate ? 1.08 : 1.0)
                .animation(.easeInOut(duration: 1.6).repeatForever(autoreverses: true), value: animate)
            
            // Main button circle
            Circle()
                .fill(color)
                .frame(width: 56, height: 56)
            
            // Your logo icon - constantly spinning!
            Image(systemName: "brain.head.profile")
                .foregroundColor(.white)
                .font(.system(size: 24, weight: .light))
                .rotationEffect(.degrees(rotation))
                .animation(.linear(duration: 3.0).repeatForever(autoreverses: false), value: rotation)
        }
        .shadow(color: color.opacity(0.35), radius: 10, x: 0, y: 6)
        .scaleEffect(isDragging ? 1.1 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isDragging)
        .contentShape(Circle())
        .position(x: position.x, y: position.y)
        .onAppear {
            animate = true
            rotation = 360 // Start the constant spinning
        }
        .highPriorityGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { value in
                    if !isDragging {
                        isDragging = true
                        startPosition = position
                    }
                    // Live update position with drag
                    let screenBounds = UIScreen.main.bounds
                    let newX = startPosition.x + value.translation.width
                    let newY = startPosition.y + value.translation.height
                    let constrainedX = max(40, min(screenBounds.width - 40, newX))
                    let constrainedY = max(100, min(screenBounds.height - 180, newY)) // Above nav bar
                    position = CGPoint(x: constrainedX, y: constrainedY)
                }
                .onEnded { value in
                    let distance = sqrt(value.translation.width * value.translation.width + value.translation.height * value.translation.height)
                    isDragging = false
                    
                    // Treat as tap if very small movement
                    if distance < 8 {
                        action()
                        return
                    }
                    // Snap to nearest horizontal edge
                    let screenBounds = UIScreen.main.bounds
                    let targetX = (position.x < screenBounds.midX) ? 40 : screenBounds.width - 40
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                        position = CGPoint(x: targetX, y: position.y)
                    }
                }
        )
        .zIndex(isDragging ? 10 : 0)
        .accessibilityLabel("Coach. Drag to move, tap to open.")
        .accessibilityAddTraits(.isButton)
    }
}

private struct CoachOverlay<Content: View>: View {
    @Binding var isPresented: Bool
    let content: () -> Content
    @EnvironmentObject var themeProvider: ThemeProvider
    
    var body: some View {
        ZStack(alignment: .bottom) {
            // Dimmed backdrop
            Color.black.opacity(0.35)
                .ignoresSafeArea()
                .onTapGesture {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.9)) { isPresented = false }
                }
            
            // Sheet
            VStack(spacing: 0) {
                Capsule()
                    .fill(Color.white.opacity(0.3))
                    .frame(width: 44, height: 5)
                    .padding(.top, 8)
                    .padding(.bottom, 6)
                
                content()
                    .frame(maxHeight: 620)
                    .clipShape(RoundedRectangle(cornerRadius: 20))
            }
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(themeProvider.theme.backgroundPrimary)
                    .shadow(color: Color.black.opacity(0.25), radius: 16, x: 0, y: -4)
            )
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .padding(.horizontal, 8)
            .padding(.bottom, 8)
        }
    }
}

// MARK: - AgentPanel (per-tab AI agent with prompt gallery)

private struct AgentPrompt: Hashable {
    let title: String
    let prompt: String
}

private struct AgentPanel: View {
    let title: String
    let icon: String
    let context: ChatContext
    let presets: [AgentPrompt]
    
    @EnvironmentObject var themeProvider: ThemeProvider
    @EnvironmentObject var authService: AuthenticationService
    @State private var input: String = ""
    @State private var output: String = ""
    @State private var isLoading: Bool = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .foregroundColor(themeProvider.theme.accent)
                Text(title)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(themeProvider.theme.gradientTextPrimary)
                Spacer()
                if isLoading { ProgressView() }
            }
            
            // Preset gallery
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(presets, id: \.self) { preset in
                        Button {
                            input = preset.prompt
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: "sparkles")
                                Text(preset.title)
                            }
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(themeProvider.theme.accent)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 8)
                            .background(themeProvider.theme.accent.opacity(0.1))
                            .clipShape(Capsule())
                        }
                    }
                }
            }
            
            // Input
            ZStack(alignment: .topLeading) {
                RoundedRectangle(cornerRadius: 12)
                    .fill(themeProvider.theme.backgroundSecondary)
                TextEditor(text: $input)
                    .frame(minHeight: 80, maxHeight: 120)
                    .padding(10)
                    .scrollContentBackground(.hidden)
                    .foregroundColor(themeProvider.theme.textPrimary)
            }
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(themeProvider.theme.accent.opacity(0.15), lineWidth: 1)
            )
            
            Button(action: run) {
                HStack {
                    Image(systemName: "paperplane.fill")
                    Text("Ask Agent")
                        .fontWeight(.semibold)
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(themeProvider.theme.accent)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .shadow(color: themeProvider.theme.accent.opacity(0.25), radius: 8, x: 0, y: 4)
            }
            .disabled(isLoading || input.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            
            if !output.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Agent Response")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(themeProvider.theme.gradientTextSecondary)
                    Text(output)
                        .font(.system(size: 15))
                        .foregroundColor(themeProvider.theme.textPrimary)
                        .lineSpacing(3)
                }
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(themeProvider.theme.backgroundSecondary)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(themeProvider.theme.accent.opacity(0.1), lineWidth: 1)
                )
            }
        }
    }
    
    private func run() {
        guard let user = authService.currentUser else { return }
        isLoading = true
        output = ""
        Task {
            do {
                let response = try await AIService.shared.generateChatResponse(
                    messages: [ChatMessage(id: UUID(), role: .user, content: input, timestamp: Date())],
                    user: user,
                    context: context
                )
                await MainActor.run { self.output = response }
            } catch {
                await MainActor.run { self.output = "Error: \(error.localizedDescription)" }
            }
            await MainActor.run { self.isLoading = false }
        }
    }
}

// MARK: - Placeholder Components to satisfy references

private struct EnhancedFeedCard: View {
    let item: FeedItem
    @EnvironmentObject var themeProvider: ThemeProvider
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(item.title ?? item.text)
                    .font(.headline)
                Spacer()
                Text(item.topicTags.first?.capitalized ?? "")
                    .font(.caption)
                    .foregroundColor(themeProvider.theme.textSecondary)
            }
            Text(item.text)
                .font(.subheadline)
                .foregroundColor(themeProvider.theme.textSecondary)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.backgroundSecondary)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.borderLight, lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
        )
    }
}

private struct StatsCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    @EnvironmentObject var themeProvider: ThemeProvider
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(color)
                .frame(width: 28, height: 28)
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.caption)
                    .foregroundColor(themeProvider.theme.adaptiveSecondaryTextOnCard)
                Text(value)
                    .font(.headline)
                    .foregroundColor(themeProvider.theme.adaptiveTextOnCard)
            }
            Spacer()
        }
        .padding(16)
        .floatingGlassCard(cornerRadius: 14)
        .environmentObject(themeProvider)
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
            .background(ThemedBackground().environmentObject(themeProvider))
            .navigationTitle("Plans")
        }
    }
}

private struct FlowmateCoachView: View {
    @EnvironmentObject var themeProvider: ThemeProvider
    @EnvironmentObject var authService: AuthenticationService
    @Environment(\.colorScheme) var colorScheme
    
    private var userInterests: [UserInterest] {
        authService.currentUser?.preferences?.theme.selectedInterests ?? []
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
            VStack(spacing: 24) {
                // Flowmate Coach Header
                VStack(spacing: 16) {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [themeProvider.theme.accent, themeProvider.theme.accent.opacity(0.7)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 80, height: 80)
                            .shadow(color: themeProvider.theme.accent.opacity(0.3), radius: 12, x: 0, y: 6)
                        
                        Image(systemName: "brain.head.profile")
                            .font(.system(size: 36, weight: .medium))
                            .foregroundColor(.white)
                    }
                    
                    VStack(spacing: 8) {
                        Text("Your Flowmate Coach")
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                            .foregroundColor(themeProvider.textForSystemContext(colorScheme))
                            .shadow(color: Color.black.opacity(0.3), radius: 1, x: 0, y: 1)
                        
                        Text(personalizedCoachSubtitle)
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(themeProvider.secondaryTextForSystemContext(colorScheme))
                            .shadow(color: Color.black.opacity(0.2), radius: 1, x: 0, y: 1)
                            .multilineTextAlignment(.center)
                            .lineLimit(2)
                    }
                }
                .padding(.top, 20)
                
                    // Daily Motivation Card
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Text("Daily Motivation")
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundColor(themeProvider.theme.textPrimary)
                                .shadow(color: Color.black.opacity(0.2), radius: 1, x: 0, y: 1)
                Spacer()
                            Text("Personalized")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(themeProvider.theme.accent)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(themeProvider.theme.accent.opacity(0.1))
                                .clipShape(Capsule())
                        }
                        
                        VStack(alignment: .leading, spacing: 12) {
                            Text(dailyMotivation)
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(themeProvider.theme.textPrimary)
                                .lineSpacing(2)
                                .shadow(color: Color.black.opacity(0.1), radius: 1, x: 0, y: 1)
                            
                            Button {
                                // Get new motivation
                            } label: {
                                HStack {
                                    Image(systemName: "arrow.clockwise")
                                    Text("New Motivation")
                                        .font(.system(size: 14, weight: .semibold))
                                }
                                .foregroundColor(themeProvider.theme.accent)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 10)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(themeProvider.theme.accent, lineWidth: 1.5)
                                )
                            }
                        }
                    }
                    .padding(20)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(themeProvider.theme.backgroundSecondary.opacity(0.9))
                            .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
                    )
                    .padding(.horizontal, 20)
                
                // Quick Actions
                    VStack(spacing: 16) {
                        HStack {
                    Text("Quick Actions")
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundColor(themeProvider.textForSystemContext(colorScheme))
                                .shadow(color: Color.black.opacity(0.2), radius: 1, x: 0, y: 1)
                            Spacer()
                        }
                    
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 2), spacing: 12) {
                        ForEach(quickActions, id: \.title) { action in
                            Button {
                                // Handle quick action
                            } label: {
                                VStack(spacing: 8) {
                                    Image(systemName: action.icon)
                                        .font(.title2)
                                        .foregroundColor(themeProvider.theme.accent)
                                    
                                    Text(action.title)
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundColor(themeProvider.theme.adaptiveTextOnCard)
                                            .multilineTextAlignment(.center)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                            .fill(themeProvider.theme.backgroundSecondary.opacity(0.9))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12)
                                                    .stroke(themeProvider.theme.accent.opacity(0.2), lineWidth: 1)
                                        )
                                )
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                }
                .padding(.horizontal, 20)
                
                    // Recent Insights
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Text("Recent Insights")
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundColor(themeProvider.textForSystemContext(colorScheme))
                                .shadow(color: Color.black.opacity(0.2), radius: 1, x: 0, y: 1)
                Spacer()
                        }
                        
                        VStack(spacing: 12) {
                            ForEach(recentInsights, id: \.title) { insight in
                                HStack(spacing: 12) {
                                    Image(systemName: insight.icon)
                                        .font(.title3)
                                        .foregroundColor(themeProvider.theme.accent)
                                        .frame(width: 24, height: 24)
                                    
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(insight.title)
                                            .font(.system(size: 14, weight: .semibold))
                                            .foregroundColor(themeProvider.theme.adaptiveTextOnCard)
                                        
                                        Text(insight.subtitle)
                                            .font(.system(size: 12, weight: .medium))
                                            .foregroundColor(themeProvider.theme.adaptiveSecondaryTextOnCard)
                                    }
                                    
                                    Spacer()
                                    
                                    Image(systemName: "arrow.right")
                                        .font(.caption)
                                        .foregroundColor(themeProvider.theme.textSecondary)
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)
                                .background(
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(themeProvider.theme.backgroundSecondary.opacity(0.9))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 10)
                                                .stroke(themeProvider.theme.accent.opacity(0.15), lineWidth: 1)
                                        )
                                )
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                
                // Start Conversation Button
                Button {
                    // Start AI conversation
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "message.fill")
                            .font(.title3)
                            Text("Start Deep Conversation")
                            .font(.system(size: 18, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        LinearGradient(
                            colors: [themeProvider.theme.accent, themeProvider.theme.accent.opacity(0.8)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .shadow(color: themeProvider.theme.accent.opacity(0.3), radius: 8, x: 0, y: 4)
                    )
                }
                .buttonStyle(PlainButtonStyle())
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
                }
            }
            .navigationTitle("Coach")
            .background(ThemedBackground().environmentObject(themeProvider))
        }
    }
    
    private var personalizedCoachSubtitle: String {
        let interestTitles = userInterests.map { $0.title.lowercased() }
        
        if interestTitles.isEmpty {
            return "AI-powered guidance personalized for your journey"
        } else if interestTitles.count == 1 {
            return "AI guidance specialized in \(interestTitles.first!) growth"
        } else if interestTitles.count == 2 {
            return "AI guidance for \(interestTitles.joined(separator: " and ")) excellence"
        } else {
            let firstTwo = Array(interestTitles.prefix(2)).joined(separator: ", ")
            return "AI guidance for \(firstTwo) and \(interestTitles.count - 2) more areas"
        }
    }
    
    private var quickActions: [(title: String, icon: String)] {
        var actions: [(String, String)] = [("Daily Check-in", "checkmark.circle"), ("Goal Setting", "target")]
        
        // Dynamically add actions based on user's top interests
        let prioritizedInterests = userInterests.sorted { interest1, interest2 in
            getInterestWeight(interest1) > getInterestWeight(interest2)
        }
        
        for interest in prioritizedInterests.prefix(4) {
            switch interest {
            case .fitness:
            actions.append(("Workout Plan", "figure.run"))
            case .business:
                actions.append(("Business Strategy", "briefcase"))
            case .mindset:
                actions.append(("Mindful Moment", "brain.head.profile"))
            case .creativity:
                actions.append(("Creative Spark", "paintbrush"))
            case .wealth:
                actions.append(("Financial Review", "dollarsign.circle"))
            case .relationships:
                actions.append(("Connection Tips", "heart"))
            case .learning:
                actions.append(("Learn Something", "book"))
            case .spirituality:
                actions.append(("Meditation", "leaf"))
            case .adventure:
                actions.append(("Adventure Ideas", "mountain.2"))
            case .leadership:
                actions.append(("Leadership Insight", "crown"))
            case .health:
                actions.append(("Wellness Check", "mind.head.profile"))
            case .family:
                actions.append(("Family Time", "house"))
            }
        }
        
        return Array(actions.prefix(6)) // Limit to 6 actions for clean layout
    }
    
    private var dailyMotivation: String {
        let interestTitles = userInterests.map { $0.title.lowercased() }
        
        if interestTitles.contains("fitness") && interestTitles.contains("business") {
            return "Your strength in fitness reflects your potential in business. Channel that same discipline and consistency into building your empire today."
        } else if interestTitles.contains("mindset") && interestTitles.contains("creativity") {
            return "Your mindful awareness amplifies your creative power. Today, approach your creative projects with intention and watch magic unfold."
        } else if interestTitles.contains("wealth") {
            return "Every small financial decision today shapes your future freedom. Invest in yourself and your goals with unwavering focus."
        } else if interestTitles.contains("leadership") {
            return "Great leaders are forged in the crucible of daily choices. Today, lead yourself first and others will naturally follow."
        } else {
            return "You have everything within you to create the life you envision. Today is your canvas - paint it with intention and purpose."
        }
    }
    
    private var recentInsights: [(title: String, subtitle: String, icon: String)] {
        var insights: [(String, String, String)] = []
        
        for interest in userInterests.prefix(3) {
            switch interest {
            case .fitness:
                insights.append(("Consistency beats intensity", "Small daily actions compound over time", "figure.run"))
            case .business:
                insights.append(("Focus on value creation", "Revenue follows when you solve real problems", "briefcase.fill"))
            case .mindset:
                insights.append(("Growth mindset advantage", "Challenges become opportunities for expansion", "brain.head.profile"))
            case .creativity:
                insights.append(("Creativity flows from constraints", "Limitations often spark innovation", "paintbrush.fill"))
            case .wealth:
                insights.append(("Time in market beats timing", "Consistent investing builds lasting wealth", "dollarsign.circle.fill"))
            default:
                break
            }
        }
        
        if insights.isEmpty {
            insights = [
                ("Start where you are", "Perfect conditions never come - begin today", "flag.fill"),
                ("Progress over perfection", "Small steps forward beat standing still", "chart.line.uptrend.xyaxis")
            ]
        }
        
        return insights
    }
    
    // Helper method to get interest priority weight (simplified version)
    private func getInterestWeight(_ interest: UserInterest) -> Int {
        guard let prefs = authService.currentUser?.preferences else { return 50 }
        
        var weight = 50 // Base weight
        
        // Boost weight based on detailed preferences provided
        switch interest {
        case .fitness:
            if !prefs.fitness.preferredActivities.isEmpty { weight += 30 }
        case .business:
            if prefs.business != nil { weight += 25 }
        case .creativity:
            if prefs.creativity != nil { weight += 25 }
        case .mindset:
            if prefs.mindset != nil { weight += 20 }
        case .wealth:
            if prefs.wealth != nil { weight += 25 }
        case .relationships:
            if prefs.relationships != nil { weight += 20 }
        default:
            break
        }
        
        // Core interests get slight boost
        switch interest {
        case .fitness, .business, .mindset: weight += 10
        default: break
        }
        
        return weight
    }
}

private struct ProfileView: View {
    @EnvironmentObject var themeProvider: ThemeProvider
    @EnvironmentObject var authService: AuthenticationService
    @Environment(\.colorScheme) var colorScheme
    
    private var userInterests: [UserInterest] {
        authService.currentUser?.preferences?.theme.selectedInterests ?? []
    }
    
    var body: some View {
        NavigationStack {
            List {
                Section(header: Text("Your Interests").foregroundStyle(themeProvider.secondaryTextForSystemContext(colorScheme))) {
                    if !userInterests.isEmpty {
                        ForEach(userInterests, id: \.self) { interest in
                            HStack {
                                Image(systemName: interest.icon)
                                    .foregroundColor(themeProvider.theme.accent)
                                    .frame(width: 20)
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(interest.title)
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundColor(themeProvider.textForSystemContext(colorScheme))
                                    
                                    Text(interest.subtitle)
                                        .font(.caption)
                                        .foregroundColor(themeProvider.secondaryTextForSystemContext(colorScheme))
                                }
                                
                                Spacer()
                                
                                // Priority indicator
                                Text("\(getInterestPriority(interest))")
                                    .font(.caption2)
                                    .fontWeight(.semibold)
                                    .foregroundColor(themeProvider.theme.accent)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(
                                        Capsule()
                                            .fill(themeProvider.theme.accent.opacity(0.1))
                                    )
                            }
                            .padding(.vertical, 4)
                        }
                        
                        Text("Top 4 interests appear as tabs")
                            .font(.caption)
                            .foregroundColor(themeProvider.theme.textSecondary)
                            .padding(.top, 8)
                    } else {
                        Text("Complete onboarding to set your interests")
                            .foregroundColor(themeProvider.theme.textSecondary)
                    }
                }
                
                // Revolutionary Tab Customization Section
                Section(header: Text("Navigation").foregroundStyle(themeProvider.secondaryTextForSystemContext(colorScheme))) {
                    NavigationLink {
                        MemoriesView()
                            .environmentObject(themeProvider)
                    } label: {
                        HStack {
                            Image(systemName: "brain")
                                .foregroundColor(.purple)
                                .frame(width: 30)
                            Text("Memories")
                            Spacer()
                            Text("\(MemoryService.shared.memories.count)")
                                .foregroundColor(.secondary)
                                .font(.caption)
                        }
                    }
                    
                    NavigationLink {
                        TabManagementView()
                            .environmentObject(authService)
                            .environmentObject(themeProvider)
                    } label: {
                        HStack {
                            Image(systemName: "square.grid.2x2")
                                .foregroundColor(themeProvider.theme.accent)
                                .frame(width: 20)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Tab Management")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(themeProvider.textForSystemContext(colorScheme))
                                
                                Text("Customize your tab bar experience")
                                    .font(.caption)
                                    .foregroundColor(themeProvider.secondaryTextForSystemContext(colorScheme))
                            }
                            
                            Spacer()
                            
                            // Show current tab count
                            if let tabVisibility = authService.currentUser?.preferences?.theme.tabVisibility {
                                Text("\(tabVisibility.visibleTabs.count + 2)") // +2 for fixed tabs
                                    .font(.caption2)
                                    .fontWeight(.semibold)
                                    .foregroundColor(themeProvider.theme.accent)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(
                                        Capsule()
                                            .fill(themeProvider.theme.accent.opacity(0.1))
                                    )
                            } else {
                                Text("Auto")
                                    .font(.caption2)
                                    .fontWeight(.semibold)
                                    .foregroundColor(themeProvider.theme.textSecondary)
                            }
                            
                            Image(systemName: "chevron.right")
                                .foregroundColor(themeProvider.theme.textSecondary)
                                .font(.caption)
                        }
                        .padding(.vertical, 4)
                    }
                }
                
                Section(header: Text("Theme").foregroundStyle(themeProvider.secondaryTextForSystemContext(colorScheme))) {
                    HStack {
                        Circle()
                            .fill(themeProvider.theme.accent)
                            .frame(width: 20, height: 20)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Current Style")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(themeProvider.textForSystemContext(colorScheme))
                            
                            Text("\(themeProvider.style.displayName) • \(themeProvider.accentChoice.displayName)")
                                .font(.caption)
                                .foregroundColor(themeProvider.secondaryTextForSystemContext(colorScheme))
                        }
                        
                        Spacer()
                        
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(themeProvider.theme.accent)
                    }
                    .padding(.vertical, 4)
                    
                    Picker("Style", selection: Binding(get: { themeProvider.style }, set: { themeProvider.setTheme(style: $0, accent: themeProvider.accentChoice) })) {
                        ForEach(ThemeStyle.allCases, id: \.self) { style in
                            Text(style.displayName)
                        }
                    }
                    
                    Picker("Accent", selection: Binding(get: { themeProvider.accentChoice }, set: { themeProvider.setTheme(style: themeProvider.style, accent: $0) })) {
                        ForEach(AccentColorChoice.allCases, id: \.self) { choice in
                            Text(choice.displayName)
                        }
                    }
                }
                
                Section(header: Text("Account").foregroundStyle(themeProvider.secondaryTextForSystemContext(colorScheme))) {
                    Button(role: .destructive) {
                        authService.signOut()
                    } label: {
                        Text("Sign Out")
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(ThemedBackground().environmentObject(themeProvider))
            .navigationTitle("Profile")
        }
    }
    
    private func getInterestPriority(_ interest: UserInterest) -> Int {
        guard let prefs = authService.currentUser?.preferences else { return 1 }
        
        var priority = 1
        
        // Calculate priority based on detailed preferences
        switch interest {
        case .fitness:
            if !prefs.fitness.preferredActivities.isEmpty { priority += 2 }
            if prefs.fitness.workoutFrequency != .light { priority += 1 }
        case .business:
            if let businessPrefs = prefs.business {
                priority += 2
                if businessPrefs.weeklyHours > 10 { priority += 1 }
            }
        case .creativity:
            if let creativityPrefs = prefs.creativity {
                priority += 2
                if !creativityPrefs.mediums.isEmpty { priority += 1 }
            }
        case .mindset:
            if let mindsetPrefs = prefs.mindset {
                priority += 1
                if !mindsetPrefs.focuses.isEmpty { priority += 1 }
            }
        case .wealth:
            if let wealthPrefs = prefs.wealth {
                priority += 2
                if !wealthPrefs.goals.isEmpty { priority += 1 }
            }
        case .relationships:
            if let relationshipsPrefs = prefs.relationships {
                priority += 1
                if relationshipsPrefs.weeklySocialHours > 5 { priority += 1 }
            }
        default:
            break
        }
        
        return min(priority, 5) // Cap at 5 stars
    }
}

// MARK: - PersonalizedContentCard

private struct PersonalizedContentCard: View {
    let interest: UserInterest
    @EnvironmentObject var themeProvider: ThemeProvider
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: interest.icon)
                    .font(.title2)
                    .foregroundColor(themeProvider.theme.accent)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(interest.title)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(themeProvider.theme.adaptiveTextOnCard)
                    
                    Text(interest.subtitle)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(themeProvider.theme.adaptiveSecondaryTextOnCard)
                }
                
                Spacer()
                
                Button {
                    // Navigate to specific interest view
                } label: {
                    Image(systemName: "arrow.right.circle.fill")
                        .font(.title3)
                        .foregroundColor(themeProvider.theme.accent)
                }
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text(contentForInterest(interest))
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(themeProvider.theme.adaptiveTextOnCard)
                    .lineLimit(3)
                
                Text(motivationalQuoteForInterest(interest))
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(themeProvider.theme.accent)
                    .italic()
            }
        }
        .padding(20)
        .floatingGlassCard(cornerRadius: 18)
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(
                    LinearGradient(
                        colors: [
                            themeProvider.theme.accent.opacity(0.3),
                            themeProvider.theme.accent.opacity(0.1),
                            Color.clear
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
        .environmentObject(themeProvider)
    }
    
    private func contentForInterest(_ interest: UserInterest) -> String {
        switch interest {
        case .fitness: return "Your next workout is ready! Today's focus: building strength and endurance."
        case .business: return "Market insights: 3 trending opportunities in your industry this week."
        case .mindset: return "Daily reflection: How can you turn today's challenges into growth opportunities?"
        case .creativity: return "Creative spark: Try this 15-minute expression exercise to unlock new ideas."
        case .wealth: return "Investment tip: Review your portfolio allocation for Q1 optimization."
        case .relationships: return "Connection builder: 3 ways to deepen meaningful relationships this week."
        case .learning: return "Knowledge boost: Explore this fascinating topic that aligns with your goals."
        case .spirituality: return "Inner wisdom: Take 10 minutes today for mindful meditation and reflection."
        case .adventure: return "Adventure awaits: Discover a new local experience to expand your horizons."
        case .leadership: return "Leadership insight: How to inspire others through authentic communication."
        case .health: return "Wellness check: Simple habits to enhance your mental and physical vitality."
        case .family: return "Family focus: Create meaningful moments that strengthen your closest bonds."
        }
    }
    
    private func motivationalQuoteForInterest(_ interest: UserInterest) -> String {
        switch interest {
        case .fitness: return "\"Strength doesn't come from what you can do. It comes from overcoming what you thought you couldn't.\""
        case .business: return "\"Innovation distinguishes between a leader and a follower.\" - Steve Jobs"
        case .mindset: return "\"Your mindset is everything. What you think, you become.\" - Buddha"
        case .creativity: return "\"Creativity is intelligence having fun.\" - Albert Einstein"
        case .wealth: return "\"Wealth consists not in having great possessions, but in having few wants.\" - Epictetus"
        case .relationships: return "\"The best way to find out if you can trust somebody is to trust them.\" - Ernest Hemingway"
        case .learning: return "\"Live as if you were to die tomorrow. Learn as if you were to live forever.\" - Gandhi"
        case .spirituality: return "\"The present moment is the only time over which we have dominion.\" - Thích Nhất Hạnh"
        case .adventure: return "\"Life is either a daring adventure or nothing at all.\" - Helen Keller"
        case .leadership: return "\"A leader is one who knows the way, goes the way, and shows the way.\" - John Maxwell"
        case .health: return "\"Health is not about the weight you lose, but about the life you gain.\" - Unknown"
        case .family: return "\"Family is not an important thing. It's everything.\" - Michael J. Fox"
        }
    }
}

// MARK: - Dynamic Interest Views

private struct FitnessView: View {
    @EnvironmentObject var themeProvider: ThemeProvider
    @EnvironmentObject var authService: AuthenticationService
    
    private var fitnessPrefs: FitnessPreferences? {
        authService.currentUser?.preferences?.fitness
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Personalized Header
                    VStack(spacing: 12) {
                        HStack {
                            Image(systemName: "figure.run")
                                .font(.system(size: 24, weight: .medium))
                                .foregroundColor(themeProvider.theme.accent)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Your Fitness Flow")
                                    .font(.system(size: 28, weight: .bold, design: .rounded))
                                    .foregroundColor(themeProvider.theme.textPrimary)
                                    .shadow(color: Color.black.opacity(0.3), radius: 1, x: 0, y: 1)
                    
                                Text(personalizedSubtitle)
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(themeProvider.theme.textSecondary)
                                    .shadow(color: Color.black.opacity(0.2), radius: 1, x: 0, y: 1)
                            }
                            
                            Spacer()
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 16)
                    }
                    
                    // Quick Stats Cards
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 16), count: 2), spacing: 16) {
                        StatsCard(
                            title: "Level",
                            value: fitnessPrefs?.level.displayName ?? "Beginner",
                            icon: "trophy.fill",
                            color: themeProvider.theme.accent
                        )
                        
                        StatsCard(
                            title: "Activities",
                            value: "\(fitnessPrefs?.preferredActivities.count ?? 0)",
                            icon: "heart.fill",
                            color: themeProvider.theme.accent
                        )
                        
                        StatsCard(
                            title: "Duration",
                            value: fitnessPrefs?.workoutDuration.displayName ?? "Short",
                            icon: "clock.fill",
                            color: themeProvider.theme.accent
                        )
                        
                        StatsCard(
                            title: "Frequency",
                            value: fitnessPrefs?.workoutFrequency.displayName ?? "Light",
                            icon: "calendar.fill",
                            color: themeProvider.theme.accent
                        )
                    }
                    .padding(.horizontal, 20)
                    
                    // Today's Focus
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Text("Today's Focus")
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundColor(themeProvider.theme.textPrimary)
                            Spacer()
                            Text("Personalized")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(themeProvider.theme.accent)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(themeProvider.theme.accent.opacity(0.1))
                                .clipShape(Capsule())
                        }
                        
                        VStack(alignment: .leading, spacing: 12) {
                            Text(todaysFocus)
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(themeProvider.theme.textPrimary)
                                .lineSpacing(2)
                            
                            Button {
                                // Start workout action
                            } label: {
                                HStack {
                                    Image(systemName: "play.fill")
                                    Text("Start Workout")
                                        .font(.system(size: 16, weight: .semibold))
                                }
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(
                                    LinearGradient(
                                        colors: [themeProvider.theme.accent, themeProvider.theme.accent.opacity(0.8)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                .shadow(color: themeProvider.theme.accent.opacity(0.3), radius: 8, x: 0, y: 4)
                            }
                        }
                    }
                    .padding(20)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(themeProvider.theme.backgroundSecondary)
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(Color.borderLight, lineWidth: 1)
                            )
                            .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
                    )

                    // AI Workout Agent
                    if authService.currentUser != nil {
                        AgentPanel(
                            title: "Workout Agent",
                            icon: "bolt.heart",
                            context: .workout,
                            presets: [
                                AgentPrompt(title: "Weekly Plan", prompt: "Design a 7-day workout plan aligned with my fitness preferences, level, available equipment, and workout duration preferences. Include rest guidance and warm-up/cool-down."),
                                AgentPrompt(title: "Today's Session", prompt: "Create a personalized workout for today based on my recent activity and preferences. Include sets, reps, tempo, and form cues."),
                                AgentPrompt(title: "Form Tips", prompt: "Give concise form tips and common mistakes for my top 3 preferred exercises.")
                            ]
                        )
                        .environmentObject(themeProvider)
                        .environmentObject(authService)
                        .padding(.horizontal, 20)
                    }
                }
                .padding(.bottom, 20)
            }
            .background(ThemedBackground().environmentObject(themeProvider))
            .navigationTitle("Fitness")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        // Open fitness settings
                    } label: {
                        Image(systemName: "gear")
                            .foregroundColor(themeProvider.theme.accent)
                    }
                }
            }
        }
    }
    
    var personalizedSubtitle: String {
        // TODO: Implement personalizedSubtitle
        return "Your personalized subtitle"
    }
    
    var todaysFocus: String {
        // TODO: Implement todaysFocus
        return "Today's focus"
    }
}

// MARK: - WealthView (minimal implementation)

private struct WealthView: View {
    @EnvironmentObject var themeProvider: ThemeProvider
    @EnvironmentObject var authService: AuthenticationService
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    HStack {
                        Image(systemName: "dollarsign.circle.fill")
                            .font(.system(size: 24, weight: .medium))
                            .foregroundColor(themeProvider.theme.accent)
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Your Wealth Flow")
                                .font(.system(size: 28, weight: .bold, design: .rounded))
                                .foregroundColor(themeProvider.textForSystemContext(colorScheme))
                                .shadow(color: Color.black.opacity(0.3), radius: 1, x: 0, y: 1)
                            Text("Personalized finance insights")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(themeProvider.secondaryTextForSystemContext(colorScheme))
                                .shadow(color: Color.black.opacity(0.2), radius: 1, x: 0, y: 1)
                        }
                        Spacer()
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)

                    // Agent panel
                    if authService.currentUser != nil {
                        AgentPanel(
                            title: "Wealth Agent",
                            icon: "dollarsign.square.fill",
                            context: .general,
                            presets: [
                                AgentPrompt(title: "Budget Plan", prompt: "Create a monthly budget with target savings and smart cuts."),
                                AgentPrompt(title: "Investing Steps", prompt: "Suggest 3 next investing steps with brief rationale."),
                                AgentPrompt(title: "Optimize Expenses", prompt: "Identify 5 expenses to optimize without killing QoL.")
                            ]
                        )
                        .environmentObject(themeProvider)
                        .environmentObject(authService)
                        .padding(.horizontal, 20)
                    }
                }
                .padding(.bottom, 20)
            }
            .background(ThemedBackground().environmentObject(themeProvider))
            .navigationTitle("Wealth")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { } label: {
                        Image(systemName: "gear")
                            .foregroundColor(themeProvider.theme.accent)
                    }
                }
            }
        }
    }
}


private extension View {
    func shimmer() -> some View { 
        self.overlay(
            ShimmerView()
                .clipShape(RoundedRectangle(cornerRadius: 16))
        )
    }
}

#Preview {
    MainTabView()
        .environmentObject(AuthenticationService())
        .environmentObject(ThemeProvider())
}
