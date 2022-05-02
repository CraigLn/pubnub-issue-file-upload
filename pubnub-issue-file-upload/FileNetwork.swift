//
//  Network.swift
//  pubnub-issue-file-upload
//
//  Created by Craig Lane on 4/29/22.
//

import UIKit

class FileNetwork {
  
  /// URLSession configuration type used
  enum SessionType: String {
    case `default`
    case background
  }
  
  /// URLSessin used when `SessionType` is `default`
  let defaultSession = URLSession(
    configuration: .default,
    delegate: FileSessionUploadDelegate(),
    delegateQueue: .main
  )
  /// URLSessin used when `SessionType` is `background`
  let backgroundSession = URLSession(
    configuration: .background(withIdentifier: "com.pubnub.file"),
    delegate: FileSessionUploadDelegate(),
    delegateQueue: .main
  )
  
  /// Upload file data using PubNub to generate a presigned [AWS S3](https://docs.aws.amazon.com/AmazonS3/latest/userguide/PresignedUrlUploadObject.html) url
  func upload(
    imageData: Data?,
    key: PubNub.Key,
    sessionType: SessionType,
    progress: @escaping ((Progress) -> Void),
    completion: @escaping ((Result<Double, Error>) -> Void)
  ) {
    
    // Validate that file data exists
    guard let imageData = imageData else {
      completion(.failure(AppError.missingImageData))
      return
    }
    
    // Determine the session based on the session type
    let session: URLSession
    switch sessionType {
    case .default:
      session = defaultSession
    case .background:
      session = backgroundSession
    }
    
    // Generate AWS presigned URL from PubNub (This request is not included in the timings)
    PubNub.generateSignedUploadURL(key: key) { result in
      switch result {
      case .success(let response):
        
        print("Using AWS URL \(response.uploadRequestURL) on \(sessionType.rawValue) session")
        
        // Create a multipart request body using Data
        var multipartRequestData = Data()
        // Set the form fields via the PubNub response
        multipartRequestData.append(
          string: response.uploadFormFields
            .map({ "--\(response.fileId)\r\nContent-Disposition: form-data; name=\"\($0.key)\"\r\n\r\n\($0.value)\r\n" })
            .joined()
        )
        // Set filename via PubNub response
        multipartRequestData.append(string: "--\(response.fileId)\r\nContent-Disposition: form-data; name=\"file\"; filename=\"\(response.filename)\"\r\n")
        multipartRequestData.append(string: "Content-Type: application/octet-stream\r\n\r\n")
        // Add File Data between boundaries
        multipartRequestData.append(imageData)
        // Create EoL for Multipart payload
        multipartRequestData.append(string: "\r\n--\(response.fileId)--")
        
        // Create multipart request
        var request = URLRequest(url: response.uploadRequestURL)
        request.httpMethod = response.uploadMethod
        request.setValue("\(multipartRequestData.count)", forHTTPHeaderField: "Content-Length")
        request.setValue("multipart/form-data; boundary=\(response.fileId)", forHTTPHeaderField: "Content-Type")
        
        // Convert PubNub Response into a URLSession Upload Task
        let task: URLSessionUploadTask
        switch sessionType {
        case .default:
          // Foreground tasks can upload directly from Data
          task = session.uploadTask(with: request, from: multipartRequestData)
        case .background:

          // Create a temporary file inside the Cache directrory
          let tempFileURL = FileManager.default.temporaryDirectory.appendingPathComponent(response.fileId)
          
          // If the file doesn't already exist, then write the data to the temp file location
          if !FileManager.default.fileExists(atPath: tempFileURL.path) {
            do {
              try multipartRequestData.write(to: tempFileURL)
            } catch {
              completion(.failure(error))
              return
            }
          }

          // Background requests require that the data be loaded from a file.
          task = session.uploadTask(with: request, fromFile: tempFileURL)
        }
        
        // Background tasks require a Delegate to be used, so use a wrapped task object to manage the
        // delegate calls
        let fileUploadTask = HTTPFileUploadTask(task: task)
        
        // Create task map inside Delegate if we're managing it
        (session.delegate as? FileSessionUploadDelegate)?.tasksByIdentifier[task.taskIdentifier] = fileUploadTask

        // Start the "Timer" by capturing the current datetime
        let timerDate: Date = Date()
        
        // Return the task `Progress` object, so it can be displayed in the UI
        progress(task.progress)
        
        // Completion Handler for task
        fileUploadTask.completionBlock = { uploadError in
          if let uploadError = uploadError {
            
            // Print out the AWS XML response if there is an error, and then use a Base64 to XML tool
            // to determine what this actually means
            if let base64String = fileUploadTask.responseErrorData?.base64EncodedString() {
              print("XML Error as Base64 \(base64String)")
            }
            
            completion(.failure(uploadError))
          } else {
            // "End" Timer by calculating the difference between when it started and now
            completion(.success(fabs((timerDate.timeIntervalSinceNow)) * 1000))
          }
          
          // Remove the finished task from out delegate tracker
          (session.delegate as? FileSessionUploadDelegate)?.tasksByIdentifier.removeValue(forKey: task.taskIdentifier)
        }

        // Start the upload
        task.resume()
  
      case .failure(let error):
        completion(.failure(error))
      }
    }
  }
}
