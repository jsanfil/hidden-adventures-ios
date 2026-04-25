import SwiftUI

struct DiscoverView: View {
  let initialModel: DiscoverScreenModel
  var initialSearchQuery: String = ""
  let discoverService: (any DiscoverService)?
  let adventureService: any AdventureService
  let runtimeMode: AppRuntimeMode
  let onOpenProfile: (String) -> Void
  let onOpenDetail: (String) -> Void

  @State private var model: DiscoverScreenModel
  @State private var searchQuery: String
  @State private var remoteSearchResults: DiscoverScreenModel.SearchResults?
  @State private var isLoadingHome = false
  @State private var isLoadingSearch = false
  @State private var errorMessage: String?
  @State private var searchTask: Task<Void, Never>?
  @FocusState private var isSearchFocused: Bool

  init(
    model: DiscoverScreenModel,
    initialSearchQuery: String = "",
    discoverService: (any DiscoverService)? = nil,
    adventureService: any AdventureService = FixtureAdventureService(),
    runtimeMode: AppRuntimeMode = .fixturePreview,
    onOpenProfile: @escaping (String) -> Void,
    onOpenDetail: @escaping (String) -> Void
  ) {
    self.initialModel = model
    self.initialSearchQuery = initialSearchQuery
    self.discoverService = discoverService
    self.adventureService = adventureService
    self.runtimeMode = runtimeMode
    self.onOpenProfile = onOpenProfile
    self.onOpenDetail = onOpenDetail
    _model = State(initialValue: model)
    _searchQuery = State(initialValue: initialSearchQuery)
  }

  private var isSearching: Bool {
    searchQuery.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false
  }

  private var searchResults: DiscoverScreenModel.SearchResults {
    remoteSearchResults ?? model.searchResults(for: searchQuery)
  }

  private var normalizedSearchQuery: String {
    searchQuery.trimmingCharacters(in: .whitespacesAndNewlines)
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 0) {
      HAStatusBarSpacer()

      header

      if let errorMessage {
        errorState(message: errorMessage)
      } else if isLoadingHome && model.adventurers.isEmpty && model.popularAdventures.isEmpty {
        loadingState
      } else if isSearching {
        searchResultsContent
      } else {
        homeContent
      }
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    .background(HATheme.Colors.background.ignoresSafeArea())
    .task {
      await loadHome()
      await refreshSearchIfNeeded()
    }
    .onChange(of: normalizedSearchQuery) {
      remoteSearchResults = nil
      scheduleSearch()
    }
  }

  private var header: some View {
    VStack(alignment: .leading, spacing: 14) {
      Text("Discover")
        .font(HATheme.Typography.screenTitle)
        .foregroundStyle(HATheme.Colors.foreground)
        .accessibilityIdentifier("discover.title")

      searchBar
    }
    .padding(.horizontal, 20)
    .padding(.top, 12)
    .padding(.bottom, 14)
  }

