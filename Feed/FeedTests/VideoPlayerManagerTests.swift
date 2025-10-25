//
//  VideoPlayerManagerTests.swift
//  Feed
//
//  Created by Parth on 2025-10-25.
//


import XCTest
import AVFoundation
@testable import Feed

// MARK: - VideoPlayerManager Tests

@MainActor
final class VideoPlayerManagerTests: XCTestCase {
  var playerManager: VideoPlayerManager!
  
  override func setUp() {
    super.setUp()
    playerManager = VideoPlayerManager()
  }
  
  override func tearDown() {
    playerManager.cleanup()
    playerManager = nil
    super.tearDown()
  }
  
  // MARK: - Happy Path Tests
  
  func testSetupPlayer_ValidURL_ReturnsPlayer() async {
    // Given
    let videoId = "test-video-1"
    // Using Apple's sample HLS stream for reliable testing
    let url = URL(string: "https://devstreaming-cdn.apple.com/videos/streaming/examples/img_bipbop_adv_example_fmp4/master.m3u8")!
    
    // When
    let player = await playerManager.setupPlayer(for: videoId, url: url)
    
    // Then
    XCTAssertNotNil(player, "Player manager should return a player.")
    if let player = player {
      XCTAssertTrue(player.isMuted, "Player should be muted by default.")
      XCTAssertEqual(player.volume, 0.0, "Player volume should be 0.0.")
    }
  }
  
  func testSetupPlayer_SameVideoIdTwice_ReturnsSamePlayer() async {
    // Given
    let videoId = "test-video-1"
    // Using Apple's sample HLS stream for reliable testing
    let url = URL(string: "https://devstreaming-cdn.apple.com/videos/streaming/examples/img_bipbop_adv_example_fmp4/master.m3u8")!
    
    // When
    let player1 = await playerManager.setupPlayer(for: videoId, url: url)
    let player2 = await playerManager.setupPlayer(for: videoId, url: url)
    
    // Then
    XCTAssertNotNil(player1, "First player setup should return a player.")
    XCTAssertNotNil(player2, "Second player setup should return a player.")
    if player1 != nil && player2 != nil {
      XCTAssertTrue(player1 === player2, "Player manager should return the same player instance for the same video ID.")
    }
  }
  
  func testSetupPlayer_DifferentVideoIds_ReturnsDifferentPlayers() async {
    // Given
    let videoId1 = "test-video-1"
    let videoId2 = "test-video-2"
    // Using Apple's sample HLS streams for reliable testing
    let url1 = URL(string: "https://devstreaming-cdn.apple.com/videos/streaming/examples/img_bipbop_adv_example_fmp4/master.m3u8")!
    let url2 = URL(string: "https://devstreaming-cdn.apple.com/videos/streaming/examples/bipbop_4x3/bipbop_4x3_variant.m3u8")!
    
    // When
    let player1 = await playerManager.setupPlayer(for: videoId1, url: url1)
    let player2 = await playerManager.setupPlayer(for: videoId2, url: url2)
    
    // Then
    XCTAssertNotNil(player1, "First player setup should return a player.")
    XCTAssertNotNil(player2, "Second player setup should return a player.")
    if player1 != nil && player2 != nil {
      XCTAssertFalse(player1 === player2, "Player manager should return different players for different video IDs.")
    }
  }
  
  func testPlay_ValidVideoId_DoesNotThrow() async {
    // Given
    let videoId = "test-video-1"
    let url = URL(string: "https://devstreaming-cdn.apple.com/videos/streaming/examples/img_bipbop_adv_example_fmp4/master.m3u8")!
    _ = await playerManager.setupPlayer(for: videoId, url: url)
    
    // When/Then - Should not throw
    await playerManager.play(videoId: videoId)
    XCTAssertTrue(true, "Player manager should play video without throwing.")
  }
  
  func testPlay_NonExistentVideoId_DoesNotCrash() async {
    // When/Then - Should handle gracefully
    await playerManager.play(videoId: "non-existent-id")
    XCTAssertTrue(true, "Player manager should handle non-existent video ID gracefully without crashing.")
  }
  
  func testPause_ValidVideoId_DoesNotThrow() async {
    // Given
    let videoId = "test-video-1"
    let url = URL(string: "https://devstreaming-cdn.apple.com/videos/streaming/examples/img_bipbop_adv_example_fmp4/master.m3u8")!
    _ = await playerManager.setupPlayer(for: videoId, url: url)
    
    // When/Then - Should not throw
    await playerManager.pause(videoId: videoId)
    XCTAssertTrue(true, "Player manager should pause video without throwing.")
  }
  
  func testCleanup_RemovesAllPlayers() async {
    // Given
    let videoId1 = "test-video-1"
    let videoId2 = "test-video-2"
    let url1 = URL(string: "https://devstreaming-cdn.apple.com/videos/streaming/examples/img_bipbop_adv_example_fmp4/master.m3u8")!
    let url2 = URL(string: "https://devstreaming-cdn.apple.com/videos/streaming/examples/bipbop_4x3/bipbop_4x3_variant.m3u8")!
    
    _ = await playerManager.setupPlayer(for: videoId1, url: url1)
    _ = await playerManager.setupPlayer(for: videoId2, url: url2)
    
    // When
    playerManager.cleanup()
    
    // Then - Setting up same video after cleanup should create new player
    let newPlayer = await playerManager.setupPlayer(for: videoId1, url: url1)
    XCTAssertNotNil(newPlayer, "Player manager should create a new player after cleanup.")
  }
  
  func testSetupPlayer_ConcurrentCalls_DoesNotCreateDuplicates() async {
    // Given
    let videoId = "test-video-1"
    let url = URL(string: "https://devstreaming-cdn.apple.com/videos/streaming/examples/img_bipbop_adv_example_fmp4/master.m3u8")!
    
    // When - Call setup concurrently multiple times
    async let player1 = playerManager.setupPlayer(for: videoId, url: url)
    async let player2 = playerManager.setupPlayer(for: videoId, url: url)
    async let player3 = playerManager.setupPlayer(for: videoId, url: url)
    
    let results = await [player1, player2, player3]
    
    // Then - All should return the same player instance
    XCTAssertNotNil(results[0], "First concurrent call should return a player.")
    XCTAssertNotNil(results[1], "Second concurrent call should return a player.")
    XCTAssertNotNil(results[2], "Third concurrent call should return a player.")
    
    if results[0] != nil && results[1] != nil && results[2] != nil {
      XCTAssertTrue(results[0] === results[1], "Concurrent calls should return the same player instance.")
      XCTAssertTrue(results[1] === results[2], "Concurrent calls should return the same player instance.")
    }
  }
}
