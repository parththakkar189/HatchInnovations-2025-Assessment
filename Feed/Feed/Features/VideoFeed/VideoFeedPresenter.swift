//
//  VideoFeedPresenter.swift
//  Feed
//
//  Created by Parth Thakkar on 2025-10-23.
//

import Foundation
import Combine

@MainActor
final class VideoFeedPresenter: ObservableObject {
  @Published private(set) var videos: [Video] = []
  @Published private(set) var isLoading = false
  @Published private(set) var error: String?
  @Published var currentIndex: Int = 0
  
  private let networkService: NetworkServiceProtocol
  private let playerManager: VideoPlayerManagerProtocol
  private let endpoint: String
  
  init(
    networkService: NetworkServiceProtocol,
    playerManager: VideoPlayerManagerProtocol,
    endpoint: String = ""
  ) {
    self.networkService = networkService
    self.playerManager = playerManager
    self.endpoint = endpoint
  }
  
  func loadVideos() async {
    guard !isLoading else { return }
    
    isLoading = true
    error = nil
    
    let result: Result<VideoFeedResponse, NetworkError> = await networkService.fetch(from: endpoint)
    
    switch result {
    case .success(let response):
      videos = response.videoObjects
      
      // Prefetch first 3 videos
      for video in videos.prefix(3) {
        guard let url = video.hlsURL else { continue }
        Task {
          _ = await playerManager.setupPlayer(for: video.id, url: url)
        }
      }
      
    case .failure(let networkError):
      error = networkError.errorDescription
    }
    
    isLoading = false
  }
  
  func onVideoAppear(index: Int, video: Video) {
    currentIndex = index
    
    Task {
      await playerManager.play(videoId: video.id)
      
      // Prefetch adjacent videos
      let nextIndex = index + 1
      if nextIndex < videos.count, let url = videos[nextIndex].hlsURL {
        _ = await playerManager.setupPlayer(for: videos[nextIndex].id, url: url)
      }
    }
  }
  
  func refreshVideos() async {
    playerManager.cleanup()
    videos = []
    currentIndex = 0
    await loadVideos()
  }
  
  func retryLoading() async {
    await loadVideos()
  }
}
