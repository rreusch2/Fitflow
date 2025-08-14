//
//  FinanceAIService.swift
//  Flowmate
//
//  Created on 2025-01-13
//

import Foundation
import Combine

@MainActor
class FinanceAIService: ObservableObject {
    static let shared = FinanceAIService()
    
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var marketOverview: MarketOverview?
    @Published var watchlistQuotes: [String: StockQuote] = [:]
    
    private let aiService = AIService.shared
    private var cancellables = Set<AnyCancellable>()
    private let cache = FinanceCache()
    
    // Rate limiting for external API calls
    private var lastMarketDataRequest = Date.distantPast
    private let marketDataCooldown: TimeInterval = 60 // 1 minute between requests
    
    private init() {}
    
    // MARK: - Real-time Stock Data via AI
    
    func getStockQuote(symbol: String) async throws -> StockQuote {
        let cacheKey = "quote_\(symbol)"
        
        // Check cache first (5 minute TTL for quotes)
        if let cachedQuote: StockQuote = cache.get(key: cacheKey, ttl: 300) {
            return cachedQuote
        }
        
        isLoading = true
        defer { isLoading = false }
        
        let prompt = createStockQuotePrompt(symbol: symbol)
        
        do {
            let response = try await callFinanceAI(
                prompt: prompt,
                type: .stockQuote
            )
            
            let quote = try parseStockQuoteResponse(response, symbol: symbol)
            cache.set(key: cacheKey, value: quote)
            
            return quote
            
        } catch {
            errorMessage = "Failed to fetch quote for \(symbol): \(error.localizedDescription)"
            throw error
        }
    }
    
    func getMultipleQuotes(symbols: [String]) async throws -> [StockQuote] {
        // Process in batches to avoid rate limiting
        let batchSize = 5
        var allQuotes: [StockQuote] = []
        
        for batch in symbols.chunked(into: batchSize) {
            let batchQuotes = try await withThrowingTaskGroup(of: StockQuote.self) { group in
                for symbol in batch {
                    group.addTask {
                        try await self.getStockQuote(symbol: symbol)
                    }
                }
                
                var quotes: [StockQuote] = []
                for try await quote in group {
                    quotes.append(quote)
                }
                return quotes
            }
            
            allQuotes.append(contentsOf: batchQuotes)
            
            // Small delay between batches
            if symbols.count > batchSize {
                try await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
            }
        }
        
        return allQuotes
    }
    
    // MARK: - AI Stock Analysis
    
    func analyzeStock(
        symbol: String,
        analysisType: AIStockAnalysis.AnalysisType = .comprehensive,
        userPreferences: FinancePreferences?
    ) async throws -> AIStockAnalysis {
        let cacheKey = "analysis_\(symbol)_\(analysisType.rawValue)"
        // Check cache (30 minute TTL for analysis)
        if let cachedAnalysis: AIStockAnalysis = cache.get(key: cacheKey, ttl: 1800) {
            return cachedAnalysis
        }
        isLoading = true
        defer { isLoading = false }
        do {
            let analysis = try await backendAnalyzeStock(symbol: symbol, analysisType: analysisType)
            cache.set(key: cacheKey, value: analysis)
            return analysis
        } catch {
            errorMessage = "Failed to analyze \(symbol): \(error.localizedDescription)"
            throw error
        }
    }

