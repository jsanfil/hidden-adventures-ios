import SwiftUI

struct FeedView: View {
  let items: [AdventureCard]
  let scope: FeedScope?
  let adventureService: AdventureService
  let runtimeMode: AppRuntimeMode
  let onOpenDetail: (String) -> Void
  var body: some View {
    ScrollView {
      LazyVStack(spacing: 16) {
        ForEach(items) { adventure in
          FeedCardView(
            adventure: adventure,
            scope: scope,
            adventureService: adventureService,
            runtimeMode: runtimeMode,
            onOpenDetail: onOpenDetail
          )
        }
      }
      .padding(.horizontal, 20)
      .padding(.bottom, 24)
    }
    .accessibilityIdentifier("feed.scroll")
  }
}

struct FeedView_Previews: PreviewProvider {
  static var previews: some View {
    FeedView(
      items: MockFixtures.feedItems,
      scope: nil,
      adventureService: FixtureAdventureService(),
      runtimeMode: .fixturePreview,
      onOpenDetail: { _ in }
    )
  }
}

private struct FeedCardView: View {
  let adventure: AdventureCard
  let scope: FeedScope?
  let adventureService: AdventureService
  let runtimeMode: AppRuntimeMode
  let onOpenDetail: (String) -> Void

  @State private var visibleAdventure: AdventureCard
  @State private var isFavoriteMutationInFlight = false

  init(
    adventure: AdventureCard,
    scope: FeedScope?,
    adventureService: AdventureService,
    runtimeMode: AppRuntimeMode,
    onOpenDetail: @escaping (String) -> Void
  ) {
    self.adventure = adventure
    self.scope = scope
    self.adventureService = adventureService
    self.runtimeMode = runtimeMode
    self.onOpenDetail = onOpenDetail
    _visibleAdventure = State(initialValue: adventure)
  }

  private var accessibilityAdventureID: String {
    runtimeMode == .fixturePreview ? MockFixtures.uiTestAdventureID(for: visibleAdventure.id) : visibleAdventure.id
  }

  private var mediaSource: HAMediaSource {
    if runtimeMode == .fixturePreview {
      return .fixture(
        AdventurePresentation.imageNames(
          for: visibleAdventure.id,
          runtimeMode: runtimeMode
        )
      )
    }

    return .remote(
      visibleAdventure.primaryMedia.map(\.id).map { [$0] } ?? [],
      adventureService
    )
  }

  var body: some View {
    ZStack {
      Button {
        onOpenDetail(visibleAdventure.id)
      } label: {
        cardContent
      }
      .buttonStyle(.plain)
      .accessibilityIdentifier("feed.card.\(accessibilityAdventureID)")

      VStack {
        HStack {
          categoryBadge

          Spacer()

          Button(action: toggleFavorite) {
            Image(systemName: visibleAdventure.isFavorited ? "bookmark.fill" : "bookmark")
              .font(.system(size: 14, weight: .medium))
              .foregroundStyle(visibleAdventure.isFavorited ? .white : HATheme.Colors.foreground)
              .frame(width: 32, height: 32)
              .background(visibleAdventure.isFavorited ? HATheme.Colors.primary : .white.opacity(0.92))
              .clipShape(Circle())
          }
          .buttonStyle(.plain)
          .disabled(isFavoriteMutationInFlight)
          .accessibilityLabel(visibleAdventure.isFavorited ? "Remove favorite" : "Add favorite")
          .accessibilityValue(visibleAdventure.isFavorited ? "favorited" : "not favorited")
          .accessibilityIdentifier("feed.card.favorite.\(accessibilityAdventureID)")
        }
        Spacer()
      }
      .padding(12)
    }
    .onChange(of: adventure) { _, newValue in
      visibleAdventure = newValue
    }
    .onReceive(NotificationCenter.default.publisher(for: FavoriteStateChange.notificationName)) { notification in
      guard let change = FavoriteStateChange(notification: notification) else { return }
      guard change.adventureID == visibleAdventure.id else { return }
      visibleAdventure = visibleAdventure.applyingFavoriteState(change.isFavorited)
    }
  }

  private var cardContent: some View {
    ZStack(alignment: .bottomLeading) {
      HAMediaCarouselOrPlaceholder(
        source: mediaSource,
        aspectRatio: 4 / 3,
        cornerRadius: 16,
        dotsInside: true,
        title: visibleAdventure.title
      )
      .overlay {
        RoundedRectangle(cornerRadius: 16, style: .continuous)
          .fill(
            LinearGradient(
              colors: [.clear, .black.opacity(0.10), .black.opacity(0.65)],
              startPoint: .top,
              endPoint: .bottom
            )
          )
      }
      .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))

      VStack(alignment: .leading, spacing: 8) {
        Text(visibleAdventure.title)
          .font(.system(size: 16, weight: .semibold))
          .foregroundStyle(.white)
          .multilineTextAlignment(.leading)
          .lineSpacing(1)
          .accessibilityIdentifier("feed.card.title.\(accessibilityAdventureID)")

        HStack(alignment: .center) {
          HStack(spacing: 4) {
            Image(systemName: "mappin")
              .font(.system(size: 12, weight: .medium))
            Text(visibleAdventure.placeLabel ?? "Hidden location")
              .lineLimit(1)
          }
          .font(.system(size: 13, weight: .medium))
          .foregroundStyle(.white.opacity(0.82))
          .accessibilityIdentifier("feed.card.location.\(accessibilityAdventureID)")

          Spacer(minLength: 8)

          statsRow
        }
      }
      .padding(.horizontal, 16)
      .padding(.bottom, 28)
      .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
    }
  }

  @ViewBuilder
  private var categoryBadge: some View {
    if let categoryLabel = visibleAdventure.categoryLabel ?? visibleAdventure.categorySlug?.displayTitle {
      Text(categoryLabel)
        .font(.system(size: 11, weight: .medium))
        .foregroundStyle(HATheme.Colors.foreground)
        .padding(.horizontal, 10)
        .padding(.vertical, 4)
        .background(.white.opacity(0.92))
        .clipShape(Capsule(style: .continuous))
        .accessibilityIdentifier("feed.card.category.\(accessibilityAdventureID)")
    }
  }

  private var statsRow: some View {
    HStack(spacing: 12) {
      if scope != nil, let distanceMiles = visibleAdventure.distanceMiles {
        HStack(spacing: 4) {
          Image(systemName: "location.north.line")
          Text(String(format: "%.1f mi", distanceMiles))
        }
      }

      HStack(spacing: 4) {
        Image(systemName: "star.fill")
        Text(String(format: "%.1f", visibleAdventure.stats.averageRating))
      }
      HStack(spacing: 4) {
        Image(systemName: "heart")
        Text(visibleAdventure.stats.favoriteCount.formatted())
      }
    }
    .font(.system(size: 13, weight: .medium))
    .foregroundStyle(.white.opacity(0.86))
  }

  private func toggleFavorite() {
    let targetState = !visibleAdventure.isFavorited
    let previousState = visibleAdventure
    visibleAdventure = visibleAdventure.applyingFavoriteState(targetState)
    isFavoriteMutationInFlight = true

    Task {
      do {
        if targetState {
          try await adventureService.favoriteAdventure(id: visibleAdventure.id)
        } else {
          try await adventureService.unfavoriteAdventure(id: visibleAdventure.id)
        }
      } catch {
        visibleAdventure = previousState
      }

      isFavoriteMutationInFlight = false
    }
  }
}
