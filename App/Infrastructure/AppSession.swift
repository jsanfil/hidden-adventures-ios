import Foundation

@MainActor
final class AppSession: ObservableObject {
  let runtime: AppRuntime

  private let backendAuthService: AuthService?
  private let appAuthService: AppAuthService?
  private let profileService: ProfileService
  private let authState: AuthStateStore

  @Published var viewerHandle: String?
  @Published var viewerDisplayName: String?
  @Published var profileDraft: ProfileBootstrapDraft
  @Published var pendingAuthChallenge: PendingAuthChallenge?
  @Published var authIntent: WelcomeIntent = .onboarding
  @Published var isWorking = false
  @Published var alertMessage: String?
  @Published var canRetryAuthenticatedBootstrap = false

  init(
    runtime: AppRuntime,
    backendAuthService: AuthService?,
    appAuthService: AppAuthService?,
    profileService: ProfileService,
    authState: AuthStateStore
  ) {
    self.runtime = runtime
    self.backendAuthService = backendAuthService
    self.appAuthService = appAuthService
    self.profileService = profileService
    self.authState = authState

    if runtime.usesFixturePreview {
      viewerHandle = MockFixtures.profile.handle
      viewerDisplayName = MockFixtures.profile.displayName ?? MockFixtures.profile.handle
      profileDraft = MockFixtures.bootstrapDraft
    } else {
      viewerHandle = nil
      viewerDisplayName = nil
      profileDraft = .blank
    }

    if runtime.usesFixturePreview == false,
       runtime.authToken == nil,
       let restoredTokens = appAuthService?.restoreSession() {
      authState.replace(tokens: restoredTokens)
    }
  }

  var showsProfileSkip: Bool {
    runtime.usesFixturePreview
  }

  var shouldRestoreAuthenticatedSession: Bool {
    authState.bearerToken != nil
  }

  var usesDirectBootstrapFlow: Bool {
    runtime.usesFixturePreview == false && runtime.supportsInteractiveEmailAuth == false
  }

  func beginAuth(intent: WelcomeIntent) {
    authIntent = intent
    pendingAuthChallenge = nil
    canRetryAuthenticatedBootstrap = false
  }

  func restoreAuthenticatedSession() async -> AppStage? {
    await bootstrapAuthenticatedSession(clearSessionOnFailure: true)
  }

  func bootstrapFromWelcome() async -> AppStage? {
    await bootstrapAuthenticatedSession(clearSessionOnFailure: false)
  }

  func requestEmailCode(for email: String) async -> AppStage? {
    let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
    guard trimmedEmail.isEmpty == false else {
      alertMessage = "Enter a valid email address to continue."
      return nil
    }

    guard let appAuthService else {
      alertMessage = """
      Email sign-in isn't configured for this build. Set HA_COGNITO_REGION and \
      HA_COGNITO_CLIENT_ID to enable interactive email auth.
      """
      return nil
    }

    return await runAuthenticatedAction {
      let result = try await appAuthService.start(email: trimmedEmail, intent: self.authIntent)
      return await self.advance(after: result)
    }
  }

  func resendEmailCode() async -> AppStage? {
    guard let appAuthService, let pendingAuthChallenge else {
      alertMessage = "Start over and request a new verification code."
      return nil
    }

    return await runAuthenticatedAction {
      let result = try await appAuthService.resend(challenge: pendingAuthChallenge, intent: self.authIntent)
      return await self.advance(after: result)
    }
  }

  func verifyEmailCode(_ code: String) async -> AppStage? {
    guard let appAuthService, let pendingAuthChallenge else {
      alertMessage = "Start over and request a new verification code."
      return nil
    }

    return await runAuthenticatedAction {
      let result = try await appAuthService.verify(code: code, challenge: pendingAuthChallenge)
      return await self.advance(after: result)
    }
  }

