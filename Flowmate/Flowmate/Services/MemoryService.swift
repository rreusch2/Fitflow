//
//  MemoryService.swift
//  Flowmate
//
//  Service for managing user memories with Supabase (with graceful fallback if SDK unavailable)
//

import Foundation

#if canImport(Supabase)
import Supabase

class MemoryService: ObservableObject {
    static let shared = MemoryService()
    
    @Published var memories: [UserMemory] = []
    @Published var isLoading = false
    @Published var error: String?
    
    // TODO: Configure with your real Supabase values
    private let supabase = SupabaseClient(
        supabaseURL: URL(string: "YOUR_SUPABASE_URL")!,
        supabaseKey: "YOUR_SUPABASE_ANON_KEY"
    )
    
    private init() {}
    
    // MARK: - Fetch Memories
    func fetchMemories(for userId: UUID) async {
        isLoading = true
        error = nil
        
        do {
            let response = try await supabase
                .from("user_memories")
                .select()
                .eq("user_id", value: userId.uuidString)
                .order("created_at", ascending: false)
                .execute()
            
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            
            let memories = try decoder.decode([UserMemory].self, from: response.data)
            
            await MainActor.run {
                self.memories = memories
                self.isLoading = false
            }
        } catch {
            await MainActor.run {
                self.error = "Failed to fetch memories: \(error.localizedDescription)"
                self.isLoading = false
            }
        }
    }
    
    // MARK: - Save Memory
    func saveMemory(_ memory: UserMemory) async -> Bool {
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            let memoryData = try encoder.encode(memory)
            
            _ = try await supabase
                .from("user_memories")
                .insert(memoryData)
                .execute()
            
            await MainActor.run {
                self.memories.insert(memory, at: 0)
            }
            
            return true
        } catch {
            await MainActor.run {
                self.error = "Failed to save memory: \(error.localizedDescription)"
            }
            return false
        }
    }
    
    // MARK: - Update Memory
    func updateMemory(_ memory: UserMemory) async -> Bool {
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            let memoryData = try encoder.encode(memory)
            
            _ = try await supabase
                .from("user_memories")
                .update(memoryData)
                .eq("id", value: memory.id.uuidString)
                .execute()
            
            await MainActor.run {
                if let index = self.memories.firstIndex(where: { $0.id == memory.id }) {
                    self.memories[index] = memory
                }
            }
            
            return true
        } catch {
            await MainActor.run {
                self.error = "Failed to update memory: \(error.localizedDescription)"
            }
            return false
        }
    }
    
    // MARK: - Delete Memory
    func deleteMemory(_ memory: UserMemory) async -> Bool {
        do {
            _ = try await supabase
                .from("user_memories")
                .delete()
                .eq("id", value: memory.id.uuidString)
                .execute()
            
            await MainActor.run {
                self.memories.removeAll { $0.id == memory.id }
            }
            
            return true
        } catch {
            await MainActor.run {
                self.error = "Failed to delete memory: \(error.localizedDescription)"
            }
            return false
        }
    }
    
    // MARK: - Toggle Favorite
    func toggleFavorite(_ memory: UserMemory) async -> Bool {
        var updatedMemory = memory
        updatedMemory.isFavorite.toggle()
        updatedMemory.updatedAt = Date()
        
        return await updateMemory(updatedMemory)
    }
}
#else

// Fallback in-memory implementation so the app compiles and runs without Supabase SDK
class MemoryService: ObservableObject {
    static let shared = MemoryService()
    
    @Published var memories: [UserMemory] = []
    @Published var isLoading = false
    @Published var error: String?
    
    private init() {}
    
    // Simulated fetch
    func fetchMemories(for userId: UUID) async {
        await MainActor.run {
            self.isLoading = false
        }
    }
    
    // Local insert
    func saveMemory(_ memory: UserMemory) async -> Bool {
        await MainActor.run {
            self.memories.insert(memory, at: 0)
        }
        return true
    }
    
    // Local update
    func updateMemory(_ memory: UserMemory) async -> Bool {
        await MainActor.run {
            if let idx = self.memories.firstIndex(where: { $0.id == memory.id }) {
                self.memories[idx] = memory
            }
        }
        return true
    }
    
    // Local delete
    func deleteMemory(_ memory: UserMemory) async -> Bool {
        await MainActor.run {
            self.memories.removeAll { $0.id == memory.id }
        }
        return true
    }
    
