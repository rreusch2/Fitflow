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
    case vibrancy      // Ultra-modern with vibrant gradients
    case prism         // Rainbow gradient effects
    case sunset        // Warm sunset tones
    case ocean         // Cool ocean depths
    case neon          // Cyberpunk neon vibes
}

enum AccentColorChoice: String, CaseIterable, Codable {
    case coral          // Primary brand
    case gold           // Achievement, success
    case ocean          // Trust, professional
    case fitness        // Health, energy
    case business       // Productivity, growth
    case mindset        // Wellness, balance
    case creative       // Art, hobbies
    case vibrancy      // Multi-color gradient
    case prism         // Rainbow spectrum
    case sunset        // Warm gradient
    case neon          // Electric gradient
    case cosmic        // Space-themed gradient
}

struct Theme {
    let backgroundPrimary: Color
    let backgroundSecondary: Color
    let backgroundTertiary: Color
    let textPrimary: Color
    let textSecondary: Color
    let textTertiary: Color
    let accent: Color
    let accentSecondary: Color
    let emphasis: Color
    let cardBackground: Color
    let cardText: Color
    let border: Color
    let shadow: Color
    
    // NEW: Gradient accent support
    let accentGradient: LinearGradient?
    let isGradientAccent: Bool
    
    // Dynamic text colors that adapt to backgrounds
    var adaptiveTextOnCard: Color {
        cardBackground.luminance > 0.5 ? Color(red: 26/255, green: 32/255, blue: 46/255) : Color.white
    }
    
    var adaptiveSecondaryTextOnCard: Color {
        cardBackground.luminance > 0.5 ? Color(red: 71/255, green: 85/255, blue: 105/255) : Color(red: 174/255, green: 174/255, blue: 178/255)
    }
    
    // Helper for accent display (gradient or solid)
    @ViewBuilder
    func accentBackground() -> some View {
        if isGradientAccent, let gradient = accentGradient {
            gradient
        } else {
            accent
        }
    }
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
    
    // MARK: - System-Aware Text Colors
    
    /// Get primary text color that works on native backgrounds (considers both theme and system appearance)
    func textForSystemContext(_ colorScheme: ColorScheme) -> Color {
        switch colorScheme {
        case .light:
            // Light system mode - native backgrounds are white/light
            return Color(red: 26/255, green: 32/255, blue: 46/255) // Dark text
        case .dark:
            // Dark system mode - native backgrounds are black/dark  
            return Color.white // White text
        @unknown default:
            return theme.textPrimary
        }
    }
    
    /// Get secondary text color that works on native backgrounds (considers both theme and system appearance)
    func secondaryTextForSystemContext(_ colorScheme: ColorScheme) -> Color {
        switch colorScheme {
        case .light:
            // Light system mode - native backgrounds are white/light
            return Color(red: 71/255, green: 85/255, blue: 105/255) // Medium gray text
        case .dark:
            // Dark system mode - native backgrounds are black/dark
            return Color(red: 174/255, green: 174/255, blue: 178/255) // Light gray text
        @unknown default:
            return theme.textSecondary
        }
    }
    
