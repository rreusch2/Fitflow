//
//  MainTabView.swift
//  Flowmate
//
//  Created on 2025-01-13
//

import SwiftUI

// MARK: - UserInterest helpers
// Note: `UserInterest` properties like `icon`, `title`, and `subtitle` are defined in
// `OnboardingContainerView.swift` and are reused here.

struct MainTabView: View {
    @EnvironmentObject var authService: AuthenticationService
    @EnvironmentObject var themeProvider: ThemeProvider
    
    @State private var selectedTab: Int = 0
    
    private var userInterests: [UserInterest] {
        authService.currentUser?.preferences?.theme.selectedInterests ?? []
    }
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // Always show the main feed
            PersonalizedFeedView()
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
    }
    
    // Revolutionary intelligent tab system - prioritizes and limits tabs for optimal UX
    private var dynamicTabs: [(title: String, icon: String, view: AnyView)] {
        let maxTabs = 4 // Perfect for navigation without overcrowding
        
        // Define all possible tabs with priority weights
        let allPossibleTabs: [(interest: UserInterest, title: String, icon: String, view: AnyView, weight: Int)] = [
            (.fitness, "Fitness", "figure.run", AnyView(FitnessView()), getInterestWeight(.fitness)),
            (.business, "Business", "briefcase.fill", AnyView(BusinessView()), getInterestWeight(.business)),
            (.mindset, "Mindset", "brain.head.profile", AnyView(MindsetView()), getInterestWeight(.mindset)),
            (.creativity, "Create", "paintbrush.fill", AnyView(CreativityView()), getInterestWeight(.creativity)),
            (.wealth, "Wealth", "dollarsign.circle.fill", AnyView(WealthView()), getInterestWeight(.wealth)),
            (.relationships, "Connect", "heart.fill", AnyView(RelationshipsView()), getInterestWeight(.relationships)),
            (.learning, "Learn", "book.fill", AnyView(LearningView()), getInterestWeight(.learning)),
            (.spirituality, "Spirit", "leaf.fill", AnyView(SpiritualityView()), getInterestWeight(.spirituality)),
            (.adventure, "Adventure", "mountain.2.fill", AnyView(AdventureView()), getInterestWeight(.adventure)),
            (.leadership, "Lead", "crown.fill", AnyView(LeadershipView()), getInterestWeight(.leadership)),
            (.health, "Health", "mind.head.profile", AnyView(HealthView()), getInterestWeight(.health)),
            (.family, "Family", "house.fill", AnyView(FamilyView()), getInterestWeight(.family))
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
                            .foregroundColor(themeProvider.theme.gradientTextPrimary)
                            .shadow(color: Color.black.opacity(0.3), radius: 1, x: 0, y: 1)
                        
                        Text(personalizedCoachSubtitle)
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(themeProvider.theme.gradientTextSecondary)
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
                                .foregroundColor(themeProvider.theme.gradientTextPrimary)
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
                                        .foregroundColor(Color(red: 26/255, green: 32/255, blue: 46/255))
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
                                .foregroundColor(themeProvider.theme.gradientTextPrimary)
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
                                            .foregroundColor(Color(red: 26/255, green: 32/255, blue: 46/255))
                                        
                                        Text(insight.subtitle)
                                            .font(.system(size: 12, weight: .medium))
                                            .foregroundColor(Color(red: 71/255, green: 85/255, blue: 105/255))
                                    }
                                    
                                    Spacer()
                                    
                                    Image(systemName: "arrow.right")
                                        .font(.caption)
                                        .foregroundColor(Color(red: 71/255, green: 85/255, blue: 105/255))
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
    
    private var userInterests: [UserInterest] {
        authService.currentUser?.preferences?.theme.selectedInterests ?? []
    }
    
    var body: some View {
        NavigationStack {
            List {
                Section(header: Text("Your Interests").foregroundStyle(themeProvider.theme.gradientTextSecondary)) {
                    if !userInterests.isEmpty {
                        ForEach(userInterests, id: \.self) { interest in
                            HStack {
                                Image(systemName: interest.icon)
                                    .foregroundColor(themeProvider.theme.accent)
                                    .frame(width: 20)
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(interest.title)
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundColor(themeProvider.theme.gradientTextPrimary)
                                    
                                    Text(interest.subtitle)
                                        .font(.caption)
                                        .foregroundColor(themeProvider.theme.gradientTextSecondary)
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
                
                Section(header: Text("Theme").foregroundStyle(themeProvider.theme.gradientTextSecondary)) {
                    HStack {
                        Circle()
                            .fill(themeProvider.theme.accent)
                            .frame(width: 20, height: 20)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Current Style")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(themeProvider.theme.gradientTextPrimary)
                            
                            Text("\(themeProvider.style.displayName) • \(themeProvider.accentChoice.displayName)")
                                .font(.caption)
                                .foregroundColor(themeProvider.theme.gradientTextSecondary)
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
                
                Section(header: Text("Account").foregroundStyle(themeProvider.theme.gradientTextSecondary)) {
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
                        .foregroundColor(themeProvider.theme.textPrimary)
                    
                    Text(interest.subtitle)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(themeProvider.theme.textSecondary)
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
                    .foregroundColor(themeProvider.theme.textPrimary)
                    .lineLimit(3)
                
                Text(motivationalQuoteForInterest(interest))
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(themeProvider.theme.accent.opacity(0.8))
                    .italic()
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(
                    LinearGradient(
                        colors: [themeProvider.theme.backgroundSecondary, themeProvider.theme.backgroundPrimary],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
        )
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
                                    .foregroundColor(themeProvider.theme.gradientTextPrimary)
                                    .shadow(color: Color.black.opacity(0.3), radius: 1, x: 0, y: 1)
                    
                                Text(personalizedSubtitle)
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(themeProvider.theme.gradientTextSecondary)
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
                            .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
                    )
                    .padding(.horizontal, 20)
                    
                    // Preferred Activities
                    if let activities = fitnessPrefs?.preferredActivities, !activities.isEmpty {
                        VStack(alignment: .leading, spacing: 16) {
                            HStack {
                                Text("Your Activities")
                                    .font(.system(size: 20, weight: .semibold))
                                    .foregroundColor(themeProvider.theme.textPrimary)
                                Spacer()
                            }
                            
                            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 2), spacing: 12) {
                                ForEach(activities.prefix(4), id: \.self) { activity in
                                    ActivityCard(activity: activity)
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                    
                    Spacer(minLength: 20)
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
    
    private var personalizedSubtitle: String {
        guard let prefs = fitnessPrefs else { return "Ready to start your fitness journey" }
        
        let level = prefs.level.displayName.lowercased()
        let frequency = prefs.workoutFrequency.displayName.lowercased()
        
        return "Your \(level) \(frequency) fitness plan"
    }
    
    private var todaysFocus: String {
        guard let prefs = fitnessPrefs else {
            return "Welcome to your fitness journey! Let's start with some basic movements to build your foundation."
        }
        
        let activities = prefs.preferredActivities
        let level = prefs.level
        
        if activities.contains(.strength) {
            switch level {
            case .beginner: return "Today we're focusing on bodyweight strength fundamentals. Perfect your form with squats, push-ups, and planks."
            case .intermediate: return "Time for progressive strength training! We'll work on compound movements with proper weight progression."
            case .advanced: return "Advanced strength session ahead! Focus on complex movements and challenging your limits safely."
            }
        } else if activities.contains(.cardio) {
            switch level {
            case .beginner: return "Let's get your heart pumping with a gentle cardio session. Walking or light jogging to build your endurance."
            case .intermediate: return "Interval cardio training today! Mix high and low intensity to boost your cardiovascular fitness."
            case .advanced: return "High-intensity cardio challenge! Push your limits with advanced intervals and endurance work."
            }
        } else if activities.contains(.yoga) {
            return "Find your inner balance with a mindful yoga flow. Focus on breath, flexibility, and strength through movement."
        } else {
            return "A balanced workout combining your favorite activities. Listen to your body and enjoy the movement!"
        }
    }
}

private struct StatsCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    @EnvironmentObject var themeProvider: ThemeProvider
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text(value)
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(themeProvider.theme.textPrimary)
            
            Text(title)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(themeProvider.theme.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(themeProvider.theme.backgroundSecondary)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.borderLight, lineWidth: 1)
                )
        )
    }
}

private struct ActivityCard: View {
    let activity: ActivityType
    @EnvironmentObject var themeProvider: ThemeProvider
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: activity.icon)
                .font(.title3)
                .foregroundColor(themeProvider.theme.accent)
                .frame(width: 24, height: 24)
            
            Text(activity.displayName)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(themeProvider.theme.textPrimary)
            
            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(themeProvider.theme.accent.opacity(0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(themeProvider.theme.accent.opacity(0.2), lineWidth: 1)
                )
        )
    }
}



private struct BusinessView: View {
    @EnvironmentObject var themeProvider: ThemeProvider
    @EnvironmentObject var authService: AuthenticationService
    
    private var businessPrefs: BusinessPreferences? {
        authService.currentUser?.preferences?.business
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Personalized Header
                    VStack(spacing: 12) {
                        HStack {
                            Image(systemName: "briefcase.fill")
                                .font(.system(size: 24, weight: .medium))
                                .foregroundColor(themeProvider.theme.accent)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Business Growth")
                                    .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(themeProvider.theme.textPrimary)
                    
                                Text(personalizedBusinessSubtitle)
                                    .font(.system(size: 16, weight: .medium))
                        .foregroundColor(themeProvider.theme.textSecondary)
                }
                            
                            Spacer()
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 16)
                    }
                    
                    // Business Focus Cards
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 16), count: 2), spacing: 16) {
                        StatsCard(
                            title: "Focus",
                            value: businessPrefs?.focus.displayName ?? "Growth",
                            icon: "target",
                            color: themeProvider.theme.accent
                        )
                        
                        StatsCard(
                            title: "Work Style",
                            value: businessPrefs?.workStyle.displayName ?? "Hybrid",
                            icon: "location.fill",
                            color: themeProvider.theme.accent
                        )
                        
                        StatsCard(
                            title: "Weekly Hours",
                            value: "\(businessPrefs?.weeklyHours ?? 0)h",
                            icon: "clock.badge.fill",
                            color: themeProvider.theme.accent
                        )
                        
                        StatsCard(
                            title: "Growth Mode",
                            value: "Active",
                            icon: "chart.line.uptrend.xyaxis",
                            color: themeProvider.theme.accent
                        )
                    }
                    .padding(.horizontal, 20)
                    
                    // Today's Business Focus
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Text("Today's Priority")
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundColor(themeProvider.theme.textPrimary)
                            Spacer()
                            Text("AI Recommended")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(themeProvider.theme.accent)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(themeProvider.theme.accent.opacity(0.1))
                                .clipShape(Capsule())
                        }
                        
                        VStack(alignment: .leading, spacing: 12) {
                            Text(todaysBusinessFocus)
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(themeProvider.theme.textPrimary)
                                .lineSpacing(2)
                            
                            HStack(spacing: 12) {
                                Button {
                                    // View insights action
                                } label: {
                                    HStack {
                                        Image(systemName: "lightbulb.fill")
                                        Text("View Insights")
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
                                
                                Button {
                                    // Take action
                                } label: {
                                    HStack {
                                        Image(systemName: "arrow.right.circle.fill")
                                        Text("Take Action")
                                            .font(.system(size: 14, weight: .semibold))
                                    }
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 10)
                                    .background(
                                        LinearGradient(
                                            colors: [themeProvider.theme.accent, themeProvider.theme.accent.opacity(0.8)],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                                }
                            }
                        }
                    }
                    .padding(20)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(themeProvider.theme.backgroundSecondary)
                            .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
                    )
                    .padding(.horizontal, 20)
                    
                    // Quick Actions
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Text("Quick Actions")
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundColor(themeProvider.theme.gradientTextPrimary)
                                .shadow(color: Color.black.opacity(0.3), radius: 1, x: 0, y: 1)
                            Spacer()
                        }
                        
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 2), spacing: 12) {
                            QuickActionCard(
                                title: "Network",
                                subtitle: "Connect & grow",
                                icon: "person.2.fill",
                                color: themeProvider.theme.accent
                            )
                            
                            QuickActionCard(
                                title: "Learn",
                                subtitle: "Skill development",
                                icon: "brain.head.profile",
                                color: themeProvider.theme.accent
                            )
                            
                            QuickActionCard(
                                title: "Strategy",
                                subtitle: "Plan your moves",
                                icon: "chess.piece",
                                color: themeProvider.theme.accent
                            )
                            
                            QuickActionCard(
                                title: "Metrics",
                                subtitle: "Track progress",
                                icon: "chart.bar.fill",
                                color: themeProvider.theme.accent
                            )
                        }
                    }
                    .padding(.horizontal, 20)
                    
                    Spacer(minLength: 20)
                }
                .padding(.bottom, 20)
            }
            .background(ThemedBackground().environmentObject(themeProvider))
            .navigationTitle("Business")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        // Open business settings
                    } label: {
                        Image(systemName: "gear")
                            .foregroundColor(themeProvider.theme.accent)
                    }
                }
            }
        }
    }
    
    private var personalizedBusinessSubtitle: String {
        guard let prefs = businessPrefs else { return "Ready to accelerate your business growth" }
        
        let focus = prefs.focus.displayName.lowercased()
        let style = prefs.workStyle.displayName.lowercased()
        
        return "Your \(focus)-focused \(style) strategy"
    }
    
    private var todaysBusinessFocus: String {
        guard let prefs = businessPrefs else {
            return "Welcome to your business growth journey! Let's start by identifying your key opportunities and building momentum."
        }
        
        switch prefs.focus {
        case .productivity:
            return "Focus on optimizing your workflows today. Identify bottlenecks and implement systems that will scale with your growth."
        case .leadership:
            return "Today's focus: Develop your leadership presence. Practice clear communication and decision-making that inspires your team."
        case .entrepreneurship:
            return "Channel your entrepreneurial energy today. Explore new opportunities, validate ideas, and take calculated risks that drive innovation."
        case .sales:
            return "Drive revenue growth with strategic sales activities. Focus on qualifying leads and closing deals that align with your ideal customer profile."
        }
    }
}

