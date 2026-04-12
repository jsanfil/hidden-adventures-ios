import Foundation
import XCTest
@testable import HiddenAdventures

final class AdventureServiceTests: XCTestCase {
  override func tearDown() {
    MockAdventureURLProtocol.requestHandler = nil
    super.tearDown()
  }

  func testCreateAdventureAllocatesUploadsThenCreatesAdventure() async throws {
    final class RequestBox {
      var requests: [URLRequest] = []
      var createAdventureBody: Data?
    }

    let requestBox = RequestBox()

    MockAdventureURLProtocol.requestHandler = { request in
      requestBox.requests.append(request)

      switch (request.httpMethod, request.url?.path) {
      case ("POST", "/api/media/adventure-uploads"):
        let response = HTTPURLResponse(
          url: request.url!,
          statusCode: 200,
          httpVersion: nil,
          headerFields: ["Content-Type": "application/json"]
        )!

        return (
          response,
          Data(
            #"""
            {
              "items": [
                {
                  "clientId": "photo-0",
                  "mediaId": "media-1",
                  "storageKey": "adventures/test_media-1.jpg",
                  "upload": {
                    "method": "PUT",
                    "url": "https://uploads.example.com/media-1",
                    "headers": { "Content-Type": "image/jpeg" },
                    "expiresAt": "2026-04-08T18:00:00.000Z"
                  }
                }
              ]
            }
            """#.utf8
          )
        )

      case ("PUT", "/media-1"):
        let response = HTTPURLResponse(
          url: request.url!,
          statusCode: 200,
          httpVersion: nil,
          headerFields: nil
        )!
        return (response, Data())

      case ("POST", "/api/adventures"):
        requestBox.createAdventureBody = request.bodyData
        let response = HTTPURLResponse(
          url: request.url!,
          statusCode: 201,
          httpVersion: nil,
          headerFields: ["Content-Type": "application/json"]
        )!
        return (
          response,
          Data(#"{"item":{"id":"adventure-1","status":"pending_moderation"}}"#.utf8)
        )

      default:
        XCTFail("Unexpected request \(request)")
        throw URLError(.badServerResponse)
      }
    }

    let configuration = URLSessionConfiguration.ephemeral
    configuration.protocolClasses = [MockAdventureURLProtocol.self]
    let session = URLSession(configuration: configuration)

    let client = APIClient(
      baseURL: URL(string: "https://example.com/api")!,
      authTokenProvider: { "token" },
      session: session
    )

    let service = RemoteAdventureService(client: client)
    let response = try await service.createAdventure(
      request: CreateAdventureRequest(
        title: "Hidden Falls",
        description: "Bring water and wear good shoes.",
        categorySlug: .waterSpots,
        visibility: .sidekicks,
        location: AdventureLocation(latitude: 34.12, longitude: -118.45),
        placeLabel: "Hidden Falls Trailhead",
        photos: [
          CreateAdventurePhotoUpload(
            data: Data("fixture-photo".utf8),
            mimeType: "image/jpeg",
            width: 1200,
            height: 900
          )
        ]
      )
    )

    XCTAssertEqual(response.item, CreatedAdventureItem(id: "adventure-1", status: "pending_moderation"))
    XCTAssertEqual(requestBox.requests.count, 3)
    XCTAssertEqual(requestBox.requests[0].url?.path, "/api/media/adventure-uploads")
    XCTAssertEqual(requestBox.requests[1].url?.absoluteString, "https://uploads.example.com/media-1")
    XCTAssertEqual(requestBox.requests[2].url?.path, "/api/adventures")

    let requestBody = try XCTUnwrap(requestBox.createAdventureBody, "Expected create adventure body")
    let payload = try JSONDecoder().decode(CreateAdventurePayloadAssertion.self, from: requestBody)
    XCTAssertEqual(payload.visibility, "sidekicks")
  }
}

private struct CreateAdventurePayloadAssertion: Decodable {
  let visibility: String
}

private extension URLRequest {
  var bodyData: Data? {
    if let httpBody {
      return httpBody
    }

    guard let stream = httpBodyStream else {
      return nil
    }

    stream.open()
    defer { stream.close() }

    let bufferSize = 1024
    var data = Data()
    let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: bufferSize)
    defer { buffer.deallocate() }

    while stream.hasBytesAvailable {
      let read = stream.read(buffer, maxLength: bufferSize)
      guard read > 0 else {
        break
      }
      data.append(buffer, count: read)
    }

    return data.isEmpty ? nil : data
  }
}

private final class MockAdventureURLProtocol: URLProtocol {
  static var requestHandler: ((URLRequest) throws -> (HTTPURLResponse, Data))?

  override class func canInit(with request: URLRequest) -> Bool {
    true
  }

  override class func canonicalRequest(for request: URLRequest) -> URLRequest {
    request
  }

  override func startLoading() {
    guard let requestHandler = Self.requestHandler else {
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
