import SwiftUI

@main
struct HiddenAdventuresApp: App {
  private let runtime = AppRuntime()

  private var adventureService: AdventureService {
    if runtime.usesFixturePreview {
      return FixtureAdventureService()
    }

    return RemoteAdventureService(client: APIClient(baseURL: runtime.apiBaseURL, authToken: runtime.authToken))
  }

  private var profileService: ProfileService {
    if runtime.usesFixturePreview {
      return FixtureProfileService()
    }

    return RemoteProfileService(client: APIClient(baseURL: runtime.apiBaseURL, authToken: runtime.authToken))
  }

  private var authService: AuthService? {
    guard runtime.usesFixturePreview == false else {
      return nil
    }

    return RemoteAuthService(client: APIClient(baseURL: runtime.apiBaseURL, authToken: runtime.authToken))
  }

  var body: some Scene {
    WindowGroup {
      RootView(
        runtime: runtime,
        adventureService: adventureService,
        profileService: profileService,
        authService: authService
      )
    }
  }
}
