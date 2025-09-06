import SwiftUI

struct EnhancedFinanceView: View {
    @EnvironmentObject var themeProvider: ThemeProvider
    @EnvironmentObject var authService: AuthenticationService
    @State private var selectedTab = 0
    @State private var stockSymbol = "AAPL"
    @State private var isAnalyzing = false
    @State private var stockAnalysis: String = ""
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    wealthHubHeader
                    
                    // Stock AI Section
                    stockAISection
                    
                    // Quick Actions
                    quickActionsSection
                    
                    // Financial Insights
                    financialInsightsSection
                }
                .padding()
            }
            .background(ThemedBackground().environmentObject(themeProvider))
            .navigationTitle("Wealth Hub")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button("Market Overview") { /* TODO */ }
                        Button("Portfolio Analysis") { /* TODO */ }
                        Button("Settings") { /* TODO */ }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
        }
    }
    
    private var wealthHubHeader: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Wealth Hub")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundColor(themeProvider.theme.gradientTextPrimary)
                    
                    Text("AI-Powered Financial Intelligence")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(themeProvider.theme.gradientTextSecondary)
                }
                
                Spacer()
                
                // Market Status Indicator
                HStack(spacing: 8) {
                    Circle()
                        .fill(Color.green)
                        .frame(width: 8, height: 8)
                    Text("Markets Open")
                        .font(.caption)
                        .foregroundColor(themeProvider.theme.textSecondary)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    Capsule()
                        .fill(themeProvider.theme.backgroundSecondary)
                )
            }
        }
    }
    
    private var stockAISection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .foregroundColor(themeProvider.theme.accent)
                Text("Stock AI Analysis")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(themeProvider.theme.textPrimary)
                Spacer()
            }
            
            VStack(spacing: 12) {
                HStack {
                    TextField("Enter stock symbol", text: $stockSymbol)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .autocapitalization(.allCharacters)
                    
                    Button(action: analyzeStock) {
                        HStack {
                            if isAnalyzing {
                                ProgressView()
                                    .scaleEffect(0.8)
                            } else {
                                Image(systemName: "brain.head.profile")
                            }
                            Text("Analyze")
                                .fontWeight(.semibold)
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(themeProvider.theme.accent)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                    .disabled(isAnalyzing || stockSymbol.isEmpty)
                }
                
                if !stockAnalysis.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("AI Analysis")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(themeProvider.theme.textSecondary)
                        
                        Text(stockAnalysis)
                            .font(.system(size: 15))
                            .foregroundColor(themeProvider.theme.textPrimary)
                            .lineSpacing(3)
                    }
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(themeProvider.theme.backgroundSecondary)
                    )
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(themeProvider.theme.backgroundSecondary.opacity(0.9))
                .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
        )
    }
    
    private var quickActionsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Quick Actions")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(themeProvider.theme.textPrimary)
                Spacer()
            }
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 16) {
                WealthActionCard(
                    title: "Portfolio Analysis",
                    icon: "chart.pie.fill",
                    color: .blue,
                    action: { /* TODO */ }
                )
                
                WealthActionCard(
                    title: "Market Trends",
                    icon: "chart.line.uptrend.xyaxis",
                    color: .green,
                    action: { /* TODO */ }
                )
                
                WealthActionCard(
                    title: "Budget Planner",
                    icon: "dollarsign.circle.fill",
                    color: .orange,
                    action: { /* TODO */ }
                )
                
                WealthActionCard(
                    title: "Investment Tips",
                    icon: "lightbulb.fill",
                    color: .purple,
                    action: { /* TODO */ }
                )
            }
        }
    }
    
    private var financialInsightsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Financial Insights")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(themeProvider.theme.textPrimary)
                Spacer()
                Button("View All") { /* TODO */ }
                    .font(.caption)
                    .foregroundColor(themeProvider.theme.accent)
            }
            
            VStack(spacing: 12) {
                InsightCard(
                    title: "Market Sentiment",
                    value: "Bullish",
                    description: "Tech stocks showing strong momentum",
                    icon: "arrow.up.circle.fill",
                    color: .green
                )
                
                InsightCard(
                    title: "Portfolio Health",
                    value: "82/100",
                    description: "Well diversified with moderate risk",
                    icon: "heart.fill",
                    color: .blue
                )
                
                InsightCard(
                    title: "Savings Goal",
                    value: "$12,450",
                    description: "67% towards emergency fund",
                    icon: "target",
                    color: .orange
                )
            }
        }
    }
    
    private func analyzeStock() {
        guard !stockSymbol.isEmpty else { return }
        isAnalyzing = true
        stockAnalysis = ""
        
        Task {
            do {
                // This would call your AI service
                let analysis = try await generateStockAnalysis(for: stockSymbol)
                await MainActor.run {
                    stockAnalysis = analysis
                    isAnalyzing = false
                }
            } catch {
                await MainActor.run {
                    stockAnalysis = "Failed to analyze \(stockSymbol). Please try again."
                    isAnalyzing = false
                }
            }
        }
    }
    
    private func generateStockAnalysis(for symbol: String) async throws -> String {
        // TODO: Connect to your AI backend
        // This is placeholder - replace with actual API call
        return """
        **\(symbol) Analysis:**
        
        Current market conditions suggest \(symbol) is positioned for moderate growth. Key factors include:
        
        • Strong fundamentals with solid revenue growth
        • Market sentiment remains positive
        • Technical indicators show upward trend
        
        **Recommendation:** Hold with potential for gradual accumulation
        """
    }
}

struct WealthActionCard: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void
    @EnvironmentObject var themeProvider: ThemeProvider
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 28))
                    .foregroundColor(color)
                
                Text(title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(themeProvider.theme.textPrimary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(themeProvider.theme.backgroundSecondary)
                    .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
            )
        }
    }
}

struct InsightCard: View {
    let title: String
    let value: String
    let description: String
    let icon: String
    let color: Color
    @EnvironmentObject var themeProvider: ThemeProvider
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(color)
                .frame(width: 40)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(themeProvider.theme.textSecondary)
                
                Text(value)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(themeProvider.theme.textPrimary)
                
                Text(description)
                    .font(.system(size: 12))
                    .foregroundColor(themeProvider.theme.textSecondary)
                    .lineLimit(2)
            }
            
            Spacer()
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(themeProvider.theme.backgroundSecondary)
        )
    }
}

#Preview {
    EnhancedFinanceView()
        .environmentObject(ThemeProvider())
        .environmentObject(AuthenticationService.shared)
}
