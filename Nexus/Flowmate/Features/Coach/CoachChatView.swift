import SwiftUI

struct CoachChatView: View {
    @State private var input: String = ""
    @State private var messages: [ChatBubble] = []
    @State private var isSending = false
    @State private var isStreaming = false
    @State private var error: String?
    @State private var currentStreamingMessage = ""
    @FocusState private var isInputFocused: Bool

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(messages) { msg in
                                MessageBubbleView(message: msg)
                                    .id(msg.id)
                                    .padding(.horizontal)
                            }
                            
                            // Streaming message bubble
                            if isStreaming && !currentStreamingMessage.isEmpty {
                                MessageBubbleView(message: ChatBubble(role: .assistant, text: currentStreamingMessage, isStreaming: true))
                                    .id("streaming")
                                    .padding(.horizontal)
                            }
                            
                            // Typing indicator
                            if isStreaming && currentStreamingMessage.isEmpty {
                                TypingIndicatorView()
                                    .id("typing")
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

                // Quick actions - now populate input instead of sending directly
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        QuickActionButton(title: "Workout Plan", systemImage: "figure.run", gradient: LinearGradient(colors: [.orange, .red], startPoint: .topLeading, endPoint: .bottomTrailing)) {
                            populateInput("Create a personalized workout plan for me based on my fitness goals and current level")
                        }
                        QuickActionButton(title: "Meal Plan", systemImage: "fork.knife", gradient: LinearGradient(colors: [.green, .mint], startPoint: .topLeading, endPoint: .bottomTrailing)) {
                            populateInput("Design a healthy meal plan that aligns with my fitness goals and dietary preferences")
                        }
                        QuickActionButton(title: "Analyze Progress", systemImage: "chart.line.uptrend.xyaxis", gradient: LinearGradient(colors: [.blue, .purple], startPoint: .topLeading, endPoint: .bottomTrailing)) {
                            populateInput("Analyze my recent progress and provide insights on my fitness journey")
                        }
                        QuickActionButton(title: "Daily Tips", systemImage: "lightbulb.fill", gradient: LinearGradient(colors: [.yellow, .orange], startPoint: .topLeading, endPoint: .bottomTrailing)) {
                            populateInput("Give me some motivational fitness tips for today")
                        }
                        QuickActionButton(title: "Form Check", systemImage: "figure.strengthtraining.traditional", gradient: LinearGradient(colors: [.indigo, .blue], startPoint: .topLeading, endPoint: .bottomTrailing)) {
                            populateInput("Help me understand proper form for my exercises")
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 10)
                }
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
                .padding(.horizontal, 8)

                // Enhanced input area
                VStack(spacing: 0) {
                    HStack(alignment: .bottom, spacing: 12) {
                        VStack(spacing: 0) {
                            TextField("Ask your coach anything...", text: $input, axis: .vertical)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 14)
                                .background(
                                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                                        .fill(.ultraThinMaterial)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 24, style: .continuous)
                                                .stroke(isInputFocused ? .accent : .primary.opacity(0.1), lineWidth: isInputFocused ? 2 : 1)
                                        )
                                )
                                .focused($isInputFocused)
                                .disabled(isSending || isStreaming)
                                .lineLimit(1...6)
                                .font(.system(size: 16))
                        }
                        
                        Button {
                            Task { await sendWithStreaming() }
                        } label: {
                            ZStack {
                                if isSending || isStreaming {
                                    ProgressView()
                                        .scaleEffect(0.8)
                                        .tint(.white)
                                } else {
                                    Image(systemName: "paperplane.fill")
                                        .font(.system(size: 18, weight: .semibold))
                                        .foregroundColor(.white)
                                }
                            }
                            .frame(width: 44, height: 44)
                            .background(
                                Circle()
                                    .fill(
                                        input.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isSending || isStreaming
                                        ? .gray.opacity(0.3)
                                        : LinearGradient(colors: [.accentColor, .blue], startPoint: .topLeading, endPoint: .bottomTrailing)
                                    )
                            )
                            .scaleEffect((isSending || isStreaming) ? 0.95 : 1.0)
                        }
                        .disabled(input.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isSending || isStreaming)
                        .animation(.easeInOut(duration: 0.2), value: isSending || isStreaming)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 12)
                    .padding(.bottom, max(12, UIApplication.shared.keyWindow?.safeAreaInsets.bottom ?? 0))
                }
                .background(
                    .regularMaterial,
                    in: RoundedRectangle(cornerRadius: 20, style: .continuous)
                )
                .animation(.easeInOut(duration: 0.3), value: isInputFocused)
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

    private func populateInput(_ prompt: String) {
        input = prompt
        isInputFocused = true
        
        // Add haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
    }
    
    private func sendWithStreaming() async {
        let text = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        
        // Clear input and add user message
        input = ""
        error = nil
        isInputFocused = false
        
        let userMsg = ChatBubble(role: .user, text: text)
        messages.append(userMsg)
        
        // Start streaming
        isStreaming = true
        currentStreamingMessage = ""
        
        do {
            // For now, we'll simulate streaming by getting the full response
            // and then "typing" it out character by character
            let fullReply = try await CoachAPIClient.shared.chat(message: text)
            
            // Simulate streaming effect
            await streamMessage(fullReply)
            
        } catch {
            self.error = "Failed to send: \(error.localizedDescription)"
            isStreaming = false
            currentStreamingMessage = ""
        }
    }
    
    private func streamMessage(_ fullMessage: String) async {
        let words = fullMessage.components(separatedBy: " ")
        var streamedText = ""
        
        for (index, word) in words.enumerated() {
            if index > 0 { streamedText += " " }
            streamedText += word
            
            await MainActor.run {
                currentStreamingMessage = streamedText
            }
            
            // Add a small delay to simulate streaming
            try? await Task.sleep(nanoseconds: 50_000_000) // 50ms
        }
        
        // Finish streaming
        await MainActor.run {
            messages.append(ChatBubble(role: .assistant, text: fullMessage))
            isStreaming = false
            currentStreamingMessage = ""
        }
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
    let gradient: LinearGradient
    let action: () -> Void
    @State private var isPressed = false

    var body: some View {
        Button(action: {
            let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
            impactFeedback.impactOccurred()
            action()
        }) {
            HStack(spacing: 8) {
                Image(systemName: systemImage)
                    .font(.system(size: 14, weight: .semibold))
                Text(title)
                    .font(.system(size: 14, weight: .semibold))
            }
            .foregroundColor(.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                Capsule()
                    .fill(gradient)
                    .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
            )
            .scaleEffect(isPressed ? 0.95 : 1.0)
        }
        .pressEvents {
            withAnimation(.easeInOut(duration: 0.1)) {
                isPressed = true
            }
        } onRelease: {
            withAnimation(.easeInOut(duration: 0.1)) {
                isPressed = false
            }
        }
    }
}

