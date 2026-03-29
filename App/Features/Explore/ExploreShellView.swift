import SwiftUI

struct ExploreShellView: View {
  let adventureService: AdventureService
  let viewerHandle: String?
  @Binding var mode: ExploreMode
  let onOpenDetail: (UUID) -> Void

  @State private var feedItems: [AdventureCard] = []
  @State private var visibilityFilter: VisibilityFilter = .all
  @State private var activeCategory: Category?
  @State private var isLoading = true

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
      } else if mode == .feed {
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
            onOpenDetail: onOpenDetail
          )
        }
      } else {
        MapExploreView(
          items: filteredItems,
          visibilityFilter: visibilityFilter,
          activeCategory: activeCategory,
          onVisibilityChange: { visibilityFilter = $0 },
          onCategoryToggle: { category in
            activeCategory = activeCategory == category ? nil : category
          },
          onSelectTab: { tab in
            switch tab {
            case .home:
              mode = .feed
            case .explore:
              mode = .map
            case .post, .saved, .profile:
              break
            }
          },
          onOpenDetail: onOpenDetail
        )
      }
    }
    .safeAreaInset(edge: .bottom, spacing: 0) {
      if mode == .feed {
        HABottomTabBar(
          selectedTab: .home,
          onSelect: { tab in
            switch tab {
            case .home:
              mode = .feed
            case .explore:
              mode = .map
            case .post, .saved, .profile:
              break
            }
          }
        )
      }
    }
    .task {
      guard feedItems.isEmpty else { return }
      let response = try? await adventureService.listFeed(
        viewerHandle: viewerHandle,
        limit: 20,
        offset: 0
      )
      feedItems = response?.items ?? []
      isLoading = false
    }
    .toolbar(.hidden, for: .navigationBar)
  }

  private var header: some View {
    HStack(alignment: .top) {
      VStack(alignment: .leading, spacing: 4) {
        Text("Good morning")
          .font(.system(size: 14, weight: .regular))
          .foregroundStyle(HATheme.Colors.mutedForeground)

        Text("Jordan")
          .font(.system(size: 20, weight: .semibold))
          .foregroundStyle(HATheme.Colors.foreground)
      }

      Spacer()

      HStack(spacing: 10) {
        CircleIconButton(systemImage: "magnifyingglass", accessibilityID: "header.search")
        CircleIconButton(systemImage: "bell", showsIndicator: true, accessibilityID: "header.notifications")
      }
    }
    .padding(.horizontal, 20)
    .padding(.top, 12)
    .padding(.bottom, 12)
  }

  private var visibilityControl: some View {
    HStack(spacing: 6) {
      ForEach(VisibilityFilter.allCases) { filter in
        Button {
          visibilityFilter = filter
        } label: {
          HStack(spacing: 5) {
            if let symbol = filter.symbolName {
              Image(systemName: symbol)
                .font(.system(size: 11, weight: .semibold))
            }

            Text(filter.title)
              .font(.system(size: 12, weight: .semibold))
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
        }
      }
      .padding(.horizontal, 1)
    }
  }
}

private struct CircleIconButton: View {
  let systemImage: String
  var showsIndicator: Bool = false
  let accessibilityID: String

  var body: some View {
    Button(action: {}) {
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
