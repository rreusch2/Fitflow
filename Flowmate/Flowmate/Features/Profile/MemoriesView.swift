//
//  MemoriesView.swift
//  Flowmate
//
//  Beautiful memories display for user profile
//

import SwiftUI

struct MemoriesView: View {
    @State private var memories: [UserMemory] = []
    @State private var filteredMemories: [UserMemory] = []
    @State private var selectedCategory: MemoryCategory? = nil
    @State private var searchText = ""
    @State private var showOnlyFavorites = false
    @State private var isLoading = true
    @State private var selectedMemory: UserMemory? = nil
    @State private var showEditSheet = false
    @State private var showDeleteAlert = false
    @State private var memoryToDelete: UserMemory? = nil
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background gradient
                LinearGradient(
                    colors: [
                        Color(UIColor.systemBackground),
                        Color(UIColor.secondarySystemBackground).opacity(0.3)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                if isLoading {
                    loadingView
                } else if filteredMemories.isEmpty {
                    emptyStateView
                } else {
                    memoriesContent
                }
            }
            .navigationTitle("Memories")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button(action: { showOnlyFavorites.toggle() }) {
                            Label(
                                showOnlyFavorites ? "Show All" : "Show Favorites",
                                systemImage: showOnlyFavorites ? "star.slash" : "star.fill"
                            )
                        }
                        
                        Button(action: exportMemories) {
                            Label("Export Memories", systemImage: "square.and.arrow.up")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
            .searchable(text: $searchText, prompt: "Search memories...")
            .onChange(of: searchText) { filterMemories() }
            .onChange(of: selectedCategory) { filterMemories() }
            .onChange(of: showOnlyFavorites) { filterMemories() }
            .onAppear {
                loadMemories()
            }
            .sheet(isPresented: $showEditSheet) {
                if let memory = selectedMemory {
                    EditMemoryView(memory: memory) { updatedMemory in
                        updateMemory(updatedMemory)
                    }
                }
            }
            .alert("Delete Memory", isPresented: $showDeleteAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Delete", role: .destructive) {
                    if let memory = memoryToDelete {
                        deleteMemory(memory)
                    }
                }
            } message: {
                Text("Are you sure you want to delete this memory? This action cannot be undone.")
            }
        }
    }
    
    private var loadingView: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.5)
            Text("Loading your memories...")
                .font(.headline)
                .foregroundColor(.secondary)
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 25) {
            Image(systemName: "sparkles")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
                .symbolEffect(.pulse)
            
            VStack(spacing: 10) {
                Text("No Memories Yet")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("Your important moments with your AI Coach will appear here")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
        }
        .padding()
    }
    
    private var memoriesContent: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Category filter
                categoryFilter
                
                // Stats card
                if !filteredMemories.isEmpty {
                    statsCard
                }
                
                // Memories grid
                memoriesGrid
            }
            .padding()
        }
    }
    
    private var categoryFilter: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                // All category
                FilterChip(
                    title: "All",
                    icon: "square.grid.2x2",
                    isSelected: selectedCategory == nil,
                    count: memories.count
                ) {
                    selectedCategory = nil
                }
                
                // Category chips
                ForEach(MemoryCategory.allCases, id: \.self) { category in
                    let count = memories.filter { $0.category == category }.count
                    if count > 0 {
                        FilterChip(
                            title: category.displayName,
                            icon: nil,
                            emoji: category.defaultEmoji,
                            isSelected: selectedCategory == category,
                            count: count
                        ) {
                            selectedCategory = category
                        }
                    }
                }
            }
        }
    }
    
    private var statsCard: some View {
        HStack(spacing: 30) {
            StatItem(
                value: "\(filteredMemories.count)",
                label: "Total",
                icon: "brain.head.profile",
                color: .blue
            )
            
            StatItem(
                value: "\(filteredMemories.filter { $0.isFavorite }.count)",
                label: "Favorites",
                icon: "star.fill",
                color: .yellow
            )
            
            StatItem(
                value: mostCommonCategory(),
                label: "Top Category",
                icon: "chart.pie.fill",
                color: .purple
            )
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(15)
    }
    
    private var memoriesGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 15) {
            ForEach(filteredMemories) { memory in
                MemoryCard(memory: memory) {
                    // Toggle favorite
                    toggleFavorite(memory)
                } onEdit: {
                    selectedMemory = memory
                    showEditSheet = true
                } onDelete: {
                    memoryToDelete = memory
                    showDeleteAlert = true
                }
                .transition(.scale.combined(with: .opacity))
            }
        }
    }
    
    // MARK: - Helper Methods
    private func loadMemories() {
        // Simulate loading - replace with actual Supabase call
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            // Sample data for demonstration
            memories = [
                UserMemory(
                    userId: UUID(),
                    title: "First 10K Run!",
                    content: "Today I completed my first 10K run without stopping. My coach's training plan worked perfectly!",
                    category: .personalRecord,
                    tags: ["running", "milestone", "cardio"],
                    emoji: "🏃‍♂️",
                    isFavorite: true
                ),
                UserMemory(
                    userId: UUID(),
                    title: "Mindset Breakthrough",
                    content: "Realized that consistency beats perfection. Small daily actions compound into massive results.",
                    category: .mindsetShift,
                    tags: ["motivation", "wisdom"],
                    emoji: "🧠"
                ),
                UserMemory(
                    userId: UUID(),
                    title: "New PR on Bench Press",
                    content: "Hit 225lbs for the first time! Coach's progressive overload strategy is amazing.",
                    category: .personalRecord,
                    tags: ["strength", "gym"],
                    emoji: "💪",
                    isFavorite: true
                )
            ]
            filteredMemories = memories
            isLoading = false
        }
    }
    
    private func filterMemories() {
        filteredMemories = memories.filter { memory in
            let matchesCategory = selectedCategory == nil || memory.category == selectedCategory
            let matchesFavorite = !showOnlyFavorites || memory.isFavorite
            let matchesSearch = searchText.isEmpty ||
                memory.title.localizedCaseInsensitiveContains(searchText) ||
                memory.content.localizedCaseInsensitiveContains(searchText) ||
                memory.tags.contains { $0.localizedCaseInsensitiveContains(searchText) }
            
            return matchesCategory && matchesFavorite && matchesSearch
        }
    }
    
    private func toggleFavorite(_ memory: UserMemory) {
        if let index = memories.firstIndex(where: { $0.id == memory.id }) {
            memories[index].isFavorite.toggle()
            filterMemories()
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        }
    }
    
    private func updateMemory(_ memory: UserMemory) {
        if let index = memories.firstIndex(where: { $0.id == memory.id }) {
            memories[index] = memory
            filterMemories()
        }
    }
    
    private func deleteMemory(_ memory: UserMemory) {
        withAnimation {
            memories.removeAll { $0.id == memory.id }
            filterMemories()
        }
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }
    
    private func mostCommonCategory() -> String {
        let categories = filteredMemories.map { $0.category }
        let counts = Dictionary(grouping: categories, by: { $0 }).mapValues { $0.count }
        let mostCommon = counts.max(by: { $0.value < $1.value })
        return mostCommon?.key.defaultEmoji ?? "📊"
    }
    
    private func exportMemories() {
        // Implement export functionality
        print("Exporting memories...")
    }
}