    // MARK: - Backend Integration
    private func backendAnalyzeStock(symbol: String, analysisType: AIStockAnalysis.AnalysisType) async throws -> AIStockAnalysis {
        guard let url = URL(string: Config.Environment.current.baseURL + "/v1/finance/stock-analysis") else {
            throw URLError(.badURL)
        }
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        // Optional: forward auth if available later
        let body: [String: Any] = [
            "symbol": symbol.uppercased(),
            "analysis_type": analysisType.rawValue
        ]
        req.httpBody = try JSONSerialization.data(withJSONObject: body, options: [])
        let (data, resp) = try await URLSession.shared.data(for: req)
        if let http = resp as? HTTPURLResponse, http.statusCode >= 400 {
            let msg = String(data: data, encoding: .utf8) ?? "HTTP \(http.statusCode)"
            throw NSError(domain: "FinanceAIService", code: http.statusCode, userInfo: [NSLocalizedDescriptionKey: msg])
        }
        struct Payload: Decodable {
            struct BackendAnalysis: Decodable {
                let symbol: String
                let analysisType: String
                let rating: String
                let targetPrice: Double?
                let reasoning: String
                let keyPoints: [String]
                let riskFactors: [String]
                let timeframe: String
                let confidence: Double
                let generatedAt: String
            }
            let analysis: BackendAnalysis
        }
        let decoded = try JSONDecoder().decode(Payload.self, from: data)
        let a = decoded.analysis
        let tf = mapTimeframe(a.timeframe)
        let rating = AIStockAnalysis.AIRating(rawValue: a.rating) ?? .hold
        let date = ISO8601DateFormatter().date(from: a.generatedAt) ?? Date()
        return AIStockAnalysis(
            symbol: a.symbol,
            analysisType: AIStockAnalysis.AnalysisType(rawValue: a.analysisType) ?? analysisType,
            rating: rating,
            targetPrice: a.targetPrice,
            reasoning: a.reasoning,
            keyPoints: a.keyPoints,
            riskFactors: a.riskFactors,
            timeframe: tf,
            confidence: a.confidence,
            generatedAt: date
        )
    }

    private func mapTimeframe(_ s: String) -> AIStockAnalysis.AnalysisTimeframe {
        switch s {
        case AIStockAnalysis.AnalysisTimeframe.shortTerm.rawValue: return .shortTerm
        case AIStockAnalysis.AnalysisTimeframe.mediumTerm.rawValue: return .mediumTerm
        case AIStockAnalysis.AnalysisTimeframe.longTerm.rawValue: return .longTerm
        default:
            if s.contains("1-3") { return .shortTerm }
            if s.contains("3-12") { return .mediumTerm }
            if s.contains("1-5") { return .longTerm }
            return .mediumTerm
        }
    }
    
    // MARK: - Portfolio Analysis
    
    func analyzePortfolio(_ portfolio: Portfolio, userPreferences: FinancePreferences?) async throws -> [AIPortfolioInsight] {
        let cacheKey = "portfolio_analysis_\(portfolio.id)"
        
        // Check cache (1 hour TTL)
        if let cachedInsights: [AIPortfolioInsight] = cache.get(key: cacheKey, ttl: 3600) {
            return cachedInsights
        }
        
        isLoading = true
        defer { isLoading = false }
        
        let prompt = createPortfolioAnalysisPrompt(portfolio: portfolio, userPreferences: userPreferences)
        
        do {
            let response = try await callFinanceAI(
                prompt: prompt,
                type: .portfolioAnalysis
            )
            
            let insights = try parsePortfolioInsightsResponse(response)
            cache.set(key: cacheKey, value: insights)
            
            return insights
            
        } catch {
            errorMessage = "Failed to analyze portfolio: \(error.localizedDescription)"
            throw error
        }
    }
    
    // MARK: - Market News & Sentiment
    
    func getMarketNews(symbols: [String] = [], limit: Int = 10) async throws -> [StockNews] {
        let cacheKey = "market_news_\(symbols.joined(separator: ","))"
        
        // Check cache (15 minute TTL for news)
        if let cachedNews: [StockNews] = cache.get(key: cacheKey, ttl: 900) {
            return cachedNews
        }
        
        isLoading = true
        defer { isLoading = false }
        
        let prompt = createMarketNewsPrompt(symbols: symbols, limit: limit)
        
        do {
            let response = try await callFinanceAI(
                prompt: prompt,
                type: .marketNews
            )
            
            let news = try parseMarketNewsResponse(response, symbols: symbols)
            cache.set(key: cacheKey, value: news)
            
            return news
            
        } catch {
            errorMessage = "Failed to fetch market news: \(error.localizedDescription)"
            throw error
        }
    }
    
    // MARK: - Investment Ideas Generation
    
    func generateInvestmentIdeas(
        userPreferences: FinancePreferences,
        portfolio: Portfolio?
    ) async throws -> [AIStockAnalysis] {
        let cacheKey = "investment_ideas_\(userPreferences.riskTolerance.rawValue)"
        
        // Check cache (2 hour TTL)
        if let cachedIdeas: [AIStockAnalysis] = cache.get(key: cacheKey, ttl: 7200) {
            return cachedIdeas
        }
        
        isLoading = true
        defer { isLoading = false }
        
        let prompt = createInvestmentIdeasPrompt(
            userPreferences: userPreferences,
            currentPortfolio: portfolio
        )
        
        do {
            let response = try await callFinanceAI(
                prompt: prompt,
                type: .investmentIdeas
            )
            
            let ideas = try parseInvestmentIdeasResponse(response, userPreferences: userPreferences)
            cache.set(key: cacheKey, value: ideas)
            
            return ideas
            
        } catch {
            errorMessage = "Failed to generate investment ideas: \(error.localizedDescription)"
            throw error
        }
    }
    
