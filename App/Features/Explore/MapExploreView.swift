import CoreLocation
import MapKit
import SwiftUI

struct MapExploreView: View {
  let items: [AdventureCard]
  let scope: FeedScope
  let scopeLabel: String?
  let selectedPlaceLabel: String?
  let currentLocation: AdventureLocation?
  let adventureService: any AdventureService
  let runtimeMode: AppRuntimeMode
  let onUseCurrentLocation: () -> Void
  let onSelectDiscoveryPlace: (ExploreLocationResolvedPlace) -> Void
  let onClearSelectedDiscoveryPlace: () -> Void
  let onOpenDetail: (String) -> Void

  @StateObject private var locationSearchController: ExploreLocationSearchController
  @State private var searchText = ""
  @State private var visibilityFilter: VisibilityFilter = .all
  @State private var activeCategory: Category?
  @State private var selectedAdventureID: String?
  @State private var sheetState: MapSheetState = .peek
  @State private var isFilterPopoverPresented = false
  @State private var mapPosition: MapCameraPosition = .automatic
  @State private var hasSetInitialMapPosition = false

  @FocusState private var isSearchFieldFocused: Bool

  init(
    items: [AdventureCard],
    scope: FeedScope,
    scopeLabel: String? = nil,
    selectedPlaceLabel: String? = nil,
    currentLocation: AdventureLocation? = nil,
    adventureService: any AdventureService,
    runtimeMode: AppRuntimeMode,
    initialState: MapExploreInitialState = .default,
    onUseCurrentLocation: @escaping () -> Void = {},
    onSelectDiscoveryPlace: @escaping (ExploreLocationResolvedPlace) -> Void = { _ in },
    onClearSelectedDiscoveryPlace: @escaping () -> Void = {},
    onOpenDetail: @escaping (String) -> Void
  ) {
    self.items = items
    self.scope = scope
    self.scopeLabel = scopeLabel
    self.selectedPlaceLabel = selectedPlaceLabel
    self.currentLocation = currentLocation
    self.adventureService = adventureService
    self.runtimeMode = runtimeMode
    self.onUseCurrentLocation = onUseCurrentLocation
    self.onSelectDiscoveryPlace = onSelectDiscoveryPlace
    self.onClearSelectedDiscoveryPlace = onClearSelectedDiscoveryPlace
    self.onOpenDetail = onOpenDetail
    _locationSearchController = StateObject(
      wrappedValue: ExploreLocationSearchController(runtimeMode: runtimeMode)
    )
    _searchText = State(initialValue: selectedPlaceLabel ?? initialState.searchText)
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

  private var sheetTitle: String {
    if let scopeLabel, scopeLabel.isEmpty == false {
      return "Near \(scopeLabel)"
    }

    return "Nearby Adventures"
  }

  private var sheetCountText: String {
    let count = filteredItems.count
    let noun = count == 1 ? "place" : "places"

    return "\(count) \(noun) within \(radiusText(scope.radiusMiles))"
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
        applyInitialMapPositionIfNeeded()
      }
      .onChange(of: searchText) {
        locationSearchController.updateQuery(searchText)
      }
      .onChange(of: selectedPlaceLabel) {
        syncSearchTextWithSelectedPlace()
      }
      .onChange(of: visibilityFilter) {
        updateSelectionAfterFiltering()
      }
      .onChange(of: activeCategory) {
        updateSelectionAfterFiltering()
      }
      .onChange(of: scopeCenterKey) {
        applyScopeMapPosition()
      }
      .onChange(of: items.map(\.id)) {
        updateSelectionAfterFiltering()
      }
      .onAppear {
        syncSearchTextWithSelectedPlace()
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
    ExploreLocationSuggestionsPopover(
      suggestions: locationSearchController.completions,
      suggestionsAccessibilityID: "map.searchSuggestions",
      suggestionAccessibilityPrefix: "map.searchSuggestion",
      onSelect: handleSuggestionSelection
    )
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
          Text(sheetTitle)
            .font(.system(size: 16, weight: .semibold))
            .foregroundStyle(HATheme.Colors.foreground)

          Text(sheetCountText)
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
          Text("No adventures match this area yet.")
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

      VStack(alignment: .leading, spacing: 8) {
        Text(item.category)
          .font(.system(size: 10, weight: .medium))
          .foregroundStyle(HATheme.Colors.foreground)
          .padding(.horizontal, 8)
          .padding(.vertical, 3)
          .background(.white.opacity(0.92))
          .clipShape(Capsule(style: .continuous))

        if item.distanceText != "Nearby" {
          Text(item.distanceText)
            .font(.system(size: 10, weight: .semibold))
            .foregroundStyle(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(.black.opacity(0.26))
            .clipShape(Capsule(style: .continuous))
        }
      }
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

  private var scopeCenterKey: String {
    return "\(scope.center.latitude)|\(scope.center.longitude)|\(scope.radiusMiles)"
  }

  private func applyInitialMapPositionIfNeeded() {
    guard hasSetInitialMapPosition == false else {
      return
    }

    guard let region = initialRegion else {
      return
    }

    hasSetInitialMapPosition = true
    centerMap(on: region, animated: false)
  }

  private func applyScopeMapPosition() {
    guard let region = initialRegion else {
      return
    }

    hasSetInitialMapPosition = true
    centerMap(on: region)
  }

  private var initialRegion: MKCoordinateRegion? {
    MapExploreRegionHelper.region(center: scope.center.coordinate, radiusMiles: scope.radiusMiles)
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
    if currentLocation != nil {
      onUseCurrentLocation()
    }

    if let currentLocation {
      centerMap(on: MapExploreRegionHelper.region(center: currentLocation.coordinate))
      return
    }
    
    centerMap(on: MapExploreRegionHelper.region(center: scope.center.coordinate, radiusMiles: scope.radiusMiles))
  }

  private func clearSearch() {
    let shouldResetSelectedPlace = selectedPlaceLabel?.isEmpty == false

    searchText = ""
    isSearchFieldFocused = false
    locationSearchController.clearSuggestions()
    selectedAdventureID = nil

    if shouldResetSelectedPlace {
      onClearSelectedDiscoveryPlace()
      return
    }

    recenterMap()
  }

  private func handleSuggestionSelection(_ suggestion: ExploreLocationSearchSuggestion) {
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
        onSelectDiscoveryPlace(resolved)
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

  private func radiusText(_ radiusMiles: Double) -> String {
    if radiusMiles.rounded(.towardZero) == radiusMiles {
      return "\(Int(radiusMiles)) miles"
    }

    return String(format: "%.1f miles", radiusMiles)
  }

  private func syncSearchTextWithSelectedPlace() {
    let nextValue = selectedPlaceLabel ?? ""

    guard searchText != nextValue else {
      return
    }

    searchText = nextValue
    if nextValue.isEmpty {
      locationSearchController.clearSuggestions()
    }
  }
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
        scope: FeedScope(
          center: AdventureLocation(latitude: 37.3349, longitude: -122.0090),
          radiusMiles: MapExploreRegionHelper.defaultRadiusMiles
        ),
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
      scope: FeedScope(
        center: AdventureLocation(latitude: 45.5152, longitude: -122.6784),
        radiusMiles: MapExploreRegionHelper.defaultRadiusMiles
      ),
      scopeLabel: "Portland",
      currentLocation: AdventureLocation(latitude: 45.5152, longitude: -122.6784),
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
