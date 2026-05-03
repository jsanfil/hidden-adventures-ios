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

  @State private var currentDetail: AdventureDetail?
  @State private var screenModel: AdventureDetailScreenModel?
  @State private var mediaIDs: [String] = []
  @State private var isLoading = false
  @State private var didFailToLoad = false
  @State private var isFavorited = false
  @State private var isFavoriteMutationInFlight = false
  @State private var userRating = 0
  @State private var isRatingMutationInFlight = false
  @State private var commentText = ""
  @State private var viewerProfile: ProfileDetail?
  @State private var isLoadingComments = false
  @State private var isLoadingMoreComments = false
  @State private var isSendingComment = false
  @State private var commentsErrorMessage: String?
  @State private var commentAlertMessage: String?
  @State private var ratingErrorMessage: String?
  @State private var sharePayload: AdventureSharePayload?
  @State private var shareUnavailableMessage: String?

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
    screenModel?.comments ?? []
  }

  private var trimmedCommentText: String {
    commentText.trimmingCharacters(in: .whitespacesAndNewlines)
  }

  private var canSendComment: Bool {
    trimmedCommentText.isEmpty == false && isSendingComment == false && screenModel != nil
  }

  private var hasMoreComments: Bool {
    guard let screenModel else { return false }
    return screenModel.comments.count < screenModel.commentsTotalCount
  }

  private var commentPageSize: Int {
    usesFixturePreview ? 20 : 20
  }

  private var viewerInitials: String {
    let name = viewerProfile?.displayName?.trimmingCharacters(in: .whitespacesAndNewlines)
    if let name, name.isEmpty == false {
      return AdventureDetailScreenModel.initials(for: name)
    }

    let handle = viewerProfile?.handle.trimmingCharacters(in: .whitespacesAndNewlines)
    if let handle, handle.isEmpty == false {
      return AdventureDetailScreenModel.initials(for: handle)
    }

    return "ME"
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
    .sheet(isPresented: Binding(
      get: { sharePayload != nil },
      set: { if $0 == false { sharePayload = nil } }
    )) {
      if let sharePayload {
        ShareSheet(items: [sharePayload.message, sharePayload.url])
      }
    }
    .toolbar(.hidden, for: .navigationBar)
    .task {
      guard screenModel == nil, isLoading == false else { return }
      await loadScreen()
    }
    .alert(
      "Hidden Adventures",
      isPresented: Binding(
        get: { commentAlertMessage != nil },
        set: { if $0 == false { commentAlertMessage = nil } }
      )
    ) {
      Button("OK", role: .cancel) {
        commentAlertMessage = nil
      }
    } message: {
      Text(commentAlertMessage ?? "")
    }
    .alert(
      "Sharing unavailable",
      isPresented: Binding(
        get: { shareUnavailableMessage != nil },
        set: { if $0 == false { shareUnavailableMessage = nil } }
      )
    ) {
      Button("OK", role: .cancel) {
        shareUnavailableMessage = nil
      }
    } message: {
      Text(shareUnavailableMessage ?? "")
        .accessibilityIdentifier("detail.shareUnavailableMessage")
    }
    .onReceive(NotificationCenter.default.publisher(for: FavoriteStateChange.notificationName)) { notification in
      guard let change = FavoriteStateChange(notification: notification) else { return }
      guard change.adventureID == MockFixtures.resolvedAdventureID(for: adventureID) else { return }
      isFavorited = change.isFavorited
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
        Button(action: handleShareTapped) {
          NavigationCircleButton(systemImage: "square.and.arrow.up")
        }
        .buttonStyle(.plain)
        .disabled(currentDetail == nil)
        .opacity(currentDetail == nil ? 0.7 : 1)
        .accessibilityIdentifier("detail.share")

        Button(action: toggleFavorite) {
          FavoriteNavigationButton(isFavorited: isFavorited)
        }
        .buttonStyle(.plain)
        .disabled(isFavoriteMutationInFlight || screenModel == nil)
        .accessibilityLabel(isFavorited ? "Remove favorite" : "Add favorite")
        .accessibilityValue(isFavorited ? "favorited" : "not favorited")
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
            .accessibilityIdentifier(index == 0 ? "detail.description" : "detail.description.\(index)")
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
          Button(action: { submitRating(rating) }) {
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
          .disabled(isRatingMutationInFlight || screenModel == nil)
          .accessibilityElement(children: .ignore)
          .accessibilityLabel("Rate \(rating) star\(rating == 1 ? "" : "s")")
          .accessibilityIdentifier("detail.ratingStar.\(rating)")
          .accessibilityValue(rating <= userRating ? "selected" : "not selected")
        }

        if let feedback = ratingFeedback {
          Text(feedback)
            .font(.system(size: 14, weight: .medium))
            .foregroundStyle(HATheme.Colors.mutedForeground)
            .padding(.leading, 8)
            .accessibilityIdentifier("detail.ratingFeedback")
        }
      }
      .accessibilityIdentifier("detail.ratingStars")

      HStack(spacing: 12) {
        if userRating > 0 {
          Button("Clear rating") {
            submitRating(nil)
          }
          .buttonStyle(.plain)
          .font(.system(size: 13, weight: .semibold))
          .foregroundStyle(HATheme.Colors.primary)
          .disabled(isRatingMutationInFlight || screenModel == nil)
          .accessibilityIdentifier("detail.ratingClear")
        }

        if isRatingMutationInFlight {
          ProgressView()
            .tint(HATheme.Colors.primary)
            .scaleEffect(0.8)
        }
      }

      if let ratingErrorMessage {
        Text(ratingErrorMessage)
          .font(.system(size: 13, weight: .medium))
          .foregroundStyle(.red)
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
      }

      if visibleComments.isEmpty {
        if isLoadingComments {
          ProgressView("Loading comments...")
            .tint(HATheme.Colors.primary)
            .font(.system(size: 14, weight: .medium))
            .accessibilityIdentifier("detail.comments.loading")
        } else if let commentsErrorMessage {
          CommentsErrorCard(
            message: commentsErrorMessage,
            retry: { Task { await loadComments(reset: true) } }
          )
        } else {
          EmptyCommentsCard()
        }
      } else {
        VStack(spacing: 14) {
          ForEach(visibleComments) { comment in
            CommentBubble(comment: comment, mediaLoader: adventureService)
              .onAppear {
                Task {
                  await loadMoreCommentsIfNeeded(currentCommentID: comment.id)
                }
              }
          }

          if isLoadingMoreComments {
            ProgressView("Loading more comments...")
              .tint(HATheme.Colors.primary)
              .font(.system(size: 13, weight: .medium))
              .accessibilityIdentifier("detail.comments.loadingMore")
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
      ProfileAvatarView(
        initials: viewerInitials,
        mediaID: viewerProfile?.avatar?.id,
        mediaLoader: adventureService,
        size: 34,
        background: HATheme.Colors.primary,
        foreground: .white,
        borderColor: nil,
        borderWidth: 0,
        loadingTint: .white
      )

      TextField(
        "Add a comment...",
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
        .disabled(isSendingComment)
        .accessibilityIdentifier("detail.composer")

      Button(action: sendComment) {
        Group {
          if isSendingComment {
            ProgressView()
              .tint(.white)
          } else {
            Image(systemName: "paperplane")
              .font(.system(size: 16, weight: .semibold))
              .foregroundStyle(.white)
          }
        }
        .frame(width: 38, height: 38)
        .background(canSendComment ? HATheme.Colors.primary : HATheme.Colors.accent.opacity(0.5))
        .clipShape(Circle())
      }
      .buttonStyle(.plain)
      .disabled(canSendComment == false)
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
      do {
        let detail = try await adventureService.getAdventure(id: adventureID).item
        currentDetail = detail
        isFavorited = detail.isFavorited
        userRating = detail.viewerRating ?? 0
        ratingErrorMessage = nil
        viewerProfile = await loadViewerProfile()
        let baseModel = MockFixtures.adventureDetailScreenModel(
          for: adventureID,
          variant: fixtureVariant
        )
        screenModel = baseModel.replacingRating(
          viewerRating: detail.viewerRating,
          averageRating: detail.stats.averageRating,
          ratingCount: detail.stats.ratingCount
        )
        let totalCount = fixtureVariant == .noComments
          ? 0
          : MockFixtures.detailCommentsByAdventureID[MockFixtures.resolvedAdventureID(for: adventureID)]?.count ?? 0
        screenModel = screenModel?.replacingComments([], totalCount: totalCount)
        if totalCount > 0 {
          await loadComments(reset: true)
        }
      } catch {
        didFailToLoad = true
      }
      return
    }

    do {
      let detail = try await adventureService.getAdventure(id: adventureID).item
      currentDetail = detail
      isFavorited = detail.isFavorited
      userRating = detail.viewerRating ?? 0
      ratingErrorMessage = nil
      async let authorProfileTask: ProfileDetail? = loadAuthorProfile(handle: detail.author.handle)
      async let viewerProfileTask: ProfileDetail? = loadViewerProfile()
      async let mediaTask: [String] = loadMediaIDs(for: detail)

      let authorProfile = await authorProfileTask
      viewerProfile = await viewerProfileTask
      mediaIDs = await mediaTask
      let heroImageNames = AdventurePresentation.imageNames(
        for: adventureID,
        runtimeMode: runtimeMode
      )
      screenModel = AdventureDetailScreenModel(
        detail: detail,
        heroImageNames: heroImageNames,
        comments: [],
        commentsTotalCount: detail.stats.commentCount,
        authorProfile: authorProfile
      )

      if detail.stats.commentCount > 0 {
        await loadComments(reset: true)
      }
    } catch {
      didFailToLoad = true
    }
  }

  private func toggleFavorite() {
    let targetState = !isFavorited
    let previousState = isFavorited
    isFavorited = targetState
    isFavoriteMutationInFlight = true

    Task {
      do {
        if targetState {
          try await adventureService.favoriteAdventure(id: adventureID)
        } else {
          try await adventureService.unfavoriteAdventure(id: adventureID)
        }
      } catch {
        await MainActor.run {
          isFavorited = previousState
        }
      }

      await MainActor.run {
        isFavoriteMutationInFlight = false
      }
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

  private func handleShareTapped() {
    guard let currentDetail else { return }

    if let payload = AdventureSharePayload.make(
      detail: currentDetail,
      baseURL: URL(string: "https://hiddenadventures.app")!
    ) {
      sharePayload = payload
      return
    }

    shareUnavailableMessage = AdventureSharePayload.unavailableMessage(for: currentDetail.visibility)
  }

  private func sendComment() {
    Task {
      await submitComment()
    }
  }

  private func submitRating(_ rating: Int?) {
    Task {
      await mutateRating(rating)
    }
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

  private func loadViewerProfile() async -> ProfileDetail? {
    do {
      return try await profileService.getMyProfile().profile
    } catch {
      return nil
    }
  }

  private func loadCommentAuthorProfiles(
    for items: [AdventureCommentItem]
  ) async -> [String: ProfileDetail] {
    let handlesNeedingProfiles = Array(
      Set(
        items.compactMap { item -> String? in
          guard item.author.avatar == nil else { return nil }
          return item.author.handle
        }
      )
    )

    return await withTaskGroup(of: (String, ProfileDetail?).self) { group in
      for handle in handlesNeedingProfiles {
        group.addTask {
          (handle, await loadAuthorProfile(handle: handle))
        }
      }

      var profiles: [String: ProfileDetail] = [:]
      for await (handle, profile) in group {
        if let profile {
          profiles[handle] = profile
        }
      }
      return profiles
    }
  }

  @MainActor
  private func loadComments(reset: Bool) async {
    guard let currentScreenModel = screenModel else { return }
    guard isLoadingComments == false, isLoadingMoreComments == false else { return }

    let offset = reset ? 0 : currentScreenModel.comments.count
    if reset == false, offset >= currentScreenModel.commentsTotalCount {
      return
    }

    if reset {
      isLoadingComments = true
      commentsErrorMessage = nil
    } else {
      isLoadingMoreComments = true
    }

    defer {
      isLoadingComments = false
      isLoadingMoreComments = false
    }

    do {
      let response = try await adventureService.listComments(
        adventureID: adventureID,
        limit: commentPageSize,
        offset: offset
      )
      let authorProfiles = await loadCommentAuthorProfiles(for: response.items)
      let mappedComments = response.items.map { item in
        AdventureDetailScreenModel.comment(from: item, profile: authorProfiles[item.author.handle])
      }
      let latestScreenModel = screenModel ?? currentScreenModel
      let existingComments = reset ? [] : latestScreenModel.comments
      let mergedComments = mergeComments(existingComments, mappedComments)
      let totalCount = response.paging.returned == 0
        ? mergedComments.count
        : max(latestScreenModel.commentsTotalCount, mergedComments.count)
      screenModel = latestScreenModel.replacingComments(mergedComments, totalCount: totalCount)
    } catch {
      if reset {
        commentsErrorMessage = "Unable to load comments right now."
      } else {
        commentAlertMessage = "Unable to load more comments right now."
      }
    }
  }

  @MainActor
  private func loadMoreCommentsIfNeeded(currentCommentID: String) async {
    guard let screenModel else { return }
    guard hasMoreComments else { return }
    guard screenModel.comments.last?.id == currentCommentID else { return }
    await loadComments(reset: false)
  }

  @MainActor
  private func submitComment() async {
    guard canSendComment else { return }
    guard let currentScreenModel = screenModel else { return }

    isSendingComment = true
    defer { isSendingComment = false }

    do {
      let response = try await adventureService.createComment(
        adventureID: adventureID,
        body: trimmedCommentText
      )
      if viewerProfile == nil {
        viewerProfile = await loadViewerProfile()
      }
      let newComment = AdventureDetailScreenModel.comment(from: response.item, profile: viewerProfile)
      let latestScreenModel = screenModel ?? currentScreenModel
      let updatedComments = mergeComments(latestScreenModel.comments, [newComment])
      screenModel = latestScreenModel.replacingComments(
        updatedComments,
        totalCount: max(latestScreenModel.commentsTotalCount + 1, updatedComments.count)
      )
      commentText = ""
      commentsErrorMessage = nil
    } catch let error as APIError {
      commentAlertMessage = error.localizedDescription
    } catch {
      commentAlertMessage = "Unable to post your comment right now."
    }
  }

  @MainActor
  private func mutateRating(_ rating: Int?) async {
    guard screenModel != nil else { return }
    guard isRatingMutationInFlight == false else { return }

    let previousRating = userRating
    userRating = rating ?? 0
    isRatingMutationInFlight = true
    ratingErrorMessage = nil

    defer { isRatingMutationInFlight = false }

    do {
      let response = if let rating {
        try await adventureService.rateAdventure(id: adventureID, score: rating)
      } else {
        try await adventureService.clearRating(id: adventureID)
      }
      applyUpdatedRating(response.item)
    } catch let error as APIError {
      userRating = previousRating
      ratingErrorMessage = error.localizedDescription
    } catch {
      userRating = previousRating
      ratingErrorMessage = "Unable to update your rating right now."
    }
  }

  @MainActor
  private func applyUpdatedRating(_ detail: AdventureDetail) {
    let latestScreenModel = screenModel
    userRating = detail.viewerRating ?? 0
    screenModel = latestScreenModel?.replacingRating(
      viewerRating: detail.viewerRating,
      averageRating: detail.stats.averageRating,
      ratingCount: detail.stats.ratingCount
    )
  }

  private func mergeComments(
    _ existing: [AdventureDetailScreenModel.Comment],
    _ incoming: [AdventureDetailScreenModel.Comment]
  ) -> [AdventureDetailScreenModel.Comment] {
    var seen = Set(existing.map(\.id))
    var merged = existing

    for comment in incoming where seen.contains(comment.id) == false {
      merged.append(comment)
      seen.insert(comment.id)
    }

    return merged
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
    Image(systemName: isFavorited ? "bookmark.fill" : "bookmark")
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
  let mediaLoader: any AdventureService

  var body: some View {
    HStack(alignment: .top, spacing: 12) {
      ProfileAvatarView(
        initials: comment.authorInitials,
        mediaID: comment.avatarMediaID,
        mediaLoader: mediaLoader,
        size: 36,
        background: HATheme.Colors.accent.opacity(0.95),
        foreground: .white,
        borderColor: nil,
        borderWidth: 0,
        loadingTint: .white
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
    .accessibilityIdentifier("detail.comment.\(comment.id)")
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

private struct EmptyCommentsCard: View {
  var body: some View {
    UnsupportedSectionCard(
      systemImage: "ellipsis.message",
      message: "No comments yet. Be the first!"
    )
    .accessibilityIdentifier("detail.comments.empty")
  }
}

private struct CommentsErrorCard: View {
  let message: String
  let retry: () -> Void

  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      UnsupportedSectionCard(
        systemImage: "exclamationmark.bubble",
        message: message
      )

      Button("Try Again", action: retry)
        .buttonStyle(.plain)
        .font(.system(size: 14, weight: .semibold))
        .foregroundStyle(HATheme.Colors.primary)
    }
    .accessibilityIdentifier("detail.comments.error")
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
    .onReceive(NotificationCenter.default.publisher(for: .haMediaCacheDidChange)) { notification in
      guard
        let changedMediaID = notification.userInfo?[MediaCacheNotifications.mediaIDUserInfoKey] as? String,
        changedMediaID == mediaID,
        let rawAction = notification.userInfo?[MediaCacheNotifications.actionUserInfoKey] as? String,
        let action = MediaCacheChangeAction(rawValue: rawAction)
      else {
        return
      }

      switch action {
      case .invalidated:
        image = nil
        didFail = true
      case .updated:
        Task {
          await loadImage(forceReload: true)
        }
      }
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
  private func loadImage(forceReload: Bool = false) async {
    if image != nil && forceReload == false {
      return
    }

    do {
      let data = try await mediaLoader.loadMediaData(id: mediaID)
      image = UIImage(data: data)
      didFail = image == nil
    } catch {
      image = nil
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