// MARK: - Memory Card
struct MemoryCard: View {
    let memory: UserMemory
    let onFavorite: () -> Void
    let onEdit: () -> Void
    let onDelete: () -> Void
    
    @State private var isPressed = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Text(memory.emoji)
                    .font(.title2)
                
                Spacer()
                
                Button(action: onFavorite) {
                    Image(systemName: memory.isFavorite ? "star.fill" : "star")
                        .foregroundColor(memory.isFavorite ? .yellow : .gray)
                        .scaleEffect(isPressed ? 1.2 : 1.0)
                }
            }
            
            // Title
            Text(memory.title)
                .font(.headline)
                .lineLimit(2)
            
            // Content preview
            Text(memory.content)
                .font(.caption)
                .foregroundColor(.secondary)
                .lineLimit(3)
            
            // Tags
            if !memory.tags.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        ForEach(memory.tags, id: \.self) { tag in
                            Text("#\(tag)")
                                .font(.caption2)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.blue.opacity(0.1))
                                .foregroundColor(.blue)
                                .cornerRadius(8)
                        }
                    }
                }
            }
            
            // Footer
            HStack {
                Text(memory.createdAt, style: .date)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Menu {
                    Button(action: onEdit) {
                        Label("Edit", systemImage: "pencil")
                    }
                    
                    Button(role: .destructive, action: onDelete) {
                        Label("Delete", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 15)
                .fill(Color(UIColor.secondarySystemBackground))
                .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
        )
        .scaleEffect(isPressed ? 0.98 : 1.0)
        .onTapGesture {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                isPressed = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                isPressed = false
            }
        }
    }
}

