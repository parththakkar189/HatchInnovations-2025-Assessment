//
//  NetworkServiceProtocol.swift
//  Feed
//
//  Created by Parth Thakkar on 2025-10-23.
//

import Foundation

protocol NetworkServiceProtocol {
  func fetch<T: Decodable>(
    from endpoint: String
  ) async -> Result<T, NetworkError>
}

final class NetworkService: NetworkServiceProtocol {
  private let session: URLSession
  private let baseURL: String
  
  init(
    session: URLSession = .shared,
    baseURL: String = "https://cdn.dev.airxp.app"
  ) {
    self.session = session
    self.baseURL = baseURL
  }
  
  func fetch<T: Decodable>(
    from endpoint: String
  ) async -> Result<T, NetworkError> {
    let fullURL = baseURL + endpoint
    
    guard let url = URL(string: fullURL) else {
      return .failure(.invalidURL)
    }
    
    var request = URLRequest(url: url)
    request.httpMethod = "GET"
    request.setValue("application/json", forHTTPHeaderField: "Accept")
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    
    do {
      let (data, response) = try await session.data(for: request)
      
      guard let httpResponse = response as? HTTPURLResponse else {
        return .failure(.invalidResponse)
      }
      
      guard (200...299).contains(httpResponse.statusCode) else {
        return .failure(.httpError(statusCode: httpResponse.statusCode))
      }
      
      let decoder = JSONDecoder()
      let decodedData = try decoder.decode(T.self, from: data)
      return .success(decodedData)
      
    } catch let error as DecodingError {
      return .failure(.decodingError(error))
    } catch let error as URLError {
      return .failure(.urlError(error))
    } catch {
      return .failure(.unknown(error))
    }
  }
}
