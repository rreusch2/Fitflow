//
//  FloatingCoach.swift
//  Flowmate
//
//  Created on 2025-01-13
//

import SwiftUI
import UIKit

// MARK: - Floating Coach Manager

@MainActor
class FloatingCoachManager: ObservableObject {
    @Published var isExpanded = false
    @Published var isVisible = true
    @Published var dragOffset = CGSize.zero
    
    static let shared = FloatingCoachManager()
    
    private init() {}
    
    func showCoach() {
        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
            isExpanded = true
        }
    }
    
    func hideCoach() {
        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
            isExpanded = false
        }
    }
    
    func toggleCoach() {
        if isExpanded {
            hideCoach()
        } else {
            showCoach()
        }
    }
}

// MARK: - Floating Coach View

struct FloatingCoach: View {
    @StateObject private var coachManager = FloatingCoachManager.shared
    @StateObject private var agentManager = AIAgentManager.shared
    @EnvironmentObject var themeProvider: ThemeProvider
    @EnvironmentObject var authService: AuthenticationService
    
    @State private var pulseScale: CGFloat = 1.0
    @State private var rotationAngle: Double = 0
    @State private var isAnimating = false
    @State private var chatMessages: [CoachMessage] = []
    @State private var currentMessage = ""
    @State private var isTyping = false
    
    var body: some View {
        ZStack {
            // Backdrop overlay when expanded
            if coachManager.isExpanded {
                Color.black.opacity(0.3)
                    .ignoresSafeArea()
                    .onTapGesture {
                        coachManager.hideCoach()
                    }
                    .transition(.opacity)
            }
            
            VStack {
                Spacer()
                
                HStack {
                    Spacer()
                    
                    // Main floating coach container
                    ZStack(alignment: .bottomTrailing) {
                        // Expanded chat interface
                        if coachManager.isExpanded {
                            FloatingChatInterface(
                                messages: $chatMessages,
                                currentMessage: $currentMessage,
                                isTyping: $isTyping,
                                onSendMessage: sendMessage,
                                onClose: {
                                    coachManager.hideCoach()
                                }
                            )
                            .transition(.asymmetric(
                                insertion: .scale(scale: 0.8).combined(with: .opacity),
                                removal: .scale(scale: 0.8).combined(with: .opacity)
                            ))
                        }
                        
                        // Floating coach button
                        FloatingCoachButton(
                            isExpanded: coachManager.isExpanded,
                            pulseScale: pulseScale,
                            rotationAngle: rotationAngle,
                            onTap: {
                                impactFeedback()
                                coachManager.toggleCoach()
                            }
                        )
                    }
                }
                .padding(.trailing, 20)
                .padding(.bottom, 100) // Above tab bar
            }
        }
        .onAppear {
            startIdleAnimation()
        }
        .animation(.spring(response: 0.6, dampingFraction: 0.8), value: coachManager.isExpanded)
    }
    
    private func sendMessage(_ message: String) {
        guard !message.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        
        // Add user message
        chatMessages.append(CoachMessage(
            id: UUID(),
            content: message,
            isFromUser: true,
            timestamp: Date()
        ))
        
        currentMessage = ""
        isTyping = true
        
        // Get AI response
        Task {
            do {
                let coach = agentManager.getCoachAgent()
                let response = try await coach.processUserQuery(message, for: authService.currentUser!)
                
                await MainActor.run {
                    isTyping = false
                    chatMessages.append(CoachMessage(
                        id: UUID(),
                        content: response,
                        isFromUser: false,
                        timestamp: Date()
                    ))
                }
            } catch {
                await MainActor.run {
                    isTyping = false
                    chatMessages.append(CoachMessage(
                        id: UUID(),
                        content: "I'm having trouble connecting right now. Please try again!",
                        isFromUser: false,
                        timestamp: Date()
                    ))
                }
            }
        }
    }
    
    private func startIdleAnimation() {
        // Gentle pulse animation when idle
        withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
            pulseScale = 1.05
        }
        
