//
//  NetworkError.swift
//  Feed
//
//  Created by Parth Thakkar on 2025-10-23.
//

import Foundation

public enum NetworkError: Error, LocalizedError, Sendable {
  case invalidURL
  case invalidResponse
  case httpError(statusCode: Int)
  case decodingError(DecodingError)
  case urlError(URLError)
  case unknown(Error)
  
  public var errorDescription: String? {
    switch self {
    case .invalidURL:
      return "Invalid URL"
    case .invalidResponse:
      return "Invalid response from server"
    case .httpError(let statusCode):
      return "HTTP Error: \(statusCode)"
    case .decodingError(let error):
      return "Decoding error: \(error.localizedDescription)"
    case .urlError(let error):
      return "Network error: \(error.localizedDescription)"
    case .unknown(let error):
      return "Unknown error: \(error.localizedDescription)"
    }
  }
}
