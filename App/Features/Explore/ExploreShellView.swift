import SwiftUI

struct ExploreShellView: View {
  let adventureService: AdventureService
  let profileService: ProfileService
  let runtimeMode: AppRuntimeMode
  let viewerHandle: String?
  let viewerDisplayName: String?
  @Binding var mode: ExploreMode
  let onViewerProfileLoaded: (ProfileDetail) -> Void
  let onOpenDetail: (String) -> Void
  let onLogout: () -> Void

  @State private var feedItems: [AdventureCard] = []
  @State private var visibilityFilter: VisibilityFilter = .all
  @State private var activeCategory: Category?
  @State private var isLoading = true
  @State private var errorMessage: String?

  var filteredItems: [AdventureCard] {
    feedItems.filter { item in
      let visibilityMatches = visibilityFilter.matches(item.visibility)
      let categoryMatches = activeCategory == nil || item.categorySlug == activeCategory
      return visibilityMatches && categoryMatches
    }
  }

  var body: some View {
    ZStack {
      HATheme.Colors.background
        .ignoresSafeArea()

      if isLoading {
        ProgressView()
          .tint(HATheme.Colors.primary)
      } else if let errorMessage {
        errorState(message: errorMessage)
      } else {
        switch mode {
        case .feed:
          feedScreen
        case .map:
          mapScreen
        case .profile:
          profileScreen
        }
      }
    }
    .safeAreaInset(edge: .bottom, spacing: 8) {
      HABottomTabBar(
        selectedTab: selectedTab,
        onSelect: handleTabSelection
      )
    }
    .task {
      guard feedItems.isEmpty else { return }
      await loadFeed()
    }
    .toolbar(.hidden, for: .navigationBar)
  }

  private var selectedTab: HAAppTab {
    switch mode {
    case .feed:
      return .home
    case .map:
      return .explore
    case .profile:
      return .profile
    }
  }

  private var feedScreen: some View {
    VStack(spacing: 0) {
      HAStatusBarSpacer()
      header

      VStack(spacing: 12) {
        visibilityControl
        categoryStrip
      }
      .padding(.horizontal, 20)
      .padding(.bottom, 12)

      FeedView(
        items: filteredItems,
        adventureService: adventureService,
        runtimeMode: runtimeMode,
        onOpenDetail: onOpenDetail
      )
    }
  }

  private var mapScreen: some View {
    MapExploreView(
      items: filteredItems,
      runtimeMode: runtimeMode,
      visibilityFilter: visibilityFilter,
      activeCategory: activeCategory,
      onVisibilityChange: { visibilityFilter = $0 },
      onCategoryToggle: { category in
        activeCategory = activeCategory == category ? nil : category
      },
      onSelectTab: handleTabSelection,
      onOpenDetail: onOpenDetail
    )
  }

  private var profileScreen: some View {
    ProfileView(
      handle: viewerHandle,
      adventureService: adventureService,
      profileService: profileService,
      runtimeMode: runtimeMode,
      onProfileLoaded: onViewerProfileLoaded,
      onOpenDetail: onOpenDetail,
      onLogout: onLogout
    )
  }

  private var header: some View {
    HStack(alignment: .top) {
      VStack(alignment: .leading, spacing: 4) {
        Text("Good morning")
          .font(.system(size: 14, weight: .regular))
          .foregroundStyle(HATheme.Colors.mutedForeground)

        Text(viewerDisplayName ?? viewerHandle ?? "Explorer")
          .font(.system(size: 20, weight: .semibold))
          .foregroundStyle(HATheme.Colors.foreground)
      }

      Spacer()

      HStack(spacing: 10) {
        CircleIconButton(systemImage: "magnifyingglass", accessibilityID: "header.search")
        CircleIconButton(systemImage: "bell", showsIndicator: true, accessibilityID: "header.notifications")
        if mode == .profile {
          CircleIconButton(
            systemImage: "rectangle.portrait.and.arrow.right",
            accessibilityID: "header.logout",
            action: onLogout
          )
        }
      }
    }
    .padding(.horizontal, 20)
    .padding(.top, 12)
    .padding(.bottom, 12)
  }

