import SwiftUI

struct MapExploreView: View {
  let items: [AdventureCard]
  let runtimeMode: AppRuntimeMode
  let visibilityFilter: VisibilityFilter
  let activeCategory: Category?
  let onVisibilityChange: (VisibilityFilter) -> Void
  let onCategoryToggle: (Category) -> Void
  let onSelectTab: (HAAppTab) -> Void
  let onOpenDetail: (UUID) -> Void

  @State private var selectedAdventureID: UUID?

  private var selectedAdventure: AdventureCard? {
    let currentID = selectedAdventureID ?? defaultSelectedAdventureID
    return items.first { $0.id == currentID }
  }

  private var mapSheetItems: [MapCardPresentation] {
    AdventurePresentation.mapCardItems(
      from: items,
      runtimeMode: runtimeMode
    )
  }

  private var defaultSelectedAdventureID: UUID? {
    if runtimeMode == .fixturePreview,
       items.contains(where: { $0.id == MockFixtures.bluePoolID }) {
      return MockFixtures.bluePoolID
    }

    return items.first?.id
  }

  var body: some View {
    GeometryReader { geometry in
      ZStack(alignment: .bottom) {
        mapSurface(size: geometry.size)

        VStack(spacing: 0) {
          HAStatusBarSpacer()

          visibilityBar
            .padding(.horizontal, 16)
            .padding(.top, 4)

          if let selectedAdventure {
            Spacer()

            currentLocationButton
              .frame(maxWidth: .infinity, alignment: .trailing)
              .padding(.horizontal, 16)
              .padding(.bottom, 12)

            mapSheet(for: selectedAdventure)
          }
        }
      }
      .onAppear {
        selectedAdventureID = defaultSelectedAdventureID
      }
    }
  }

