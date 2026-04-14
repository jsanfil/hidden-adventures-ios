import Foundation
import XCTest
@testable import HiddenAdventures

final class SidekickServiceTests: XCTestCase {
  override func tearDown() {
    SidekickMockURLProtocol.requestHandler = nil
    super.tearDown()
  }

  func testRemoteServiceFetchesMySidekicksAndSearchResults() async throws {
    SidekickMockURLProtocol.requestHandler = { request in
      switch (request.httpMethod, request.url?.path) {
      case ("GET", "/api/me/sidekicks"):
        XCTAssertEqual(request.url?.query, "limit=50&offset=0")
        return (
          Self.jsonResponse(for: request, statusCode: 200),
          Data(Self.mySidekicksPayload.utf8)
        )
      case ("GET", "/api/sidekicks/search"):
        XCTAssertEqual(request.url?.query, "q=Port&limit=20&offset=0")
        return (
          Self.jsonResponse(for: request, statusCode: 200),
          Data(Self.searchPayload.utf8)
        )
      default:
        XCTFail("Unexpected request: \(request)")
        throw URLError(.badServerResponse)
      }
    }

    let service = RemoteSidekickService(client: Self.makeClient())

    let mine = try await service.getMySidekicks(limit: 50, offset: 0)
    XCTAssertEqual(mine.items.first?.profile.handle, "maya")
    XCTAssertTrue(mine.items.first?.relationship.isSidekick == true)
    XCTAssertEqual(mine.items.first?.profile.avatar?.id, "hero-mountain")

    let search = try await service.searchProfiles(query: "Port", limit: 20, offset: 0)
    XCTAssertEqual(search.query, "Port")
    XCTAssertEqual(search.items.first?.profile.handle, "maya")
  }

  func testRemoteServiceUsesPostAndDeleteForMutations() async throws {
    final class RequestState {
      var seenPost = false
      var seenDelete = false
    }

    let state = RequestState()

    SidekickMockURLProtocol.requestHandler = { request in
      switch (request.httpMethod, request.url?.path) {
      case ("POST", "/api/me/sidekicks/maya"):
        state.seenPost = true
        XCTAssertNil(request.httpBody)
        return (
          Self.jsonResponse(for: request, statusCode: 200),
          Data(Self.mutationAddPayload.utf8)
        )
      case ("DELETE", "/api/me/sidekicks/maya"):
        state.seenDelete = true
        return (
          Self.jsonResponse(for: request, statusCode: 200),
          Data(Self.mutationRemovePayload.utf8)
        )
      default:
        XCTFail("Unexpected request: \(request)")
        throw URLError(.badServerResponse)
      }
    }

    let service = RemoteSidekickService(client: Self.makeClient())

    let added = try await service.addSidekick(handle: "maya")
    XCTAssertTrue(added.item.relationship.isSidekick)

    let removed = try await service.removeSidekick(handle: "maya")
    XCTAssertFalse(removed.item.relationship.isSidekick)
    XCTAssertTrue(state.seenPost)
    XCTAssertTrue(state.seenDelete)
  }

  func testFixtureServiceTracksRelationshipsAcrossMutations() async throws {
    let service = FixtureSidekickService(initialSidekickIDs: Set(["sidekick-sarah"]))

    let initial = try await service.getMySidekicks(limit: 50, offset: 0)
    XCTAssertEqual(initial.items.map(\.profile.handle), ["sarahc"])

    let added = try await service.addSidekick(handle: "mikerod")
    XCTAssertTrue(added.item.relationship.isSidekick)

    let updated = try await service.getMySidekicks(limit: 50, offset: 0)
    XCTAssertEqual(updated.items.map(\.profile.handle), ["sarahc", "mikerod"])

    let removed = try await service.removeSidekick(handle: "mikerod")
    XCTAssertFalse(removed.item.relationship.isSidekick)

    let final = try await service.getMySidekicks(limit: 50, offset: 0)
    XCTAssertEqual(final.items.map(\.profile.handle), ["sarahc"])
  }

  private static func makeClient() -> APIClient {
    APIClient(
      baseURL: URL(string: "https://example.com/api")!,
      authTokenProvider: { "token" },
      session: URLSession(configuration: makeConfiguration())
    )
  }

  private static func makeConfiguration() -> URLSessionConfiguration {
    let configuration = URLSessionConfiguration.ephemeral
    configuration.protocolClasses = [SidekickMockURLProtocol.self]
    return configuration
  }

  private static func jsonResponse(for request: URLRequest, statusCode: Int) -> HTTPURLResponse {
    HTTPURLResponse(
      url: request.url!,
      statusCode: statusCode,
      httpVersion: nil,
      headerFields: ["Content-Type": "application/json"]
    )!
  }

  private static let mySidekicksPayload = #"""
  {
    "items": [
      {
        "profile": {
          "id": "u-1",
          "handle": "maya",
          "displayName": "Maya",
          "bio": null,
          "homeCity": "Portland",
          "homeRegion": "OR",
          "avatar": {
            "id": "hero-mountain",
            "storageKey": "hero-mountain"
          },
          "cover": null
        },
        "relationship": { "isSidekick": true },
        "stats": { "adventuresCount": 3 }
      }
    ],
    "paging": { "limit": 50, "offset": 0, "returned": 1 }
  }
  """#

  private static let searchPayload = #"""
  {
    "items": [
      {
        "profile": {
          "id": "u-2",
          "handle": "maya",
          "displayName": "Maya",
          "bio": null,
          "homeCity": "Portland",
          "homeRegion": "OR",
          "avatar": null,
          "cover": null
        },
        "relationship": { "isSidekick": false },
        "stats": { "adventuresCount": 3 }
      }
    ],
    "paging": { "limit": 20, "offset": 0, "returned": 1 },
    "query": "Port"
  }
  """#

  private static let mutationAddPayload = #"""
  {
    "item": {
      "profile": {
        "id": "u-2",
        "handle": "maya",
        "displayName": "Maya",
        "bio": null,
        "homeCity": "Portland",
        "homeRegion": "OR",
        "avatar": null,
        "cover": null
      },
      "relationship": { "isSidekick": true },
      "stats": { "adventuresCount": 3 }
    }
  }
  """#

  private static let mutationRemovePayload = #"""
  {
    "item": {
      "profile": {
        "id": "u-2",
        "handle": "maya",
        "displayName": "Maya",
        "bio": null,
        "homeCity": "Portland",
        "homeRegion": "OR",
        "avatar": null,
        "cover": null
      },
      "relationship": { "isSidekick": false },
      "stats": { "adventuresCount": 3 }
    }
  }
  """#
}

private final class SidekickMockURLProtocol: URLProtocol {
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
