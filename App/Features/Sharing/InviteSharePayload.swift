import Foundation

struct InviteSharePayload: Equatable {
  let url: URL
  let message: String

  var items: [Any] {
    [message, url]
  }

  static func make(appURL: URL = URL(string: "https://hiddenadventures.app/invite")!) -> Self {
    Self(
      url: appURL,
      message: "Join me on Hidden Adventures to swap hidden gems and weekend plans.\n\(appURL.absoluteString)"
    )
  }
}
