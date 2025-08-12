//
//  AuthenticationView.swift
//  NexusGPT
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
    
    var body: some View {
        NavigationStack {
            ZStack {
                ThemedBackground()
                    .environmentObject(themeProvider)
                
                ScrollView {
                    VStack(spacing: 24) {
                        VStack(spacing: 8) {
                            Image(systemName: "brain.head.profile")
                                .font(.system(size: 64, weight: .light))
                                .foregroundColor(.white)
                                .shadow(color: .white.opacity(0.35), radius: 8)
                            Text("NexusGPT")
                                .font(.system(size: 36, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                        }
                        
                        VStack(spacing: 16) {
                            if isSignUp {
                                TextField("Full Name", text: $fullName)
                                    .textContentType(.name)
                                    .autocapitalization(.words)
                                    .foregroundColor(.textPrimary)
                                    .inputFieldStyle(isError: false)
                            }
                            TextField("Email", text: $email)
                                .textContentType(.emailAddress)
                                .keyboardType(.emailAddress)
                                .autocapitalization(.none)
                                .textInputAutocapitalization(.never)
                                .foregroundColor(.textPrimary)
                                .inputFieldStyle(isError: false)
                            SecureField("Password", text: $password)
                                .textContentType(.password)
                                .textInputAutocapitalization(.never)
                                .foregroundColor(.textPrimary)
                                .inputFieldStyle(isError: false)
                        }
                        .glassCard(cornerRadius: CornerRadius.xl)
                        .padding(.horizontal)
                        
                        if !formErrors.isEmpty {
                            VStack(alignment: .leading, spacing: 6) {
                                ForEach(formErrors, id: \.self) { err in
                                    Text("• \(err)")
                                        .font(.caption)
                                        .foregroundColor(.errorRed)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                }
                            }
                            .glassCard()
                            .padding(.horizontal)
                        }
                        
                        VStack(spacing: 12) {
                            Button {
                                Task { await submit() }
                            } label: {
                                Text(isSignUp ? "Create Account" : "Sign In")
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(PrimaryButtonStyle(isEnabled: !authService.isLoading))
                            
                            Button {
                                withAnimation(.smooth) { isSignUp.toggle() }
                            } label: {
                                Text(isSignUp ? "Have an account? Sign In" : "New here? Create an account")
                            }
                            .buttonStyle(TertiaryButtonStyle())
                            
                            if let error = authService.errorMessage, !error.isEmpty {
                                Text(error)
                                    .foregroundColor(.errorRed)
                                    .font(.caption)
                            }
                            
                            Button {
                                Task { await authService.signInWithApple() }
                            } label: {
                                HStack {
                                    Image(systemName: "applelogo")
                                    Text("Sign in with Apple")
                                }
                                .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(SecondaryButtonStyle())
                        }
                        .glassCard()
                        .padding(.horizontal)
                        .padding(.bottom)
                    }
                    .padding(.top, 80)
                }
            }
            .navigationTitle(isSignUp ? "Create Account" : "Welcome Back")
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarBackground(Color.clear, for: .navigationBar)
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


