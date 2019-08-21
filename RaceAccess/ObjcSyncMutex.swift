//
//  ObjcSyncMutex.swift
//  RaceAccess
//
//  Created by Andrew DeClerck on 8/21/19.
//  Copyright © 2019 Andrew DeClerck. All rights reserved.
//

import Foundation

/// Basic mutex that wraps `objc_sync_enter()` and `objc_sync_exit()` calls.
public final class ObjcSyncMutex {

  public init() {}

  public func synchronized<R>(_ closure: () throws -> R) rethrows -> R {
    defer {
      objc_sync_exit(self)
    }
    objc_sync_enter(self)
    return try closure()
  }

}
