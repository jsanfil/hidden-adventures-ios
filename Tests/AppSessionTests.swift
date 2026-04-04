import XCTest
@testable import HiddenAdventures

final class AppSessionTests: XCTestCase {
  func testRestoreAuthenticatedSessionDoesNothingWithoutToken() async {
    let session = await makeSession(
      runtime: AppRuntime(
        environment: [
          "HA_RUNTIME_MODE": "live",
          "HA_SERVER_MODE": "local_manual_qa"
        ]
      ),
      backendAuthService: BackendAuthServiceStub(),
      appAuthService: AppAuthServiceStub(),
      profileService: ProfileServiceStub(),
      authState: AuthStateStore()
    )

    let nextStage = await session.restoreAuthenticatedSession()

    XCTAssertNil(nextStage)
  }

  func testRestoreAuthenticatedSessionRoutesLinkedUserToExplore() async {
    let backendAuthService = BackendAuthServiceStub()
    backendAuthService.bootstrapResponse = AuthBootstrapResponse(
      accountState: .linked,
      user: AuthBootstrapUser(
        id: "user-1",
        cognitoSubject: "sub-1",
        handle: "linked_user",
        email: "linked@example.com",
        accountOrigin: "rebuild_signup",
        status: "active",
        createdAt: "2026-04-03T10:00:00Z",
        updatedAt: "2026-04-03T10:00:00Z"
      ),
      suggestedHandle: nil,
      recoveryEmail: nil
    )

    let session = await makeSession(
      runtime: AppRuntime(
        environment: [
          "HA_RUNTIME_MODE": "live",
          "HA_SERVER_MODE": "local_manual_qa"
        ]
      ),
      backendAuthService: backendAuthService,
      appAuthService: AppAuthServiceStub(),
      profileService: ProfileServiceStub(),
      authState: AuthStateStore(initialTokens: .environmentOverride(token: "token"))
    )

    let nextStage = await session.restoreAuthenticatedSession()
    let viewerHandle = await MainActor.run { session.viewerHandle }

    XCTAssertEqual(nextStage, .explore)
    XCTAssertEqual(viewerHandle, "linked_user")
  }

  func testVerifyEmailCodeRoutesNewUserToProfileSetup() async {
    let backendAuthService = BackendAuthServiceStub()
    backendAuthService.bootstrapResponse = AuthBootstrapResponse(
      accountState: .newUserNeedsHandle,
      user: nil,
      suggestedHandle: "new_user",
      recoveryEmail: nil
    )

    let appAuthService = AppAuthServiceStub()
    appAuthService.startResult = .challenge(
      PendingAuthChallenge(
        kind: .signIn,
        email: "new@example.com",
        deliveryDestination: "n•••@example.com",
        session: "session-1"
      )
    )
    appAuthService.verifyResult = .authenticated(.environmentOverride(token: "verified-token"))

    let session = await makeSession(
      runtime: AppRuntime(
        environment: [
          "HA_RUNTIME_MODE": "live",
          "HA_SERVER_MODE": "local_manual_qa"
        ]
      ),
      backendAuthService: backendAuthService,
      appAuthService: appAuthService,
      profileService: ProfileServiceStub(),
      authState: AuthStateStore()
    )

    await MainActor.run {
      session.beginAuth(intent: .onboarding)
    }
    _ = await session.requestEmailCode(for: "new@example.com")
    let nextStage = await session.verifyEmailCode("123456")
    let suggestedHandle = await MainActor.run { session.profileDraft.handle }

    XCTAssertEqual(nextStage, .profileSetup)
    XCTAssertEqual(suggestedHandle, "new_user")
  }

  func testLogoutClearsViewerStateAndToken() async {
    let backendAuthService = BackendAuthServiceStub()
    backendAuthService.bootstrapResponse = AuthBootstrapResponse(
      accountState: .linked,
      user: AuthBootstrapUser(
        id: "user-1",
        cognitoSubject: "sub-1",
        handle: "linked_user",
        email: "linked@example.com",
        accountOrigin: "rebuild_signup",
        status: "active",
        createdAt: "2026-04-03T10:00:00Z",
        updatedAt: "2026-04-03T10:00:00Z"
      ),
      suggestedHandle: nil,
      recoveryEmail: nil
    )

    let authState = AuthStateStore(initialTokens: .environmentOverride(token: "token"))
    let session = await makeSession(
      runtime: AppRuntime(
        environment: [
          "HA_RUNTIME_MODE": "live",
          "HA_SERVER_MODE": "local_manual_qa"
        ]
      ),
      backendAuthService: backendAuthService,
      appAuthService: AppAuthServiceStub(),
      profileService: ProfileServiceStub(),
      authState: authState
    )

    _ = await session.restoreAuthenticatedSession()
    await MainActor.run {
      session.logout()
    }
    let viewerHandle = await MainActor.run { session.viewerHandle }

    XCTAssertNil(authState.bearerToken)
    XCTAssertNil(viewerHandle)
  }