  private var visibilityControl: some View {
    HStack(spacing: 4) {
      ForEach(VisibilityFilter.allCases) { filter in
        Button {
          visibilityFilter = filter
        } label: {
          HStack(spacing: 3) {
            if let symbol = filter.symbolName {
              Image(systemName: symbol)
                .font(.system(size: 10, weight: .semibold))
            }

            Text(filter.title)
              .font(.system(size: 11, weight: .semibold))
              .lineLimit(1)
              .minimumScaleFactor(0.85)
          }
          .foregroundStyle(visibilityFilter == filter ? HATheme.Colors.foreground : HATheme.Colors.mutedForeground)
          .frame(maxWidth: .infinity)
          .frame(height: 32)
          .background(visibilityFilter == filter ? HATheme.Colors.card : .clear)
          .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        }
        .buttonStyle(.plain)
      }
    }
    .padding(4)
    .background(HATheme.Colors.secondary)
    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
  }

  private var categoryStrip: some View {
    ScrollView(.horizontal, showsIndicators: false) {
      HStack(spacing: 10) {
        ForEach(Category.allCases) { category in
          HAChip(
            title: category.displayTitle,
            systemImage: category.systemImage,
            isSelected: activeCategory == category
          ) {
            activeCategory = activeCategory == category ? nil : category
          }
          .accessibilityIdentifier("explore.category.\(category.rawValue)")
        }
      }
      .padding(.horizontal, 1)
    }
  }

  private func errorState(message: String) -> some View {
    VStack(spacing: 16) {
      Image(systemName: "wifi.exclamationmark")
        .font(.system(size: 32, weight: .medium))
        .foregroundStyle(HATheme.Colors.primary)

      Text("We couldn't load the Slice 1 feed.")
        .font(HATheme.Typography.sectionTitle)
        .foregroundStyle(HATheme.Colors.foreground)

      Text(message)
        .font(HATheme.Typography.body)
        .foregroundStyle(HATheme.Colors.mutedForeground)
        .multilineTextAlignment(.center)

      HAPrimaryButton(title: "Try Again") {
        Task {
          await loadFeed()
        }
      }
      .frame(maxWidth: 240)
    }
    .padding(24)
  }

  private func handleTabSelection(_ tab: HAAppTab) {
    switch tab {
    case .home:
      mode = .feed
    case .explore:
      mode = .map
    case .profile:
      mode = .profile
    case .post, .saved:
      break
    }
  }

  private func loadFeed() async {
    isLoading = true
    defer { isLoading = false }

    do {
      let response = try await adventureService.listFeed(limit: 20, offset: 0)
      feedItems = response.items
      errorMessage = nil
    } catch {
      errorMessage = error.localizedDescription
    }
  }
}

private struct CircleIconButton: View {
  let systemImage: String
  var showsIndicator: Bool = false
  let accessibilityID: String
  var action: () -> Void = {}

  var body: some View {
    Button(action: action) {
      ZStack {
        Circle()
          .fill(HATheme.Colors.secondary)
          .frame(width: 40, height: 40)

        Image(systemName: systemImage)
          .font(.system(size: 18, weight: .medium))
          .foregroundStyle(HATheme.Colors.foreground)

        if showsIndicator {
          Circle()
            .fill(HATheme.Colors.primary)
            .frame(width: 8, height: 8)
            .offset(x: 11, y: -11)
        }
      }
    }
    .buttonStyle(.plain)
    .accessibilityIdentifier(accessibilityID)
  }
}

enum VisibilityFilter: CaseIterable, Identifiable {
  case all
  case `public`
  case connections
  case `private`

  var id: Self { self }

  var title: String {
    switch self {
    case .all: "All"
    case .public: "Public"
    case .connections: "Connections"
    case .private: "Private"
    }
  }

  var symbolName: String? {
    switch self {
    case .all: nil
    case .public: "globe"
    case .connections: "person.2"
    case .private: "lock"
    }
  }

  var accessibilityKey: String {
    switch self {
    case .all: "all"
    case .public: "public"
    case .connections: "connections"
    case .private: "private"
    }
  }

  func matches(_ visibility: Visibility) -> Bool {
    switch self {
    case .all: true
    case .public: visibility == .public
    case .connections: visibility == .connections
    case .private: visibility == .private
    }
  }
}

private struct ExploreShellPreviewWrapper: View {
  @State private var mode: ExploreMode = .feed

  var body: some View {
    ExploreShellView(
      adventureService: FixtureAdventureService(),
      profileService: FixtureProfileService(),
      runtimeMode: .fixturePreview,
      viewerHandle: MockFixtures.profile.handle,
      viewerDisplayName: MockFixtures.profile.displayName,
      mode: $mode,
      onViewerProfileLoaded: { _ in },
      onOpenDetail: { _ in },
      onLogout: {}
    )
  }
}

struct ExploreShellView_Previews: PreviewProvider {
  static var previews: some View {
    ExploreShellPreviewWrapper()
  }
}
