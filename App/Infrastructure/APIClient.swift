import Foundation

struct APIClient {
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
    let (data, _) = try await performRequest(
      pathComponents: pathComponents,
      method: method,
      queryItems: queryItems,
      requiresAuth: requiresAuth,
      body: body
    )

    do {
      return try JSONDecoder().decode(Response.self, from: data)
    } catch {
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
    let url = try makeURL(pathComponents: pathComponents, queryItems: queryItems)
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
      throw APIError.missingAuthToken
    }

    let data: Data
    let response: URLResponse

    do {
      (data, response) = try await session.data(for: request)
    } catch {
      throw APIError.transport(error)
    }

    guard let httpResponse = response as? HTTPURLResponse else {
      throw APIError.invalidResponse
    }

    guard (200..<300).contains(httpResponse.statusCode) else {
      let message = (try? JSONDecoder().decode(APIErrorResponse.self, from: data).error)
        ?? HTTPURLResponse.localizedString(forStatusCode: httpResponse.statusCode)
      throw APIError.server(statusCode: httpResponse.statusCode, message: message)
    }

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
