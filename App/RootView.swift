import SwiftUI

struct RootView: View {
  private let adventureService: AdventureService
  private let profileService: ProfileService

  @StateObject private var coordinator = AppCoordinator()

  init(
    adventureService: AdventureService,
    profileService: ProfileService
  ) {
    self.adventureService = adventureService
    self.profileService = profileService
  }

  var body: some View {
    NavigationStack(path: coordinator.pathBinding) {
      Group {
        switch coordinator.stage {
        case .welcome:
          WelcomeView {
            coordinator.stage = .profileSetup
          }

        case .profileSetup:
          ProfileSetupView(
            profileService: profileService,
            onBack: { coordinator.stage = .welcome },
            onSkip: { coordinator.stage = .explore },
            onContinue: { _ in coordinator.stage = .explore }
          )

        case .explore:
          ExploreShellView(
            adventureService: adventureService,
            viewerHandle: coordinator.viewerHandle,
            mode: coordinator.exploreModeBinding,
            onOpenDetail: { adventureID in
              coordinator.path.append(.detail(adventureID))
            }
          )
        }
      }
      .navigationDestination(for: AppRoute.self) { route in
        switch route {
        case .detail(let adventureID):
          AdventureDetailView(
            adventureID: adventureID,
            adventureService: adventureService,
            viewerHandle: coordinator.viewerHandle
          )
        }
      }
    }
    .tint(HATheme.Colors.primary)
    .preferredColorScheme(.light)
  }
}
