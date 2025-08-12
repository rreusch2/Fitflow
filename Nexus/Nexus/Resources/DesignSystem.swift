//
//  DesignSystem.swift
//  Fitflow
//
//  Created on 2025-01-13
//

import SwiftUI

// MARK: - Revolutionary Color System
extension Color {
    // === VIBRANT PRIMARY PALETTE ===
    // Energetic Coral - Main brand color
    static let primaryCoral = Color(red: 255/255, green: 107/255, blue: 107/255) // #FF6B6B
    static let primaryCoralDark = Color(red: 238/255, green: 82/255, blue: 83/255) // #EE5253
    static let primaryCoralLight = Color(red: 255/255, green: 154/255, blue: 158/255) // #FF9A9E
    
    // Warm Gold - Success & Achievement
    static let warmGold = Color(red: 255/255, green: 183/255, blue: 77/255) // #FFB74D
    static let warmGoldDark = Color(red: 255/255, green: 152/255, blue: 0/255) // #FF9800
    static let warmGoldLight = Color(red: 255/255, green: 204/255, blue: 128/255) // #FFCC80
    
    // Deep Ocean - Professional & Trust
    static let deepOcean = Color(red: 72/255, green: 126/255, blue: 176/255) // #487EB0
    static let deepOceanDark = Color(red: 47/255, green: 54/255, blue: 64/255) // #2F3640
    static let deepOceanLight = Color(red: 116/255, green: 185/255, blue: 255/255) // #74B9FF
    
    // === DYNAMIC THEME COLORS ===
    // Fitness & Energy
    static let fitnessGreen = Color(red: 85/255, green: 239/255, blue: 196/255) // #55EFC4
    static let fitnessOrange = Color(red: 253/255, green: 121/255, blue: 168/255) // #FD79A8
    
    // Business & Productivity  
    static let businessBlue = Color(red: 116/255, green: 185/255, blue: 255/255) // #74B9FF
    static let businessPurple = Color(red: 162/255, green: 155/255, blue: 254/255) // #A29BFE
    
    // Mindset & Wellness
    static let mindsetLavender = Color(red: 253/255, green: 203/255, blue: 110/255) // #FDCB6E
    static let mindsetRose = Color(red: 255/255, green: 118/255, blue: 117/255) // #FF7675
    
    // Creative & Hobbies
    static let creativePink = Color(red: 255/255, green: 107/255, blue: 129/255) // #FF6B81
    static let creativeViolet = Color(red: 196/255, green: 69/255, blue: 105/255) // #C44569
    
    // === STATUS & FEEDBACK COLORS ===
    static let successGreen = Color(red: 85/255, green: 239/255, blue: 196/255) // #55EFC4
    static let warningGold = Color(red: 255/255, green: 183/255, blue: 77/255) // #FFB74D
    static let errorCoral = Color(red: 255/255, green: 107/255, blue: 107/255) // #FF6B6B
    static let errorRed = Color(red: 255/255, green: 107/255, blue: 107/255) // #FF6B6B
    static let infoOcean = Color(red: 116/255, green: 185/255, blue: 255/255) // #74B9FF
    
    // === WARM NEUTRAL PALETTE ===
    static let textPrimary = Color(red: 47/255, green: 54/255, blue: 64/255) // #2F3640 - Warm dark
    static let textSecondary = Color(red: 87/255, green: 96/255, blue: 111/255) // #57606F - Softer
    static let textTertiary = Color(red: 149/255, green: 165/255, blue: 166/255) // #95A5A6 - Warm gray
    
    static let backgroundPrimary = Color(red: 253/255, green: 251/255, blue: 247/255) // #FDFBF7 - Warm white
    static let backgroundSecondary = Color.white
    static let backgroundTertiary = Color(red: 247/255, green: 241/255, blue: 227/255) // #F7F1E3 - Cream
    
    static let borderLight = Color(red: 238/255, green: 238/255, blue: 238/255) // #EEEEEE
    static let borderMedium = Color(red: 220/255, green: 221/255, blue: 225/255) // #DCDDE1
    
    // === WARM DARK MODE ===
    static let darkBackgroundPrimary = Color(red: 47/255, green: 54/255, blue: 64/255) // #2F3640
    static let darkBackgroundSecondary = Color(red: 87/255, green: 96/255, blue: 111/255) // #57606F
    static let darkTextPrimary = Color(red: 253/255, green: 251/255, blue: 247/255) // #FDFBF7
    static let darkTextSecondary = Color(red: 220/255, green: 221/255, blue: 225/255) // #DCDDE1
    
    // === LEGACY SUPPORT (for existing components) ===
    static let primaryGreen = primaryCoral // Map old to new
    static let deepBlue = deepOcean
    static let motivationalOrange = warmGold
    static let motivationalOrangeLight = Color(red: 255/255, green: 204/255, blue: 128/255) // #FFCC80
    
    // === GRADIENT COMBINATIONS ===
    static let energeticGradient = LinearGradient(
        colors: [primaryCoral, warmGold],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let professionalGradient = LinearGradient(
        colors: [deepOcean, businessBlue],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let warmGradient = LinearGradient(
        colors: [mindsetLavender, mindsetRose],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
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

// MARK: - Themed Gradient Background + Glass Card
struct ThemedBackground: View {
    @EnvironmentObject var themeProvider: ThemeProvider
    
    var body: some View {
        Group {
            switch themeProvider.style {
            case .energetic, .playful:
                Color.energeticGradient
            case .professional, .calm, .minimal:
                Color.professionalGradient
            case .mindful, .creative, .balanced:
                Color.warmGradient
            }
        }
        .ignoresSafeArea()
    }
}

struct GlassCard: ViewModifier {
    let cornerRadius: CGFloat
    
    init(cornerRadius: CGFloat = CornerRadius.lg) {
        self.cornerRadius = cornerRadius
    }
    
    func body(content: Content) -> some View {
        content
            .padding(Spacing.lg)
            .background(
                .ultraThinMaterial,
                in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(Color.white.opacity(0.25), lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.25), radius: 20, x: 0, y: 12)
    }
}

extension View {
    func glassCard(cornerRadius: CGFloat = CornerRadius.lg) -> some View {
        modifier(GlassCard(cornerRadius: cornerRadius))
    }
    
    func tipBanner(icon: String, text: String) -> some View {
        self.overlay(alignment: .top) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .foregroundStyle(Color.textSecondary)
                Text(text)
                    .font(.caption)
                    .foregroundColor(.textSecondary)
                Spacer(minLength: 0)
            }
            .padding(.horizontal, Spacing.md)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: CornerRadius.md)
                    .fill(Color.backgroundSecondary.opacity(0.8))
                    .overlay(
                        RoundedRectangle(cornerRadius: CornerRadius.md)
                            .stroke(Color.borderLight, lineWidth: 1)
                    )
            )
            .padding(.horizontal)
            .padding(.top)
        }
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
            .foregroundColor(.textPrimary)
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