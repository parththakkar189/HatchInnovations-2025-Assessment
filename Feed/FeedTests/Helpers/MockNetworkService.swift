//
//  MockNetworkService.swift
//  Feed
//
//  Created by Parth Thakkar on 2025-10-25.
//

import Foundation
@testable import Feed

// MARK: - Mock Network Service

final public class MockNetworkService: NetworkServiceProtocol {
  var mockResult: Result<Any, NetworkError>?
  var fetchCallCount = 0
  var lastEndpoint: String?

  public func fetch<T: Decodable>(from endpoint: String) async -> Result<T, NetworkError> {
    fetchCallCount += 1
    lastEndpoint = endpoint
    
    guard let mockResult = mockResult else {
      return .failure(.unknown(NSError(domain: "MockError", code: -1)))
    }
    
    switch mockResult {
    case .success(let data):
      if let typedData = data as? T {
        return .success(typedData)
      }
      return .failure(.decodingError(DecodingError.typeMismatch(T.self, DecodingError.Context(codingPath: [], debugDescription: "Type mismatch"))))
    case .failure(let error):
      return .failure(error)
    }
  }
}
