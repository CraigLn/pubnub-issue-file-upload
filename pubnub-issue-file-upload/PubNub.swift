//
//  PubNubFile.swift
//  pubnub-issue-file-upload
//
//  Created by Craig Lane on 4/28/22.
//

import Foundation
  
/// Encapsulation of PubNub specific configuration and logic
struct PubNub {
  
  enum Key: String {
    case usWest = "sub-c-1c91d154-3b83-11e9-b221-7a660e69c40f"
    case usEast = "sub-c-77a0ba8e-c040-11ec-b71b-82b465a2b170"
    case euCentral = "sub-c-c2c8793e-c040-11ec-b71b-82b465a2b170"
    case apacSouth = "sub-c-7b28b384-c0ed-11ec-92c7-a6fdca316470"
    
    var name: String {
      switch self {
      case .usWest:
        return "us-west"
      case .usEast:
        return "us-east"
      case .euCentral:
        return "eu-central"
      case .apacSouth:
        return "apac-south"
      }
    }
  }

  /// Channel that will be used for file upload
  static let channel = "file-test-upload-latency"
  /// UUID used when configuring PubNub request URL
  static let uuid = "user-file-latency"
  
  // Queue structure matching default inside PubNub
  static let sessionQueue = DispatchQueue(label: "com.pubnub.session.sessionQueue")
  static let operationalQueue: OperationQueue = {
    var queue = OperationQueue()
    queue.maxConcurrentOperationCount = 1
    queue.underlyingQueue = sessionQueue
    queue.name = "org.pubnub.httpClient.URLSessionReplaceableDelegate"
    return queue
  }()
  
  // Separate URLSession used only for PubNub traffic
  static let session = URLSession(configuration: .default, delegate: nil, delegateQueue: operationalQueue)
  
  /// Request that will generate an AWS download URL via PubNub for a given AWS region (based on the subscribe key)
  static func uploadRequest(_ key: Key) -> URLRequest? {
    guard
      let url = URL(string: "https://ps.pndsn.com/v1/files/\(key.rawValue)/channels/\(channel)/generate-upload-url"),
      let body = try? JSONEncoder().encode(["name": UUID().uuidString])
    else { return nil }
    
    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.httpBody = body
    return request
  }
  
  /// Network call to PubNub that will generate a response containing all the request information required to construct a presigned AWS S3 Upload Request
  static func generateSignedUploadURL(key: PubNub.Key, completion: @escaping (Result<GenerateUploadURLResponse, AppError>) -> Void ) {
    // Create PubNub Request
    guard let request = uploadRequest(key) else {
      completion(.failure(.pubnubUploadRequestCreationFailure))
      return
    }
    
    // Execute request to PubNub and respond with AWS URLRequest
    let task = session.dataTask(with: request) { data, _, _ in
      guard
        let data = data,
        let pubnubResponse = try? JSONDecoder().decode(GenerateUploadURLResponse.self, from: data)
      else {
        completion(.failure(.pubnubUploadResponseCreationFailure))
        return
      }
      
      completion(.success(pubnubResponse))
    }
    
    task.resume()
  }
}

// MARK: URL Response JSON

/// PubNub Response JSON that represents a preconfigured AWS File Upload URLRequest
struct GenerateUploadURLResponse: Codable {
  /// Status code
  let status: Int
  
  let filename: String
  let fileId: String
  
  let uploadRequestURL: URL
  let uploadMethod: String
  let uploadFormFields: [FormField]
  
  init(
    status: Int,
    filename: String,
    fileId: String,
    uploadRequestURL: URL,
    uploadMethod: String,
    uploadFormFields: [FormField]
  ) {
    self.status = status
    self.filename = filename
    self.fileId = fileId
    self.uploadRequestURL = uploadRequestURL
    self.uploadMethod = uploadMethod
    self.uploadFormFields = uploadFormFields
  }
  
  // Codable
  
  enum CodingKeys: String, CodingKey {
    case status
    case data
    case fileRequest = "file_upload_request"
  }
  
  enum FileCodingKeys: String, CodingKey {
    case fileId = "id"
    case filename = "name"
  }
  
  enum FileRequestCodingKeys: String, CodingKey {
    case url
    case method
    case fields = "form_fields"
    case expiration = "expiration_date"
  }
  
  init(from decoder: Decoder) throws {
    let rootContainer = try decoder.container(keyedBy: CodingKeys.self)
    status = try rootContainer.decode(Int.self, forKey: .status)
    
    let fileContainer = try rootContainer.nestedContainer(keyedBy: FileCodingKeys.self, forKey: .data)
    fileId = try fileContainer.decode(String.self, forKey: .fileId)
    filename = try fileContainer.decode(String.self, forKey: .filename)
    
    let uploadRequestContainer = try rootContainer.nestedContainer(
      keyedBy: FileRequestCodingKeys.self, forKey: .fileRequest
    )
    uploadRequestURL = try uploadRequestContainer.decode(URL.self, forKey: .url)
    uploadMethod = try uploadRequestContainer.decode(String.self, forKey: .method)
    uploadFormFields = try uploadRequestContainer.decode([FormField].self, forKey: .fields)
  }
  
  func encode(to encoder: Encoder) throws {
    var rootContainer = encoder.container(keyedBy: CodingKeys.self)
    try rootContainer.encode(status, forKey: .status)
    
    var fileContainer = rootContainer.nestedContainer(keyedBy: FileCodingKeys.self, forKey: .data)
    try fileContainer.encode(fileId, forKey: .fileId)
    try fileContainer.encode(filename, forKey: .filename)
    
    var uploadRequestContainer = rootContainer.nestedContainer(
      keyedBy: FileRequestCodingKeys.self, forKey: .fileRequest
    )
    try uploadRequestContainer.encode(uploadRequestURL, forKey: .url)
    try uploadRequestContainer.encode(uploadMethod, forKey: .method)
    try uploadRequestContainer.encode(uploadFormFields, forKey: .fields)
  }
}

/// An array of form fields to be used in the presigned POST request. You must supply these fields in the order in which you receive them from the server.
struct FormField: Codable {
  /// Form field name
  let key: String
  /// Form field value
  let value: String
}

