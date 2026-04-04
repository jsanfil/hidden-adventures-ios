import CryptoKit
import Foundation

enum WelcomeIntent: Equatable {
  case onboarding
  case signIn
}

struct AuthTokens: Codable, Sendable {
  let idToken: String
  let accessToken: String?
  let refreshToken: String?
  let expiresAt: Date

  var bearerToken: String {
    idToken
  }

  var isExpired: Bool {
    expiresAt <= Date()
  }

  static func environmentOverride(token: String) -> AuthTokens {
    AuthTokens(
      idToken: token,
      accessToken: nil,
      refreshToken: nil,
      expiresAt: .distantFuture
    )
  }
}

final class AuthStateStore {
  private let lock = NSLock()
  private var tokens: AuthTokens?

  init(initialTokens: AuthTokens? = nil) {
    tokens = initialTokens
  }

  var bearerToken: String? {
    lock.lock()
    defer { lock.unlock() }

    guard let tokens else {
      return nil
    }

    if tokens.isExpired {
      self.tokens = nil
      return nil
    }

    return tokens.bearerToken
  }

  func replace(tokens: AuthTokens?) {
    lock.lock()
    self.tokens = tokens
    lock.unlock()
  }
}

protocol AuthTokenStore {
  func load() -> AuthTokens?
  func save(_ tokens: AuthTokens?)
}

struct UserDefaultsAuthTokenStore: AuthTokenStore {
  private let defaults: UserDefaults
  private let key: String

  init(
    defaults: UserDefaults = .standard,
    key: String = "hidden_adventures.auth_tokens"
  ) {
    self.defaults = defaults
    self.key = key
  }

  func load() -> AuthTokens? {
    guard let data = defaults.data(forKey: key) else {
      return nil
    }

    return try? JSONDecoder().decode(AuthTokens.self, from: data)
  }

  func save(_ tokens: AuthTokens?) {
    if let tokens, let data = try? JSONEncoder().encode(tokens) {
      defaults.set(data, forKey: key)
    } else {
      defaults.removeObject(forKey: key)
    }
  }
}

enum PendingAuthChallengeKind: Equatable, Sendable {
  case signIn
  case signUp
}

struct PendingAuthChallenge: Equatable, Sendable {
  let kind: PendingAuthChallengeKind
  let cognitoUsername: String
  let email: String
  let deliveryDestination: String
  let session: String?
}

enum AuthFlowResult: Sendable {
  case challenge(PendingAuthChallenge)
  case authenticated(AuthTokens)
}

protocol AppAuthService {
  func restoreSession() -> AuthTokens?
  func start(email: String, intent: WelcomeIntent) async throws -> AuthFlowResult
  func resend(challenge: PendingAuthChallenge, intent: WelcomeIntent) async throws -> AuthFlowResult
  func verify(code: String, challenge: PendingAuthChallenge) async throws -> AuthFlowResult
  func logout()
}

struct CognitoConfiguration {
  let region: String
  let clientID: String
}

enum AppAuthError: LocalizedError {
  case missingConfiguration
  case invalidEmail
  case invalidCode
  case challengeExpired
  case unsupportedChallenge(String)
  case service(code: String, message: String)

  var errorDescription: String? {
    switch self {
    case .missingConfiguration:
      return "Email sign-in is not configured for this build. Set HA_COGNITO_REGION and HA_COGNITO_CLIENT_ID."
    case .invalidEmail:
      return "Enter a valid email address to continue."
    case .invalidCode:
      return "Enter the verification code from your email."
    case .challengeExpired:
      return "This sign-in step expired. Start over and request a new code."
    case .unsupportedChallenge(let challengeName):
      return "The auth flow returned an unsupported challenge: \(challengeName)."
    case .service(let code, let message):
      switch code {
      case "UserNotFoundException":
        return "We couldn't find an account for that email."
      case "UsernameExistsException":
        return "That email already has an account. Try signing in instead."
      case "CodeMismatchException":
        return "That code didn't match. Double-check the email and try again."
      case "ExpiredCodeException":
        return "That code expired. Request a new one and try again."
      case "TooManyRequestsException":
        return "Too many auth attempts were made. Please wait a moment and try again."
      default:
        return message
      }
    }
  }
}

final class CognitoAppAuthService: AppAuthService {
  private let configuration: CognitoConfiguration
  private let session: URLSession
  private let tokenStore: AuthTokenStore

  init(
    configuration: CognitoConfiguration,
    session: URLSession = .shared,
    tokenStore: AuthTokenStore = UserDefaultsAuthTokenStore()
  ) {
    self.configuration = configuration
    self.session = session
    self.tokenStore = tokenStore
  }

