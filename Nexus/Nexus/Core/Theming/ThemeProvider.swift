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
                backgroundPrimary: Color(red: 255/255, green: 251/255, blue: 250/255), // Energetic warm white
                backgroundSecondary: Color(red: 254/255, green: 246/255, blue: 243/255), // Soft coral tint
                textPrimary: Color(red: 68/255, green: 28/255, blue: 35/255), // Deep energetic red
                textSecondary: Color(red: 147/255, green: 51/255, blue: 66/255), // Energetic rose
                accent: accentColor,
                emphasis: .primaryCoral
            )
        case .professional:
            return Theme(
                backgroundPrimary: Color(red: 249/255, green: 250/255, blue: 252/255), // Cool light gray
                backgroundSecondary: Color.white, // Pure white
                textPrimary: Color(red: 31/255, green: 41/255, blue: 55/255), // Professional dark blue
                textSecondary: Color(red: 100/255, green: 116/255, blue: 139/255), // Professional gray
                accent: accentColor,
                emphasis: .deepOcean
            )
        case .mindful:
            return Theme(
                backgroundPrimary: Color(red: 249/255, green: 250/255, blue: 248/255), // Zen warm white
                backgroundSecondary: Color(red: 244/255, green: 246/255, blue: 243/255), // Soft sage tint
                textPrimary: Color(red: 45/255, green: 55/255, blue: 44/255), // Deep forest green
                textSecondary: Color(red: 93/255, green: 108/255, blue: 91/255), // Mindful sage
                accent: accentColor,
                emphasis: .mindsetRose
            )
        case .creative:
            return Theme(
                backgroundPrimary: Color(red: 253/255, green: 249/255, blue: 252/255), // Soft pink-white
                backgroundSecondary: Color(red: 247/255, green: 242/255, blue: 250/255), // Creative lavender
                textPrimary: Color(red: 61/255, green: 39/255, blue: 91/255), // Deep creative purple
                textSecondary: Color(red: 123/255, green: 97/255, blue: 158/255), // Medium purple
                accent: accentColor,
                emphasis: .creativePink
            )
        case .balanced:
            return Theme(
                backgroundPrimary: Color(red: 250/255, green: 248/255, blue: 246/255), // Warm neutral
                backgroundSecondary: Color(red: 245/255, green: 243/255, blue: 240/255), // Balanced beige
                textPrimary: Color(red: 52/255, green: 48/255, blue: 42/255), // Warm dark brown
                textSecondary: Color(red: 107/255, green: 99/255, blue: 92/255), // Warm gray
                accent: accentColor,
                emphasis: .warmGold
            )
        case .calm:
            return Theme(
                backgroundPrimary: Color(red: 247/255, green: 251/255, blue: 254/255), // Soft blue-white
                backgroundSecondary: Color(red: 241/255, green: 248/255, blue: 252/255), // Calm sky blue
                textPrimary: Color(red: 30/255, green: 58/255, blue: 75/255), // Deep calm blue
                textSecondary: Color(red: 71/255, green: 109/255, blue: 130/255), // Soft blue-gray
                accent: accentColor.opacity(0.9),
                emphasis: Color(red: 94/255, green: 234/255, blue: 212/255)
            )
        case .minimal:
            return Theme(
                backgroundPrimary: Color.white, // Pure white
                backgroundSecondary: Color(red: 249/255, green: 249/255, blue: 249/255), // Ultra-light gray
                textPrimary: Color(red: 17/255, green: 17/255, blue: 17/255), // Near black
                textSecondary: Color(red: 115/255, green: 115/255, blue: 115/255), // Clean gray
                accent: accentColor,
                emphasis: Color(red: 200/255, green: 200/255, blue: 200/255) // Clean border
            )
        case .playful:
            return Theme(
                backgroundPrimary: Color(red: 254/255, green: 252/255, blue: 232/255), // Warm cream
                backgroundSecondary: Color(red: 255/255, green: 248/255, blue: 220/255), // Light golden
                textPrimary: Color(red: 133/255, green: 77/255, blue: 14/255), // Warm brown
                textSecondary: Color(red: 180/255, green: 130/255, blue: 70/255), // Golden brown
                accent: accentColor,
                emphasis: .motivationalOrangeLight
            )
        }
    }
}
