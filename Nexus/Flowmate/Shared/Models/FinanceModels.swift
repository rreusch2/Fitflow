//
//  FinanceModels.swift
//  Flowmate
//
//  Created on 2025-01-13
//

import Foundation

// MARK: - Portfolio Models

struct Portfolio: Codable, Identifiable {
    let id = UUID()
    var userId: UUID
    var totalValue: Double
    var dailyChange: Double
    var dailyChangePercent: Double
    var positions: [Position]
    var lastUpdated: Date
    var riskScore: Double // 0-100
    var diversificationScore: Double // 0-100
    
    var isPositive: Bool {
        dailyChange >= 0
    }
    
    var formattedTotalValue: String {
        currencyFormatter.string(from: NSNumber(value: totalValue)) ?? "$0"
    }
    
    var formattedDailyChange: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.positivePrefix = "+"
        return formatter.string(from: NSNumber(value: dailyChange)) ?? "$0"
    }
    
    var formattedDailyChangePercent: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .percent
        formatter.minimumFractionDigits = 2
        formatter.positivePrefix = "+"
        return formatter.string(from: NSNumber(value: dailyChangePercent / 100)) ?? "0%"
    }
}

struct Position: Codable, Identifiable {
    let id = UUID()
    var symbol: String
    var name: String
    var shares: Double
    var avgCost: Double
    var currentPrice: Double
    var lastUpdated: Date
    var sector: String
    
    var totalValue: Double {
        shares * currentPrice
    }
    
    var totalGainLoss: Double {
        totalValue - (shares * avgCost)
    }
    
    var gainLossPercent: Double {
        guard avgCost > 0 else { return 0 }
        return ((currentPrice - avgCost) / avgCost) * 100
    }
    
    var isPositive: Bool {
        totalGainLoss >= 0
    }
    
    var formattedPrice: String {
        currencyFormatter.string(from: NSNumber(value: currentPrice)) ?? "$0"
    }
    
    var formattedGainLoss: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.positivePrefix = "+"
        return formatter.string(from: NSNumber(value: totalGainLoss)) ?? "$0"
    }
}

// MARK: - Stock Data Models

struct StockQuote: Codable {
    let symbol: String
    let price: Double
    let change: Double
    let changePercent: Double
    let volume: Int64
    let marketCap: Double?
    let pe: Double?
    let week52High: Double?
    let week52Low: Double?
    let timestamp: Date
    
    var isPositive: Bool {
        change >= 0
    }
    
    var formattedPrice: String {
        currencyFormatter.string(from: NSNumber(value: price)) ?? "$0"
    }
    
    var formattedChange: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.positivePrefix = "+"
        return formatter.string(from: NSNumber(value: change)) ?? "$0"
    }
    
    var formattedChangePercent: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .percent
        formatter.minimumFractionDigits = 2
        formatter.positivePrefix = "+"
        return formatter.string(from: NSNumber(value: changePercent / 100)) ?? "0%"
    }
}

struct StockNews: Codable, Identifiable {
    let id = UUID()
    let headline: String
    let summary: String
    let source: String
    let publishedDate: Date
    let url: String?
    let sentiment: NewsSentiment
    let relatedStocks: [String]
    
    enum NewsSentiment: String, Codable, CaseIterable {
        case bullish = "bullish"
        case bearish = "bearish"
        case neutral = "neutral"
        
        var color: String {
            switch self {
            case .bullish: return "green"
            case .bearish: return "red"
            case .neutral: return "gray"
            }
        }
        
        var emoji: String {
            switch self {
            case .bullish: return "🚀"
            case .bearish: return "📉"
            case .neutral: return "📰"
            }
        }
    }
}

// MARK: - AI Analysis Models

struct AIStockAnalysis: Codable, Identifiable {
    let id = UUID()
    let symbol: String
    let analysisType: AnalysisType
    let rating: AIRating
    let targetPrice: Double?
    let reasoning: String
    let keyPoints: [String]
    let riskFactors: [String]
    let timeframe: AnalysisTimeframe
    let confidence: Double // 0-100
    let generatedAt: Date
    
