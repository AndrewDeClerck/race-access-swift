//
//  ViewController.swift
//  RaceAccess
//
//  Created by Andrew DeClerck on 8/19/19.
//  Copyright © 2019 Andrew DeClerck. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

  @IBOutlet weak var noMutexTimeLabel: UILabel!
  @IBOutlet weak var inlinedMutexTimeLabel: UILabel!
  @IBOutlet weak var noInlineTimeLabel: UILabel!
  @IBOutlet weak var syncQueueLabel: UILabel!

  private var dictionary = [String: String]()
  private var threadsCreated = 0
  private let dictionaryLock = PThreadMutex()

  private func triggerRaceCondition() {
    let queues = createQueues()
    for queue in queues {
      queue.async {
        print("Queue label: \(queue.label)")
        self.dictionary[queue.label] = "hey"
      }
    }
  }

  private func dontTriggerRaceCondition() {
    let queues = createQueues()
    for queue in queues {
      queue.async {
        self.dictionaryLock.sync_same_file {
          print("Queue label: \(queue.label)")
          self.dictionary[queue.label] = "sup"
        }
      }
    }
  }

  private func createQueues() -> [DispatchQueue] {
    var queues = [DispatchQueue]()
    for _ in 0..<24 {
      let queue = DispatchQueue.init(label: "thread_\(threadsCreated)", qos: .background, attributes: [], target: nil)
      queues.append(queue)
      threadsCreated += 1
    }
    return queues
  }

  @IBAction func tappedCrashButton() {
    triggerRaceCondition()
  }

  @IBAction func tappedDontCrashButton() {
    dontTriggerRaceCondition()
  }

  @IBAction func tappedTimeProfileButton() {
    timeNoMutex()
    timeMutexInlined()
    timeMutexNoInline()
    timeQueue()
  }

  private func timeNoMutex() {
    let noMutexStartTime = Date()
    var dict = [Int: String]()
    for i in 0..<1000000 {
      dict[i] = String(i)
    }
    let noMutexEndTime = Date()
    let truncatedTime = String(format: "%.6f", noMutexEndTime.timeIntervalSince(noMutexStartTime))
    noMutexTimeLabel.text = "Without mutex, it took: \(truncatedTime) s"
    print("Without mutex, it took: \(truncatedTime) s")
  }

  private func timeMutexInlined() {
    let mutexStartTime = Date()
    var dict = [Int: String]()
    for i in 0..<1000000 {
      dictionaryLock.sync_same_file {
        dict[i] = String(i)
      }
    }
    let mutexEndTime = Date()
    let truncatedTime = String(format: "%.6f", mutexEndTime.timeIntervalSince(mutexStartTime))
    inlinedMutexTimeLabel.text = "With mutex (inlining), it took: \(truncatedTime) s"
    print("With mutex (inlining), it took: \(truncatedTime) s")
  }

  private func timeMutexNoInline() {
    let mutexStartTime = Date()
    var dict = [Int: String]()
    for i in 0..<1000000 {
      dictionaryLock.sync {
        dict[i] = String(i)
      }
    }
    let mutexEndTime = Date()
    let truncatedTime = String(format: "%.6f", mutexEndTime.timeIntervalSince(mutexStartTime))
    noInlineTimeLabel.text = "With mutex (no inline), it took: \(truncatedTime) s"
    print("With mutex (no inline), it took: \(truncatedTime) s")
  }

  private func timeQueue() {
    //Check time it takes to do same thing w/ DispatchQueue
    let queue = DispatchQueue(label: "test_queue")
    let queueStartTime = Date()
    var dict = [Int: String]()
    for i in 0..<1000000 {
      queue.sync {
        dict[i] = String(i)
      }
    }
    let queueEndTime = Date()
    let truncatedTime = String(format: "%.6f", queueEndTime.timeIntervalSince(queueStartTime))
    syncQueueLabel.text = "With DispatchQueue, it took: \(truncatedTime) s"
    print("With DispatchQueue, it took: \(truncatedTime) s")
  }
}

private extension PThreadMutex {

  /// Performs the given closure guarded by a lock / unlock sequence of the underlying mutex
  /// Implementing this in a private extension ensures inlining, even when Whole Module Optimization is disabled for DEBUG/STAGING builds.
  func sync_same_file<R>(execute: () throws -> R) rethrows -> R {
    pthread_mutex_lock(&underlyingMutex)
    defer { pthread_mutex_unlock(&underlyingMutex) }
    return try execute()
  }
}
