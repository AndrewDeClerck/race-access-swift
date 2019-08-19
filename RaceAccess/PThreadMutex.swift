//
//  PThreadMutex.swift
//  Riffsy Keyboard
//
//  Created by Andrew DeClerck on 8/15/19.
//  Copyright © 2019 Andrew DeClerck. All rights reserved.
//

import Darwin

/// A basic wrapper around the "NORMAL" `pthread_mutex_t` (a general purpose mutex). This type is a "class" type to take advantage of the "deinit" method and prevent accidental copying of the `pthread_mutex_t`.
///
/// This class is a modified version of the mutex wrapping class from and inspired by https://www.cocoawithlove.com/blog/2016/06/02/threads-and-mutexes.html.
public final class PThreadMutex {

  public var underlyingMutex = pthread_mutex_t()

  public init() {
    var attr = pthread_mutexattr_t()
    guard pthread_mutexattr_init(&attr) == 0 else {
      preconditionFailure()
    }
    pthread_mutexattr_settype(&attr, PTHREAD_MUTEX_NORMAL)
    guard pthread_mutex_init(&underlyingMutex, &attr) == 0 else {
      preconditionFailure()
    }
    pthread_mutexattr_destroy(&attr)
  }

  deinit {
    pthread_mutex_destroy(&underlyingMutex)
  }

  public func sync<R>(execute: () throws -> R) rethrows -> R {
    pthread_mutex_lock(&underlyingMutex)
    defer { pthread_mutex_unlock(&underlyingMutex) }
    return try execute()
  }
}