private struct QuickActionCard: View {
    let title: String
    let subtitle: String
    let icon: String
    let color: Color
    @EnvironmentObject var themeProvider: ThemeProvider
    
    var body: some View {
        Button {
            // Handle action
        } label: {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: icon)
                        .font(.title3)
                        .foregroundColor(color)
                    Spacer()
                    Image(systemName: "arrow.up.right")
                        .font(.caption)
                        .foregroundColor(themeProvider.theme.textSecondary)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(themeProvider.theme.textPrimary)
                    
                    Text(subtitle)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(themeProvider.theme.textSecondary)
                }
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(themeProvider.theme.backgroundSecondary)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.borderLight, lineWidth: 1)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

private struct MindsetView: View {
    @EnvironmentObject var themeProvider: ThemeProvider
    @EnvironmentObject var authService: AuthenticationService
    
    private var mindsetPrefs: MindsetPreferences? {
        authService.currentUser?.preferences?.mindset
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Personalized Header
                    VStack(spacing: 12) {
                        HStack {
                            Image(systemName: "brain.head.profile")
                                .font(.system(size: 24, weight: .medium))
                                .foregroundColor(themeProvider.theme.accent)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Mindful Growth")
                                    .font(.system(size: 28, weight: .bold, design: .rounded))
                                    .foregroundColor(themeProvider.theme.gradientTextPrimary)
                                    .shadow(color: Color.black.opacity(0.3), radius: 1, x: 0, y: 1)
                    
                                Text(personalizedMindsetSubtitle)
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(themeProvider.theme.gradientTextSecondary)
                                    .shadow(color: Color.black.opacity(0.2), radius: 1, x: 0, y: 1)
                            }
                            
                            Spacer()
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 16)
                    }
                    