  func restoreSession() -> AuthTokens? {
    guard let tokens = tokenStore.load() else {
      return nil
    }

    guard tokens.isExpired == false else {
      tokenStore.save(nil)
      return nil
    }

    return tokens
  }

  func start(email: String, intent: WelcomeIntent) async throws -> AuthFlowResult {
    let normalizedEmail = try normalized(email: email)

    switch intent {
    case .signIn:
      return try await initiateSignIn(email: normalizedEmail)

    case .onboarding:
      do {
        let cognitoUsername = signUpUsername(for: normalizedEmail)
        let response = try await signUp(email: normalizedEmail, username: cognitoUsername)
        return .challenge(
          PendingAuthChallenge(
            kind: .signUp,
            cognitoUsername: cognitoUsername,
            email: normalizedEmail,
            deliveryDestination: response.codeDeliveryDetails?.destination ?? normalizedEmail,
            session: nil
          )
        )
      } catch let error as AppAuthError {
        guard case .service(let code, _) = error, code == "UsernameExistsException" else {
          throw error
        }
        return try await initiateSignIn(email: normalizedEmail)
      }
    }
  }

  func verify(code: String, challenge: PendingAuthChallenge) async throws -> AuthFlowResult {
    let trimmedCode = code.trimmingCharacters(in: .whitespacesAndNewlines)
    guard trimmedCode.isEmpty == false else {
      throw AppAuthError.invalidCode
    }

    switch challenge.kind {
    case .signIn:
      return try await respondToEmailOTP(
        email: challenge.email,
        code: trimmedCode,
        session: challenge.session
      )

    case .signUp:
      let response: ConfirmSignUpResponse
      do {
        response = try await confirmSignUp(username: challenge.cognitoUsername, code: trimmedCode)
      } catch let error as AppAuthError {
        guard case .service(let code, _) = error, code == "AliasExistsException" else {
          throw error
        }
        return try await initiateSignIn(email: challenge.email)
      }
      if let session = response.session {
        return try await continueAfterConfirmSignUp(email: challenge.email, session: session)
      }

      return try await initiateSignIn(email: challenge.email)
    }
  }

  func resend(challenge: PendingAuthChallenge, intent: WelcomeIntent) async throws -> AuthFlowResult {
    switch challenge.kind {
    case .signIn:
      return try await start(email: challenge.email, intent: intent)

    case .signUp:
      let response = try await resendConfirmationCode(username: challenge.cognitoUsername)
      return .challenge(
        PendingAuthChallenge(
          kind: .signUp,
          cognitoUsername: challenge.cognitoUsername,
          email: challenge.email,
          deliveryDestination: response.codeDeliveryDetails?.destination ?? challenge.email,
          session: nil
        )
      )
    }
  }

  func logout() {
    tokenStore.save(nil)
  }

  private func initiateSignIn(email: String) async throws -> AuthFlowResult {
    let response: CognitoAuthResponse = try await send(
      target: "InitiateAuth",
      body: InitiateAuthRequest(
        authFlow: "USER_AUTH",
        clientId: configuration.clientID,
        authParameters: [
          "USERNAME": email,
          "PREFERRED_CHALLENGE": "EMAIL_OTP"
        ],
        session: nil
      )
    )

    return try await authFlowResult(from: response, email: email)
  }

  private func continueAfterConfirmSignUp(email: String, session: String) async throws -> AuthFlowResult {
    let response: CognitoAuthResponse = try await send(
      target: "InitiateAuth",
      body: InitiateAuthRequest(
        authFlow: "USER_AUTH",
        clientId: configuration.clientID,
        authParameters: [
          "USERNAME": email
        ],
        session: session
      )
    )

    return try await authFlowResult(from: response, email: email)
  }

  private func respondToEmailOTP(
    email: String,
    code: String,
    session: String?
  ) async throws -> AuthFlowResult {
    guard let session else {
      throw AppAuthError.challengeExpired
    }

    let response: CognitoAuthResponse = try await send(
      target: "RespondToAuthChallenge",
      body: RespondToAuthChallengeRequest(
        challengeName: "EMAIL_OTP",
        clientId: configuration.clientID,
        session: session,
        challengeResponses: [
          "USERNAME": email,
          "EMAIL_OTP_CODE": code
        ]
      )
    )

    return try await authFlowResult(from: response, email: email)
  }

  private func signUp(email: String, username: String) async throws -> SignUpResponse {
    try await send(
      target: "SignUp",
      body: SignUpRequest(
        clientId: configuration.clientID,
        username: username,
        userAttributes: [
          CognitoAttribute(name: "email", value: email)
        ]
      )
    )
  }

