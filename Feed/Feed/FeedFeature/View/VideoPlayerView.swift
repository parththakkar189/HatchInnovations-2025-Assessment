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
  @Binding var isAnyInputFocused: Bool
  let playerManager: VideoPlayerManagerProtocol
  
  @State private var player: AVPlayer?
  @State private var isLoading = true
  @State private var hasError = false
  @State private var messageText = ""
  
  @ObservedObject private var keyboardManager = KeyboardManager.shared
  @ObservedObject private var lifecycleManager = AppLifecycleManager.shared

  var body: some View {
    ZStack {
      Color.black
        .ignoresSafeArea()
      
      if let player = player, !isLoading {
        CustomVideoPlayer(player: player)
          .ignoresSafeArea()
      } else if hasError {
        errorView
      } else {
        loadingView
      }

      if isAnyInputFocused {
        Color.clear
          .contentShape(Rectangle())
          .ignoresSafeArea()
          .onTapGesture {
            isAnyInputFocused = false
          }
      }

      VStack {
        Spacer()
        
        MessageInputBar(
          text: $messageText,
          isFocused: $isAnyInputFocused,
          onSend: {
            handleSendMessage()
          },
          onHeartTap: {
            handleHeartReaction()
          },
          onShareTap: {
            handleShare()
          }
        )
        .padding(.bottom, keyboardManager.isKeyboardVisible ? 0 : 20)
      }
      .offset(y: keyboardManager.isKeyboardVisible ? -keyboardManager.keyboardHeight : 0)
    }
    .ignoresSafeArea(.keyboard, edges: .bottom)
    .simultaneousGesture(
      DragGesture(minimumDistance: 30, coordinateSpace: .local)
        .onChanged { value in
          if abs(value.translation.height) > abs(value.translation.width) {
            if isAnyInputFocused {
              isAnyInputFocused = false
            }
          }
        }
    )
    .task(id: video.id) {
      await setupAndPlay()
    }
    .onChange(of: isVisible) { oldValue, visible in
      handleVisibilityChange(visible)
    }
    .onChange(of: isAnyInputFocused) { oldValue, focused in
      handleFocusChange(focused)
    }
    .onChange(of: lifecycleManager.isAppActive) { _, isActive in
      handleAppLifecycleChange(isActive)
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
      await MainActor.run {
        hasError = true
      }
      return
    }
    
    if let setupPlayer = await playerManager.setupPlayer(for: video.id, url: url) {
      await MainActor.run {
        self.player = setupPlayer
        self.isLoading = false
      }

      if isVisible && !isAnyInputFocused {
        await playerManager.play(videoId: video.id)
      } else {
        print("⏸️ Not playing video \(video.id) - visible: \(isVisible), focused: \(isAnyInputFocused)")
      }
    } else {
      await MainActor.run {
        self.hasError = true
        self.isLoading = false
      }
    }
  }
  
  private func handleVisibilityChange(_ visible: Bool) {
    if visible && !isAnyInputFocused {
      player?.play()
    } else {
      player?.pause()
    }

    if !visible && isAnyInputFocused {

      isAnyInputFocused = false
    }
  }
  
  private func handleFocusChange(_ focused: Bool) {
    if focused {
      player?.pause()
    } else if isVisible {
      player?.play()
    } else {
      print("⏸️ Keyboard closed but video \(video.id) not visible")
    }
  }
  
  private func handleSendMessage() {
    print("📤 Sending message: \(messageText)")
    messageText = ""
    isAnyInputFocused = false
  }
  
  private func handleHeartReaction() {
    print("❤️ Heart reaction tapped for video: \(video.id)")
  }
  
  private func handleShare() {
    print("✈️ Share tapped for video: \(video.id)")
  }
  
  // MARK: - Lifecycle Handler (Centralized)
  
  private func handleAppLifecycleChange(_ isActive: Bool) {
    if !isActive {
      if isVisible {
        player?.pause()
      }
    } else {
      if isVisible && !isAnyInputFocused {
        player?.play()
      }
    }
  }
}