  private var searchBar: some View {
    HStack(spacing: 12) {
      Image(systemName: "magnifyingglass")
        .font(.system(size: 16, weight: .medium))
        .foregroundStyle(HATheme.Colors.mutedForeground)

      TextField("Search people and adventures...", text: $searchQuery)
        .font(.system(size: 14, weight: .regular))
        .foregroundStyle(HATheme.Colors.foreground)
        .textInputAutocapitalization(.words)
        .disableAutocorrection(true)
        .focused($isSearchFocused)
        .accessibilityIdentifier("discover.searchField")

      if isSearching {
        Button {
          searchQuery = ""
          isSearchFocused = false
          searchTask?.cancel()
          remoteSearchResults = nil
          isLoadingSearch = false
        } label: {
          Image(systemName: "xmark")
            .font(.system(size: 14, weight: .semibold))
            .foregroundStyle(HATheme.Colors.mutedForeground)
            .frame(width: 24, height: 24)
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("discover.searchClear")
      }
    }
    .padding(.horizontal, 14)
    .frame(height: 44)
    .background(HATheme.Colors.secondary)
    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    .overlay {
      RoundedRectangle(cornerRadius: 16, style: .continuous)
        .stroke(isSearchFocused ? HATheme.Colors.primary.opacity(0.30) : HATheme.Colors.border, lineWidth: isSearchFocused ? 2 : 1)
    }
  }

  private var homeContent: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 28) {
        if isLoadingHome {
          ProgressView()
            .tint(HATheme.Colors.primary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .accessibilityIdentifier("discover.homeLoading")
        }

        DiscoverSectionHeader(title: "Explore Adventurers")
          .accessibilityIdentifier("discover.section.exploreAdventurers")

        horizontalAdventurers

        DiscoverSectionHeader(title: "Popular Adventures")
          .accessibilityIdentifier("discover.section.popularAdventures")

        horizontalAdventures
      }
      .padding(.top, 4)
      .padding(.bottom, 24)
    }
    .accessibilityIdentifier("discover.homeScroll")
  }

  private var horizontalAdventurers: some View {
    ScrollView(.horizontal, showsIndicators: false) {
      LazyHStack(spacing: 12) {
        ForEach(model.adventurers) { adventurer in
          Button {
            onOpenProfile(adventurer.handle)
          } label: {
            DiscoverAdventurerCard(adventurer: adventurer)
              .environment(\.discoverMediaSource, adventurerMediaSource(for: adventurer))
              .environment(\.discoverMediaLoader, adventureService)
          }
          .buttonStyle(.plain)
          .accessibilityIdentifier("discover.adventurerCard.\(adventurer.id)")
        }
      }
      .padding(.horizontal, 20)
    }
  }

  private var horizontalAdventures: some View {
    ScrollView(.horizontal, showsIndicators: false) {
      LazyHStack(spacing: 12) {
        ForEach(model.popularAdventures) { adventure in
          Button {
            onOpenDetail(adventure.id)
          } label: {
            DiscoverAdventureCard(adventure: adventure)
              .environment(\.discoverMediaSource, adventureMediaSource(for: adventure))
              .environment(\.discoverMediaLoader, adventureService)
          }
          .buttonStyle(.plain)
          .accessibilityIdentifier("discover.adventureCard.\(adventure.id)")
        }
      }
      .padding(.horizontal, 20)
    }
  }

  private var searchResultsContent: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 24) {
        if isLoadingSearch {
          ProgressView()
            .tint(HATheme.Colors.primary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .accessibilityIdentifier("discover.searchLoading")
        }

        if searchResults.people.isEmpty == false {
          searchSectionTitle("People")
            .accessibilityIdentifier("discover.search.peopleSection")

          VStack(spacing: 8) {
            ForEach(searchResults.people) { person in
              Button {
                onOpenProfile(person.handle)
              } label: {
                DiscoverPersonRow(person: person)
                  .environment(\.discoverMediaLoader, adventureService)
              }
              .buttonStyle(.plain)
              .accessibilityIdentifier("discover.personRow.\(person.id)")
            }
          }
        }

        if searchResults.adventures.isEmpty == false {
          searchSectionTitle("Adventures")
            .accessibilityIdentifier("discover.search.adventuresSection")

          VStack(spacing: 12) {
            ForEach(searchResults.adventures) { adventure in
              Button {
                onOpenDetail(adventure.id)
              } label: {
                DiscoverAdventureRow(adventure: adventure)
                  .environment(\.discoverMediaSource, adventureMediaSource(for: adventure))
                  .environment(\.discoverMediaLoader, adventureService)
              }
              .buttonStyle(.plain)
              .accessibilityIdentifier("discover.adventureRow.\(adventure.id)")
            }
          }
        }

        if searchResults.isEmpty {
          DiscoverEmptySearchState(
            title: model.emptyStateTitle,
            subtitle: model.emptyStateSubtitle,
            query: searchQuery
          )
          .padding(.top, 36)
          .accessibilityIdentifier("discover.search.emptyState")
        }
      }
      .padding(.horizontal, 20)
      .padding(.top, 12)
      .padding(.bottom, 24)
    }
    .accessibilityIdentifier("discover.searchScroll")
  }

  private func searchSectionTitle(_ title: String) -> some View {
    Text(title.uppercased())
      .font(.system(size: 12, weight: .semibold))
      .foregroundStyle(HATheme.Colors.mutedForeground)
  }

  private var loadingState: some View {
    VStack(spacing: 12) {
      ProgressView()
        .tint(HATheme.Colors.primary)
      Text("Loading Discover")
        .font(.system(size: 14, weight: .medium))
        .foregroundStyle(HATheme.Colors.mutedForeground)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .accessibilityIdentifier("discover.loading")
  }

  private func errorState(message: String) -> some View {
    VStack(spacing: 14) {
      Image(systemName: "wifi.exclamationmark")
        .font(.system(size: 34, weight: .medium))
        .foregroundStyle(HATheme.Colors.mutedForeground.opacity(0.65))

      Text("Discover is unavailable")
        .font(.system(size: 16, weight: .semibold))
        .foregroundStyle(HATheme.Colors.foreground)

      Text(message)
        .font(.system(size: 12, weight: .regular))
        .foregroundStyle(HATheme.Colors.mutedForeground)
        .multilineTextAlignment(.center)
        .lineLimit(3)

      Button {
        Task { await loadHome() }
      } label: {
        Text("Retry")
          .font(.system(size: 13, weight: .semibold))
          .foregroundStyle(.white)
          .padding(.horizontal, 18)
          .padding(.vertical, 10)
          .background(HATheme.Colors.primary)
          .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
      }
      .buttonStyle(.plain)
      .accessibilityIdentifier("discover.retry")
    }
    .padding(.horizontal, 28)
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .accessibilityIdentifier("discover.error")
  }

  private func loadHome() async {
    guard let discoverService else {
      return
    }

    isLoadingHome = true
    defer { isLoadingHome = false }

    do {
      model = try await discoverService.home()
      errorMessage = nil
    } catch {
      errorMessage = error.localizedDescription
    }
  }

  private func scheduleSearch() {
    searchTask?.cancel()
    searchTask = Task {
      try? await Task.sleep(nanoseconds: 250_000_000)
      guard Task.isCancelled == false else { return }
      await refreshSearchIfNeeded()
    }
  }

  private func refreshSearchIfNeeded() async {
    guard let discoverService else {
      return
    }

    let query = normalizedSearchQuery
    guard query.isEmpty == false else {
      remoteSearchResults = nil
      return
    }

    isLoadingSearch = true
    defer { isLoadingSearch = false }

    do {
      remoteSearchResults = try await discoverService.search(query: query, limit: 20, offset: 0)
      errorMessage = nil
    } catch {
      remoteSearchResults = DiscoverScreenModel.SearchResults(people: [], adventures: [], query: query)
      errorMessage = nil
    }
  }

  private func adventurerMediaSource(for adventurer: DiscoverScreenModel.Adventurer) -> HAMediaSource {
    if runtimeMode == .fixturePreview {
      return .fixture(adventurer.coverImageNames)
    }

    return .remote(adventurer.coverMediaIDs, adventureService)
  }

  private func adventureMediaSource(for adventure: DiscoverScreenModel.Adventure) -> HAMediaSource {
    if runtimeMode == .fixturePreview {
      return .fixture(adventure.imageNames)
    }

    return .remote(adventure.mediaIDs, adventureService)
  }
}

