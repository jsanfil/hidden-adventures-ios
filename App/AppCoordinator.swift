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
  case profile = "Profile"

  var id: Self { self }
}

enum AppRoute: Hashable {
  case detail(String)
}

final class AppCoordinator: ObservableObject {
  @Published var stage: AppStage
  @Published var path: [AppRoute]
  @Published var exploreMode: ExploreMode

  init(environment: [String: String] = ProcessInfo.processInfo.environment) {
    path = []

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
    case "explore-feed":
      stage = .explore
      exploreMode = .feed
    case "detail":
      stage = .explore
      exploreMode = .feed
      let adventureID = environment["UITEST_DETAIL_ID"] ?? MockFixtures.bluePoolID
      path = [.detail(adventureID)]
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

  func resetToWelcome() {
    path = []
    stage = .welcome
    exploreMode = .feed
  }
}
