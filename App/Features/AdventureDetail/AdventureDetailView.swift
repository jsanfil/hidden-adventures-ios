import SwiftUI

struct AdventureDetailView: View {
  private enum Layout {
    static let heroHeight: CGFloat = 318
    static let sheetOverlap: CGFloat = 24
    static let sheetCornerRadius: CGFloat = 28
    static let horizontalPadding: CGFloat = 20
  }

  let adventureID: String
  let adventureService: AdventureService
  let profileService: ProfileService
  let runtimeMode: AppRuntimeMode
  let fixtureVariantOverride: AdventureDetailFixtureVariant?

  @Environment(\.dismiss) private var dismiss
  @Environment(\.openURL) private var openURL

  @State private var screenModel: AdventureDetailScreenModel?
  @State private var mediaIDs: [String] = []
  @State private var isLoading = false
  @State private var didFailToLoad = false
  @State private var isFavorited = false
  @State private var userRating = 0
  @State private var commentText = ""

  init(
    adventureID: String,
    adventureService: AdventureService,
    profileService: ProfileService,
    runtimeMode: AppRuntimeMode,
    fixtureVariantOverride: AdventureDetailFixtureVariant? = nil
  ) {
    self.adventureID = adventureID
    self.adventureService = adventureService
    self.profileService = profileService
    self.runtimeMode = runtimeMode
    self.fixtureVariantOverride = fixtureVariantOverride
  }

  private var fixtureVariant: AdventureDetailFixtureVariant {
    fixtureVariantOverride ?? AdventureDetailFixtureVariant.resolve()
  }

  private var mediaSource: HAMediaSource {
    if runtimeMode == .fixturePreview {
      let imageNames = screenModel?.heroImageNames
        ?? MockFixtures.adventureDetailScreenModel(
          for: adventureID,
          variant: fixtureVariant
        ).heroImageNames
      return .fixture(imageNames)
    }

    return .remote(mediaIDs, adventureService)
  }

  private var usesFixturePreview: Bool {
    runtimeMode == .fixturePreview
  }

  private var visibleComments: [AdventureDetailScreenModel.Comment] {
    guard let screenModel else { return [] }
    if usesFixturePreview == false {
      return screenModel.comments
    }

    if screenModel.comments.isEmpty {
      return [
        AdventureDetailScreenModel.Comment(
          id: "placeholder-comment-1",
          authorDisplayName: "alex",
          authorInitials: "AL",
          relativeTimestamp: "2 days ago",
          body: "This is a solid layout check comment. The bubble spacing feels good, and the pinned composer still leaves enough room to read the thread."
        ),
        AdventureDetailScreenModel.Comment(
          id: "placeholder-comment-2",
          authorDisplayName: "maya",
          authorInitials: "MA",
          relativeTimestamp: "1 week ago",
          body: "Second placeholder comment for visual QA. Long enough to wrap onto another line so we can judge the notched bubble shape and timestamp alignment."
        )
      ]
    }

    return screenModel.comments
  }

  var body: some View {
    ZStack(alignment: .top) {
      hero

      content
    }
    .background(HATheme.Colors.background.ignoresSafeArea())
    .overlay(alignment: .top) {
      floatingNavigation
    }
    .safeAreaInset(edge: .bottom, spacing: 0) {
      commentComposerBar
    }
    .toolbar(.hidden, for: .navigationBar)
    .task {
      guard screenModel == nil, isLoading == false else { return }
      await loadScreen()
    }
  }

  private var hero: some View {
    HAMediaCarouselOrPlaceholder(
      source: mediaSource,
      aspectRatio: nil,
      cornerRadius: 0,
      dotsInside: true,
      title: screenModel?.title ?? "Adventure"
    )
    .frame(height: Layout.heroHeight)
    .overlay {
      LinearGradient(
        colors: [.black.opacity(0.28), .clear, .clear],
        startPoint: .top,
        endPoint: .bottom
      )
    }
    .accessibilityIdentifier("detail.carousel")
  }

