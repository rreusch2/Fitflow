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
    case creative       // Artistic, hobbies, self-expression
    case minimal        // Clean, crisp, high contrast
    case playful        // Fun, bold
    case dark          // iOS dark mode aesthetic
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
        self.style = .energetic
        self.accentChoice = .coral
        self.theme = ThemeProvider.buildTheme(style: .energetic, accent: .coral)
    }
    
    func applyTheme(for user: User?) {
        guard let prefs = user?.preferences else {
            setTheme(style: .energetic, accent: .coral)
            return
        }
        
        // Map communication style to theme style
        let themeStyle: ThemeStyle
        switch prefs.motivation.communicationStyle {
        case .energetic: themeStyle = .energetic
        case .calm: themeStyle = .minimal
        case .tough: themeStyle = .professional
        case .supportive: themeStyle = .playful
        case .scientific: themeStyle = .professional
        case .humorous: themeStyle = .creative
        case .dark: themeStyle = .dark
        }
        
        setTheme(style: themeStyle, accent: .coral)
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
                backgroundPrimary: Color(red: 255/255, green: 252/255, blue: 248/255), // Warm pristine white
                backgroundSecondary: Color(red: 255/255, green: 248/255, blue: 240/255), // Soft peach glow
                textPrimary: Color(red: 26/255, green: 32/255, blue: 46/255), // High contrast dark slate
                textSecondary: Color(red: 71/255, green: 85/255, blue: 105/255), // Medium slate
                accent: accentColor,
                emphasis: .primaryCoral
            )
        case .professional:
            return Theme(
                backgroundPrimary: Color(red: 249/255, green: 250/255, blue: 252/255), // Cool pristine white
                backgroundSecondary: Color(red: 244/255, green: 247/255, blue: 251/255), // Light blue-gray
                textPrimary: Color(red: 30/255, green: 41/255, blue: 59/255), // Professional navy
                textSecondary: Color(red: 71/255, green: 85/255, blue: 105/255), // Medium slate
                accent: accentColor,
                emphasis: .businessBlue
            )
        case .creative:
            return Theme(
                backgroundPrimary: Color(red: 255/255, green: 251/255, blue: 254/255), // Ethereal white
                backgroundSecondary: Color(red: 252/255, green: 246/255, blue: 252/255), // Soft lavender mist
                textPrimary: Color(red: 26/255, green: 32/255, blue: 46/255), // High contrast dark
                textSecondary: Color(red: 71/255, green: 85/255, blue: 105/255), // Medium slate
                accent: accentColor,
                emphasis: .creativePink
            )
        case .minimal:
            return Theme(
                backgroundPrimary: Color.white,
                backgroundSecondary: Color(red: 246/255, green: 248/255, blue: 250/255),
                textPrimary: Color(red: 24/255, green: 24/255, blue: 24/255),
                textSecondary: Color(red: 120/255, green: 120/255, blue: 120/255),
                accent: accentColor,
                emphasis: Color(red: 200/255, green: 200/255, blue: 200/255) // Clean border
            )
        case .playful:
            return Theme(
                backgroundPrimary: Color(red: 255/255, green: 253/255, blue: 250/255), // Vibrant white
                backgroundSecondary: Color(red: 255/255, green: 250/255, blue: 245/255), // Warm peach tint
                textPrimary: Color(red: 26/255, green: 32/255, blue: 46/255), // High contrast dark
                textSecondary: Color(red: 71/255, green: 85/255, blue: 105/255), // Medium slate  
                accent: accentColor,
                emphasis: .creativePink
            )
        case .dark:
            return Theme(
                backgroundPrimary: Color(red: 0/255, green: 0/255, blue: 0/255), // Pure black
                backgroundSecondary: Color(red: 28/255, green: 28/255, blue: 30/255), // iOS dark secondary
                textPrimary: Color(red: 255/255, green: 255/255, blue: 255/255), // Pure white
                textSecondary: Color(red: 174/255, green: 174/255, blue: 178/255), // iOS dark secondary text
                accent: accentColor,
                emphasis: Color(red: 44/255, green: 44/255, blue: 46/255) // iOS dark tertiary
            )
        }
    }
}

extension Theme {
    // Background gradient that works with the new optimized ThemedBackground
    var backgroundGradient: some View {
        Color.clear // Will be handled by ThemedBackground for performance
    }
    
    // High-contrast text color that works on all backgrounds
    var readableText: Color {
        Color.readableTextOnLight
    }
    
    // Dynamic text colors that adapt to theme background brightness
    var adaptiveTextPrimary: Color {
        // Use white text for dark theme, high contrast dark for others
        return textPrimary == Color.white ? Color.white : Color(red: 250/255, green: 250/255, blue: 250/255)
    }
    
    var adaptiveTextSecondary: Color {
        // Use light gray for dark theme, white with opacity for gradient backgrounds
        return textPrimary == Color.white ? 
            Color(red: 174/255, green: 174/255, blue: 178/255) : 
            Color.white.opacity(0.9)
    }
    
    // Text color for gradient overlays - always use white with high contrast
    var gradientTextPrimary: Color {
        Color.white
    }
    
    var gradientTextSecondary: Color {
        Color.white.opacity(0.85)
    }
}
