//
//  DesignSystem.swift
//  Fitflow
//
//  Created on 2025-01-13
//

import SwiftUI

// MARK: - Colors
extension Color {
    // Primary Colors
    static let primaryGreen = Color(red: 0/255, green: 212/255, blue: 170/255) // #00D4AA
    static let primaryGreenDark = Color(red: 0/255, green: 180/255, blue: 144/255)
    static let primaryGreenLight = Color(red: 51/255, green: 224/255, blue: 191/255)
    
    // Secondary Colors
    static let deepBlue = Color(red: 30/255, green: 58/255, blue: 138/255) // #1E3A8A
    static let deepBlueDark = Color(red: 23/255, green: 44/255, blue: 104/255)
    static let deepBlueLight = Color(red: 59/255, green: 130/255, blue: 246/255)
    
    // Accent Colors
    static let motivationalOrange = Color(red: 245/255, green: 158/255, blue: 11/255) // #F59E0B
    static let motivationalOrangeLight = Color(red: 251/255, green: 191/255, blue: 36/255)
    
    // Status Colors
    static let successGreen = Color(red: 34/255, green: 197/255, blue: 94/255)
    static let warningYellow = Color(red: 234/255, green: 179/255, blue: 8/255)
    static let errorRed = Color(red: 239/255, green: 68/255, blue: 68/255)
    static let infoBlue = Color(red: 59/255, green: 130/255, blue: 246/255)
    
    // Dynamic Colors that adapt to light/dark mode
    static let textPrimary = Color.primary
    static let textSecondary = Color.secondary
    static let textTertiary = Color(UIColor.tertiaryLabel)
    
    static let backgroundPrimary = Color(UIColor.systemBackground)
    static let backgroundSecondary = Color(UIColor.secondarySystemBackground)
    static let backgroundTertiary = Color(UIColor.tertiarySystemBackground)
    
    static let borderLight = Color(UIColor.separator)
    static let borderMedium = Color(UIColor.opaqueSeparator)
    
    // Static Light Mode Colors (for reference/fallback)
    static let lightTextPrimary = Color(red: 17/255, green: 24/255, blue: 39/255) // #111827
    static let lightTextSecondary = Color(red: 75/255, green: 85/255, blue: 99/255) // #4B5563
    static let lightBackgroundPrimary = Color(red: 249/255, green: 250/255, blue: 251/255) // #F9FAFB
    static let lightBackgroundSecondary = Color.white
    
    // Static Dark Mode Colors (for reference/fallback)
    static let darkBackgroundPrimary = Color(red: 17/255, green: 24/255, blue: 39/255)
    static let darkBackgroundSecondary = Color(red: 31/255, green: 41/255, blue: 55/255)
    static let darkTextPrimary = Color.white
    static let darkTextSecondary = Color(red: 209/255, green: 213/255, blue: 219/255)
}

// MARK: - Typography
extension Font {
    // Headlines
    static let largeTitle = Font.custom("SF Pro Display", size: 34, relativeTo: .largeTitle).weight(.bold)
    static let title1 = Font.custom("SF Pro Display", size: 28, relativeTo: .title).weight(.bold)
    static let title2 = Font.custom("SF Pro Display", size: 22, relativeTo: .title2).weight(.bold)
    static let title3 = Font.custom("SF Pro Display", size: 20, relativeTo: .title3).weight(.semibold)
    
    // Body Text
    static let bodyLarge = Font.custom("SF Pro Text", size: 17, relativeTo: .body).weight(.regular)
    static let bodyMedium = Font.custom("SF Pro Text", size: 15, relativeTo: .body).weight(.regular)
    static let bodySmall = Font.custom("SF Pro Text", size: 13, relativeTo: .caption).weight(.regular)
    
    // UI Elements
    static let buttonLarge = Font.custom("SF Pro Text", size: 17, relativeTo: .body).weight(.semibold)
    static let buttonMedium = Font.custom("SF Pro Text", size: 15, relativeTo: .body).weight(.semibold)
    static let buttonSmall = Font.custom("SF Pro Text", size: 13, relativeTo: .caption).weight(.semibold)
    
    // Captions
    static let captionLarge = Font.custom("SF Pro Text", size: 12, relativeTo: .caption).weight(.medium)
    static let captionSmall = Font.custom("SF Pro Text", size: 11, relativeTo: .caption2).weight(.regular)
}

// MARK: - Spacing
struct Spacing {
    static let xs: CGFloat = 4
    static let sm: CGFloat = 8
    static let md: CGFloat = 16
    static let lg: CGFloat = 24
    static let xl: CGFloat = 32
    static let xxl: CGFloat = 48
    static let xxxl: CGFloat = 64
}

// MARK: - Corner Radius
struct CornerRadius {
    static let xs: CGFloat = 4
    static let sm: CGFloat = 8
    static let md: CGFloat = 12
    static let lg: CGFloat = 16
    static let xl: CGFloat = 24
    static let full: CGFloat = 999
}

// MARK: - Shadows
extension View {
    func cardShadow() -> some View {
        self.shadow(
            color: Color.black.opacity(0.1),
            radius: 8,
            x: 0,
            y: 2
        )
    }
    
    func buttonShadow() -> some View {
        self.shadow(
            color: Color.black.opacity(0.15),
            radius: 4,
            x: 0,
            y: 2
        )
    }
    