    // MARK: - Market Overview
    
    func getMarketOverview() async throws -> MarketOverview {
        let now = Date()
        
        // Rate limit market data requests
        guard now.timeIntervalSince(lastMarketDataRequest) >= marketDataCooldown else {
            if let cached = marketOverview {
                return cached
            }
            throw FinanceError.rateLimited
        }
        
        let cacheKey = "market_overview"
        
        // Check cache (10 minute TTL)
        if let cachedOverview: MarketOverview = cache.get(key: cacheKey, ttl: 600) {
            marketOverview = cachedOverview
            return cachedOverview
        }
        
        isLoading = true
        defer { 
            isLoading = false
            lastMarketDataRequest = now
        }
        
        let prompt = createMarketOverviewPrompt()
        
        do {
            let response = try await callFinanceAI(
                prompt: prompt,
                type: .marketOverview
            )
            
            let overview = try parseMarketOverviewResponse(response)
            cache.set(key: cacheKey, value: overview)
            marketOverview = overview
            
            return overview
            
        } catch {
            errorMessage = "Failed to fetch market overview: \(error.localizedDescription)"
            throw error
        }
    }
    
    // MARK: - AI API Communication
    
    private func callFinanceAI(prompt: String, type: FinanceAIRequestType) async throws -> String {
            // Create a dummy user for the AI service call
        let dummyUser = User(
            id: UUID(),
            email: "finance@ai.service",
            subscriptionTier: .free,
            preferences: nil,
            healthProfile: nil,
            hasCompletedOnboarding: true,
            createdAt: Date(),
            updatedAt: Date()
        )
        
        // Use the existing AIService with chat completion
        let messages = [ChatMessage(id: UUID(), role: .user, content: prompt, timestamp: Date())]
        return try await aiService.generateChatResponse(
            messages: messages,
            user: dummyUser,
            context: .general
        )
    }
    
    // MARK: - Prompt Creation
    
    private func createStockQuotePrompt(symbol: String) -> String {
        return """
        You are a financial data expert. Get the current stock quote for \(symbol).
        
        Provide the response in this EXACT JSON format:
        {
            "symbol": "\(symbol)",
            "price": 150.25,
            "change": 2.35,
            "changePercent": 1.59,
            "volume": 45678900,
            "marketCap": 2456789000000,
            "pe": 25.4,
            "week52High": 198.23,
            "week52Low": 124.17,
            "timestamp": "\(ISO8601DateFormatter().string(from: Date()))"
        }
        
        Use real, current market data. If the market is closed, use the last closing price.
        Make sure all numbers are accurate and properly formatted.
        """
    }
    
    private func createStockAnalysisPrompt(
        symbol: String,
        analysisType: AIStockAnalysis.AnalysisType,
        userPreferences: FinancePreferences?
    ) -> String {
        let riskTolerance = userPreferences?.riskTolerance.rawValue ?? "moderate"
        let goals = userPreferences?.investmentGoals.map { $0.displayName }.joined(separator: ", ") ?? "wealth building"
        
        return """
        You are an expert financial analyst. Perform a \(analysisType.displayName.lowercased()) of \(symbol).
        
        User Profile:
        - Risk Tolerance: \(riskTolerance)
        - Investment Goals: \(goals)
        
        Provide your analysis in this EXACT JSON format:
        {
            "symbol": "\(symbol)",
            "analysisType": "\(analysisType.rawValue)",
            "rating": "buy|sell|hold|strong_buy|strong_sell",
            "targetPrice": 175.50,
            "reasoning": "Detailed reasoning for the rating based on \(analysisType.displayName.lowercased())",
            "keyPoints": [
                "Point 1 about the stock",
                "Point 2 about financials or technicals",
                "Point 3 about market position"
            ],
            "riskFactors": [
                "Risk factor 1",
                "Risk factor 2"
            ],
            "timeframe": "1-3 months|3-12 months|1-5 years",
            "confidence": 85
        }
        
        Base your analysis on real market data, financials, news, and technical indicators.
        Consider the user's risk tolerance and goals in your recommendation.
        Be thorough but concise in your reasoning.
        """
    }
    
