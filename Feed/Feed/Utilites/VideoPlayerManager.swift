//
//  VideoPlayerManagerProtocol.swift
//  Feed
//
//  Created by Parth Thakkar on 2025-10-25.
//

import AVFoundation
import Combine
import Foundation

@MainActor
protocol VideoPlayerManagerProtocol: Sendable {
  func setupPlayer(for videoId: String, url: URL) async -> AVPlayer?
  func play(videoId: String) async
  func pause(videoId: String) async
  func cleanup()
}

@MainActor
final class VideoPlayerManager: VideoPlayerManagerProtocol {
  private var players: [String: AVPlayer] = [:]
  private var loopObservers: [String: NSObjectProtocol] = [:]
  private var currentlyPlayingId: String?
  private var setupInProgress: Set<String> = []
  
  init() {
    configureAudioSession()
  }
  
  private func configureAudioSession() {
    do {
      try AVAudioSession.sharedInstance().setCategory(
        .playback,
        mode: .moviePlayback,
        options: [.mixWithOthers]
      )
      try AVAudioSession.sharedInstance().setActive(true)
    } catch {
    }
  }
  
  func setupPlayer(for videoId: String, url: URL) async -> AVPlayer? {
    // Return existing player if already set up
    if let existingPlayer = players[videoId] {
      return existingPlayer
    }
    
    // Prevent concurrent setup
    guard !setupInProgress.contains(videoId) else {
      while setupInProgress.contains(videoId) {
        try? await Task.sleep(nanoseconds: 100_000_000)
      }
      return players[videoId]
    }
    
    setupInProgress.insert(videoId)
    defer { setupInProgress.remove(videoId) }
    

    let asset = AVURLAsset(url: url)
    let playerItem = AVPlayerItem(asset: asset)

    do {
      if let audioGroup = try await asset.loadMediaSelectionGroup(for: .audible) {
        playerItem.select(nil, in: audioGroup)
      }
    } catch {
    }

    playerItem.preferredForwardBufferDuration = 2.0
    
  
    let player = AVPlayer(playerItem: playerItem)
    player.isMuted = true
    player.volume = 0.0
    player.automaticallyWaitsToMinimizeStalling = true
    player.allowsExternalPlayback = false
    

    players[videoId] = player
    

    setupLooping(for: videoId, player: player)

    var attempts = 0
    while attempts < 30 {
      if let item = player.currentItem {
        if item.status == .readyToPlay {
          return player
        } else if item.status == .failed {
          players.removeValue(forKey: videoId)
          loopObservers.removeValue(forKey: videoId)
          return nil
        }
      }
      try? await Task.sleep(nanoseconds: 100_000_000)
      attempts += 1
    }
    
    return player
  }

  private func setupLooping(for videoId: String, player: AVPlayer) {
    let observer = NotificationCenter.default.addObserver(
      forName: .AVPlayerItemDidPlayToEndTime,
      object: player.currentItem,
      queue: .main
    ) { [weak player] _ in
      player?.seek(to: .zero) { finished in
        if finished {
          player?.play()
        }
      }
    }
    
    loopObservers[videoId] = observer
  }
  
  func play(videoId: String) async {
    for (id, player) in players where id != videoId {
      player.pause()
    }
    
    if let player = players[videoId] {
      currentlyPlayingId = videoId
      player.play()
    }
  }
  
  func pause(videoId: String) async {
    players[videoId]?.pause()
    if currentlyPlayingId == videoId {
      currentlyPlayingId = nil
    }
  }
  
  func cleanup() {
    // Remove all observers
    for observer in loopObservers.values {
      NotificationCenter.default.removeObserver(observer)
    }
    loopObservers.removeAll()
    
    // Cleanup players
    for player in players.values {
      player.pause()
      player.replaceCurrentItem(with: nil)
    }
    players.removeAll()
  }
}
