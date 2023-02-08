//
//  LaunchingInteractable.swift
//  
//
//  Created by SwiftMan on 2023/01/31.
//

import LaunchingService

public protocol LaunchingInteractable: AnyObject {
  func fetchLaunchingConfig() async throws -> AppUpdateStatus
}