// MARK: - Filter Chip
struct FilterChip: View {
    let title: String
    let icon: String?
    var emoji: String? = nil
    let isSelected: Bool
    let count: Int
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                if let emoji = emoji {
                    Text(emoji)
                } else if let icon = icon {
                    Image(systemName: icon)
                }
                Text(title)
                Text("(\(count))")
                    .foregroundColor(.secondary)
            }
            .font(.caption)
            .fontWeight(.medium)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(isSelected ? Color.blue : Color(UIColor.secondarySystemBackground))
            .foregroundColor(isSelected ? .white : .primary)
            .cornerRadius(20)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(isSelected ? Color.clear : Color.secondary.opacity(0.2), lineWidth: 1)
            )
        }
    }
}

// MARK: - Stat Item
struct StatItem: View {
    let value: String
    let label: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .foregroundColor(color)
                Text(value)
                    .font(.title3)
                    .fontWeight(.bold)
            }
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - Edit Memory View
struct EditMemoryView: View {
    @Environment(\.dismiss) var dismiss
    let memory: UserMemory
    let onSave: (UserMemory) -> Void
    
    @State private var title: String = ""
    @State private var content: String = ""
    @State private var selectedCategory: MemoryCategory
    @State private var tags: String = ""
    @State private var emoji: String = ""
    
    init(memory: UserMemory, onSave: @escaping (UserMemory) -> Void) {
        self.memory = memory
        self.onSave = onSave
        self._title = State(initialValue: memory.title)
        self._content = State(initialValue: memory.content)
        self._selectedCategory = State(initialValue: memory.category)
        self._tags = State(initialValue: memory.tags.joined(separator: ", "))
        self._emoji = State(initialValue: memory.emoji)
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Memory Details") {
                    TextField("Title", text: $title)
                    
                    TextEditor(text: $content)
                        .frame(minHeight: 100)
                }
                
                Section("Category") {
                    Picker("Category", selection: $selectedCategory) {
                        ForEach(MemoryCategory.allCases, id: \.self) { category in
                            Label(category.displayName, systemImage: "")
                                .tag(category)
                        }
                    }
                }
                
                Section("Tags") {
                    TextField("Tags (comma separated)", text: $tags)
                }
                
                Section("Emoji") {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 15) {
                            ForEach(["💪", "🎯", "🚀", "💡", "🔥", "⭐", "🏆", "💎", "🌟", "✨"], id: \.self) { emojiOption in
                                Text(emojiOption)
                                    .font(.title)
                                    .scaleEffect(emoji == emojiOption ? 1.2 : 1.0)
                                    .onTapGesture {
                                        emoji = emojiOption
                                    }
                            }
                        }
                        .padding(.vertical, 5)
                    }
                }
            }
            .navigationTitle("Edit Memory")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        saveMemory()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }
    
    private func saveMemory() {
        var updatedMemory = memory
        updatedMemory.title = title
        updatedMemory.content = content
        updatedMemory.category = selectedCategory
        updatedMemory.tags = tags.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }
        updatedMemory.emoji = emoji
        updatedMemory.updatedAt = Date()
        
        onSave(updatedMemory)
        dismiss()
    }
}