                    // Mindset Stats Cards
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 16), count: 2), spacing: 16) {
                        StatsCard(
                            title: "Focus Areas",
                            value: "\(mindsetPrefs?.focuses.count ?? 0)",
                            icon: "target",
                            color: themeProvider.theme.accent
                        )
                        
                        StatsCard(
                            title: "Reflection",
                            value: mindsetPrefs?.reflection.displayName ?? "Weekly",
                            icon: "calendar.circle.fill",
                            color: themeProvider.theme.accent
                        )
                        
                        StatsCard(
                            title: "Growth Mode",
                            value: "Active",
                            icon: "chart.line.uptrend.xyaxis",
                            color: themeProvider.theme.accent
                        )
                        
                        StatsCard(
                            title: "Mindfulness",
                            value: "Daily",
                            icon: "leaf.fill",
                            color: themeProvider.theme.accent
                        )
                    }
                    .padding(.horizontal, 20)
                    
                    // Today's Mindset Focus
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Text("Today's Reflection")
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
                            Text(todaysMindsetFocus)
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(themeProvider.theme.textPrimary)
                                .lineSpacing(2)
                            
                            HStack(spacing: 12) {
                                Button {
                                    // Start meditation action
                                } label: {
                                    HStack {
                                        Image(systemName: "leaf.fill")
                                        Text("Meditate")
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
                                
                                Button {
                                    // Journal reflection
                                } label: {
                                    HStack {
                                        Image(systemName: "book.fill")
                                        Text("Journal")
                                            .font(.system(size: 14, weight: .semibold))
                                    }
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 10)
                                    .background(
                                        LinearGradient(
                                            colors: [themeProvider.theme.accent, themeProvider.theme.accent.opacity(0.8)],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                                }
                            }
                        }
                    }
                    .padding(20)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(themeProvider.theme.backgroundSecondary)
                            .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
                    )
                    .padding(.horizontal, 20)
                    
                    // Mindset Focus Areas
                    if let focuses = mindsetPrefs?.focuses, !focuses.isEmpty {
                        VStack(alignment: .leading, spacing: 16) {
                            HStack {
                                Text("Your Focus Areas")
                                    .font(.system(size: 20, weight: .semibold))
                                    .foregroundColor(themeProvider.theme.textPrimary)
                                Spacer()
                            }
                            
                            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 2), spacing: 12) {
                                ForEach(focuses.prefix(4), id: \.self) { focus in
                                    MindsetFocusCard(focus: focus)
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                    
                    Spacer(minLength: 20)
                }
                .padding(.bottom, 20)
            }
            .background(ThemedBackground().environmentObject(themeProvider))
            .navigationTitle("Mindset")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        // Open mindset settings
                    } label: {
                        Image(systemName: "gear")
                            .foregroundColor(themeProvider.theme.accent)
                    }
                }
            }
        }
    }
    
    private var personalizedMindsetSubtitle: String {
        guard let prefs = mindsetPrefs else { return "Ready to cultivate your mindful growth" }
        
        let focusCount = prefs.focuses.count
        let reflection = prefs.reflection.displayName.lowercased()
        
        if focusCount > 0 {
            return "Your \(focusCount) focus areas with \(reflection) reflection"
        } else {
            return "Your mindful journey with \(reflection) reflection"
        }
    }
    
    private var todaysMindsetFocus: String {
        guard let prefs = mindsetPrefs else {
            return "Welcome to your mindset journey! Let's start with a moment of mindful awareness and intention setting."
        }
        
        let focuses = prefs.focuses
        
        if focuses.contains(.mindfulness) {
            return "Center yourself with mindful awareness today. Take 10 minutes to breathe deeply and observe your thoughts without judgment."
        } else if focuses.contains(.growth) {
            return "Focus on personal growth today. Reflect on one area where you'd like to improve and take a small step forward."
        } else if focuses.contains(.habits) {
            return "Focus on building positive habits today. Choose one small habit to practice consistently and observe your progress with compassion."
        } else if focuses.contains(.resilience) {
            return "Cultivate resilience today. Notice challenges as opportunities to grow stronger and more adaptable."
        } else {
            return "Take a moment for mindful reflection today. Check in with yourself and set an intention for growth and presence."
        }
    }
}

