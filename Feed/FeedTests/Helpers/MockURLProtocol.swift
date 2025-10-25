//
//  MockURLProtocol.swift
//  Feed
//
//  Created by Parth on 2025-10-25.
//

import Foundation

// MARK: - Mock URL Protocol

public class MockURLProtocol: URLProtocol {
  static var requestHandler: ((URLRequest) throws -> (HTTPURLResponse, Data))?
  
  public override class func canInit(with request: URLRequest) -> Bool {
    return true
  }
  
  public override class func canonicalRequest(for request: URLRequest) -> URLRequest {
    return request
  }
  
  public override func startLoading() {
    guard let handler = MockURLProtocol.requestHandler else {
      fatalError("Handler is unavailable.")
    }
    
    do {
      let (response, data) = try handler(request)
      client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
      client?.urlProtocol(self, didLoad: data)
      client?.urlProtocolDidFinishLoading(self)
    } catch {
      client?.urlProtocol(self, didFailWithError: error)
    }
  }
  
  public override func stopLoading() {
  }
}
