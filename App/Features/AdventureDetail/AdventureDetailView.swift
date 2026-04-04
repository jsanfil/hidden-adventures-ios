import SwiftUI

struct AdventureDetailView: View {
  let adventureID: UUID
  let adventureService: AdventureService
  let runtimeMode: AppRuntimeMode

  @Environment(\.dismiss) private var dismiss
  @State private var detail: AdventureDetail?

  private var imageNames: [String] {
    AdventurePresentation.imageNames(
      for: adventureID,
      runtimeMode: runtimeMode
    )
  }

  var body: some View {
    VStack(spacing: 0) {
      if let detail {
        ScrollView {
          VStack(spacing: 0) {
            hero(detail: detail)

            VStack(alignment: .leading, spacing: 20) {
              header(detail: detail)
              statRow
              authorRow(detail: detail)
              aboutSection(detail: detail)
              locationPreview(detail: detail)
              activityPreview
            }
            .padding(20)
            .padding(.bottom, 36)
            .background(HATheme.Colors.background)
            .clipShape(RoundedRectangle(cornerRadius: 30, style: .continuous))
            .offset(y: -18)
            .padding(.bottom, -18)
          }
        }

        bottomCTA(detail: detail)
      } else {
        ZStack {
          HATheme.Colors.background
            .ignoresSafeArea()

          ProgressView()
            .tint(HATheme.Colors.primary)
        }
      }
    }
    .background(HATheme.Colors.background.ignoresSafeArea())
    .toolbar(.hidden, for: .navigationBar)
    .task {
      guard detail == nil else { return }
      detail = try? await adventureService.getAdventure(id: adventureID).item
    }
  }