private struct MindsetFocusCard: View {
    let focus: MindsetFocus
    @EnvironmentObject var themeProvider: ThemeProvider
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: focus.icon)
                .font(.title3)
                .foregroundColor(themeProvider.theme.accent)
                .frame(width: 24, height: 24)
            
            Text(focus.displayName)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(themeProvider.theme.textPrimary)
            
            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(themeProvider.theme.accent.opacity(0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(themeProvider.theme.accent.opacity(0.2), lineWidth: 1)
                )
        )
    }
}

// Extension to add icons for mindset focus types
private extension MindsetFocus {
    var icon: String {
        switch self {
        case .mindfulness: return "leaf.fill"
        case .growth: return "chart.line.uptrend.xyaxis"
        case .habits: return "target"
        case .resilience: return "shield.fill"
        }
    }
}

private struct CreativityView: View {
    @EnvironmentObject var themeProvider: ThemeProvider
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    Text("Creative Expression")
                        .font(.largeTitle.bold())
                        .foregroundColor(themeProvider.theme.textPrimary)
                    
                    Text("Unlock your creative potential and imagination")
                        .foregroundColor(themeProvider.theme.textSecondary)
                }
                .padding()
            }
            .background(ThemedBackground().environmentObject(themeProvider))
            .navigationTitle("Creativity")
        }
    }
}

