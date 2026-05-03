import XCTest
@testable import HiddenAdventures

final class AppCoordinatorTests: XCTestCase {
  func testFixtureSettingsStartScreenRoutesToSettings() {
    let coordinator = AppCoordinator(
      environment: [
        "UITEST_START_SCREEN": "settings"
      ]
    )

    XCTAssertEqual(coordinator.stage, .explore)
    XCTAssertEqual(coordinator.exploreMode, .profile)
    XCTAssertEqual(coordinator.path, [.settings])
  }
}
