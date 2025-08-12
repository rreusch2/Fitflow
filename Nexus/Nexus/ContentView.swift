//
//  ContentView.swift
//  Flowmate
//
//  Created on 2025-01-13
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var authService: AuthenticationService
    @StateObject private var themeProvider = ThemeProvider()
    @State private var isLoading = true
    
    var body: some View {
        Group {
            if isLoading {
                SplashView()
            } else if authService.isAuthenticated {
                if authService.currentUser?.hasCompletedOnboarding == true {
                    MainTabView()
                        .environmentObject(themeProvider)
                        .onAppear { themeProvider.applyTheme(for: authService.currentUser) }
                } else {
                    OnboardingContainerView()
                        .environmentObject(themeProvider)
                }
            } else {
                AuthenticationView()
                    .environmentObject(themeProvider)
            }
        }
        .onAppear {
            // Simulate loading time for splash screen
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                withAnimation(.easeInOut(duration: 0.5)) {
                    isLoading = false
                }
            }
        }
        .animation(.easeInOut(duration: 0.3), value: authService.isAuthenticated)
    }
}

struct SplashView: View {
    @State private var scale: CGFloat = 0.8
    @State private var opacity: Double = 0.0
    @State private var gradientOffset: CGFloat = -200
    
    var body: some View {
        ZStack {
            // Beautiful gradient background
            Color.energeticGradient
                .ignoresSafeArea()
            
            // Animated gradient overlay
            LinearGradient(
                colors: [Color.clear, Color.white.opacity(0.1), Color.clear],
                startPoint: .leading,
                endPoint: .trailing
            )
            .offset(x: gradientOffset)
            .ignoresSafeArea()
            
            VStack(spacing: 24) {
                // Modern icon with glow effect
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.2))
                        .frame(width: 120, height: 120)
                        .blur(radius: 20)
                    
                    Image(systemName: "brain.head.profile")
                        .font(.system(size: 60, weight: .light))
                        .foregroundColor(.white)
                        .shadow(color: .white.opacity(0.3), radius: 10)
                }
                .scaleEffect(scale)
                .opacity(opacity)
                
                VStack(spacing: 8) {
                    Text("NexusGPT")
                        .font(.system(size: 42, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .shadow(color: .black.opacity(0.2), radius: 2, x: 0, y: 2)
                    
                    Text("Your AI Motivational Assistant")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.white.opacity(0.9))
                        .multilineTextAlignment(.center)
                }
                .opacity(opacity)
                
                // Subtle loading indicator
                HStack(spacing: 8) {
                    ForEach(0..<3) { index in
                        Circle()
                            .fill(Color.white.opacity(0.7))
                            .frame(width: 8, height: 8)
                            .scaleEffect(scale)
                            .animation(
                                Animation.easeInOut(duration: 0.6)
                                    .repeatForever(autoreverses: true)
                                    .delay(Double(index) * 0.2),
                                value: scale
                            )
                    }
                }
                .opacity(opacity)
                .padding(.top, 20)
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 1.2)) {
                scale = 1.0
                opacity = 1.0
            }
            
            withAnimation(.linear(duration: 3.0).repeatForever(autoreverses: false)) {
                gradientOffset = 400
            }
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(AuthenticationService())
        .environmentObject(DatabaseService.shared)
}
