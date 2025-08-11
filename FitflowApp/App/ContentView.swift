//
//  ContentView.swift
//  Fitflow
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
    
    var body: some View {
        ZStack {
            Color.primaryGreen
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
                Image(systemName: "figure.run")
                    .font(.system(size: 80, weight: .light))
                    .foregroundColor(.white)
                    .scaleEffect(scale)
                    .opacity(opacity)
                
                Text("Fitflow")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .opacity(opacity)
                
                Text("AI-Powered Fitness Assistant")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.8))
                    .opacity(opacity)
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 1.0)) {
                scale = 1.0
                opacity = 1.0
            }
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(AuthenticationService())
        .environmentObject(DatabaseService())
}