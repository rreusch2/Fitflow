//
//  ThemeProvider.swift
//  Fitflow
//
//  Created on 2025-01-13
//

import SwiftUI

enum ThemeStyle: String, CaseIterable, Codable {
    case energetic
    case calm
    case minimal
    case playful
}

enum AccentColorChoice: String, CaseIterable, Codable {
    case green
    case blue
    case orange
    case pink
    case purple
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
        self.style = .energetic
        self.accentChoice = .green
        self.theme = ThemeProvider.buildTheme(style: .energetic, accent: .green)
    }
    
    func applyTheme(for user: User?) {
        guard let prefs = user?.preferences else {
            setTheme(style: .energetic, accent: .green)
            return
        }
        // Map communication style → UI vibe. Avoid gendered assumptions; rely on vibe.
        let mappedStyle: ThemeStyle
        switch prefs.motivation.communicationStyle {
        case .energetic: mappedStyle = .energetic
        case .calm: mappedStyle = .calm
        case .supportive: mappedStyle = .minimal
        case .humorous: mappedStyle = .playful
        case .tough: mappedStyle = .minimal
        case .scientific: mappedStyle = .minimal
        }
        // Pick an accent informed by top activity preference if any
        let topActivity = prefs.fitness.preferredActivities.first
        let accent: AccentColorChoice
        switch topActivity {
        case .some(.strength): accent = .orange
        case .some(.cardio): accent = .green
        case .some(.yoga), .some(.pilates), .some(.swimming): accent = .blue
        case .some(.running), .some(.cycling): accent = .purple
        case .some(.dancing), .some(.sports): accent = .pink
        default: accent = .green
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
        case .green: accentColor = .primaryGreen
        case .blue: accentColor = .deepBlueLight
        case .orange: accentColor = .motivationalOrange
        case .pink: accentColor = Color(red: 236/255, green: 72/255, blue: 153/255)
        case .purple: accentColor = Color(red: 139/255, green: 92/255, blue: 246/255)
        }
        
        switch style {
        case .energetic:
            return Theme(
                backgroundPrimary: .backgroundPrimary,
                backgroundSecondary: .backgroundSecondary,
                textPrimary: .textPrimary,
                textSecondary: .textSecondary,
                accent: accentColor,
                emphasis: .deepBlue
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


