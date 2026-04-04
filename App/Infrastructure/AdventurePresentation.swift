import SwiftUI

enum AdventurePresentation {
  static func imageNames(
    for adventureID: String,
    runtimeMode: AppRuntimeMode
  ) -> [String] {
    guard runtimeMode == .fixturePreview else {
      return []
    }

    return MockFixtures.imageNamesByAdventureID[MockFixtures.resolvedAdventureID(for: adventureID)] ?? ["hero-mountain"]
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
  let source: HAMediaSource
  let aspectRatio: CGFloat?
  let cornerRadius: CGFloat
  let dotsInside: Bool
  let title: String

  var body: some View {
    switch source {
    case .fixture(let imageNames):
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
    case .remote(let mediaIDs, let mediaLoader):
      if mediaIDs.isEmpty {
        placeholder
      } else {
        HARemoteMediaCarousel(
          mediaIDs: mediaIDs,
          mediaLoader: mediaLoader,
          aspectRatio: aspectRatio,
          cornerRadius: cornerRadius,
          dotsInside: dotsInside
        )
      }
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

        Text("Image unavailable right now.")
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

enum HAMediaSource {
  case fixture([String])
  case remote([String], any AdventureService)
}

private struct HARemoteMediaCarousel: View {
  let mediaIDs: [String]
  let mediaLoader: any AdventureService
  let aspectRatio: CGFloat?
  let cornerRadius: CGFloat
  let dotsInside: Bool

  @State private var selection = 0

  var body: some View {
    VStack(spacing: dotsInside ? 0 : 8) {
      ZStack(alignment: dotsInside ? .bottom : .center) {
        carouselContent
          .background(HATheme.Colors.muted)
          .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))

        if dotsInside && mediaIDs.count > 1 {
          HADots(count: mediaIDs.count, currentIndex: selection, activeColor: .white, inactiveColor: .white.opacity(0.5))
            .padding(.bottom, 12)
        }
      }

      if !dotsInside && mediaIDs.count > 1 {
        HADots(
          count: mediaIDs.count,
          currentIndex: selection,
          activeColor: HATheme.Colors.mutedForeground,
          inactiveColor: HATheme.Colors.mutedForeground.opacity(0.4)
        )
      }
    }
  }

  @ViewBuilder
  private var carouselContent: some View {
    let tabView = TabView(selection: $selection) {
      ForEach(Array(mediaIDs.enumerated()), id: \.offset) { index, mediaID in
        HARemoteMediaImage(
          mediaID: mediaID,
          mediaLoader: mediaLoader
        )
        .tag(index)
      }
    }
    .tabViewStyle(.page(indexDisplayMode: .never))

    if let aspectRatio {
      tabView
        .aspectRatio(aspectRatio, contentMode: .fit)
    } else {
      tabView
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
  }
}

private struct HARemoteMediaImage: View {
  let mediaID: String
  let mediaLoader: any AdventureService

  @State private var image: UIImage?
  @State private var didFail = false

  var body: some View {
    Group {
      if let image {
        Image(uiImage: image)
          .resizable()
          .scaledToFill()
          .frame(maxWidth: .infinity, maxHeight: .infinity)
          .clipped()
      } else if didFail {
        placeholder
      } else {
        ZStack {
          LinearGradient(
            colors: [HATheme.Colors.mapForest, HATheme.Colors.mapBackground],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
          )
          ProgressView()
            .tint(.white)
        }
      }
    }
    .task(id: mediaID) {
      await loadImage()
    }
  }

  private var placeholder: some View {
    ZStack {
      LinearGradient(
        colors: [HATheme.Colors.mapForest, HATheme.Colors.mapBackground, HATheme.Colors.secondary],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
      )

      Image(systemName: "photo")
        .font(.system(size: 24, weight: .medium))
        .foregroundStyle(.white.opacity(0.88))
    }
  }

  @MainActor
  private func loadImage() async {
    if image != nil {
      return
    }

    do {
      let data = try await mediaLoader.loadMediaData(id: mediaID)
      image = UIImage(data: data)
      didFail = image == nil
    } catch {
      didFail = true
    }
  }
}

struct MapCardPresentation: Identifiable {
  let id: String
  let destinationID: String
  let title: String
  let rating: Double
  let category: String
  let imageNames: [String]
}

struct HAMediaCarouselOrPlaceholder_Previews: PreviewProvider {
  static var previews: some View {
    VStack(spacing: 24) {
      HAMediaCarouselOrPlaceholder(
        source: .fixture(["hero-mountain", "scenic-overlook", "trail-forest"]),
        aspectRatio: 4 / 3,
        cornerRadius: 18,
        dotsInside: true,
        title: "Eagle Creek Trail"
      )

      HAMediaCarouselOrPlaceholder(
        source: .fixture([]),
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