  func completeProfileSetup(using draft: ProfileBootstrapDraft) async -> AppStage? {
    guard let backendAuthService else {
      return nil
    }

    profileDraft = draft

    return await runAuthenticatedAction {
      let bootstrapResponse = try await backendAuthService.completeHandleSelection(handle: draft.handle)
      let nextStage = self.apply(bootstrapResponse: bootstrapResponse)
      guard nextStage == .explore else {
        return nextStage
      }

      let savedProfile = try await self.profileService.updateMyProfile(request: draft.updateRequest)
      self.seedViewerProfile(savedProfile.profile)
      return .explore
    }
  }

  func logout() {
    appAuthService?.logout()
    authState.replace(tokens: runtime.authToken.map(AuthTokens.environmentOverride(token:)))
    pendingAuthChallenge = nil
    canRetryAuthenticatedBootstrap = false
    viewerHandle = nil
    viewerDisplayName = nil
    profileDraft = runtime.usesFixturePreview ? MockFixtures.bootstrapDraft : .blank
  }

  func seedViewerProfile(_ profile: ProfileDetail) {
    guard viewerHandle == profile.handle else { return }
    viewerDisplayName = profile.displayName ?? profile.handle
    profileDraft = profileDraft.merging(profile: profile)
  }

  func clearAlert() {
    alertMessage = nil
  }

  private func bootstrapAuthenticatedSession(clearSessionOnFailure: Bool) async -> AppStage? {
    guard let backendAuthService, authState.bearerToken != nil else {
      return nil
    }

    isWorking = true
    defer { isWorking = false }

    do {
      let response = try await backendAuthService.bootstrap()
      if response.accountState == .linked, let profile = try? await self.profileService.getMyProfile() {
        self.seedViewerProfile(profile.profile)
      }
      canRetryAuthenticatedBootstrap = false
      return self.apply(bootstrapResponse: response)
    } catch {
      if shouldClearAuthenticatedSession(for: error, clearSessionOnFailure: clearSessionOnFailure) {
        appAuthService?.logout()
        authState.replace(tokens: runtime.authToken.map(AuthTokens.environmentOverride(token:)))
        canRetryAuthenticatedBootstrap = false
        alertMessage = userFacingMessage(for: error)
        return .welcome
      }

      canRetryAuthenticatedBootstrap = true
      alertMessage = recoverableBootstrapMessage(for: error)
      return .welcome
    }
  }

  private func advance(after result: AuthFlowResult) async -> AppStage {
    switch result {
    case .challenge(let challenge):
      pendingAuthChallenge = challenge
      canRetryAuthenticatedBootstrap = false
      if case .signIn = challenge.kind {
        profileDraft = profileDraft.withEmailDerivedInitials(from: challenge.email)
      }
      return .codeEntry

    case .authenticated(let tokens):
      authState.replace(tokens: tokens)
      pendingAuthChallenge = nil
      return await bootstrapAuthenticatedSession(clearSessionOnFailure: true) ?? .welcome
    }
  }

  private func runAuthenticatedAction(
    clearSessionOnFailure: Bool = false,
    _ work: @escaping () async throws -> AppStage
  ) async -> AppStage? {
    isWorking = true
    defer { isWorking = false }

    do {
      return try await work()
    } catch {
      if clearSessionOnFailure {
        appAuthService?.logout()
        authState.replace(tokens: runtime.authToken.map(AuthTokens.environmentOverride(token:)))
      }
      alertMessage = userFacingMessage(for: error)
      return nil
    }
  }

  private func shouldClearAuthenticatedSession(
    for error: Error,
    clearSessionOnFailure: Bool
  ) -> Bool {
    guard clearSessionOnFailure else {
      return false
    }

    guard let apiError = error as? APIError else {
      return false
    }

    switch apiError {
    case .missingAuthToken:
      return true
    case .server(let statusCode, _):
      return statusCode == 401 || statusCode == 403
    case .invalidBaseURL, .invalidResponse, .transport, .decoding:
      return false
    }
  }

