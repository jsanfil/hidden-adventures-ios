import Foundation

enum AppRuntimeMode: String {
  case liveServer
  case fixturePreview
}

enum AppServerMode: String {
  case localManualQA
  case localAutomation
  case production
}

struct AppRuntime {
  let mode: AppRuntimeMode
  let serverMode: AppServerMode
  let apiBaseURL: URL
  let authToken: String?
  let cognitoRegion: String?
  let cognitoClientID: String?

  init(environment: [String: String] = ProcessInfo.processInfo.environment) {
    mode = Self.resolveMode(from: environment)
    apiBaseURL = URL(string: environment["HA_API_BASE_URL"] ?? "http://127.0.0.1:3000/api")
      ?? URL(string: "http://127.0.0.1:3000/api")!
    serverMode = Self.resolveServerMode(from: environment, apiBaseURL: apiBaseURL)
    authToken = Self.resolveAuthToken(
      from: environment,
      runtimeMode: mode,
      serverMode: serverMode
    )
    cognitoRegion = environment["HA_COGNITO_REGION"]?.trimmedToNil
    cognitoClientID = environment["HA_COGNITO_CLIENT_ID"]?.trimmedToNil
  }

  var usesFixturePreview: Bool {
    mode == .fixturePreview
  }

  var supportsInteractiveEmailAuth: Bool {
    mode == .liveServer && serverMode != .localAutomation && authToken == nil
  }

  private static func resolveMode(from environment: [String: String]) -> AppRuntimeMode {
    if let rawMode = environment["HA_RUNTIME_MODE"]?.lowercased() {
      switch rawMode {
      case "fixture", "fixture_preview", "preview":
        return .fixturePreview
      case "live", "live_server", "server":
        return .liveServer
      default:
        break
      }
    }

    if environment["UITEST_START_SCREEN"] != nil {
      return .fixturePreview
    }

    return .liveServer
  }

  private static func resolveServerMode(
    from environment: [String: String],
    apiBaseURL: URL
  ) -> AppServerMode {
    if let rawMode = environment["HA_SERVER_MODE"]?.lowercased() {
      switch rawMode {
      case "manual_qa", "local_manual_qa", "local-manual-qa", "qa":
        return .localManualQA
      case "automation", "local_automation", "local-automation", "test", "test_core":
        return .localAutomation
      case "prod", "production", "cognito":
        return .production
      default:
        break
      }
    }

    if let host = apiBaseURL.host?.lowercased(),
       host == "127.0.0.1" || host == "localhost" {
      return .localAutomation
    }

    return .production
  }

  private static func resolveAuthToken(
    from environment: [String: String],
    runtimeMode: AppRuntimeMode,
    serverMode: AppServerMode
  ) -> String? {
    guard runtimeMode == .liveServer else {
      return nil
    }

    switch serverMode {
    case .localManualQA:
      return environment["HA_AUTH_TOKEN"]?.trimmedToNil
    case .localAutomation:
      return environment["HA_TEST_AUTH_TOKEN"]?.trimmedToNil
        ?? environment["HA_AUTH_TOKEN"]?.trimmedToNil
    case .production:
      return environment["HA_AUTH_TOKEN"]?.trimmedToNil
    }
  }
}

private extension String {
  var trimmedToNil: String? {
    let trimmed = trimmingCharacters(in: .whitespacesAndNewlines)
    return trimmed.isEmpty ? nil : trimmed
  }
}
