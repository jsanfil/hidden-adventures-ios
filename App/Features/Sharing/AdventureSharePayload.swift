import Foundation

struct AdventureSharePayload: Equatable {
  let url: URL
  let message: String

  static func make(detail: AdventureDetail, baseURL: URL) -> Self? {
    guard detail.visibility == .public else {
      return nil
    }

    let url = baseURL.appending(path: "adventures").appending(path: detail.id)
    let place = detail.placeLabel ?? "Hidden Adventures"

    return Self(
      url: url,
      message: "Check out \(detail.title) on Hidden Adventures\n\(place)\n\(url.absoluteString)"
    )
  }

  static func unavailableMessage(for visibility: Visibility) -> String {
    switch visibility {
    case .public:
      return ""
    case .sidekicks, .private:
      return "Only public adventures can be shared outside Hidden Adventures."
    }
  }
}
