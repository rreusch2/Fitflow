//
//  MainTabView.swift
//  Flowmate
//
//  Created on 2025-01-13
//

import SwiftUI

// MARK: - UserInterest Extension for Dynamic UI

extension UserInterest {
    var icon: String {
        switch self {
        case .fitness: return "figure.run"
        case .business: return "briefcase.fill"
        case .mindset: return "brain.head.profile"
        case .creativity: return "paintbrush.fill"
        case .wealth: return "dollarsign.circle.fill"
        case .relationships: return "heart.fill"
        case .learning: return "book.fill"
        case .spirituality: return "leaf.fill"
        case .adventure: return "mountain.2.fill"
        case .leadership: return "crown.fill"
        case .health: return "mind.head.profile"
        case .family: return "house.fill"
        }
    }
    
    var title: String {
        switch self {
        case .fitness: return "Fitness"
        case .business: return "Business"
        case .mindset: return "Mindset"
        case .creativity: return "Creativity"
        case .wealth: return "Wealth"
        case .relationships: return "Relationships"
        case .learning: return "Learning"
        case .spirituality: return "Spirituality"
        case .adventure: return "Adventure"
        case .leadership: return "Leadership"
        case .health: return "Health"
        case .family: return "Family"
        }
    }
    
    var subtitle: String {
        switch self {
        case .fitness: return "Your strength journey"
        case .business: return "Entrepreneurial excellence"
        case .mindset: return "Mental transformation"
        case .creativity: return "Artistic expression"
        case .wealth: return "Financial freedom"
        case .relationships: return "Meaningful connections"
        case .learning: return "Knowledge expansion"
        case .spirituality: return "Inner wisdom"
        case .adventure: return "New experiences"
        case .leadership: return "Inspiring others"
        case .health: return "Complete wellness"
        case .family: return "Stronger bonds"
        }
    }
}

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
        .background(themeProvider.theme.backgroundPrimary.ignoresSafeArea())
    }
    
    // Revolutionary dynamic tab system based on user interests
    private var dynamicTabs: [(title: String, icon: String, view: AnyView)] {
        var tabs: [(String, String, AnyView)] = []
        
        if userInterests.contains(.fitness) {
            tabs.append(("Fitness", "figure.run", AnyView(FitnessView())))
        }
        
        if userInterests.contains(.business) {
            tabs.append(("Business", "briefcase.fill", AnyView(BusinessView())))
        }
        
        if userInterests.contains(.mindset) {
            tabs.append(("Mindset", "brain.head.profile", AnyView(MindsetView())))
        }
        
        if userInterests.contains(.creativity) {
            tabs.append(("Create", "paintbrush.fill", AnyView(CreativityView())))
        }
        
        if userInterests.contains(.wealth) {
            tabs.append(("Wealth", "dollarsign.circle.fill", AnyView(WealthView())))
        }
        
        if userInterests.contains(.relationships) {
            tabs.append(("Connect", "heart.fill", AnyView(RelationshipsView())))
        }
        
        if userInterests.contains(.learning) {
            tabs.append(("Learn", "book.fill", AnyView(LearningView())))
        }
        
        if userInterests.contains(.spirituality) {
            tabs.append(("Spirit", "leaf.fill", AnyView(SpiritualityView())))
        }
        
        if userInterests.contains(.adventure) {
            tabs.append(("Adventure", "mountain.2.fill", AnyView(AdventureView())))
        }
        
        if userInterests.contains(.leadership) {
            tabs.append(("Lead", "crown.fill", AnyView(LeadershipView())))
        }
        
        if userInterests.contains(.health) {
            tabs.append(("Health", "mind.head.profile", AnyView(HealthView())))
        }
        
        if userInterests.contains(.family) {
            tabs.append(("Family", "house.fill", AnyView(FamilyView())))
        }
        
        return tabs
    }
}

// MARK: - Revolutionary Dynamic Views

private struct PersonalizedFeedView: View {
    @EnvironmentObject var themeProvider: ThemeProvider
    @EnvironmentObject var authService: AuthenticationService
    
    private var userInterests: [UserInterest] {
        authService.currentUser?.preferences?.theme.selectedInterests ?? []
    }
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

private struct FlowmateCoachView: View {
    @EnvironmentObject var themeProvider: ThemeProvider
    @EnvironmentObject var authService: AuthenticationService
    
    private var userInterests: [UserInterest] {
        authService.currentUser?.preferences?.theme.selectedInterests ?? []
    }
    
    var body: some View {
        NavigationStack {
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
                            .foregroundColor(themeProvider.theme.textPrimary)
                        
                        Text("AI-powered guidance tailored to your \(userInterests.map { $0.title.lowercased() }.joined(separator: ", ")) journey")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(themeProvider.theme.textSecondary)
                            .multilineTextAlignment(.center)
                            .lineLimit(2)
                    }
                }
                .padding(.top, 20)
                