        // Subtle rotation for AI feel
        withAnimation(.linear(duration: 20.0).repeatForever(autoreverses: false)) {
            rotationAngle = 360
        }
    }
    
    private func impactFeedback() {
        let impact = UIImpactFeedbackGenerator(style: .medium)
        impact.impactOccurred()
    }
}

// MARK: - Floating Coach Button

struct FloatingCoachButton: View {
    let isExpanded: Bool
    let pulseScale: CGFloat
    let rotationAngle: Double
    let onTap: () -> Void
    
    @EnvironmentObject var themeProvider: ThemeProvider
    @State private var isPressed = false
    
    var body: some View {
        Button(action: onTap) {
            ZStack {
                // Outer glow ring
                Circle()
                    .fill(
                        RadialGradient(
                            gradient: Gradient(colors: [
                                themeProvider.theme.accent.opacity(0.3),
                                themeProvider.theme.accent.opacity(0.1),
                                Color.clear
                            ]),
                            center: .center,
                            startRadius: 25,
                            endRadius: 45
                        )
                    )
                    .frame(width: 90, height: 90)
                    .scaleEffect(pulseScale)
                
                // Main button background
                Circle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                themeProvider.theme.accent,
                                themeProvider.theme.accent.opacity(0.8)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 60, height: 60)
                    .shadow(
                        color: themeProvider.theme.accent.opacity(0.4),
                        radius: 10,
                        x: 0,
                        y: 5
                    )
                    .scaleEffect(isPressed ? 0.95 : 1.0)
                
                // Coach icon with rotation
                Image(systemName: isExpanded ? "xmark" : "brain.head.profile")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundColor(.white)
                    .rotationEffect(.degrees(isExpanded ? 0 : rotationAngle))
                    .scaleEffect(isExpanded ? 1.1 : 1.0)
                
                // Activity indicator ring
                if !isExpanded {
                    Circle()
                        .trim(from: 0, to: 0.3)
                        .stroke(
                            Color.white.opacity(0.6),
                            style: StrokeStyle(lineWidth: 2, lineCap: .round)
                        )
                        .frame(width: 50, height: 50)
                        .rotationEffect(.degrees(rotationAngle * 2))
                }
            }
        }
        .buttonStyle(FloatingButtonStyle(isPressed: $isPressed))
    }
}

// MARK: - Floating Chat Interface

struct FloatingChatInterface: View {
    @Binding var messages: [CoachMessage]
    @Binding var currentMessage: String
    @Binding var isTyping: Bool
    
    let onSendMessage: (String) -> Void
    let onClose: () -> Void
    
    @EnvironmentObject var themeProvider: ThemeProvider
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Flowmate Coach")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(themeProvider.theme.textPrimary)
                    
                    Text("Your AI Life Coach")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(themeProvider.theme.textSecondary)
                }
                
                Spacer()
                
                Button(action: onClose) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(themeProvider.theme.textSecondary)
                }
            }
            .padding()
            .background(
                themeProvider.theme.backgroundSecondary
                    .overlay(
                        Rectangle()
                            .fill(themeProvider.theme.accent.opacity(0.1))
                            .frame(height: 1),
                        alignment: .bottom
                    )
            )
            
            // Messages
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 12) {
                        if messages.isEmpty {
                            CoachWelcomeMessage()
                                .padding()
                        } else {
                            ForEach(messages) { message in
                                CoachMessageBubble(message: message)
                                    .id(message.id)
                            }
                        }
                        
                        if isTyping {
                            CoachTypingIndicator()
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 8)
                }
                .onChange(of: messages.count) { _ in
                    if let lastMessage = messages.last {
                        withAnimation(.easeOut(duration: 0.3)) {
                            proxy.scrollTo(lastMessage.id, anchor: .bottom)
                        }
                    }
                }
            }
            
            // Input
            CoachMessageInput(
                currentMessage: $currentMessage,
                onSend: onSendMessage
            )
        }
        .frame(width: 320, height: 450)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(themeProvider.theme.backgroundPrimary)
                .shadow(
                    color: Color.black.opacity(0.2),
                    radius: 20,
                    x: 0,
                    y: 10
                )
        )
        .offset(x: -80, y: -20) // Position relative to button
    }
    

}

