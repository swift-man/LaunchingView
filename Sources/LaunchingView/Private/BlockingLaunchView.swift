//
//  BlockingLaunchView.swift
//
//
//  Created by SwiftMan on 2026/05/17.
//

import SwiftUI

@available(iOS 15.0, macOS 12, *)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
struct BlockingLaunchView: View {
  let title: String
  let message: String
  let buttonTitle: String
  let linkURL: URL?
  let onButtonTapped: (URL?) -> Void

  var body: some View {
    VStack(spacing: 24) {
      Spacer(minLength: 40)

      VStack(spacing: 12) {
        Image(systemName: "exclamationmark.triangle.fill")
          .font(.system(size: 44, weight: .semibold))
          .foregroundColor(.orange)
          .accessibilityHidden(true)

        Text(title)
          .font(.title2)
          .fontWeight(.semibold)
          .multilineTextAlignment(.center)

        if !message.isEmpty {
          Text(message)
            .font(.body)
            .foregroundColor(.secondary)
            .multilineTextAlignment(.center)
        }
      }

      if linkURL != nil {
        Button {
          onButtonTapped(linkURL)
        } label: {
          Text(buttonTitle)
            .font(.headline)
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.borderedProminent)
        .controlSize(.large)
        .frame(maxWidth: 320)
      }

      Spacer(minLength: 40)
    }
    .padding(32)
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(backgroundColor)
  }

  private var backgroundColor: Color {
    #if os(iOS)
      Color(uiColor: .systemBackground)
    #elseif os(macOS)
      Color(nsColor: .windowBackgroundColor)
    #else
      Color.clear
    #endif
  }
}