  @ViewBuilder
  private var content: some View {
    if let screenModel {
      ScrollView(showsIndicators: false) {
        VStack(spacing: 0) {
          Color.clear
            .frame(height: Layout.heroHeight - Layout.sheetOverlap)

          VStack(alignment: .leading, spacing: 0) {
            headerSection(screenModel)
            authorSection(screenModel)
            aboutSection(screenModel)
            locationSection(screenModel)
            ratingSection
            commentsSection(screenModel)
          }
          .padding(.horizontal, Layout.horizontalPadding)
          .padding(.top, 18)
          .padding(.bottom, 20)
          .background(HATheme.Colors.background)
          .clipShape(
            UnevenRoundedRectangle(
              topLeadingRadius: Layout.sheetCornerRadius,
              topTrailingRadius: Layout.sheetCornerRadius
            )
          )
        }
      }
    } else if didFailToLoad {
      failureState
    } else {
      loadingState
    }
  }

  private var floatingNavigation: some View {
    HStack {
      Button(action: { dismiss() }) {
        NavigationCircleButton(systemImage: "chevron.left")
      }
      .buttonStyle(.plain)
      .accessibilityIdentifier("detail.back")

      Spacer()

      HStack(spacing: 10) {
        Button(action: {}) {
          NavigationCircleButton(systemImage: "square.and.arrow.up")
        }
        .buttonStyle(.plain)
        .disabled(usesFixturePreview == false)
        .opacity(usesFixturePreview ? 1 : 0.7)
        .accessibilityIdentifier("detail.share")

        Button(action: { isFavorited.toggle() }) {
          FavoriteNavigationButton(isFavorited: isFavorited)
        }
        .buttonStyle(.plain)
        .disabled(usesFixturePreview == false)
        .opacity(usesFixturePreview ? 1 : 0.7)
        .accessibilityIdentifier("detail.favorite")
      }
    }
    .padding(.horizontal, 16)
    .padding(.top, 14)
  }

  private func headerSection(_ screenModel: AdventureDetailScreenModel) -> some View {
    VStack(alignment: .leading, spacing: 14) {
      HStack(alignment: .top, spacing: 12) {
        if let categoryLabel = screenModel.categoryLabel {
          Text(categoryLabel)
            .font(.system(size: 12, weight: .medium))
            .foregroundStyle(HATheme.Colors.mutedForeground)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(HATheme.Colors.secondary)
            .clipShape(Capsule(style: .continuous))
            .fixedSize(horizontal: true, vertical: false)
            .accessibilityIdentifier("detail.category")
        }

        Spacer(minLength: 0)

        HStack(spacing: 4) {
          Image(systemName: "star.fill")
          Text(String(format: "%.1f", screenModel.averageRating))
          Text("(\(screenModel.ratingCount))")
            .foregroundStyle(HATheme.Colors.mutedForeground)
        }
        .font(.system(size: 14, weight: .semibold))
        .foregroundStyle(Color(red: 0.88, green: 0.62, blue: 0.12))
        .fixedSize(horizontal: true, vertical: false)
        .frame(maxWidth: .infinity, alignment: .trailing)
        .accessibilityIdentifier("detail.ratingSummary")
      }
      .frame(maxWidth: .infinity)

      VStack(alignment: .leading, spacing: 8) {
        Text(screenModel.title)
          .font(.system(size: 25, weight: .semibold))
          .foregroundStyle(HATheme.Colors.foreground)
          .accessibilityIdentifier("detail.title")

        Label(screenModel.placeLabel, systemImage: "mappin.and.ellipse")
          .font(.system(size: 15, weight: .medium))
          .foregroundStyle(HATheme.Colors.mutedForeground)
          .accessibilityIdentifier("detail.location")
      }
    }
  }

