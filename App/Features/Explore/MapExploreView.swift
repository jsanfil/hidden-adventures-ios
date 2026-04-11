import CoreLocation
import MapKit
import SwiftUI

struct MapExploreView: View {
  let items: [AdventureCard]
  let adventureService: any AdventureService
  let runtimeMode: AppRuntimeMode
  let onOpenDetail: (String) -> Void

  @StateObject private var locationSearchController: MapExploreLocationSearchController
  @State private var searchText = ""
  @State private var visibilityFilter: VisibilityFilter = .all
  @State private var activeCategory: Category?
  @State private var selectedAdventureID: String?
  @State private var sheetState: MapSheetState = .peek
  @State private var isFilterPopoverPresented = false
  @State private var mapPosition: MapCameraPosition = .automatic
  @State private var hasSetInitialMapPosition = false
  @State private var hasCenteredOnUserLocation = false

  @FocusState private var isSearchFieldFocused: Bool

  init(
    items: [AdventureCard],
    adventureService: any AdventureService,
    runtimeMode: AppRuntimeMode,
    initialState: MapExploreInitialState = .default,
    onOpenDetail: @escaping (String) -> Void
  ) {
    self.items = items
    self.adventureService = adventureService
    self.runtimeMode = runtimeMode
    self.onOpenDetail = onOpenDetail
    _locationSearchController = StateObject(
      wrappedValue: MapExploreLocationSearchController(runtimeMode: runtimeMode)
    )
    _searchText = State(initialValue: initialState.searchText)
    _visibilityFilter = State(initialValue: initialState.visibilityFilter)
    _activeCategory = State(initialValue: initialState.activeCategory)
    _selectedAdventureID = State(initialValue: initialState.selectedAdventureID)
    _sheetState = State(initialValue: initialState.sheetState)
    _isFilterPopoverPresented = State(initialValue: initialState.isFilterPopoverPresented)
  }

  private var mapItems: [MapCardPresentation] {
    AdventurePresentation.mapCardItems(
      from: items,
      runtimeMode: runtimeMode
    )
  }

  private var filteredItems: [MapCardPresentation] {
    mapItems.filter { item in
      let visibilityMatches = visibilityFilter.matches(item.visibility)
      let categoryMatches = activeCategory == nil || item.categorySlug == activeCategory
      return visibilityMatches && categoryMatches
    }
  }

  private var mappableItems: [MapCardPresentation] {
    filteredItems.filter { $0.location != nil }
  }

  private var selectedAdventure: MapCardPresentation? {
    guard let selectedAdventureID else {
      return nil
    }

    return filteredItems.first { $0.destinationID == selectedAdventureID }
  }

  private var shouldShowSearchSuggestions: Bool {
    isSearchFieldFocused
      && searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false
      && locationSearchController.completions.isEmpty == false
  }

  var body: some View {
    GeometryReader { geometry in
      ZStack(alignment: .top) {
        mapSurface

        VStack(spacing: 0) {
          topChrome
            .padding(.horizontal, 12)
            .padding(.top, 4)

          Spacer()
        }
        .zIndex(4)

        recenterButton(bottomInset: floatingBottomInset(for: geometry.size.height))
          .zIndex(3)

        if let selectedAdventure {
          previewCard(for: selectedAdventure)
            .padding(.horizontal, 16)
            .padding(.bottom, 106)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
            .transition(.move(edge: .bottom).combined(with: .opacity))
            .zIndex(3)
        } else {
          bottomSheet(totalHeight: geometry.size.height)
            .frame(maxHeight: .infinity, alignment: .bottom)
            .transition(.move(edge: .bottom).combined(with: .opacity))
            .zIndex(2)
        }
      }
      .clipped()
      .background(HATheme.Colors.mapBackground)
      .task {
        locationSearchController.begin()
        applyInitialMapPositionIfNeeded()
      }
      .onReceive(locationSearchController.$currentLocationCoordinate) { coordinate in
        guard let coordinate, hasCenteredOnUserLocation == false else {
          return
        }

        hasCenteredOnUserLocation = true
        hasSetInitialMapPosition = true
        centerMap(on: MapExploreRegionHelper.region(center: coordinate))
      }
      .onChange(of: searchText) {
        locationSearchController.updateQuery(searchText)
      }
      .onChange(of: visibilityFilter) {
        updateSelectionAfterFiltering()
      }
      .onChange(of: activeCategory) {
        updateSelectionAfterFiltering()
      }
    }
  }

