import SwiftUI

@main
struct HiddenAdventuresApp: App {
  private static let logger = AppLogger.logger(category: "app.startup")
  private let runtime = AppRuntime()
  private let authState: AuthStateStore

  init() {
    if let authToken = runtime.authToken {
      authState = AuthStateStore(initialTokens: .environmentOverride(token: authToken))
    } else {
      authState = AuthStateStore()
    }

    let runtimeMode = runtime.mode
    let serverMode = runtime.serverMode
    let startupMessage = "App launch started mode=\(runtimeMode.rawValue) serverMode=\(serverMode.rawValue)"

    Self.logger.info("\(startupMessage, privacy: .public)")
  }

  private var apiClient: APIClient {
    let authState = authState
    let appAuthService = appAuthService
    let logger = Self.logger
    return APIClient(
      baseURL: runtime.apiBaseURL,
      authTokenProvider: { authState.bearerToken },
      authTokenRefresher: {
        guard let appAuthService, let tokens = authState.currentTokens else {
          return false
        }

        do {
          guard let refreshedTokens = try await appAuthService.refresh(tokens: tokens) else {
            return false
          }

          authState.replace(tokens: refreshedTokens)
          return true
        } catch {
          logger.error("Auth token refresh failed: \(error.localizedDescription, privacy: .public)")
          return false
        }
      }
    )
  }

  private var adventureService: AdventureService {
    if runtime.usesFixturePreview {
      return FixtureAdventureService()
    }

    return RemoteAdventureService(client: apiClient)
  }

  private var profileService: ProfileService {
    if runtime.usesFixturePreview {
      return FixtureProfileService()
    }

    return RemoteProfileService(client: apiClient)
  }

  private var sidekickService: SidekickService {
    if runtime.usesFixturePreview {
      return FixtureSidekickService()
    }

    return RemoteSidekickService(client: apiClient)
  }

  private var backendAuthService: AuthService? {
    guard runtime.usesFixturePreview == false else {
      return nil
    }

    return RemoteAuthService(client: apiClient)
  }

  private var appAuthService: AppAuthService? {
    guard runtime.supportsInteractiveEmailAuth else {
      return nil
    }

    guard let region = runtime.cognitoRegion, let clientID = runtime.cognitoClientID else {
      return nil
    }

    return CognitoAppAuthService(
      configuration: CognitoConfiguration(region: region, clientID: clientID)
    )
  }

  var body: some Scene {
    WindowGroup {
      RootView(
        runtime: runtime,
        adventureService: adventureService,
        profileService: profileService,
        sidekickService: sidekickService,
        backendAuthService: backendAuthService,
        appAuthService: appAuthService,
        authState: authState
      )
    }
  }
}
