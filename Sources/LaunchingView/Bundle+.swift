//
//  Bundle+.swift
//  
//
//  Created by SwiftMan on 2023/01/31.
//

import Foundation

extension Bundle {
  public var displayName: String {
    return Bundle.main.localizedInfoDictionary?["CFBundleDisplayName"] as? String ?? ""
  }
}
