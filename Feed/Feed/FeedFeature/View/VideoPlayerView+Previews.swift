//
//  VideoPlayerView+Previews.swift
//  Feed
//
//  Created by Parth Thakkar on 2025-10-26.
//

import SwiftUI
import AVKit

// MARK: - Previews

#Preview("Loading State") {
  VideoPlayerView(
    video: Video(url: "https://cdn.dev.airxp.app/AgentVideos-HLS-Progressive/000298e8-08bc-4d79-adfc-459d7b18edad/master.m3u8"),
    isVisible: true,
    isAnyInputFocused: .constant(false),
    playerManager: MockVideoPlayerManager(shouldFail: false, loadingDelay: .infinity)
  )
}

#Preview("Playing State") {
  VideoPlayerView(
    video: Video(url: "https://cdn.dev.airxp.app/AgentVideos-HLS-Progressive/000298e8-08bc-4d79-adfc-459d7b18edad/master.m3u8"),
    isVisible: true,
    isAnyInputFocused: .constant(false),
    playerManager: MockVideoPlayerManager(shouldReturnPlayer: true, autoPlay: true)
  )
}

#Preview("Paused - Not Visible") {
  VideoPlayerView(
    video: Video(url: "https://cdn.dev.airxp.app/AgentVideos-HLS-Progressive/000298e8-08bc-4d79-adfc-459d7b18edad/master.m3u8"),
    isVisible: false,
    isAnyInputFocused: .constant(false),
    playerManager: MockVideoPlayerManager(shouldReturnPlayer: true)
  )
}

#Preview("Error State") {
  VideoPlayerView(
    video: Video(url: "invalid-url"),
    isVisible: true,
    isAnyInputFocused: .constant(false),
    playerManager: MockVideoPlayerManager(shouldFail: true)
  )
}

// MARK: - Mock Video Player Manager

class MockVideoPlayerManager: VideoPlayerManagerProtocol {
  var shouldReturnPlayer: Bool
  var shouldFail: Bool
  var autoPlay: Bool
  var loadingDelay: TimeInterval
  private var players: [String: AVPlayer] = [:]
  
  init(
    shouldReturnPlayer: Bool = true,
    shouldFail: Bool = false,
    autoPlay: Bool = false,
    loadingDelay: TimeInterval = 0.5
  ) {
    self.shouldReturnPlayer = shouldReturnPlayer
    self.shouldFail = shouldFail
    self.autoPlay = autoPlay
    self.loadingDelay = loadingDelay
  }
  
  func setupPlayer(for videoId: String, url: URL) async -> AVPlayer? {
    if loadingDelay.isFinite {
      try? await Task.sleep(nanoseconds: UInt64(loadingDelay * 1_000_000_000))
    } else {
      try? await Task.sleep(nanoseconds: .max)
      return nil
    }
    
    if shouldFail {
      return nil
    }
    
    if shouldReturnPlayer {
      if let existingPlayer = players[videoId] {
        return existingPlayer
      }

      let player = AVPlayer(url: url)
      players[videoId] = player

      if autoPlay {
        await MainActor.run {
          player.play()
        }
      }

      return player
    }

    return nil
  }
  
  func play(videoId: String) async {
    await MainActor.run {
      players[videoId]?.play()
    }
  }
  
  func pause(videoId: String) {
    players[videoId]?.pause()
  }
  
  func cleanup(videoId: String) {
    players[videoId]?.pause()
    players[videoId] = nil
  }
  
  func cleanup() {
    for player in players.values {
      player.pause()
    }
    players.removeAll()
  }
}