    enum AnalysisType: String, Codable, CaseIterable {
        case technical = "technical"
        case fundamental = "fundamental"
        case sentiment = "sentiment"
        case comprehensive = "comprehensive"
        
        var displayName: String {
            switch self {
            case .technical: return "Technical Analysis"
            case .fundamental: return "Fundamental Analysis"
            case .sentiment: return "Sentiment Analysis"
            case .comprehensive: return "Comprehensive Analysis"
            }
        }
        
        var icon: String {
            switch self {
            case .technical: return "chart.line.uptrend.xyaxis"
            case .fundamental: return "building.columns"
            case .sentiment: return "brain.head.profile"
            case .comprehensive: return "scope"
            }
        }
    }
    
    enum AIRating: String, Codable, CaseIterable {
        case strongBuy = "strong_buy"
        case buy = "buy"
        case hold = "hold"
        case sell = "sell"
        case strongSell = "strong_sell"
        
        var displayName: String {
            switch self {
            case .strongBuy: return "Strong Buy"
            case .buy: return "Buy"
            case .hold: return "Hold"
            case .sell: return "Sell"
            case .strongSell: return "Strong Sell"
            }
        }
        
        var color: String {
            switch self {
            case .strongBuy: return "green"
            case .buy: return "mint"
            case .hold: return "yellow"
            case .sell: return "orange"
            case .strongSell: return "red"
            }
        }
        
        var emoji: String {
            switch self {
            case .strongBuy: return "🚀"
            case .buy: return "📈"
            case .hold: return "⏸️"
            case .sell: return "📉"
            case .strongSell: return "🔻"
            }
        }
    }
    
    enum AnalysisTimeframe: String, Codable, CaseIterable {
        case shortTerm = "1-3 months"
        case mediumTerm = "3-12 months"
        case longTerm = "1-5 years"
        
        var displayName: String {
            return self.rawValue
        }
    }
}

struct AIPortfolioInsight: Codable, Identifiable {
    let id = UUID()
    let title: String
    let description: String
    let insightType: InsightType
    let priority: Priority
    let actionable: Bool
    let suggestedActions: [String]
    let potentialImpact: String
    let generatedAt: Date
    
    enum InsightType: String, Codable, CaseIterable {
        case diversification = "diversification"
        case riskManagement = "risk_management"
        case taxOptimization = "tax_optimization"
        case rebalancing = "rebalancing"
        case performance = "performance"
        case marketOpportunity = "market_opportunity"
        
        var displayName: String {
            switch self {
            case .diversification: return "Diversification"
            case .riskManagement: return "Risk Management"
            case .taxOptimization: return "Tax Optimization"
            case .rebalancing: return "Rebalancing"
            case .performance: return "Performance"
            case .marketOpportunity: return "Market Opportunity"
            }
        }
        
        var icon: String {
            switch self {
            case .diversification: return "chart.pie"
            case .riskManagement: return "shield.checkered"
            case .taxOptimization: return "percent"
            case .rebalancing: return "arrow.triangle.2.circlepath"
            case .performance: return "chart.bar"
            case .marketOpportunity: return "lightbulb"
            }
        }
        
        var color: String {
            switch self {
            case .diversification: return "blue"
            case .riskManagement: return "red"
            case .taxOptimization: return "green"
            case .rebalancing: return "orange"
            case .performance: return "purple"
            case .marketOpportunity: return "yellow"
            }
        }
    }
    
    enum Priority: String, Codable, CaseIterable {
        case low = "low"
        case medium = "medium"
        case high = "high"
        case urgent = "urgent"
        
        var color: String {
            switch self {
            case .low: return "gray"
            case .medium: return "blue"
            case .high: return "orange"
            case .urgent: return "red"
            }
        }
    }
}

// MARK: - Market Data Models

struct MarketOverview: Codable {
    let indices: [MarketIndex]
    let topGainers: [StockQuote]
    let topLosers: [StockQuote]
    let mostActive: [StockQuote]
    let marketSentiment: MarketSentiment
    let economicEvents: [EconomicEvent]
    let lastUpdated: Date
    