    private static func buildTheme(style: ThemeStyle, accent: AccentColorChoice) -> Theme {
        let accentColor: Color
        let accentGradient: LinearGradient?
        let isGradientAccent: Bool
        
        switch accent {
        case .coral: 
            accentColor = .primaryCoral
            accentGradient = nil
            isGradientAccent = false
        case .gold: 
            accentColor = .warmGold
            accentGradient = nil
            isGradientAccent = false
        case .ocean: 
            accentColor = .deepOcean
            accentGradient = nil
            isGradientAccent = false
        case .fitness: 
            accentColor = .fitnessGreen
            accentGradient = nil
            isGradientAccent = false
        case .business: 
            accentColor = .businessBlue
            accentGradient = nil
            isGradientAccent = false
        case .mindset: 
            accentColor = .mindsetLavender
            accentGradient = nil
            isGradientAccent = false
        case .creative: 
            accentColor = .creativePink
            accentGradient = nil
            isGradientAccent = false
        case .vibrancy:
            accentColor = .primaryCoral // Fallback
            accentGradient = Color.vibrancyGradient
            isGradientAccent = true
        case .prism:
            accentColor = .creativePink // Fallback
            accentGradient = Color.prismGradient
            isGradientAccent = true
        case .sunset:
            accentColor = .warmGold // Fallback
            accentGradient = Color.sunsetGradient
            isGradientAccent = true
        case .neon:
            accentColor = .fitnessGreen // Fallback
            accentGradient = LinearGradient(
                colors: [
                    Color(red: 57/255, green: 255/255, blue: 20/255),
                    Color(red: 255/255, green: 0/255, blue: 150/255),
                    Color(red: 0/255, green: 200/255, blue: 255/255)
                ],
                startPoint: .leading,
                endPoint: .trailing
            )
            isGradientAccent = true
        case .cosmic:
            accentColor = .businessBlue // Fallback
            accentGradient = LinearGradient(
                colors: [
                    Color(red: 138/255, green: 43/255, blue: 226/255),
                    Color(red: 30/255, green: 144/255, blue: 255/255),
                    Color(red: 255/255, green: 20/255, blue: 147/255)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            isGradientAccent = true
        }
        
        switch style {
        case .energetic:
            return Theme(
                backgroundPrimary: Color(red: 255/255, green: 252/255, blue: 248/255), // Warm pristine white
                backgroundSecondary: Color(red: 255/255, green: 248/255, blue: 240/255), // Soft peach glow
                backgroundTertiary: Color(red: 252/255, green: 245/255, blue: 235/255), // Warm cream
                textPrimary: Color(red: 26/255, green: 32/255, blue: 46/255), // High contrast dark slate
                textSecondary: Color(red: 71/255, green: 85/255, blue: 105/255), // Medium slate
                textTertiary: Color(red: 120/255, green: 130/255, blue: 140/255), // Light slate
                accent: accentColor,
                accentSecondary: accentColor.opacity(0.8),
                emphasis: .primaryCoral,
                cardBackground: Color.white,
                cardText: Color(red: 26/255, green: 32/255, blue: 46/255),
                border: Color(red: 230/255, green: 235/255, blue: 240/255),
                shadow: Color.black.opacity(0.08),
                accentGradient: accentGradient,
                isGradientAccent: isGradientAccent
            )
        case .professional:
            return Theme(
                backgroundPrimary: Color(UIColor.systemBackground), // Adapts to dark/light mode
                backgroundSecondary: Color(UIColor.secondarySystemBackground), // Adapts to dark/light mode
                backgroundTertiary: Color(UIColor.tertiarySystemBackground), // Adapts to dark/light mode
                textPrimary: Color.primary, // Adapts to dark/light mode
                textSecondary: Color.secondary, // Adapts to dark/light mode
                textTertiary: Color(UIColor.tertiaryLabel), // Adapts to dark/light mode
                accent: accentColor,
                accentSecondary: accentColor.opacity(0.8),
                emphasis: .businessBlue,
                cardBackground: Color(UIColor.secondarySystemBackground), // Adapts to dark/light mode
                cardText: Color.primary, // Adapts to dark/light mode
                border: Color(UIColor.separator), // Adapts to dark/light mode
                shadow: Color.black.opacity(0.06),
                accentGradient: accentGradient,
                isGradientAccent: isGradientAccent
            )
        case .creative:
            return Theme(
                backgroundPrimary: Color(UIColor.systemBackground), // Adapts to dark/light mode
                backgroundSecondary: Color(UIColor.secondarySystemBackground), // Adapts to dark/light mode
                backgroundTertiary: Color(UIColor.tertiarySystemBackground), // Adapts to dark/light mode
                textPrimary: Color.primary, // Adapts to dark/light mode
                textSecondary: Color.secondary, // Adapts to dark/light mode
                textTertiary: Color(UIColor.tertiaryLabel), // Adapts to dark/light mode
                accent: accentColor,
                accentSecondary: accentColor.opacity(0.8),
                emphasis: .creativePink,
                cardBackground: Color(UIColor.secondarySystemBackground), // Adapts to dark/light mode
                cardText: Color.primary, // Adapts to dark/light mode
                border: Color(UIColor.separator), // Adapts to dark/light mode
                shadow: Color.black.opacity(0.08),
                accentGradient: accentGradient,
                isGradientAccent: isGradientAccent
            )
        case .minimal:
            return Theme(
                backgroundPrimary: Color.white,
                backgroundSecondary: Color(red: 246/255, green: 248/255, blue: 250/255),
                backgroundTertiary: Color(red: 240/255, green: 245/255, blue: 250/255),
                textPrimary: Color(red: 24/255, green: 24/255, blue: 24/255),
                textSecondary: Color(red: 120/255, green: 120/255, blue: 120/255),
                textTertiary: Color(red: 160/255, green: 160/255, blue: 160/255),
                accent: accentColor,
                accentSecondary: accentColor.opacity(0.8),
                emphasis: Color(red: 200/255, green: 200/255, blue: 200/255), // Clean border
                cardBackground: Color.white,
                cardText: Color(red: 24/255, green: 24/255, blue: 24/255),
                border: Color(red: 230/255, green: 230/255, blue: 230/255),
                shadow: Color.black.opacity(0.04),
                accentGradient: accentGradient,
                isGradientAccent: isGradientAccent
            )
        case .playful:
            return Theme(
                backgroundPrimary: Color(UIColor.systemBackground), // Adapts to dark/light mode
                backgroundSecondary: Color(UIColor.secondarySystemBackground), // Adapts to dark/light mode
                backgroundTertiary: Color(UIColor.tertiarySystemBackground), // Adapts to dark/light mode
                textPrimary: Color.primary, // Adapts to dark/light mode
                textSecondary: Color.secondary, // Adapts to dark/light mode
                textTertiary: Color(UIColor.tertiaryLabel), // Adapts to dark/light mode
                accent: accentColor,
                accentSecondary: accentColor.opacity(0.8),
                emphasis: .creativePink,
                cardBackground: Color(UIColor.secondarySystemBackground), // Adapts to dark/light mode
                cardText: Color.primary, // Adapts to dark/light mode
                border: Color(UIColor.separator), // Adapts to dark/light mode
                shadow: Color.black.opacity(0.08),
                accentGradient: accentGradient,
                isGradientAccent: isGradientAccent
            )
        case .dark:
            return Theme(
                backgroundPrimary: Color(red: 0/255, green: 0/255, blue: 0/255), // Pure black
                backgroundSecondary: Color(red: 28/255, green: 28/255, blue: 30/255), // iOS dark secondary
                backgroundTertiary: Color(red: 44/255, green: 44/255, blue: 46/255), // iOS dark tertiary
                textPrimary: Color(red: 255/255, green: 255/255, blue: 255/255), // Pure white
                textSecondary: Color(red: 174/255, green: 174/255, blue: 178/255), // iOS dark secondary text
                textTertiary: Color(red: 134/255, green: 134/255, blue: 138/255), // iOS dark tertiary text
                accent: accentColor,
                accentSecondary: accentColor.opacity(0.8),
                emphasis: Color(red: 44/255, green: 44/255, blue: 46/255), // iOS dark tertiary
                cardBackground: Color(red: 28/255, green: 28/255, blue: 30/255),
                cardText: Color(red: 255/255, green: 255/255, blue: 255/255),
                border: Color(red: 58/255, green: 58/255, blue: 60/255),
                shadow: Color.black.opacity(0.3),
                accentGradient: accentGradient,
                isGradientAccent: isGradientAccent
            )
        case .vibrancy:
            return Theme(
                backgroundPrimary: Color(UIColor.systemBackground), // Adapts to dark/light mode
                backgroundSecondary: Color(UIColor.secondarySystemBackground), // Adapts to dark/light mode
                backgroundTertiary: Color(UIColor.tertiarySystemBackground), // Adapts to dark/light mode
                textPrimary: Color.primary, // Adapts to dark/light mode
                textSecondary: Color.secondary, // Adapts to dark/light mode
                textTertiary: Color(UIColor.tertiaryLabel), // Adapts to dark/light mode
                accent: accentColor,
                accentSecondary: accentColor.opacity(0.7),
                emphasis: .primaryCoral,
                cardBackground: Color(UIColor.secondarySystemBackground), // Adapts to dark/light mode
                cardText: Color.primary, // Adapts to dark/light mode
                border: Color(UIColor.separator), // Adapts to dark/light mode
                shadow: Color.black.opacity(0.06),
                accentGradient: accentGradient,
                isGradientAccent: isGradientAccent
            )
        case .prism:
            return Theme(
                backgroundPrimary: Color(UIColor.systemBackground), // Adapts to dark/light mode
                backgroundSecondary: Color(UIColor.secondarySystemBackground), // Adapts to dark/light mode
                backgroundTertiary: Color(UIColor.tertiarySystemBackground), // Adapts to dark/light mode
                textPrimary: Color.primary, // Adapts to dark/light mode
                textSecondary: Color.secondary, // Adapts to dark/light mode
                textTertiary: Color(UIColor.tertiaryLabel), // Adapts to dark/light mode
                accent: accentColor,
                accentSecondary: accentColor.opacity(0.7),
                emphasis: .creativePink,
                cardBackground: Color(UIColor.secondarySystemBackground), // Adapts to dark/light mode
                cardText: Color.primary, // Adapts to dark/light mode
                border: Color(UIColor.separator), // Adapts to dark/light mode
                shadow: Color.black.opacity(0.08),
                accentGradient: accentGradient,
                isGradientAccent: isGradientAccent
            )
        case .sunset:
            return Theme(
                backgroundPrimary: Color(UIColor.systemBackground), // Adapts to dark/light mode
                backgroundSecondary: Color(UIColor.secondarySystemBackground), // Adapts to dark/light mode
                backgroundTertiary: Color(UIColor.tertiarySystemBackground), // Adapts to dark/light mode
                textPrimary: Color.primary, // Adapts to dark/light mode
                textSecondary: Color.secondary, // Adapts to dark/light mode
                textTertiary: Color(UIColor.tertiaryLabel), // Adapts to dark/light mode
                accent: accentColor,
                accentSecondary: accentColor.opacity(0.8),
                emphasis: .warmGold,
                cardBackground: Color(UIColor.secondarySystemBackground), // Adapts to dark/light mode
                cardText: Color.primary, // Adapts to dark/light mode
                border: Color(UIColor.separator), // Adapts to dark/light mode
                shadow: Color.black.opacity(0.10),
                accentGradient: accentGradient,
                isGradientAccent: isGradientAccent
            )
        case .ocean:
            return Theme(
                backgroundPrimary: Color(red: 245/255, green: 250/255, blue: 255/255), // Ocean white
                backgroundSecondary: Color(red: 235/255, green: 245/255, blue: 255/255), // Deep water
                backgroundTertiary: Color(red: 225/255, green: 240/255, blue: 255/255), // Ocean base
                textPrimary: Color(red: 15/255, green: 30/255, blue: 45/255), // Deep ocean
                textSecondary: Color(red: 45/255, green: 70/255, blue: 95/255), // Ocean blue
                textTertiary: Color(red: 85/255, green: 110/255, blue: 135/255), // Light ocean
                accent: accentColor,
                accentSecondary: accentColor.opacity(0.8),
                emphasis: .deepOcean,
                cardBackground: Color.white,
                cardText: Color(red: 15/255, green: 30/255, blue: 45/255),
                border: Color(red: 200/255, green: 220/255, blue: 240/255),
                shadow: Color.black.opacity(0.08),
                accentGradient: accentGradient,
                isGradientAccent: isGradientAccent
            )
        case .neon:
            return Theme(
                backgroundPrimary: Color(red: 8/255, green: 8/255, blue: 12/255), // Cyber black
                backgroundSecondary: Color(red: 15/255, green: 15/255, blue: 20/255), // Neon dark
                backgroundTertiary: Color(red: 25/255, green: 25/255, blue: 32/255), // Electric base
                textPrimary: Color(red: 240/255, green: 255/255, blue: 240/255), // Neon white
                textSecondary: Color(red: 180/255, green: 200/255, blue: 180/255), // Electric green tint
                textTertiary: Color(red: 140/255, green: 160/255, blue: 140/255), // Dim neon
                accent: accentColor,
                accentSecondary: accentColor.opacity(0.8),
                emphasis: Color(red: 57/255, green: 255/255, blue: 20/255), // Neon green
                cardBackground: Color(red: 18/255, green: 18/255, blue: 25/255),
                cardText: Color(red: 240/255, green: 255/255, blue: 240/255),
                border: Color(red: 40/255, green: 40/255, blue: 50/255),
                shadow: Color(red: 57/255, green: 255/255, blue: 20/255).opacity(0.15),
                accentGradient: accentGradient,
                isGradientAccent: isGradientAccent
            )
        }
    }
}

extension Color {
    // Calculate luminance for accessibility and theme adaptation
    var luminance: Double {
        let components = UIColor(self).cgColor.components ?? [0, 0, 0, 1]
        let r = components[0]
        let g = components[1] 
        let b = components[2]
        return 0.299 * r + 0.587 * g + 0.114 * b
    }
    
    // Dynamic text color based on background luminance
    var contrastingTextColor: Color {
        luminance > 0.5 ? Color(red: 26/255, green: 32/255, blue: 46/255) : Color.white
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
    
    // Text color for gradient overlays - use dynamic colors that adapt to system appearance
    var gradientTextPrimary: Color {
        // Use dynamic color that adapts to system dark/light mode
        Color.primary
    }
    
    var gradientTextSecondary: Color {
        // Use dynamic color that adapts to system dark/light mode
        Color.secondary
    }
}