private struct WealthView: View {
    @EnvironmentObject var themeProvider: ThemeProvider
    @EnvironmentObject var authService: AuthenticationService
    
    private var wealthPrefs: WealthPreferences? {
        authService.currentUser?.preferences?.wealth
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Personalized Header
                    VStack(spacing: 12) {
                        HStack {
                            Image(systemName: "dollarsign.circle.fill")
                                .font(.system(size: 24, weight: .medium))
                                .foregroundColor(themeProvider.theme.accent)
                            
                            VStack(alignment: .leading, spacing: 4) {
                    Text("Wealth Building")
                                    .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(themeProvider.theme.textPrimary)
                                    .shadow(color: Color.black.opacity(0.3), radius: 1, x: 0, y: 1)
                    
                                Text(personalizedWealthSubtitle)
                                    .font(.system(size: 16, weight: .medium))
                        .foregroundColor(themeProvider.theme.textSecondary)
                                    .shadow(color: Color.black.opacity(0.2), radius: 1, x: 0, y: 1)
                            }
                            
                            Spacer()
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 16)
                    }
                    
                    // Wealth Stats Cards
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 16), count: 2), spacing: 16) {
                        StatsCard(
                            title: "Goals",
                            value: "\(wealthPrefs?.goals.count ?? 0)",
                            icon: "target",
                            color: themeProvider.theme.accent
                        )
                        
                        StatsCard(
                            title: "Risk Level",
                            value: wealthPrefs?.risk.displayName ?? "Moderate",
                            icon: "chart.bar.fill",
                            color: themeProvider.theme.accent
                        )
                        
                        StatsCard(
                            title: "Monthly Budget",
                            value: "$\(wealthPrefs?.monthlyBudget ?? 0)",
                            icon: "creditcard.fill",
                            color: themeProvider.theme.accent
                        )
                        
                        StatsCard(
                            title: "Growth Mode",
                            value: "Active",
                            icon: "chart.line.uptrend.xyaxis",
                            color: themeProvider.theme.accent
                        )
                    }
                    .padding(.horizontal, 20)
                    
                    // Today's Wealth Focus
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Text("Today's Financial Focus")
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundColor(themeProvider.theme.textPrimary)
                                .shadow(color: Color.black.opacity(0.2), radius: 1, x: 0, y: 1)
                            Spacer()
                            Text("AI Optimized")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(themeProvider.theme.accent)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(themeProvider.theme.accent.opacity(0.1))
                                .clipShape(Capsule())
                        }
                        
                        VStack(alignment: .leading, spacing: 12) {
                            Text(todaysWealthFocus)
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(themeProvider.theme.textPrimary)
                                .lineSpacing(2)
                                .shadow(color: Color.black.opacity(0.1), radius: 1, x: 0, y: 1)
                            
                            HStack(spacing: 12) {
                                Button {
                                    // Portfolio review action
                                } label: {
                                    HStack {
                                        Image(systemName: "chart.pie.fill")
                                        Text("Review Portfolio")
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
                                
                                Button {
                                    // Investment tracker
                                } label: {
                                    HStack {
                                        Image(systemName: "plus.circle.fill")
                                        Text("Track Investment")
                                            .font(.system(size: 14, weight: .semibold))
                                    }
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 10)
                                    .background(
                                        LinearGradient(
                                            colors: [themeProvider.theme.accent, themeProvider.theme.accent.opacity(0.8)],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                                }
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
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Text("Wealth Actions")
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundColor(themeProvider.theme.gradientTextPrimary)
                                .shadow(color: Color.black.opacity(0.2), radius: 1, x: 0, y: 1)
                            Spacer()
                        }
                        
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 2), spacing: 12) {
                            QuickActionCard(
                                title: "Budget Review",
                                subtitle: "Track spending",
                                icon: "list.bullet.clipboard",
                                color: themeProvider.theme.accent
                            )
                            
                            QuickActionCard(
                                title: "Market Watch",
                                subtitle: "Check trends",
                                icon: "chart.line.uptrend.xyaxis",
                                color: themeProvider.theme.accent
                            )
                            
                            QuickActionCard(
                                title: "Investment Ideas",
                                subtitle: "Explore options",
                                icon: "lightbulb.fill",
                                color: themeProvider.theme.accent
                            )
                            
                            QuickActionCard(
                                title: "Goal Progress",
                                subtitle: "Track milestones",
                                icon: "flag.fill",
                                color: themeProvider.theme.accent
                            )
                        }
                    }
                    .padding(.horizontal, 20)
                    
                    Spacer(minLength: 20)
                }
                .padding(.bottom, 20)
            }
            .background(ThemedBackground().environmentObject(themeProvider))
            .navigationTitle("Wealth")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        // Open wealth settings
                    } label: {
                        Image(systemName: "gear")
                            .foregroundColor(themeProvider.theme.accent)
                    }
                }
            }
        }
    }
    
    private var personalizedWealthSubtitle: String {
        guard let prefs = wealthPrefs else { return "Ready to build your financial freedom" }
        
        let goalCount = prefs.goals.count
        let risk = prefs.risk.displayName.lowercased()
        
        if goalCount > 0 {
            return "Your \(goalCount) wealth goals with \(risk) risk approach"
        } else {
            return "Your \(risk) risk wealth building journey"
        }
    }
    
    private var todaysWealthFocus: String {
        guard let prefs = wealthPrefs else {
            return "Welcome to your wealth building journey! Let's start by setting clear financial goals and building healthy money habits."
        }
        
        let goals = prefs.goals
        let risk = prefs.risk
        
        if goals.contains(.saving) {
            return "Focus on building your savings today. Aim to save consistently and watch your financial security grow over time."
        } else if goals.contains(.investing) {
            switch risk {
            case .low: return "Consider low-risk investment options today. Explore index funds and bonds that align with your conservative approach."
            case .moderate: return "Balance your portfolio today. Mix growth investments with stable assets for optimal risk-adjusted returns."
            case .high: return "Explore growth opportunities today. Research emerging markets and growth stocks that match your risk tolerance."
            }
        } else if goals.contains(.debtFree) {
            return "Tackle your debt strategically today. Focus on high-interest debt first and consider debt consolidation options."
        } else if goals.contains(.income) {
            return "Focus on increasing your income streams today. Explore opportunities to enhance your skills or create additional revenue sources."
        } else {
            return "Set your wealth foundation today. Define your financial goals and start tracking your income and expenses."
        }
    }
}

