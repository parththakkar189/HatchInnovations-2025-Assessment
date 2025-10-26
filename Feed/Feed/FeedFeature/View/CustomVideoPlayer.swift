//
//  CustomVideoPlayer.swift
//  Feed
//
//  Created by Parth on 2025-10-25.
//

import SwiftUI
import AVKit

struct CustomVideoPlayer: UIViewControllerRepresentable {
  let player: AVPlayer
  
  func makeUIViewController(context: Context) -> AVPlayerViewController {
    let controller = AVPlayerViewController()
    controller.player = player

    controller.showsPlaybackControls = false
    controller.allowsPictureInPicturePlayback = false
    controller.updatesNowPlayingInfoCenter = false
    
    controller.view.isUserInteractionEnabled = false
    
    controller.videoGravity = .resizeAspect
    
    if #available(iOS 16.0, *) {
      controller.allowsVideoFrameAnalysis = false
    }
    
    return controller
  }
  
  func updateUIViewController(_ uiViewController: AVPlayerViewController, context: Context) {
    uiViewController.view.isUserInteractionEnabled = false
  }
}
