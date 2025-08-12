//
//  AuthenticationView.swift
//  Flowmate
//
//  Created on 2025-01-13
//

import SwiftUI

struct AuthenticationView: View {
    @EnvironmentObject var authService: AuthenticationService
    @EnvironmentObject var themeProvider: ThemeProvider
    
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var fullName: String = ""
    @State private var isSignUp: Bool = false
    @State private var formErrors: [String] = []
    @State private var showingWelcomeAnimation: Bool = true
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Beautiful flowing gradient background
                LinearGradient(
                    colors: [
                        Color.primaryCoral.opacity(0.8),
                        Color.warmGold.opacity(0.6),
                        Color.deepOcean.opacity(0.7)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                // Animated flowing shapes
                GeometryReader { geometry in
                    ForEach(0..<3, id: \.self) { index in
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color.white.opacity(0.1),
                                        Color.white.opacity(0.05)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 200, height: 200)
                            .offset(
                                x: geometry.size.width * 0.8 * sin(Double(index) * 2.0),
                                y: geometry.size.height * 0.3 * cos(Double(index) * 1.5)
                            )
                            .blur(radius: 20)
                    }
                }
                
                ScrollView {
                    VStack(spacing: 32) {
                        // Beautiful header with Flowmate branding
                        VStack(spacing: 16) {
                            // Animated Flowmate logo
                            ZStack {
                                Circle()
                                    .fill(
                                        LinearGradient(
                                            colors: [Color.white.opacity(0.2), Color.white.opacity(0.1)],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .frame(width: 100, height: 100)
                                    .blur(radius: 1)
                                
                                Image(systemName: "brain.head.profile")
                                    .font(.system(size: 48, weight: .ultraLight))
                                    .foregroundStyle(
                                        LinearGradient(
                                            colors: [Color.white, Color.white.opacity(0.8)],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .shadow(color: .white.opacity(0.3), radius: 8)
                                    .scaleEffect(showingWelcomeAnimation ? 1.0 : 0.8)
                                    .animation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true), value: showingWelcomeAnimation)
                            }
                            
                            VStack(spacing: 8) {
                                Text("Flowmate")
                                    .font(.system(size: 42, weight: .bold, design: .rounded))
                                    .foregroundStyle(
                                        LinearGradient(
                                            colors: [Color.white, Color.white.opacity(0.9)],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
                                
                                Text("Your personalized AI motivational companion")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.white.opacity(0.85))
                                    .multilineTextAlignment(.center)
                                    .shadow(color: .black.opacity(0.1), radius: 2)
                            }
                        }
                        .padding(.top, 60)
                        
                        // Modern floating input form
                        VStack(spacing: 20) {
                            if isSignUp {
                                FloatingTextField(
                                    placeholder: "Full Name",
                                    text: $fullName,
                                    icon: "person.circle"
                                )
                                .textContentType(.name)
                                .autocapitalization(.words)
                            }
                            
                            FloatingTextField(
                                placeholder: "Email Address",
                                text: $email,
                                icon: "envelope.circle"
                            )
                            .textContentType(.emailAddress)
                            .keyboardType(.emailAddress)
                            .autocapitalization(.none)
                            .textInputAutocapitalization(.never)
                            
                            FloatingSecureField(
                                placeholder: "Password",
                                text: $password,
                                icon: "lock.circle"
                            )
                            .textContentType(.password)
                            .textInputAutocapitalization(.never)
                        }
                        .padding(.horizontal, 24)
                        
                        // Elegant error display
                        if !formErrors.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                ForEach(formErrors, id: \.self) { error in
                                    HStack(spacing: 8) {
                                        Image(systemName: "exclamationmark.circle.fill")
                                            .foregroundColor(.errorCoral)
                                            .font(.caption)
                                        Text(error)
                                            .font(.caption)
                                            .foregroundColor(.white.opacity(0.9))
                                        Spacer()
                                    }
                                }
                            }
                            .padding(16)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color.black.opacity(0.2))
                                    .blur(radius: 0.5)
                            )
                            .padding(.horizontal, 24)
                        }
                        
                        // Beautiful action buttons
                        VStack(spacing: 16) {
                            // Primary action button
                            Button {
                                Task { await submit() }
                            } label: {
                                HStack(spacing: 12) {
                                    if authService.isLoading {
                                        ProgressView()
                                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                            .scaleEffect(0.8)
                                    } else {
                                        Image(systemName: isSignUp ? "person.badge.plus" : "person.crop.circle.badge.checkmark")
                                            .font(.title3)
                                    }
                                    Text(isSignUp ? "Create Your Flowmate Account" : "Welcome Back to Flowmate")
                                        .font(.system(size: 16, weight: .semibold))
                                }
                                .frame(maxWidth: .infinity)
                                .frame(height: 56)
                                .background(
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(
                                            LinearGradient(
                                                colors: [Color.white, Color.white.opacity(0.9)],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )
                                        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
                                )
                                .foregroundColor(.textPrimary)
                            }
                            .disabled(authService.isLoading)
                            
                            // Toggle sign up/sign in
                            Button {
                                withAnimation(.smooth(duration: 0.4)) { isSignUp.toggle() }
                            } label: {
                                Text(isSignUp ? "Already have an account? Sign In" : "New to Flowmate? Create an account")
                                    .font(.system(size: 15, weight: .medium))
                                    .foregroundColor(.white.opacity(0.8))
                            }
                            .padding(.vertical, 8)
                            
                            // Apple Sign In
                            Button {
                                Task { await authService.signInWithApple() }
                            } label: {
                                HStack(spacing: 12) {
                                    Image(systemName: "applelogo")
                                        .font(.title3)
                                    Text("Continue with Apple")
                                        .font(.system(size: 16, weight: .medium))
                                }
                                .frame(maxWidth: .infinity)
                                .frame(height: 52)
                                .background(
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(Color.black.opacity(0.2))
                                        .blur(radius: 0.5)
                                )
                                .foregroundColor(.white)
                            }
                            
                            // Service error display
                            if let error = authService.errorMessage, !error.isEmpty {
                                HStack(spacing: 8) {
                                    Image(systemName: "exclamationmark.triangle.fill")
                                        .foregroundColor(.errorCoral)
                                    Text(error)
                                        .font(.caption)
                                        .foregroundColor(.white.opacity(0.9))
                                }
                                .padding(12)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.black.opacity(0.2))
                                )
                            }
                        }
                        .padding(.horizontal, 24)
                        .padding(.bottom, 40)
                    }
                }
            }
            .navigationBarHidden(true)
        }
        .onAppear {
            showingWelcomeAnimation = true
        }
    }
    
    private func submit() async {
        if isSignUp {
            formErrors = authService.validateSignUpForm(email: email, password: password, confirmPassword: password, fullName: fullName)
            guard formErrors.isEmpty else { return }
            await authService.signUp(email: email, password: password, fullName: fullName)
        } else {
            formErrors = authService.validateSignInForm(email: email, password: password)
            guard formErrors.isEmpty else { return }
            await authService.signIn(email: email, password: password)
        }
    }
}

#Preview {
    AuthenticationView()
        .environmentObject(AuthenticationService())
        .environmentObject(ThemeProvider())
}