  private func confirmSignUp(username: String, code: String) async throws -> ConfirmSignUpResponse {
    try await send(
      target: "ConfirmSignUp",
      body: ConfirmSignUpRequest(
        clientId: configuration.clientID,
        username: username,
        confirmationCode: code
      )
    )
  }

  private func resendConfirmationCode(username: String) async throws -> ResendConfirmationCodeResponse {
    try await send(
      target: "ResendConfirmationCode",
      body: ResendConfirmationCodeRequest(
        clientId: configuration.clientID,
        username: username
      )
    )
  }

  private func authFlowResult(from response: CognitoAuthResponse, email: String) async throws -> AuthFlowResult {
    if let authenticationResult = response.authenticationResult {
      let tokens = AuthTokens(
        idToken: authenticationResult.idToken,
        accessToken: authenticationResult.accessToken,
        refreshToken: authenticationResult.refreshToken,
        expiresAt: Date().addingTimeInterval(TimeInterval(authenticationResult.expiresIn))
      )
      tokenStore.save(tokens)
      return .authenticated(tokens)
    }

    if response.challengeName == "SELECT_CHALLENGE" {
      return try await respondToSelectChallenge(email: email, response: response)
    }

    guard response.challengeName == "EMAIL_OTP" else {
      throw AppAuthError.unsupportedChallenge(response.challengeName ?? "none")
    }

    return .challenge(
      PendingAuthChallenge(
        kind: .signIn,
        cognitoUsername: email,
        email: email,
        deliveryDestination: response.challengeParameters?["CODE_DELIVERY_DESTINATION"] ?? email,
        session: response.session
      )
    )
  }

  private func respondToSelectChallenge(
    email: String,
    response: CognitoAuthResponse
  ) async throws -> AuthFlowResult {
    guard let session = response.session else {
      throw AppAuthError.challengeExpired
    }

    let availableChallenges = parseAvailableChallenges(from: response.challengeParameters)
    guard availableChallenges.isEmpty || availableChallenges.contains("EMAIL_OTP") else {
      let options = availableChallenges.joined(separator: ", ")
      throw AppAuthError.unsupportedChallenge("SELECT_CHALLENGE (\(options))")
    }

    let followUp: CognitoAuthResponse = try await send(
      target: "RespondToAuthChallenge",
      body: RespondToAuthChallengeRequest(
        challengeName: "SELECT_CHALLENGE",
        clientId: configuration.clientID,
        session: session,
        challengeResponses: [
          "USERNAME": email,
          "ANSWER": "EMAIL_OTP"
        ]
      )
    )

    return try await authFlowResult(from: followUp, email: email)
  }

  private func parseAvailableChallenges(from parameters: [String: String]?) -> [String] {
    guard let raw = parameters?["AVAILABLE_CHALLENGES"]?.trimmingCharacters(in: .whitespacesAndNewlines),
          raw.isEmpty == false else {
      return []
    }

    if raw.first == "[" {
      if let data = raw.data(using: .utf8),
         let decoded = try? JSONDecoder().decode([String].self, from: data) {
        return decoded
      }
    }

    return raw
      .split(separator: ",")
      .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
      .filter { $0.isEmpty == false }
  }

  private func normalized(email: String) throws -> String {
    let normalizedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    guard normalizedEmail.contains("@"), normalizedEmail.contains(".") else {
      throw AppAuthError.invalidEmail
    }
    return normalizedEmail
  }

  private func signUpUsername(for email: String) -> String {
    let digest = SHA256.hash(data: Data(email.utf8))
    let hex = digest.map { String(format: "%02x", $0) }.joined()
    let localPart = email.split(separator: "@").first.map(String.init) ?? "user"
    let readablePrefix = sanitizedUsernamePrefix(from: localPart)
    return "\(readablePrefix)_\(hex.prefix(24))"
  }

  private func sanitizedUsernamePrefix(from localPart: String) -> String {
    let allowed = localPart.lowercased().map { character -> Character in
      switch character {
      case "a"..."z", "0"..."9":
        return character
      default:
        return "_"
      }
    }

    let collapsed = String(allowed)
      .replacingOccurrences(of: "_+", with: "_", options: .regularExpression)
      .trimmingCharacters(in: CharacterSet(charactersIn: "_"))

    if collapsed.isEmpty {
      return "user"
    }

    return String(collapsed.prefix(24))
  }

