import Foundation
import XCTest
@testable import HiddenAdventures

final class APIClientTests: XCTestCase {
  override func tearDown() {
    MockURLProtocol.requestHandler = nil
    MockURLProtocol.requestError = nil
    super.tearDown()
  }

  func testGetDecodesSuccessResponse() async throws {
    MockURLProtocol.requestHandler = { request in
      XCTAssertEqual(request.httpMethod, "GET")
      XCTAssertEqual(request.url?.path, "/api/feed")

      let response = HTTPURLResponse(
        url: request.url!,
        statusCode: 200,
        httpVersion: nil,
        headerFields: ["Content-Type": "application/json"]
      )!

      return (response, Data(#"{"value":"ok"}"#.utf8))
    }

    let client = makeClient()
    let response: TestResponse = try await client.get(pathComponents: ["feed"])

    XCTAssertEqual(response, TestResponse(value: "ok"))
  }

  func testGetThrowsServerErrorWithResponseMessage() async throws {
    MockURLProtocol.requestHandler = { request in
      let response = HTTPURLResponse(
        url: request.url!,
        statusCode: 401,
        httpVersion: nil,
        headerFields: ["Content-Type": "application/json"]
      )!

      return (response, Data(#"{"error":"Unauthorized"}"#.utf8))
    }

    let client = makeClient()

    do {
      let _: TestResponse = try await client.get(pathComponents: ["profiles", "me"])
      XCTFail("Expected request to fail")
    } catch let error as APIError {
      guard case .server(let statusCode, let message) = error else {
        return XCTFail("Expected server error")
      }

      XCTAssertEqual(statusCode, 401)
      XCTAssertEqual(message, "Unauthorized")
    }
  }

  func testGetThrowsDecodingErrorForInvalidPayload() async throws {
    MockURLProtocol.requestHandler = { request in
      let response = HTTPURLResponse(
        url: request.url!,
        statusCode: 200,
        httpVersion: nil,
        headerFields: ["Content-Type": "application/json"]
      )!

      return (response, Data(#"{"unexpected":true}"#.utf8))
    }

    let client = makeClient()

    do {
      let _: TestResponse = try await client.get(pathComponents: ["profile"])
      XCTFail("Expected request to fail")
    } catch let error as APIError {
      guard case .decoding = error else {
        return XCTFail("Expected decoding error")
      }
    }
  }

  func testGetThrowsTransportErrorWhenRequestFails() async throws {
    MockURLProtocol.requestError = URLError(.notConnectedToInternet)

    let client = makeClient()

    do {
      let _: TestResponse = try await client.get(pathComponents: ["adventures"])
      XCTFail("Expected request to fail")
    } catch let error as APIError {
      guard case .transport = error else {
        return XCTFail("Expected transport error")
      }
    }
  }

  private func makeClient() -> APIClient {
    let configuration = URLSessionConfiguration.ephemeral
    configuration.protocolClasses = [MockURLProtocol.self]

    return APIClient(
      baseURL: URL(string: "https://example.com/api")!,
      authTokenProvider: { "token" },
      session: URLSession(configuration: configuration)
    )
  }
}

private struct TestResponse: Codable, Equatable {
  let value: String
}

private final class MockURLProtocol: URLProtocol {
  static var requestHandler: ((URLRequest) throws -> (HTTPURLResponse, Data))?
  static var requestError: Error?

  override class func canInit(with request: URLRequest) -> Bool {
    true
  }

  override class func canonicalRequest(for request: URLRequest) -> URLRequest {
    request
  }

  override func startLoading() {
    if let requestError = MockURLProtocol.requestError {
      client?.urlProtocol(self, didFailWithError: requestError)
      return
    }

    guard let requestHandler = MockURLProtocol.requestHandler else {
      client?.urlProtocol(self, didFailWithError: URLError(.badServerResponse))
      return
    }

    do {
      let (response, data) = try requestHandler(request)
      client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
      client?.urlProtocol(self, didLoad: data)
      client?.urlProtocolDidFinishLoading(self)
    } catch {
      client?.urlProtocol(self, didFailWithError: error)
    }
  }

  override func stopLoading() {}
}
