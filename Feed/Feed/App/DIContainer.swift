//
//  DIContainer.swift
//  Feed
//
//  Created by Parth Thakkar on 2025-10-23.
//

import Foundation

final class DIContainer {
  static let shared = DIContainer()
  
  private init() {}
  
  lazy var networkService: NetworkServiceProtocol = {
    let baseURL = "https://cdn.dev.airxp.app"
    return NetworkService(baseURL: baseURL)
  }()
  
  lazy var videoPlayerManager: VideoPlayerManagerProtocol = {
    return VideoPlayerManager()
  }()
  
  func makeVideoFeedView() -> VideoFeedView {
    let presenter = VideoFeedPresenter(
      networkService: networkService,
      playerManager: videoPlayerManager,
      endpoint: "/AgentVideos-HLS-Progressive/manifest.json"
    )
    
    return VideoFeedView(presenter: presenter)
  }
}
