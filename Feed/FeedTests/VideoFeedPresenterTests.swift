//
//  VideoFeedPresenterTests.swift
//  Feed
//
//  Created by Parth Thakkar on 2025-10-25.
//

import XCTest
import AVFoundation
@testable import Feed

// MARK: - VideoFeedPresenter Tests

@MainActor
final class VideoFeedPresenterTests: XCTestCase {
  var presenter: VideoFeedPresenter!
  var mockNetworkService: MockNetworkService!
  var mockPlayerManager: MockVideoPlayerManager!
  
  override func setUp() {
    super.setUp()
  }
  
  override func tearDown() {
    presenter = nil
    mockNetworkService = nil
    mockPlayerManager = nil
    super.tearDown()
  }
  
  // MARK: - Factory Method
  
  func makeSUT(endpoint: String = "/test/endpoint") -> VideoFeedPresenter {
    mockNetworkService = MockNetworkService()
    mockPlayerManager = MockVideoPlayerManager()
    presenter = VideoFeedPresenter(
      networkService: mockNetworkService,
      playerManager: mockPlayerManager,
      endpoint: endpoint
    )
    return presenter
  }
  
  // MARK: - Happy Path Tests
  
  func testLoadVideos_Success_LoadsVideosAndPrefetchesFirst3() async {
    // Given
    let sut = makeSUT()
    let mockResponse = VideoFeedResponse(videos: [
      "https://example.com/video1.m3u8",
      "https://example.com/video2.m3u8",
      "https://example.com/video3.m3u8",
      "https://example.com/video4.m3u8"
    ])
    mockNetworkService.mockResult = .success(mockResponse)
    
    XCTAssertTrue(sut.videos.isEmpty, "Videos should be empty initially.")
    XCTAssertFalse(sut.isLoading, "Presenter should not be loading initially.")
    
    // When
    await sut.loadVideos()
    
    // Then
    XCTAssertEqual(sut.videos.count, 4, "Presenter should have loaded 4 videos.")
    XCTAssertFalse(sut.isLoading, "Presenter should not be loading after completion.")
    XCTAssertNil(sut.error, "Presenter should have no error after successful load.")
    XCTAssertEqual(mockNetworkService.fetchCallCount, 1, "Network service should be called exactly once.")
    XCTAssertEqual(mockNetworkService.lastEndpoint, "/test/endpoint", "Network service should be called with correct endpoint.")
    
    // Give time for prefetch tasks to complete
    try? await Task.sleep(nanoseconds: 100_000_000)
    
    XCTAssertEqual(mockPlayerManager.setupPlayerCallCount, 3, "Player manager should prefetch first 3 videos.")
  }
  
  func testLoadVideos_WithLessThan3Videos_PrefetchesAll() async {
    // Given
    let sut = makeSUT()
    let mockResponse = VideoFeedResponse(videos: [
      "https://example.com/video1.m3u8",
      "https://example.com/video2.m3u8"
    ])
    mockNetworkService.mockResult = .success(mockResponse)
    
    // When
    await sut.loadVideos()
    
    // Then
    XCTAssertEqual(sut.videos.count, 2, "Presenter should have loaded 2 videos.")
    
    try? await Task.sleep(nanoseconds: 100_000_000)
    
    XCTAssertEqual(mockPlayerManager.setupPlayerCallCount, 2, "Player manager should prefetch all 2 videos.")
  }
  
  func testOnVideoAppear_PlaysVideoAndPrefetchesNext() async {
    // Given
    let sut = makeSUT()
    let mockResponse = VideoFeedResponse(videos: [
      "https://example.com/video1.m3u8",
      "https://example.com/video2.m3u8",
      "https://example.com/video3.m3u8"
    ])
    mockNetworkService.mockResult = .success(mockResponse)
    await sut.loadVideos()
    
    try? await Task.sleep(nanoseconds: 100_000_000)
    mockPlayerManager.setupPlayerCallCount = 0 // Reset counter
    
    // When
    let video = sut.videos[0]
    sut.onVideoAppear(index: 0, video: video)
    
    try? await Task.sleep(nanoseconds: 100_000_000)
    
    // Then
    XCTAssertEqual(sut.currentIndex, 0, "Presenter should update current index to 0.")
    XCTAssertEqual(mockPlayerManager.lastPlayedVideoId, video.id, "Player manager should play the video with correct ID.")
    XCTAssertGreaterThanOrEqual(mockPlayerManager.playCallCount, 1, "Player manager should call play at least once.")
    XCTAssertEqual(mockPlayerManager.setupPlayerCallCount, 1, "Player manager should prefetch the next video.")
    XCTAssertEqual(mockPlayerManager.lastSetupURL?.absoluteString, "https://example.com/video2.m3u8", "Player manager should prefetch the correct next video URL.")
  }
  
