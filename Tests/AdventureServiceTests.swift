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

  func testFavoriteAdventurePostsToFavoriteEndpointWithoutResponseBody() async throws {
    MockAdventureURLProtocol.requestHandler = { request in
      XCTAssertEqual(request.httpMethod, "POST")
      XCTAssertEqual(request.url?.path, "/api/adventures/adventure-1/favorite")
      XCTAssertEqual(request.value(forHTTPHeaderField: "Authorization"), "Bearer token")

      let response = HTTPURLResponse(
        url: request.url!,
        statusCode: 204,
        httpVersion: nil,
        headerFields: nil
      )!

      return (response, Data())
    }

    let service = makeService(cache: makeCache())

    try await service.favoriteAdventure(id: "adventure-1")
  }

  func testUnfavoriteAdventureDeletesFavoriteEndpointWithoutResponseBody() async throws {
    MockAdventureURLProtocol.requestHandler = { request in
      XCTAssertEqual(request.httpMethod, "DELETE")
      XCTAssertEqual(request.url?.path, "/api/adventures/adventure-1/favorite")
      XCTAssertEqual(request.value(forHTTPHeaderField: "Authorization"), "Bearer token")

      let response = HTTPURLResponse(
        url: request.url!,
        statusCode: 204,
        httpVersion: nil,
        headerFields: nil
      )!

      return (response, Data())
    }

    let service = makeService(cache: makeCache())

    try await service.unfavoriteAdventure(id: "adventure-1")
  }

  func testRateAdventurePostsScoreAndDecodesUpdatedDetail() async throws {
    final class RequestBox {
      var body: Data?
    }

    let requestBox = RequestBox()

    MockAdventureURLProtocol.requestHandler = { request in
      XCTAssertEqual(request.httpMethod, "POST")
      XCTAssertEqual(request.url?.path, "/api/adventures/adventure-1/rating")
      XCTAssertEqual(request.value(forHTTPHeaderField: "Authorization"), "Bearer token")
      requestBox.body = request.bodyData

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
            "item": {
              "id": "adventure-1",
              "title": "Blue Pool",
              "description": "Worth the hike.",
              "categorySlug": "water_spots",
              "categoryLabel": "Hidden Gem",
              "visibility": "public",
              "createdAt": "2026-04-28T18:00:00.000Z",
              "publishedAt": "2026-04-28T18:00:00.000Z",
              "location": { "latitude": 44.4, "longitude": -122.1 },
              "author": {
                "handle": "mayaexplores",
                "displayName": "Maya Reyes",
                "homeCity": "Portland",
                "homeRegion": "OR"
              },
              "primaryMedia": null,
              "stats": {
                "favoriteCount": 10,
                "commentCount": 4,
                "ratingCount": 13,
                "averageRating": 4.3
              },
              "placeLabel": "Oregon",
              "updatedAt": "2026-04-29T18:00:00.000Z",
              "isFavorited": false,
              "viewerRating": 4
            }
          }
          """#.utf8
        )
      )
    }

    let service = makeService(cache: makeCache())
    let response = try await service.rateAdventure(id: "adventure-1", score: 4)

    let requestBody = try XCTUnwrap(requestBox.body)
    let payload = try JSONDecoder().decode(RatingCreatePayloadAssertion.self, from: requestBody)

    XCTAssertEqual(payload.score, 4)
    XCTAssertEqual(response.item.viewerRating, 4)
    XCTAssertEqual(response.item.stats.ratingCount, 13)
    XCTAssertEqual(response.item.stats.averageRating, 4.3)
  }

  func testRateAdventurePostsRatingStateChangeNotification() async throws {
    let notificationExpectation = expectation(description: "rating change notification posted")
    var observedChange: RatingStateChange?

    let observer = NotificationCenter.default.addObserver(
      forName: RatingStateChange.notificationName,
      object: nil,
      queue: nil
    ) { notification in
      guard let change = RatingStateChange(notification: notification) else {
        return
      }

      observedChange = change
      notificationExpectation.fulfill()
    }

    defer {
      NotificationCenter.default.removeObserver(observer)
    }

    MockAdventureURLProtocol.requestHandler = { request in
      XCTAssertEqual(request.httpMethod, "POST")
      XCTAssertEqual(request.url?.path, "/api/adventures/adventure-1/rating")

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
            "item": {
              "id": "adventure-1",
              "title": "Blue Pool",
              "description": "Worth the hike.",
              "categorySlug": "water_spots",
              "categoryLabel": "Hidden Gem",
              "visibility": "public",
              "createdAt": "2026-04-28T18:00:00.000Z",
              "publishedAt": "2026-04-28T18:00:00.000Z",
              "location": { "latitude": 44.4, "longitude": -122.1 },
              "author": {
                "handle": "mayaexplores",
                "displayName": "Maya Reyes",
                "homeCity": "Portland",
                "homeRegion": "OR"
              },
              "primaryMedia": null,
              "stats": {
                "favoriteCount": 10,
                "commentCount": 4,
                "ratingCount": 13,
                "averageRating": 4.3
              },
              "placeLabel": "Oregon",
              "updatedAt": "2026-04-29T18:00:00.000Z",
              "isFavorited": false,
              "viewerRating": 4
            }
          }
          """#.utf8
        )
      )
    }

    let service = makeService(cache: makeCache())
    _ = try await service.rateAdventure(id: "adventure-1", score: 4)

    await fulfillment(of: [notificationExpectation], timeout: 1.0)
    XCTAssertEqual(
      observedChange,
      RatingStateChange(
        adventureID: "adventure-1",
        averageRating: 4.3,
        ratingCount: 13,
        viewerRating: 4
      )
    )
  }

  func testClearRatingDeletesRatingEndpointAndDecodesUpdatedDetail() async throws {
    MockAdventureURLProtocol.requestHandler = { request in
      XCTAssertEqual(request.httpMethod, "DELETE")
      XCTAssertEqual(request.url?.path, "/api/adventures/adventure-1/rating")
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
            "item": {
              "id": "adventure-1",
              "title": "Blue Pool",
              "description": "Worth the hike.",
              "categorySlug": "water_spots",
              "categoryLabel": "Hidden Gem",
              "visibility": "public",
              "createdAt": "2026-04-28T18:00:00.000Z",
              "publishedAt": "2026-04-28T18:00:00.000Z",
              "location": { "latitude": 44.4, "longitude": -122.1 },
              "author": {
                "handle": "mayaexplores",
                "displayName": "Maya Reyes",
                "homeCity": "Portland",
                "homeRegion": "OR"
              },
              "primaryMedia": null,
              "stats": {
                "favoriteCount": 10,
                "commentCount": 4,
                "ratingCount": 12,
                "averageRating": 4.5
              },
              "placeLabel": "Oregon",
              "updatedAt": "2026-04-29T18:00:00.000Z",
              "isFavorited": false,
              "viewerRating": null
            }
          }
          """#.utf8
        )
      )
    }

    let service = makeService(cache: makeCache())
    let response = try await service.clearRating(id: "adventure-1")

    XCTAssertNil(response.item.viewerRating)
    XCTAssertEqual(response.item.stats.ratingCount, 12)
    XCTAssertEqual(response.item.stats.averageRating, 4.5)
  }

  func testClearRatingPostsRatingStateChangeNotification() async throws {
    let notificationExpectation = expectation(description: "rating clear notification posted")
    var observedChange: RatingStateChange?

    let observer = NotificationCenter.default.addObserver(
      forName: RatingStateChange.notificationName,
      object: nil,
      queue: nil
    ) { notification in
      guard let change = RatingStateChange(notification: notification) else {
        return
      }

      observedChange = change
      notificationExpectation.fulfill()
    }

    defer {
      NotificationCenter.default.removeObserver(observer)
    }

    MockAdventureURLProtocol.requestHandler = { request in
      XCTAssertEqual(request.httpMethod, "DELETE")
      XCTAssertEqual(request.url?.path, "/api/adventures/adventure-1/rating")

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
            "item": {
              "id": "adventure-1",
              "title": "Blue Pool",
              "description": "Worth the hike.",
              "categorySlug": "water_spots",
              "categoryLabel": "Hidden Gem",
              "visibility": "public",
              "createdAt": "2026-04-28T18:00:00.000Z",
              "publishedAt": "2026-04-28T18:00:00.000Z",
              "location": { "latitude": 44.4, "longitude": -122.1 },
              "author": {
                "handle": "mayaexplores",
                "displayName": "Maya Reyes",
                "homeCity": "Portland",
                "homeRegion": "OR"
              },
              "primaryMedia": null,
              "stats": {
                "favoriteCount": 10,
                "commentCount": 4,
                "ratingCount": 12,
                "averageRating": 4.5
              },
              "placeLabel": "Oregon",
              "updatedAt": "2026-04-29T18:00:00.000Z",
              "isFavorited": false,
              "viewerRating": null
            }
          }
          """#.utf8
        )
      )
    }

    let service = makeService(cache: makeCache())
    _ = try await service.clearRating(id: "adventure-1")

    await fulfillment(of: [notificationExpectation], timeout: 1.0)
    XCTAssertEqual(
      observedChange,
      RatingStateChange(
        adventureID: "adventure-1",
        averageRating: 4.5,
        ratingCount: 12,
        viewerRating: nil
      )
    )
  }

  func testListCommentsGetsPagedCommentsForAdventure() async throws {
    MockAdventureURLProtocol.requestHandler = { request in
      XCTAssertEqual(request.httpMethod, "GET")
      XCTAssertEqual(request.url?.path, "/api/adventures/adventure-1/comments")
      XCTAssertEqual(
        request.url?.query,
        "limit=20&offset=40"
      )
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
                "id": "comment-1",
                "body": "Still one of the best swims in Oregon.",
                "createdAt": "2026-04-28T18:00:00.000Z",
                "updatedAt": "2026-04-28T18:00:00.000Z",
                "author": {
                  "handle": "mayaexplores",
                  "displayName": "Maya Reyes",
                  "homeCity": "Portland",
                  "homeRegion": "OR"
                }
              }
            ],
            "paging": {
              "limit": 20,
              "offset": 40,
              "returned": 1
            }
          }
          """#.utf8
        )
      )
    }

    let service = makeService(cache: makeCache())
    let response = try await service.listComments(
      adventureID: "adventure-1",
      limit: 20,
      offset: 40
    )

    XCTAssertEqual(response.items.count, 1)
    XCTAssertEqual(response.items.first?.id, "comment-1")
    XCTAssertEqual(response.items.first?.author.displayName, "Maya Reyes")
    XCTAssertEqual(response.paging.limit, 20)
    XCTAssertEqual(response.paging.offset, 40)
    XCTAssertEqual(response.paging.returned, 1)
  }

  func testCreateCommentPostsTrimmedBodyAndDecodesResponse() async throws {
    final class RequestBox {
      var body: Data?
    }

    let requestBox = RequestBox()

    MockAdventureURLProtocol.requestHandler = { request in
      XCTAssertEqual(request.httpMethod, "POST")
      XCTAssertEqual(request.url?.path, "/api/adventures/adventure-1/comments")
      XCTAssertEqual(request.value(forHTTPHeaderField: "Authorization"), "Bearer token")
      requestBox.body = request.bodyData

      let response = HTTPURLResponse(
        url: request.url!,
        statusCode: 201,
        httpVersion: nil,
        headerFields: ["Content-Type": "application/json"]
      )!

      return (
        response,
        Data(
          #"""
          {
            "item": {
              "id": "comment-2",
              "body": "Fresh trail beta.",
              "createdAt": "2026-04-29T12:00:00.000Z",
              "updatedAt": "2026-04-29T12:00:00.000Z",
              "author": {
                "handle": "jordan",
                "displayName": "Jordan",
                "homeCity": "Portland",
                "homeRegion": "OR"
              }
            }
          }
          """#.utf8
        )
      )
    }

    let service = makeService(cache: makeCache())
    let response = try await service.createComment(
      adventureID: "adventure-1",
      body: "  Fresh trail beta.  "
    )

    let requestBody = try XCTUnwrap(requestBox.body)
    let payload = try JSONDecoder().decode(CommentCreatePayloadAssertion.self, from: requestBody)

    XCTAssertEqual(payload.body, "Fresh trail beta.")
    XCTAssertEqual(response.item.id, "comment-2")
    XCTAssertEqual(response.item.author.handle, "jordan")
  }

  func testCreateCommentPropagatesServerError() async throws {
    MockAdventureURLProtocol.requestHandler = { request in
      XCTAssertEqual(request.httpMethod, "POST")
      XCTAssertEqual(request.url?.path, "/api/adventures/adventure-1/comments")

      let response = HTTPURLResponse(
        url: request.url!,
        statusCode: 403,
        httpVersion: nil,
        headerFields: ["Content-Type": "application/json"]
      )!

      return (
        response,
        Data(#"{"error":"Adventure comments require a completed local account."}"#.utf8)
      )
    }

    let service = makeService(cache: makeCache())

    do {
      _ = try await service.createComment(adventureID: "adventure-1", body: "Hello")
      XCTFail("Expected createComment to throw")
    } catch let error as APIError {
      guard case .server(let statusCode, let message) = error else {
        return XCTFail("Expected server error, got \(error)")
      }

      XCTAssertEqual(statusCode, 403)
      XCTAssertEqual(message, "Adventure comments require a completed local account.")
    }
  }

  func testFixtureFavoriteStateUpdatesFeedAndDetail() async throws {
    let store = FavoriteFixtureStore(initialFavoriteIDs: [])
    let service = FixtureAdventureService(favoriteStore: store)

    let initialFeed = try await service.listFeed(query: FeedQuery(limit: 20, offset: 0)).items
    XCTAssertEqual(initialFeed.first(where: { $0.id == MockFixtures.bluePoolID })?.isFavorited, false)

    try await service.favoriteAdventure(id: MockFixtures.bluePoolID)

    let favoriteFeed = try await service.listFeed(query: FeedQuery(limit: 20, offset: 0)).items
    let favoriteDetail = try await service.getAdventure(id: MockFixtures.bluePoolID).item
    XCTAssertEqual(favoriteFeed.first(where: { $0.id == MockFixtures.bluePoolID })?.isFavorited, true)
    XCTAssertEqual(favoriteDetail.isFavorited, true)

    try await service.unfavoriteAdventure(id: MockFixtures.bluePoolID)

    let unfavoriteDetail = try await service.getAdventure(id: MockFixtures.bluePoolID).item
    XCTAssertEqual(unfavoriteDetail.isFavorited, false)
  }

  func testFixtureCommentsSupportPagingAndCreate() async throws {
    let service = FixtureAdventureService()

    let initial = try await service.listComments(
      adventureID: MockFixtures.bluePoolID,
      limit: 2,
      offset: 0
    )
    XCTAssertEqual(initial.items.count, 2)
    XCTAssertEqual(initial.paging.returned, 2)

    let created = try await service.createComment(
      adventureID: MockFixtures.bluePoolID,
      body: "  Worth packing extra layers.  "
    )
    XCTAssertEqual(created.item.body, "Worth packing extra layers.")
    XCTAssertEqual(created.item.author.handle, MockFixtures.profile.handle)

    let refreshed = try await service.listComments(
      adventureID: MockFixtures.bluePoolID,
      limit: 40,
      offset: 0
    )
    XCTAssertEqual(refreshed.items.last?.id, created.item.id)
    XCTAssertEqual(refreshed.items.last?.body, "Worth packing extra layers.")
  }

  func testFixtureRatingSupportsCreateUpdateAndClear() async throws {
    let service = FixtureAdventureService()

    let initial = try await service.getAdventure(id: MockFixtures.bluePoolID).item
    XCTAssertNil(initial.viewerRating)
    let initialSum = initial.stats.averageRating * Double(initial.stats.ratingCount)

    let rated = try await service.rateAdventure(id: MockFixtures.bluePoolID, score: 4).item
    XCTAssertEqual(rated.viewerRating, 4)
    XCTAssertEqual(rated.stats.ratingCount, initial.stats.ratingCount + 1)
    XCTAssertEqual(
      rated.stats.averageRating,
      (initialSum + 4) / Double(initial.stats.ratingCount + 1),
      accuracy: 0.000_001
    )

    let updated = try await service.rateAdventure(id: MockFixtures.bluePoolID, score: 2).item
    XCTAssertEqual(updated.viewerRating, 2)
    XCTAssertEqual(updated.stats.ratingCount, rated.stats.ratingCount)
    XCTAssertEqual(
      updated.stats.averageRating,
      (initialSum + 2) / Double(initial.stats.ratingCount + 1),
      accuracy: 0.000_001
    )

    let cleared = try await service.clearRating(id: MockFixtures.bluePoolID).item
    XCTAssertNil(cleared.viewerRating)
    XCTAssertEqual(cleared.stats.ratingCount, initial.stats.ratingCount)
    XCTAssertEqual(cleared.stats.averageRating, initial.stats.averageRating, accuracy: 0.001)
  }

  func testLoadMediaDataUsesFreshCacheWithoutRefetching() async throws {
    final class RequestCounter {
      var count = 0
    }

    let counter = RequestCounter()
    let mediaID = "media-fresh"
    let cacheDirectory = makeTempDirectory()
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

    let service = makeService(cache: makeCache(directoryURL: cacheDirectory))

    let first = try await service.loadMediaData(id: mediaID)
    let second = try await service.loadMediaData(id: mediaID)

    XCTAssertEqual(first, Data("cached-image".utf8))
    XCTAssertEqual(second, Data("cached-image".utf8))
    XCTAssertEqual(counter.count, 1)
  }

  func testFixtureLoadMediaDataReturnsBundledImageBytesForAvatarMedia() async throws {
    let service = FixtureAdventureService()

    let data = try await service.loadMediaData(id: "hero-mountain")

    XCTAssertFalse(data.isEmpty)
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

private struct CommentCreatePayloadAssertion: Decodable {
  let body: String
}

private struct RatingCreatePayloadAssertion: Decodable {
  let score: Int
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
