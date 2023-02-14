//
//  File.swift
//  
//
//  Created by SwiftMan on 2023/02/11.
//

import Foundation
import Dependencies
import LaunchingService

@available(iOS 15.0, macOS 12, *)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
extension LaunchingService: DependencyKey {
   public static var liveValue = LaunchingService()
}

@available(iOS 15.0, macOS 12, *)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
extension DependencyValues {
  var launchingService: LaunchingService {
    get { self[LaunchingService.self] }
    set { self[LaunchingService.self] = newValue }
  }
}