  private func authorSection(_ screenModel: AdventureDetailScreenModel) -> some View {
    HStack(spacing: 12) {
      AuthorAvatarView(
        initials: screenModel.author.initials,
        mediaID: screenModel.author.avatarMediaID,
        mediaLoader: adventureService
      )

      VStack(alignment: .leading, spacing: 2) {
        Text("Shared by \(screenModel.author.displayName)")
          .font(.system(size: 15, weight: .medium))
          .foregroundStyle(HATheme.Colors.foreground)

        Text(screenModel.author.subtitle)
          .font(.system(size: 13, weight: .regular))
          .foregroundStyle(HATheme.Colors.mutedForeground)
      }

      Spacer(minLength: 12)

      Button("Follow", action: {})
        .font(.system(size: 13, weight: .semibold))
        .foregroundStyle(HATheme.Colors.foreground)
        .padding(.horizontal, 16)
        .padding(.vertical, 9)
        .background(.white.opacity(0.9))
        .overlay {
          Capsule(style: .continuous)
            .stroke(HATheme.Colors.border, lineWidth: 1)
        }
        .clipShape(Capsule(style: .continuous))
        .buttonStyle(.plain)
        .disabled(usesFixturePreview == false)
        .opacity(usesFixturePreview ? 1 : 0.7)
        .accessibilityIdentifier("detail.follow")
    }
    .padding(.vertical, 18)
    .overlay(alignment: .top) {
      Divider()
        .overlay(HATheme.Colors.border)
    }
    .overlay(alignment: .bottom) {
      Divider()
        .overlay(HATheme.Colors.border)
    }
    .accessibilityIdentifier("detail.author")
  }

  private func aboutSection(_ screenModel: AdventureDetailScreenModel) -> some View {
    VStack(alignment: .leading, spacing: 14) {
      Text("About this place")
        .font(HATheme.Typography.sectionTitle)
        .foregroundStyle(HATheme.Colors.foreground)

      VStack(alignment: .leading, spacing: 10) {
        ForEach(Array(screenModel.aboutLines.enumerated()), id: \.offset) { index, line in
          Text(line)
            .font(.system(size: 15, weight: .regular))
            .foregroundStyle(HATheme.Colors.mutedForeground)
            .lineSpacing(4)
            .accessibilityIdentifier(index == 0 ? "detail.aboutBody" : "detail.aboutBody.\(index)")
        }
      }
    }
    .padding(.top, 20)
  }

  private func locationSection(_ screenModel: AdventureDetailScreenModel) -> some View {
    VStack(alignment: .leading, spacing: 12) {
      HStack {
        Text("Location")
          .font(HATheme.Typography.sectionTitle)
          .foregroundStyle(HATheme.Colors.foreground)
          .accessibilityIdentifier("detail.locationSectionTitle")

        Spacer()

        Button(action: openDirections) {
          HStack(spacing: 4) {
            Text("Get Directions")
            Image(systemName: "chevron.right")
          }
          .font(.system(size: 14, weight: .semibold))
          .foregroundStyle(HATheme.Colors.primary)
        }
        .buttonStyle(.plain)
        .disabled(screenModel.directions == nil)
        .opacity(screenModel.directions == nil ? 0.55 : 1)
        .accessibilityIdentifier("detail.directions")
      }

      StylizedMapCard()
    }
    .padding(.top, 28)
  }

  private var ratingSection: some View {
    VStack(alignment: .leading, spacing: 14) {
      Text("Rate this adventure")
        .font(HATheme.Typography.sectionTitle)
        .foregroundStyle(HATheme.Colors.foreground)

      HStack(spacing: 2) {
        ForEach(1...5, id: \.self) { rating in
          Button(action: { userRating = rating }) {
            Image(systemName: rating <= userRating ? "star.fill" : "star")
              .font(.system(size: 28, weight: .regular))
              .foregroundStyle(
                rating <= userRating
                  ? Color(red: 0.88, green: 0.62, blue: 0.12)
                  : HATheme.Colors.mutedForeground.opacity(0.35)
              )
              .frame(width: 36, height: 36)
          }
          .buttonStyle(.plain)
          .disabled(usesFixturePreview == false)
        }

        if let feedback = ratingFeedback {
          Text(feedback)
            .font(.system(size: 14, weight: .medium))
            .foregroundStyle(HATheme.Colors.mutedForeground)
            .padding(.leading, 8)
        }
      }
      .accessibilityIdentifier("detail.ratingStars")

      if usesFixturePreview == false {
        Text("Rating submission is not part of the Slice 1 server contract yet.")
          .font(.system(size: 13, weight: .medium))
          .foregroundStyle(HATheme.Colors.mutedForeground)
      }
    }
    .padding(.top, 28)
  }

