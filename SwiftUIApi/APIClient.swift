//
//  APIClient.swift
//  NetworkingPractice
//
//  Created by Ali Mansour on 07/11/2025.
//

import Foundation

enum APIError: Error, LocalizedError {
  case invalidResponse
  case http(Int, body: String?)
  case decoding(Error)
  case transport(Error)

  var errorDescription: String? {
    switch self {
    case .invalidResponse:
      return "Invalid response from server."
    case .http(let code, let body):
      let tail = (body?.isEmpty == false) ? " • \(body!)" : ""
      return "Server returned HTTP \(code)\(tail)"
    case .decoding(let err):
      return "Failed to decode: \(err.localizedDescription)"
    case .transport(let err):
      return "Network error: \(err.localizedDescription)"
    }
  }
}

struct APIClient {
  let baseURL = URL(string: "https://jsonplaceholder.typicode.com")!

  /// Generic GET that supports query items (paging, search, etc.)
  func get<T: Decodable>(_ path: String, query: [URLQueryItem] = []) async throws -> T {
    var comps = URLComponents(url: baseURL.appendingPathComponent(path), resolvingAgainstBaseURL: false)!
    comps.queryItems = query.isEmpty ? nil : query
    guard let url = comps.url else { throw APIError.invalidResponse }

    var req = URLRequest(url: url)
    req.httpMethod = "GET"
    req.timeoutInterval = 15

    // 🔍 Debug log: only in Debug builds
    #if DEBUG
    print("➡️ GET \(url.absoluteString)")
    #endif

    do {
      let (data, resp) = try await URLSession.shared.data(for: req)
      guard let http = resp as? HTTPURLResponse else { throw APIError.invalidResponse }

      #if DEBUG
      print("⬅️ Status \(http.statusCode) • bytes \(data.count)")
      #endif

      guard (200..<300).contains(http.statusCode) else {
        let body = String(data: data, encoding: .utf8)
        #if DEBUG
        print("❌ HTTP \(http.statusCode) body: \(body ?? "<no body>")")
        #endif
        throw APIError.http(http.statusCode, body: body)
      }

      let decoder = JSONDecoder()
      decoder.keyDecodingStrategy = .convertFromSnakeCase // useful if API returns snake_case keys

      do {
        return try decoder.decode(T.self, from: data)
      } catch {
        #if DEBUG
        print("🟠 Decoding failed: \(error)")
        if let s = String(data: data, encoding: .utf8) { print("Payload: \(s)") }
        #endif
        throw APIError.decoding(error)
      }
    } catch let apiErr as APIError {
      throw apiErr
    } catch {
      #if DEBUG
      print("🔌 Transport error: \(error)")
      #endif
      throw APIError.transport(error)
    }
  }
}
