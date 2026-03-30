import SwiftUI

struct RootView: View {
  private let runtime: AppRuntime
  private let adventureService: AdventureService
  private let profileService: ProfileService

  @StateObject private var coordinator: AppCoordinator
  @StateObject private var session: AppSession

  init(
    runtime: AppRuntime,
    adventureService: AdventureService,
    profileService: ProfileService,
    authService: AuthService?
  ) {
    self.runtime = runtime
    self.adventureService = adventureService
    self.profileService = profileService
    _coordinator = StateObject(wrappedValue: AppCoordinator())
    _session = StateObject(wrappedValue: AppSession(runtime: runtime, authService: authService))
  }

  var body: some View {
    NavigationStack(path: coordinator.pathBinding) {
      Group {
        switch coordinator.stage {
        case .welcome:
          WelcomeView(
            onGetStarted: startWelcomeFlow,
            onSignIn: startWelcomeFlow
          )

        case .profileSetup:
          ProfileSetupView(
            initialDraft: session.profileDraft,
            showsSkip: session.showsProfileSkip,
            usesHandleOnlyContract: session.requiresHandleOnlySetup,
            onBack: { coordinator.stage = .welcome },
            onSkip: { coordinator.stage = .explore },
            onContinue: continueProfileSetup
          )

        case .explore:
          ExploreShellView(
            adventureService: adventureService,
            profileService: profileService,
            runtimeMode: runtime.mode,
            viewerHandle: session.viewerHandle,
            viewerDisplayName: session.viewerDisplayName,
            mode: coordinator.exploreModeBinding,
            onViewerProfileLoaded: session.seedViewerProfile,
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
            runtimeMode: runtime.mode
          )
        }
      }
    }
    .tint(HATheme.Colors.primary)
    .preferredColorScheme(.light)
    .overlay {
      if session.isWorking {
        ZStack {
          Color.black.opacity(0.12)
            .ignoresSafeArea()

          ProgressView("Connecting to Hidden Adventures")
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(.white)
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .tint(HATheme.Colors.primary)
        }
      }
    }
    .alert(
      "Slice 1 Sign In",
      isPresented: Binding(
        get: { session.alertMessage != nil },
        set: { if $0 == false { session.clearAlert() } }
      ),
      actions: {
        Button("OK", role: .cancel) {
          session.clearAlert()
        }
      },
      message: {
        Text(session.alertMessage ?? "")
      }
    )
  }

  private func startWelcomeFlow() {
    guard runtime.usesFixturePreview == false else {
      coordinator.stage = .profileSetup
      return
    }

    Task {
      if let nextStage = await session.bootstrapFromWelcome() {
        coordinator.stage = nextStage
      }
    }
  }

  private func continueProfileSetup(_ draft: ProfileBootstrapDraft) {
    guard runtime.usesFixturePreview == false else {
      coordinator.stage = .explore
      return
    }

    Task {
      if let nextStage = await session.completeHandleSelection(using: draft) {
        coordinator.stage = nextStage
      }
    }
  }
}
