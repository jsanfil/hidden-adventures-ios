import Foundation

@MainActor
final class AppSession: ObservableObject {
  let runtime: AppRuntime
  private let authService: AuthService?

  @Published var viewerHandle: String?
  @Published var viewerDisplayName: String?
  @Published var profileDraft: ProfileBootstrapDraft
  @Published var isWorking = false
  @Published var alertMessage: String?

  init(
    runtime: AppRuntime,
    authService: AuthService?
  ) {
    self.runtime = runtime
    self.authService = authService

    if runtime.usesFixturePreview {
      viewerHandle = MockFixtures.profile.handle
      viewerDisplayName = MockFixtures.profile.displayName ?? MockFixtures.profile.handle
      profileDraft = MockFixtures.bootstrapDraft
    } else {
      viewerHandle = nil
      viewerDisplayName = nil
      profileDraft = .blank
    }
  }

  var requiresHandleOnlySetup: Bool {
    runtime.mode == .liveServer
  }

  var showsProfileSkip: Bool {
    runtime.usesFixturePreview
  }

  func bootstrapFromWelcome() async -> AppStage? {
    guard let authService else {
      return nil
    }

    return await runAuthenticatedAction {
      let response = try await authService.bootstrap()
      return self.apply(bootstrapResponse: response)
    }
  }

  func completeHandleSelection(using draft: ProfileBootstrapDraft) async -> AppStage? {
    guard let authService else {
      return nil
    }

    profileDraft = draft

    return await runAuthenticatedAction {
      let response = try await authService.completeHandleSelection(handle: draft.handle)
      return self.apply(bootstrapResponse: response)
    }
  }

  func seedViewerProfile(_ profile: ProfileDetail) {
    guard viewerHandle == profile.handle else { return }
    viewerDisplayName = profile.displayName ?? profile.handle
  }

  func clearAlert() {
    alertMessage = nil
  }

  private func runAuthenticatedAction(
    _ work: @escaping () async throws -> AppStage
  ) async -> AppStage? {
    isWorking = true
    defer { isWorking = false }

    do {
      return try await work()
    } catch {
      alertMessage = userFacingMessage(for: error)
      return nil
    }
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
    let handle = response.user?.handle ?? response.suggestedHandle ?? ""
    return ProfileBootstrapDraft(
      displayName: "",
      handle: handle,
      homeBase: "",
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
}

private extension ProfileBootstrapDraft {
  static let blank = ProfileBootstrapDraft(
    displayName: "",
    handle: "",
    homeBase: "",
    bio: "",
    initials: "HA"
  )
}
