//
//  App+Ext.swift
//  pubnub-issue-file-upload
//
//  Created by Craig Lane on 5/2/22.
//

import Foundation
import SwiftUI

// MARK: Data

extension Data {
  mutating func append(string: String) {
    if let data = string.data(using: .utf8) {
      append(data)
    }
  }
}

// MARK: FileManager

//          let cachedURL = try! FileManager.default.temporaryFile(
//            using: response.fileId,
//            writing: multipartRequestData
//          )

extension FileManager {
  public func temporaryFile(
    using filename: String = UUID().uuidString, writing data: Data?, purgeExisting: Bool = false
  ) throws -> URL {
    // Background File
    let tempFileURL = temporaryDirectory.appendingPathComponent(filename)
    
    // Check if file exists for cache and return
    if fileExists(atPath: tempFileURL.path) {
      if purgeExisting {
        try removeItem(at: tempFileURL)
      } else {
        return tempFileURL
      }
    }
    
    try data?.write(to: tempFileURL)
    
    return tempFileURL
  }
}

// MARK: View

extension View {
  func expandVertical() -> some View {
    fixedSize(horizontal: false, vertical: true)
      .padding()
  }
}