private struct RelationshipsView: View {
    @EnvironmentObject var themeProvider: ThemeProvider
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    Text("Meaningful Connections")
                        .font(.largeTitle.bold())
                        .foregroundColor(themeProvider.theme.textPrimary)
                    
                    Text("Build deeper, more authentic relationships")
                        .foregroundColor(themeProvider.theme.textSecondary)
                }
                .padding()
            }
            .background(ThemedBackground().environmentObject(themeProvider))
            .navigationTitle("Relationships")
        }
    }
}

private struct LearningView: View {
    @EnvironmentObject var themeProvider: ThemeProvider
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    Text("Continuous Learning")
                        .font(.largeTitle.bold())
                        .foregroundColor(themeProvider.theme.textPrimary)
                    
                    Text("Expand your knowledge and skills")
                        .foregroundColor(themeProvider.theme.textSecondary)
                }
                .padding()
            }
            .background(ThemedBackground().environmentObject(themeProvider))
            .navigationTitle("Learning")
        }
    }
}

private struct SpiritualityView: View {
    @EnvironmentObject var themeProvider: ThemeProvider
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    Text("Spiritual Journey")
                        .font(.largeTitle.bold())
                        .foregroundColor(themeProvider.theme.textPrimary)
                    
                    Text("Connect with your inner wisdom and purpose")
                        .foregroundColor(themeProvider.theme.textSecondary)
                }
                .padding()
            }
            .background(ThemedBackground().environmentObject(themeProvider))
            .navigationTitle("Spirituality")
        }
    }
}

