import Foundation
import OSLog

struct APIClient {
  private static let logger = AppLogger.logger(category: "network.api")

  let baseURL: URL
  var authTokenProvider: @Sendable () -> String? = { nil }
  var session: URLSession = .shared

  func get<Response: Decodable>(
    pathComponents: [String],
    queryItems: [URLQueryItem] = [],
    requiresAuth: Bool = false
  ) async throws -> Response {
    try await send(
      pathComponents: pathComponents,
      method: "GET",
      queryItems: queryItems,
      requiresAuth: requiresAuth,
      body: Optional<Data>.none
    )
  }

  func getData(
    pathComponents: [String],
    queryItems: [URLQueryItem] = [],
    requiresAuth: Bool = false
  ) async throws -> Data {
    let (data, _) = try await performRequest(
      pathComponents: pathComponents,
      method: "GET",
      queryItems: queryItems,
      requiresAuth: requiresAuth,
      body: Optional<Data>.none
    )

    return data
  }

  func post<Body: Encodable, Response: Decodable>(
    pathComponents: [String],
    body: Body,
    requiresAuth: Bool = false
  ) async throws -> Response {
    let bodyData = try JSONEncoder().encode(body)
    return try await send(
      pathComponents: pathComponents,
      method: "POST",
      queryItems: [],
      requiresAuth: requiresAuth,
      body: bodyData
    )
  }

  func put<Body: Encodable, Response: Decodable>(
    pathComponents: [String],
    body: Body,
    requiresAuth: Bool = false
  ) async throws -> Response {
    let bodyData = try JSONEncoder().encode(body)
    return try await send(
      pathComponents: pathComponents,
      method: "PUT",
      queryItems: [],
      requiresAuth: requiresAuth,
      body: bodyData
    )
  }

  private func send<Response: Decodable>(
    pathComponents: [String],
    method: String,
    queryItems: [URLQueryItem],
    requiresAuth: Bool,
    body: Data?
  ) async throws -> Response {
    let (data, response) = try await performRequest(
      pathComponents: pathComponents,
      method: method,
      queryItems: queryItems,
      requiresAuth: requiresAuth,
      body: body
    )

    do {
      let decoded = try JSONDecoder().decode(Response.self, from: data)
      Self.logger.debug("API response decoded successfully for \(self.requestLabel(method: method, pathComponents: pathComponents), privacy: .public) status=\(response.statusCode, privacy: .public)")
      return decoded
    } catch {
      Self.logger.error("API response decode failed for \(self.requestLabel(method: method, pathComponents: pathComponents), privacy: .public) status=\(response.statusCode, privacy: .public): \(self.redactedErrorMessage(error), privacy: .public)")
      throw APIError.decoding(error)
    }
  }

  private func performRequest(
    pathComponents: [String],
    method: String,
    queryItems: [URLQueryItem],
    requiresAuth: Bool,
    body: Data?
  ) async throws -> (Data, HTTPURLResponse) {
    let requestLabel = self.requestLabel(method: method, pathComponents: pathComponents)
    Self.logger.debug("API request started for \(requestLabel, privacy: .public)")

    let url: URL
    do {
      url = try makeURL(pathComponents: pathComponents, queryItems: queryItems)
    } catch {
      Self.logger.error("API request URL construction failed for \(requestLabel, privacy: .public): \(self.redactedErrorMessage(error), privacy: .public)")
      throw error
    }

    var request = URLRequest(url: url)
    request.httpMethod = method
    request.httpBody = body
    request.setValue("application/json", forHTTPHeaderField: "Accept")

    if body != nil {
      request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    }

    let authToken = authTokenProvider()
    if let authToken, authToken.isEmpty == false {
      request.setValue("Bearer \(authToken)", forHTTPHeaderField: "Authorization")
    } else if requiresAuth {
      Self.logger.error("API request missing auth token for \(requestLabel, privacy: .public)")
      throw APIError.missingAuthToken
    }

    let data: Data
    let response: URLResponse

    do {
      (data, response) = try await session.data(for: request)
    } catch {
      Self.logger.error("API request transport failed for \(requestLabel, privacy: .public): \(self.redactedErrorMessage(error), privacy: .public)")
      throw APIError.transport(error)
    }

    guard let httpResponse = response as? HTTPURLResponse else {
      Self.logger.error("API request returned a non-HTTP response for \(requestLabel, privacy: .public)")
      throw APIError.invalidResponse
    }

    guard (200..<300).contains(httpResponse.statusCode) else {
      let message = (try? JSONDecoder().decode(APIErrorResponse.self, from: data).error)
        ?? HTTPURLResponse.localizedString(forStatusCode: httpResponse.statusCode)
      Self.logger.error("API request failed for \(requestLabel, privacy: .public) status=\(httpResponse.statusCode, privacy: .public): \(message, privacy: .public)")
      throw APIError.server(statusCode: httpResponse.statusCode, message: message)
    }

    Self.logger.info("API request succeeded for \(requestLabel, privacy: .public) status=\(httpResponse.statusCode, privacy: .public)")
    return (data, httpResponse)
  }