// MARK: - Coach Message Components

struct CoachMessage: Identifiable, Equatable {
    let id: UUID
    let content: String
    let isFromUser: Bool
    let timestamp: Date
}

struct CoachMessageBubble: View {
    let message: CoachMessage
    @EnvironmentObject var themeProvider: ThemeProvider
    
    var body: some View {
        HStack {
            if message.isFromUser {
                Spacer()
                
                Text(message.content)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 18)
                            .fill(themeProvider.theme.accent)
                    )
                    .foregroundColor(.white)
                    .font(.system(size: 15))
            } else {
                Image(systemName: "brain.head.profile")
                    .font(.system(size: 16))
                    .foregroundColor(themeProvider.theme.accent)
                    .frame(width: 24, height: 24)
                
                Text(message.content)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 18)
                            .fill(themeProvider.theme.backgroundSecondary)
                    )
                    .foregroundColor(themeProvider.theme.textPrimary)
                    .font(.system(size: 15))
                
                Spacer()
            }
        }
    }
}

struct CoachWelcomeMessage: View {
    @EnvironmentObject var themeProvider: ThemeProvider
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "brain.head.profile")
                .font(.system(size: 40))
                .foregroundColor(themeProvider.theme.accent)
            
            VStack(spacing: 8) {
                Text("Welcome to Flowmate Coach!")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(themeProvider.theme.textPrimary)
                
                Text("I'm here to help you achieve your goals and transform your life. Ask me anything!")
                    .font(.system(size: 14))
                    .foregroundColor(themeProvider.theme.textSecondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding()
    }
}

struct CoachTypingIndicator: View {
    @EnvironmentObject var themeProvider: ThemeProvider
    @State private var animationOffset: CGFloat = 0
    
    var body: some View {
        HStack {
            Image(systemName: "brain.head.profile")
                .font(.system(size: 16))
                .foregroundColor(themeProvider.theme.accent)
                .frame(width: 24, height: 24)
            
            HStack(spacing: 4) {
                ForEach(0..<3, id: \.self) { index in
                    Circle()
                        .fill(themeProvider.theme.textSecondary)
                        .frame(width: 6, height: 6)
                        .offset(y: animationOffset)
                        .animation(
                            Animation.easeInOut(duration: 0.6)
                                .repeatForever()
                                .delay(Double(index) * 0.2),
                            value: animationOffset
                        )
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 18)
                    .fill(themeProvider.theme.backgroundSecondary)
            )
            
            Spacer()
        }
        .onAppear {
            animationOffset = -3
        }
    }
}

struct CoachMessageInput: View {
    @Binding var currentMessage: String
    let onSend: (String) -> Void
    
    @EnvironmentObject var themeProvider: ThemeProvider
    @FocusState private var isTextFieldFocused: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            TextField("Ask your coach anything...", text: $currentMessage, axis: .vertical)
                .textFieldStyle(PlainTextFieldStyle())
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(themeProvider.theme.backgroundSecondary)
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(themeProvider.theme.accent.opacity(0.3), lineWidth: 1)
                        )
                )
                .focused($isTextFieldFocused)
                .font(.system(size: 15))
                .onSubmit {
                    sendMessage()
                }
            
            Button(action: sendMessage) {
                Image(systemName: "paperplane.fill")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(width: 36, height: 36)
                    .background(
                        Circle()
                            .fill(themeProvider.theme.accent)
                    )
            }
            .disabled(currentMessage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            .opacity(currentMessage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0.6 : 1.0)
        }
        .padding()
        .background(themeProvider.theme.backgroundPrimary)
    }
    
    private func sendMessage() {
        let message = currentMessage.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !message.isEmpty else { return }
        
        onSend(message)
        isTextFieldFocused = false
    }
}

// MARK: - Custom Button Style

struct FloatingButtonStyle: ButtonStyle {
    @Binding var isPressed: Bool
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .onChange(of: configuration.isPressed) { pressed in
                withAnimation(.easeInOut(duration: 0.1)) {
                    isPressed = pressed
                }
            }
    }
}
