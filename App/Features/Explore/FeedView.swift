import SwiftUI

struct FeedView: View {
  let items: [AdventureCard]
  let adventureService: AdventureService
  let runtimeMode: AppRuntimeMode
  let onOpenDetail: (String) -> Void

  private func accessibilityAdventureID(_ id: String) -> String {
    runtimeMode == .fixturePreview ? MockFixtures.uiTestAdventureID(for: id) : id
  }

  var body: some View {
    ScrollView {
      LazyVStack(spacing: 16) {
        ForEach(items) { adventure in
          Button {
            onOpenDetail(adventure.id)
          } label: {
            FeedCardView(
              adventure: adventure,
              adventureService: adventureService,
              runtimeMode: runtimeMode
            )
          }
          .buttonStyle(.plain)
          .accessibilityIdentifier("feed.card.\(accessibilityAdventureID(adventure.id))")
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
      adventureService: FixtureAdventureService(),
      runtimeMode: .fixturePreview,
      onOpenDetail: { _ in }
    )
  }
}

private struct FeedCardView: View {
  let adventure: AdventureCard
  let adventureService: AdventureService
  let runtimeMode: AppRuntimeMode

  private var accessibilityAdventureID: String {
    runtimeMode == .fixturePreview ? MockFixtures.uiTestAdventureID(for: adventure.id) : adventure.id
  }

  private var mediaSource: HAMediaSource {
    if runtimeMode == .fixturePreview {
      return .fixture(
        AdventurePresentation.imageNames(
          for: adventure.id,
          runtimeMode: runtimeMode
        )
      )
    }

    return .remote(
      adventure.primaryMedia.map(\.id).map { [$0] } ?? [],
      adventureService
    )
  }

  var body: some View {
    ZStack {
      ZStack(alignment: .bottomLeading) {
        HAMediaCarouselOrPlaceholder(
          source: mediaSource,
          aspectRatio: 4 / 3,
          cornerRadius: 16,
          dotsInside: true,
          title: adventure.title
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
          Text(adventure.title)
            .font(.system(size: 16, weight: .semibold))
            .foregroundStyle(.white)
            .multilineTextAlignment(.leading)
            .lineSpacing(1)
            .accessibilityIdentifier("feed.card.title.\(accessibilityAdventureID)")

          HStack(alignment: .center) {
            HStack(spacing: 4) {
              Image(systemName: "mappin")
                .font(.system(size: 12, weight: .medium))
              Text(adventure.placeLabel ?? "Hidden location")
                .lineLimit(1)
            }
            .font(.system(size: 13, weight: .medium))
            .foregroundStyle(.white.opacity(0.82))
            .accessibilityIdentifier("feed.card.location.\(accessibilityAdventureID)")

            Spacer(minLength: 8)

            HStack(spacing: 14) {
              HStack(spacing: 4) {
                Image(systemName: "star.fill")
                Text(String(format: "%.1f", adventure.stats.averageRating))
              }
              HStack(spacing: 4) {
                Image(systemName: "heart")
                Text(adventure.stats.favoriteCount.formatted())
              }
            }
            .font(.system(size: 13, weight: .medium))
            .foregroundStyle(.white.opacity(0.86))
          }
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 28)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
      }

      VStack {
        HStack {
          if let categoryLabel = adventure.categoryLabel ?? adventure.categorySlug?.displayTitle {
            Text(categoryLabel)
              .font(.system(size: 11, weight: .medium))
              .foregroundStyle(HATheme.Colors.foreground)
              .padding(.horizontal, 10)
              .padding(.vertical, 4)
              .background(.white.opacity(0.92))
              .clipShape(Capsule(style: .continuous))
              .accessibilityIdentifier("feed.card.category.\(accessibilityAdventureID)")
          }

          Spacer()

          Button(action: {}) {
            Image(systemName: "bookmark")
              .font(.system(size: 14, weight: .medium))
              .foregroundStyle(HATheme.Colors.foreground)
              .frame(width: 32, height: 32)
              .background(.white.opacity(0.92))
              .clipShape(Circle())
          }
          .buttonStyle(.plain)
        }
        Spacer()
      }
      .padding(12)
    }
  }
}
