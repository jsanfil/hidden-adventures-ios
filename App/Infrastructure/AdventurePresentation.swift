import SwiftUI

enum AdventurePresentation {
  static func imageNames(
    for adventureID: UUID,
    runtimeMode: AppRuntimeMode
  ) -> [String] {
    guard runtimeMode == .fixturePreview else {
      return []
    }

    return MockFixtures.imageNamesByAdventureID[adventureID] ?? ["hero-mountain"]
  }

  static func mapCardItems(
    from items: [AdventureCard],
    runtimeMode: AppRuntimeMode
  ) -> [MapCardPresentation] {
    if runtimeMode == .fixturePreview {
      return [
        MapCardPresentation(
          id: "blue-pool",
          destinationID: MockFixtures.bluePoolID,
          title: "Blue Pool",
          rating: 4.8,
          category: "Swimming",
          imageNames: ["swimming-hole", "hidden-canyon", "hero-mountain"]
        ),
        MapCardPresentation(
          id: "opal-creek-trail",
          destinationID: MockFixtures.eagleID,
          title: "Opal Creek Trail",
          rating: 4.9,
          category: "Trail",
          imageNames: ["trail-forest", "coastal-path"]
        ),
        MapCardPresentation(
          id: "tom-dick-harry",
          destinationID: MockFixtures.tomDickID,
          title: "Tom Dick & Harry",
          rating: 4.7,
          category: "Viewpoint",
          imageNames: ["scenic-overlook"]
        )
      ]
    }

    return Array(items.prefix(3)).map { item in
      MapCardPresentation(
        id: item.title.mapIdentifier,
        destinationID: item.id,
        title: item.title,
        rating: item.stats.averageRating,
        category: item.categorySlug?.displayTitle ?? "Adventure",
        imageNames: []
      )
    }
  }
}

struct HAMediaCarouselOrPlaceholder: View {
  let imageNames: [String]
  let aspectRatio: CGFloat?
  let cornerRadius: CGFloat
  let dotsInside: Bool
  let title: String

  var body: some View {
    if imageNames.isEmpty {
      placeholder
    } else {
      HAImageCarousel(
        imageNames: imageNames,
        aspectRatio: aspectRatio,
        cornerRadius: cornerRadius,
        dotsInside: dotsInside
      )
    }
  }

  private var placeholder: some View {
    let content = ZStack {
      LinearGradient(
        colors: [HATheme.Colors.mapForest, HATheme.Colors.mapBackground, HATheme.Colors.secondary],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
      )

      VStack(spacing: 12) {
        Image(systemName: "photo.on.rectangle.angled")
          .font(.system(size: 28, weight: .medium))
          .foregroundStyle(.white.opacity(0.92))

        Text("Media stays in explicit preview fallback until a locked delivery route lands.")
          .font(.system(size: 12, weight: .medium))
          .foregroundStyle(.white.opacity(0.84))
          .multilineTextAlignment(.center)
          .lineLimit(3)
          .padding(.horizontal, 16)

        Text(title)
          .font(.system(size: 15, weight: .semibold))
          .foregroundStyle(.white)
          .multilineTextAlignment(.center)
          .lineLimit(2)
          .padding(.horizontal, 16)
      }
    }
    .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))

    return Group {
      if let aspectRatio {
        content
          .aspectRatio(aspectRatio, contentMode: .fit)
      } else {
        content
      }
    }
  }
}

struct MapCardPresentation: Identifiable {
  let id: String
  let destinationID: UUID
  let title: String
  let rating: Double
  let category: String
  let imageNames: [String]
}

struct HAMediaCarouselOrPlaceholder_Previews: PreviewProvider {
  static var previews: some View {
    VStack(spacing: 24) {
      HAMediaCarouselOrPlaceholder(
        imageNames: ["hero-mountain", "scenic-overlook", "trail-forest"],
        aspectRatio: 4 / 3,
        cornerRadius: 18,
        dotsInside: true,
        title: "Eagle Creek Trail"
      )

      HAMediaCarouselOrPlaceholder(
        imageNames: [],
        aspectRatio: 4 / 3,
        cornerRadius: 18,
        dotsInside: false,
        title: "Preview-only fallback"
      )
    }
    .padding(24)
    .background(HATheme.Colors.background)
  }
}

private extension String {
  var mapIdentifier: String {
    lowercased()
      .replacingOccurrences(of: "[^a-z0-9]+", with: "-", options: .regularExpression)
      .trimmingCharacters(in: CharacterSet(charactersIn: "-"))
  }
}
