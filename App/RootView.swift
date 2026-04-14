import SwiftUI

struct RootView: View {
  private static let logger = AppLogger.logger(category: "app.rootview")
  private let runtime: AppRuntime
  private let adventureService: AdventureService
  private let profileService: ProfileService
  private let sidekickService: SidekickService

  @Environment(\.scenePhase) private var scenePhase
  @StateObject private var coordinator: AppCoordinator
  @StateObject private var session: AppSession
  @State private var hasAttemptedSessionRestore = false

  init(
    runtime: AppRuntime,
    adventureService: AdventureService,
    profileService: ProfileService,
    sidekickService: SidekickService,
    backendAuthService: AuthService?,
    appAuthService: AppAuthService?,
    authState: AuthStateStore
  ) {
    self.runtime = runtime
    self.adventureService = adventureService
    self.profileService = profileService
    self.sidekickService = sidekickService
    _coordinator = StateObject(wrappedValue: AppCoordinator())
    _session = StateObject(
      wrappedValue: AppSession(
        runtime: runtime,
        backendAuthService: backendAuthService,
        appAuthService: appAuthService,
        profileService: profileService,
        authState: authState
      )
    )
  }

  var body: some View {
    NavigationStack(path: coordinator.pathBinding) {
      Group {
        switch coordinator.stage {
        case .welcome:
          WelcomeView(
            onGetStarted: { startWelcomeFlow(intent: .onboarding) },
            onSignIn: { startWelcomeFlow(intent: .signIn) }
          )

        case .emailEntry:
          EmailAuthView(
            intent: session.authIntent,
            onBack: { coordinator.stage = .welcome },
            onContinue: requestEmailCode
          )

        case .codeEntry:
          VerificationCodeView(
            challenge: session.pendingAuthChallenge,
            onBack: { coordinator.stage = .emailEntry },
            onResend: resendEmailCode,
            onContinue: verifyEmailCode
          )

        case .profileSetup:
          ProfileSetupView(
            initialDraft: session.profileDraft,
            showsSkip: session.showsProfileSkip,
            onBack: handleProfileBack,
            onSkip: { coordinator.stage = .explore },
            onContinue: continueProfileSetup
          )

        case .explore:
          ExploreShellView(
            adventureService: adventureService,
            profileService: profileService,
            sidekickService: sidekickService,
            runtimeMode: runtime.mode,
            viewerHandle: session.viewerHandle,
            viewerDisplayName: session.viewerDisplayName,
            mode: coordinator.exploreModeBinding,
            createAdventureVariant: coordinator.createAdventureBinding,
            onViewerProfileLoaded: session.seedViewerProfile,
            onOpenDetail: { adventureID in
              coordinator.path.append(.detail(adventureID))
            },
            onLogout: logout
          )
        }
      }
      .navigationDestination(for: AppRoute.self) { route in
        switch route {
        case .detail(let adventureID):
          AdventureDetailView(
            adventureID: adventureID,
            adventureService: adventureService,
            profileService: profileService,
            runtimeMode: runtime.mode
          )
        }
      }
    }
    .tint(HATheme.Colors.primary)
    .preferredColorScheme(.light)
    .task {
      guard hasAttemptedSessionRestore == false else { return }
      hasAttemptedSessionRestore = true

      guard runtime.usesFixturePreview == false, session.shouldRestoreAuthenticatedSession else {
        return
      }

      if let nextStage = await session.restoreAuthenticatedSession() {
        coordinator.stage = nextStage
      }
    }
    .onChange(of: scenePhase) { _, newPhase in
      guard newPhase == .active else { return }

      Task {
        _ = await session.refreshAuthenticatedSessionIfNeeded()
      }
    }
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
        .allowsHitTesting(false)
      }
    }
    .alert(
      "Hidden Adventures",
      isPresented: Binding(
        get: { session.alertMessage != nil },
        set: { if $0 == false { session.clearAlert() } }
      ),
      actions: {
        if session.canRetryAuthenticatedBootstrap {
          Button("Retry") {
            retryAuthenticatedBootstrap()
          }
        }
        Button("OK", role: .cancel) {
          session.clearAlert()
        }
      },
      message: {
        Text(session.alertMessage ?? "")
      }
    )
  }

  private func startWelcomeFlow(intent: WelcomeIntent) {
    Self.logger.info("Welcome action tapped intent=\(String(describing: intent), privacy: .public)")
    session.beginAuth(intent: intent)

    guard runtime.usesFixturePreview == false else {
      coordinator.stage = .profileSetup
      return
    }

    Self.logger.info("Welcome flow moving to email entry intent=\(String(describing: intent), privacy: .public)")
    coordinator.stage = .emailEntry
  }

  private func requestEmailCode(_ email: String) {
    Task {
      if let nextStage = await session.requestEmailCode(for: email) {
        coordinator.stage = nextStage
      }
    }
  }

  private func verifyEmailCode(_ code: String) {
    Task {
      if let nextStage = await session.verifyEmailCode(code) {
        coordinator.stage = nextStage
      }
    }
  }

  private func resendEmailCode() {
    Task {
      if let nextStage = await session.resendEmailCode() {
        coordinator.stage = nextStage
      }
    }
  }

  private func retryAuthenticatedBootstrap() {
    session.clearAlert()

    Task {
      if let nextStage = await session.restoreAuthenticatedSession() {
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
      if let nextStage = await session.completeProfileSetup(using: draft) {
        coordinator.stage = nextStage
      }
    }
  }

  private func handleProfileBack() {
    coordinator.stage = runtime.supportsInteractiveEmailAuth ? .codeEntry : .welcome
  }

  private func logout() {
    session.logout()
    coordinator.resetToWelcome()
  }
}

struct RootView_Previews: PreviewProvider {
  static var previews: some View {
    RootView(
      runtime: previewRuntime,
      adventureService: FixtureAdventureService(),
      profileService: FixtureProfileService(),
      sidekickService: FixtureSidekickService(),
      backendAuthService: nil,
      appAuthService: nil,
      authState: AuthStateStore()
    )
  }

  private static var previewRuntime: AppRuntime {
    AppRuntime(environment: ["HA_RUNTIME_MODE": "preview"])
  }
}