    // Local toggle
    func toggleFavorite(_ memory: UserMemory) async -> Bool {
        var updated = memory
        updated.isFavorite.toggle()
        updated.updatedAt = Date()
        return await updateMemory(updated)
    }
}
#endif

// MARK: - Memory Analysis (available in both builds)
extension MemoryService {
    func analyzeForMemoryMoment(prompt: String, response: String) -> SuggestedMemory? {
        let breakthroughKeywords = ["realized", "breakthrough", "understand now", "finally", "aha", "clicked"]
        let goalKeywords = ["achieved", "completed", "reached", "accomplished", "goal", "milestone", "finished"]
        let recordKeywords = ["first time", "personal best", "pr", "record", "never before", "new max"]
        let habitKeywords = ["every day", "consistently", "routine", "habit", "regularly", "daily"]
        let insightKeywords = ["learned", "discovered", "found out", "insight", "tip", "advice", "strategy"]
        
        let combinedText = (prompt + " " + response).lowercased()
        
        var category: MemoryCategory = .insight
        var title = ""
        var content = ""
        
        if breakthroughKeywords.contains(where: { combinedText.contains($0) }) {
            category = .breakthrough
            title = "Breakthrough Moment"
            content = extractKeyInsight(from: response)
        } else if goalKeywords.contains(where: { combinedText.contains($0) }) {
            category = .goalAchieved
            title = "Goal Achievement"
            content = extractAchievement(from: prompt, response: response)
        } else if recordKeywords.contains(where: { combinedText.contains($0) }) {
            category = .personalRecord
            title = "New Personal Record!"
            content = extractRecord(from: prompt, response: response)
        } else if habitKeywords.contains(where: { combinedText.contains($0) }) {
            category = .habitFormed
            title = "Habit Formation"
            content = extractHabit(from: response)
        } else if insightKeywords.contains(where: { combinedText.contains($0) }) {
            category = .insight
            title = "Valuable Insight"
            content = extractKeyInsight(from: response)
        } else if response.count > 200 && (response.contains("!") || response.lowercased().contains("congratulations")) {
            category = .motivation
            title = "Motivational Moment"
            content = extractMotivation(from: response)
        } else {
            return nil
        }
        
        guard !content.isEmpty && content.count > 30 else { return nil }
        
        return SuggestedMemory(
            title: title,
            content: content,
            category: category,
            chatSessionId: UUID(),
            originalPrompt: prompt,
            aiResponse: response
        )
    }
    
    private func extractKeyInsight(from text: String) -> String {
        let sentences = text.components(separatedBy: CharacterSet(charactersIn: ".!?"))
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty && $0.count > 20 }
        for sentence in sentences {
            if sentence.lowercased().contains("remember") ||
               sentence.lowercased().contains("important") ||
               sentence.lowercased().contains("key") ||
               sentence.lowercased().contains("focus") {
                return sentence
            }
        }
        return sentences.max(by: { $0.count < $1.count }) ?? String(text.prefix(150)).trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    private func extractAchievement(from prompt: String, response: String) -> String {
        let promptKey = prompt.prefix(100).trimmingCharacters(in: .whitespacesAndNewlines)
        let responseKey = extractKeyInsight(from: response)
        return "\(promptKey)\n\nCoach: \(responseKey)"
    }
    
    private func extractRecord(from prompt: String, response: String) -> String {
        let combined = prompt + " " + response
        let sentences = combined.components(separatedBy: CharacterSet(charactersIn: ".!?"))
        for sentence in sentences {
            if sentence.rangeOfCharacter(from: .decimalDigits) != nil {
                return sentence.trimmingCharacters(in: .whitespacesAndNewlines)
            }
        }
        return extractKeyInsight(from: response)
    }
    
    private func extractHabit(from text: String) -> String {
        let sentences = text.components(separatedBy: CharacterSet(charactersIn: ".!?"))
        for sentence in sentences {
            if sentence.lowercased().contains("habit") ||
               sentence.lowercased().contains("routine") ||
               sentence.lowercased().contains("consistently") {
                return sentence.trimmingCharacters(in: .whitespacesAndNewlines)
            }
        }
        return extractKeyInsight(from: text)
    }
    
    private func extractMotivation(from text: String) -> String {
        let sentences = text.components(separatedBy: CharacterSet(charactersIn: ".!"))
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        for sentence in sentences where sentence.contains("!") {
            return sentence
        }
        return extractKeyInsight(from: text)
    }
}