private struct AdventureView: View {
    @EnvironmentObject var themeProvider: ThemeProvider
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    Text("Adventure Awaits")
                        .font(.largeTitle.bold())
                        .foregroundColor(themeProvider.theme.textPrimary)
                    
                    Text("Embrace new experiences and challenges")
                        .foregroundColor(themeProvider.theme.textSecondary)
                }
                .padding()
            }
            .background(ThemedBackground().environmentObject(themeProvider))
            .navigationTitle("Adventure")
        }
    }
}

private struct LeadershipView: View {
    @EnvironmentObject var themeProvider: ThemeProvider
    @EnvironmentObject var authService: AuthenticationService
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Personalized Header
                    VStack(spacing: 12) {
                        HStack {
                            Image(systemName: "crown.fill")
                                .font(.system(size: 24, weight: .medium))
                                .foregroundColor(themeProvider.theme.accent)
                            
                            VStack(alignment: .leading, spacing: 4) {
                    Text("Leadership Excellence")
                                    .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(themeProvider.theme.textPrimary)
                                    .shadow(color: Color.black.opacity(0.3), radius: 1, x: 0, y: 1)
                    
                                Text("Develop authentic influence and impact")
                                    .font(.system(size: 16, weight: .medium))
                        .foregroundColor(themeProvider.theme.textSecondary)
                                    .shadow(color: Color.black.opacity(0.2), radius: 1, x: 0, y: 1)
                            }
                            
                            Spacer()
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 16)
                    }
                    
                    // Leadership Stats Cards
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 16), count: 2), spacing: 16) {
                        StatsCard(
                            title: "Leadership Style",
                            value: "Authentic",
                            icon: "person.2.fill",
                            color: themeProvider.theme.accent
                        )
                        
                        StatsCard(
                            title: "Focus Area",
                            value: "Growth",
                            icon: "chart.line.uptrend.xyaxis",
                            color: themeProvider.theme.accent
                        )
                        
                        StatsCard(
                            title: "Team Impact",
                            value: "High",
                            icon: "star.fill",
                            color: themeProvider.theme.accent
                        )
                        
                        StatsCard(
                            title: "Development",
                            value: "Active",
                            icon: "brain.head.profile",
                            color: themeProvider.theme.accent
                        )
                    }
                    .padding(.horizontal, 20)
                    
                    // Today's Leadership Focus
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Text("Today's Leadership Challenge")
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundColor(themeProvider.theme.textPrimary)
                                .shadow(color: Color.black.opacity(0.2), radius: 1, x: 0, y: 1)
                            Spacer()
                            Text("Growth Focused")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(themeProvider.theme.accent)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(themeProvider.theme.accent.opacity(0.1))
                                .clipShape(Capsule())
                        }
                        
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Practice empathetic leadership today. Listen actively to three team members and understand their perspectives before making decisions.")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(themeProvider.theme.textPrimary)
                                .lineSpacing(2)
                                .shadow(color: Color.black.opacity(0.1), radius: 1, x: 0, y: 1)
                            
                            HStack(spacing: 12) {
                                Button {
                                    // Team check-in action
                                } label: {
                                    HStack {
                                        Image(systemName: "person.2.fill")
                                        Text("Team Check-in")
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
                                
                                Button {
                                    // Feedback session
                                } label: {
                                    HStack {
                                        Image(systemName: "message.fill")
                                        Text("Give Feedback")
                                            .font(.system(size: 14, weight: .semibold))
                                    }
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 10)
                                    .background(
                                        LinearGradient(
                                            colors: [themeProvider.theme.accent, themeProvider.theme.accent.opacity(0.8)],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                                }
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
                    
                    // Leadership Actions
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Text("Leadership Actions")
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundColor(themeProvider.theme.gradientTextPrimary)
                                .shadow(color: Color.black.opacity(0.2), radius: 1, x: 0, y: 1)
                            Spacer()
                        }
                        
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 2), spacing: 12) {
                            QuickActionCard(
                                title: "Vision Setting",
                                subtitle: "Define direction",
                                icon: "eye.fill",
                                color: themeProvider.theme.accent
                            )
                            
                            QuickActionCard(
                                title: "Team Building",
                                subtitle: "Strengthen bonds",
                                icon: "person.3.fill",
                                color: themeProvider.theme.accent
                            )
                            
                            QuickActionCard(
                                title: "Decision Making",
                                subtitle: "Lead with clarity",
                                icon: "arrow.triangle.branch",
                                color: themeProvider.theme.accent
                            )
                            
                            QuickActionCard(
                                title: "Mentoring",
                                subtitle: "Develop others",
                                icon: "hand.raised.fill",
                                color: themeProvider.theme.accent
                            )
                        }
                    }
                    .padding(.horizontal, 20)
                    
                    Spacer(minLength: 20)
                }
                .padding(.bottom, 20)
            }
            .background(ThemedBackground().environmentObject(themeProvider))
            .navigationTitle("Leadership")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        // Open leadership settings
                    } label: {
                        Image(systemName: "gear")
                            .foregroundColor(themeProvider.theme.accent)
                    }
                }
            }
        }
    }
}

