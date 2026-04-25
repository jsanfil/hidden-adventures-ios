import Foundation
import XCTest
@testable import HiddenAdventures

final class DiscoverServiceTests: XCTestCase {
  override func tearDown() {
    DiscoverMockURLProtocol.requestHandler = nil
    super.tearDown()
  }

  func testRemoteServiceFetchesHomeAndMapsServerModulesToScreenModel() async throws {
    DiscoverMockURLProtocol.requestHandler = { request in
      XCTAssertEqual(request.httpMethod, "GET")
      XCTAssertEqual(request.url?.path, "/api/discover/home")
      XCTAssertNil(request.url?.query)
      XCTAssertEqual(request.value(forHTTPHeaderField: "Authorization"), "Bearer token")

      return (
        Self.jsonResponse(for: request, statusCode: 200),
        Data(Self.homePayload.utf8)
      )
    }

    let service = RemoteDiscoverService(client: Self.makeClient())
    let model = try await service.home()

    XCTAssertEqual(model.adventurers.map(\.id), ["adventurer-maya"])
    XCTAssertEqual(model.adventurers.first?.name, "Maya Reyes")
    XCTAssertEqual(model.adventurers.first?.handle, "mayaexplores")
    XCTAssertEqual(model.adventurers.first?.location, "Portland, OR")
    XCTAssertEqual(model.adventurers.first?.adventureCount, 4)
    XCTAssertEqual(model.adventurers.first?.topCategories, ["Trails", "Water Spots"])
    XCTAssertEqual(model.adventurers.first?.coverMediaIDs, ["media-preview"])
    XCTAssertEqual(model.adventurers.first?.avatarMediaID, "media-avatar")

    XCTAssertEqual(model.popularAdventures.map(\.id), ["adventure-eagle"])
    XCTAssertEqual(model.popularAdventures.first?.authorName, "Maya Reyes")
    XCTAssertEqual(model.popularAdventures.first?.category, "Trails")
    XCTAssertEqual(model.popularAdventures.first?.rating, 4.75)
    XCTAssertEqual(model.popularAdventures.first?.favoriteCount, 12)
    XCTAssertEqual(model.popularAdventures.first?.mediaIDs, ["media-adventure"])
  }

  func testRemoteServiceSearchesGroupedPeopleAndAdventures() async throws {
    DiscoverMockURLProtocol.requestHandler = { request in
      XCTAssertEqual(request.httpMethod, "GET")
      XCTAssertEqual(request.url?.path, "/api/discover/search")
      XCTAssertEqual(request.url?.query, "q=maya&limit=20&offset=0")

      return (
        Self.jsonResponse(for: request, statusCode: 200),
        Data(Self.searchPayload.utf8)
      )
    }

    let service = RemoteDiscoverService(client: Self.makeClient())
    let results = try await service.search(query: "maya", limit: 20, offset: 0)

    XCTAssertEqual(results.query, "maya")
    XCTAssertEqual(results.people.map(\.handle), ["mayaexplores"])
    XCTAssertEqual(results.adventures.map(\.id), ["adventure-eagle"])
  }

  func testFixtureServicePreservesDeterministicLocalSearchForUITestHarness() async throws {
    let service = FixtureDiscoverService(variant: .happy)
    let home = try await service.home()
    let results = try await service.search(query: "maya", limit: 20, offset: 0)

    XCTAssertEqual(home.adventurers.map(\.id), ["adventurer-maya-reyes", "adventurer-theo-nakamura"])
    XCTAssertEqual(results.people.map(\.id), ["adventurer-maya-reyes"])
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
    configuration.protocolClasses = [DiscoverMockURLProtocol.self]
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

  private static let homePayload = #"""
  {
    "modules": [
      {
        "id": "explore-adventurers",
        "type": "adventurers",
        "title": "Explore Adventurers",
        "items": [
          {
            "id": "adventurer-maya",
            "handle": "mayaexplores",
            "displayName": "Maya Reyes",
            "homeCity": "Portland",
            "homeRegion": "OR",
            "avatar": {
              "id": "media-avatar",
              "storageKey": "profiles/media-avatar.jpg"
            },
            "previewMedia": {
              "id": "media-preview",
              "storageKey": "adventures/media-preview.jpg"
            },
            "publicAdventureCount": 4,
            "topCategorySlugs": ["trails", "water_spots"]
          }
        ]
      },
      {
        "id": "popular-adventures",
        "type": "adventures",
        "title": "Popular Adventures",
        "items": [
          {
            "id": "adventure-eagle",
            "title": "Eagle Creek Trail",
            "description": "Tunnel views.",
            "categorySlug": "trails",
            "visibility": "public",
            "createdAt": "2026-04-01T00:00:00.000Z",
            "publishedAt": "2026-04-02T00:00:00.000Z",
            "location": {
              "latitude": 45.5,
              "longitude": -122.1
            },
            "placeLabel": "Columbia River Gorge, OR",
            "author": {
              "handle": "mayaexplores",
              "displayName": "Maya Reyes",
              "homeCity": "Portland",
              "homeRegion": "OR"
            },
            "primaryMedia": {
              "id": "media-adventure",
              "storageKey": "adventures/media-adventure.jpg"
            },
            "stats": {
              "favoriteCount": 12,
              "commentCount": 3,
              "ratingCount": 4,
              "averageRating": 4.75
            }
          }
        ]
      }
    ]
  }
  """#

  private static let searchPayload = #"""
  {
    "query": "maya",
    "people": {
      "items": [
        {
          "id": "adventurer-maya",
          "handle": "mayaexplores",
          "displayName": "Maya Reyes",
          "homeCity": "Portland",
          "homeRegion": "OR",
          "avatar": null,
          "previewMedia": null,
          "publicAdventureCount": 4,
          "topCategorySlugs": ["trails"]
        }
      ],
      "paging": { "limit": 20, "offset": 0, "returned": 1 }
    },
    "adventures": {
      "items": [
        {
          "id": "adventure-eagle",
          "title": "Eagle Creek Trail",
          "description": "Tunnel views.",
          "categorySlug": "trails",
          "visibility": "public",
          "createdAt": "2026-04-01T00:00:00.000Z",
          "publishedAt": "2026-04-02T00:00:00.000Z",
          "location": null,
          "placeLabel": "Columbia River Gorge, OR",
          "author": {
            "handle": "mayaexplores",
            "displayName": "Maya Reyes",
            "homeCity": "Portland",
            "homeRegion": "OR"
          },
          "primaryMedia": null,
          "stats": {
            "favoriteCount": 12,
            "commentCount": 3,
            "ratingCount": 4,
            "averageRating": 4.75
          }
        }
      ],
      "paging": { "limit": 20, "offset": 0, "returned": 1 }
    }
  }
  """#
}

private final class DiscoverMockURLProtocol: URLProtocol {
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