  private func commentsSection(_ screenModel: AdventureDetailScreenModel) -> some View {
    let commentsCount = screenModel.commentsHeaderCount

    return VStack(alignment: .leading, spacing: 16) {
      HStack {
        HStack(spacing: 8) {
          Image(systemName: "message")
            .font(.system(size: 18, weight: .medium))
            .foregroundStyle(HATheme.Colors.mutedForeground)
          Text("\(commentsCount) \(commentsCount == 1 ? "Comment" : "Comments")")
            .font(.system(size: 16, weight: .semibold))
            .foregroundStyle(HATheme.Colors.foreground)
        }

        Spacer()

        Button(action: {}) {
          Image(systemName: "ellipsis")
            .font(.system(size: 18, weight: .semibold))
            .foregroundStyle(HATheme.Colors.mutedForeground)
            .frame(width: 30, height: 30)
        }
        .buttonStyle(.plain)
        .disabled(usesFixturePreview == false)
        .opacity(usesFixturePreview ? 1 : 0.7)
      }

      if visibleComments.isEmpty {
        UnsupportedSectionCard(
          systemImage: "ellipsis.message",
          message: commentsCount == 0
            ? "Comments will show up here once this API is available in a later slice."
            : "This adventure has comments, but the Slice 1 API does not expose the thread yet."
        )
      } else {
        VStack(spacing: 14) {
          ForEach(visibleComments) { comment in
            CommentBubble(comment: comment)
          }
        }
      }
    }
    .padding(.top, 28)
    .padding(.bottom, 12)
    .accessibilityIdentifier("detail.comments")
  }

  private var commentComposerBar: some View {
    HStack(alignment: .bottom, spacing: 12) {
      HAAvatarView(
        initials: "ME",
        size: 34,
        background: HATheme.Colors.primary,
        foreground: .white
      )

      TextField(
        usesFixturePreview ? "Add a comment..." : "Commenting is coming in a later slice",
        text: $commentText,
        axis: .vertical
      )
        .font(.system(size: 15, weight: .regular))
        .foregroundStyle(HATheme.Colors.foreground)
        .lineLimit(1...4)
        .submitLabel(.send)
        .onSubmit(sendComment)
        .padding(.horizontal, 16)
        .padding(.vertical, 11)
        .background(HATheme.Colors.muted)
        .clipShape(Capsule(style: .continuous))
        .disabled(usesFixturePreview == false)
        .accessibilityIdentifier("detail.composer")

      Button(action: sendComment) {
        Image(systemName: "paperplane")
          .font(.system(size: 16, weight: .semibold))
          .foregroundStyle(.white)
          .frame(width: 38, height: 38)
          .background(HATheme.Colors.accent.opacity(commentText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0.5 : 1))
          .clipShape(Circle())
      }
      .buttonStyle(.plain)
      .disabled(usesFixturePreview == false || commentText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
      .accessibilityIdentifier("detail.send")
    }
    .padding(.horizontal, 16)
    .padding(.top, 10)
    .padding(.bottom, 12)
    .background(.ultraThinMaterial)
    .overlay(alignment: .top) {
      Divider()
        .overlay(HATheme.Colors.border)
    }
    .accessibilityIdentifier("detail.composer")
  }

  private var loadingState: some View {
    ProgressView()
      .tint(HATheme.Colors.primary)
      .padding(.top, Layout.heroHeight + 80)
  }

  private var failureState: some View {
    VStack(spacing: 12) {
      Text("Unable to load this adventure.")
        .font(.system(size: 17, weight: .semibold))
        .foregroundStyle(HATheme.Colors.foreground)

      Button("Try Again") {
        Task { await loadScreen(force: true) }
      }
      .buttonStyle(.plain)
      .foregroundStyle(HATheme.Colors.primary)
    }
    .padding(.top, Layout.heroHeight + 80)
  }

  private var ratingFeedback: String? {
    switch userRating {
    case 5: return "Amazing!"
    case 4: return "Great"
    case 3: return "Good"
    case 2: return "Fair"
    case 1: return "Poor"
    default: return nil
    }
  }

  @MainActor
  private func loadScreen(force: Bool = false) async {
    if isLoading && force == false {
      return
    }

    isLoading = true
    didFailToLoad = false

    defer { isLoading = false }

    if runtimeMode == .fixturePreview {
      screenModel = MockFixtures.adventureDetailScreenModel(
        for: adventureID,
        variant: fixtureVariant
      )
      return
    }

    do {
      let detail = try await adventureService.getAdventure(id: adventureID).item
      async let authorProfileTask: ProfileDetail? = loadAuthorProfile(handle: detail.author.handle)
      async let mediaTask: [String] = loadMediaIDs(for: detail)

      let authorProfile = await authorProfileTask
      mediaIDs = await mediaTask
      let heroImageNames = AdventurePresentation.imageNames(
        for: adventureID,
        runtimeMode: runtimeMode
      )
      screenModel = AdventureDetailScreenModel(
        detail: detail,
        heroImageNames: heroImageNames,
        comments: [],
        authorProfile: authorProfile
      )
    } catch {
      didFailToLoad = true
    }
  }

  private func openDirections() {
    guard
      let directions = screenModel?.directions,
      let url = URL(string: "https://maps.apple.com/?q=\(directions.latitude),\(directions.longitude)")
    else {
      return
    }

    openURL(url)
  }

  private func sendComment() {
    guard usesFixturePreview else {
      return
    }

    guard commentText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false else {
      return
    }

    commentText = ""
  }

  private func loadMediaIDs(for detail: AdventureDetail) async -> [String] {
    do {
      return try await adventureService.listAdventureMedia(id: adventureID).items.map(\.id)
    } catch {
      return detail.primaryMedia.map { [$0.id] } ?? []
    }
  }

  private func loadAuthorProfile(handle: String) async -> ProfileDetail? {
    do {
      return try await profileService.getProfile(handle: handle, limit: 1, offset: 0).profile
    } catch {
      return nil
    }
  }
}

private struct NavigationCircleButton: View {
  let systemImage: String

