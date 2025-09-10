//
//  TikTokStyleVideoFeed.swift
//  Flowmate
//
//  Created on 2025-01-13
//

import SwiftUI
import AVKit

struct TikTokStyleVideoFeed: View {
    @EnvironmentObject var themeProvider: ThemeProvider
    @State private var currentVideoIndex = 0
    @State private var players: [AVPlayer] = []
    @State private var scrollOffset: CGFloat = 0
    @State private var isTabActive = true
    
    private let videoNames = ["vid1", "vid2", "vid3", "vid4"]
    
    var body: some View {
        GeometryReader { geometry in
            ScrollView(.vertical, showsIndicators: false) {
                LazyVStack(spacing: 0) {
                    ForEach(0..<videoNames.count, id: \.self) { index in
                        VideoPlayerView(
                            player: players.indices.contains(index) ? players[index] : AVPlayer(),
                            videoName: videoNames[index],
                            isCurrentVideo: index == currentVideoIndex,
                            geometry: geometry,
                            onPlayPause: { toggleVideoPlayback(at: index) }
                        )
                        .frame(width: geometry.size.width, height: geometry.size.height)
                        .background(
                            GeometryReader { itemGeometry in
                                Color.clear
                                    .onAppear {
                                        updateCurrentVideoIndex(itemGeometry: itemGeometry, containerGeometry: geometry, index: index)
                                    }
                                    .onChange(of: scrollOffset) {
                                        updateCurrentVideoIndex(itemGeometry: itemGeometry, containerGeometry: geometry, index: index)
                                    }
                            }
                        )
                    }
                }
                .background(
                    GeometryReader { scrollGeometry in
                        Color.clear
                            .onChange(of: scrollGeometry.frame(in: .global).minY) {
                                scrollOffset = $0
                            }
                    }
                )
            }
            .scrollTargetBehavior(.paging)
            .onAppear {
                setupPlayers()
                isTabActive = true
                playCurrentVideo()
            }
            .onDisappear {
                isTabActive = false
                pauseAllVideos()
            }
            .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
                if isTabActive {
                    playCurrentVideo()
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: UIApplication.didEnterBackgroundNotification)) { _ in
                pauseAllVideos()
            }
        }
        .ignoresSafeArea(.all)
    }
    
    private func updateCurrentVideoIndex(itemGeometry: GeometryProxy, containerGeometry: GeometryProxy, index: Int) {
        let itemFrame = itemGeometry.frame(in: .global)
        let containerFrame = containerGeometry.frame(in: .global)
        
        // Check if this video is currently visible (center of screen)
        let itemCenter = itemFrame.midY
        let containerCenter = containerFrame.midY
        
        if abs(itemCenter - containerCenter) < containerFrame.height / 4 {
            if currentVideoIndex != index {
                currentVideoIndex = index
                updateVideoPlayback()
            }
        }
    }
    
    private func toggleVideoPlayback(at index: Int) {
        guard players.indices.contains(index) else { return }
        
        let player = players[index]
        if player.timeControlStatus == .playing {
            player.pause()
        } else {
            // Pause all other videos first
            pauseAllVideos()
            player.play()
        }
    }
    
    private func setupPlayers() {
        players = videoNames.map { videoName in
            guard let url = VideoBundle.shared.getVideoURL(named: videoName) else {
                print("Video file not found: \(videoName).mp4")
                return AVPlayer()
            }
            let player = AVPlayer(url: url)
            
            // Loop video
            NotificationCenter.default.addObserver(
                forName: .AVPlayerItemDidPlayToEndTime,
                object: player.currentItem,
                queue: .main
            ) { _ in
                player.seek(to: .zero)
                player.play()
            }
            
            return player
        }
        
        // Play first video
        playCurrentVideo()
    }
    
    private func playCurrentVideo() {
        guard players.indices.contains(currentVideoIndex) && isTabActive else { return }
        players[currentVideoIndex].play()
    }
    
    private func pauseAllVideos() {
        players.forEach { $0.pause() }
    }
    
    private func updateVideoPlayback() {
        for (index, player) in players.enumerated() {
            if index == currentVideoIndex && isTabActive {
                player.play()
            } else {
                player.pause()
            }
        }
    }
}

