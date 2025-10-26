//
//  AppLifecycleManager.swift
//  Feed
//
//  Created by Parth Thakkar on 2025-10-26.
//

import SwiftUI
import Combine

/// Centralized manager for app lifecycle events
class AppLifecycleManager: ObservableObject {
  static let shared = AppLifecycleManager()
  
  @Published var isAppActive: Bool = true
  
  private var cancellables = Set<AnyCancellable>()
  
  private init() {
    setupLifecycleObservers()
  }
  
  private func setupLifecycleObservers() {
    NotificationCenter.default.publisher(for: UIApplication.willResignActiveNotification)
      .sink { [weak self] _ in
        DispatchQueue.main.async {
          self?.isAppActive = false
        }
      }
      .store(in: &cancellables)

    NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)
      .sink { [weak self] _ in
        DispatchQueue.main.async {
          self?.isAppActive = true
        }
      }
      .store(in: &cancellables)
  }
}

typealias LifecycleManager = AppLifecycleManager