import SwiftUI

struct MapExploreView: View {
  let items: [AdventureCard]
  let adventureService: any AdventureService
  let runtimeMode: AppRuntimeMode
  let onOpenDetail: (String) -> Void

  @State private var searchText = ""
  @State private var visibilityFilter: VisibilityFilter = .all
  @State private var activeCategory: Category?
  @State private var selectedAdventureID: String?
  @State private var sheetState: MapSheetState = .peek
  @State private var isFilterPopoverPresented = false

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
      let searchMatches = searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        || item.title.localizedCaseInsensitiveContains(searchText)
        || item.placeLabel.localizedCaseInsensitiveContains(searchText)
        || item.category.localizedCaseInsensitiveContains(searchText)

      return visibilityMatches && categoryMatches && searchMatches
    }
  }

  private var selectedAdventure: MapCardPresentation? {
    guard let selectedAdventureID else {
      return nil
    }

    return filteredItems.first { $0.destinationID == selectedAdventureID }
  }

  var body: some View {
    GeometryReader { geometry in
      ZStack(alignment: .top) {
        mapSurface(size: geometry.size)

        VStack(spacing: 0) {
          topChrome
            .padding(.horizontal, 12)
            .padding(.top, 4)

          Spacer()
        }

        currentLocationIndicator(in: geometry.size)

        recenterButton(bottomInset: floatingBottomInset(for: geometry.size.height))

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
      .onChange(of: searchText) {
        updateSelectionAfterFiltering()
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
      HStack(spacing: 10) {
        Image(systemName: "magnifyingglass")
          .font(.system(size: 17, weight: .medium))
          .foregroundStyle(HATheme.Colors.mutedForeground)

        TextField("Search adventures or places...", text: $searchText)
          .font(.system(size: 16, weight: .medium))
          .foregroundStyle(HATheme.Colors.foreground)
          .textInputAutocapitalization(.words)
          .disableAutocorrection(true)
          .accessibilityIdentifier("map.searchField")

        if !searchText.isEmpty {
          Button {
            searchText = ""
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

      Button {
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

  @ViewBuilder
  private func mapSurface(size: CGSize) -> some View {
    ZStack {
      LinearGradient(
        colors: [HATheme.Colors.mapForest, HATheme.Colors.mapBackground],
        startPoint: .top,
        endPoint: .bottom
      )
      .ignoresSafeArea()

      RoundedRectangle(cornerRadius: 28, style: .continuous)
        .fill(HATheme.Colors.mapForest.opacity(0.38))
        .frame(width: 112, height: 88)
        .position(x: size.width * 0.22, y: size.height * 0.26)

      RoundedRectangle(cornerRadius: 36, style: .continuous)
        .fill(HATheme.Colors.mapForest.opacity(0.34))
        .frame(width: 150, height: 110)
        .position(x: size.width * 0.79, y: size.height * 0.78)

      Circle()
        .fill(HATheme.Colors.mapForest.opacity(0.30))
        .frame(width: 84, height: 84)
        .position(x: size.width * 0.40, y: size.height * 0.74)

      Ellipse()
        .fill(HATheme.Colors.accent.opacity(0.36))
        .frame(width: 110, height: 72)
        .position(x: size.width * 0.72, y: size.height * 0.40)

      Path { path in
        path.move(to: CGPoint(x: size.width * 0.24, y: size.height * 0.10))
        path.addCurve(
          to: CGPoint(x: size.width * 0.14, y: size.height * 0.61),
          control1: CGPoint(x: size.width * 0.31, y: size.height * 0.24),
          control2: CGPoint(x: size.width * 0.12, y: size.height * 0.42)
        )
      }
      .stroke(.white.opacity(0.60), style: StrokeStyle(lineWidth: 4, lineCap: .round))

      Path { path in
        path.move(to: CGPoint(x: size.width * 0.48, y: size.height * 0.08))
        path.addCurve(
          to: CGPoint(x: size.width * 0.37, y: size.height * 0.94),
          control1: CGPoint(x: size.width * 0.51, y: size.height * 0.31),
          control2: CGPoint(x: size.width * 0.43, y: size.height * 0.67)
        )
      }
      .stroke(.white.opacity(0.58), style: StrokeStyle(lineWidth: 4, lineCap: .round))

      Path { path in
        path.move(to: CGPoint(x: size.width * 0.77, y: size.height * 0.12))
        path.addCurve(
          to: CGPoint(x: size.width * 0.70, y: size.height * 0.46),
          control1: CGPoint(x: size.width * 0.75, y: size.height * 0.24),
          control2: CGPoint(x: size.width * 0.74, y: size.height * 0.36)
        )
      }
      .stroke(.white.opacity(0.54), style: StrokeStyle(lineWidth: 3, lineCap: .round))

      Path { path in
        path.move(to: CGPoint(x: 0, y: size.height * 0.53))
        path.addCurve(
          to: CGPoint(x: size.width, y: size.height * 0.49),
          control1: CGPoint(x: size.width * 0.24, y: size.height * 0.47),
          control2: CGPoint(x: size.width * 0.72, y: size.height * 0.59)
        )
      }
      .stroke(.white.opacity(0.82), style: StrokeStyle(lineWidth: 8, lineCap: .round))

      Path { path in
        path.move(to: CGPoint(x: 0, y: size.height * 0.77))
        path.addCurve(
          to: CGPoint(x: size.width * 0.84, y: size.height * 0.80),
          control1: CGPoint(x: size.width * 0.18, y: size.height * 0.76),
          control2: CGPoint(x: size.width * 0.53, y: size.height * 0.74)
        )
      }
      .stroke(.white.opacity(0.66), style: StrokeStyle(lineWidth: 6, lineCap: .round))

      Color.clear
        .contentShape(Rectangle())
        .ignoresSafeArea()
        .onTapGesture {
          withAnimation(.spring(response: 0.24, dampingFraction: 0.9)) {
            isFilterPopoverPresented = false
            selectedAdventureID = nil
          }
        }

      ForEach(Array(filteredItems.enumerated()), id: \.element.id) { index, item in
        let point = markerPoint(for: item, fallbackIndex: index, in: size)
        MapPinButton(
          item: item,
          isSelected: selectedAdventure?.destinationID == item.destinationID
        ) {
          withAnimation(.spring(response: 0.28, dampingFraction: 0.9)) {
            if selectedAdventure?.destinationID == item.destinationID {
              selectedAdventureID = nil
            } else {
              selectedAdventureID = item.destinationID
              sheetState = .collapsed
            }
            isFilterPopoverPresented = false
          }
        }
        .position(point)
      }
    }
  }

  private func markerPoint(
    for item: MapCardPresentation,
    fallbackIndex index: Int,
    in size: CGSize
  ) -> CGPoint {
    if runtimeMode == .fixturePreview, let markerPoint = item.markerPoint {
      return CGPoint(x: size.width * markerPoint.x, y: size.height * markerPoint.y)
    }

    if let location = item.location,
       let bounds = liveLocationBounds {
      let longitudeSpan = max(bounds.maxLongitude - bounds.minLongitude, 0.0001)
      let latitudeSpan = max(bounds.maxLatitude - bounds.minLatitude, 0.0001)
      let normalizedX = (location.longitude - bounds.minLongitude) / longitudeSpan
      let normalizedY = 1 - ((location.latitude - bounds.minLatitude) / latitudeSpan)
      return CGPoint(
        x: size.width * (0.18 + (normalizedX * 0.64)),
        y: size.height * (0.22 + (normalizedY * 0.56))
      )
    }

    let fallbackPoints: [CGPoint] = [
      CGPoint(x: size.width * 0.45, y: size.height * 0.37),
      CGPoint(x: size.width * 0.67, y: size.height * 0.28),
      CGPoint(x: size.width * 0.26, y: size.height * 0.20),
      CGPoint(x: size.width * 0.31, y: size.height * 0.53),
      CGPoint(x: size.width * 0.72, y: size.height * 0.45),
      CGPoint(x: size.width * 0.48, y: size.height * 0.73)
    ]

    return fallbackPoints[index % fallbackPoints.count]
  }

  private var liveLocationBounds: (minLatitude: Double, maxLatitude: Double, minLongitude: Double, maxLongitude: Double)? {
    let locations = filteredItems.compactMap(\.location)
    guard let first = locations.first else {
      return nil
    }

    return locations.dropFirst().reduce(
      (first.latitude, first.latitude, first.longitude, first.longitude)
    ) { partialResult, location in
      (
        min(partialResult.0, location.latitude),
        max(partialResult.1, location.latitude),
        min(partialResult.2, location.longitude),
        max(partialResult.3, location.longitude)
      )
    }
  }

  private func currentLocationIndicator(in size: CGSize) -> some View {
    ZStack {
      Circle()
        .fill(Color(red: 0.24, green: 0.48, blue: 0.96).opacity(0.16))
        .frame(width: 28, height: 28)

      Circle()
        .fill(Color(red: 0.24, green: 0.48, blue: 0.96))
        .frame(width: 12, height: 12)
        .overlay {
          Circle()
            .stroke(.white, lineWidth: 3)
        }
    }
    .position(x: size.width * 0.50, y: size.height * 0.67)
    .accessibilityIdentifier("map.currentLocation")
  }

  private func recenterButton(bottomInset: CGFloat) -> some View {
    VStack {
      Spacer()
      HStack {
        Spacer()

        Button(action: {}) {
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
    }
  }

  private func updateSelectionAfterFiltering() {
    if let selectedAdventureID,
       !filteredItems.contains(where: { $0.destinationID == selectedAdventureID }) {
      self.selectedAdventureID = nil
    }

    if filteredItems.isEmpty {
      sheetState = .peek
      isFilterPopoverPresented = false
    }
  }

  private func accessibilityAdventureID(_ id: String) -> String {
    runtimeMode == .fixturePreview ? MockFixtures.uiTestAdventureID(for: id) : id
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

  private var accessibilityAdventureID: String {
    MockFixtures.uiTestAdventureID(for: item.destinationID)
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