  private var topChrome: some View {
    HStack(alignment: .top, spacing: 10) {
      ZStack(alignment: .topLeading) {
        HStack(spacing: 10) {
          Image(systemName: "magnifyingglass")
            .font(.system(size: 17, weight: .medium))
            .foregroundStyle(HATheme.Colors.mutedForeground)

          TextField("Search for a place...", text: $searchText)
            .font(.system(size: 16, weight: .medium))
            .foregroundStyle(HATheme.Colors.foreground)
            .textInputAutocapitalization(.words)
            .disableAutocorrection(true)
            .focused($isSearchFieldFocused)
            .submitLabel(.search)
            .onSubmit {
              Task {
                await selectFirstSuggestionIfNeeded()
              }
            }
            .accessibilityIdentifier("map.searchField")

          if searchText.isEmpty == false {
            Button {
              clearSearch()
            } label: {
              Image(systemName: "xmark")
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(HATheme.Colors.mutedForeground)
                .frame(width: 22, height: 22)
                .background(HATheme.Colors.secondary)
                .clipShape(Circle())
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("map.searchClear")
          }
        }
        .padding(.horizontal, 16)
        .frame(height: 44)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: HATheme.Colors.shadow.opacity(1.1), radius: 14, x: 0, y: 6)

        if shouldShowSearchSuggestions {
          searchSuggestionsPopover
            .padding(.top, 56)
        }
      }
      .frame(maxWidth: .infinity, alignment: .leading)

      Button {
        isSearchFieldFocused = false
        locationSearchController.clearSuggestions()
        withAnimation(.spring(response: 0.25, dampingFraction: 0.9)) {
          isFilterPopoverPresented.toggle()
        }
      } label: {
        Image(systemName: "slider.horizontal.3")
          .font(.system(size: 18, weight: .semibold))
          .foregroundStyle(isFilterPopoverPresented || visibilityFilter != .all ? .white : HATheme.Colors.foreground)
          .frame(width: 44, height: 44)
          .background(isFilterPopoverPresented || visibilityFilter != .all ? HATheme.Colors.primary : .white)
          .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
          .shadow(color: HATheme.Colors.shadow.opacity(1.1), radius: 14, x: 0, y: 6)
      }
      .buttonStyle(.plain)
      .accessibilityIdentifier("map.filterButton")
      .overlay(alignment: .topTrailing) {
        if isFilterPopoverPresented {
          filterPopover
            .offset(x: 0, y: 56)
        }
      }
    }
  }

