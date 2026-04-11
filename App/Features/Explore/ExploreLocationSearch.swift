import CoreLocation
import MapKit
import SwiftUI

@MainActor
final class ExploreLocationSearchController: NSObject, ObservableObject {
  @Published private(set) var completions: [ExploreLocationSearchSuggestion] = []

  private let runtimeMode: AppRuntimeMode
  private let completer: MKLocalSearchCompleter?

  init(runtimeMode: AppRuntimeMode) {
    self.runtimeMode = runtimeMode

    if runtimeMode == .fixturePreview {
      completer = nil
      super.init()
      return
    }

    let completer = MKLocalSearchCompleter()
    self.completer = completer
    super.init()
    completer.delegate = self
    completer.resultTypes = [.address, .pointOfInterest]
  }

  func updateQuery(_ query: String) {
    let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)

    guard trimmed.isEmpty == false else {
      completions = []
      completer?.queryFragment = ""
      return
    }

    if runtimeMode == .fixturePreview {
      let normalized = trimmed.localizedLowercase
      completions = ExploreLocationSearchSuggestion.fixtureSuggestions.filter { suggestion in
        suggestion.title.localizedLowercase.contains(normalized)
          || suggestion.subtitle.localizedLowercase.contains(normalized)
      }
      return
    }

    completer?.queryFragment = trimmed
  }

  func clearSuggestions() {
    completions = []
  }

  func resolveSuggestion(_ suggestion: ExploreLocationSearchSuggestion) async -> ExploreLocationResolvedPlace? {
    if let coordinate = suggestion.fixtureCoordinate {
      return ExploreLocationResolvedPlace(
        title: suggestion.displayLabel,
        location: AdventureLocation(latitude: coordinate.latitude, longitude: coordinate.longitude),
        region: MapExploreRegionHelper.region(center: coordinate)
      )
    }

    guard let completion = suggestion.completion else {
      return nil
    }

    let request = MKLocalSearch.Request(completion: completion)

    do {
      let response = try await MKLocalSearch(request: request).start()
      if let coordinate = response.mapItems.first?.placemark.coordinate {
        return ExploreLocationResolvedPlace(
          title: suggestion.displayLabel,
          location: AdventureLocation(latitude: coordinate.latitude, longitude: coordinate.longitude),
          region: MapExploreRegionHelper.region(center: coordinate)
        )
      }
    } catch {
      return nil
    }

    return nil
  }
}

extension ExploreLocationSearchController: @preconcurrency MKLocalSearchCompleterDelegate {
  func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
    completions = completer.results.map(ExploreLocationSearchSuggestion.init(completion:))
  }

  func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: Error) {
    completions = []
  }
}

struct ExploreLocationSearchSuggestion: Identifiable {
  let id: String
  let title: String
  let subtitle: String
  fileprivate let completion: MKLocalSearchCompletion?
  fileprivate let fixtureCoordinate: CLLocationCoordinate2D?

  init(title: String, subtitle: String, fixtureCoordinate: CLLocationCoordinate2D) {
    self.id = "\(title)|\(subtitle)"
    self.title = title
    self.subtitle = subtitle
    self.completion = nil
    self.fixtureCoordinate = fixtureCoordinate
  }

  init(completion: MKLocalSearchCompletion) {
    self.id = "\(completion.title)|\(completion.subtitle)"
    self.title = completion.title
    self.subtitle = completion.subtitle
    self.completion = completion
    self.fixtureCoordinate = nil
  }

  var displayLabel: String {
    subtitle.isEmpty ? title : "\(title), \(subtitle)"
  }

  var accessibilityIdentifier: String {
    displayLabel
      .lowercased()
      .replacingOccurrences(of: "[^a-z0-9]+", with: "-", options: .regularExpression)
      .trimmingCharacters(in: CharacterSet(charactersIn: "-"))
  }

  static let fixtureSuggestions: [ExploreLocationSearchSuggestion] = [
    ExploreLocationSearchSuggestion(
      title: "Portland",
      subtitle: "Oregon",
      fixtureCoordinate: CLLocationCoordinate2D(latitude: 45.5152, longitude: -122.6784)
    ),
    ExploreLocationSearchSuggestion(
      title: "Mount Hood",
      subtitle: "Oregon",
      fixtureCoordinate: CLLocationCoordinate2D(latitude: 45.3735, longitude: -121.6959)
    ),
    ExploreLocationSearchSuggestion(
      title: "Columbia River Gorge",
      subtitle: "Oregon",
      fixtureCoordinate: CLLocationCoordinate2D(latitude: 45.6698, longitude: -121.8842)
    )
  ]
}

struct ExploreLocationResolvedPlace {
  let title: String
  let location: AdventureLocation
  let region: MKCoordinateRegion
}

struct ExploreLocationSuggestionsPopover: View {
  let suggestions: [ExploreLocationSearchSuggestion]
  let suggestionsAccessibilityID: String
  let suggestionAccessibilityPrefix: String
  let onSelect: (ExploreLocationSearchSuggestion) -> Void

  var body: some View {
    VStack(alignment: .leading, spacing: 0) {
      ForEach(suggestions) { suggestion in
        Button {
          onSelect(suggestion)
        } label: {
          VStack(alignment: .leading, spacing: 4) {
            Text(suggestion.title)
              .font(.system(size: 15, weight: .semibold))
              .foregroundStyle(HATheme.Colors.foreground)
              .frame(maxWidth: .infinity, alignment: .leading)

            if suggestion.subtitle.isEmpty == false {
              Text(suggestion.subtitle)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(HATheme.Colors.mutedForeground)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
          }
          .padding(.horizontal, 16)
          .padding(.vertical, 12)
          .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("\(suggestionAccessibilityPrefix).\(suggestion.accessibilityIdentifier)")

        if suggestion.id != suggestions.last?.id {
          Divider()
            .padding(.leading, 16)
        }
      }
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .background(.white)
    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    .shadow(color: HATheme.Colors.shadow.opacity(1.3), radius: 22, x: 0, y: 10)
    .accessibilityElement(children: .contain)
    .accessibilityIdentifier(suggestionsAccessibilityID)
  }
}
