//
//  LaunchScreenView.swift
//  Feed
//
//  Created by Parth Thakkar on 2025-10-23.
//

import SwiftUI

struct LaunchScreenView: View {
  @State private var scale: CGFloat = 0.7
  @State private var opacity: Double = 0.5
  
  var body: some View {
    ZStack {
      LinearGradient(
        gradient: Gradient(colors: [.black, .gray.opacity(0.8)]),
        startPoint: .top,
        endPoint: .bottom
      )
      .ignoresSafeArea()
      
      VStack(spacing: 24) {
        Image(systemName: "play.rectangle.fill")
          .resizable()
          .scaledToFit()
          .frame(width: 120, height: 120)
          .foregroundColor(.white)
          .scaleEffect(scale)
          .opacity(opacity)
        
        Text("Video Feed")
          .font(.system(size: 36, weight: .bold, design: .rounded))
          .foregroundColor(.white)
          .opacity(opacity)

        Text("Infinite Video Experience")
          .font(.system(size: 16, weight: .medium))
          .foregroundColor(.white.opacity(0.8))
          .opacity(opacity)
      }
    }
    .onAppear {
      withAnimation(.easeInOut(duration: 1.2)) {
        scale = 1.0
        opacity = 1.0
      }
    }
  }
}

#Preview {
  LaunchScreenView()
}