  private func recoverableBootstrapMessage(for error: Error) -> String {
    let detail = userFacingMessage(for: error)
    guard detail.isEmpty == false else {
      return "Your email code worked, but the Hidden Adventures server is unavailable. Start the server and retry. You do not need a new code."
    }

    return """
    Your email code worked, but the Hidden Adventures server is unavailable. Start the server and retry. You do not need a new code.

    Details: \(detail)
    """
  }

  private func apply(bootstrapResponse: AuthBootstrapResponse) -> AppStage {
    switch bootstrapResponse.accountState {
    case .linked, .legacyClaimed:
      guard let user = bootstrapResponse.user else {
        alertMessage = "The auth bootstrap completed without a linked user."
        return .welcome
      }

      viewerHandle = user.handle
      viewerDisplayName = user.handle
      profileDraft = draft(for: bootstrapResponse)
      return .explore

    case .newUserNeedsHandle:
      viewerHandle = nil
      viewerDisplayName = nil
      profileDraft = draft(for: bootstrapResponse)
      return .profileSetup

    case .manualRecoveryRequired:
      viewerHandle = nil
      viewerDisplayName = nil
      profileDraft = draft(for: bootstrapResponse)
      if let recoveryEmail = bootstrapResponse.recoveryEmail {
        alertMessage = "This account needs manual recovery before Slice 1 can continue. Recovery email: \(recoveryEmail)"
      } else {
        alertMessage = "This account needs manual recovery before Slice 1 can continue."
      }
      return .welcome
    }
  }

  private func draft(for response: AuthBootstrapResponse) -> ProfileBootstrapDraft {
    let handle = response.user?.handle
      ?? response.suggestedHandle
      ?? Self.suggestedPublicHandle(from: response.recoveryEmail)
      ?? ""
    return ProfileBootstrapDraft(
      displayName: "",
      handle: handle,
      homeCity: "",
      homeRegion: "",
      bio: "",
      initials: Self.initials(for: handle)
    )
  }

  private func userFacingMessage(for error: Error) -> String {
    if let localized = (error as? LocalizedError)?.errorDescription {
      return localized
    }

    return error.localizedDescription
  }

  private static func initials(for handle: String) -> String {
    let cleaned = handle
      .replacingOccurrences(of: "_", with: " ")
      .split(separator: " ")
      .prefix(2)
      .compactMap(\.first)
      .map { String($0).uppercased() }
      .joined()

    return cleaned.isEmpty ? "HA" : cleaned
  }

  private static func suggestedPublicHandle(from email: String?) -> String? {
    guard let email else {
      return nil
    }

    let localPart = email
      .trimmingCharacters(in: .whitespacesAndNewlines)
      .lowercased()
      .split(separator: "@")
      .first
      .map(String.init) ?? ""

    let sanitized = localPart
      .replacingOccurrences(of: "[^a-z0-9]+", with: "_", options: .regularExpression)
      .replacingOccurrences(of: "_+", with: "_", options: .regularExpression)
      .trimmingCharacters(in: CharacterSet(charactersIn: "_"))

    if sanitized.isEmpty {
      return "explorer"
    }

    return String(sanitized.prefix(64))
  }
}

private extension ProfileBootstrapDraft {
  static let blank = ProfileBootstrapDraft(
    displayName: "",
    handle: "",
    homeCity: "",
    homeRegion: "",
    bio: "",
    initials: "HA"
  )

  func withEmailDerivedInitials(from email: String) -> ProfileBootstrapDraft {
    var copy = self
    if copy.initials == "HA" {
      copy.initials = String(email.prefix(2)).uppercased()
    }
    return copy
  }

  func merging(profile: ProfileDetail) -> ProfileBootstrapDraft {
    ProfileBootstrapDraft(
      displayName: profile.displayName ?? displayName,
      handle: profile.handle,
      homeCity: profile.homeCity ?? homeCity,
      homeRegion: profile.homeRegion ?? homeRegion,
      bio: profile.bio ?? bio,
      initials: initials
    )
  }
}
