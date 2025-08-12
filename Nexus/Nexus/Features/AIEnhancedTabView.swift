//
//  AIEnhancedTabView.swift
//  Flowmate
//
//  Created on 2025-01-13
//

import SwiftUI

// MARK: - AI Enhanced Tab View Wrapper

struct AIEnhancedTabView: View {
    let interest: UserInterest
    let originalView: AnyView
    
    @EnvironmentObject var themeProvider: ThemeProvider
    @EnvironmentObject var authService: AuthenticationService
    @StateObject private var agentManager = SimpleAgentManager.shared
    
    @State private var showingAIPanel = false
    @State private var selectedAction: String?
    
    var body: some View {
        ZStack {
            // Original tab content
            originalView
            
            // AI Enhancement Overlay
            VStack {
                // AI Status Bar at top
                AIStatusBar(
                    interest: interest,
                    agentManager: agentManager,
                    onToggle: {
                        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                            showingAIPanel.toggle()
                        }
                    }
                )
                .padding(.horizontal)
                .padding(.top, 8)
                
                Spacer()
                
                // Expandable AI Panel
                if showingAIPanel {
                    AIActionPanel(
                        interest: interest,
                        agentManager: agentManager,
                        onActionTap: { action in
                            selectedAction = action
                            // Handle AI action
                        }
                    )
                    .transition(.asymmetric(
                        insertion: .move(edge: .bottom).combined(with: .opacity),
                        removal: .move(edge: .bottom).combined(with: .opacity)
                    ))
                }
            }
        }
        .onAppear {
            loadAIInsight()
        }
    }
    
    private func loadAIInsight() {
        guard let user = authService.currentUser else { return }
        
        Task {
            await agentManager.generateInsight(for: interest, user: user)
        }
    }
}

// MARK: - AI Status Bar

struct AIStatusBar: View {
    let interest: UserInterest
    @ObservedObject var agentManager: SimpleAgentManager
    let onToggle: () -> Void
    
    @EnvironmentObject var themeProvider: ThemeProvider
    @State private var pulseScale: CGFloat = 1.0
    
    var body: some View {
        HStack {
            // AI Agent Icon
            HStack(spacing: 8) {
                Image(systemName: "brain.head.profile")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(themeProvider.theme.accent)
                    .scaleEffect(pulseScale)
                    .onAppear {
                        withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
                            pulseScale = 1.2
                        }
                    }
                
                Text(agentManager.getAgent(for: interest).name)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(themeProvider.theme.textPrimary)
            }
            
            Spacer()
            
            // AI Toggle Button
            Button(action: onToggle) {
                HStack(spacing: 6) {
                    if agentManager.isLoading {
                        ProgressView()
                            .scaleEffect(0.7)
                    } else {
                        Image(systemName: "sparkles")
                            .font(.system(size: 12, weight: .semibold))
                    }
                    
                    Text("AI")
                        .font(.system(size: 12, weight: .bold))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(themeProvider.theme.accent)
                )
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(themeProvider.theme.backgroundSecondary.opacity(0.95))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(themeProvider.theme.accent.opacity(0.3), lineWidth: 1)
                )
        )
        .shadow(
            color: themeProvider.theme.accent.opacity(0.1),
            radius: 8,
            x: 0,
            y: 4
        )
    }
}

// MARK: - AI Action Panel

struct AIActionPanel: View {
    let interest: UserInterest
    @ObservedObject var agentManager: SimpleAgentManager
    let onActionTap: (String) -> Void
    
    @EnvironmentObject var themeProvider: ThemeProvider
    
    var body: some View {
        VStack(spacing: 20) {
            // AI Insight Card
            if let insight = agentManager.currentInsight {
                AIInsightDisplayCard(insight: insight, interest: interest)
            }
            
            // Quick Actions Grid
                                    AISimpleActionsGrid(
                actions: agentManager.getAgent(for: interest).getQuickActions(),
                onActionTap: onActionTap
            )
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(themeProvider.theme.backgroundSecondary)
                .shadow(
                    color: Color.black.opacity(0.1),
                    radius: 15,
                    x: 0,
                    y: -5
                )
        )
        .padding(.horizontal)
        .padding(.bottom, 100) // Space above tab bar
    }
}

// MARK: - AI Insight Display Card

struct AIInsightDisplayCard: View {
    let insight: String
    let interest: UserInterest
    
    @EnvironmentObject var themeProvider: ThemeProvider
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: getIconForInterest(interest))
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(themeProvider.theme.accent)
                
                Text("AI Insight")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(themeProvider.theme.textPrimary)
                
                Spacer()
                
                Text("Personalized")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(themeProvider.theme.textSecondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(
                        RoundedRectangle(cornerRadius: 6)
                            .fill(themeProvider.theme.accent.opacity(0.2))
                    )
            }
            
            Text(insight)
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(themeProvider.theme.textPrimary)
                .multilineTextAlignment(.leading)
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(themeProvider.theme.accent.opacity(0.1))
                )
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(themeProvider.theme.background.opacity(0.8))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(themeProvider.theme.accent.opacity(0.2), lineWidth: 1)
                )
        )
    }
    
    private func getIconForInterest(_ interest: UserInterest) -> String {
        switch interest {
        case .fitness: return "figure.run"
        case .business: return "briefcase.fill"
        case .wealth: return "dollarsign.circle.fill"
        case .mindset: return "brain.head.profile"
        case .creativity: return "paintbrush.fill"
        case .relationships: return "heart.fill"
        case .learning: return "book.fill"
        case .spirituality: return "leaf.fill"
        case .adventure: return "mountain.2.fill"
        case .leadership: return "crown.fill"
        case .health: return "cross.fill"
        case .family: return "house.fill"
        }
    }
}

// MARK: - AI Quick Actions Grid

struct AISimpleActionsGrid: View {
    let actions: [String]
    let onActionTap: (String) -> Void
    
    @EnvironmentObject var themeProvider: ThemeProvider
    
    var body: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
            ForEach(Array(actions.enumerated()), id: \.offset) { index, action in
                Button(action: { onActionTap(action) }) {
                    VStack(spacing: 8) {
                        Image(systemName: getActionIcon(action, index: index))
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(themeProvider.theme.accent)
                        
                        Text(action)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(themeProvider.theme.textPrimary)
                            .multilineTextAlignment(.center)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(.vertical, 16)
                    .padding(.horizontal, 8)
                    .frame(maxWidth: .infinity)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(themeProvider.theme.backgroundSecondary)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(themeProvider.theme.accent.opacity(0.3), lineWidth: 1)
                            )
                    )
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
    }
    
    private func getActionIcon(_ action: String, index: Int) -> String {
        let icons = ["sparkles", "bolt.fill", "target", "chart.line.uptrend.xyaxis", "lightbulb.fill", "star.fill"]
        return icons[index % icons.count]
    }
}

// MARK: - Preview

#Preview {
    AIEnhancedTabView(
        interest: .fitness,
        originalView: AnyView(
            ScrollView {
                VStack {
                    Text("Original Fitness Content")
                        .font(.title)
                        .padding()
                    
                    ForEach(0..<10) { i in
                        Text("Content item \(i)")
                            .padding()
                    }
                }
            }
        )
    )
    .environmentObject(ThemeProvider())
    .environmentObject(AuthenticationService())
}
