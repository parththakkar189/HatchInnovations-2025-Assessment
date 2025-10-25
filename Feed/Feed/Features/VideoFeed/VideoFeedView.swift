//
//  VideoFeedView.swift
//  Feed
//
//  Created by Parth Thakkar on 2025-10-23.
//

import SwiftUI

struct VideoFeedView: View {
  @StateObject var presenter: VideoFeedPresenter
  @State private var currentIndex: Int? = 0
  
  var body: some View {
    ZStack {
      Color.black.ignoresSafeArea()
      
      if presenter.isLoading {
        loadingView
      } else if let error = presenter.error {
        errorView(message: error)
      } else {
        videoScrollView
      }
    }
    .task {
      await presenter.loadVideos()
    }
  }
  
  private var videoScrollView: some View {
    GeometryReader { geometry in
      ScrollViewReader { proxy in
        ScrollView(.vertical, showsIndicators: false) {
          LazyVStack(spacing: 0) {
            ForEach(Array(presenter.videos.enumerated()), id: \.element.id) { index, video in
              VideoPlayerView(
                video: video,
                isVisible: currentIndex == index,
                playerManager: DIContainer.shared.videoPlayerManager
              )
              .frame(
                width: geometry.size.width,
                height: geometry.size.height
              )
              .containerRelativeFrame(.vertical)  // ✅ KEY: Full screen height
              .id(index)
            }
          }
          .scrollTargetLayout()
        }
        .scrollTargetBehavior(.paging)
        .scrollPosition(id: $currentIndex)
        .onChange(of: currentIndex) { _, newIndex in
          guard let newIndex = newIndex, newIndex < presenter.videos.count else { return }
          presenter.onVideoAppear(index: newIndex, video: presenter.videos[newIndex])
        }
        .ignoresSafeArea()
      }
    }
    .ignoresSafeArea()
  }
  
  private var loadingView: some View {
    VStack(spacing: 20) {
      ProgressView()
        .scaleEffect(1.5)
        .tint(.white)
      Text("Loading videos...")
        .foregroundColor(.white)
        .font(.headline)
    }
  }
  
  private func errorView(message: String) -> some View {
    VStack(spacing: 20) {
      Image(systemName: "exclamationmark.triangle.fill")
        .font(.system(size: 50))
        .foregroundColor(.orange)
      
      Text("Oops!")
        .font(.title)
        .foregroundColor(.white)
      
      Text(message)
        .font(.body)
        .foregroundColor(.gray)
        .multilineTextAlignment(.center)
        .padding(.horizontal, 40)
      
      Button(action: {
        Task {
          await presenter.retryLoading()
        }
      }) {
        Text("Retry")
          .font(.headline)
          .foregroundColor(.black)
          .padding(.horizontal, 40)
          .padding(.vertical, 12)
          .background(Color.white)
          .cornerRadius(25)
      }
    }
  }
}
