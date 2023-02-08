//
//  SharedURL.swift
//  
//
//  Created by SwiftMan on 2023/02/08.
//

import SwiftUI

/// Open URL macOS and iOS
public struct SharedURL {
  public static let shared = SharedURL()
  private init() {}
  
  public func open(_ url: URL) {
#if os(iOS)
        UIApplication.shared.open(url)
#else
        NSWorkspace.shared.open(url)
#endif
  }
}
