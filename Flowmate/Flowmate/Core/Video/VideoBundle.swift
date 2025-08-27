//
//  VideoBundle.swift
//  Flowmate
//
//  Created on 2025-01-13
//

import Foundation
import AVFoundation

class VideoBundle {
    static let shared = VideoBundle()
    
    private init() {}
    
    func getVideoURL(named videoName: String) -> URL? {
        // First try to find in main bundle
        if let bundleURL = Bundle.main.url(forResource: videoName, withExtension: "mp4") {
            return bundleURL
        }
        
        // If not in bundle, try to find in Resources folder
        let resourcesPath = Bundle.main.resourcePath ?? ""
        let videoPath = "\(resourcesPath)/Videos/\(videoName).mp4"
        
        if FileManager.default.fileExists(atPath: videoPath) {
            return URL(fileURLWithPath: videoPath)
        }
        
        // Try alternative paths
        let alternativePaths = [
            "\(resourcesPath)/\(videoName).mp4",
            Bundle.main.bundlePath + "/Videos/\(videoName).mp4",
            Bundle.main.bundlePath + "/\(videoName).mp4"
        ]
        
        for path in alternativePaths {
            if FileManager.default.fileExists(atPath: path) {
                return URL(fileURLWithPath: path)
            }
        }
        
        print("❌ Video not found: \(videoName).mp4")
        print("📁 Searched paths:")
        print("   - Bundle: \(Bundle.main.bundlePath)")
        print("   - Resources: \(resourcesPath)")
        
        return nil
    }
    
    func getAllAvailableVideos() -> [String] {
        let videoNames = ["vid1", "vid2", "vid3", "vid4"]
        return videoNames.filter { getVideoURL(named: $0) != nil }
    }
}
