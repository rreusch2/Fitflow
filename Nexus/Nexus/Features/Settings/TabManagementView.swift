//
//  TabManagementView.swift
//  Flowmate
//
//  Created on 2025-01-13
//

import SwiftUI

struct TabManagementView: View {
    @EnvironmentObject var authService: AuthenticationService
    @EnvironmentObject var themeProvider: ThemeProvider
    
    @State private var availableTabs: [TabType] = []
    @State private var visibleTabs: Set<TabType> = []
    @State private var maxVisibleTabs: Int = 4
    @State private var isLoading = false
    @State private var showingPreview = false
    
    private var userInterests: [UserInterest] {
        authService.currentUser?.preferences?.theme.selectedInterests ?? []
    }
    
    private var currentTabVisibility: TabVisibilityPreferences? {
        authService.currentUser?.preferences?.theme.tabVisibility
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Header Section
                    VStack(spacing: 16) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Tab Management")
                                    .font(.system(size: 28, weight: .bold))
                                    .foregroundColor(themeProvider.theme.gradientTextPrimary)
                                
                                Text("Customize your navigation experience")
                                    .font(.system(size: 16))
                                    .foregroundColor(themeProvider.theme.textSecondary)
                            }
                            
                            Spacer()
                            
                            Button("Preview") {
                                showingPreview = true
                            }
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(themeProvider.theme.accent)
                        }
                        .padding(.horizontal, 20)
                        
                        // Max Tabs Selector
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("Maximum Tabs")
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundColor(themeProvider.theme.textPrimary)
                                
                                Spacer()
                                
                                Text("\(maxVisibleTabs)")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(themeProvider.theme.accent)
                            }
                            
                            HStack(spacing: 12) {
                                ForEach(3...5, id: \.self) { count in
                                    Button {
                                        maxVisibleTabs = count
                                        updateVisibleTabsIfNeeded()
                                    } label: {
                                        Text("\(count)")
                                            .font(.system(size: 14, weight: .medium))
                                            .foregroundColor(maxVisibleTabs == count ? .white : themeProvider.theme.textPrimary)
                                            .frame(width: 40, height: 40)
                                            .background(
                                                Circle()
                                                    .fill(maxVisibleTabs == count ? themeProvider.theme.accent : themeProvider.theme.cardBackground)
                                            )
                                    }
                                }
                                
                                Spacer()
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(themeProvider.theme.cardBackground)
                                .shadow(color: themeProvider.theme.shadowColor, radius: 2, x: 0, y: 1)
                        )
                        .padding(.horizontal, 20)
                    }
                    
                    // Available Tabs Section
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Text("Available Tabs")
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundColor(themeProvider.theme.textPrimary)
                            
                            Spacer()
                            
                            Text("\(visibleTabs.count)/\(maxVisibleTabs)")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(themeProvider.theme.textSecondary)
                        }
                        .padding(.horizontal, 20)
                        
                        LazyVStack(spacing: 12) {
                            // Always visible tabs
                            TabToggleCard(
                                tabType: .flow,
                                isSelected: true,
                                isAlwaysVisible: true,
                                themeProvider: themeProvider
                            ) { _ in }
                            
                            // Dynamic interest tabs
                            ForEach(availableInterestTabs, id: \.self) { tabType in
                                TabToggleCard(
                                    tabType: tabType,
                                    isSelected: visibleTabs.contains(tabType),
                                    isAlwaysVisible: false,
                                    themeProvider: themeProvider
                                ) { isSelected in
                                    if isSelected && visibleTabs.count < maxVisibleTabs {
                                        visibleTabs.insert(tabType)
                                    } else if !isSelected {
                                        visibleTabs.remove(tabType)
                                    }
                                }
                                .disabled(visibleTabs.count >= maxVisibleTabs && !visibleTabs.contains(tabType))
                            }
                            
                            // Always visible tabs
                            TabToggleCard(
                                tabType: .coach,
                                isSelected: true,
                                isAlwaysVisible: true,
                                themeProvider: themeProvider
                            ) { _ in }
                            
                            TabToggleCard(
                                tabType: .profile,
                                isSelected: true,
                                isAlwaysVisible: true,
                                themeProvider: themeProvider
                            ) { _ in }
                        }
                        .padding(.horizontal, 20)
                    }
                    
                    // Save Button
                    Button {
                        saveTabPreferences()
                    } label: {
                        HStack {
                            if isLoading {
                                ProgressView()
                                    .scaleEffect(0.8)
                                    .tint(.white)
                            } else {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 16, weight: .semibold))
                            }
                            
                            Text(isLoading ? "Saving..." : "Save Changes")
                                .font(.system(size: 16, weight: .semibold))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(
                            RoundedRectangle(cornerRadius: 25)
                                .fill(
                                    LinearGradient(
                                        colors: [themeProvider.theme.accent, themeProvider.theme.accent.opacity(0.8)],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                        )
                    }
                    .disabled(isLoading)
                    .padding(.horizontal, 20)
                    .padding(.top, 12)
                }
                .padding(.bottom, 20)
            }
            .background(ThemedBackground().environmentObject(themeProvider))
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Done") {
                        // Navigation back handled by parent
                    }
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(themeProvider.theme.accent)
                }
            }
        }
        .onAppear {
            loadCurrentSettings()
        }
        .sheet(isPresented: $showingPreview) {
            TabPreviewView(visibleTabs: Array(visibleTabs), maxTabs: maxVisibleTabs)
                .environmentObject(themeProvider)
        }
    }
    
    private var availableInterestTabs: [TabType] {
        userInterests.compactMap { interest in
            switch interest {
            case .fitness: return .fitness
            case .business: return .business
            case .mindset: return .mindset
            case .creativity: return .creativity
            case .wealth: return .wealth
            case .relationships: return .relationships
            case .learning: return .learning
            case .spirituality: return .spirituality
            case .adventure: return .adventure
            case .leadership: return .leadership
            case .health: return .health
            case .family: return .family
            }
        }
    }
    
    private func loadCurrentSettings() {
        if let tabVisibility = currentTabVisibility {
            // Load existing preferences
            maxVisibleTabs = tabVisibility.maxVisibleTabs
            visibleTabs = Set(availableInterestTabs.filter { tabType in
                guard let interest = tabType.userInterest else { return false }
                return tabVisibility.visibleTabs.contains(interest)
            })
        } else {
            // Set defaults - show top priority interests
            maxVisibleTabs = 4
            let prioritizedTabs = availableInterestTabs.prefix(maxVisibleTabs - 2) // -2 for Coach and Profile
            visibleTabs = Set(prioritizedTabs)
        }
    }
    
    private func updateVisibleTabsIfNeeded() {
        if visibleTabs.count > maxVisibleTabs - 2 { // -2 for fixed tabs (Coach, Profile)
            let prioritizedTabs = Array(visibleTabs).prefix(maxVisibleTabs - 2)
            visibleTabs = Set(prioritizedTabs)
        }
    }
    
    private func saveTabPreferences() {
        guard let user = authService.currentUser else { return }
        
        isLoading = true
        
        let visibleInterests = visibleTabs.compactMap { $0.userInterest }
        let tabOrder: [TabType] = [.flow] + Array(visibleTabs).sorted { tab1, tab2 in
            // Sort by user interest priority or alphabetically
            return tab1.displayName < tab2.displayName
        } + [.coach, .profile]
        
        let newTabVisibility = TabVisibilityPreferences(
            visibleTabs: visibleInterests,
            tabOrder: tabOrder,
            maxVisibleTabs: maxVisibleTabs
        )
        
        // Update the theme preferences with new tab visibility
        var updatedTheme = user.preferences?.theme ?? ThemePreferences(
            style: .balanced,
            accent: .blue,
            selectedInterests: userInterests,
            tabVisibility: newTabVisibility
        )
        
        // Create new theme with updated tab visibility
        let newTheme = ThemePreferences(
            style: updatedTheme.style,
            accent: updatedTheme.accent,
            selectedInterests: updatedTheme.selectedInterests,
            tabVisibility: newTabVisibility
        )
        
        // Here you would typically save to your backend
        // For now, we'll simulate the save
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            isLoading = false
            // You could show a success message or navigate back
        }
    }
}

