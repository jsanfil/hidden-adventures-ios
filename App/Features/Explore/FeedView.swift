import SwiftUI

struct FeedView: View {
  let items: [AdventureCard]
  let onOpenDetail: (UUID) -> Void

  var body: some View {
    ScrollView {
      LazyVStack(spacing: 16) {
        ForEach(items) { adventure in
          Button {
            onOpenDetail(adventure.id)
          } label: {
            FeedCardView(adventure: adventure)
          }
          .buttonStyle(.plain)
          .accessibilityIdentifier("feed.card.\(adventure.id.uuidString)")
        }
      }
      .padding(.horizontal, 20)
      .padding(.bottom, 24)
    }
  }
}

private struct FeedCardView: View {
  let adventure: AdventureCard

  private var images: [String] {
    MockFixtures.imageNamesByAdventureID[adventure.id] ?? ["hero-mountain"]
  }

  var body: some View {
    ZStack(alignment: .topTrailing) {
      ZStack(alignment: .bottomLeading) {
        HAImageCarousel(
          imageNames: images,
          aspectRatio: 4 / 3,
          cornerRadius: 16,
          dotsInside: true
        )
        .overlay {
          RoundedRectangle(cornerRadius: 16, style: .continuous)
            .fill(
              LinearGradient(
                colors: [.clear, .black.opacity(0.18), .black.opacity(0.68)],
                startPoint: .top,
                endPoint: .bottom
              )
            )
        }

        VStack(alignment: .leading, spacing: 10) {
          if let category = adventure.categorySlug {
            Text(category.displayTitle)
              .font(.system(size: 11, weight: .medium))
              .foregroundStyle(HATheme.Colors.foreground)
              .padding(.horizontal, 10)
              .padding(.vertical, 4)
              .background(.white.opacity(0.92))
              .clipShape(Capsule(style: .continuous))
          }

          Spacer()

          VStack(alignment: .leading, spacing: 8) {
            Text(adventure.title)
              .font(.system(size: 16, weight: .semibold))
              .foregroundStyle(.white)
              .multilineTextAlignment(.leading)

            HStack(alignment: .bottom) {
              Label(
                adventure.author.homeCity.map { "\($0), \(adventure.author.homeRegion ?? "")" } ?? "Hidden location",
                systemImage: "mappin"
              )
              .font(.system(size: 13, weight: .medium))
              .foregroundStyle(.white.opacity(0.8))

              Spacer()

              HStack(spacing: 12) {
                Label(String(format: "%.1f", adventure.stats.averageRating), systemImage: "star.fill")
                Label("\(adventure.stats.favoriteCount.formatted())", systemImage: "heart")
              }
              .font(.system(size: 13, weight: .medium))
              .foregroundStyle(.white.opacity(0.86))
            }
          }
        }
        .padding(16)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
      }

      Button(action: {}) {
        Image(systemName: "bookmark")
          .font(.system(size: 14, weight: .semibold))
          .foregroundStyle(HATheme.Colors.foreground)
          .frame(width: 32, height: 32)
          .background(.white.opacity(0.92))
          .clipShape(Circle())
      }
      .buttonStyle(.plain)
      .padding(14)
    }
  }
}