  private func makeURL(
    pathComponents: [String],
    queryItems: [URLQueryItem]
  ) throws -> URL {
    var url = baseURL
    for component in pathComponents {
      url.appendPathComponent(component)
    }

    guard var components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
      throw APIError.invalidBaseURL(baseURL.absoluteString)
    }

    if queryItems.isEmpty == false {
      components.queryItems = queryItems
    }

    guard let resolvedURL = components.url else {
      throw APIError.invalidBaseURL(url.absoluteString)
    }

    return resolvedURL
  }

  private func requestLabel(method: String, pathComponents: [String]) -> String {
    let path = "/" + pathComponents.joined(separator: "/")
    return "\(method) \(path)"
  }

  private func redactedErrorMessage(_ error: Error) -> String {
    if let apiError = error as? APIError {
      return apiError.errorDescription ?? String(describing: apiError)
    }

    return error.localizedDescription
  }
}

private struct APIErrorResponse: Decodable {
  let error: String
}

enum APIError: LocalizedError {
  case invalidBaseURL(String)
  case missingAuthToken
  case invalidResponse
  case server(statusCode: Int, message: String)
  case transport(Error)
  case decoding(Error)

  var errorDescription: String? {
    switch self {
    case .invalidBaseURL(let value):
      return "The API base URL is invalid: \(value)"
    case .missingAuthToken:
      return "Sign in with email, or provide HA_AUTH_TOKEN / HA_TEST_AUTH_TOKEN for explicit local auth overrides."
    case .invalidResponse:
      return "The server returned an invalid response."
    case .server(_, let message):
      return message
    case .transport(let error):
      return error.localizedDescription
    case .decoding(let error):
      return Self.decodingMessage(for: error)
    }
  }

  private static func decodingMessage(for error: Error) -> String {
    guard let decodingError = error as? DecodingError else {
      return "The app could not decode the server response."
    }

    switch decodingError {
    case .typeMismatch(_, let context):
      return "The app could not decode the server response at \(codingPath(context.codingPath)): \(context.debugDescription)"
    case .valueNotFound(_, let context):
      return "The app expected a value at \(codingPath(context.codingPath)): \(context.debugDescription)"
    case .keyNotFound(let key, let context):
      return "The app expected the key '\(key.stringValue)' at \(codingPath(context.codingPath))."
    case .dataCorrupted(let context):
      return "The server returned invalid data at \(codingPath(context.codingPath)): \(context.debugDescription)"
    @unknown default:
      return "The app could not decode the server response."
    }
  }

  private static func codingPath(_ codingPath: [CodingKey]) -> String {
    guard codingPath.isEmpty == false else {
      return "the top level"
    }

    return codingPath
      .map { key in
        if let intValue = key.intValue {
          return "[\(intValue)]"
        }

        return key.stringValue
      }
      .joined(separator: ".")
  }
}