  private var searchSuggestionsPopover: some View {
    VStack(alignment: .leading, spacing: 0) {
      ForEach(locationSearchController.completions) { suggestion in
        Button {
          handleSuggestionSelection(suggestion)
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
        .accessibilityIdentifier("map.searchSuggestion.\(suggestion.accessibilityIdentifier)")

        if suggestion.id != locationSearchController.completions.last?.id {
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
    .accessibilityIdentifier("map.searchSuggestions")
  }

  private var filterPopover: some View {
    VStack(alignment: .leading, spacing: 0) {
      Text("SHOW ADVENTURES")
        .font(.system(size: 12, weight: .semibold))
        .foregroundStyle(HATheme.Colors.mutedForeground)
        .padding(.horizontal, 16)
        .padding(.top, 14)
        .padding(.bottom, 8)

      ForEach(VisibilityFilter.allCases) { filter in
        Button {
          visibilityFilter = filter
          withAnimation(.spring(response: 0.24, dampingFraction: 0.9)) {
            isFilterPopoverPresented = false
          }
        } label: {
          HStack(spacing: 12) {
            Image(systemName: filter.symbolName ?? "globe")
              .font(.system(size: 15, weight: .medium))
              .foregroundStyle(HATheme.Colors.foreground)
              .frame(width: 18)

            Text(filter.title)
              .font(.system(size: 16, weight: .medium))
              .foregroundStyle(HATheme.Colors.foreground)

            Spacer()

            if visibilityFilter == filter {
              Image(systemName: "checkmark")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(HATheme.Colors.primary)
            }
          }
          .padding(.horizontal, 16)
          .frame(height: 44)
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("map.filter.option.\(filter.accessibilityKey)")
      }
    }
    .frame(width: 212)
    .background(.white)
    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    .shadow(color: HATheme.Colors.shadow.opacity(1.3), radius: 22, x: 0, y: 10)
    .accessibilityElement(children: .contain)
    .accessibilityIdentifier("map.filterPopover")
  }

  private var mapSurface: some View {
    Map(position: $mapPosition, interactionModes: .all) {
      UserAnnotation()

      ForEach(mappableItems) { item in
        if let coordinate = item.location?.coordinate {
          Annotation(item.title, coordinate: coordinate, anchor: .bottom) {
            MapPinButton(
              item: item,
              isSelected: selectedAdventure?.destinationID == item.destinationID,
              accessibilityAdventureID: accessibilityAdventureID(item.destinationID)
            ) {
              withAnimation(.spring(response: 0.28, dampingFraction: 0.9)) {
                if selectedAdventure?.destinationID == item.destinationID {
                  selectedAdventureID = nil
                } else {
                  selectedAdventureID = item.destinationID
                  sheetState = .collapsed
                  centerMap(on: item)
                }
                isFilterPopoverPresented = false
                isSearchFieldFocused = false
                locationSearchController.clearSuggestions()
              }
            }
          }
        }
      }
    }
    .mapStyle(.standard(elevation: .realistic))
    .ignoresSafeArea()
    .simultaneousGesture(
      TapGesture().onEnded {
        withAnimation(.spring(response: 0.24, dampingFraction: 0.9)) {
          isFilterPopoverPresented = false
          isSearchFieldFocused = false
          locationSearchController.clearSuggestions()
          selectedAdventureID = nil
        }
      }
    )
    .accessibilityIdentifier("map.surface")
  }

  private func recenterButton(bottomInset: CGFloat) -> some View {
    VStack {
      Spacer()
      HStack {
        Spacer()

        Button {
          recenterMap()
        } label: {
          Image(systemName: "scope")
            .font(.system(size: 18, weight: .semibold))
            .foregroundStyle(HATheme.Colors.primary)
            .frame(width: 46, height: 46)
            .background(.white)
            .clipShape(Circle())
            .shadow(color: HATheme.Colors.shadow.opacity(1.1), radius: 14, x: 0, y: 8)
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("map.recenterButton")
      }
      .padding(.horizontal, 16)
      .padding(.bottom, bottomInset)
    }
  }

  private func bottomSheet(totalHeight: CGFloat) -> some View {
    VStack(spacing: 0) {
      Capsule(style: .continuous)
        .fill(HATheme.Colors.border)
        .frame(width: 40, height: 5)
        .padding(.top, sheetState == .collapsed ? 6 : 10)
        .padding(.bottom, sheetState == .collapsed ? 8 : 14)
        .accessibilityIdentifier("map.sheet.handle")
        .gesture(
          DragGesture(minimumDistance: 20)
            .onEnded(handleSheetDrag)
        )

      HStack(alignment: .top) {
        VStack(alignment: .leading, spacing: sheetState == .collapsed ? 2 : 4) {
          Text("Nearby Adventures")
            .font(.system(size: 16, weight: .semibold))
            .foregroundStyle(HATheme.Colors.foreground)

          Text("\(filteredItems.count) places within 25 miles")
            .font(.system(size: 14, weight: .regular))
            .foregroundStyle(HATheme.Colors.mutedForeground)
            .accessibilityIdentifier("map.sheet.count")
        }

        Spacer()

        Button(sheetState == .expanded ? "Map view" : "List view") {
          withAnimation(.spring(response: 0.28, dampingFraction: 0.9)) {
            sheetState = sheetState == .expanded ? .peek : .expanded
          }
        }
        .font(.system(size: 15, weight: .medium))
        .foregroundStyle(HATheme.Colors.primary)
        .buttonStyle(.plain)
        .accessibilityIdentifier("map.sheet.modeButton")
      }
      .padding(.horizontal, 20)
      .padding(.bottom, sheetState == .collapsed ? 6 : 14)

      if sheetState != .collapsed {
        categoryStrip
          .padding(.bottom, 14)

        if sheetState == .peek {
          peekCardRail
        } else {
          expandedList
        }
      }

      Spacer(minLength: 0)
    }
    .frame(height: sheetHeight(for: totalHeight), alignment: .top)
    .frame(maxWidth: .infinity)
    .background(.white)
    .clipShape(RoundedRectangle(cornerRadius: 30, style: .continuous))
    .shadow(color: HATheme.Colors.shadow.opacity(1.2), radius: 26, x: 0, y: -6)
    .accessibilityElement(children: .contain)
  }

  private var categoryStrip: some View {
    ScrollView(.horizontal, showsIndicators: false) {
      HStack(spacing: 10) {
        ForEach(Category.allCases) { category in
          Button {
            withAnimation(.spring(response: 0.24, dampingFraction: 0.9)) {
              activeCategory = activeCategory == category ? nil : category
            }
          } label: {
            HStack(spacing: 6) {
              Image(systemName: category.systemImage)
                .font(.system(size: 12, weight: .semibold))

              Text(category.displayTitle)
                .font(.system(size: 13, weight: .medium))
            }
            .foregroundStyle(activeCategory == category ? .white : HATheme.Colors.foreground)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(activeCategory == category ? HATheme.Colors.primary : HATheme.Colors.secondary)
            .clipShape(Capsule(style: .continuous))
          }
          .buttonStyle(.plain)
          .accessibilityIdentifier("map.category.\(category.rawValue)")
        }
      }
      .padding(.horizontal, 20)
    }
  }

  private var peekCardRail: some View {
    ScrollView(.horizontal, showsIndicators: false) {
      HStack(spacing: 4) {
        ForEach(filteredItems) { item in
          Button {
            selectAdventure(item)
          } label: {
            mapCard(for: item)
          }
          .buttonStyle(.plain)
          .accessibilityIdentifier("map.card.\(accessibilityAdventureID(item.destinationID))")
        }
      }
      .padding(.horizontal, 20)
      .padding(.bottom, 16)
    }
  }

  private var expandedList: some View {
    ScrollView {
      LazyVStack(spacing: 12) {
        if filteredItems.isEmpty {
          Text("No adventures match this search yet.")
            .font(.system(size: 15, weight: .medium))
            .foregroundStyle(HATheme.Colors.mutedForeground)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.top, 8)
        }

        ForEach(filteredItems) { item in
          Button {
            selectAdventure(item)
          } label: {
            expandedRow(for: item)
          }
          .buttonStyle(.plain)
          .accessibilityIdentifier("map.listrow.\(accessibilityAdventureID(item.destinationID))")
        }
      }
      .padding(.horizontal, 20)
      .padding(.bottom, 108)
    }
  }

  private func mapCard(for item: MapCardPresentation) -> some View {
    ZStack(alignment: .topLeading) {
      mapMedia(for: item, aspectRatio: 16 / 10, cornerRadius: 18)
        .overlay {
          RoundedRectangle(cornerRadius: 18, style: .continuous)
            .fill(
              LinearGradient(
                colors: [.clear, .clear, .black.opacity(0.45)],
                startPoint: .top,
                endPoint: .bottom
              )
            )
        }
        .accessibilityIdentifier("map.card.image.\(item.id)")
      Text(item.category)
        .font(.system(size: 10, weight: .medium))
        .foregroundStyle(HATheme.Colors.foreground)
        .padding(.horizontal, 8)
        .padding(.vertical, 3)
        .background(.white.opacity(0.92))
        .clipShape(Capsule(style: .continuous))
        .padding(8)

      VStack {
        Spacer(minLength: 0)

        Text(item.title)
          .font(.system(size: 14, weight: .semibold))
          .foregroundStyle(.white)
          .lineLimit(1)
          .allowsTightening(true)
          .minimumScaleFactor(0.82)
          .truncationMode(.tail)
          .frame(maxWidth: .infinity, alignment: .leading)
          .padding(.horizontal, 10)
          .padding(.bottom, 10)
          .accessibilityIdentifier("map.card.title.\(item.id)")
      }
    }
    .frame(width: 240)
  }

  private func expandedRow(for item: MapCardPresentation) -> some View {
    HStack(spacing: 12) {
      mapMedia(for: item, aspectRatio: 1, cornerRadius: 14)
        .frame(width: 64, height: 64)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

      VStack(alignment: .leading, spacing: 6) {
        Text(item.title)
          .font(.system(size: 15, weight: .semibold))
          .foregroundStyle(HATheme.Colors.foreground)
          .lineLimit(1)

        Text(item.placeLabel)
          .font(.system(size: 13, weight: .medium))
          .foregroundStyle(HATheme.Colors.mutedForeground)
          .lineLimit(1)

        HStack(spacing: 10) {
          Text(item.distanceText)
          Label(String(format: "%.1f", item.rating), systemImage: "star.fill")
        }
        .font(.system(size: 12, weight: .medium))
        .foregroundStyle(HATheme.Colors.mutedForeground)
      }

      Spacer()

      Image(systemName: "chevron.right")
        .font(.system(size: 14, weight: .semibold))
        .foregroundStyle(HATheme.Colors.mutedForeground)
    }
    .padding(12)
    .background(HATheme.Colors.secondary.opacity(0.52))
    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
  }

  private func previewCard(for item: MapCardPresentation) -> some View {
    ZStack(alignment: .topTrailing) {
      ZStack(alignment: .bottomLeading) {
        mapMedia(for: item, aspectRatio: 4 / 3, cornerRadius: 24)
          .overlay {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
              .fill(
                LinearGradient(
                  colors: [.clear, .black.opacity(0.12), .black.opacity(0.68)],
                  startPoint: .top,
                  endPoint: .bottom
                )
              )
          }

        VStack(alignment: .leading, spacing: 10) {
          Text(item.title)
            .font(.system(size: 18, weight: .semibold))
            .foregroundStyle(.white)

          HStack(spacing: 8) {
            Label(item.placeLabel, systemImage: "mappin")
              .lineLimit(1)

            Text("·")

            Text(item.distanceText)

            Spacer(minLength: 8)

            Label(String(format: "%.1f", item.rating), systemImage: "star.fill")
          }
          .font(.system(size: 14, weight: .medium))
          .foregroundStyle(.white.opacity(0.84))
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 18)
        .frame(maxWidth: .infinity, alignment: .leading)
      }

      HStack {
        Text(item.category)
          .font(.system(size: 11, weight: .medium))
          .foregroundStyle(HATheme.Colors.foreground)
          .padding(.horizontal, 10)
          .padding(.vertical, 5)
          .background(.white.opacity(0.92))
          .clipShape(Capsule(style: .continuous))

        Spacer()

        Button {
          withAnimation(.spring(response: 0.24, dampingFraction: 0.9)) {
            selectedAdventureID = nil
          }
        } label: {
          Image(systemName: "xmark")
            .font(.system(size: 12, weight: .bold))
            .foregroundStyle(HATheme.Colors.foreground)
            .frame(width: 32, height: 32)
            .background(.white.opacity(0.92))
            .clipShape(Circle())
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("map.preview.close")
      }
      .padding(14)
    }
    .contentShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
    .onTapGesture {
      onOpenDetail(item.destinationID)
    }
    .accessibilityElement(children: .contain)
    .accessibilityIdentifier("map.preview")
  }

  private func mapMedia(
    for item: MapCardPresentation,
    aspectRatio: CGFloat,
    cornerRadius: CGFloat
  ) -> some View {
    let source: HAMediaSource = runtimeMode == .fixturePreview
      ? .fixture(item.imageNames)
      : .remote(
        items.first(where: { $0.id == item.destinationID })?.primaryMedia.map(\.id).map { [$0] } ?? [],
        adventureService
      )

    return HAMediaCarouselOrPlaceholder(
      source: source,
      aspectRatio: aspectRatio,
      cornerRadius: cornerRadius,
      dotsInside: true,
      title: item.title
    )
  }

  private func floatingBottomInset(for totalHeight: CGFloat) -> CGFloat {
    if selectedAdventure != nil {
      return 238
    }

    return sheetHeight(for: totalHeight) + 18
  }

  private func sheetHeight(for totalHeight: CGFloat) -> CGFloat {
    switch sheetState {
    case .collapsed:
      return 86
    case .peek:
      return 286
    case .expanded:
      return totalHeight * 0.68
    }
  }

  private func handleSheetDrag(_ value: DragGesture.Value) {
    let delta = value.translation.height
    guard abs(delta) > 36 else {
      return
    }

    withAnimation(.spring(response: 0.28, dampingFraction: 0.9)) {
      if delta < 0 {
        switch sheetState {
        case .collapsed:
          sheetState = .peek
        case .peek:
          sheetState = .expanded
        case .expanded:
          break
        }
      } else {
        switch sheetState {
        case .expanded:
          sheetState = .peek
        case .peek:
          sheetState = .collapsed
        case .collapsed:
          break
        }
      }
    }
  }

  private func selectAdventure(_ item: MapCardPresentation) {
    withAnimation(.spring(response: 0.28, dampingFraction: 0.9)) {
      selectedAdventureID = item.destinationID
      isFilterPopoverPresented = false
      isSearchFieldFocused = false
      locationSearchController.clearSuggestions()
      centerMap(on: item)
    }
  }

  private func updateSelectionAfterFiltering() {
    selectedAdventureID = MapExploreSelectionHelper.validSelectionID(
      currentSelectionID: selectedAdventureID,
      filteredItems: filteredItems
    )

    if filteredItems.isEmpty {
      sheetState = .peek
      isFilterPopoverPresented = false
    }
  }

  private func applyInitialMapPositionIfNeeded() {
    guard hasSetInitialMapPosition == false else {
      return
    }

    guard let region = locationSearchController.defaultInitialRegion(for: filteredItems) else {
      return
    }

    hasSetInitialMapPosition = true
    centerMap(on: region, animated: false)
  }

  private func centerMap(on item: MapCardPresentation) {
    guard let coordinate = item.location?.coordinate else {
      return
    }

    centerMap(on: MapExploreRegionHelper.region(center: coordinate))
  }

  private func centerMap(on region: MKCoordinateRegion, animated: Bool = true) {
    if animated {
      withAnimation(.spring(response: 0.3, dampingFraction: 0.9)) {
        mapPosition = .region(region)
      }
    } else {
      mapPosition = .region(region)
    }
  }

  private func recenterMap() {
    if let region = locationSearchController.regionAroundCurrentLocation() {
      hasCenteredOnUserLocation = true
      centerMap(on: region)
      return
    }

    if let region = MapExploreRegionHelper.fallbackRegion(for: filteredItems) {
      centerMap(on: region)
    }
  }

  private func clearSearch() {
    searchText = ""
    isSearchFieldFocused = false
    locationSearchController.clearSuggestions()
    recenterMap()
  }

  private func handleSuggestionSelection(_ suggestion: MapExploreSearchSuggestion) {
    Task {
      guard let resolved = await locationSearchController.resolveSuggestion(suggestion) else {
        return
      }

      await MainActor.run {
        searchText = resolved.title
        selectedAdventureID = nil
        isFilterPopoverPresented = false
        isSearchFieldFocused = false
        locationSearchController.clearSuggestions()
        centerMap(on: resolved.region)
      }
    }
  }

  private func selectFirstSuggestionIfNeeded() async {
    guard let suggestion = locationSearchController.completions.first else {
      return
    }

    handleSuggestionSelection(suggestion)
  }

  private func accessibilityAdventureID(_ id: String) -> String {
    runtimeMode == .fixturePreview ? MockFixtures.uiTestAdventureID(for: id) : id
  }
}

@MainActor
final class MapExploreLocationSearchController: NSObject, ObservableObject {
  @Published private(set) var completions: [MapExploreSearchSuggestion] = []
  @Published private(set) var currentLocationCoordinate: CLLocationCoordinate2D?

  private let runtimeMode: AppRuntimeMode
  private let locationManager: CLLocationManager?
  private let completer: MKLocalSearchCompleter?
  private var hasRequestedLocation = false

  init(runtimeMode: AppRuntimeMode) {
    self.runtimeMode = runtimeMode

    if runtimeMode == .fixturePreview {
      locationManager = nil
      completer = nil
    } else {
      let locationManager = CLLocationManager()
      let completer = MKLocalSearchCompleter()
      self.locationManager = locationManager
      self.completer = completer
      super.init()
      locationManager.delegate = self
      completer.delegate = self
      completer.resultTypes = [.address, .pointOfInterest]
      return
    }

    super.init()
  }

  func begin() {
    guard runtimeMode != .fixturePreview, let locationManager else {
      return
    }

    switch locationManager.authorizationStatus {
    case .authorizedAlways, .authorizedWhenInUse:
      requestLocationIfNeeded()
    case .notDetermined:
      locationManager.requestWhenInUseAuthorization()
    case .denied, .restricted:
      break
    @unknown default:
      break
    }
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
      completions = MapExploreSearchSuggestion.fixtureSuggestions.filter { suggestion in
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

  func defaultInitialRegion(for items: [MapCardPresentation]) -> MKCoordinateRegion? {
    if let region = regionAroundCurrentLocation() {
      return region
    }

    return MapExploreRegionHelper.fallbackRegion(for: items)
  }

  func regionAroundCurrentLocation() -> MKCoordinateRegion? {
    guard let currentLocationCoordinate else {
      return nil
    }

    return MapExploreRegionHelper.region(center: currentLocationCoordinate)
  }

  func resolveSuggestion(_ suggestion: MapExploreSearchSuggestion) async -> MapExploreResolvedPlace? {
    if let coordinate = suggestion.fixtureCoordinate {
      return MapExploreResolvedPlace(
        title: suggestion.displayLabel,
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
        return MapExploreResolvedPlace(
          title: suggestion.displayLabel,
          region: MapExploreRegionHelper.region(center: coordinate)
        )
      }
    } catch {
      return nil
    }

    return nil
  }

  private func requestLocationIfNeeded() {
    guard hasRequestedLocation == false, let locationManager else {
      return
    }

    hasRequestedLocation = true
    locationManager.requestLocation()
  }
}

extension MapExploreLocationSearchController: @preconcurrency CLLocationManagerDelegate {
  func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
    switch manager.authorizationStatus {
    case .authorizedAlways, .authorizedWhenInUse:
      requestLocationIfNeeded()
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

extension MapExploreLocationSearchController: @preconcurrency MKLocalSearchCompleterDelegate {
  func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
    completions = completer.results.map(MapExploreSearchSuggestion.init(completion:))
  }

  func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: Error) {
    completions = []
  }
}

struct MapExploreSearchSuggestion: Identifiable {
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

  static let fixtureSuggestions: [MapExploreSearchSuggestion] = [
    MapExploreSearchSuggestion(
      title: "Portland",
      subtitle: "Oregon",
      fixtureCoordinate: CLLocationCoordinate2D(latitude: 45.5152, longitude: -122.6784)
    ),
    MapExploreSearchSuggestion(
      title: "Mount Hood",
      subtitle: "Oregon",
      fixtureCoordinate: CLLocationCoordinate2D(latitude: 45.3735, longitude: -121.6959)
    ),
    MapExploreSearchSuggestion(
      title: "Columbia River Gorge",
      subtitle: "Oregon",
      fixtureCoordinate: CLLocationCoordinate2D(latitude: 45.6698, longitude: -121.8842)
    )
  ]
}

struct MapExploreResolvedPlace {
  let title: String
  let region: MKCoordinateRegion
}

enum MapExploreRegionHelper {
  static let defaultRadiusMiles = 25.0
  private static let metersPerMile = 1_609.344

  static func region(
    center: CLLocationCoordinate2D,
    radiusMiles: Double = defaultRadiusMiles
  ) -> MKCoordinateRegion {
    let diameterMeters = radiusMiles * metersPerMile * 2
    return MKCoordinateRegion(
      center: center,
      latitudinalMeters: diameterMeters,
      longitudinalMeters: diameterMeters
    )
  }

  static func fallbackRegion(for items: [MapCardPresentation]) -> MKCoordinateRegion? {
    let coordinates = items.compactMap(\.location?.coordinate)
    guard let first = coordinates.first else {
      return nil
    }

    guard coordinates.count > 1 else {
      return region(center: first)
    }

    let minLatitude = coordinates.map(\.latitude).min() ?? first.latitude
    let maxLatitude = coordinates.map(\.latitude).max() ?? first.latitude
    let minLongitude = coordinates.map(\.longitude).min() ?? first.longitude
    let maxLongitude = coordinates.map(\.longitude).max() ?? first.longitude

    let center = CLLocationCoordinate2D(
      latitude: (minLatitude + maxLatitude) / 2,
      longitude: (minLongitude + maxLongitude) / 2
    )

    let latitudeDelta = max((maxLatitude - minLatitude) * 1.4, 0.08)
    let longitudeDelta = max((maxLongitude - minLongitude) * 1.4, 0.08)

    return MKCoordinateRegion(
      center: center,
      span: MKCoordinateSpan(latitudeDelta: latitudeDelta, longitudeDelta: longitudeDelta)
    )
  }
}

enum MapExploreSelectionHelper {
  static func validSelectionID(
    currentSelectionID: String?,
    filteredItems: [MapCardPresentation]
  ) -> String? {
    guard let currentSelectionID else {
      return nil
    }

    return filteredItems.contains(where: { $0.destinationID == currentSelectionID })
      ? currentSelectionID
      : nil
  }
}

struct MapExploreView_Previews: PreviewProvider {
  static var previews: some View {
    Group {
      MapExploreView(
        items: MockFixtures.feedItems,
        adventureService: FixtureAdventureService(),
        runtimeMode: .fixturePreview,
        onOpenDetail: { _ in }
      )
      .previewDisplayName("Map Default")

      MapExplorePreviewHarness(
        initialSelection: MockFixtures.oneontaID,
        initialSheetState: .peek,
        searchText: "",
        activeCategory: nil,
        visibilityFilter: .all,
        isFilterPopoverPresented: false
      )
      .previewDisplayName("Selected Preview")

      MapExplorePreviewHarness(
        initialSelection: nil,
        initialSheetState: .peek,
        searchText: "Port",
        activeCategory: nil,
        visibilityFilter: .all,
        isFilterPopoverPresented: false
      )
      .previewDisplayName("Search Suggestions")

      MapExplorePreviewHarness(
        initialSelection: nil,
        initialSheetState: .peek,
        searchText: "",
        activeCategory: nil,
        visibilityFilter: .all,
        isFilterPopoverPresented: true
      )
      .previewDisplayName("Filter Open")

      MapExplorePreviewHarness(
        initialSelection: nil,
        initialSheetState: .expanded,
        searchText: "",
        activeCategory: .trails,
        visibilityFilter: .all,
        isFilterPopoverPresented: false
      )
      .previewDisplayName("Expanded List")
    }
  }
}

private struct MapExplorePreviewHarness: View {
  let initialSelection: String?
  let initialSheetState: MapSheetState
  let searchText: String
  let activeCategory: Category?
  let visibilityFilter: VisibilityFilter
  let isFilterPopoverPresented: Bool

  var body: some View {
    MapExploreView(
      items: MockFixtures.feedItems,
      adventureService: FixtureAdventureService(),
      runtimeMode: .fixturePreview,
      initialState: MapExploreInitialState(
        searchText: searchText,
        visibilityFilter: visibilityFilter,
        activeCategory: activeCategory,
        selectedAdventureID: initialSelection,
        sheetState: initialSheetState,
        isFilterPopoverPresented: isFilterPopoverPresented
      ),
      onOpenDetail: { _ in }
    )
  }
}

struct MapExploreInitialState {
  let searchText: String
  let visibilityFilter: VisibilityFilter
  let activeCategory: Category?
  let selectedAdventureID: String?
  let sheetState: MapSheetState
  let isFilterPopoverPresented: Bool

  static let `default` = MapExploreInitialState(
    searchText: "",
    visibilityFilter: .all,
    activeCategory: nil,
    selectedAdventureID: nil,
    sheetState: .peek,
    isFilterPopoverPresented: false
  )
}

enum MapSheetState {
  case collapsed
  case peek
  case expanded
}

private struct MapPinButton: View {
  let item: MapCardPresentation
  let isSelected: Bool
  let accessibilityAdventureID: String
  let action: () -> Void

  var body: some View {
    Button(action: action) {
      VStack(spacing: 4) {
        Text(item.title)
          .font(.system(size: 11, weight: .semibold))
          .foregroundStyle(isSelected ? .white : HATheme.Colors.foreground)
          .padding(.horizontal, 10)
          .padding(.vertical, 5)
          .background(isSelected ? HATheme.Colors.primary : .white)
          .clipShape(Capsule(style: .continuous))
          .shadow(color: HATheme.Colors.shadow.opacity(1.1), radius: 8, x: 0, y: 4)

        ZStack {
          MarkerPoint()
            .fill(isSelected ? HATheme.Colors.primary : .white)
            .frame(width: 16, height: 12)
            .offset(y: 19)

          Circle()
            .fill(isSelected ? HATheme.Colors.primary : .white)
            .frame(width: 38, height: 38)

          Image(systemName: item.categorySlug?.systemImage ?? "sparkles")
            .font(.system(size: 13, weight: .semibold))
            .foregroundStyle(isSelected ? .white : HATheme.Colors.primary)
            .frame(width: 38, height: 38, alignment: .center)
        }
        .frame(width: 38, height: 50)
      }
      .scaleEffect(isSelected ? 1.1 : 1.0)
      .shadow(
        color: isSelected ? HATheme.Colors.primary.opacity(0.24) : HATheme.Colors.shadow.opacity(1.1),
        radius: 12,
        x: 0,
        y: 6
      )
    }
    .buttonStyle(.plain)
    .accessibilityIdentifier("map.pin.\(accessibilityAdventureID)")
  }
}

private struct MarkerPoint: Shape {
  func path(in rect: CGRect) -> Path {
    var path = Path()
    path.move(to: CGPoint(x: rect.midX, y: rect.maxY))
    path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
    path.addLine(to: CGPoint(x: rect.minX, y: rect.minY))
    path.closeSubpath()
    return path
  }
}

private extension AdventureLocation {
  var coordinate: CLLocationCoordinate2D {
    CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
  }
}