    enum MarketSentiment: String, Codable, CaseIterable {
        case fearful = "fearful"
        case cautious = "cautious"
        case neutral = "neutral"
        case optimistic = "optimistic"
        case greedy = "greedy"
        
        var displayName: String {
            return rawValue.capitalized
        }
        
        var color: String {
            switch self {
            case .fearful: return "red"
            case .cautious: return "orange"
            case .neutral: return "gray"
            case .optimistic: return "green"
            case .greedy: return "purple"
            }
        }
        
        var emoji: String {
            switch self {
            case .fearful: return "😨"
            case .cautious: return "🤔"
            case .neutral: return "😐"
            case .optimistic: return "😊"
            case .greedy: return "🤑"
            }
        }
    }
}

struct MarketIndex: Codable, Identifiable {
    let id = UUID()
    let name: String
    let symbol: String
    let value: Double
    let change: Double
    let changePercent: Double
    
    var isPositive: Bool {
        change >= 0
    }
    
    var formattedValue: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 2
        return formatter.string(from: NSNumber(value: value)) ?? "0"
    }
    
    var formattedChange: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.positivePrefix = "+"
        formatter.maximumFractionDigits = 2
        return formatter.string(from: NSNumber(value: change)) ?? "0"
    }
}

struct EconomicEvent: Codable, Identifiable {
    let id = UUID()
    let title: String
    let date: Date
    let importance: EventImportance
    let description: String
    let expectedImpact: String
    
    enum EventImportance: String, Codable, CaseIterable {
        case low = "low"
        case medium = "medium"
        case high = "high"
        
        var color: String {
            switch self {
            case .low: return "gray"
            case .medium: return "orange"
            case .high: return "red"
            }
        }
    }
}

// MARK: - Watchlist Models

struct Watchlist: Codable, Identifiable {
    let id = UUID()
    var name: String
    var stocks: [String] // Stock symbols
    var createdAt: Date
    var userId: UUID
    
    static let defaultLists = [
        "My Portfolio",
        "Tech Stocks",
        "Dividend Stocks", 
        "Growth Stocks",
        "Value Plays"
    ]
}

// MARK: - Helper Formatters

private let currencyFormatter: NumberFormatter = {
    let formatter = NumberFormatter()
    formatter.numberStyle = .currency
    formatter.maximumFractionDigits = 2
    return formatter
}()

// MARK: - Finance Preferences

struct FinancePreferences: Codable {
    var riskTolerance: RiskTolerance = .moderate
    var investmentGoals: [InvestmentGoal] = []
    var preferredSectors: [String] = []
    var portfolioSize: PortfolioSize = .medium
    var tradingExperience: TradingExperience = .intermediate
    
    enum RiskTolerance: String, Codable, CaseIterable {
        case conservative = "conservative"
        case moderate = "moderate"
        case aggressive = "aggressive"
        
        var displayName: String {
            return rawValue.capitalized
        }
        
        var description: String {
            switch self {
            case .conservative: return "Minimize risk, steady growth"
            case .moderate: return "Balanced risk and return"
            case .aggressive: return "Higher risk, higher reward"
            }
        }
    }
    
    enum InvestmentGoal: String, Codable, CaseIterable {
        case retirement = "retirement"
        case wealth = "wealth_building"
        case income = "income_generation"
        case speculation = "speculation"
        
        var displayName: String {
            switch self {
            case .retirement: return "Retirement Planning"
            case .wealth: return "Wealth Building"
            case .income: return "Income Generation"
            case .speculation: return "Active Trading"
            }
        }
    }
    
    enum PortfolioSize: String, Codable, CaseIterable {
        case small = "under_10k"
        case medium = "10k_100k"
        case large = "100k_1m"
        case institutional = "over_1m"
        
        var displayName: String {
            switch self {
            case .small: return "Under $10K"
            case .medium: return "$10K - $100K"
            case .large: return "$100K - $1M"
            case .institutional: return "Over $1M"
            }
        }
    }
    
    enum TradingExperience: String, Codable, CaseIterable {
        case beginner = "beginner"
        case intermediate = "intermediate"
        case advanced = "advanced"
        case professional = "professional"
        
        var displayName: String {
            return rawValue.capitalized
        }
    }
}
