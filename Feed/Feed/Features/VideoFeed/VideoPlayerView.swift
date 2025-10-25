//
//  VideoPlayerView.swift
//  Feed
//
//  Created by Parth Thakkar on 2025-10-23.
//

import SwiftUI
import AVKit
import Combine

struct VideoPlayerView: View {
  let video: Video
  let isVisible: Bool
  let playerManager: VideoPlayerManagerProtocol
  
  @State private var player: AVPlayer?
  @State private var isLoading = true
  @State private var hasError = false
  
  var body: some View {
    ZStack {
      Color.black
      
      if let player = player, !isLoading {
        CustomVideoPlayer(player: player)
          .ignoresSafeArea()
      } else if hasError {
        errorView
      } else {
        loadingView
      }
    }
    .task(id: video.id) {
      await setupAndPlay()
    }
    .onChange(of: isVisible) { _, visible in
      if visible {
        player?.play()
      } else {
        player?.pause()
      }
    }
  }
  
  private var loadingView: some View {
    VStack(spacing: 16) {
      ProgressView()
        .scaleEffect(1.5)
        .tint(.white)
      Text("Loading...")
        .foregroundColor(.white)
    }
  }
  
  private var errorView: some View {
    VStack(spacing: 16) {
      Image(systemName: "exclamationmark.triangle.fill")
        .font(.system(size: 50))
        .foregroundColor(.orange)
      Text("Unable to load video")
        .foregroundColor(.white)
    }
  }
  
  private func setupAndPlay() async {
    guard let url = video.hlsURL else {
      hasError = true
      return
    }
    
    if let setupPlayer = await playerManager.setupPlayer(for: video.id, url: url) {
      await MainActor.run {
        self.player = setupPlayer
        self.isLoading = false
      }
      
      if isVisible {
        await playerManager.play(videoId: video.id)
      }
    } else {
      await MainActor.run {
        self.hasError = true
        self.isLoading = false
      }
    }
  }
}
