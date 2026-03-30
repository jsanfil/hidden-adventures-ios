import Foundation

protocol AuthService {
  func bootstrap() async throws -> AuthBootstrapResponse
  func completeHandleSelection(handle: String) async throws -> AuthBootstrapResponse
}

struct RemoteAuthService: AuthService {
  let client: APIClient

  func bootstrap() async throws -> AuthBootstrapResponse {
    try await client.get(
      pathComponents: ["auth", "bootstrap"],
      requiresAuth: true
    )
  }

  func completeHandleSelection(handle: String) async throws -> AuthBootstrapResponse {
    try await client.post(
      pathComponents: ["auth", "handle"],
      body: HandleSelectionRequest(handle: handle),
      requiresAuth: true
    )
  }
}

private struct HandleSelectionRequest: Encodable {
  let handle: String
}