// MARK: - Tab Toggle Card

private struct TabToggleCard: View {
    let tabType: TabType
    let isSelected: Bool
    let isAlwaysVisible: Bool
    let themeProvider: ThemeProvider
    let onToggle: (Bool) -> Void
    
    var body: some View {
        HStack(spacing: 16) {
            // Tab Icon
            Image(systemName: tabType.systemImage)
                .font(.system(size: 20, weight: .medium))
                .foregroundColor(isSelected ? themeProvider.theme.accent : themeProvider.theme.textSecondary)
                .frame(width: 40, height: 40)
                .background(
                    Circle()
                        .fill(isSelected ? themeProvider.theme.accent.opacity(0.15) : themeProvider.theme.cardBackground)
                )
            
            VStack(alignment: .leading, spacing: 2) {
                Text(tabType.displayName)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(themeProvider.theme.textPrimary)
                
                if isAlwaysVisible {
                    Text("Always visible")
                        .font(.system(size: 12, weight: .regular))
                        .foregroundColor(themeProvider.theme.textSecondary)
                } else {
                    Text("Optional tab")
                        .font(.system(size: 12, weight: .regular))
                        .foregroundColor(themeProvider.theme.textSecondary)
                }
            }
            
            Spacer()
            
            if isAlwaysVisible {
                Image(systemName: "lock.fill")
                    .font(.system(size: 14))
                    .foregroundColor(themeProvider.theme.textSecondary)
            } else {
                Toggle("", isOn: Binding(
                    get: { isSelected },
                    set: { onToggle($0) }
                ))
                .toggleStyle(SwitchToggleStyle(tint: themeProvider.theme.accent))
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(themeProvider.theme.cardBackground)
                .shadow(color: themeProvider.theme.shadowColor, radius: 1, x: 0, y: 1)
        )
    }
}

// MARK: - Tab Preview View

private struct TabPreviewView: View {
    let visibleTabs: [TabType]
    let maxTabs: Int
    @EnvironmentObject var themeProvider: ThemeProvider
    @Environment(\.dismiss) var dismiss
    
