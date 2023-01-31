//
//  AppVersionInteractable.swift
//  
//
//  Created by SwiftMan on 2023/01/31.
//

import AppVersionService

public protocol AppVersionInteractable: AnyObject {
  func fetchAppVersion() async throws -> ResultAppVersion
}
