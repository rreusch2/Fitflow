//
//  VideoTestView.swift
//  Flowmate
//
//  Created on 2025-01-13
//

import SwiftUI

struct VideoTestView: View {
    @State private var availableVideos: [String] = []
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Video Feed Test")
                    .font(.title)
                    .padding()
                
                if availableVideos.isEmpty {
                    Text("No videos found")
                        .foregroundColor(.red)
                } else {
                    Text("Found \(availableVideos.count) videos:")
                        .foregroundColor(.green)
                    
                    ForEach(availableVideos, id: \.self) { videoName in
                        Text("✅ \(videoName).mp4")
                            .font(.monospaced(.body)())
                    }
                }
                
                Button("Test Video Feed") {
                    // This would navigate to the video feed
                }
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(10)
                
                Spacer()
            }
            .onAppear {
                availableVideos = VideoBundle.shared.getAllAvailableVideos()
            }
            .navigationTitle("Video Test")
        }
    }
}

#Preview {
    VideoTestView()
}