private struct DiscoverMediaSourceKey: EnvironmentKey {
  static let defaultValue: HAMediaSource = .fixture([])
}

private struct DiscoverMediaLoaderKey: EnvironmentKey {
  static let defaultValue: any AdventureService = FixtureAdventureService()
}

private extension EnvironmentValues {
  var discoverMediaSource: HAMediaSource {
    get { self[DiscoverMediaSourceKey.self] }
    set { self[DiscoverMediaSourceKey.self] = newValue }
  }

  var discoverMediaLoader: any AdventureService {
    get { self[DiscoverMediaLoaderKey.self] }
    set { self[DiscoverMediaLoaderKey.self] = newValue }
  }
}

private struct DiscoverSectionHeader: View {
  let title: String

  var body: some View {
    Text(title)
      .font(HATheme.Typography.sectionTitle)
      .foregroundStyle(HATheme.Colors.foreground)
      .padding(.horizontal, 20)
  }
}

private struct DiscoverAdventurerCard: View {
  let adventurer: DiscoverScreenModel.Adventurer
  @Environment(\.discoverMediaSource) private var mediaSource

  var body: some View {
    VStack(alignment: .leading, spacing: 0) {
      ZStack(alignment: .bottomLeading) {
        HAMediaCarouselOrPlaceholder(
          source: mediaSource,
          aspectRatio: nil,
          cornerRadius: 0,
          dotsInside: true,
          title: adventurer.name
        )
        .frame(height: 112)
        .overlay {
          LinearGradient(
            colors: [.clear, .black.opacity(0.50)],
            startPoint: .top,
            endPoint: .bottom
          )
        }

        HAAvatarView(
          initials: adventurer.initials,
          size: 48,
          background: HATheme.Colors.primary.opacity(0.16),
          foreground: HATheme.Colors.primary
        )
        .overlay {
          Circle()
            .stroke(HATheme.Colors.card, lineWidth: 2)
        }
        .offset(y: 24)
        .padding(.leading, 16)
      }
      .frame(height: 112)

      VStack(alignment: .leading, spacing: 7) {
        HStack(alignment: .top, spacing: 8) {
          VStack(alignment: .leading, spacing: 2) {
            Text(adventurer.name)
              .font(.system(size: 14, weight: .semibold))
              .foregroundStyle(HATheme.Colors.foreground)
              .lineLimit(1)

            Text(adventurer.displayHandle)
              .font(.system(size: 12, weight: .regular))
              .foregroundStyle(HATheme.Colors.mutedForeground)
              .lineLimit(1)
          }

          Spacer(minLength: 8)

          Text("\(adventurer.adventureCount) trips")
            .font(.system(size: 12, weight: .medium))
            .foregroundStyle(HATheme.Colors.mutedForeground)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(HATheme.Colors.secondary)
            .clipShape(Capsule(style: .continuous))
        }

        if let location = adventurer.location {
          HStack(spacing: 4) {
            Image(systemName: "mappin")
              .font(.system(size: 12, weight: .medium))

            Text(location)
              .lineLimit(1)
          }
          .font(.system(size: 12, weight: .regular))
          .foregroundStyle(HATheme.Colors.mutedForeground)
        }

        HStack(spacing: 5) {
          ForEach(adventurer.topCategories.prefix(2), id: \.self) { category in
            Text(category)
              .font(.system(size: 10, weight: .medium))
              .foregroundStyle(HATheme.Colors.primary)
              .lineLimit(1)
              .padding(.horizontal, 7)
              .padding(.vertical, 3)
              .background(HATheme.Colors.primary.opacity(0.10))
              .clipShape(Capsule(style: .continuous))
          }
        }
      }
      .padding(.top, 34)
      .padding(.horizontal, 16)
      .padding(.bottom, 14)
    }
    .frame(width: 256, alignment: .leading)
    .background(HATheme.Colors.card)
    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    .overlay {
      RoundedRectangle(cornerRadius: 16, style: .continuous)
        .stroke(HATheme.Colors.border, lineWidth: 1)
    }
    .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 2)
  }
}

