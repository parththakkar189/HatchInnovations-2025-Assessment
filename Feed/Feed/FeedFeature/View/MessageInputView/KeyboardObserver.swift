//
//  KeyboardManager.swift
//  Feed
//
//  Created by Parth Thakkar on 2025-10-25.
//

import SwiftUI
import Combine

/// Centralized manager for keyboard state
class KeyboardManager: ObservableObject {
  static let shared = KeyboardManager()
  
  @Published var keyboardHeight: CGFloat = 0
  @Published var isKeyboardVisible: Bool = false
  
  private var cancellables = Set<AnyCancellable>()
  
  private init() {
    setupKeyboardObservers()
  }
  
  private func setupKeyboardObservers() {
    NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)
      .compactMap { notification in
        notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect
      }
      .map { $0.height }
      .sink { [weak self] height in
        DispatchQueue.main.async {
          withAnimation(.easeOut(duration: 0.25)) {
            self?.keyboardHeight = height
            self?.isKeyboardVisible = true
          }
        }
      }
      .store(in: &cancellables)
    
    NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)
      .sink { [weak self] _ in
        DispatchQueue.main.async {
          withAnimation(.easeOut(duration: 0.25)) {
            self?.keyboardHeight = 0
            self?.isKeyboardVisible = false
          }
        }
      }
      .store(in: &cancellables)
  }
}

typealias KeyboardObserver = KeyboardManager