  var body: some View {
    Image(systemName: systemImage)
      .font(.system(size: 16, weight: .semibold))
      .foregroundStyle(HATheme.Colors.foreground)
      .frame(width: 40, height: 40)
      .background(.white.opacity(0.92))
      .clipShape(Circle())
      .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 2)
  }
}

private struct FavoriteNavigationButton: View {
  let isFavorited: Bool

  var body: some View {
    Image(systemName: "bookmark.fill")
      .font(.system(size: 16, weight: .semibold))
      .foregroundStyle(isFavorited ? .white : HATheme.Colors.foreground)
      .frame(width: 40, height: 40)
      .background(isFavorited ? HATheme.Colors.primary : .white.opacity(0.92))
      .clipShape(Circle())
      .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 2)
  }
}

private struct AuthorAvatarView: View {
  let initials: String
  let mediaID: String?
  let mediaLoader: any AdventureService

  var body: some View {
    if let mediaID {
      HARemoteAvatarImage(
        mediaID: mediaID,
        mediaLoader: mediaLoader,
        initials: initials
      )
    } else {
      HAAvatarView(
        initials: initials,
        size: 42,
        background: HATheme.Colors.primary,
        foreground: .white
      )
    }
  }
}

private struct StylizedMapCard: View {
  var body: some View {
    ZStack {
      RoundedRectangle(cornerRadius: 20, style: .continuous)
        .fill(
          LinearGradient(
            colors: [
              Color(red: 0.86, green: 0.90, blue: 0.82),
              Color(red: 0.88, green: 0.91, blue: 0.84)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
          )
        )

      Canvas { context, size in
        var primaryRoad = Path()
        primaryRoad.move(to: CGPoint(x: 0, y: size.height * 0.50))
        primaryRoad.addCurve(
          to: CGPoint(x: size.width, y: size.height * 0.42),
          control1: CGPoint(x: size.width * 0.22, y: size.height * 0.28),
          control2: CGPoint(x: size.width * 0.66, y: size.height * 0.60)
        )

        var secondaryRoad = Path()
        secondaryRoad.move(to: CGPoint(x: 0, y: size.height * 0.60))
        secondaryRoad.addCurve(
          to: CGPoint(x: size.width, y: size.height * 0.54),
          control1: CGPoint(x: size.width * 0.26, y: size.height * 0.40),
          control2: CGPoint(x: size.width * 0.72, y: size.height * 0.72)
        )

        context.stroke(primaryRoad, with: .color(.white.opacity(0.74)), style: StrokeStyle(lineWidth: 4, lineCap: .round))
        context.stroke(secondaryRoad, with: .color(.white.opacity(0.32)), style: StrokeStyle(lineWidth: 2, lineCap: .round))
        context.fill(
          Path(ellipseIn: CGRect(x: size.width * 0.39, y: size.height * 0.28, width: size.width * 0.22, height: size.height * 0.28)),
          with: .color(HATheme.Colors.accent.opacity(0.25))
        )
      }

      ZStack {
        Circle()
          .fill(HATheme.Colors.primary)
          .frame(width: 40, height: 40)
        Image(systemName: "mappin.and.ellipse")
          .font(.system(size: 15, weight: .semibold))
          .foregroundStyle(.white)
      }
    }
    .frame(height: 138)
    .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
  }
}

private struct CommentBubble: View {
  let comment: AdventureDetailScreenModel.Comment

