import SwiftUI

struct MapExploreView: View {
  let items: [AdventureCard]
  let visibilityFilter: VisibilityFilter
  let activeCategory: Category?
  let onVisibilityChange: (VisibilityFilter) -> Void
  let onCategoryToggle: (Category) -> Void
  let onSelectTab: (HAAppTab) -> Void
  let onOpenDetail: (UUID) -> Void

  @State private var selectedAdventureID: UUID?

  private var selectedAdventure: AdventureCard? {
    let currentID = selectedAdventureID ?? items.first?.id
    return items.first { $0.id == currentID }
  }

  var body: some View {
    GeometryReader { geometry in
      ZStack(alignment: .bottom) {
        mapSurface(size: geometry.size)

        VStack(spacing: 0) {
          HAStatusBarSpacer()

          VStack(spacing: 12) {
            searchBar
            visibilityBar
            categoryStrip
          }
          .padding(.horizontal, 16)

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
        selectedAdventureID = items.first?.id
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
      }
    }
    .padding(4)
    .background(.white)
    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    .shadow(color: HATheme.Colors.shadow, radius: 6, x: 0, y: 2)
  }

  private var searchBar: some View {
    HStack(spacing: 12) {
      Image(systemName: "magnifyingglass")
        .font(.system(size: 17, weight: .medium))
        .foregroundStyle(HATheme.Colors.mutedForeground)

      Text("Search places...")
        .font(HATheme.Typography.body)
        .foregroundStyle(HATheme.Colors.mutedForeground)

      Spacer()

      HStack(spacing: 4) {
        Text("Portland, OR")
        Image(systemName: "chevron.down")
          .font(.system(size: 13, weight: .semibold))
      }
      .font(.system(size: 14, weight: .medium))
      .foregroundStyle(HATheme.Colors.mutedForeground)
    }
    .padding(.horizontal, 16)
    .frame(height: 52)
    .background(HATheme.Colors.card)
    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    .shadow(color: HATheme.Colors.shadow, radius: 10, x: 0, y: 4)
  }

  private var categoryStrip: some View {
    ScrollView(.horizontal, showsIndicators: false) {
      HStack(spacing: 8) {
        ForEach(Category.allCases) { category in
          HAChip(
            title: category.displayTitle,
            systemImage: category.systemImage,
            isSelected: activeCategory == category
          ) {
            onCategoryToggle(category)
          }
        }
      }
      .padding(.horizontal, 1)
      .padding(.bottom, 2)
    }
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

      ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
        let point = markerPoint(for: index, in: size)
        MapPinButton(
          isSelected: item.id == (selectedAdventureID ?? items.first?.id),
          action: { selectedAdventureID = item.id }
        )
        .position(point)
      }
    }
  }

  private func markerPoint(for index: Int, in size: CGSize) -> CGPoint {
    let points: [CGPoint] = [
      CGPoint(x: size.width * 0.47, y: size.height * 0.31),
      CGPoint(x: size.width * 0.69, y: size.height * 0.25),
      CGPoint(x: size.width * 0.32, y: size.height * 0.47),
      CGPoint(x: size.width * 0.71, y: size.height * 0.43)
    ]
    return points[index % points.count]
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

          Text("\(items.count) places within 25 miles")
            .font(.system(size: 14, weight: .regular))
            .foregroundStyle(HATheme.Colors.mutedForeground)
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
          ForEach(items) { item in
            Button {
              selectedAdventureID = item.id
              onOpenDetail(item.id)
            } label: {
              mapCard(for: item)
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("map.card.\(item.id.uuidString)")
          }
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 16)
      }

      HABottomTabBar(selectedTab: .explore, onSelect: onSelectTab)
    }
    .background(HATheme.Colors.card)
    .clipShape(RoundedRectangle(cornerRadius: 30, style: .continuous))
    .shadow(color: HATheme.Colors.shadow, radius: 20, x: 0, y: -4)
  }

  private func mapCard(for adventure: AdventureCard) -> some View {
    VStack(alignment: .leading, spacing: 0) {
      ZStack(alignment: .topLeading) {
        HAImageCarousel(
          imageNames: MockFixtures.imageNamesByAdventureID[adventure.id] ?? ["hero-mountain"],
          aspectRatio: 16 / 9,
          cornerRadius: 16,
          dotsInside: true
        )

        if let category = adventure.categorySlug {
          Text(category.displayTitle)
            .font(.system(size: 11, weight: .medium))
            .foregroundStyle(HATheme.Colors.foreground)
            .padding(.horizontal, 9)
            .padding(.vertical, 5)
            .background(.white.opacity(0.92))
            .clipShape(Capsule(style: .continuous))
            .padding(10)
        }
      }

      VStack(alignment: .leading, spacing: 10) {
        Text(adventure.title)
          .font(.system(size: 15, weight: .semibold))
          .foregroundStyle(HATheme.Colors.foreground)
          .lineLimit(1)

        HStack {
          Label("\(distanceText(for: adventure))", systemImage: "mappin")
            .font(.system(size: 12, weight: .medium))
            .foregroundStyle(HATheme.Colors.mutedForeground)

          Spacer()

          Label(String(format: "%.1f", adventure.stats.averageRating), systemImage: "star.fill")
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

  private func distanceText(for adventure: AdventureCard) -> String {
    switch adventure.id {
    case MockFixtures.bluePoolID: "2.4 mi"
    case MockFixtures.tomDickID: "8.2 mi"
    case MockFixtures.capeID: "12.6 mi"
    default: "4.1 mi"
    }
  }
}

private struct MapPinButton: View {
  let isSelected: Bool
  let action: () -> Void

  var body: some View {
    Button(action: action) {
      ZStack {
        Circle()
          .fill(isSelected ? HATheme.Colors.primary : .white)
          .frame(width: 34, height: 34)
          .shadow(color: HATheme.Colors.shadow, radius: 8, x: 0, y: 4)

        Image(systemName: "mappin")
          .font(.system(size: 16, weight: .semibold))
          .foregroundStyle(isSelected ? .white : HATheme.Colors.primary)
      }
      .overlay(alignment: .bottom) {
        if isSelected {
          Circle()
            .fill(HATheme.Colors.primary)
            .frame(width: 9, height: 9)
            .offset(y: 9)
        }
      }
    }
    .buttonStyle(.plain)
  }
}
