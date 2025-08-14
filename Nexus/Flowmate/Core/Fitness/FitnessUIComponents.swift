//
//  FitnessUIComponents.swift
//  Flowmate
//
//  Created on 2025-01-13
//

import SwiftUI

// MARK: - Enhanced Stats Card
struct EnhancedStatsCard: View {
    let title: String
    let value: String
    let icon: String
    let gradient: [Color]
    let subtitle: String
    @EnvironmentObject var themeProvider: ThemeProvider
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(
                        LinearGradient(
                            colors: gradient,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                
                Spacer()
                
                Text(subtitle)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(gradient.first?.opacity(0.8))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(
                        Capsule()
                            .fill(gradient.first?.opacity(0.1) ?? Color.clear)
                    )
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(value)
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(themeProvider.theme.textPrimary)
                
                Text(title)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(themeProvider.theme.textSecondary)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(themeProvider.theme.backgroundSecondary)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(
                            LinearGradient(
                                colors: [gradient.first?.opacity(0.3) ?? Color.clear, Color.clear],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
                .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
        )
    }
}

// MARK: - Muscle Group Button
struct MuscleGroupButton: View {
    let group: MuscleGroup
    let isSelected: Bool
    let action: () -> Void
    @EnvironmentObject var themeProvider: ThemeProvider
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: group.icon)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(isSelected ? .white : themeProvider.theme.accent)
                
                Text(group.displayName)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(isSelected ? .white : themeProvider.theme.textPrimary)
            }
            .frame(height: 60)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(
                        isSelected ? 
                        LinearGradient(
                            colors: [themeProvider.theme.accent, themeProvider.theme.accent.opacity(0.8)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ) :
                        LinearGradient(
                            colors: [themeProvider.theme.backgroundSecondary, themeProvider.theme.backgroundSecondary],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(
                                isSelected ? Color.clear : Color.gray.opacity(0.2),
                                lineWidth: 1
                            )
                    )
                    .shadow(
                        color: isSelected ? themeProvider.theme.accent.opacity(0.3) : Color.black.opacity(0.05),
                        radius: isSelected ? 8 : 4,
                        x: 0,
                        y: isSelected ? 4 : 2
                    )
            )
        }
        .scaleEffect(isSelected ? 1.05 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
    }
}

// MARK: - Quick Action Card
struct QuickActionCard: View {
    let title: String
    let subtitle: String
    let icon: String
    let gradient: [Color]
    let action: () -> Void
    @EnvironmentObject var themeProvider: ThemeProvider
    
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: icon)
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundStyle(
                            LinearGradient(
                                colors: gradient,
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    
                    Spacer()
                    
                    Image(systemName: "arrow.up.right")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(themeProvider.theme.textSecondary)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(themeProvider.theme.textPrimary)
                    
                    Text(subtitle)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(themeProvider.theme.textSecondary)
                }
            }
            .padding(16)
            .frame(width: 140, height: 100)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(themeProvider.theme.backgroundSecondary)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(
                                LinearGradient(
                                    colors: [gradient.first?.opacity(0.3) ?? Color.clear, Color.clear],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    )
                    .shadow(color: Color.black.opacity(0.05), radius: 6, x: 0, y: 3)
            )
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

// MARK: - Insight Card
struct InsightCard: View {
    let insight: String
    let type: InsightType
    let icon: String
    @EnvironmentObject var themeProvider: ThemeProvider
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(type.color)
                .frame(width: 32, height: 32)
                .background(
                    Circle()
                        .fill(type.color.opacity(0.1))
                )
            
            VStack(alignment: .leading, spacing: 4) {
                Text(type.title)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(type.color)
                
                Text(insight)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(themeProvider.theme.textPrimary)
                    .lineLimit(3)
                    .multilineTextAlignment(.leading)
            }
            
            Spacer()
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(themeProvider.theme.backgroundSecondary)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(type.color.opacity(0.2), lineWidth: 1)
                )
        )
    }
}

enum InsightType {
    case positive
    case suggestion
    case tip
    case warning
    
    var title: String {
        switch self {
        case .positive: return "Great Progress!"
        case .suggestion: return "Suggestion"
        case .tip: return "Pro Tip"
        case .warning: return "Attention"
        }
    }
    
    var color: Color {
        switch self {
        case .positive: return .green
        case .suggestion: return .blue
        case .tip: return .orange
        case .warning: return .red
        }
    }
}

// MARK: - Scale Button Style
struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.spring(response: 0.2, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

#Preview {
    VStack(spacing: 20) {
        EnhancedStatsCard(
            title: "Fitness Level",
            value: "Intermediate",
            icon: "trophy.fill",
            gradient: [Color.orange, Color.red],
            subtitle: "Keep pushing!"
        )
        
        HStack {
            MuscleGroupButton(
                group: .chest,
                isSelected: false,
                action: {}
            )
            
            MuscleGroupButton(
                group: .quadriceps,
                isSelected: true,
                action: {}
            )
        }
        
        QuickActionCard(
            title: "Progress Tracker",
            subtitle: "View your journey",
            icon: "chart.line.uptrend.xyaxis",
            gradient: [Color.blue, Color.cyan],
            action: {}
        )
        
        InsightCard(
            insight: "Your consistency has improved 40% this month! Keep up the momentum.",
            type: .positive,
            icon: "arrow.up.circle.fill"
        )
    }
    .padding()
    .environmentObject(ThemeProvider())
}
