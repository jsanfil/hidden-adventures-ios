import SwiftUI

@main
struct HiddenAdventuresApp: App {
  private let adventureService = MockAdventureService()
  private let profileService = MockProfileService()

  var body: some Scene {
    WindowGroup {
      RootView(
        adventureService: adventureService,
        profileService: profileService
      )
    }
  }
}
