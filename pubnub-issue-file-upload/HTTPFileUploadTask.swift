//
//  HTTPFileUploadTask.swift
//  pubnub-issue-file-upload
//
//  Created by Craig Lane on 5/2/22.
//

import Foundation

// A File-based URL session task that uploads data to the network in a request body or directy from a file URL
public class HTTPFileUploadTask: Hashable {
  
  /// The underlying URLSessionTask that is being processed
  public private(set) var urlSessionTask: URLSessionTask
  
  var responseErrorData: Data?
  /// The body of the response
  public var responseData: Data?
  /// The  block that is called when the task completes
  public var completionBlock: ((Error?) -> Void)?
  
  /// Creates a new task based on an existing URLSessionTask and the URLSession that created it
  ///
  /// To ensure delegate events are not missed, this `init` should be used before calling `resume()` on the `URLSessionTask` for the first time
  public init(task: URLSessionTask) {
    urlSessionTask = task
  }
  
  // MARK: URLSessionTaskDelegate methods
  
  func didError(_ error: Error) {
    completionBlock?(error)
  }
  
  func didComplete() {
    // If there is response data then its an XML encoded data blob
    if let data = responseData, !data.isEmpty {
      // There isn't a native XML parser, and I don't think it's necessary to include the our code for one
      responseErrorData = data
      // Just bubble up that an error occurred
      completionBlock?(AppError.awsXMLError)
      return
    }
    
    completionBlock?(nil)
  }
  
  func didReceieve(data: Data) {
    if responseData == nil {
      responseData = data
    } else {
      responseData?.append(data)
    }
  }
  
  // MARK: Progress
  
  func updateProgress(bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
    print("\(String(describing: urlSessionTask.currentRequest?.url)) uploaded \(totalBytesWritten) of \(totalBytesExpectedToWrite)")
  }
  
  // MARK: Hashable
  
  public static func == (lhs: HTTPFileUploadTask, rhs: HTTPFileUploadTask) -> Bool {
    return lhs.urlSessionTask.taskIdentifier == rhs.urlSessionTask.taskIdentifier
  }
  
  public func hash(into hasher: inout Hasher) {
    hasher.combine(urlSessionTask.taskIdentifier)
  }
}

// MARK: - URLSessionDataDelegate

open class FileSessionUploadDelegate: NSObject, URLSessionDataDelegate {
  var tasksByIdentifier = [Int: HTTPFileUploadTask]()
  
  // MARK: URLSessionDelegate
  
  open func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
    if let error = error {
      tasksByIdentifier[task.taskIdentifier]?.didError(error)
    } else {
      tasksByIdentifier[task.taskIdentifier]?.didComplete()
    }
    // Cleanup Task After Completion
    tasksByIdentifier.removeValue(forKey: task.taskIdentifier)
  }
  
  // MARK: URLSessionDataDelegate
  
  open func urlSession(
    _ session: URLSession, task: URLSessionTask,
    didSendBodyData bytesSent: Int64, totalBytesSent: Int64, totalBytesExpectedToSend: Int64
  ) {
    tasksByIdentifier[task.taskIdentifier]?.updateProgress(
      bytesWritten: bytesSent,
      totalBytesWritten: totalBytesSent,
      totalBytesExpectedToWrite: totalBytesExpectedToSend
    )
  }
  
  open func urlSession(_: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
    (tasksByIdentifier[dataTask.taskIdentifier])?.didReceieve(data: data)
  }
}
