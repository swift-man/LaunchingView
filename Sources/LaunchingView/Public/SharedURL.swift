//
//  SharedURL.swift
//  
//
//  Created by SwiftMan on 2023/02/08.
//

import SwiftUI

/// Open URL macOS and iOS
@available(iOS 15.0, macOS 12, *)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
public struct SharedURL: Sendable {
  public static let shared = SharedURL()
  private init() {}
  
  public func open(_ url: URL) {
    Task { @MainActor in
      EnvironmentValues().openURL(url)
    }
  }
}
