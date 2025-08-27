//
//  MemorySavePrompt.swift
//  Flowmate
//
//  Beautiful memory save prompt for AI Coach
//

import SwiftUI

struct MemorySavePrompt: View {
    @Binding var isPresented: Bool
    let suggestedMemory: SuggestedMemory
    let onSave: (UserMemory) -> Void
    
    @State private var title: String = ""
    @State private var content: String = ""
    @State private var selectedCategory: MemoryCategory = .insight
    @State private var selectedEmoji: String = ""
    @State private var tags: String = ""
    @State private var isSaving = false
    @State private var showSuccess = false
    
    init(isPresented: Binding<Bool>, suggestedMemory: SuggestedMemory, onSave: @escaping (UserMemory) -> Void) {
        self._isPresented = isPresented
        self.suggestedMemory = suggestedMemory
        self.onSave = onSave
        self._title = State(initialValue: suggestedMemory.title)
        self._content = State(initialValue: suggestedMemory.content)
        self._selectedCategory = State(initialValue: suggestedMemory.category)
        self._selectedEmoji = State(initialValue: suggestedMemory.category.defaultEmoji)
    }
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .onTapGesture {
                    withAnimation(.spring()) {
                        isPresented = false
                    }
                }
            
            VStack(spacing: 0) {
                // Header with emoji and close button
                headerView
                
                // Memory content
                ScrollView {
                    VStack(spacing: 20) {
                        // Title field
                        titleField
                        
                        // Content field
                        contentField
                        
                        // Category selector
                        categorySelector
                        
                        // Tags field
                        tagsField
                        
                        // Emoji picker
                        emojiPicker
                    }
                    .padding()
                }
                
                // Action buttons
                actionButtons
            }
            .frame(maxWidth: UIScreen.main.bounds.width * 0.9)
            .frame(maxHeight: UIScreen.main.bounds.height * 0.75)
            .background(Color(UIColor.systemBackground))
            .cornerRadius(25)
            .shadow(radius: 30)
            .scaleEffect(showSuccess ? 1.05 : 1.0)
            .overlay(
                Group {
                    if showSuccess {
                        successOverlay
                    }
                }
            )
        }
    }
    
    private var headerView: some View {
        HStack {
            Text(selectedEmoji)
                .font(.system(size: 40))
                .scaleEffect(showSuccess ? 1.3 : 1.0)
                .animation(.spring(response: 0.5, dampingFraction: 0.6), value: showSuccess)
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Save Memory")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("This moment seems worth remembering")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Button(action: {
                withAnimation(.spring()) {
                    isPresented = false
                }
            }) {
                Image(systemName: "xmark.circle.fill")
                    .font(.title2)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
    }
    
    private var titleField: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Title", systemImage: "textformat")
                .font(.caption)
                .foregroundColor(.secondary)
            
            TextField("Give this memory a title", text: $title)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .font(.headline)
        }
    }
    
    private var contentField: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Memory", systemImage: "quote.bubble")
                .font(.caption)
                .foregroundColor(.secondary)
            
            TextEditor(text: $content)
                .frame(minHeight: 100, maxHeight: 150)
                .padding(8)
                .background(Color(UIColor.secondarySystemBackground))
                .cornerRadius(10)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
                )
        }
    }
    
    private var categorySelector: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Category", systemImage: "folder")
                .font(.caption)
                .foregroundColor(.secondary)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(MemoryCategory.allCases, id: \.self) { category in
                        CategoryChip(
                            category: category,
                            isSelected: selectedCategory == category
                        ) {
                            selectedCategory = category
                            selectedEmoji = category.defaultEmoji
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        }
                    }
                }
            }
        }
    }
    
    private var tagsField: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Tags (optional)", systemImage: "tag")
                .font(.caption)
                .foregroundColor(.secondary)
            
            TextField("strength, motivation, breakthrough", text: $tags)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .font(.callout)
        }
    }
    
    private var emojiPicker: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Emoji", systemImage: "face.smiling")
                .font(.caption)
                .foregroundColor(.secondary)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 15) {
                    ForEach(["💪", "🎯", "🚀", "💡", "🔥", "⭐", "🏆", "💎", "🌟", "✨", "🎉", "💯"], id: \.self) { emoji in
                        Text(emoji)
                            .font(.title)
                            .scaleEffect(selectedEmoji == emoji ? 1.2 : 1.0)
                            .onTapGesture {
                                selectedEmoji = emoji
                                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            }
                    }
                }
            }
        }
    }
    
    private var actionButtons: some View {
        HStack(spacing: 15) {
            // Discard button
            Button(action: {
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                withAnimation(.spring()) {
                    isPresented = false
                }
            }) {
                HStack {
                    Image(systemName: "xmark")
                    Text("Discard")
                }
                .font(.headline)
                .foregroundColor(.red)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.red.opacity(0.1))
                .cornerRadius(15)
            }
            
            // Save button
            Button(action: saveMemory) {
                HStack {
                    if isSaving {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(0.8)
                    } else {
                        Image(systemName: "checkmark")
                        Text("Save Memory")
                    }
                }
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(
                    LinearGradient(
                        colors: [Color.blue, Color.purple],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(15)
            }
            .disabled(title.isEmpty || content.isEmpty || isSaving)
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
    }
    
    private var successOverlay: some View {
        VStack(spacing: 20) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 60))
                .foregroundColor(.green)
            
            Text("Memory Saved!")
                .font(.title2)
                .fontWeight(.bold)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(UIColor.systemBackground).opacity(0.95))
        .cornerRadius(25)
        .transition(.scale.combined(with: .opacity))
    }
    
    private func saveMemory() {
        guard !title.isEmpty, !content.isEmpty else { return }
        
        isSaving = true
        UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
        
        // Parse tags
        let parsedTags = tags.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }
        
        // Create memory
        let memory = UserMemory(
            userId: UUID(), // This should be the actual user ID from your auth system
            title: title,
            content: content,
            category: selectedCategory,
            tags: parsedTags,
            context: MemoryContext(
                chatSessionId: suggestedMemory.chatSessionId,
                originalPrompt: suggestedMemory.originalPrompt,
                aiResponse: suggestedMemory.aiResponse
            ),
            emoji: selectedEmoji
        )
        
        // Simulate save with animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            withAnimation(.spring()) {
                showSuccess = true
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                onSave(memory)
                isPresented = false
            }
        }
    }
}

// MARK: - Category Chip
private struct CategoryChip: View {
    let category: MemoryCategory
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Text(category.defaultEmoji)
                Text(category.displayName)
                    .font(.caption)
                    .fontWeight(.medium)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                Group {
                    if isSelected {
                        LinearGradient(
                            colors: category.gradientColors.map { Color(hex: $0) ?? .blue },
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    } else {
                        Color(UIColor.secondarySystemBackground)
                    }
                }
            )
            .foregroundColor(isSelected ? .white : .primary)
            .cornerRadius(20)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(isSelected ? Color.clear : Color.secondary.opacity(0.2), lineWidth: 1)
            )
            .scaleEffect(isSelected ? 1.05 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
        }
    }
}

// MARK: - Suggested Memory
struct SuggestedMemory {
    let title: String
    let content: String
    let category: MemoryCategory
    let chatSessionId: UUID?
    let originalPrompt: String?
    let aiResponse: String?
}

// MARK: - Color Extension
extension Color {
    init?(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            return nil
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
