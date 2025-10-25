//
//  Video.swift
//  Feed
//
//  Created by Parth Thakkar on 2025-10-23.
//

import Foundation

struct Video: Identifiable, Hashable, Sendable {
  let id: String
  let url: String
  
  var hlsURL: URL? {
    URL(string: url)
  }
  
  init(url: String) {
    self.url = url
    self.id = UUID().uuidString
  }
}

struct VideoFeedResponse: Codable, Sendable {
  let videos: [String]
  
  var videoObjects: [Video] {
    videos.map { Video(url: $0) }
  }
}
