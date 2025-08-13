//
//  FeedModels.swift
//  Fitflow
//
//  Created on 2025-01-13
//

import Foundation

enum FeedItemKind: String, Codable {
    case image
    case video
    case quote
}

struct FeedItem: Codable, Identifiable {
    let id: UUID
    let userId: UUID
    let date: Date
    let kind: FeedItemKind
    let title: String?
    let text: String
    let imageUrl: String?
    let videoUrl: String?
    let topicTags: [String]
    let style: String?
    let createdAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id, date, kind, title, text, style, createdAt
        case userId = "user_id"
        case imageUrl = "image_url"
        case videoUrl = "video_url"
        case topicTags = "topic_tags"
    }
}