// Helper for press events
private struct PressActions: ViewModifier {
    var onPress: () -> Void
    var onRelease: () -> Void
    
    func body(content: Content) -> some View {
        content
            .simultaneousGesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in
                        onPress()
                    }
                    .onEnded { _ in
                        onRelease()
                    }
            )
    }
}

private extension View {
    func pressEvents(onPress: @escaping (() -> Void), onRelease: @escaping (() -> Void)) -> some View {
        modifier(PressActions(onPress: onPress, onRelease: onRelease))
    }
}

// Enhanced message bubble
private struct MessageBubbleView: View {
    let message: ChatBubble
    
    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            if message.role == .assistant {
                // Coach avatar
                Image(systemName: "figure.run.circle.fill")
                    .font(.system(size: 24))
                    .foregroundStyle(
                        LinearGradient(colors: [.blue, .purple], startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
                    .background(Circle().fill(.white))
            } else {
                Spacer(minLength: 50)
            }
            
            VStack(alignment: message.role == .user ? .trailing : .leading, spacing: 4) {
                Text(message.text)
                    .font(.system(size: 16, weight: .regular, design: .default))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .fill(
                                message.role == .user
                                ? LinearGradient(colors: [.accentColor.opacity(0.8), .accentColor], startPoint: .topLeading, endPoint: .bottomTrailing)
                                : LinearGradient(colors: [.gray.opacity(0.1), .gray.opacity(0.05)], startPoint: .topLeading, endPoint: .bottomTrailing)
                            )
                            .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
                    )
                    .foregroundColor(message.role == .user ? .white : .primary)
                    .overlay(
                        // Streaming indicator
                        message.isStreaming ?
                        HStack {
                            Spacer()
                            HStack(spacing: 4) {
                                ForEach(0..<3, id: \.self) { index in
                                    Circle()
                                        .fill(.secondary)
                                        .frame(width: 4, height: 4)
                                        .scaleEffect(1.0)
                                        .animation(
                                            Animation.easeInOut(duration: 0.6)
                                                .repeatForever(autoreverses: true)
                                                .delay(Double(index) * 0.2),
                                            value: message.isStreaming
                                        )
                                }
                            }
                            .padding(.trailing, 8)
                            .padding(.bottom, 8)
                        } : nil,
                        alignment: .bottomTrailing
                    )
                
                // Timestamp
                Text(DateFormatter.chatTime.string(from: message.timestamp))
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 4)
            }
            
            if message.role == .user {
                Spacer(minLength: 50)
            }
        }
        .padding(.vertical, 4)
    }
}

// Typing indicator
private struct TypingIndicatorView: View {
    @State private var animating = false
    
    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            // Coach avatar
            Image(systemName: "figure.run.circle.fill")
                .font(.system(size: 24))
                .foregroundStyle(
                    LinearGradient(colors: [.blue, .purple], startPoint: .topLeading, endPoint: .bottomTrailing)
                )
                .background(Circle().fill(.white))
            
            HStack(spacing: 4) {
                ForEach(0..<3, id: \.self) { index in
                    Circle()
                        .fill(.secondary)
                        .frame(width: 8, height: 8)
                        .scaleEffect(animating ? 1.5 : 1.0)
                        .animation(
                            Animation.easeInOut(duration: 0.6)
                                .repeatForever(autoreverses: true)
                                .delay(Double(index) * 0.2),
                            value: animating
                        )
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(.gray.opacity(0.1))
                    .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
            )
            
            Spacer(minLength: 50)
        }
        .onAppear {
            animating = true
        }
        .padding(.vertical, 4)
    }
}

// Date formatter extension
private extension DateFormatter {
    static let chatTime: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter
    }()
}

private struct ChatBubble: Identifiable {
    enum Role { case user, assistant }
    let id = UUID()
    let role: Role
    let text: String
    let timestamp = Date()
    var isStreaming: Bool = false
    
    init(role: Role, text: String, isStreaming: Bool = false) {
        self.role = role
        self.text = text
        self.isStreaming = isStreaming
    }
}