  private func send<Request: Encodable, Response: Decodable>(
    target: String,
    body: Request
  ) async throws -> Response {
    let url = URL(string: "https://cognito-idp.\(configuration.region).amazonaws.com/")!
    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.setValue("application/x-amz-json-1.1", forHTTPHeaderField: "Content-Type")
    request.setValue("AWSCognitoIdentityProviderService.\(target)", forHTTPHeaderField: "X-Amz-Target")
    request.httpBody = try JSONEncoder().encode(body)

    let data: Data
    let response: URLResponse

    do {
      (data, response) = try await session.data(for: request)
    } catch {
      throw AppAuthError.service(code: "TransportError", message: error.localizedDescription)
    }

    guard let httpResponse = response as? HTTPURLResponse else {
      throw AppAuthError.service(code: "InvalidResponse", message: "The auth service returned an invalid response.")
    }

    guard (200..<300).contains(httpResponse.statusCode) else {
      let payload = (try? JSONDecoder().decode(CognitoErrorResponse.self, from: data))
      throw AppAuthError.service(
        code: payload?.normalizedCode ?? "HTTP\(httpResponse.statusCode)",
        message: payload?.message ?? HTTPURLResponse.localizedString(forStatusCode: httpResponse.statusCode)
      )
    }

    return try JSONDecoder().decode(Response.self, from: data)
  }
}

private struct CognitoAttribute: Encodable {
  let name: String
  let value: String

  enum CodingKeys: String, CodingKey {
    case name = "Name"
    case value = "Value"
  }
}

private struct SignUpRequest: Encodable {
  let clientId: String
  let username: String
  let userAttributes: [CognitoAttribute]

  enum CodingKeys: String, CodingKey {
    case clientId = "ClientId"
    case username = "Username"
    case userAttributes = "UserAttributes"
  }
}

private struct ConfirmSignUpRequest: Encodable {
  let clientId: String
  let username: String
  let confirmationCode: String

  enum CodingKeys: String, CodingKey {
    case clientId = "ClientId"
    case username = "Username"
    case confirmationCode = "ConfirmationCode"
  }
}

private struct ResendConfirmationCodeRequest: Encodable {
  let clientId: String
  let username: String

  enum CodingKeys: String, CodingKey {
    case clientId = "ClientId"
    case username = "Username"
  }
}

private struct InitiateAuthRequest: Encodable {
  let authFlow: String
  let clientId: String
  let authParameters: [String: String]?
  let session: String?

  enum CodingKeys: String, CodingKey {
    case authFlow = "AuthFlow"
    case clientId = "ClientId"
    case authParameters = "AuthParameters"
    case session = "Session"
  }
}

private struct RespondToAuthChallengeRequest: Encodable {
  let challengeName: String
  let clientId: String
  let session: String
  let challengeResponses: [String: String]

  enum CodingKeys: String, CodingKey {
    case challengeName = "ChallengeName"
    case clientId = "ClientId"
    case session = "Session"
    case challengeResponses = "ChallengeResponses"
  }
}

private struct CodeDeliveryDetails: Decodable {
  let destination: String?

  enum CodingKeys: String, CodingKey {
    case destination = "Destination"
  }
}

private struct SignUpResponse: Decodable {
  let codeDeliveryDetails: CodeDeliveryDetails?

  enum CodingKeys: String, CodingKey {
    case codeDeliveryDetails = "CodeDeliveryDetails"
  }
}

private struct ConfirmSignUpResponse: Decodable {
  let session: String?

  enum CodingKeys: String, CodingKey {
    case session = "Session"
  }
}

private struct ResendConfirmationCodeResponse: Decodable {
  let codeDeliveryDetails: CodeDeliveryDetails?

  enum CodingKeys: String, CodingKey {
    case codeDeliveryDetails = "CodeDeliveryDetails"
  }
}

private struct CognitoAuthenticationResult: Decodable {
  let accessToken: String?
  let expiresIn: Int
  let idToken: String
  let refreshToken: String?

  enum CodingKeys: String, CodingKey {
    case accessToken = "AccessToken"
    case expiresIn = "ExpiresIn"
    case idToken = "IdToken"
    case refreshToken = "RefreshToken"
  }
}

private struct CognitoAuthResponse: Decodable {
  let authenticationResult: CognitoAuthenticationResult?
  let challengeName: String?
  let challengeParameters: [String: String]?
  let session: String?

  enum CodingKeys: String, CodingKey {
    case authenticationResult = "AuthenticationResult"
    case challengeName = "ChallengeName"
    case challengeParameters = "ChallengeParameters"
    case session = "Session"
  }
}

private struct CognitoErrorResponse: Decodable {
  let type: String?
  let message: String?

  enum CodingKeys: String, CodingKey {
    case type = "__type"
    case message
  }

  var normalizedCode: String {
    guard let type else {
      return "UnknownError"
    }

    if let hashIndex = type.lastIndex(of: "#") {
      return String(type[type.index(after: hashIndex)...])
    }

    return type
  }
}