  private func hero(detail: AdventureDetail) -> some View {
    ZStack(alignment: .top) {
      HAMediaCarouselOrPlaceholder(
        imageNames: imageNames,
        aspectRatio: nil,
        cornerRadius: 0,
        dotsInside: true,
        title: detail.title
      )
      .frame(height: 304)
      .overlay {
        LinearGradient(
          colors: [.black.opacity(0.30), .clear, .clear],
          startPoint: .top,
          endPoint: .bottom
        )
      }

      HStack {
        Button(action: { dismiss() }) {
          CircleIconNavigationButton(systemImage: "chevron.left")
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("detail.back")

        Spacer()

        HStack(spacing: 10) {
          Button(action: {}) {
            CircleIconNavigationButton(systemImage: "square.and.arrow.up")
          }
          .buttonStyle(.plain)

          Button(action: {}) {
            CircleFilledNavigationButton(systemImage: "bookmark.fill")
          }
          .buttonStyle(.plain)
        }
      }
      .padding(.horizontal, 20)
      .padding(.top, 14)
    }
  }

  private func header(detail: AdventureDetail) -> some View {
    VStack(alignment: .leading, spacing: 14) {
      HStack {
        if let categoryTitle = detail.categoryLabel ?? detail.categorySlug?.displayTitle {
          Text(categoryTitle)
            .font(.system(size: 12, weight: .medium))
            .foregroundStyle(HATheme.Colors.foreground)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(HATheme.Colors.secondary)
            .clipShape(Capsule(style: .continuous))
            .accessibilityIdentifier("detail.category")
        }

        Spacer()

        HStack(spacing: 4) {
          Image(systemName: "star.fill")
          Text(String(format: "%.1f", detail.stats.averageRating))
          Text("(\(detail.stats.ratingCount))")
            .foregroundStyle(HATheme.Colors.mutedForeground)
        }
        .font(.system(size: 14, weight: .semibold))
        .foregroundStyle(.orange)
        .accessibilityIdentifier("detail.ratingSummary")
      }

      VStack(alignment: .leading, spacing: 8) {
        Text(detail.title)
          .font(.system(size: 28, weight: .semibold))
          .foregroundStyle(HATheme.Colors.foreground)
          .accessibilityIdentifier("detail.title")

        Label(detail.placeLabel ?? "Hidden location", systemImage: "mappin.and.ellipse")
          .font(.system(size: 15, weight: .medium))
          .foregroundStyle(HATheme.Colors.mutedForeground)
          .accessibilityIdentifier("detail.location")
      }
    }
  }

  private var statRow: some View {
    HStack(spacing: 18) {
      DetailStatItem(title: "Duration", value: "2-3 hrs", systemImage: "clock")
      DetailStatItem(title: "Difficulty", value: "Moderate", systemImage: "chart.line.uptrend.xyaxis")
      DetailStatItem(title: "Distance", value: "4.2 mi", systemImage: "location.north.line")
    }
    .padding(.vertical, 14)
    .overlay(alignment: .top) { Divider().overlay(HATheme.Colors.border) }
    .overlay(alignment: .bottom) { Divider().overlay(HATheme.Colors.border) }
  }

  private func authorRow(detail: AdventureDetail) -> some View {
    HStack(spacing: 12) {
      HAAvatarView(
        initials: authorInitials(detail.author),
        size: 42,
        background: HATheme.Colors.primary.opacity(0.15),
        foreground: HATheme.Colors.primary
      )

      VStack(alignment: .leading, spacing: 2) {
        Text("Shared by \(detail.author.displayName ?? detail.author.handle)")
          .font(.system(size: 15, weight: .medium))
          .foregroundStyle(HATheme.Colors.foreground)

        Text("Local Explorer · 48 adventures")
          .font(.system(size: 13, weight: .regular))
          .foregroundStyle(HATheme.Colors.mutedForeground)
      }

      Spacer()

      Button("Follow", action: {})
        .font(.system(size: 13, weight: .semibold))
        .foregroundStyle(HATheme.Colors.foreground)
        .padding(.horizontal, 14)
        .padding(.vertical, 7)
        .overlay {
          Capsule(style: .continuous)
            .stroke(HATheme.Colors.border, lineWidth: 1)
        }
        .buttonStyle(.plain)
    }
  }

  private func authorInitials(_ author: AdventureAuthor) -> String {
    let source = author.displayName ?? author.handle
    let letters = source
      .split(separator: " ")
      .prefix(2)
      .compactMap(\.first)
      .map { String($0).uppercased() }
      .joined()

    return letters.isEmpty ? "HA" : letters
  }

  private func aboutSection(detail: AdventureDetail) -> some View {
    VStack(alignment: .leading, spacing: 10) {
      Text("About this place")
        .font(HATheme.Typography.sectionTitle)
        .foregroundStyle(HATheme.Colors.foreground)
        .accessibilityIdentifier("detail.aboutTitle")

      Text(detail.body ?? detail.summary ?? "No description yet.")
        .font(HATheme.Typography.body)
        .foregroundStyle(HATheme.Colors.mutedForeground)
        .lineSpacing(4)
        .lineLimit(4)
        .accessibilityIdentifier("detail.aboutBody")

      Button("Read more", action: {})
        .font(.system(size: 14, weight: .semibold))
        .foregroundStyle(HATheme.Colors.primary)
        .buttonStyle(.plain)
        .accessibilityIdentifier("detail.readMore")
    }
  }

  private func locationPreview(detail: AdventureDetail) -> some View {
    VStack(alignment: .leading, spacing: 12) {
      HStack {
        Text("Location")
          .font(HATheme.Typography.sectionTitle)
          .foregroundStyle(HATheme.Colors.foreground)
          .accessibilityIdentifier("detail.locationSectionTitle")

        Spacer()

        Button(action: {}) {
          HStack(spacing: 4) {
            Text("Get Directions")
            Image(systemName: "chevron.right")
          }
          .font(.system(size: 14, weight: .semibold))
          .foregroundStyle(HATheme.Colors.primary)
        }
        .buttonStyle(.plain)
      }

      ZStack {
        LinearGradient(
          colors: [HATheme.Colors.mapForest, HATheme.Colors.mapBackground],
          startPoint: .topLeading,
          endPoint: .bottomTrailing
        )

        Path { path in
          path.move(to: CGPoint(x: 0, y: 72))
          path.addCurve(
            to: CGPoint(x: 320, y: 56),
            control1: CGPoint(x: 84, y: 44),
            control2: CGPoint(x: 220, y: 86)
          )
        }
        .stroke(.white.opacity(0.75), style: StrokeStyle(lineWidth: 4, lineCap: .round))

        Ellipse()
          .fill(HATheme.Colors.accent.opacity(0.72))
          .frame(width: 76, height: 44)

        ZStack {
          Circle()
            .fill(HATheme.Colors.primary)
            .frame(width: 34, height: 34)
          Image(systemName: "mappin")
            .foregroundStyle(.white)
            .font(.system(size: 15, weight: .semibold))
        }
      }
      .frame(height: 150)
      .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
    }
  }

  private var activityPreview: some View {
    VStack(alignment: .leading, spacing: 14) {
      HStack {
        Text("Recent Activity")
          .font(HATheme.Typography.sectionTitle)
          .foregroundStyle(HATheme.Colors.foreground)

        Spacer()

        Button("See all", action: {})
          .font(.system(size: 14, weight: .semibold))
          .foregroundStyle(HATheme.Colors.primary)
          .buttonStyle(.plain)
      }

      VStack(spacing: 12) {
        ActivityCard(
          initials: "MJ",
          headline: "Mike J. visited this spot",
          message: "Absolutely magical! Got there early and had it all to ourselves.",
          metrics: "24 likes · 3 comments · 2 days ago",
          accent: HATheme.Colors.accent
        )

        ActivityCard(
          initials: "AL",
          headline: "Amy L. saved this adventure",
          message: nil,
          metrics: "8 likes · 5 days ago",
          accent: HATheme.Colors.primary.opacity(0.2)
        )
      }
    }
  }

  private func bottomCTA(detail: AdventureDetail) -> some View {
    VStack(spacing: 6) {
      Divider()
        .overlay(HATheme.Colors.border)

      HStack(spacing: 14) {
        Text("\(detail.stats.favoriteCount.formatted()) people saved this")
          .font(.system(size: 12, weight: .regular))
          .foregroundStyle(HATheme.Colors.mutedForeground)
          .frame(maxWidth: .infinity, alignment: .leading)
          .accessibilityIdentifier("detail.savedCount")

        Button(action: {}) {
          HStack(spacing: 8) {
            Image(systemName: "location.north.fill")
              .font(.system(size: 16, weight: .semibold))
            Text("Start Adventure")
              .font(.system(size: 17, weight: .semibold))
          }
          .foregroundStyle(.white)
          .frame(width: 184, height: 48)
          .background(HATheme.Colors.primary)
          .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("detail.startCTA")
      }
      .padding(.horizontal, 20)
      .padding(.top, 8)
      .padding(.bottom, 10)
    }
    .background(.white.opacity(0.95))
  }
}

private struct DetailStatItem: View {
  let title: String
  let value: String
  let systemImage: String

  var body: some View {
    HStack(spacing: 10) {
      ZStack {
        Circle()
          .fill(HATheme.Colors.secondary)
          .frame(width: 38, height: 38)
        Image(systemName: systemImage)
          .font(.system(size: 15, weight: .semibold))
          .foregroundStyle(HATheme.Colors.mutedForeground)
      }

      VStack(alignment: .leading, spacing: 2) {
        Text(title)
          .font(.system(size: 11, weight: .regular))
          .foregroundStyle(HATheme.Colors.mutedForeground)
        Text(value)
          .font(.system(size: 13, weight: .semibold))
          .foregroundStyle(HATheme.Colors.foreground)
      }
    }
  }
}

private struct ActivityCard: View {
  let initials: String
  let headline: String
  let message: String?
  let metrics: String
  let accent: Color

  var body: some View {
    HStack(alignment: .top, spacing: 12) {
      HAAvatarView(
        initials: initials,
        size: 38,
        background: accent.opacity(0.9),
        foreground: .white
      )

      VStack(alignment: .leading, spacing: 6) {
        Text(headline)
          .font(.system(size: 14, weight: .medium))
          .foregroundStyle(HATheme.Colors.foreground)

        if let message {
          Text(message)
            .font(.system(size: 13, weight: .regular))
            .foregroundStyle(HATheme.Colors.mutedForeground)
            .lineSpacing(2)
        }

        Text(metrics)
          .font(.system(size: 12, weight: .regular))
          .foregroundStyle(HATheme.Colors.mutedForeground)
      }

      Spacer()
    }
    .padding(14)
    .background(HATheme.Colors.secondary.opacity(0.55))
    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
  }
}

private struct CircleIconNavigationButton: View {
  let systemImage: String

  var body: some View {
    Image(systemName: systemImage)
      .font(.system(size: 16, weight: .semibold))
      .foregroundStyle(HATheme.Colors.foreground)
      .frame(width: 40, height: 40)
      .background(.white.opacity(0.92))
      .clipShape(Circle())
  }
}

private struct CircleFilledNavigationButton: View {
  let systemImage: String

  var body: some View {
    Image(systemName: systemImage)
      .font(.system(size: 16, weight: .semibold))
      .foregroundStyle(.white)
      .frame(width: 40, height: 40)
      .background(HATheme.Colors.primary)
      .clipShape(Circle())
  }
}

struct AdventureDetailView_Previews: PreviewProvider {
  static var previews: some View {
    AdventureDetailView(
      adventureID: MockFixtures.eagleID,
      adventureService: FixtureAdventureService(),
      runtimeMode: .fixturePreview
    )
  }
}
