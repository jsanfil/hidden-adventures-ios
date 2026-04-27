import XCTest
@testable import HiddenAdventures

final class ProfileServiceTests: XCTestCase {
  override func tearDown() {
    ProfileMockURLProtocol.requestHandler = nil
    super.tearDown()
  }

  func testFixtureServiceReturnsViewerVisibleAdventuresForSelfAndSidekickProfiles() async throws {
    let service = FixtureProfileService()

    let selfProfile = try await service.getProfile(handle: MockFixtures.profile.handle, limit: 20, offset: 0)
    XCTAssertEqual(selfProfile.profile.handle, MockFixtures.profile.handle)
    XCTAssertEqual(selfProfile.adventures.map(\.id), [
      MockFixtures.eagleID,
      MockFixtures.jordanHiddenRidgeID
    ])

    let sidekickProfile = try await service.getProfile(handle: "sarahc", limit: 20, offset: 0)
    XCTAssertEqual(sidekickProfile.profile.handle, "sarahc")
    XCTAssertEqual(sidekickProfile.adventures.map(\.id), [
      MockFixtures.sarahCliffsID,
      MockFixtures.sarahSecretSpringsID
    ])
    XCTAssertFalse(sidekickProfile.adventures.contains(where: { $0.id == MockFixtures.sarahQuietQuarryID }))
  }

  func testFixtureServiceReturnsDiscoverProfilesWithVisibleAdventures() async throws {
    let service = FixtureProfileService()

    let mayaProfile = try await service.getProfile(handle: "mayaexplores", limit: 20, offset: 0)
    XCTAssertEqual(mayaProfile.profile.handle, "mayaexplores")
    XCTAssertEqual(mayaProfile.profile.displayName, "Maya Reyes")
    XCTAssertEqual(mayaProfile.adventures.map(\.id), [MockFixtures.eagleID])
    XCTAssertTrue(mayaProfile.adventures.allSatisfy { $0.visibility == .public })

    let theoProfile = try await service.getProfile(handle: "theo.outdoors", limit: 20, offset: 0)
    XCTAssertEqual(theoProfile.profile.handle, "theo.outdoors")
    XCTAssertEqual(theoProfile.profile.displayName, "Theo Nakamura")
    XCTAssertEqual(theoProfile.adventures.map(\.id), [MockFixtures.bluePoolID])
    XCTAssertTrue(theoProfile.adventures.allSatisfy { $0.visibility == .public })
  }

  func testRemoteServiceFetchesProfileFavoritesWithPagingAndAuth() async throws {
    ProfileMockURLProtocol.requestHandler = { request in
      XCTAssertEqual(request.httpMethod, "GET")
      XCTAssertEqual(request.url?.path, "/api/profiles/jordan/favorites")
      XCTAssertEqual(request.url?.query, "limit=10&offset=20")
      XCTAssertEqual(request.value(forHTTPHeaderField: "Authorization"), "Bearer token")

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
                "id": "adventure-1",
                "title": "Hidden Falls",
                "description": "Bring water and wear good shoes.",
                "categorySlug": "water_spots",
                "visibility": "public",
                "createdAt": "2026-03-01T00:00:00.000Z",
                "publishedAt": "2026-03-02T00:00:00.000Z",
                "location": {
                  "latitude": 34.12,
                  "longitude": -118.45
                },
                "placeLabel": "Hidden Falls Trailhead",
                "author": {
                  "handle": "jacksanfil",
                  "displayName": "Jack",
                  "homeCity": "Los Angeles",
                  "homeRegion": "CA"
                },
                "primaryMedia": {
                  "id": "media-1",
                  "storageKey": "adventures/media-1.jpg"
                },
                "stats": {
                  "favoriteCount": 8,
                  "commentCount": 3,
                  "ratingCount": 2,
                  "averageRating": 4.5
                },
                "isFavorited": true
              }
            ],
            "paging": {
              "limit": 10,
              "offset": 20,
              "returned": 1
            }
          }
          """#.utf8
        )
      )
    }

    let service = RemoteProfileService(client: Self.makeClient())

    let response = try await service.getProfileFavorites(handle: "jordan", limit: 10, offset: 20)

    XCTAssertEqual(response.items.map(\.id), ["adventure-1"])
    XCTAssertEqual(response.items.first?.isFavorited, true)
    XCTAssertEqual(response.paging.offset, 20)
  }

  func testFixtureServiceReturnsPopulatedAndEmptyFavoritesStates() async throws {
    let populated = FixtureProfileService(
      favoriteStore: FavoriteFixtureStore(initialFavoriteIDs: [MockFixtures.bluePoolID])
    )

    let populatedResponse = try await populated.getProfileFavorites(
      handle: MockFixtures.profile.handle,
      limit: 20,
      offset: 0
    )
    XCTAssertEqual(populatedResponse.items.map(\.id), [MockFixtures.bluePoolID])
    XCTAssertTrue(populatedResponse.items.allSatisfy(\.isFavorited))

    let empty = FixtureProfileService(favoriteStore: FavoriteFixtureStore(initialFavoriteIDs: []))
    let emptyResponse = try await empty.getProfileFavorites(
      handle: MockFixtures.profile.handle,
      limit: 20,
      offset: 0
    )
    XCTAssertEqual(emptyResponse.items, [])
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
    configuration.protocolClasses = [ProfileMockURLProtocol.self]
    return configuration
  }
}

private final class ProfileMockURLProtocol: URLProtocol {
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
