import Foundation
import XCTest
@testable import HiddenAdventures

final class AppAuthServiceTests: XCTestCase {
  override func tearDown() {
    CognitoMockURLProtocol.requestHandler = nil
    CognitoMockURLProtocol.requestQueue = []
    CognitoMockURLProtocol.requestError = nil
    super.tearDown()
  }

  func testGetStartedUsesSignUpWithDerivedUsername() async throws {
    let expectedUsername = "new_1853b7412ac94d75cb23e033"

    CognitoMockURLProtocol.requestHandler = { request in
      XCTAssertEqual(request.value(forHTTPHeaderField: "X-Amz-Target"), "AWSCognitoIdentityProviderService.SignUp")

      let payload = try XCTUnwrap(Self.jsonPayload(from: request))
      XCTAssertEqual(payload["ClientId"] as? String, "client-id")
      XCTAssertEqual(payload["Username"] as? String, expectedUsername)

      let attributes = payload["UserAttributes"] as? [[String: Any]]
      XCTAssertEqual(attributes?.count, 1)
      XCTAssertEqual(attributes?.first?["Name"] as? String, "email")
      XCTAssertEqual(attributes?.first?["Value"] as? String, "new@example.com")

      return Self.successResponse(
        request: request,
        body: #"{"CodeDeliveryDetails":{"Destination":"n•••@example.com"}}"#
      )
    }

    let service = makeService()

    let result = try await service.start(email: "new@example.com", intent: .onboarding)

    guard case .challenge(let challenge) = result else {
      return XCTFail("Expected signup challenge")
    }

    XCTAssertEqual(challenge.kind, .signUp)
    XCTAssertEqual(challenge.cognitoUsername, expectedUsername)
    XCTAssertEqual(challenge.email, "new@example.com")
    XCTAssertEqual(challenge.deliveryDestination, "n•••@example.com")
    XCTAssertNil(challenge.session)
  }

  func testSignupResendUsesResendConfirmationCode() async throws {
    CognitoMockURLProtocol.requestHandler = { request in
      XCTAssertEqual(request.value(forHTTPHeaderField: "X-Amz-Target"), "AWSCognitoIdentityProviderService.ResendConfirmationCode")

      let payload = try XCTUnwrap(Self.jsonPayload(from: request))
      XCTAssertEqual(payload["ClientId"] as? String, "client-id")
      XCTAssertEqual(payload["Username"] as? String, "signup_username")

      return Self.successResponse(
        request: request,
        body: #"{"CodeDeliveryDetails":{"Destination":"ne•••@example.com"}}"#
      )
    }

    let service = makeService()

    let result = try await service.resend(
      challenge: PendingAuthChallenge(
        kind: .signUp,
        cognitoUsername: "signup_username",
        email: "new@example.com",
        deliveryDestination: "n•••@example.com",
        session: nil
      ),
      intent: .onboarding
    )

    guard case .challenge(let challenge) = result else {
      return XCTFail("Expected signup resend challenge")
    }

    XCTAssertEqual(challenge.kind, .signUp)
    XCTAssertEqual(challenge.cognitoUsername, "signup_username")
    XCTAssertEqual(challenge.deliveryDestination, "ne•••@example.com")
  }

  func testSignupConfirmationWithSessionAuthenticatesWithoutSecondChallenge() async throws {
    CognitoMockURLProtocol.requestQueue = [
      { request in
        XCTAssertEqual(request.value(forHTTPHeaderField: "X-Amz-Target"), "AWSCognitoIdentityProviderService.ConfirmSignUp")

        let payload = try XCTUnwrap(Self.jsonPayload(from: request))
        XCTAssertEqual(payload["Username"] as? String, "signup_username")
        XCTAssertEqual(payload["ConfirmationCode"] as? String, "123456")

        return Self.successResponse(
          request: request,
          body: #"{"Session":"signup-session"}"#
        )
      },
      { request in
        XCTAssertEqual(request.value(forHTTPHeaderField: "X-Amz-Target"), "AWSCognitoIdentityProviderService.InitiateAuth")

        let payload = try XCTUnwrap(Self.jsonPayload(from: request))
        XCTAssertEqual(payload["AuthFlow"] as? String, "USER_AUTH")
        XCTAssertEqual(payload["Session"] as? String, "signup-session")

        let parameters = payload["AuthParameters"] as? [String: String]
        XCTAssertEqual(parameters?["USERNAME"], "new@example.com")

        return Self.successResponse(
          request: request,
          body: #"{"AuthenticationResult":{"IdToken":"id-token","AccessToken":"access-token","RefreshToken":"refresh-token","ExpiresIn":3600}}"#
        )
      }
    ]

    let service = makeService()

    let result = try await service.verify(
      code: "123456",
      challenge: PendingAuthChallenge(
        kind: .signUp,
        cognitoUsername: "signup_username",
        email: "new@example.com",
        deliveryDestination: "n•••@example.com",
        session: nil
      )
    )

    guard case .authenticated(let tokens) = result else {
      return XCTFail("Expected authenticated result")
    }

    XCTAssertEqual(tokens.idToken, "id-token")
    XCTAssertEqual(tokens.accessToken, "access-token")
    XCTAssertEqual(tokens.refreshToken, "refresh-token")
  }

