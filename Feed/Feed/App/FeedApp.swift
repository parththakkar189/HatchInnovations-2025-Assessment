//
//  FeedApp.swift
//  Feed
//
//  Created by Parth Thakkar on 2025-10-23.
//

import AVKit
import SwiftUI

@main
struct FeedApp: App {
  @State private var showSplashScreen = true
  private let container = DIContainer.shared
  
  init() {
    setupAudioSession()
    if #available(iOS 16.0, *) {
      UserDefaults.standard.set(false, forKey: "VKCImageAnalysisInteractionEnabled")
    }
  }
  
  var body: some Scene {
    WindowGroup {
      ZStack {
        // Main Content
        container.makeVideoFeedView()
          .opacity(showSplashScreen ? 0 : 1)
        
        // Splash Screen Overlay
        if showSplashScreen {
          LaunchScreenView()
            .transition(.opacity)
            .zIndex(1)
            .onAppear {
              // Hide splash screen after 2 seconds
              DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                withAnimation(.easeOut(duration: 0.5)) {
                  showSplashScreen = false
                }
              }
            }
        }
      }
    }
  }
  
  private func setupAudioSession() {
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
}
