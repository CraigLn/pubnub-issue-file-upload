//
//  pubnub_issue_file_uploadApp.swift
//  pubnub-issue-file-upload
//
//  Created by Craig Lane on 4/28/22.
//

import SwiftUI

@main
struct FilUploadApp: App {
  var body: some Scene {
    WindowGroup {
      ContentView()
    }
  }
}

enum AppError: Error {
  case missingImageData
  case pubnubUploadRequestCreationFailure
  case pubnubUploadResponseCreationFailure
  case awsXMLError
}
