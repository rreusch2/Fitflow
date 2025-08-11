//
//  NexusApp.swift
//  NexusGPT
//
//  Created on 2025-01-13
//

import SwiftUI

@main
struct NexusApp: App {
    @StateObject private var authService = AuthenticationService()
    @StateObject private var databaseService = DatabaseService()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(authService)
                .environmentObject(databaseService)
                .onAppear {
                    setupServices()
                }
        }
    }
    
    private func setupServices() {
        // Initialize Supabase and other services
        databaseService.initialize()
        authService.checkAuthState()
    }
}