private struct DiscoverAdventureCard: View {
  let adventure: DiscoverScreenModel.Adventure
  @Environment(\.discoverMediaSource) private var mediaSource

  var body: some View {
    VStack(spacing: 0) {
      ZStack(alignment: .topLeading) {
        HAMediaCarouselOrPlaceholder(
          source: mediaSource,
          aspectRatio: 4 / 3,
          cornerRadius: 0,
          dotsInside: true,
          title: adventure.title
        )
        .overlay {
          LinearGradient(
            colors: [.clear, .black.opacity(0.10), .black.opacity(0.65)],
            startPoint: .top,
            endPoint: .bottom
          )
        }

        Text(adventure.category)
          .font(.system(size: 10, weight: .medium))
          .foregroundStyle(HATheme.Colors.foreground)
          .padding(.horizontal, 9)
          .padding(.vertical, 4)
          .background(.white.opacity(0.90))
          .clipShape(Capsule(style: .continuous))
          .padding(10)

        VStack(alignment: .leading, spacing: 6) {
          Spacer()

          HStack(alignment: .bottom, spacing: 8) {
            VStack(alignment: .leading, spacing: 5) {
              Text(adventure.title)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.white)
                .lineLimit(2)
                .multilineTextAlignment(.leading)

              if let location = adventure.location {
                HStack(spacing: 4) {
                  Image(systemName: "mappin")
                    .font(.system(size: 12, weight: .medium))

                  Text(location)
                    .lineLimit(1)
                }
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(.white.opacity(0.78))
              }
            }

            Spacer(minLength: 8)

            if let rating = adventure.rating {
              HStack(spacing: 4) {
                Image(systemName: "star.fill")
                  .font(.system(size: 12, weight: .semibold))
                Text(String(format: "%.1f", rating))
              }
              .font(.system(size: 11, weight: .medium))
              .foregroundStyle(.white.opacity(0.88))
            }
          }
        }
        .padding(.horizontal, 12)
        .padding(.bottom, 22)
      }

      HStack(spacing: 8) {
        Text("by \(adventure.authorName)")
          .font(.system(size: 10, weight: .regular))
          .foregroundStyle(HATheme.Colors.mutedForeground)
          .lineLimit(1)

        Spacer()

        HStack(spacing: 4) {
          Image(systemName: "heart")
            .font(.system(size: 12, weight: .regular))
          Text(adventure.favoriteCount.formatted())
        }
        .font(.system(size: 10, weight: .regular))
        .foregroundStyle(HATheme.Colors.mutedForeground)
      }
      .padding(.horizontal, 12)
      .frame(height: 36)
    }
    .frame(width: 224)
    .background(HATheme.Colors.card)
    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    .overlay {
      RoundedRectangle(cornerRadius: 16, style: .continuous)
        .stroke(HATheme.Colors.border, lineWidth: 1)
    }
    .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 2)
  }
}

