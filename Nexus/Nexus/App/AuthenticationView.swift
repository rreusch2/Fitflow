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
            VStack(spacing: 20) {
                Spacer()
                Image(systemName: "figure.run")
                    .font(.system(size: 64))
                    .foregroundColor(themeProvider.theme.accent)
                Text("NexusGPT")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                VStack(spacing: 12) {
                    if isSignUp {
                        TextField("Full Name", text: $fullName)
                            .textContentType(.name)
                            .autocapitalization(.words)
                            .inputFieldStyle(isError: false)
                    }
                    TextField("Email", text: $email)
                        .textContentType(.emailAddress)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                        .inputFieldStyle(isError: false)
                    SecureField("Password", text: $password)
                        .textContentType(.password)
                        .inputFieldStyle(isError: false)
                }
                .padding(.horizontal)
                
                if !formErrors.isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
                        ForEach(formErrors, id: \.self) { err in
                            Text("• \(err)")
                                .font(.caption)
                                .foregroundColor(.errorRed)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                    .padding(.horizontal)
                }
                
                Button {
                    Task { await submit() }
                } label: {
                    Text(isSignUp ? "Create Account" : "Sign In")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(PrimaryButtonStyle(isEnabled: !authService.isLoading))
                .padding(.horizontal)
                
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
                        .padding(.horizontal)
                }
                
                Spacer()
                
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
                .padding([.horizontal, .bottom])
            }
            .background(themeProvider.theme.backgroundPrimary.ignoresSafeArea())
            .navigationTitle(isSignUp ? "Create Account" : "Welcome Back")
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


