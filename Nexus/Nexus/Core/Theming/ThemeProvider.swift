//
//  ThemeProvider.swift
//  Fitflow
//
//  Created on 2025-01-13
//

import SwiftUI

enum ThemeStyle: String, CaseIterable, Codable {
    case energetic      // High energy, motivational
    case professional   // Business, productivity focused
    case mindful        // Wellness, meditation, calm
    case creative       // Artistic, hobbies, self-expression
    case balanced       // Mixed interests, harmonious
    case calm
    case minimal
    case playful
}

enum AccentColorChoice: String, CaseIterable, Codable {
    case coral          // Primary brand
    case gold           // Achievement, success
    case ocean          // Trust, professional
    case fitness        // Health, energy
    case business       // Productivity, growth
    case mindset        // Wellness, balance
    case creative       // Art, hobbies
}

struct Theme {
    let backgroundPrimary: Color
    let backgroundSecondary: Color
    let textPrimary: Color
    let textSecondary: Color
    let accent: Color
    let emphasis: Color
}

@MainActor
final class ThemeProvider: ObservableObject {
    @Published private(set) var theme: Theme
    @Published private(set) var style: ThemeStyle
    @Published private(set) var accentChoice: AccentColorChoice
    
    init() {
        self.style = .balanced
        self.accentChoice = .coral
        self.theme = ThemeProvider.buildTheme(style: .balanced, accent: .coral)
    }
    
    func applyTheme(for user: User?) {
        guard let prefs = user?.preferences else {
            setTheme(style: .balanced, accent: .coral)
            return
        }
        
        // Map communication style to theme style
        let mappedStyle: ThemeStyle
        switch prefs.motivation.communicationStyle {
        case .energetic: mappedStyle = .energetic
        case .calm: mappedStyle = .mindful
        case .supportive: mappedStyle = .balanced
        case .humorous: mappedStyle = .creative
        case .tough: mappedStyle = .professional
        case .scientific: mappedStyle = .professional
        }
        
        // Determine primary interest area for accent color
        let hasBusinessGoals = !prefs.goals.isEmpty && prefs.goals.contains { $0.type == .career }
        let hasFitnessInterest = !prefs.fitness.preferredActivities.isEmpty
        let hasCreativeInterest = prefs.fitness.preferredActivities.contains(.dancing)
        
        let accent: AccentColorChoice
        if hasBusinessGoals {
            accent = .business
        } else if hasFitnessInterest {
            accent = .fitness
        } else if hasCreativeInterest {
            accent = .creative
        } else {
            // Default based on communication style
            switch prefs.motivation.communicationStyle {
            case .energetic: accent = .coral
            case .calm: accent = .mindset
            case .scientific, .tough: accent = .business
            case .humorous: accent = .creative
            case .supportive: accent = .gold
            }
        }
        
        setTheme(style: mappedStyle, accent: accent)
    }
    
    func setTheme(style: ThemeStyle, accent: AccentColorChoice) {
        self.style = style
        self.accentChoice = accent
        self.theme = ThemeProvider.buildTheme(style: style, accent: accent)
    }
    
    private static func buildTheme(style: ThemeStyle, accent: AccentColorChoice) -> Theme {
        let accentColor: Color
        switch accent {
        case .coral: accentColor = .primaryCoral
        case .gold: accentColor = .warmGold
        case .ocean: accentColor = .deepOcean
        case .fitness: accentColor = .fitnessGreen
        case .business: accentColor = .businessBlue
        case .mindset: accentColor = .mindsetLavender
        case .creative: accentColor = .creativePink
        }
        
        switch style {
        case .energetic:
            return Theme(
                backgroundPrimary: .backgroundPrimary,
                backgroundSecondary: .backgroundSecondary,
                textPrimary: .textPrimary,
                textSecondary: .textSecondary,
                accent: accentColor,
                emphasis: .primaryCoral
            )
        case .professional:
            return Theme(
                backgroundPrimary: .backgroundPrimary,
                backgroundSecondary: .backgroundSecondary,
                textPrimary: .textPrimary,
                textSecondary: .textSecondary,
                accent: accentColor,
                emphasis: .deepOcean
            )
        case .mindful:
            return Theme(
                backgroundPrimary: .backgroundPrimary,
                backgroundSecondary: .backgroundSecondary,
                textPrimary: .textPrimary,
                textSecondary: .textSecondary,
                accent: accentColor,
                emphasis: .mindsetRose
            )
        case .creative:
            return Theme(
                backgroundPrimary: .backgroundPrimary,
                backgroundSecondary: .backgroundSecondary,
                textPrimary: .textPrimary,
                textSecondary: .textSecondary,
                accent: accentColor,
                emphasis: .creativePink
            )
        case .balanced:
            return Theme(
                backgroundPrimary: .backgroundPrimary,
                backgroundSecondary: .backgroundSecondary,
                textPrimary: .textPrimary,
                textSecondary: .textSecondary,
                accent: accentColor,
                emphasis: .warmGold
            )
        case .calm:
            return Theme(
                backgroundPrimary: Color(red: 248/255, green: 250/255, blue: 252/255),
                backgroundSecondary: .backgroundSecondary,
                textPrimary: .textPrimary,
                textSecondary: .textSecondary,
                accent: accentColor.opacity(0.9),
                emphasis: Color(red: 94/255, green: 234/255, blue: 212/255)
            )
        case .minimal:
            return Theme(
                backgroundPrimary: .white,
                backgroundSecondary: .backgroundPrimary,
                textPrimary: .textPrimary,
                textSecondary: .textSecondary,
                accent: accentColor,
                emphasis: .borderMedium
            )
        case .playful:
            return Theme(
                backgroundPrimary: Color(red: 254/255, green: 252/255, blue: 232/255),
                backgroundSecondary: .backgroundSecondary,
                textPrimary: .textPrimary,
                textSecondary: .textSecondary,
                accent: accentColor,
                emphasis: .motivationalOrangeLight
            )
        }
    }
}
