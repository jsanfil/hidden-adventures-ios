import CoreLocation
import SwiftUI

struct ExploreShellView: View {
  let adventureService: AdventureService
  let profileService: ProfileService
  let runtimeMode: AppRuntimeMode
  let viewerHandle: String?
  let viewerDisplayName: String?
  @Binding var mode: ExploreMode
  @Binding var createAdventureVariant: CreateAdventureFixtureVariant?
  let onViewerProfileLoaded: (ProfileDetail) -> Void
  let onOpenDetail: (String) -> Void
  let onLogout: () -> Void

  @StateObject private var locationController = ExploreDiscoveryLocationController()

  @State private var feedResponse: FeedResponse?
  @State private var visibilityFilter: VisibilityFilter = .all
  @State private var activeCategory: Category?
  @State private var discoveryScopeState: ExploreDiscoveryScopeState?
  @State private var isLoading = true
  @State private var errorMessage: String?
  @State private var hasStartedLocationUpdates = false

  private let defaultFeedLimit = 20
  private let defaultRadiusMiles = MapExploreRegionHelper.defaultRadiusMiles
  private let fallbackDiscoveryLocation = AdventureLocation(latitude: 37.3349, longitude: -122.0090)

  private var feedItems: [AdventureCard] {
    feedResponse?.items ?? []
  }

  var filteredItems: [AdventureCard] {
    feedItems.filter { item in
      let visibilityMatches = visibilityFilter.matches(item.visibility)
      let categoryMatches = activeCategory == nil || item.categorySlug == activeCategory
      return visibilityMatches && categoryMatches
    }
  }

  private var fallbackScope: FeedScope {
    FeedScope(center: fallbackDiscoveryLocation, radiusMiles: defaultRadiusMiles)
  }

  private var effectiveDiscoveryScope: FeedScope {
    if let searchedScope = discoveryScopeState?.scope,
      discoveryScopeState?.source == .searchedPlace
    {
      return searchedScope
    }

    if let currentLocation {
      return FeedScope(center: currentLocation, radiusMiles: defaultRadiusMiles)
    }

    return fallbackScope
  }

  private var activeFeedScope: FeedScope {
    feedResponse?.scope ?? effectiveDiscoveryScope
  }

  private var mapScopeLabel: String? {
    guard discoveryScopeState?.source == .searchedPlace else {
      return nil
    }

    return discoveryScopeState?.label
  }

  private var currentLocation: AdventureLocation? {
    locationController.currentLocationCoordinate.map {
      AdventureLocation(latitude: $0.latitude, longitude: $0.longitude)
    }
  }

  var body: some View {
    ZStack {
      HATheme.Colors.background
        .ignoresSafeArea()

      if isLoading {
        ProgressView()
          .tint(HATheme.Colors.primary)
      } else if let errorMessage {
        errorState(message: errorMessage)
      } else {
        switch mode {
        case .feed:
          feedScreen
        case .map:
          mapScreen
        case .profile:
          profileScreen
        }
      }
    }
    .overlay {
      if let createAdventureVariant {
        CreateAdventureView(
          initialVariant: createAdventureVariant,
          adventureService: adventureService,
          runtimeMode: runtimeMode
        ) {
          self.createAdventureVariant = nil
        }
        .ignoresSafeArea()
        .zIndex(1)
      }
    }
    .safeAreaInset(edge: .bottom, spacing: 8) {
      if createAdventureVariant == nil {
        HABottomTabBar(
          selectedTab: selectedTab,
          onSelect: handleTabSelection
        )
      }
    }
    .task {
      if hasStartedLocationUpdates == false {
        hasStartedLocationUpdates = true
        locationController.begin(runtimeMode: runtimeMode)
      }

      guard feedResponse == nil else { return }
      await reloadDiscoveryContent()
    }
    .onReceive(locationController.$currentLocationCoordinate) { coordinate in
      guard let coordinate else {
        return
      }

      guard discoveryScopeState?.source != .searchedPlace else {
        return
      }

      let currentLocationState = ExploreDiscoveryScopeState(
        scope: FeedScope(
          center: AdventureLocation(latitude: coordinate.latitude, longitude: coordinate.longitude),
          radiusMiles: defaultRadiusMiles
        ),
        label: "",
        source: .currentLocation
      )

      guard currentLocationState != discoveryScopeState else {
        return
      }

      discoveryScopeState = currentLocationState
      Task {
        await reloadDiscoveryContent()
      }
    }
    .toolbar(.hidden, for: .navigationBar)
  }

  private var selectedTab: HAAppTab {
    switch mode {
    case .feed:
      return .home
    case .map:
      return .explore
    case .profile:
      return .profile
    }
  }

  private var feedScreen: some View {
    VStack(spacing: 0) {
      HAStatusBarSpacer()
      header

      VStack(spacing: 12) {
        visibilityControl
        categoryStrip
      }
      .padding(.horizontal, 20)
      .padding(.bottom, 12)

      FeedView(
        items: filteredItems,
        scope: activeFeedScope,
        adventureService: adventureService,
        runtimeMode: runtimeMode,
        onOpenDetail: onOpenDetail
      )
    }
  }

