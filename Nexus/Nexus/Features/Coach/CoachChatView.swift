import SwiftUI

struct CoachChatView: View {
    @State private var input: String = ""
    @State private var messages: [ChatBubble] = []
    @State private var isSending = false
    @State private var error: String?

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(messages) { msg in
                                HStack(alignment: .bottom) {
                                    if msg.role == .assistant { Spacer(minLength: 0) }
                                    Text(msg.text)
                                        .padding(12)
                                        .background(msg.role == .user ? Color.accentColor.opacity(0.15) : Color.secondary.opacity(0.12))
                                        .foregroundColor(.primary)
                                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                                .stroke(Color.primary.opacity(0.05))
                                        )
                                    if msg.role == .user { Spacer(minLength: 0) }
                                }
                                .id(msg.id)
                                .padding(.horizontal)
                            }
                            .padding(.vertical)
                        }
                    }
                    .onChange(of: messages.count) { _ in
                        if let last = messages.last { withAnimation { proxy.scrollTo(last.id, anchor: .bottom) } }
                    }
                }

                if let error { Text(error).foregroundColor(.red).padding(.vertical, 4) }

                // Quick actions
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        QuickActionButton(title: "Workout Plan", systemImage: "figure.run") {
                            Task { await generateWorkoutPlan() }
                        }
                        QuickActionButton(title: "Meal Plan", systemImage: "fork.knife") {
                            Task { await generateMealPlan() }
                        }
                        QuickActionButton(title: "Analyze Progress", systemImage: "chart.line.uptrend.xyaxis") {
                            Task { await analyzeProgress() }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                }
                .background(.ultraThinMaterial)

                HStack(spacing: 10) {
                    TextField("Ask your coach anything...", text: $input, axis: .vertical)
                        .textFieldStyle(.roundedBorder)
                        .disabled(isSending)
                        .lineLimit(1...4)
                    Button {
                        Task { await send() }
                    } label: {
                        Image(systemName: isSending ? "hourglass" : "paperplane.fill")
                            .font(.system(size: 18, weight: .semibold))
                    }
                    .disabled(input.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isSending)
                }
                .padding(.horizontal)
                .padding(.vertical, 10)
                .background(.bar)
            }
            .navigationTitle("Coach")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button("Clear Chat", role: .destructive) { messages.removeAll() }
                    } label: { Image(systemName: "ellipsis.circle") }
                }
            }
            .onAppear {
                if messages.isEmpty {
                    messages.append(ChatBubble(role: .assistant, text: "Hey! I’m your AI coach. Ask me anything or use the quick actions below."))
                }
            }
        }
    }

    private func send() async {
        let text = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        input = ""
        error = nil
        let userMsg = ChatBubble(role: .user, text: text)
        messages.append(userMsg)
        isSending = true
        do {
            let reply = try await CoachAPIClient.shared.chat(message: text)
            messages.append(ChatBubble(role: .assistant, text: reply))
        } catch {
            self.error = "Failed to send: \(error.localizedDescription)"
        }
        isSending = false
    }

    private func generateWorkoutPlan() async {
        error = nil
        isSending = true
        messages.append(ChatBubble(role: .assistant, text: "Generating a personalized workout plan..."))
        do {
            let plan = try await CoachAPIClient.shared.generateWorkoutPlan()
            let summary = summarizePlan(plan, titleKey: "title", itemsKey: "exercises")
            messages.append(ChatBubble(role: .assistant, text: summary))
        } catch {
            self.error = "Workout plan failed: \(error.localizedDescription)"
        }
        isSending = false
    }

    private func generateMealPlan() async {
        error = nil
        isSending = true
        messages.append(ChatBubble(role: .assistant, text: "Crafting a meal plan for your goals..."))
        do {
            let plan = try await CoachAPIClient.shared.generateMealPlan()
            let summary = summarizePlan(plan, titleKey: "title", itemsKey: "meals")
            messages.append(ChatBubble(role: .assistant, text: summary))
        } catch {
            self.error = "Meal plan failed: \(error.localizedDescription)"
        }
        isSending = false
    }

    private func analyzeProgress() async {
        error = nil
        isSending = true
        messages.append(ChatBubble(role: .assistant, text: "Analyzing your recent progress..."))
        do {
            let result = try await CoachAPIClient.shared.analyzeProgress(entries: [])
            let summary = summarizeAnalysis(result)
            messages.append(ChatBubble(role: .assistant, text: summary))
        } catch {
            self.error = "Analysis failed: \(error.localizedDescription)"
        }
        isSending = false
    }

    private func summarizePlan(_ plan: [String: Any], titleKey: String, itemsKey: String) -> String {
        let title = plan[titleKey] as? String ?? "Personalized Plan"
        let description = plan["description"] as? String ?? ""
        let items = plan[itemsKey] as? [Any] ?? []
        return "\(title)\n\n\(description)\n\nItems: \(items.count)."
    }

    private func summarizeAnalysis(_ result: [String: Any]) -> String {
        let summary = result["summary"] as? String ?? "Here are your insights."
        let trends = result["trends"] as? [Any] ?? []
        return "\(summary)\n\nTrends found: \(trends.count)."
    }
}

private struct QuickActionButton: View {
    let title: String
    let systemImage: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: systemImage)
                Text(title)
                    .fontWeight(.semibold)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(.ultraThinMaterial)
            .clipShape(Capsule())
        }
    }
}

private struct ChatBubble: Identifiable {
    enum Role { case user, assistant }
    let id = UUID()
    let role: Role
    let text: String
}