  var body: some View {
    HStack(alignment: .top, spacing: 12) {
      HAAvatarView(
        initials: comment.authorInitials,
        size: 36,
        background: HATheme.Colors.accent.opacity(0.95),
        foreground: .white
      )

      VStack(alignment: .leading, spacing: 6) {
        HStack(alignment: .firstTextBaseline) {
          Text(comment.authorDisplayName)
            .font(.system(size: 15, weight: .medium))
            .foregroundStyle(HATheme.Colors.foreground)

          Spacer(minLength: 8)

          Text(comment.relativeTimestamp)
            .font(.system(size: 12, weight: .medium))
            .foregroundStyle(HATheme.Colors.mutedForeground)
        }

        Text(comment.body)
          .font(.system(size: 15, weight: .regular))
          .foregroundStyle(HATheme.Colors.mutedForeground)
          .lineSpacing(4)
      }
    }
    .padding(14)
    .background(HATheme.Colors.muted)
    .clipShape(
      UnevenRoundedRectangle(
        topLeadingRadius: 10,
        bottomLeadingRadius: 20,
        bottomTrailingRadius: 20,
        topTrailingRadius: 20
      )
    )
  }
}

private struct UnsupportedSectionCard: View {
  let systemImage: String
  let message: String

  var body: some View {
    HStack(alignment: .top, spacing: 12) {
      Image(systemName: systemImage)
        .font(.system(size: 18, weight: .medium))
        .foregroundStyle(HATheme.Colors.primary)
        .frame(width: 24)

      Text(message)
        .font(.system(size: 14, weight: .medium))
        .foregroundStyle(HATheme.Colors.mutedForeground)
        .fixedSize(horizontal: false, vertical: true)

      Spacer(minLength: 0)
    }
    .padding(14)
    .background(HATheme.Colors.muted)
    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
  }
}

private struct HARemoteAvatarImage: View {
  let mediaID: String
  let mediaLoader: any AdventureService
  let initials: String

  @State private var image: UIImage?
  @State private var didFail = false

  var body: some View {
    Group {
      if let image {
        Image(uiImage: image)
          .resizable()
          .scaledToFill()
      } else if didFail {
        fallback
      } else {
        ZStack {
          Circle()
            .fill(HATheme.Colors.primary)

          ProgressView()
            .tint(.white)
            .scaleEffect(0.75)
        }
      }
    }
    .frame(width: 42, height: 42)
    .clipShape(Circle())
    .task(id: mediaID) {
      await loadImage()
    }
  }

  private var fallback: some View {
    HAAvatarView(
      initials: initials,
      size: 42,
      background: HATheme.Colors.primary,
      foreground: .white
    )
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

struct AdventureDetailView_Previews: PreviewProvider {
  static var previews: some View {
    Group {
      AdventureDetailPreviewContainer(variant: .happy)
        .previewDisplayName("Happy Path")
      AdventureDetailPreviewContainer(variant: .longText)
        .previewDisplayName("Long Text")
      AdventureDetailPreviewContainer(variant: .singleImage)
        .previewDisplayName("Single Image")
      AdventureDetailPreviewContainer(variant: .noComments)
        .previewDisplayName("No Comments")
    }
  }
}

private struct AdventureDetailPreviewContainer: View {
  let variant: AdventureDetailFixtureVariant

  var body: some View {
    AdventureDetailView(
      adventureID: MockFixtures.bluePoolID,
      adventureService: FixtureAdventureService(),
      profileService: FixtureProfileService(),
      runtimeMode: .fixturePreview,
      fixtureVariantOverride: variant
    )
  }
}