  private var mapScreen: some View {
    MapExploreView(
      items: feedItems,
      scope: activeFeedScope,
      scopeLabel: mapScopeLabel,
      currentLocation: currentLocation,
      adventureService: adventureService,
      runtimeMode: runtimeMode,
      onUseCurrentLocation: useCurrentLocationScope,
      onSelectDiscoveryPlace: selectDiscoveryPlace,
      onOpenDetail: onOpenDetail
    )
  }

  private var profileScreen: some View {
    ProfileView(
      handle: viewerHandle,
      adventureService: adventureService,
      profileService: profileService,
      runtimeMode: runtimeMode,
      onProfileLoaded: onViewerProfileLoaded,
      onOpenDetail: onOpenDetail,
      onLogout: onLogout
    )
  }

  private var header: some View {
    HStack(alignment: .top) {
      VStack(alignment: .leading, spacing: 4) {
        Text("Good morning")
          .font(.system(size: 14, weight: .regular))
          .foregroundStyle(HATheme.Colors.mutedForeground)

        Text(viewerDisplayName ?? viewerHandle ?? "Explorer")
          .font(.system(size: 20, weight: .semibold))
          .foregroundStyle(HATheme.Colors.foreground)
      }

      Spacer()

      HStack(spacing: 10) {
        CircleIconButton(systemImage: "magnifyingglass", accessibilityID: "header.search")
        CircleIconButton(systemImage: "bell", showsIndicator: true, accessibilityID: "header.notifications")
        if mode == .profile {
          CircleIconButton(
            systemImage: "rectangle.portrait.and.arrow.right",
            accessibilityID: "header.logout",
            action: onLogout
          )
        }
      }
    }
    .padding(.horizontal, 20)
    .padding(.top, 12)
    .padding(.bottom, 12)
  }

  private var visibilityControl: some View {
    HStack(spacing: 4) {
      ForEach(VisibilityFilter.allCases) { filter in
        Button {
          visibilityFilter = filter
        } label: {
          HStack(spacing: 3) {
            if let symbol = filter.symbolName {
              Image(systemName: symbol)
                .font(.system(size: 10, weight: .semibold))
            }

            Text(filter.title)
              .font(.system(size: 11, weight: .semibold))
              .lineLimit(1)
              .minimumScaleFactor(0.85)
          }
          .foregroundStyle(visibilityFilter == filter ? HATheme.Colors.foreground : HATheme.Colors.mutedForeground)
          .frame(maxWidth: .infinity)
          .frame(height: 32)
          .background(visibilityFilter == filter ? HATheme.Colors.card : .clear)
          .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        }
        .buttonStyle(.plain)
      }
    }
    .padding(4)
    .background(HATheme.Colors.secondary)
    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
  }

  private var categoryStrip: some View {
    ScrollView(.horizontal, showsIndicators: false) {
      HStack(spacing: 10) {
        ForEach(Category.allCases) { category in
          HAChip(
            title: category.displayTitle,
            systemImage: category.systemImage,
            isSelected: activeCategory == category
          ) {
            activeCategory = activeCategory == category ? nil : category
          }
          .accessibilityIdentifier("explore.category.\(category.rawValue)")
        }
      }
      .padding(.horizontal, 1)
    }
  }

  private func errorState(message: String) -> some View {
    VStack(spacing: 16) {
      Image(systemName: "wifi.exclamationmark")
        .font(.system(size: 32, weight: .medium))
        .foregroundStyle(HATheme.Colors.primary)

      Text("We couldn't load the Slice 1 feed.")
        .font(HATheme.Typography.sectionTitle)
        .foregroundStyle(HATheme.Colors.foreground)

      Text(message)
        .font(HATheme.Typography.body)
        .foregroundStyle(HATheme.Colors.mutedForeground)
        .multilineTextAlignment(.center)

      HAPrimaryButton(title: "Try Again") {
        Task {
          await reloadDiscoveryContent()
        }
      }
      .frame(maxWidth: 240)
    }
    .padding(24)
  }

  private func handleTabSelection(_ tab: HAAppTab) {
    switch tab {
    case .home:
      mode = .feed
    case .explore:
      mode = .map
    case .post:
      createAdventureVariant = .photos
    case .profile:
      mode = .profile
    case .saved:
      break
    }
  }

  private func useCurrentLocationScope() {
    guard let currentLocation else {
      locationController.requestCurrentLocation()
      return
    }

    let nextScopeState = ExploreDiscoveryScopeState(
      scope: FeedScope(center: currentLocation, radiusMiles: defaultRadiusMiles),
      label: "",
      source: .currentLocation
    )

    guard nextScopeState != discoveryScopeState else {
      return
    }

    discoveryScopeState = nextScopeState
    Task {
      await reloadDiscoveryContent()
    }
  }

  private func selectDiscoveryPlace(_ place: MapExploreResolvedPlace) {
    let nextScopeState = ExploreDiscoveryScopeState(
      scope: FeedScope(center: place.location, radiusMiles: defaultRadiusMiles),
      label: place.title,
      source: .searchedPlace
    )

    guard nextScopeState != discoveryScopeState else {
      return
    }

    discoveryScopeState = nextScopeState
    Task {
      await reloadDiscoveryContent()
    }
  }