  func testSignupConfirmationWithoutSessionThrowsExplicitError() async {
    CognitoMockURLProtocol.requestHandler = { request in
      XCTAssertEqual(request.value(forHTTPHeaderField: "X-Amz-Target"), "AWSCognitoIdentityProviderService.ConfirmSignUp")
      return Self.successResponse(request: request, body: #"{}"#)
    }

    let service = makeService()

    do {
      _ = try await service.verify(
        code: "123456",
        challenge: PendingAuthChallenge(
          kind: .signUp,
          cognitoUsername: "signup_username",
          email: "new@example.com",
          deliveryDestination: "n•••@example.com",
          session: nil
        )
      )
      XCTFail("Expected verify to fail")
    } catch let error as AppAuthError {
      guard case .service(let code, _) = error else {
        return XCTFail("Expected service error")
      }

      XCTAssertEqual(code, "MissingSessionAfterConfirmSignUp")
      XCTAssertEqual(
        error.errorDescription,
        "Your email was confirmed, but Hidden Adventures couldn't finish account setup automatically. Please try again."
      )
    } catch {
      XCTFail("Unexpected error: \(error)")
    }
  }

  func testSignupConfirmationAliasExistsShowsExplicitAccountExistsError() async {
    CognitoMockURLProtocol.requestHandler = { request in
      XCTAssertEqual(request.value(forHTTPHeaderField: "X-Amz-Target"), "AWSCognitoIdentityProviderService.ConfirmSignUp")
      return Self.errorResponse(
        request: request,
        code: 400,
        body: #"{"__type":"AliasExistsException","message":"Alias already exists"}"#
      )
    }

    let service = makeService()

    do {
      _ = try await service.verify(
        code: "123456",
        challenge: PendingAuthChallenge(
          kind: .signUp,
          cognitoUsername: "signup_username",
          email: "linked@example.com",
          deliveryDestination: "l•••@example.com",
          session: nil
        )
      )
      XCTFail("Expected verify to fail")
    } catch let error as AppAuthError {
      guard case .service(let code, _) = error else {
        return XCTFail("Expected service error")
      }

      XCTAssertEqual(code, "AliasExistsException")
      XCTAssertEqual(error.errorDescription, "That email already has an account. Use Sign In.")
    } catch {
      XCTFail("Unexpected error: \(error)")
    }
  }

  func testSignInReturnsEmailOtpChallengeForExistingAccount() async throws {
    CognitoMockURLProtocol.requestHandler = { request in
      XCTAssertEqual(request.value(forHTTPHeaderField: "X-Amz-Target"), "AWSCognitoIdentityProviderService.InitiateAuth")

      let payload = try XCTUnwrap(Self.jsonPayload(from: request))
      let parameters = payload["AuthParameters"] as? [String: String]
      XCTAssertEqual(parameters?["USERNAME"], "linked@example.com")
      XCTAssertEqual(parameters?["PREFERRED_CHALLENGE"], "EMAIL_OTP")

      return Self.successResponse(
        request: request,
        body: #"{"ChallengeName":"EMAIL_OTP","ChallengeParameters":{"CODE_DELIVERY_DESTINATION":"l•••@example.com"},"Session":"session-1"}"#
      )
    }

    let service = makeService()

    let result = try await service.start(email: "linked@example.com", intent: .signIn)

    guard case .challenge(let challenge) = result else {
      return XCTFail("Expected sign-in challenge")
    }

    XCTAssertEqual(challenge.kind, .signIn)
    XCTAssertEqual(challenge.cognitoUsername, "linked@example.com")
    XCTAssertEqual(challenge.deliveryDestination, "l•••@example.com")
    XCTAssertEqual(challenge.session, "session-1")
  }

  func testRefreshUsesRefreshTokenGrantAndPersistsNewTokens() async throws {
    CognitoMockURLProtocol.requestHandler = { request in
      XCTAssertEqual(request.value(forHTTPHeaderField: "X-Amz-Target"), "AWSCognitoIdentityProviderService.InitiateAuth")

      let payload = try XCTUnwrap(Self.jsonPayload(from: request))
      XCTAssertEqual(payload["AuthFlow"] as? String, "REFRESH_TOKEN_AUTH")

      let parameters = payload["AuthParameters"] as? [String: String]
      XCTAssertEqual(parameters?["REFRESH_TOKEN"], "refresh-token")

      return Self.successResponse(
        request: request,
        body: #"{"AuthenticationResult":{"IdToken":"new-id-token","AccessToken":"new-access-token","ExpiresIn":3600}}"#
      )
    }

    let service = makeService()
    let refreshedTokens = try await service.refresh(
      tokens: AuthTokens(
        idToken: "old-id-token",
        accessToken: "old-access-token",
        refreshToken: "refresh-token",
        expiresAt: Date(timeIntervalSince1970: 1)
      )
    )

    XCTAssertEqual(refreshedTokens?.idToken, "new-id-token")
    XCTAssertEqual(refreshedTokens?.accessToken, "new-access-token")
    XCTAssertEqual(refreshedTokens?.refreshToken, "refresh-token")
  }

  func testSignInMissingAccountShowsNoAccountError() async {
    CognitoMockURLProtocol.requestHandler = { request in
      XCTAssertEqual(request.value(forHTTPHeaderField: "X-Amz-Target"), "AWSCognitoIdentityProviderService.InitiateAuth")
      return Self.errorResponse(
        request: request,
        code: 400,
        body: #"{"__type":"UserNotFoundException","message":"User does not exist"}"#
      )
    }

    let service = makeService()

    do {
      _ = try await service.start(email: "missing@example.com", intent: .signIn)
      XCTFail("Expected sign-in to fail")
    } catch let error as AppAuthError {
      guard case .service(let code, _) = error else {
        return XCTFail("Expected service error")
      }

      XCTAssertEqual(code, "UserNotFoundException")
      XCTAssertEqual(error.errorDescription, "We couldn't find an account for that email.")
    } catch {
      XCTFail("Unexpected error: \(error)")
    }
  }

  private func makeService() -> CognitoAppAuthService {
    let configuration = URLSessionConfiguration.ephemeral
    configuration.protocolClasses = [CognitoMockURLProtocol.self]

    return CognitoAppAuthService(
      configuration: CognitoConfiguration(region: "us-west-2", clientID: "client-id"),
      session: URLSession(configuration: configuration),
      tokenStore: InMemoryAuthTokenStore()
    )
  }

  private static func jsonPayload(from request: URLRequest) -> [String: Any]? {
    guard let data = request.httpBody else {
      return nil
    }

    return (try? JSONSerialization.jsonObject(with: data)) as? [String: Any]
  }

  private static func successResponse(
    request: URLRequest,
    body: String
  ) -> (HTTPURLResponse, Data) {
    let response = HTTPURLResponse(
      url: request.url!,
      statusCode: 200,
      httpVersion: nil,
      headerFields: ["Content-Type": "application/x-amz-json-1.1"]
    )!

    return (response, Data(body.utf8))
  }

  private static func errorResponse(
    request: URLRequest,
    code: Int,
    body: String
  ) -> (HTTPURLResponse, Data) {
    let response = HTTPURLResponse(
      url: request.url!,
      statusCode: code,
      httpVersion: nil,
      headerFields: ["Content-Type": "application/x-amz-json-1.1"]
    )!

    return (response, Data(body.utf8))
  }
}

private final class InMemoryAuthTokenStore: AuthTokenStore {
  private var tokens: AuthTokens?

  func load() -> AuthTokens? {
    tokens
  }

  func save(_ tokens: AuthTokens?) {
    self.tokens = tokens
  }
}

private final class CognitoMockURLProtocol: URLProtocol {
  static var requestHandler: ((URLRequest) throws -> (HTTPURLResponse, Data))?
  static var requestQueue: [((URLRequest) throws -> (HTTPURLResponse, Data))] = []
  static var requestError: Error?

  override class func canInit(with request: URLRequest) -> Bool {
    true
  }

  override class func canonicalRequest(for request: URLRequest) -> URLRequest {
    request
  }

  override func startLoading() {
    if let requestError = Self.requestError {
      client?.urlProtocol(self, didFailWithError: requestError)
      return
    }

    let handler = Self.requestQueue.isEmpty == false ? Self.requestQueue.removeFirst() : Self.requestHandler

    guard let handler else {
      client?.urlProtocol(self, didFailWithError: URLError(.badServerResponse))
      return
    }

    do {
      let (response, data) = try handler(request)
      client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
      client?.urlProtocol(self, didLoad: data)
      client?.urlProtocolDidFinishLoading(self)
    } catch {
      client?.urlProtocol(self, didFailWithError: error)
    }
  }

  override func stopLoading() {}
}
