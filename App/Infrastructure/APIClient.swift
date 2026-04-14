import Foundation
import OSLog

struct MediaResponse: Sendable {
  let data: Data
  let eTag: String?
  let maxAgeSeconds: Int
  let contentType: String?
}

enum MediaRequestResult: Sendable {
  case fetched(MediaResponse)
  case notModified(eTag: String?, maxAgeSeconds: Int)
  case notFound
}

struct APIClient {
  private static let logger = AppLogger.logger(category: "network.api")

  let baseURL: URL
  var authTokenProvider: @Sendable () -> String? = { nil }
  var authTokenRefresher: @Sendable () async -> Bool = { false }
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

  func getMedia(
    pathComponents: [String],
    ifNoneMatch: String? = nil,
    requiresAuth: Bool = false
  ) async throws -> MediaRequestResult {
    try await performMediaRequest(
      pathComponents: pathComponents,
      queryItems: [],
      ifNoneMatch: ifNoneMatch,
      requiresAuth: requiresAuth
    )
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

  func post<Response: Decodable>(
    pathComponents: [String],
    requiresAuth: Bool = false
  ) async throws -> Response {
    try await send(
      pathComponents: pathComponents,
      method: "POST",
      queryItems: [],
      requiresAuth: requiresAuth,
      body: Optional<Data>.none
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

  func delete<Response: Decodable>(
    pathComponents: [String],
    requiresAuth: Bool = false
  ) async throws -> Response {
    try await send(
      pathComponents: pathComponents,
      method: "DELETE",
      queryItems: [],
      requiresAuth: requiresAuth,
      body: Optional<Data>.none
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
    body: Data?,
    allowsAuthRetry: Bool = true
  ) async throws -> (Data, HTTPURLResponse) {
    let requestLabel = self.requestLabel(method: method, pathComponents: pathComponents)
    let isMediaRequest = method == "GET" && pathComponents.first == "media" && pathComponents.count == 2
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

    if isMediaRequest {
      let ifNoneMatch = request.value(forHTTPHeaderField: "If-None-Match") ?? "<none>"
      let ifModifiedSince = request.value(forHTTPHeaderField: "If-Modified-Since") ?? "<none>"
      let cachePolicy = String(describing: request.cachePolicy)
      Self.logger.info(
        "Media request diagnostics for \(requestLabel, privacy: .public) ifNoneMatch=\(ifNoneMatch, privacy: .public) ifModifiedSince=\(ifModifiedSince, privacy: .public) cachePolicy=\(cachePolicy, privacy: .public)"
      )
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

    if isMediaRequest {
      let responseETag = httpResponse.value(forHTTPHeaderField: "ETag") ?? "<none>"
      let cacheControl = httpResponse.value(forHTTPHeaderField: "Cache-Control") ?? "<none>"
      let age = httpResponse.value(forHTTPHeaderField: "Age") ?? "<none>"
      Self.logger.info(
        "Media response diagnostics for \(requestLabel, privacy: .public) status=\(httpResponse.statusCode, privacy: .public) etag=\(responseETag, privacy: .public) cacheControl=\(cacheControl, privacy: .public) age=\(age, privacy: .public)"
      )
    }

    guard (200..<300).contains(httpResponse.statusCode) else {
      let message = (try? JSONDecoder().decode(APIErrorResponse.self, from: data).error)
        ?? HTTPURLResponse.localizedString(forStatusCode: httpResponse.statusCode)

      if allowsAuthRetry,
         requiresAuth,
         httpResponse.statusCode == 401 || httpResponse.statusCode == 403 {
        Self.logger.info("API request received auth failure for \(requestLabel, privacy: .public); attempting token refresh")
        if await authTokenRefresher() {
          Self.logger.info("API request retrying after token refresh for \(requestLabel, privacy: .public)")
          return try await performRequest(
            pathComponents: pathComponents,
            method: method,
            queryItems: queryItems,
            requiresAuth: requiresAuth,
            body: body,
            allowsAuthRetry: false
          )
        }
      }

      Self.logger.error("API request failed for \(requestLabel, privacy: .public) status=\(httpResponse.statusCode, privacy: .public): \(message, privacy: .public)")
      throw APIError.server(statusCode: httpResponse.statusCode, message: message)
    }

    Self.logger.info("API request succeeded for \(requestLabel, privacy: .public) status=\(httpResponse.statusCode, privacy: .public)")
    return (data, httpResponse)
  }

  private func performMediaRequest(
    pathComponents: [String],
    queryItems: [URLQueryItem],
    ifNoneMatch: String?,
    requiresAuth: Bool
  ) async throws -> MediaRequestResult {
    let requestLabel = self.requestLabel(method: "GET", pathComponents: pathComponents)
    Self.logger.debug("API request started for \(requestLabel, privacy: .public)")

    let request = try makeRequest(
      pathComponents: pathComponents,
      method: "GET",
      queryItems: queryItems,
      requiresAuth: requiresAuth,
      body: nil,
      extraHeaders: ifNoneMatch.map { ["If-None-Match": $0] } ?? [:]
    )

    let ifModifiedSince = request.value(forHTTPHeaderField: "If-Modified-Since") ?? "<none>"
    let requestIfNoneMatch = request.value(forHTTPHeaderField: "If-None-Match") ?? "<none>"
    let cachePolicy = String(describing: request.cachePolicy)
    Self.logger.info(
      "Media request diagnostics for \(requestLabel, privacy: .public) ifNoneMatch=\(requestIfNoneMatch, privacy: .public) ifModifiedSince=\(ifModifiedSince, privacy: .public) cachePolicy=\(cachePolicy, privacy: .public)"
    )

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

    let responseETag = httpResponse.value(forHTTPHeaderField: "ETag")
    let cacheControl = httpResponse.value(forHTTPHeaderField: "Cache-Control") ?? "<none>"
    let age = httpResponse.value(forHTTPHeaderField: "Age") ?? "<none>"
    Self.logger.info(
      "Media response diagnostics for \(requestLabel, privacy: .public) status=\(httpResponse.statusCode, privacy: .public) etag=\(responseETag ?? "<none>", privacy: .public) cacheControl=\(cacheControl, privacy: .public) age=\(age, privacy: .public)"
    )

    switch httpResponse.statusCode {
    case 200:
      Self.logger.info("API request succeeded for \(requestLabel, privacy: .public) status=\(httpResponse.statusCode, privacy: .public)")
      return .fetched(
        MediaResponse(
          data: data,
          eTag: responseETag,
          maxAgeSeconds: Self.maxAgeSeconds(from: cacheControl) ?? 0,
          contentType: httpResponse.value(forHTTPHeaderField: "Content-Type")
        )
      )
    case 304:
      Self.logger.info("API request succeeded for \(requestLabel, privacy: .public) status=\(httpResponse.statusCode, privacy: .public)")
      return .notModified(
        eTag: responseETag,
        maxAgeSeconds: Self.maxAgeSeconds(from: cacheControl) ?? 0
      )
    case 404:
      Self.logger.info("API request failed for \(requestLabel, privacy: .public) status=404: media not found")
      return .notFound
    default:
      let message = (try? JSONDecoder().decode(APIErrorResponse.self, from: data).error)
        ?? HTTPURLResponse.localizedString(forStatusCode: httpResponse.statusCode)
      Self.logger.error("API request failed for \(requestLabel, privacy: .public) status=\(httpResponse.statusCode, privacy: .public): \(message, privacy: .public)")
      throw APIError.server(statusCode: httpResponse.statusCode, message: message)
    }
  }

  private func makeRequest(
    pathComponents: [String],
    method: String,
    queryItems: [URLQueryItem],
    requiresAuth: Bool,
    body: Data?,
    extraHeaders: [String: String] = [:]
  ) throws -> URLRequest {
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

    for (header, value) in extraHeaders {
      request.setValue(value, forHTTPHeaderField: header)
    }

    return request
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

  private static func maxAgeSeconds(from cacheControl: String) -> Int? {
    for directive in cacheControl.split(separator: ",") {
      let trimmed = directive.trimmingCharacters(in: .whitespacesAndNewlines)
      guard trimmed.hasPrefix("max-age=") else {
        continue
      }

      return Int(trimmed.dropFirst("max-age=".count))
    }

    return nil
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