  private func reloadDiscoveryContent() async {
    isLoading = true
    defer { isLoading = false }

    do {
      let feedQuery = makeFeedQuery(sort: .recent)
      let nextFeedResponse = try await adventureService.listFeed(query: feedQuery)
      feedResponse = nextFeedResponse
      errorMessage = nil
    } catch {
      errorMessage = error.localizedDescription
    }
  }

  private func makeFeedQuery(sort: FeedSort) -> FeedQuery {
    let scope = effectiveDiscoveryScope

    return FeedQuery(
      limit: defaultFeedLimit,
      offset: 0,
      latitude: scope.center.latitude,
      longitude: scope.center.longitude,
      radiusMiles: scope.radiusMiles,
      sort: sort
    )
  }

  private func radiusText(_ radiusMiles: Double) -> String {
    if radiusMiles.rounded(.towardZero) == radiusMiles {
      return "\(Int(radiusMiles)) miles"
    }

    return String(format: "%.1f miles", radiusMiles)
  }
}

private struct CircleIconButton: View {
  let systemImage: String
  var showsIndicator: Bool = false
  let accessibilityID: String
  var action: () -> Void = {}

  var body: some View {
    Button(action: action) {
      ZStack {
        Circle()
          .fill(HATheme.Colors.secondary)
          .frame(width: 40, height: 40)

        Image(systemName: systemImage)
          .font(.system(size: 18, weight: .medium))
          .foregroundStyle(HATheme.Colors.foreground)

        if showsIndicator {
          Circle()
            .fill(HATheme.Colors.primary)
            .frame(width: 8, height: 8)
            .offset(x: 11, y: -11)
        }
      }
    }
    .buttonStyle(.plain)
    .accessibilityIdentifier(accessibilityID)
  }
}

enum VisibilityFilter: CaseIterable, Identifiable {
  case all
  case `public`
  case connections
  case `private`

  var id: Self { self }

  var title: String {
    switch self {
    case .all: "All"
    case .public: "Public"
    case .connections: "Connections"
    case .private: "Private"
    }
  }

  var symbolName: String? {
    switch self {
    case .all: nil
    case .public: "globe"
    case .connections: "person.2"
    case .private: "lock"
    }
  }

  var accessibilityKey: String {
    switch self {
    case .all: "all"
    case .public: "public"
    case .connections: "connections"
    case .private: "private"
    }
  }

  func matches(_ visibility: Visibility) -> Bool {
    switch self {
    case .all: true
    case .public: visibility == .public
    case .connections: visibility == .connections
    case .private: visibility == .private
    }
  }
}

@MainActor
final class ExploreDiscoveryLocationController: NSObject, ObservableObject {
  @Published private(set) var currentLocationCoordinate: CLLocationCoordinate2D?
  @Published private(set) var authorizationStatus: CLAuthorizationStatus

  private let locationManager = CLLocationManager()

  override init() {
    authorizationStatus = locationManager.authorizationStatus
    super.init()
    locationManager.delegate = self
  }

  func begin(runtimeMode: AppRuntimeMode) {
    guard runtimeMode != .fixturePreview else {
      return
    }

    requestCurrentLocation()
  }

  func requestCurrentLocation() {
    authorizationStatus = locationManager.authorizationStatus

    switch authorizationStatus {
    case .authorizedAlways, .authorizedWhenInUse:
      locationManager.requestLocation()
    case .notDetermined:
      locationManager.requestWhenInUseAuthorization()
    case .denied, .restricted:
      break
    @unknown default:
      break
    }
  }
}

extension ExploreDiscoveryLocationController: @preconcurrency CLLocationManagerDelegate {
  func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
    authorizationStatus = manager.authorizationStatus

    switch manager.authorizationStatus {
    case .authorizedAlways, .authorizedWhenInUse:
      requestCurrentLocation()
    case .denied, .restricted, .notDetermined:
      break
    @unknown default:
      break
    }
  }

  func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
    currentLocationCoordinate = locations.last?.coordinate
  }

  func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {}
}
private struct ExploreDiscoveryScopeState: Equatable {
  let scope: FeedScope
  let label: String
  let source: ExploreDiscoveryScopeSource
}

private enum ExploreDiscoveryScopeSource {
  case currentLocation
  case searchedPlace
}

private struct ExploreShellPreviewWrapper: View {
  @State private var mode: ExploreMode = .feed
  @State private var createAdventureVariant: CreateAdventureFixtureVariant?

  var body: some View {
    ExploreShellView(
      adventureService: FixtureAdventureService(),
      profileService: FixtureProfileService(),
      runtimeMode: .fixturePreview,
      viewerHandle: "jordan",
      viewerDisplayName: "Jordan",
      mode: $mode,
      createAdventureVariant: $createAdventureVariant,
      onViewerProfileLoaded: { _ in },
      onOpenDetail: { _ in },
      onLogout: {}
    )
  }
}

struct ExploreShellView_Previews: PreviewProvider {
  static var previews: some View {
    ExploreShellPreviewWrapper()
  }
}