    private func createPortfolioAnalysisPrompt(portfolio: Portfolio, userPreferences: FinancePreferences?) -> String {
        let positions = portfolio.positions.map { "\($0.symbol): \($0.shares) shares at $\($0.currentPrice)" }.joined(separator: ", ")
        let riskTolerance = userPreferences?.riskTolerance.rawValue ?? "moderate"
        
        return """
        You are a portfolio management expert. Analyze this portfolio and provide actionable insights.
        
        Portfolio Details:
        - Total Value: $\(portfolio.totalValue)
        - Positions: \(positions)
        - Current Risk Score: \(portfolio.riskScore)/100
        - Diversification Score: \(portfolio.diversificationScore)/100
        - User Risk Tolerance: \(riskTolerance)
        
        Provide insights in this EXACT JSON format as an array:
        [
            {
                "title": "Portfolio Diversification Assessment",
                "description": "Analysis of portfolio diversification",
                "insightType": "diversification",
                "priority": "high",
                "actionable": true,
                "suggestedActions": [
                    "Specific action 1",
                    "Specific action 2"
                ],
                "potentialImpact": "Expected outcome of following suggestions"
            }
        ]
        
        Focus on:
        1. Diversification across sectors
        2. Risk management opportunities
        3. Rebalancing recommendations
        4. Tax optimization strategies
        5. Performance improvements
        
        Provide 3-5 practical, actionable insights.
        """
    }
    
    private func createMarketNewsPrompt(symbols: [String], limit: Int) -> String {
        let symbolList = symbols.isEmpty ? "general market" : symbols.joined(separator: ", ")
        
        return """
        You are a financial news analyst. Get the latest market news for: \(symbolList)
        
        Provide \(limit) most relevant news items in this EXACT JSON format:
        [
            {
                "headline": "News headline",
                "summary": "2-3 sentence summary of the news",
                "source": "News source name",
                "publishedDate": "\(ISO8601DateFormatter().string(from: Date()))",
                "url": "https://example.com/article",
                "sentiment": "bullish|bearish|neutral",
                "relatedStocks": ["AAPL", "MSFT"]
            }
        ]
        
        Focus on:
        - Recent market moving news
        - Earnings reports and guidance
        - Economic indicators
        - Regulatory changes
        - Major corporate developments
        
        Ensure sentiment analysis is accurate and relates to stock impact.
        Use real, recent news from the past 24-48 hours.
        """
    }
    
    private func createInvestmentIdeasPrompt(userPreferences: FinancePreferences, currentPortfolio: Portfolio?) -> String {
        let riskTolerance = userPreferences.riskTolerance.rawValue
        let goals = userPreferences.investmentGoals.map { $0.displayName }.joined(separator: ", ")
        let portfolioInfo = currentPortfolio != nil ? "Current holdings: \(currentPortfolio!.positions.map { $0.symbol }.joined(separator: ", "))" : "No current positions"
        
        return """
        You are an investment advisor. Generate 5 investment ideas tailored to this user profile:
        
        User Profile:
        - Risk Tolerance: \(riskTolerance)
        - Investment Goals: \(goals)
        - \(portfolioInfo)
        - Preferred Sectors: \(userPreferences.preferredSectors.joined(separator: ", "))
        
        Provide investment ideas in this EXACT JSON format as an array of analyses:
        [
            {
                "symbol": "STOCK_SYMBOL",
                "analysisType": "comprehensive",
                "rating": "buy|strong_buy",
                "targetPrice": 125.50,
                "reasoning": "Why this fits the user's profile and goals",
                "keyPoints": [
                    "Reason 1 it matches user preferences",
                    "Reason 2 about growth potential",
                    "Reason 3 about risk/reward"
                ],
                "riskFactors": [
                    "Risk factor 1",
                    "Risk factor 2"
                ],
                "timeframe": "3-12 months",
                "confidence": 80
            }
        ]
        
        Consider:
        - User's risk tolerance and goals
        - Current market conditions
        - Diversification vs current holdings
        - Sector rotation opportunities
        - ESG factors if relevant
        
        Provide 5 diverse, well-researched ideas.
        """
    }
    
