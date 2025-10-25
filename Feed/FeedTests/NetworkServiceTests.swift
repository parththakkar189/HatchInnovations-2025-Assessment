//
//  NetworkServiceTests.swift
//  Feed
//
//  Created by Parth on 2025-10-25.
//


import XCTest
import AVFoundation
@testable import Feed

// MARK: - NetworkService Tests

@MainActor
final class NetworkServiceTests: XCTestCase {
  var networkService: NetworkService!
  var mockSession: URLSession!
  
  override func setUp() {
    super.setUp()
    let config = URLSessionConfiguration.ephemeral
    config.protocolClasses = [MockURLProtocol.self]
    mockSession = URLSession(configuration: config)
    networkService = NetworkService(session: mockSession, baseURL: "https://test.com")
  }
  
  override func tearDown() {
    networkService = nil
    mockSession = nil
    MockURLProtocol.requestHandler = nil
    super.tearDown()
  }
  
  // MARK: - Happy Path Tests
  
  func testFetch_Success_ReturnsDecodedData() async {
    // Given
    let jsonString = """
    {
      "videos": [
        "https://example.com/video1.m3u8",
        "https://example.com/video2.m3u8"
      ]
    }
    """
    let jsonData = jsonString.data(using: .utf8)!
    
    MockURLProtocol.requestHandler = { request in
      let response = HTTPURLResponse(
        url: request.url!,
        statusCode: 200,
        httpVersion: nil,
        headerFields: ["Content-Type": "application/json"]
      )!
      return (response, jsonData)
    }
    
    // When
    let result: Result<VideoFeedResponse, NetworkError> = await networkService.fetch(from: "/videos")
    
    // Then
    switch result {
    case .success(let response):
      let videos = response.videos
      XCTAssertEqual(videos.count, 2, "Network service should return 2 videos.")
      XCTAssertEqual(videos[0], "https://example.com/video1.m3u8", "First video URL should match expected value.")
      XCTAssertEqual(videos[1], "https://example.com/video2.m3u8", "Second video URL should match expected value.")
    case .failure(let error):
      XCTFail("Expected success, but got error \(error) instead.")
    }
  }
  
  func testFetch_EmptyVideoList_ReturnsEmptyArray() async {
    // Given
    let jsonString = """
    {
      "videos": []
    }
    """
    let jsonData = jsonString.data(using: .utf8)!
    
    MockURLProtocol.requestHandler = { request in
      let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
      return (response, jsonData)
    }
    
    // When
    let result: Result<VideoFeedResponse, NetworkError> = await networkService.fetch(from: "/videos")
    
    // Then
    switch result {
    case .success(let response):
      let videos = response.videos
      XCTAssertTrue(videos.isEmpty, "Network service should return empty videos array.")
    case .failure(let error):
      XCTFail("Expected success, but got error \(error) instead.")
    }
  }
  
  func testFetch_Status200Range_ReturnsSuccess() async {
    // Test various 2xx status codes
    let statusCodes = [200, 201, 204, 299]
    
    for statusCode in statusCodes {
      // Given
      let jsonString = """
      {
        "videos": ["https://example.com/video.m3u8"]
      }
      """
      let jsonData = jsonString.data(using: .utf8)!
      
      MockURLProtocol.requestHandler = { request in
        let response = HTTPURLResponse(url: request.url!, statusCode: statusCode, httpVersion: nil, headerFields: nil)!
        return (response, jsonData)
      }
      
      // When
      let result: Result<VideoFeedResponse, NetworkError> = await networkService.fetch(from: "/videos")
      
      // Then
      switch result {
      case .success:
        XCTAssertTrue(true, "Network service should succeed with status code \(statusCode).")
      case .failure:
        XCTFail("Expected success with status code \(statusCode), but got failure instead.")
      }
    }
  }
  
  func testFetch_SetsCorrectHeaders() async {
    // Given
    var capturedRequest: URLRequest?
    let jsonString = """
    {
      "videos": []
    }
    """
    let jsonData = jsonString.data(using: .utf8)!
    
    MockURLProtocol.requestHandler = { request in
      capturedRequest = request
      let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
      return (response, jsonData)
    }
    
    // When
    let _: Result<VideoFeedResponse, NetworkError> = await networkService.fetch(from: "/videos")
    
    // Then
    XCTAssertNotNil(capturedRequest, "Request should be captured.")
    XCTAssertEqual(capturedRequest?.httpMethod, "GET", "Request HTTP method should be GET.")
    XCTAssertEqual(capturedRequest?.value(forHTTPHeaderField: "Accept"), "application/json", "Request Accept header should be application/json.")
    XCTAssertEqual(capturedRequest?.value(forHTTPHeaderField: "Content-Type"), "application/json", "Request Content-Type header should be application/json.")
  }
  
  func testFetch_ConstructsCorrectURL() async {
    // Given
    var capturedURL: URL?
    let jsonString = """
    {
      "videos": []
    }
    """
    let jsonData = jsonString.data(using: .utf8)!
    
    MockURLProtocol.requestHandler = { request in
      capturedURL = request.url
      let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
      return (response, jsonData)
    }
    
    // When
    let _: Result<VideoFeedResponse, NetworkError> = await networkService.fetch(from: "/test/endpoint")
    
    // Then
    XCTAssertEqual(capturedURL?.absoluteString, "https://test.com/test/endpoint", "Network service should construct correct URL from base URL and endpoint.")
  }
}

