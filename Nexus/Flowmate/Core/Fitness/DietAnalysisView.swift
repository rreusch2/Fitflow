//
//  DietAnalysisView.swift
//  Flowmate
//
//  Created on 2025-01-15
//

import SwiftUI

struct DietAnalysisView: View {
    @EnvironmentObject var themeProvider: ThemeProvider
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var aiService = NutritionAIService.shared
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 8) {
                        Text("Diet Analysis")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(themeProvider.theme.textPrimary)
                        
                        Text("AI-powered insights into your nutrition")
                            .font(.system(size: 16))
                            .foregroundColor(themeProvider.theme.textSecondary)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    
                    if !aiService.dietAnalysis.isEmpty {
                        // Analysis Content (Markdown-like rendering)
                        VStack(alignment: .leading, spacing: 20) {
                            ForEach(parseAnalysisContent(aiService.dietAnalysis), id: \.id) { section in
                                AnalysisSection(section: section)
                                    .environmentObject(themeProvider)
                            }
                        }
                        .padding(.horizontal, 20)
                        
                        // Action Buttons
                        VStack(spacing: 12) {
                            Button {
                                // Save analysis to notes or memories
                                dismiss()
                            } label: {
                                HStack {
                                    Image(systemName: "bookmark.fill")
                                    Text("Save Analysis")
                                        .font(.system(size: 16, weight: .semibold))
                                }
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(
                                    LinearGradient(
                                        colors: [themeProvider.theme.accent, themeProvider.theme.accent.opacity(0.8)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                            }
                            
                            Button {
                                dismiss()
                            } label: {
                                Text("Close")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(themeProvider.theme.accent)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 14)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(themeProvider.theme.accent, lineWidth: 2)
                                    )
                            }
                        }
                        .padding(.horizontal, 20)
                        
                    } else {
                        // Loading or empty state
                        VStack(spacing: 16) {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle())
                                .scaleEffect(1.5)
                            
                            Text("Analyzing your diet...")
                                .font(.system(size: 18, weight: .medium))
                                .foregroundColor(themeProvider.theme.textSecondary)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .padding(.top, 100)
                    }
                }
                .padding(.bottom, 40)
            }
            .background(ThemedBackground().environmentObject(themeProvider))
            .navigationTitle("Diet Analysis")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(themeProvider.theme.accent)
                }
            }
        }
    }
    
    private func parseAnalysisContent(_ content: String) -> [AnalysisSectionData] {
        let lines = content.components(separatedBy: .newlines)
        var sections: [AnalysisSectionData] = []
        var currentSection: AnalysisSectionData?
        
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            
            if trimmed.hasPrefix("##") {
                // Save current section if exists
                if let section = currentSection {
                    sections.append(section)
                }
                // Start new section
                let title = trimmed.replacingOccurrences(of: "##", with: "").trimmingCharacters(in: .whitespaces)
                currentSection = AnalysisSectionData(title: title, items: [])
                
            } else if trimmed.hasPrefix("#") {
                // Main heading - treat as section
                if let section = currentSection {
                    sections.append(section)
                }
                let title = trimmed.replacingOccurrences(of: "#", with: "").trimmingCharacters(in: .whitespaces)
                currentSection = AnalysisSectionData(title: title, items: [], isMainHeading: true)
                
            } else if trimmed.hasPrefix("- ") || trimmed.hasPrefix("* ") {
                // Bullet point
                let content = String(trimmed.dropFirst(2))
                currentSection?.items.append(.bullet(content))
                
            } else if trimmed.hasPrefix("✅") || trimmed.hasPrefix("⚠️") || trimmed.hasPrefix("💡") {
                // Special item with emoji
                currentSection?.items.append(.highlight(trimmed))
                
            } else if !trimmed.isEmpty {
                // Regular paragraph
                currentSection?.items.append(.paragraph(trimmed))
            }
        }
        
        // Add last section
        if let section = currentSection {
            sections.append(section)
        }
        
        // If no sections were parsed, create a single section with the content
        if sections.isEmpty && !content.isEmpty {
            sections.append(AnalysisSectionData(
                title: "Analysis",
                items: [.paragraph(content)]
            ))
        }
        
        return sections
    }
}

struct AnalysisSectionData: Identifiable {
    let id = UUID()
    let title: String
    var items: [AnalysisItem] = []
    var isMainHeading: Bool = false
    
    enum AnalysisItem {
        case paragraph(String)
        case bullet(String)
        case highlight(String)
    }
}

struct AnalysisSection: View {
    let section: AnalysisSectionData
    @EnvironmentObject var themeProvider: ThemeProvider
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Section Title
            Text(section.title)
                .font(.system(size: section.isMainHeading ? 24 : 20, weight: .bold))
                .foregroundColor(themeProvider.theme.textPrimary)
                .padding(.bottom, 4)
            
            // Section Items
            ForEach(Array(section.items.enumerated()), id: \.offset) { _, item in
                switch item {
                case .paragraph(let text):
                    Text(text)
                        .font(.system(size: 16))
                        .foregroundColor(themeProvider.theme.textPrimary)
                        .lineSpacing(4)
                    
                case .bullet(let text):
                    HStack(alignment: .top, spacing: 8) {
                        Circle()
                            .fill(themeProvider.theme.accent)
                            .frame(width: 6, height: 6)
                            .padding(.top, 8)
                        
                        Text(text)
                            .font(.system(size: 15))
                            .foregroundColor(themeProvider.theme.textPrimary)
                            .lineSpacing(3)
                    }
                    
                case .highlight(let text):
                    HStack {
                        Text(text)
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(themeProvider.theme.textPrimary)
                        
                        Spacer()
                    }
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(getHighlightColor(for: text).opacity(0.1))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(getHighlightColor(for: text).opacity(0.3), lineWidth: 1)
                    )
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(themeProvider.theme.cardBackground)
                .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
        )
    }
    
    private func getHighlightColor(for text: String) -> Color {
        if text.contains("✅") {
            return .green
        } else if text.contains("⚠️") {
            return .orange
        } else if text.contains("💡") {
            return .blue
        } else {
            return themeProvider.theme.accent
        }
    }
}