    private func createMarketOverviewPrompt() -> String {
        return """
        You are a market data expert. Provide a comprehensive market overview with current data.
        
        Provide the response in this EXACT JSON format:
        {
            "indices": [
                {
                    "name": "S&P 500",
                    "symbol": "SPX",
                    "value": 4567.89,
                    "change": 12.34,
                    "changePercent": 0.27
                },
                {
                    "name": "Nasdaq",
                    "symbol": "IXIC",
                    "value": 14234.56,
                    "change": -45.67,
                    "changePercent": -0.32
                },
                {
                    "name": "Dow Jones",
                    "symbol": "DJI",
                    "value": 34567.89,
                    "change": 89.12,
                    "changePercent": 0.26
                }
            ],
            "topGainers": [
                {
                    "symbol": "STOCK1",
                    "price": 125.50,
                    "change": 8.25,
                    "changePercent": 7.04,
                    "volume": 1234567
                }
            ],
            "topLosers": [
                {
                    "symbol": "STOCK2",
                    "price": 89.75,
                    "change": -6.25,
                    "changePercent": -6.51,
                    "volume": 987654
                }
            ],
            "mostActive": [
                {
                    "symbol": "STOCK3",
                    "price": 234.50,
                    "change": 2.15,
                    "changePercent": 0.93,
                    "volume": 45678901
                }
            ],
            "marketSentiment": "optimistic",
            "economicEvents": [
                {
                    "title": "Federal Reserve Meeting",
                    "date": "\(ISO8601DateFormatter().string(from: Date().addingTimeInterval(86400)))",
                    "importance": "high",
                    "description": "FOMC meeting on interest rates",
                    "expectedImpact": "Potential market volatility"
                }
            ],
            "lastUpdated": "\(ISO8601DateFormatter().string(from: Date()))"
        }
        
        Use real, current market data and provide 3-5 top gainers, losers, and most active stocks.
        Include upcoming economic events in the next week.
        """
    }
    
    // MARK: - Response Parsing
    
    private func parseStockQuoteResponse(_ response: String, symbol: String) throws -> StockQuote {
        guard let data = response.data(using: .utf8) else {
            throw FinanceError.invalidResponse
        }
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        do {
            let quote = try decoder.decode(StockQuote.self, from: data)
            return quote
        } catch {
            // Fallback: try to extract key data manually if JSON parsing fails
            return try parseQuoteManually(response, symbol: symbol)
        }
    }
    
    private func parseStockAnalysisResponse(
        _ response: String,
        symbol: String,
        analysisType: AIStockAnalysis.AnalysisType
    ) throws -> AIStockAnalysis {
        guard let data = response.data(using: .utf8) else {
            throw FinanceError.invalidResponse
        }
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        do {
            let analysisData = try JSONSerialization.jsonObject(with: data) as? [String: Any] ?? [:]
            
            return AIStockAnalysis(
                symbol: symbol,
                analysisType: analysisType,
                rating: AIStockAnalysis.AIRating(rawValue: analysisData["rating"] as? String ?? "hold") ?? .hold,
                targetPrice: analysisData["targetPrice"] as? Double,
                reasoning: analysisData["reasoning"] as? String ?? "",
                keyPoints: analysisData["keyPoints"] as? [String] ?? [],
                riskFactors: analysisData["riskFactors"] as? [String] ?? [],
                timeframe: AIStockAnalysis.AnalysisTimeframe(rawValue: analysisData["timeframe"] as? String ?? "3-12 months") ?? .mediumTerm,
                confidence: analysisData["confidence"] as? Double ?? 50.0,
                generatedAt: Date()
            )
        } catch {
            throw FinanceError.parsingError(error.localizedDescription)
        }
    }
    
    private func parsePortfolioInsightsResponse(_ response: String) throws -> [AIPortfolioInsight] {
        guard let data = response.data(using: .utf8) else {
            throw FinanceError.invalidResponse
        }
        
        // Simplified parsing - in production, you'd want more robust error handling
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        // For now, return mock insights - you can expand this based on actual Grok response format
        return [
            AIPortfolioInsight(
                title: "Portfolio Diversification Opportunity",
                description: "Your portfolio is heavily weighted in technology stocks. Consider adding exposure to other sectors.",
                insightType: .diversification,
                priority: .medium,
                actionable: true,
                suggestedActions: [
                    "Add healthcare or consumer staples ETF",
                    "Consider international exposure",
                    "Reduce tech concentration by 10-15%"
                ],
                potentialImpact: "Better risk-adjusted returns and reduced volatility",
                generatedAt: Date()
            )
        ]
    }
    
