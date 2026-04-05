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

  func testForegroundRefreshDoesNothingWithoutToken() async {
    let appAuthService = AppAuthServiceStub()
    let authState = AuthStateStore()
    let session = await makeSession(
      runtime: AppRuntime(
        environment: [
          "HA_RUNTIME_MODE": "live",
          "HA_SERVER_MODE": "local_manual_qa"
        ]
      ),
      backendAuthService: BackendAuthServiceStub(),
      appAuthService: appAuthService,
      profileService: ProfileServiceStub(),
      authState: authState
    )

    let didRefresh = await session.refreshAuthenticatedSessionIfNeeded()

    XCTAssertFalse(didRefresh)
    XCTAssertTrue(appAuthService.refreshInvocations.isEmpty)
    XCTAssertNil(authState.bearerToken)
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

  func testForegroundRefreshUpdatesExpiredTokens() async {
    let appAuthService = AppAuthServiceStub()
    appAuthService.refreshResult = AuthTokens(
      idToken: "refreshed-id-token",
      accessToken: "refreshed-access-token",
      refreshToken: "refresh-token",
      expiresAt: Date.distantFuture
    )

    let expiredTokens = AuthTokens(
      idToken: "expired-id-token",
      accessToken: "expired-access-token",
      refreshToken: "refresh-token",
      expiresAt: Date(timeIntervalSince1970: 1)
    )
    let authState = AuthStateStore(initialTokens: expiredTokens)
    let session = await makeSession(
      runtime: AppRuntime(
        environment: [
          "HA_RUNTIME_MODE": "live",
          "HA_SERVER_MODE": "local_manual_qa"
        ]
      ),
      backendAuthService: BackendAuthServiceStub(),
      appAuthService: appAuthService,
      profileService: ProfileServiceStub(),
      authState: authState
    )

    let didRefresh = await session.refreshAuthenticatedSessionIfNeeded()
    let currentTokens = authState.currentTokens

    XCTAssertTrue(didRefresh)
    XCTAssertEqual(appAuthService.refreshInvocations.count, 1)
    XCTAssertEqual(appAuthService.refreshInvocations.first?.idToken, "expired-id-token")
    XCTAssertEqual(currentTokens?.idToken, "refreshed-id-token")
    XCTAssertEqual(currentTokens?.accessToken, "refreshed-access-token")
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
        kind: .signUp,
        cognitoUsername: "new_1853b7412ac94d75cb23e033",
        email: "new@example.com",
        deliveryDestination: "n•••@example.com",
        session: nil
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

  func testVerifyEmailCodeDerivesFriendlyHandleFromRecoveryEmailWhenSuggestionMissing() async {
    let backendAuthService = BackendAuthServiceStub()
    backendAuthService.bootstrapResponse = AuthBootstrapResponse(
      accountState: .newUserNeedsHandle,
      user: nil,
      suggestedHandle: nil,
      recoveryEmail: "joe.sanfilippo+qa@example.com"
    )

    let appAuthService = AppAuthServiceStub()
    appAuthService.startResult = .challenge(
      PendingAuthChallenge(
        kind: .signUp,
        cognitoUsername: "joe_sanfilippo_qa_1234567890abcdef12345678",
        email: "joe.sanfilippo+qa@example.com",
        deliveryDestination: "j•••@example.com",
        session: nil
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
    _ = await session.requestEmailCode(for: "joe.sanfilippo+qa@example.com")
    let nextStage = await session.verifyEmailCode("123456")
    let suggestedHandle = await MainActor.run { session.profileDraft.handle }

    XCTAssertEqual(nextStage, .profileSetup)
    XCTAssertEqual(suggestedHandle, "joe_sanfilippo_qa")
  }

  func testVerifyEmailCodeFallsBackToExplorerHandleWhenRecoveryEmailLocalPartIsInvalid() async {
    let backendAuthService = BackendAuthServiceStub()
    backendAuthService.bootstrapResponse = AuthBootstrapResponse(
      accountState: .newUserNeedsHandle,
      user: nil,
      suggestedHandle: nil,
      recoveryEmail: "+++@example.com"
    )

    let appAuthService = AppAuthServiceStub()
    appAuthService.startResult = .challenge(
      PendingAuthChallenge(
        kind: .signUp,
        cognitoUsername: "user_1234567890abcdef12345678",
        email: "+++@example.com",
        deliveryDestination: "•••@example.com",
        session: nil
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
    _ = await session.requestEmailCode(for: "+++@example.com")
    let nextStage = await session.verifyEmailCode("123456")
    let suggestedHandle = await MainActor.run { session.profileDraft.handle }

    XCTAssertEqual(nextStage, .profileSetup)
    XCTAssertEqual(suggestedHandle, "explorer")
  }

  func testVerifyEmailCodePreservesTokensWhenBootstrapTransportFails() async {
    let backendAuthService = BackendAuthServiceStub()
    backendAuthService.bootstrapError = APIError.transport(NSError(domain: NSURLErrorDomain, code: NSURLErrorCannotConnectToHost))

    let appAuthService = AppAuthServiceStub()
    appAuthService.startResult = .challenge(
      PendingAuthChallenge(
        kind: .signIn,
        cognitoUsername: "linked@example.com",
        email: "linked@example.com",
        deliveryDestination: "l•••@example.com",
        session: "session-1"
      )
    )
    appAuthService.verifyResult = .authenticated(.environmentOverride(token: "verified-token"))

    let authState = AuthStateStore()
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
      authState: authState
    )

    await MainActor.run {
      session.beginAuth(intent: .signIn)
    }
    _ = await session.requestEmailCode(for: "linked@example.com")
    let nextStage = await session.verifyEmailCode("123456")
    let canRetry = await MainActor.run { session.canRetryAuthenticatedBootstrap }
    let alertMessage = await MainActor.run { session.alertMessage }
    let pendingChallenge = await MainActor.run { session.pendingAuthChallenge }

    XCTAssertEqual(nextStage, .welcome)
    XCTAssertEqual(authState.bearerToken, "verified-token")
    XCTAssertTrue(canRetry)
    XCTAssertEqual(appAuthService.logoutCallCount, 0)
    XCTAssertNil(pendingChallenge)
    XCTAssertTrue(alertMessage?.contains("Your email code worked") == true)
    XCTAssertTrue(alertMessage?.contains("You do not need a new code.") == true)
  }

  func testVerifyEmailCodeClearsTokensWhenBootstrapReturnsUnauthorized() async {
    let backendAuthService = BackendAuthServiceStub()
    backendAuthService.bootstrapError = APIError.server(statusCode: 401, message: "Unauthorized")

    let appAuthService = AppAuthServiceStub()
    appAuthService.startResult = .challenge(
      PendingAuthChallenge(
        kind: .signIn,
        cognitoUsername: "linked@example.com",
        email: "linked@example.com",
        deliveryDestination: "l•••@example.com",
        session: "session-1"
      )
    )
    appAuthService.verifyResult = .authenticated(.environmentOverride(token: "verified-token"))

    let authState = AuthStateStore()
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
      authState: authState
    )

    await MainActor.run {
      session.beginAuth(intent: .signIn)
    }
    _ = await session.requestEmailCode(for: "linked@example.com")
    let nextStage = await session.verifyEmailCode("123456")
    let canRetry = await MainActor.run { session.canRetryAuthenticatedBootstrap }

    XCTAssertEqual(nextStage, .welcome)
    XCTAssertNil(authState.bearerToken)
    XCTAssertFalse(canRetry)
    XCTAssertEqual(appAuthService.logoutCallCount, 1)
  }

  func testResendEmailCodeReplacesPendingChallenge() async {
    let appAuthService = AppAuthServiceStub()
    appAuthService.startResult = .challenge(
      PendingAuthChallenge(
        kind: .signIn,
        cognitoUsername: "linked@example.com",
        email: "linked@example.com",
        deliveryDestination: "l•••@example.com",
        session: "session-1"
      )
    )
    appAuthService.resendResult = .challenge(
      PendingAuthChallenge(
        kind: .signIn,
        cognitoUsername: "linked@example.com",
        email: "linked@example.com",
        deliveryDestination: "li•••@example.com",
        session: "session-2"
      )
    )

    let session = await makeSession(
      runtime: AppRuntime(
        environment: [
          "HA_RUNTIME_MODE": "live",
          "HA_SERVER_MODE": "local_manual_qa"
        ]
      ),
      backendAuthService: BackendAuthServiceStub(),
      appAuthService: appAuthService,
      profileService: ProfileServiceStub(),
      authState: AuthStateStore()
    )

    await MainActor.run {
      session.beginAuth(intent: .signIn)
    }
    _ = await session.requestEmailCode(for: "linked@example.com")
    let nextStage = await session.resendEmailCode()
    let pendingChallenge = await MainActor.run { session.pendingAuthChallenge }

    XCTAssertEqual(nextStage, .codeEntry)
    XCTAssertEqual(appAuthService.startInvocations.count, 1)
    XCTAssertEqual(appAuthService.resendInvocations.count, 1)
    XCTAssertEqual(appAuthService.resendInvocations.last?.challenge.email, "linked@example.com")
    XCTAssertEqual(appAuthService.resendInvocations.last?.intent, .signIn)
    XCTAssertEqual(pendingChallenge?.session, "session-2")
    XCTAssertEqual(pendingChallenge?.deliveryDestination, "li•••@example.com")
  }

  func testResendEmailCodeForSignUpUsesConfirmationResend() async {
    let appAuthService = AppAuthServiceStub()
    appAuthService.startResult = .challenge(
      PendingAuthChallenge(
        kind: .signUp,
        cognitoUsername: "email_signup_username",
        email: "new@example.com",
        deliveryDestination: "n•••@example.com",
        session: nil
      )
    )
    appAuthService.resendResult = .challenge(
      PendingAuthChallenge(
        kind: .signUp,
        cognitoUsername: "email_signup_username",
        email: "new@example.com",
        deliveryDestination: "ne•••@example.com",
        session: nil
      )
    )

    let session = await makeSession(
      runtime: AppRuntime(
        environment: [
          "HA_RUNTIME_MODE": "live",
          "HA_SERVER_MODE": "local_manual_qa"
        ]
      ),
      backendAuthService: BackendAuthServiceStub(),
      appAuthService: appAuthService,
      profileService: ProfileServiceStub(),
      authState: AuthStateStore()
    )

    await MainActor.run {
      session.beginAuth(intent: .onboarding)
    }
    _ = await session.requestEmailCode(for: "new@example.com")
    let nextStage = await session.resendEmailCode()
    let pendingChallenge = await MainActor.run { session.pendingAuthChallenge }

    XCTAssertEqual(nextStage, .codeEntry)
    XCTAssertEqual(appAuthService.resendInvocations.count, 1)
    XCTAssertEqual(appAuthService.resendInvocations.last?.challenge.kind, .signUp)
    XCTAssertEqual(appAuthService.resendInvocations.last?.challenge.email, "new@example.com")
    XCTAssertEqual(appAuthService.resendInvocations.last?.intent, .onboarding)
    XCTAssertEqual(pendingChallenge?.kind, .signUp)
    XCTAssertEqual(pendingChallenge?.deliveryDestination, "ne•••@example.com")
  }

  func testVerifyEmailCodeShowsErrorWhenSignupAliasAlreadyExists() async {
    let appAuthService = AppAuthServiceStub()
    appAuthService.startResult = .challenge(
      PendingAuthChallenge(
        kind: .signUp,
        cognitoUsername: "existing_alias_signup",
        email: "linked@example.com",
        deliveryDestination: "l•••@example.com",
        session: nil
      )
    )
    appAuthService.verifyError = AppAuthError.service(
      code: "AliasExistsException",
      message: "Alias already exists"
    )

    let session = await makeSession(
      runtime: AppRuntime(
        environment: [
          "HA_RUNTIME_MODE": "live",
          "HA_SERVER_MODE": "local_manual_qa"
        ]
      ),
      backendAuthService: BackendAuthServiceStub(),
      appAuthService: appAuthService,
      profileService: ProfileServiceStub(),
      authState: AuthStateStore()
    )

    await MainActor.run {
      session.beginAuth(intent: .onboarding)
    }
    _ = await session.requestEmailCode(for: "linked@example.com")
    let nextStage = await session.verifyEmailCode("123456")
    let pendingChallenge = await MainActor.run { session.pendingAuthChallenge }
    let alertMessage = await MainActor.run { session.alertMessage }

    XCTAssertNil(nextStage)
    XCTAssertEqual(appAuthService.verifyInvocations.count, 1)
    XCTAssertEqual(appAuthService.startInvocations.count, 1)
    XCTAssertEqual(pendingChallenge?.kind, .signUp)
    XCTAssertNil(pendingChallenge?.session)
    XCTAssertEqual(alertMessage, "That email already has an account. Use Sign In.")
  }

  func testRestoreAuthenticatedSessionSucceedsAfterRecoverableBootstrapFailure() async {
    let backendAuthService = BackendAuthServiceStub()
    backendAuthService.bootstrapError = APIError.transport(NSError(domain: NSURLErrorDomain, code: NSURLErrorCannotConnectToHost))

    let appAuthService = AppAuthServiceStub()
    appAuthService.startResult = .challenge(
      PendingAuthChallenge(
        kind: .signIn,
        cognitoUsername: "linked@example.com",
        email: "linked@example.com",
        deliveryDestination: "l•••@example.com",
        session: "session-1"
      )
    )
    appAuthService.verifyResult = .authenticated(.environmentOverride(token: "verified-token"))

    let authState = AuthStateStore()
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
      authState: authState
    )

    await MainActor.run {
      session.beginAuth(intent: .signIn)
    }
    _ = await session.requestEmailCode(for: "linked@example.com")
    _ = await session.verifyEmailCode("123456")

    backendAuthService.bootstrapError = nil
    let nextStage = await session.restoreAuthenticatedSession()
    let canRetry = await MainActor.run { session.canRetryAuthenticatedBootstrap }

    XCTAssertEqual(nextStage, .explore)
    XCTAssertEqual(authState.bearerToken, "verified-token")
    XCTAssertFalse(canRetry)
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
  var bootstrapError: Error?
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
    if let bootstrapError {
      throw bootstrapError
    }
    return bootstrapResponse
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
      cognitoUsername: "linked@example.com",
      email: "linked@example.com",
      deliveryDestination: "l•••@example.com",
      session: "session"
    )
  )
  var startResults: [AuthFlowResult] = []
  var startInvocations: [(email: String, intent: WelcomeIntent)] = []
  var resendResult: AuthFlowResult?
  var resendInvocations: [(challenge: PendingAuthChallenge, intent: WelcomeIntent)] = []
  var verifyResult: AuthFlowResult = .authenticated(.environmentOverride(token: "token"))
  var verifyError: Error?
  var verifyInvocations: [(code: String, challenge: PendingAuthChallenge)] = []
  var refreshResult: AuthTokens?
  var refreshInvocations: [AuthTokens] = []
  var logoutCallCount = 0

  func restoreSession() -> AuthTokens? {
    restoredTokens
  }

  func start(email: String, intent: WelcomeIntent) async throws -> AuthFlowResult {
    startInvocations.append((email, intent))
    if startResults.isEmpty == false {
      return startResults.removeFirst()
    }
    return startResult
  }

  func resend(challenge: PendingAuthChallenge, intent: WelcomeIntent) async throws -> AuthFlowResult {
    resendInvocations.append((challenge, intent))
    return resendResult ?? startResult
  }

  func verify(code: String, challenge: PendingAuthChallenge) async throws -> AuthFlowResult {
    verifyInvocations.append((code, challenge))
    if let verifyError {
      throw verifyError
    }
    return verifyResult
  }

  func refresh(tokens: AuthTokens) async throws -> AuthTokens? {
    refreshInvocations.append(tokens)
    return refreshResult
  }

  func logout() {
    logoutCallCount += 1
  }
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
