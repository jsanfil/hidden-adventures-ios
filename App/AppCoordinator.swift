import Foundation
import SwiftUI
import Combine

enum AppStage: Equatable {
  case welcome
  case emailEntry
  case codeEntry
  case profileSetup
  case explore
}

enum ExploreMode: String, CaseIterable, Identifiable {
  case feed = "Feed"
  case map = "Map"
  case discover = "Discover"
  case profile = "Profile"

  var id: Self { self }
}

enum AppRoute: Hashable {
  case detail(String)
  case profile(String)
}

final class AppCoordinator: ObservableObject {
  @Published var stage: AppStage
  @Published var path: [AppRoute]
  @Published var exploreMode: ExploreMode
  @Published var createAdventureVariant: CreateAdventureFixtureVariant?

  init(environment: [String: String] = ProcessInfo.processInfo.environment) {
    path = []
    createAdventureVariant = nil

    switch environment["UITEST_START_SCREEN"] {
    case "email":
      stage = .emailEntry
      exploreMode = .feed
    case "code":
      stage = .codeEntry
      exploreMode = .feed
    case "profile":
      stage = .profileSetup
      exploreMode = .feed
    case "explore-map":
      stage = .explore
      exploreMode = .map
    case "discover":
      stage = .explore
      exploreMode = .discover
    case "explore-feed":
      stage = .explore
      exploreMode = .feed
    case "explore-profile":
      stage = .explore
      exploreMode = .profile
    case "detail":
      stage = .explore
      exploreMode = .feed
      let adventureID = environment["UITEST_DETAIL_ID"] ?? MockFixtures.bluePoolID
      path = [.detail(adventureID)]
    case "create-photos":
      stage = .explore
      exploreMode = .feed
      createAdventureVariant = .photos
    case "create-details-empty":
      stage = .explore
      exploreMode = .feed
      createAdventureVariant = .detailsEmpty
    case "create-details-location":
      stage = .explore
      exploreMode = .feed
      createAdventureVariant = .detailsLocation
    case "create-location-options":
      stage = .explore
      exploreMode = .feed
      createAdventureVariant = .locationOptions
    case "create-location-search-empty":
      stage = .explore
      exploreMode = .feed
      createAdventureVariant = .locationSearchEmpty
    case "create-location-search-results":
      stage = .explore
      exploreMode = .feed
      createAdventureVariant = .locationSearchResults
    case "create-location-pin":
      stage = .explore
      exploreMode = .feed
      createAdventureVariant = .locationPin
    default:
      stage = .welcome
      exploreMode = .feed
    }
  }

  var pathBinding: Binding<[AppRoute]> {
    Binding(
      get: { self.path },
      set: { self.path = $0 }
    )
  }

  var exploreModeBinding: Binding<ExploreMode> {
    Binding(
      get: { self.exploreMode },
      set: { self.exploreMode = $0 }
    )
  }

  var createAdventureBinding: Binding<CreateAdventureFixtureVariant?> {
    Binding(
      get: { self.createAdventureVariant },
      set: { self.createAdventureVariant = $0 }
    )
  }

  func resetToWelcome() {
    path = []
    stage = .welcome
    exploreMode = .feed
    createAdventureVariant = nil
  }
}