private struct DiscoverPersonRow: View {
  let person: DiscoverScreenModel.Adventurer

  var body: some View {
    HStack(spacing: 14) {
      HAAvatarView(
        initials: person.initials,
        size: 40,
        background: HATheme.Colors.primary.opacity(0.14),
        foreground: HATheme.Colors.primary
      )

      VStack(alignment: .leading, spacing: 3) {
        Text(person.name)
          .font(.system(size: 14, weight: .semibold))
          .foregroundStyle(HATheme.Colors.foreground)
          .lineLimit(1)

        Text(rowMeta(for: person))
          .font(.system(size: 12, weight: .regular))
          .foregroundStyle(HATheme.Colors.mutedForeground)
          .lineLimit(2)
      }

      Spacer(minLength: 12)

      Text("View")
        .font(.system(size: 12, weight: .semibold))
        .foregroundStyle(HATheme.Colors.primary)
        .padding(.horizontal, 12)
        .padding(.vertical, 7)
        .overlay {
          RoundedRectangle(cornerRadius: 12, style: .continuous)
            .stroke(HATheme.Colors.primary, lineWidth: 1)
        }
    }
    .padding(.horizontal, 16)
    .padding(.vertical, 13)
    .background(HATheme.Colors.card)
    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    .overlay {
      RoundedRectangle(cornerRadius: 16, style: .continuous)
        .stroke(HATheme.Colors.border, lineWidth: 1)
    }
    .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
  }