struct VideoPlayerView: View {
    let player: AVPlayer
    let videoName: String
    let isCurrentVideo: Bool
    let geometry: GeometryProxy
    let onPlayPause: () -> Void
    
    @State private var isPlaying = false
    @State private var showControls = false
    
    var body: some View {
        ZStack {
            // Video Player
            VideoPlayer(player: player)
                .aspectRatio(contentMode: .fit)
                .frame(width: geometry.size.width, height: geometry.size.height)
                .background(Color.black)
            
            // Transparent tap overlay for better tap detection
            Color.clear
                .frame(width: geometry.size.width, height: geometry.size.height)
                .contentShape(Rectangle())
                .onTapGesture {
                    onPlayPause()
                    updatePlayingState()
                }
                .onLongPressGesture(minimumDuration: 0.1) {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        showControls.toggle()
                    }
                }
            
            // Gradient overlay for better text visibility
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.black.opacity(0.0),
                    Color.black.opacity(0.3),
                    Color.black.opacity(0.6)
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
            
            // Video info overlay
            VStack {
                Spacer()
                
                HStack {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Fitness Flow")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.white)
                        
                        Text("Transform your body, elevate your mind")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white.opacity(0.9))
                        
                        HStack(spacing: 12) {
                            HStack(spacing: 4) {
                                Image(systemName: "heart.fill")
                                    .foregroundColor(.red)
                                Text("\(Int.random(in: 1200...5000))")
                                    .foregroundColor(.white)
                            }
                            .font(.system(size: 14, weight: .medium))
                            
                            HStack(spacing: 4) {
                                Image(systemName: "message.fill")
                                    .foregroundColor(.white)
                                Text("\(Int.random(in: 50...300))")
                                    .foregroundColor(.white)
                            }
                            .font(.system(size: 14, weight: .medium))
                            
                            HStack(spacing: 4) {
                                Image(systemName: "arrowshape.turn.up.right.fill")
                                    .foregroundColor(.white)
                                Text("\(Int.random(in: 20...150))")
                                    .foregroundColor(.white)
                            }
                            .font(.system(size: 14, weight: .medium))
                        }
                    }
                    
                    Spacer()
                    
                    // Side actions
                    VStack(spacing: 20) {
                        ActionButton(icon: "heart", isActive: false) {
                            // Like action
                        }
                        
                        ActionButton(icon: "message", isActive: false) {
                            // Comment action
                        }
                        
                        ActionButton(icon: "arrowshape.turn.up.right", isActive: false) {
                            // Share action
                        }
                        
                        ActionButton(icon: "bookmark", isActive: false) {
                            // Save action
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 100) // Account for tab bar
            }
            
            // Play/Pause indicator
            if showControls {
                VStack {
                    Spacer()
                    
                    HStack {
                        Spacer()
                        
                        Button(action: {
                            onPlayPause()
                            updatePlayingState()
                        }) {
                            Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                                .font(.system(size: 50))
                                .foregroundColor(.white)
                                .background(
                                    Circle()
                                        .fill(Color.black.opacity(0.5))
                                        .frame(width: 80, height: 80)
                                )
                        }
                        
                        Spacer()
                    }
                    
                    Spacer()
                }
                .transition(.opacity)
            }
        }
        .onChange(of: isCurrentVideo) {
            if $0 {
                player.play()
                isPlaying = true
            } else {
                player.pause()
                isPlaying = false
            }
        }
        .onAppear {
            if isCurrentVideo {
                player.play()
                isPlaying = true
            }
        }
    }
    
    private func updatePlayingState() {
        isPlaying = player.timeControlStatus == .playing
        
        // Show controls briefly
        withAnimation(.easeInOut(duration: 0.2)) {
            showControls = true
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation(.easeInOut(duration: 0.3)) {
                showControls = false
            }
        }
    }
}

struct ActionButton: View {
    let icon: String
    let isActive: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon + (isActive ? ".fill" : ""))
                    .font(.system(size: 24, weight: .medium))
                    .foregroundColor(isActive ? .red : .white)
                    .frame(width: 44, height: 44)
                    .background(
                        Circle()
                            .fill(Color.black.opacity(0.3))
                    )
            }
        }
        .scaleEffect(isActive ? 1.1 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isActive)
    }
}

#Preview {
    TikTokStyleVideoFeed()
        .environmentObject(ThemeProvider())
}
