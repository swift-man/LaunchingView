//
//  Bundle+.swift
//  
//
//  Created by SwiftMan on 2023/01/31.
//

import Foundation

@available(iOS 16.0, macOS 13, *)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
extension Bundle {
  public var displayName: String {
    return Bundle.main.localizedInfoDictionary?["CFBundleDisplayName"] as? String ?? ""
  }
}