    private var previewTabs: [TabType] {
        [.flow] + visibleTabs.prefix(maxTabs - 2) + [.coach, .profile]
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Text("Tab Bar Preview")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(themeProvider.theme.textPrimary)
                    .padding(.top, 20)
                
                Text("This is how your tab bar will look")
                    .font(.system(size: 16))
                    .foregroundColor(themeProvider.theme.textSecondary)
                
                Spacer()
                
                // Mock Tab Bar Preview
                HStack(spacing: 0) {
                    ForEach(previewTabs, id: \.self) { tab in
                        VStack(spacing: 4) {
                            Image(systemName: tab.systemImage)
                                .font(.system(size: 20))
                                .foregroundColor(themeProvider.theme.accent)
                            
                            Text(tab.displayName)
                                .font(.system(size: 10, weight: .medium))
                                .foregroundColor(themeProvider.theme.textSecondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(themeProvider.theme.cardBackground.opacity(0.3))
                        )
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(themeProvider.theme.cardBackground)
                        .shadow(color: themeProvider.theme.shadowColor, radius: 4, x: 0, y: 2)
                )
                .padding(.horizontal, 20)
                
                Spacer()
                
                Button("Close Preview") {
                    dismiss()
                }
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(themeProvider.theme.accent)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(
                    RoundedRectangle(cornerRadius: 25)
                        .stroke(themeProvider.theme.accent, lineWidth: 2)
                )
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            }
            .background(ThemedBackground().environmentObject(themeProvider))
            .navigationBarHidden(true)
        }
    }
}
