//
//  File.swift
//  
//
//  Created by SwiftMan on 2023/02/11.
//

import Foundation
import Dependencies
import LaunchingService

extension LaunchingService: DependencyKey {
   public static var liveValue = LaunchingService()
}

extension DependencyValues {
  var launchingService: LaunchingService {
    get { self[LaunchingService.self] }
    set { self[LaunchingService.self] = newValue }
  }
}
