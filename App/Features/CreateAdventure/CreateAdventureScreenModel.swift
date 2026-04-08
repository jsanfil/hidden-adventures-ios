import Foundation

enum CreateAdventureStep: String, Equatable, Sendable {
  case photos
  case details
}

enum CreateAdventureLocationPickerMode: String, Equatable, Sendable {
  case options
  case search
  case pin
}

enum CreateAdventureCurrentLocationState: Equatable, Sendable {
  case idle
  case loading
  case resolved(CreateAdventureResolvedLocation)
}

struct CreateAdventureResolvedLocation: Equatable, Sendable {
  let name: String
  let latitude: Double
  let longitude: Double
}

struct CreateAdventureSearchResult: Identifiable, Equatable, Sendable {
  let id: String
  let name: String
  let subtitle: String
  let latitude: Double
  let longitude: Double
}

struct CreateAdventureScreenModel: Equatable, Sendable {
  let step: CreateAdventureStep
  let selectedPhotoNames: [String]
  let activePhotoIndex: Int
  let title: String
  let description: String
  let resolvedLocation: CreateAdventureResolvedLocation?
  let locationLabel: String
  let selectedCategory: Category?
  let visibility: Visibility
  let isLocationPickerPresented: Bool
  let locationPickerMode: CreateAdventureLocationPickerMode
  let locationSearchQuery: String
  let currentLocationState: CreateAdventureCurrentLocationState
  let locationSearchResults: [CreateAdventureSearchResult]
  let pinLocation: CreateAdventureResolvedLocation
}

enum CreateAdventureFixtureVariant: String, CaseIterable, Equatable, Sendable {
  case photos
  case detailsEmpty
  case detailsLocation
  case locationOptions
  case locationSearchEmpty
  case locationSearchResults
  case locationPin
}
