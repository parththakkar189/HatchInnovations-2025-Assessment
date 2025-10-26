//
//  MessageInputBar.swift
//  Feed
//
//  Created by Parth Thakkar on 2025-10-25.
//

import SwiftUI

struct MessageInputBar: View {
  @Binding var text: String
  @Binding var isFocused: Bool
  let onSend: () -> Void
  let onHeartTap: () -> Void
  let onShareTap: () -> Void
  
  @FocusState private var isTextFieldFocused: Bool
  
  private let inputHeight: CGFloat = 44
  
  var body: some View {
    HStack(alignment: .center, spacing: 12) {
      // Text Input Field with Send Button Inside
      ZStack(alignment: .bottomTrailing) {
        TextField("Send Message", text: $text, axis: .vertical)
          .focused($isTextFieldFocused)
          .lineLimit(1...5)
          .textFieldStyle(.plain)
          .font(.system(size: 17))
          .foregroundColor(.white)
          .tint(.white)
          .submitLabel(.return)
          .autocorrectionDisabled()
          .textInputAutocapitalization(.sentences)
          .padding(.leading, 16)
          .padding(.trailing, isTextFieldFocused && !text.isEmpty ? 52 : 16)
          .padding(.vertical, 12)
          .frame(minHeight: inputHeight)
          .background(
            RoundedRectangle(cornerRadius: 22)
              .fill(Color.white.opacity(0.2))
              .overlay(
                RoundedRectangle(cornerRadius: 22)
                  .stroke(Color.white.opacity(0.1), lineWidth: 1)
              )
          )
        
        // Send Button Inside at Trailing
        if isTextFieldFocused && !text.isEmpty {
          Button(action: {
            onSend()
            isTextFieldFocused = false
          }) {
            Image(systemName: "paperplane")
              .font(.system(size: 18, weight: .semibold))
              .foregroundColor(.white)
              .frame(width: 36, height: 36)
          }
          .padding(.trailing, 8)
          .transition(.identity)
        }
      }
      
      // Reaction Buttons (Outside, only when not focused)
      if !isTextFieldFocused {
        HStack(spacing: 16) {
          Button(action: onHeartTap) {
            Image(systemName: "heart")
              .font(.system(size: 26, weight: .regular))
              .foregroundColor(.white)
              .frame(width: 44, height: 44)
          }
          
          Button(action: onShareTap) {
            Image(systemName: "paperplane")
              .font(.system(size: 26, weight: .regular))
              .foregroundColor(.white)
              .frame(width: 44, height: 44)
          }
        }
        .transition(.identity)
      }
    }
    .padding(.horizontal, 16)
    .padding(.vertical, 10)
    .onChange(of: isTextFieldFocused) { _, focused in
      isFocused = focused
      if !focused {
        text = ""
      }
    }
    .onChange(of: isFocused) { _, focused in
      if !focused {
        isTextFieldFocused = false
      }
    }
  }
}