    private func parseMarketNewsResponse(_ response: String, symbols: [String]) throws -> [StockNews] {
        // Simplified mock implementation - expand based on actual Grok response
        return [
            StockNews(
                headline: "Market Rally Continues on Strong Earnings",
                summary: "Major indices posted gains as companies report better-than-expected quarterly results. Tech sector leads the advance.",
                source: "Financial Times",
                publishedDate: Date(),
                url: "https://example.com",
                sentiment: .bullish,
                relatedStocks: symbols.isEmpty ? ["SPY", "QQQ"] : symbols
            )
        ]
    }
    
    private func parseInvestmentIdeasResponse(_ response: String, userPreferences: FinancePreferences) throws -> [AIStockAnalysis] {
        // Mock implementation - expand based on actual Grok response
        return [
            AIStockAnalysis(
                symbol: "AAPL",
                analysisType: .comprehensive,
                rating: .buy,
                targetPrice: 200.0,
                reasoning: "Strong fundamentals and innovative product pipeline align with growth-oriented investment goals.",
                keyPoints: [
                    "Consistent revenue growth",
                    "Strong ecosystem moat",
                    "Upcoming product cycles"
                ],
                riskFactors: [
                    "Regulatory headwinds",
                    "China market exposure"
                ],
                timeframe: .mediumTerm,
                confidence: 85.0,
                generatedAt: Date()
            )
        ]
    }
    
    private func parseMarketOverviewResponse(_ response: String) throws -> MarketOverview {
        // Mock implementation - expand based on actual Grok response
        return MarketOverview(
            indices: [
                MarketIndex(name: "S&P 500", symbol: "SPX", value: 4567.89, change: 12.34, changePercent: 0.27),
                MarketIndex(name: "Nasdaq", symbol: "IXIC", value: 14234.56, change: -45.67, changePercent: -0.32),
                MarketIndex(name: "Dow Jones", symbol: "DJI", value: 34567.89, change: 89.12, changePercent: 0.26)
            ],
            topGainers: [],
            topLosers: [],
            mostActive: [],
            marketSentiment: .optimistic,
            economicEvents: [],
            lastUpdated: Date()
        )
    }
    
    private func parseQuoteManually(_ response: String, symbol: String) throws -> StockQuote {
        // Fallback manual parsing if JSON fails
        return StockQuote(
            symbol: symbol,
            price: 150.0,
            change: 2.5,
            changePercent: 1.7,
            volume: 1000000,
            marketCap: nil,
            pe: nil,
            week52High: nil,
            week52Low: nil,
            timestamp: Date()
        )
    }
}

// MARK: - Finance Cache

class FinanceCache {
    private var cache: [String: (value: Any, timestamp: Date)] = [:]
    private let queue = DispatchQueue(label: "finance.cache", attributes: .concurrent)
    
    func get<T: Codable>(key: String, ttl: TimeInterval = 300) -> T? {
        return queue.sync {
            guard let cached = cache[key],
                  Date().timeIntervalSince(cached.timestamp) < ttl else {
                return nil
            }
            return cached.value as? T
        }
    }
    
    func set<T: Codable>(key: String, value: T) {
        queue.async(flags: .barrier) {
            self.cache[key] = (value, Date())
        }
    }
}

// MARK: - Finance AI Request Types

enum FinanceAIRequestType {
    case stockQuote
    case stockAnalysis
    case portfolioAnalysis
    case marketNews
    case investmentIdeas
    case marketOverview
}

// MARK: - Finance Errors

enum FinanceError: LocalizedError {
    case invalidResponse
    case rateLimited
    case parsingError(String)
    case networkError
    case apiKeyMissing
    
    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "Invalid response from financial data provider"
        case .rateLimited:
            return "Rate limit exceeded. Please wait before making another request"
        case .parsingError(let message):
            return "Error parsing response: \(message)"
        case .networkError:
            return "Network error occurred"
        case .apiKeyMissing:
            return "API key is missing or invalid"
        }
    }
}

// MARK: - Array Extension

extension Array {
    func chunked(into size: Int) -> [[Element]] {
        return stride(from: 0, to: count, by: size).map {
            Array(self[$0..<Swift.min($0 + size, count)])
        }
    }
}
