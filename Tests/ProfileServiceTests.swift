import XCTest
@testable import HiddenAdventures

final class ProfileServiceTests: XCTestCase {
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
}