    func floatingShadow() -> some View {
        self.shadow(
            color: Color.black.opacity(0.2),
            radius: 16,
            x: 0,
            y: 8
        )
    }
}

// MARK: - Custom Button Styles
struct PrimaryButtonStyle: ButtonStyle {
    let isEnabled: Bool
    
    init(isEnabled: Bool = true) {
        self.isEnabled = isEnabled
    }
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.buttonLarge)
            .foregroundColor(.white)
            .padding(.horizontal, Spacing.lg)
            .padding(.vertical, Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: CornerRadius.md)
                    .fill(isEnabled ? Color.primaryGreen : Color.textTertiary)
            )
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
            .buttonShadow()
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.buttonLarge)
            .foregroundColor(.primaryGreen)
            .padding(.horizontal, Spacing.lg)
            .padding(.vertical, Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: CornerRadius.md)
                    .stroke(Color.primaryGreen, lineWidth: 2)
                    .background(
                        RoundedRectangle(cornerRadius: CornerRadius.md)
                            .fill(Color.backgroundSecondary)
                    )
            )
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

struct TertiaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.buttonMedium)
            .foregroundColor(.textSecondary)
            .padding(.horizontal, Spacing.md)
            .padding(.vertical, Spacing.sm)
            .background(
                RoundedRectangle(cornerRadius: CornerRadius.sm)
                    .fill(Color.backgroundTertiary)
            )
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

// MARK: - Custom Card Style
struct CardStyle: ViewModifier {
    let padding: CGFloat
    
    init(padding: CGFloat = Spacing.md) {
        self.padding = padding
    }
    
    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(
                RoundedRectangle(cornerRadius: CornerRadius.lg)
                    .fill(Color.backgroundSecondary)
            )
            .cardShadow()
    }
}

extension View {
    func cardStyle(padding: CGFloat = Spacing.md) -> some View {
        self.modifier(CardStyle(padding: padding))
    }
}

// MARK: - Progress Ring
struct ProgressRing: View {
    let progress: Double
    let lineWidth: CGFloat
    let size: CGFloat
    let color: Color
    
    init(progress: Double, lineWidth: CGFloat = 8, size: CGFloat = 60, color: Color = .primaryGreen) {
        self.progress = progress
        self.lineWidth = lineWidth
        self.size = size
        self.color = color
    }
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.borderLight, lineWidth: lineWidth)
            
            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    color,
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 1.0), value: progress)
        }
        .frame(width: size, height: size)
    }
}

// MARK: - Loading States
struct LoadingView: View {
    @State private var isAnimating = false
    
    var body: some View {
        Circle()
            .trim(from: 0, to: 0.8)
            .stroke(Color.primaryGreen, lineWidth: 4)
            .frame(width: 40, height: 40)
            .rotationEffect(.degrees(isAnimating ? 360 : 0))
            .animation(.linear(duration: 1).repeatForever(autoreverses: false), value: isAnimating)
            .onAppear {
                isAnimating = true
            }
    }
}

struct ShimmerView: View {
    @State private var phase: CGFloat = 0
    
    var body: some View {
        LinearGradient(
            colors: [
                Color.backgroundTertiary,
                Color.backgroundTertiary.opacity(0.6),
                Color.backgroundTertiary
            ],
            startPoint: .leading,
            endPoint: .trailing
        )
        .mask(
            Rectangle()
                .offset(x: phase)
        )
        .onAppear {
            withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                phase = 300
            }
        }
    }
}

// MARK: - Input Field Style
struct InputFieldStyle: ViewModifier {
    let isError: Bool
    
    init(isError: Bool = false) {
        self.isError = isError
    }
    
    func body(content: Content) -> some View {
        content
            .padding(Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: CornerRadius.md)
                    .stroke(isError ? Color.errorRed : Color.borderLight, lineWidth: 1)
                    .background(
                        RoundedRectangle(cornerRadius: CornerRadius.md)
                            .fill(Color.backgroundSecondary)
                    )
            )
    }
}

extension View {
    func inputFieldStyle(isError: Bool = false) -> some View {
        self.modifier(InputFieldStyle(isError: isError))
    }
}

// MARK: - Haptic Feedback
struct HapticFeedback {
    static func light() {
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
    }
    
    static func medium() {
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
    }
    
    static func heavy() {
        let impactFeedback = UIImpactFeedbackGenerator(style: .heavy)
        impactFeedback.impactOccurred()
    }
    
    static func success() {
        let notificationFeedback = UINotificationFeedbackGenerator()
        notificationFeedback.notificationOccurred(.success)
    }
    
    static func error() {
        let notificationFeedback = UINotificationFeedbackGenerator()
        notificationFeedback.notificationOccurred(.error)
    }
    
    static func warning() {
        let notificationFeedback = UINotificationFeedbackGenerator()
        notificationFeedback.notificationOccurred(.warning)
    }
}

// MARK: - Animation Presets
extension Animation {
    static let bouncy = Animation.spring(response: 0.6, dampingFraction: 0.8)
    static let smooth = Animation.easeInOut(duration: 0.3)
    static let quick = Animation.easeInOut(duration: 0.15)
    static let slow = Animation.easeInOut(duration: 0.8)
}

// MARK: - Custom Transitions
extension AnyTransition {
    static let slideUp = AnyTransition.move(edge: .bottom).combined(with: .opacity)
    static let slideDown = AnyTransition.move(edge: .top).combined(with: .opacity)
    static let scaleAndFade = AnyTransition.scale.combined(with: .opacity)
}