private struct HealthView: View {
    @EnvironmentObject var themeProvider: ThemeProvider
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    Text("Holistic Health")
                        .font(.largeTitle.bold())
                        .foregroundColor(themeProvider.theme.gradientTextPrimary)
                        .shadow(color: Color.black.opacity(0.3), radius: 1, x: 0, y: 1)
                    
                    Text("Optimize your physical and mental wellbeing")
                        .foregroundColor(themeProvider.theme.gradientTextSecondary)
                        .shadow(color: Color.black.opacity(0.2), radius: 1, x: 0, y: 1)
                }
                .padding()
            }
            .background(ThemedBackground().environmentObject(themeProvider))
            .navigationTitle("Health")
        }
    }
}

private struct FamilyView: View {
    @EnvironmentObject var themeProvider: ThemeProvider
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    Text("Family Harmony")
                        .font(.largeTitle.bold())
                        .foregroundColor(themeProvider.theme.textPrimary)
                    
                    Text("Strengthen bonds with those you love most")
                        .foregroundColor(themeProvider.theme.textSecondary)
                }
                .padding()
            }
            .background(ThemedBackground().environmentObject(themeProvider))
            .navigationTitle("Family")
        }
    }
}

// MARK: - Feed Card + Shimmer

private struct EnhancedFeedCard: View {
    let item: FeedItem
    @EnvironmentObject var themeProvider: ThemeProvider
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Image section
            AsyncImage(url: URL(string: item.imageUrl ?? "")) { phase in
                switch phase {
                case .empty:
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.backgroundTertiary)
                        .frame(height: 200)
                        .shimmer()
                case .success(let img):
                    img
                        .resizable()
                        .scaledToFill()
                        .frame(height: 200)
                        .clipped()
                        .overlay(
                            // Gradient overlay for better text readability
                            LinearGradient(
                                colors: [Color.clear, Color.black.opacity(0.3)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                case .failure:
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.backgroundTertiary)
                        .frame(height: 200)
                        .overlay(
                            Image(systemName: "photo")
                                .foregroundColor(themeProvider.theme.textSecondary)
                                .font(.title)
                        )
                @unknown default:
                    EmptyView()
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            
            // Content section
            VStack(alignment: .leading, spacing: 12) {
                if let title = item.title {
                    Text(title)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(Color(red: 26/255, green: 32/255, blue: 46/255)) // High contrast dark
                        .lineLimit(2)
                }
                
                Text(item.text)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(Color(red: 71/255, green: 85/255, blue: 105/255)) // Medium contrast
                    .lineLimit(3)
                    .lineSpacing(2)
                
                // Tags and action
                HStack {
                    // Tags
                    HStack(spacing: 6) {
                        ForEach(item.topicTags.prefix(2), id: \.self) { tag in
                            Text(tag.capitalized)
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(themeProvider.theme.accent)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(
                                    Capsule()
                                        .fill(themeProvider.theme.accent.opacity(0.1))
                                )
                        }
                    }
                    
                    Spacer()
                    
                    // Action button
                    Button {
                        // Handle feed item action
                    } label: {
                        Image(systemName: "arrow.up.right")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(themeProvider.theme.accent)
                    }
                }
            }
            .padding(16)
        }
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(themeProvider.theme.backgroundSecondary)
                .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
        )
    }
}

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
