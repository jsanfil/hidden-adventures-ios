import Foundation
import XCTest
@testable import HiddenAdventures

final class AdventureServiceTests: XCTestCase {
  private var tempDirectories: [URL] = []

  override func tearDown() {
    MockAdventureURLProtocol.requestHandler = nil
    for directory in tempDirectories {
      try? FileManager.default.removeItem(at: directory)
    }
    tempDirectories.removeAll()
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

  func testLoadMediaDataUsesFreshCacheWithoutRefetching() async throws {
    final class RequestCounter {
      var count = 0
    }

    let counter = RequestCounter()
    let mediaID = "media-fresh"
    MockAdventureURLProtocol.requestHandler = { request in
      counter.count += 1
      XCTAssertEqual(request.url?.path, "/api/media/\(mediaID)")

      let response = HTTPURLResponse(
        url: request.url!,
        statusCode: 200,
        httpVersion: nil,
        headerFields: [
          "ETag": "\"\(mediaID)-tag\"",
          "Cache-Control": "private, max-age=300",
          "Content-Type": "image/jpeg"
        ]
      )!

      return (response, Data("cached-image".utf8))
    }

    let service = makeService(cache: makeCache())

    let first = try await service.loadMediaData(id: mediaID)
    let second = try await service.loadMediaData(id: mediaID)

    XCTAssertEqual(first, Data("cached-image".utf8))
    XCTAssertEqual(second, Data("cached-image".utf8))
    XCTAssertEqual(counter.count, 1)
  }

  func testLoadMediaDataPersistsAcrossServiceInstances() async throws {
    final class RequestCounter {
      var count = 0
    }

    let counter = RequestCounter()
    let cacheDirectory = makeTempDirectory()
    let now = Date(timeIntervalSince1970: 1_000)

    MockAdventureURLProtocol.requestHandler = { request in
      counter.count += 1

      let response = HTTPURLResponse(
        url: request.url!,
        statusCode: 200,
        httpVersion: nil,
        headerFields: [
          "ETag": "\"media-1-tag\"",
          "Cache-Control": "private, max-age=300",
          "Content-Type": "image/jpeg"
        ]
      )!

      return (response, Data("persistent-image".utf8))
    }

    let firstService = makeService(
      cache: makeCache(directoryURL: cacheDirectory, now: { now })
    )
    let secondService = makeService(
      cache: makeCache(directoryURL: cacheDirectory, now: { now.addingTimeInterval(120) })
    )

    _ = try await firstService.loadMediaData(id: "media-1")
    let second = try await secondService.loadMediaData(id: "media-1")

    XCTAssertEqual(second, Data("persistent-image".utf8))
    XCTAssertEqual(counter.count, 1)
  }

  func testLoadMediaDataRevalidatesStaleEntriesWithETag() async throws {
    final class State {
      var requestCount = 0
    }

    let state = State()
    let revalidationExpectation = expectation(description: "stale entry revalidated")
    let cacheDirectory = makeTempDirectory()
    let baseDate = Date(timeIntervalSince1970: 1_000)

    MockAdventureURLProtocol.requestHandler = { request in
      state.requestCount += 1

      if state.requestCount == 1 {
        let response = HTTPURLResponse(
          url: request.url!,
          statusCode: 200,
          httpVersion: nil,
          headerFields: [
            "ETag": "\"media-1-tag\"",
            "Cache-Control": "private, max-age=300",
            "Content-Type": "image/jpeg"
          ]
        )!
        return (response, Data("stale-image".utf8))
      }

      XCTAssertEqual(request.value(forHTTPHeaderField: "If-None-Match"), "\"media-1-tag\"")
      if state.requestCount == 2 {
        revalidationExpectation.fulfill()
      }
      let response = HTTPURLResponse(
        url: request.url!,
        statusCode: 304,
        httpVersion: nil,
        headerFields: [
          "ETag": "\"media-1-tag\"",
          "Cache-Control": "private, max-age=300"
        ]
      )!
      return (response, Data())
    }

    let firstService = makeService(
      cache: makeCache(directoryURL: cacheDirectory, now: { baseDate })
    )
    let staleService = makeService(
      cache: makeCache(directoryURL: cacheDirectory, now: { baseDate.addingTimeInterval(301) })
    )
    let refreshedService = makeService(
      cache: makeCache(directoryURL: cacheDirectory, now: { baseDate.addingTimeInterval(302) })
    )

    _ = try await firstService.loadMediaData(id: "media-1")
    let staleData = try await staleService.loadMediaData(id: "media-1")

    XCTAssertEqual(staleData, Data("stale-image".utf8))
    await fulfillment(of: [revalidationExpectation], timeout: 1.0)
    try await Task.sleep(nanoseconds: 100_000_000)

    let refreshedData = try await refreshedService.loadMediaData(id: "media-1")
    XCTAssertEqual(refreshedData, Data("stale-image".utf8))
    XCTAssertEqual(state.requestCount, 2)
  }

  func testLoadMediaDataInvalidatesStaleEntriesWhenServerReturnsNotFound() async throws {
    final class State {
      var requestCount = 0
    }

    let state = State()
    let invalidationExpectation = expectation(description: "stale entry invalidated")
    let cacheDirectory = makeTempDirectory()
    let baseDate = Date(timeIntervalSince1970: 1_000)
    var observedAction: String?
    invalidationExpectation.assertForOverFulfill = false

    let observer = NotificationCenter.default.addObserver(
      forName: .haMediaCacheDidChange,
      object: nil,
      queue: nil
    ) { notification in
      guard
        let mediaID = notification.userInfo?[MediaCacheNotifications.mediaIDUserInfoKey] as? String,
        mediaID == "media-404"
      else {
        return
      }

      guard observedAction == nil else {
        return
      }

      observedAction = notification.userInfo?[MediaCacheNotifications.actionUserInfoKey] as? String
      invalidationExpectation.fulfill()
    }

    MockAdventureURLProtocol.requestHandler = { request in
      state.requestCount += 1

      if state.requestCount == 1 {
        let response = HTTPURLResponse(
          url: request.url!,
          statusCode: 200,
          httpVersion: nil,
          headerFields: [
            "ETag": "\"media-404-tag\"",
            "Cache-Control": "private, max-age=300",
            "Content-Type": "image/jpeg"
          ]
        )!
        return (response, Data("moderated-image".utf8))
      }

      let response = HTTPURLResponse(
        url: request.url!,
        statusCode: 404,
        httpVersion: nil,
        headerFields: ["Content-Type": "application/json"]
      )!
      return (response, Data(#"{"error":"Media not found."}"#.utf8))
    }

    defer {
      NotificationCenter.default.removeObserver(observer)
    }

    let firstService = makeService(
      cache: makeCache(directoryURL: cacheDirectory, now: { baseDate })
    )
    let staleService = makeService(
      cache: makeCache(directoryURL: cacheDirectory, now: { baseDate.addingTimeInterval(301) })
    )
    let missingService = makeService(
      cache: makeCache(directoryURL: cacheDirectory, now: { baseDate.addingTimeInterval(302) })
    )

    _ = try await firstService.loadMediaData(id: "media-404")
    let staleData = try await staleService.loadMediaData(id: "media-404")
    XCTAssertEqual(staleData, Data("moderated-image".utf8))

    await fulfillment(of: [invalidationExpectation], timeout: 1.0)
    XCTAssertEqual(observedAction, MediaCacheChangeAction.invalidated.rawValue)

    do {
      _ = try await missingService.loadMediaData(id: "media-404")
      XCTFail("Expected missing media to fail after invalidation")
    } catch let error as APIError {
      guard case .server(let statusCode, _) = error else {
        return XCTFail("Expected server error")
      }

      XCTAssertEqual(statusCode, 404)
    }
  }

  private func makeService(cache: MediaDataCache) -> RemoteAdventureService {
    let configuration = URLSessionConfiguration.ephemeral
    configuration.protocolClasses = [MockAdventureURLProtocol.self]
    let session = URLSession(configuration: configuration)

    let client = APIClient(
      baseURL: URL(string: "https://example.com/api")!,
      authTokenProvider: { "token" },
      session: session
    )

    return RemoteAdventureService(client: client, cache: cache)
  }

  private func makeCache(
    directoryURL: URL? = nil,
    now: @escaping @Sendable () -> Date = { Date() }
  ) -> MediaDataCache {
    MediaDataCache(directoryURL: directoryURL, now: now)
  }

  private func makeTempDirectory() -> URL {
    let url = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
    tempDirectories.append(url)
    return url
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
