//
//  FeedTests.swift
//  FeedTests
//
//  Created by Parth Thakkar on 2025-10-23.
//

import XCTest
import AVFoundation
@testable import Feed

// MARK: - Mock Video Player Manager

@MainActor
final class MockVideoPlayerManager: VideoPlayerManagerProtocol {
  var setupPlayerCallCount = 0
  var playCallCount = 0
  var pauseCallCount = 0
  var cleanupCallCount = 0
  
  var lastSetupVideoId: String?
  var lastSetupURL: URL?
  var lastPlayedVideoId: String?
  var lastPausedVideoId: String?
  
  var shouldReturnPlayer = true
  var mockPlayer: AVPlayer?
  
  func setupPlayer(for videoId: String, url: URL) async -> AVPlayer? {
    setupPlayerCallCount += 1
    lastSetupVideoId = videoId
    lastSetupURL = url
    
    if shouldReturnPlayer {
      let player = mockPlayer ?? AVPlayer()
      return player
    }
    return nil
  }
  
  func play(videoId: String) async {
    playCallCount += 1
    lastPlayedVideoId = videoId
  }
  
  func pause(videoId: String) async {
    pauseCallCount += 1
    lastPausedVideoId = videoId
  }
  
  func cleanup() {
    cleanupCallCount += 1
  }
}