                Spacer()
                
                // Quick Actions
                VStack(spacing: 12) {
                    Text("Quick Actions")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(themeProvider.theme.textPrimary)
                    
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
                                        .foregroundColor(themeProvider.theme.textPrimary)
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
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                }
                .padding(.horizontal, 20)
                
                Spacer()
                
                // Start Conversation Button
                Button {
                    // Start AI conversation
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "message.fill")
                            .font(.title3)
                        Text("Start Conversation")
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
            .navigationTitle("Coach")
            .background(themeProvider.theme.backgroundPrimary.ignoresSafeArea())
        }
    }
    
    private var quickActions: [(title: String, icon: String)] {
        var actions: [(String, String)] = [("Daily Check-in", "checkmark.circle"), ("Goal Setting", "target")]
        
        if userInterests.contains(.fitness) {
            actions.append(("Workout Plan", "figure.run"))
        }
        if userInterests.contains(.business) {
            actions.append(("Business Advice", "briefcase"))
        }
        if userInterests.contains(.mindset) {
            actions.append(("Mindfulness", "brain.head.profile"))
        }
        if userInterests.contains(.creativity) {
            actions.append(("Creative Boost", "paintbrush"))
        }
        
        return Array(actions.prefix(6)) // Limit to 6 actions for clean layout
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
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    Text("Your Fitness Journey")
                        .font(.largeTitle.bold())
                        .foregroundColor(themeProvider.theme.textPrimary)
                    
                    Text("AI-powered workouts tailored to your goals")
                        .foregroundColor(themeProvider.theme.textSecondary)
                }
                .padding()
            }
            .background(themeProvider.theme.backgroundPrimary.ignoresSafeArea())
            .navigationTitle("Fitness")
        }
    }
}

private struct BusinessView: View {
    @EnvironmentObject var themeProvider: ThemeProvider
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    Text("Business Excellence")
                        .font(.largeTitle.bold())
                        .foregroundColor(themeProvider.theme.textPrimary)
                    
                    Text("Strategic insights for entrepreneurial success")
                        .foregroundColor(themeProvider.theme.textSecondary)
                }
                .padding()
            }
            .background(themeProvider.theme.backgroundPrimary.ignoresSafeArea())
            .navigationTitle("Business")
        }
    }
}

private struct MindsetView: View {
    @EnvironmentObject var themeProvider: ThemeProvider
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    Text("Mindful Growth")
                        .font(.largeTitle.bold())
                        .foregroundColor(themeProvider.theme.textPrimary)
                    
                    Text("Cultivate a powerful mindset for transformation")
                        .foregroundColor(themeProvider.theme.textSecondary)
                }
                .padding()
            }
            .background(themeProvider.theme.backgroundPrimary.ignoresSafeArea())
            .navigationTitle("Mindset")
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
            .background(themeProvider.theme.backgroundPrimary.ignoresSafeArea())
            .navigationTitle("Creativity")
        }
    }
}

private struct WealthView: View {
    @EnvironmentObject var themeProvider: ThemeProvider
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    Text("Wealth Building")
                        .font(.largeTitle.bold())
                        .foregroundColor(themeProvider.theme.textPrimary)
                    
                    Text("Smart strategies for financial freedom")
                        .foregroundColor(themeProvider.theme.textSecondary)
                }
                .padding()
            }
            .background(themeProvider.theme.backgroundPrimary.ignoresSafeArea())
            .navigationTitle("Wealth")
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
            .background(themeProvider.theme.backgroundPrimary.ignoresSafeArea())
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
            .background(themeProvider.theme.backgroundPrimary.ignoresSafeArea())
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
            .background(themeProvider.theme.backgroundPrimary.ignoresSafeArea())
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
            .background(themeProvider.theme.backgroundPrimary.ignoresSafeArea())
            .navigationTitle("Adventure")
        }
    }
}

private struct LeadershipView: View {
    @EnvironmentObject var themeProvider: ThemeProvider
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    Text("Leadership Excellence")
                        .font(.largeTitle.bold())
                        .foregroundColor(themeProvider.theme.textPrimary)
                    
                    Text("Develop authentic leadership skills")
                        .foregroundColor(themeProvider.theme.textSecondary)
                }
                .padding()
            }
            .background(themeProvider.theme.backgroundPrimary.ignoresSafeArea())
            .navigationTitle("Leadership")
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
                        .foregroundColor(themeProvider.theme.textPrimary)
                    
                    Text("Optimize your physical and mental wellbeing")
                        .foregroundColor(themeProvider.theme.textSecondary)
                }
                .padding()
            }
            .background(themeProvider.theme.backgroundPrimary.ignoresSafeArea())
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
            .background(themeProvider.theme.backgroundPrimary.ignoresSafeArea())
            .navigationTitle("Family")
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
