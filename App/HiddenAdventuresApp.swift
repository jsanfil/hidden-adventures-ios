import SwiftUI

@main
struct HiddenAdventuresApp: App {
  private let runtime = AppRuntime()
  private let authState: AuthStateStore

  init() {
    if let authToken = runtime.authToken {
      authState = AuthStateStore(initialTokens: .environmentOverride(token: authToken))
    } else {
      authState = AuthStateStore()
    }
  }

  private var apiClient: APIClient {
    let authState = authState
    return APIClient(
      baseURL: runtime.apiBaseURL,
      authTokenProvider: { authState.bearerToken }
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
        backendAuthService: backendAuthService,
        appAuthService: appAuthService,
        authState: authState
      )
    }
  }
}