  private func rowMeta(for person: DiscoverScreenModel.Adventurer) -> String {
    if let location = person.location {
      return "\(person.displayHandle) - \(location)"
    }

    return person.displayHandle
  }
}

private struct DiscoverAdventureRow: View {
  let adventure: DiscoverScreenModel.Adventure
  @Environment(\.discoverMediaSource) private var mediaSource

  var body: some View {
    HStack(spacing: 14) {
      HAMediaCarouselOrPlaceholder(
        source: mediaSource,
        aspectRatio: nil,
        cornerRadius: 12,
        dotsInside: false,
        title: adventure.title
      )
        .frame(width: 56, height: 56)

      VStack(alignment: .leading, spacing: 5) {
        Text(adventure.title)
          .font(.system(size: 14, weight: .semibold))
          .foregroundStyle(HATheme.Colors.foreground)
          .lineLimit(2)
          .multilineTextAlignment(.leading)

        if let location = adventure.location {
          HStack(spacing: 4) {
            Image(systemName: "mappin")
              .font(.system(size: 12, weight: .medium))
            Text(location)
              .lineLimit(1)
          }
          .font(.system(size: 12, weight: .regular))
          .foregroundStyle(HATheme.Colors.mutedForeground)
        }
      }

      Spacer(minLength: 10)

      if let rating = adventure.rating {
        HStack(spacing: 4) {
          Image(systemName: "star.fill")
            .font(.system(size: 14, weight: .semibold))
            .foregroundStyle(HATheme.Colors.primary)
          Text(String(format: "%.1f", rating))
            .font(.system(size: 14, weight: .medium))
            .foregroundStyle(HATheme.Colors.foreground)
        }
      }
    }
    .padding(.horizontal, 14)
    .padding(.vertical, 13)
    .background(HATheme.Colors.card)
    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    .overlay {
      RoundedRectangle(cornerRadius: 16, style: .continuous)
        .stroke(HATheme.Colors.border, lineWidth: 1)
    }
    .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
  }
}

private struct DiscoverEmptySearchState: View {
  let title: String
  let subtitle: String
  let query: String

  var body: some View {
    VStack(spacing: 10) {
      Image(systemName: "binoculars")
        .font(.system(size: 34, weight: .medium))
        .foregroundStyle(HATheme.Colors.mutedForeground.opacity(0.5))

      Text("\(title) for \"\(query)\"")
        .font(.system(size: 14, weight: .semibold))
        .foregroundStyle(HATheme.Colors.foreground)
        .multilineTextAlignment(.center)

      Text(subtitle)
        .font(.system(size: 12, weight: .regular))
        .foregroundStyle(HATheme.Colors.mutedForeground)
        .multilineTextAlignment(.center)
    }
    .frame(maxWidth: .infinity)
  }
}

private struct DiscoverPreviewWrapper: View {
  let variant: DiscoverFixtureVariant

  var body: some View {
    DiscoverView(
      model: MockFixtures.discoverScreenModel(for: variant),
      initialSearchQuery: variant == .empty ? "zzzz" : "",
      discoverService: FixtureDiscoverService(variant: variant),
      adventureService: FixtureAdventureService(),
      runtimeMode: .fixturePreview,
      onOpenProfile: { _ in },
      onOpenDetail: { _ in }
    )
  }
}

struct DiscoverView_Previews: PreviewProvider {
  static var previews: some View {
    DiscoverPreviewWrapper(variant: .happy)
    DiscoverPreviewWrapper(variant: .longText)
    DiscoverPreviewWrapper(variant: .empty)
  }
}