  func testCompleteProfileSetupPersistsProfileDetails() async {
    let backendAuthService = BackendAuthServiceStub()
    backendAuthService.handleSelectionResponse = AuthBootstrapResponse(
      accountState: .linked,
      user: AuthBootstrapUser(
        id: "user-1",
        cognitoSubject: "sub-1",
        handle: "new_user",
        email: "new@example.com",
        accountOrigin: "rebuild_signup",
        status: "active",
        createdAt: "2026-04-03T10:00:00Z",
        updatedAt: "2026-04-03T10:00:00Z"
      ),
      suggestedHandle: nil,
      recoveryEmail: nil
    )

    let profileService = ProfileServiceStub()
    profileService.updatedProfile = ProfileDetail(
      id: "profile-1",
      handle: "new_user",
      displayName: "Jordan",
      bio: "Explorer",
      homeCity: "Portland",
      homeRegion: "OR",
      avatar: nil,
      cover: nil,
      createdAt: "2026-04-03T10:00:00Z",
      updatedAt: "2026-04-03T10:00:00Z"
    )

    let session = await makeSession(
      runtime: AppRuntime(
        environment: [
          "HA_RUNTIME_MODE": "live",
          "HA_SERVER_MODE": "local_manual_qa"
        ]
      ),
      backendAuthService: backendAuthService,
      appAuthService: AppAuthServiceStub(),
      profileService: profileService,
      authState: AuthStateStore(initialTokens: .environmentOverride(token: "token"))
    )

    let nextStage = await session.completeProfileSetup(
      using: ProfileBootstrapDraft(
        displayName: "Jordan",
        handle: "new_user",
        homeCity: "Portland",
        homeRegion: "OR",
        bio: "Explorer",
        initials: "JD"
      )
    )
    let viewerDisplayName = await MainActor.run { session.viewerDisplayName }

    XCTAssertEqual(nextStage, .explore)
    XCTAssertEqual(viewerDisplayName, "Jordan")
  }

  @MainActor
  private func makeSession(
    runtime: AppRuntime,
    backendAuthService: AuthService,
    appAuthService: AppAuthService,
    profileService: ProfileService,
    authState: AuthStateStore
  ) -> AppSession {
    AppSession(
      runtime: runtime,
      backendAuthService: backendAuthService,
      appAuthService: appAuthService,
      profileService: profileService,
      authState: authState
    )
  }
}

private final class BackendAuthServiceStub: AuthService {
  var bootstrapResponse = AuthBootstrapResponse(
    accountState: .linked,
    user: AuthBootstrapUser(
      id: "user-1",
      cognitoSubject: "sub-1",
      handle: "linked_user",
      email: "linked@example.com",
      accountOrigin: "rebuild_signup",
      status: "active",
      createdAt: "2026-04-03T10:00:00Z",
      updatedAt: "2026-04-03T10:00:00Z"
    ),
    suggestedHandle: nil,
    recoveryEmail: nil
  )
  var handleSelectionResponse = AuthBootstrapResponse(
    accountState: .linked,
    user: AuthBootstrapUser(
      id: "user-1",
      cognitoSubject: "sub-1",
      handle: "linked_user",
      email: "linked@example.com",
      accountOrigin: "rebuild_signup",
      status: "active",
      createdAt: "2026-04-03T10:00:00Z",
      updatedAt: "2026-04-03T10:00:00Z"
    ),
    suggestedHandle: nil,
    recoveryEmail: nil
  )

  func bootstrap() async throws -> AuthBootstrapResponse {
    bootstrapResponse
  }

  func completeHandleSelection(handle: String) async throws -> AuthBootstrapResponse {
    handleSelectionResponse
  }
}

private final class AppAuthServiceStub: AppAuthService {
  var restoredTokens: AuthTokens?
  var startResult: AuthFlowResult = .challenge(
    PendingAuthChallenge(
      kind: .signIn,
      email: "linked@example.com",
      deliveryDestination: "l•••@example.com",
      session: "session"
    )
  )
  var verifyResult: AuthFlowResult = .authenticated(.environmentOverride(token: "token"))

  func restoreSession() -> AuthTokens? {
    restoredTokens
  }

  func start(email: String, intent: WelcomeIntent) async throws -> AuthFlowResult {
    startResult
  }

  func verify(code: String, challenge: PendingAuthChallenge) async throws -> AuthFlowResult {
    verifyResult
  }

  func logout() {}
}

private final class ProfileServiceStub: ProfileService {
  var updatedProfile = ProfileDetail(
    id: "profile-linked-user",
    handle: "linked_user",
    displayName: "Linked User",
    bio: nil,
    homeCity: nil,
    homeRegion: nil,
    avatar: nil,
    cover: nil,
    createdAt: "2026-04-03T10:00:00Z",
    updatedAt: "2026-04-03T10:00:00Z"
  )

  func getProfile(handle: String, limit: Int, offset: Int) async throws -> ProfileResponse {
    ProfileResponse(profile: updatedProfile, adventures: [], paging: Paging(limit: limit, offset: offset, returned: 0))
  }

  func getMyProfile() async throws -> MeProfileResponse {
    MeProfileResponse(profile: updatedProfile)
  }

  func updateMyProfile(request: MeProfileUpdateRequest) async throws -> MeProfileResponse {
    MeProfileResponse(profile: updatedProfile)
  }
}
