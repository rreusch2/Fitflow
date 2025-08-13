//
//  FeedService.swift
//  Fitflow
//
//  Created on 2025-01-13
//

import Foundation

@MainActor
final class FeedService: ObservableObject {
    static let shared = FeedService()
    private init() {}

    private let ai = AIService.shared
    private let imageProvider: ImageProvider = MockImageProvider()

    func getTodayFeed(for user: User, desiredCount: Int = 6) async -> [FeedItem] {
        do {
            // Generate items (text + placeholder image)
            var items = try await ai.generateDailyFeedItems(for: user, count: desiredCount)
            // Optionally swap images from provider (later we’ll call backend)
            for idx in items.indices {
                if let url = await imageProvider.generateImageURL(topic: items[idx].topicTags.first ?? "mindset", vibe: items[idx].style ?? "calm") {
                    items[idx] = FeedItem(
                        id: items[idx].id,
                        userId: items[idx].userId,
                        date: items[idx].date,
                        kind: items[idx].kind,
                        title: items[idx].title,
                        text: items[idx].text,
                        imageUrl: url.absoluteString,
                        videoUrl: items[idx].videoUrl,
                        topicTags: items[idx].topicTags,
                        style: items[idx].style,
                        createdAt: items[idx].createdAt
                    )
                }
            }
            return items
        } catch {
            return []
        }
    }
}

// MARK: - Image Providers

protocol ImageProvider {
    func generateImageURL(topic: String, vibe: String) async -> URL?
}

/// For development/testing. Generates stable placeholder URLs.
struct MockImageProvider: ImageProvider {
    func generateImageURL(topic: String, vibe: String) async -> URL? {
        let seed = "\(topic)-\(vibe)-\(Int(Date().timeIntervalSince1970 / 86400))"
        return URL(string: "https://picsum.photos/seed/\(seed)/1024/1024")
    }
}

/// Backend provider stub (Supabase Edge Function) that will call OpenAI gpt-image-1
struct BackendImageProvider: ImageProvider {
    func generateImageURL(topic: String, vibe: String) async -> URL? {
        guard let url = URL(string: Config.Environment.current.baseURL + Config.Endpoints.generateImage) else { return nil }
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let body: [String: String] = ["topic": topic, "vibe": vibe]
        req.httpBody = try? JSONSerialization.data(withJSONObject: body)
        do {
            let (data, response) = try await URLSession.shared.data(for: req)
            guard let http = response as? HTTPURLResponse, http.statusCode == 200 else { return nil }
            if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
               let urlString = json["imageUrl"] as? String,
               let imageURL = URL(string: urlString) { return imageURL }
            return nil
        } catch {
            return nil
        }
    }
}