  private var visibilityBar: some View {
    HStack(spacing: 6) {
      ForEach(VisibilityFilter.allCases) { filter in
        Button {
          onVisibilityChange(filter)
        } label: {
          HStack(spacing: 5) {
            if let symbol = filter.symbolName {
              Image(systemName: symbol)
                .font(.system(size: 11, weight: .semibold))
            }

            Text(filter.title)
              .font(.system(size: 12, weight: .semibold))
          }
          .foregroundStyle(visibilityFilter == filter ? .white : HATheme.Colors.mutedForeground)
          .frame(maxWidth: .infinity)
          .frame(height: 34)
          .background(visibilityFilter == filter ? HATheme.Colors.primary : .clear)
          .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("map.visibility.\(filter.accessibilityKey)")
      }
    }
    .padding(4)
    .background(.white)
    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    .shadow(color: HATheme.Colors.shadow, radius: 6, x: 0, y: 2)
    .accessibilityIdentifier("map.visibilityBar")
  }

  private var currentLocationButton: some View {
    Button(action: {}) {
      Image(systemName: "location.north.fill")
        .font(.system(size: 18, weight: .semibold))
        .foregroundStyle(HATheme.Colors.primary)
        .frame(width: 44, height: 44)
        .background(HATheme.Colors.card)
        .clipShape(Circle())
        .shadow(color: HATheme.Colors.shadow, radius: 10, x: 0, y: 4)
    }
    .buttonStyle(.plain)
    .accessibilityIdentifier("map.locationButton")
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

      Path { path in
        path.move(to: CGPoint(x: 0, y: size.height * 0.38))
        path.addCurve(
          to: CGPoint(x: size.width, y: size.height * 0.31),
          control1: CGPoint(x: size.width * 0.28, y: size.height * 0.31),
          control2: CGPoint(x: size.width * 0.66, y: size.height * 0.38)
        )
      }
      .stroke(.white.opacity(0.8), style: StrokeStyle(lineWidth: 8, lineCap: .round))

      Path { path in
        path.move(to: CGPoint(x: 0, y: size.height * 0.52))
        path.addCurve(
          to: CGPoint(x: size.width, y: size.height * 0.49),
          control1: CGPoint(x: size.width * 0.20, y: size.height * 0.49),
          control2: CGPoint(x: size.width * 0.70, y: size.height * 0.56)
        )
      }
      .stroke(.white.opacity(0.74), style: StrokeStyle(lineWidth: 6, lineCap: .round))

      Ellipse()
        .fill(HATheme.Colors.accent.opacity(0.7))
        .frame(width: 120, height: 76)
        .position(x: size.width * 0.74, y: size.height * 0.33)

      Ellipse()
        .fill(HATheme.Colors.accent.opacity(0.68))
        .frame(width: 96, height: 62)
        .position(x: size.width * 0.21, y: size.height * 0.67)

      RoundedRectangle(cornerRadius: 28, style: .continuous)
        .fill(HATheme.Colors.mapForest.opacity(0.42))
        .frame(width: 128, height: 90)
        .position(x: size.width * 0.26, y: size.height * 0.24)

      RoundedRectangle(cornerRadius: 28, style: .continuous)
        .fill(HATheme.Colors.mapForest.opacity(0.42))
        .frame(width: 150, height: 110)
        .position(x: size.width * 0.77, y: size.height * 0.57)

      Path { path in
        path.move(to: CGPoint(x: size.width * 0.56, y: 0))
        path.addCurve(
          to: CGPoint(x: size.width * 0.53, y: size.height * 0.34),
          control1: CGPoint(x: size.width * 0.57, y: size.height * 0.11),
          control2: CGPoint(x: size.width * 0.53, y: size.height * 0.22)
        )
      }
      .stroke(.white.opacity(0.66), style: StrokeStyle(lineWidth: 5, lineCap: .round))

      ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
        let point = markerPoint(for: item, fallbackIndex: index, in: size)
        MapPinButton(
          adventureID: item.id,
          isSelected: item.id == (selectedAdventureID ?? defaultSelectedAdventureID),
          action: { selectedAdventureID = item.id }
        )
        .position(point)
      }
    }
  }

  private func markerPoint(for item: AdventureCard, fallbackIndex index: Int, in size: CGSize) -> CGPoint {
    if runtimeMode == .fixturePreview {
      switch item.id {
      case MockFixtures.bluePoolID:
        return CGPoint(x: size.width * 0.45, y: size.height * 0.35)
      case MockFixtures.eagleID:
        return CGPoint(x: size.width * 0.65, y: size.height * 0.25)
      case MockFixtures.tomDickID:
        return CGPoint(x: size.width * 0.30, y: size.height * 0.50)
      case MockFixtures.capeID:
        return CGPoint(x: size.width * 0.70, y: size.height * 0.45)
      default:
        break
      }
    }

    if let location = item.location,
       let bounds = liveLocationBounds {
      let longitudeSpan = max(bounds.maxLongitude - bounds.minLongitude, 0.0001)
      let latitudeSpan = max(bounds.maxLatitude - bounds.minLatitude, 0.0001)
      let normalizedX = (location.longitude - bounds.minLongitude) / longitudeSpan
      let normalizedY = 1 - ((location.latitude - bounds.minLatitude) / latitudeSpan)
      return CGPoint(
        x: size.width * (0.18 + (normalizedX * 0.64)),
        y: size.height * (0.22 + (normalizedY * 0.44))
      )
    }

    let fallbackPoints: [CGPoint] = [
      CGPoint(x: size.width * 0.55, y: size.height * 0.60),
      CGPoint(x: size.width * 0.25, y: size.height * 0.30),
      CGPoint(x: size.width * 0.72, y: size.height * 0.28),
      CGPoint(x: size.width * 0.34, y: size.height * 0.50)
    ]
    return fallbackPoints[index % fallbackPoints.count]
  }

  private var liveLocationBounds: (minLatitude: Double, maxLatitude: Double, minLongitude: Double, maxLongitude: Double)? {
    let locations = items.compactMap(\.location)
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

  private func mapSheet(for adventure: AdventureCard) -> some View {
    VStack(spacing: 0) {
      Capsule(style: .continuous)
        .fill(HATheme.Colors.border)
        .frame(width: 42, height: 5)
        .padding(.top, 10)
        .padding(.bottom, 14)

      HStack {
        VStack(alignment: .leading, spacing: 4) {
          Text("Nearby Adventures")
            .font(.system(size: 16, weight: .semibold))
            .foregroundStyle(HATheme.Colors.foreground)

          Text("\(mapSheetItems.count) places in the current feed")
            .font(.system(size: 14, weight: .regular))
            .foregroundStyle(HATheme.Colors.mutedForeground)
            .accessibilityIdentifier("map.sheet.count")
        }

        Spacer()

        Button("List view", action: {})
          .font(.system(size: 14, weight: .semibold))
          .foregroundStyle(HATheme.Colors.primary)
          .buttonStyle(.plain)
      }
      .padding(.horizontal, 20)
      .padding(.bottom, 14)

      ScrollView(.horizontal, showsIndicators: false) {
        HStack(spacing: 14) {
          ForEach(mapSheetItems) { item in
            Button {
              selectedAdventureID = item.destinationID
              onOpenDetail(item.destinationID)
            } label: {
              mapCard(for: item)
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("map.card.\(item.id)")
          }
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 16)
      }
    }
    .background(HATheme.Colors.card)
    .clipShape(RoundedRectangle(cornerRadius: 30, style: .continuous))
    .shadow(color: HATheme.Colors.shadow, radius: 20, x: 0, y: -4)
  }

  private func mapCard(for adventure: MapCardPresentation) -> some View {
    VStack(alignment: .leading, spacing: 0) {
      ZStack(alignment: .topLeading) {
        HAMediaCarouselOrPlaceholder(
          imageNames: adventure.imageNames,
          aspectRatio: 16 / 9,
          cornerRadius: 16,
          dotsInside: true,
          title: adventure.title
        )

        Text(adventure.category)
          .font(.system(size: 11, weight: .medium))
          .foregroundStyle(HATheme.Colors.foreground)
          .padding(.horizontal, 9)
          .padding(.vertical, 5)
          .background(.white.opacity(0.92))
          .clipShape(Capsule(style: .continuous))
          .padding(10)
      }

      VStack(alignment: .leading, spacing: 10) {
        Text(adventure.title)
          .font(.system(size: 15, weight: .semibold))
          .foregroundStyle(HATheme.Colors.foreground)
          .lineLimit(1)
          .accessibilityIdentifier("map.card.title.\(adventure.id)")

        HStack {
          Label(selectedAdventure?.placeLabel ?? "Hidden location", systemImage: "mappin")
            .font(.system(size: 12, weight: .medium))
            .foregroundStyle(HATheme.Colors.mutedForeground)
            .lineLimit(1)

          Spacer()

          Label(String(format: "%.1f", adventure.rating), systemImage: "star.fill")
            .font(.system(size: 12, weight: .medium))
            .foregroundStyle(HATheme.Colors.mutedForeground)
        }
      }
      .padding(14)
    }
    .frame(width: 262)
    .background(HATheme.Colors.card)
    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    .overlay {
      RoundedRectangle(cornerRadius: 16, style: .continuous)
        .stroke(HATheme.Colors.border.opacity(0.7), lineWidth: 1)
    }
  }
}

private struct MapPinButton: View {
  let adventureID: UUID
  let isSelected: Bool
  let action: () -> Void

  var body: some View {
    Button(action: action) {
      if isSelected {
        selectedMarker
      } else {
        unselectedMarker
      }
    }
    .buttonStyle(.plain)
    .accessibilityIdentifier("map.pin.\(adventureID.uuidString)")
  }

  private var selectedMarker: some View {
    ZStack(alignment: .bottom) {
      Circle()
        .fill(HATheme.Colors.primary)
        .frame(width: 38, height: 38)

      MarkerPoint()
        .fill(HATheme.Colors.primary)
        .frame(width: 18, height: 14)
        .offset(y: 8)

      ZStack {
        Circle()
          .fill(.white.opacity(0.18))
          .frame(width: 18, height: 18)

        Image(systemName: "mappin")
          .font(.system(size: 10, weight: .bold))
          .foregroundStyle(.white)
          .offset(y: -1)
      }
      .offset(y: -1)
    }
    .frame(width: 38, height: 52)
    .shadow(color: HATheme.Colors.primary.opacity(0.24), radius: 12, x: 0, y: 6)
  }

  private var unselectedMarker: some View {
    ZStack {
      Circle()
        .fill(.white)
        .frame(width: 38, height: 38)
        .overlay {
          Circle()
            .stroke(.white.opacity(0.7), lineWidth: 1)
        }

      Image(systemName: "mappin")
        .font(.system(size: 12, weight: .bold))
        .foregroundStyle(HATheme.Colors.primary.opacity(0.78))
        .offset(y: -1)
    }
    .shadow(color: HATheme.Colors.shadow.opacity(1.2), radius: 12, x: 0, y: 6)
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