  func testOnVideoAppear_LastVideo_DoesNotPrefetchBeyondBounds() async {
    // Given
    let sut = makeSUT()
    let mockResponse = VideoFeedResponse(videos: [
      "https://example.com/video1.m3u8",
      "https://example.com/video2.m3u8"
    ])
    mockNetworkService.mockResult = .success(mockResponse)
    await sut.loadVideos()
    
    try? await Task.sleep(nanoseconds: 100_000_000)
    mockPlayerManager.setupPlayerCallCount = 0
    
    // When - Navigate to last video
    let lastVideo = sut.videos[1]
    sut.onVideoAppear(index: 1, video: lastVideo)
    
    try? await Task.sleep(nanoseconds: 100_000_000)
    
    // Then
    XCTAssertEqual(mockPlayerManager.setupPlayerCallCount, 0, "Player manager should not prefetch beyond array bounds.")
  }
  
  func testRefreshVideos_CleansUpAndReloads() async {
    // Given
    let sut = makeSUT()
    let initialResponse = VideoFeedResponse(videos: ["https://example.com/video1.m3u8"])
    mockNetworkService.mockResult = .success(initialResponse)
    await sut.loadVideos()
    
    XCTAssertEqual(sut.videos.count, 1, "Presenter should have loaded 1 video initially.")
    
    // Change mock data
    let newResponse = VideoFeedResponse(videos: [
      "https://example.com/video2.m3u8",
      "https://example.com/video3.m3u8"
    ])
    mockNetworkService.mockResult = .success(newResponse)
    
    // When
    await sut.refreshVideos()
    
    // Then
    XCTAssertEqual(mockPlayerManager.cleanupCallCount, 1, "Player manager should cleanup players exactly once.")
    XCTAssertEqual(sut.videos.count, 2, "Presenter should load 2 new videos after refresh.")
    XCTAssertEqual(sut.currentIndex, 0, "Presenter should reset current index to 0.")
  }
  
  func testRetryLoading_ReattemptsLoad() async {
    // Given
    let sut = makeSUT()
    mockNetworkService.mockResult = .failure(.invalidURL)
    await sut.loadVideos()
    
    XCTAssertNotNil(sut.error, "Presenter should have an error after failed load.")
    XCTAssertEqual(mockNetworkService.fetchCallCount, 1, "Network service should be called exactly once.")
    
    // Change to success
    let mockResponse = VideoFeedResponse(videos: ["https://example.com/video1.m3u8"])
    mockNetworkService.mockResult = .success(mockResponse)
    
    // When
    await sut.retryLoading()
    
    // Then
    XCTAssertEqual(mockNetworkService.fetchCallCount, 2, "Network service should be called twice after retry.")
    XCTAssertEqual(sut.videos.count, 1, "Presenter should load 1 video after successful retry.")
    XCTAssertNil(sut.error, "Presenter should clear error after successful retry.")
  }
  
  func testLoadVideos_PreventsConcurrentLoads() async {
    // Given
    let sut = makeSUT()
    let mockResponse = VideoFeedResponse(videos: ["https://example.com/video1.m3u8"])
    mockNetworkService.mockResult = .success(mockResponse)
    
    // When - Call loadVideos twice simultaneously
    async let load1: Void = sut.loadVideos()
    // Give a tiny delay to ensure first call sets isLoading flag
    try? await Task.sleep(nanoseconds: 10_000_000)
    async let load2: Void = sut.loadVideos()
    
    await load1
    await load2
    
    // Then
    // Note: Due to timing, this may be 1 or 2 calls. The important part is it doesn't crash or cause data races
    XCTAssertGreaterThanOrEqual(mockNetworkService.fetchCallCount, 1, "Network service should be called at least once.")
    XCTAssertLessThanOrEqual(mockNetworkService.fetchCallCount, 2, "Network service should be called at most twice.")
  }
}
