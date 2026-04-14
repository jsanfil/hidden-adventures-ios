import SwiftUI

struct SidekicksView: View {
  private enum LoadTarget: Hashable {
    case mySidekicks
    case discover
    case search(String)
  }

  let sidekickService: SidekickService
  let adventureService: AdventureService
  let onSidekicksChanged: () -> Void

  @Environment(\.dismiss) private var dismiss
  @FocusState private var isSearchFocused: Bool
  @State private var selectedTab: SidekicksTab = .mySidekicks
  @State private var searchText = ""
  @State private var mySidekicks: [SidekickListItem] = []
  @State private var discoverUsers: [SidekickListItem] = []
  @State private var searchUsers: [SidekickListItem] = []
  @State private var isLoadingCurrentTab = true
  @State private var errorMessage: String?
  @State private var pendingRemovalHandle: String?
  @State private var inFlightHandle: String?

  init(
    sidekickService: SidekickService = FixtureSidekickService(),
    adventureService: AdventureService = FixtureAdventureService(),
    onSidekicksChanged: @escaping () -> Void = {}
  ) {
    self.sidekickService = sidekickService
    self.adventureService = adventureService
    self.onSidekicksChanged = onSidekicksChanged
  }

  var body: some View {
    ZStack(alignment: .top) {
      HATheme.Colors.background
        .ignoresSafeArea()

      VStack(spacing: 0) {
        header
        searchField
          .padding(.horizontal, 20)
          .padding(.top, 18)

        HASegmentedControl(options: SidekicksTab.allCases, selection: $selectedTab)
          .padding(.horizontal, 20)
          .padding(.top, 16)
          .accessibilityIdentifier("sidekicks.segmented")

        ScrollView {
          LazyVStack(spacing: 18) {
            if isLoadingCurrentTab && displayedUsers.isEmpty {
              loadingState
                .padding(.top, 48)
            } else if let errorMessage {
              errorState(message: errorMessage)
                .padding(.top, 48)
            } else if displayedUsers.isEmpty {
              emptyState
                .padding(.top, 48)
            } else {
              ForEach(displayedUsers) { user in
                sidekickRow(for: user)
              }
            }
          }
          .padding(.horizontal, 20)
          .padding(.top, 22)
          .padding(.bottom, 120)
        }
        .overlay(alignment: .top) {
          if isLoadingCurrentTab && displayedUsers.isEmpty == false {
            ProgressView()
              .tint(HATheme.Colors.primary)
              .padding(.top, 10)
          }
        }
        .accessibilityIdentifier("sidekicks.scroll")
      }
    }
    .safeAreaInset(edge: .bottom) {
      footer
    }
    .navigationBarBackButtonHidden(true)
    .toolbar(.hidden, for: .navigationBar)
    .task(id: loadTarget) {
      await loadCurrentTabContent()
    }
    .onChange(of: selectedTab) {
      searchText = ""
      pendingRemovalHandle = nil
      isSearchFocused = false
    }
  }

  private var loadTarget: LoadTarget {
    switch selectedTab {
    case .mySidekicks:
      return .mySidekicks
    case .findUsers:
      let query = trimmedSearchText
      return query.isEmpty ? .discover : .search(query)
    }
  }

  private var trimmedSearchText: String {
    searchText.trimmingCharacters(in: .whitespacesAndNewlines)
  }

  private var currentSidekicksCount: Int {
    mySidekicks.filter { $0.relationship.isSidekick }.count
  }

  private var displayedUsers: [SidekickListItem] {
    switch selectedTab {
    case .mySidekicks:
      guard trimmedSearchText.isEmpty == false else {
        return mySidekicks
      }

      return mySidekicks.filter { item in
        matchesSearch(item, query: trimmedSearchText)
      }
    case .findUsers:
      if trimmedSearchText.isEmpty {
        return discoverUsers
      }

      return searchUsers
    }
  }

  private var header: some View {
    HStack(spacing: 16) {
      Button {
        dismiss()
      } label: {
        Image(systemName: "chevron.left")
          .font(.system(size: 22, weight: .medium))
          .foregroundStyle(HATheme.Colors.foreground)
          .frame(width: 48, height: 48)
          .background(HATheme.Colors.secondary)
          .clipShape(Circle())
      }
      .buttonStyle(.plain)
      .accessibilityIdentifier("sidekicks.back")

      VStack(alignment: .leading, spacing: 4) {
        Text("Sidekicks")
          .font(.system(size: 26, weight: .semibold))
          .foregroundStyle(HATheme.Colors.foreground)

        Text("\(currentSidekicksCount) connections")
          .font(.system(size: 14, weight: .medium))
          .foregroundStyle(HATheme.Colors.mutedForeground)
          .accessibilityIdentifier("sidekicks.connectionCount")
      }

      Spacer()
    }
    .padding(.horizontal, 20)
    .padding(.top, 60)
  }

  private var searchField: some View {
    HStack(spacing: 12) {
      Image(systemName: "magnifyingglass")
        .font(.system(size: 18, weight: .medium))
        .foregroundStyle(HATheme.Colors.mutedForeground)

      TextField(searchPlaceholder, text: $searchText)
        .font(HATheme.Typography.body)
        .foregroundStyle(HATheme.Colors.foreground)
        .textInputAutocapitalization(.never)
        .disableAutocorrection(true)
        .focused($isSearchFocused)
        .accessibilityIdentifier("sidekicks.searchField")
    }
    .padding(.horizontal, 18)
    .frame(height: 56)
    .background(HATheme.Colors.secondary)
    .overlay {
      RoundedRectangle(cornerRadius: 20, style: .continuous)
        .stroke(isSearchFocused ? HATheme.Colors.primary.opacity(0.45) : HATheme.Colors.secondary, lineWidth: 2)
    }
    .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
  }

  private var searchPlaceholder: String {
    switch selectedTab {
    case .mySidekicks:
      return "Search your sidekicks..."
    case .findUsers:
      return "Search all users..."
    }
  }

  private func sidekickRow(for user: SidekickListItem) -> some View {
    let handle = user.profile.handle
    let isSidekick = user.relationship.isSidekick
    let isPendingRemoval = pendingRemovalHandle == handle
    let isBusy = inFlightHandle == handle

    return HStack(spacing: 16) {
      ProfileAvatarView(
        initials: initials(for: user.profile),
        mediaID: user.profile.avatar?.id,
        mediaLoader: adventureService,
        size: 48,
        background: HATheme.Colors.primary.opacity(0.14),
        foreground: HATheme.Colors.primary,
        borderColor: nil,
        borderWidth: 0,
        loadingTint: HATheme.Colors.primary
      )

      VStack(alignment: .leading, spacing: 2) {
        Text(user.profile.displayName ?? handle)
          .font(.system(size: 18, weight: .medium))
          .foregroundStyle(HATheme.Colors.foreground)
          .lineLimit(1)

        Text("@\(handle)")
          .font(.system(size: 14, weight: .medium))
          .foregroundStyle(HATheme.Colors.mutedForeground)

        Text("\(locationLabel(for: user.profile)) · \(user.stats.adventuresCount) adventures")
          .font(.system(size: 14, weight: .medium))
          .foregroundStyle(HATheme.Colors.mutedForeground)
          .lineLimit(1)
      }

      Spacer(minLength: 12)

      if isBusy {
        ProgressView()
          .tint(HATheme.Colors.primary)
          .frame(width: 42, height: 42)
      } else if isPendingRemoval {
        HStack(spacing: 8) {
          Button {
            confirmRemoval(for: handle)
          } label: {
            Image(systemName: "checkmark.circle.fill")
              .font(.system(size: 24))
              .foregroundStyle(HATheme.Colors.primary)
          }
          .buttonStyle(.plain)
          .accessibilityIdentifier("sidekicks.confirmRemove.\(handle)")

          Button {
            pendingRemovalHandle = nil
          } label: {
            Image(systemName: "xmark.circle.fill")
              .font(.system(size: 24))
              .foregroundStyle(HATheme.Colors.mutedForeground)
          }
          .buttonStyle(.plain)
          .accessibilityIdentifier("sidekicks.cancelRemove.\(handle)")
        }
      } else if isSidekick {
        sidekickActionButton(
          title: "Remove",
          systemImage: "person.badge.minus",
          fill: HATheme.Colors.secondary,
          foreground: HATheme.Colors.mutedForeground,
          identifier: "sidekicks.remove.\(handle)"
        ) {
          pendingRemovalHandle = handle
        }
      } else {
        sidekickActionButton(
          title: "Add",
          systemImage: "person.badge.plus",
          fill: HATheme.Colors.primary,
          foreground: .white,
          identifier: "sidekicks.add.\(handle)"
        ) {
          Task {
            await addSidekick(handle: handle)
          }
        }
      }
    }
    .padding(.horizontal, 16)
    .padding(.vertical, 18)
    .background(HATheme.Colors.card)
    .overlay {
      RoundedRectangle(cornerRadius: 24, style: .continuous)
        .stroke(isPendingRemoval ? HATheme.Colors.primary.opacity(0.28) : HATheme.Colors.border, lineWidth: 1)
    }
    .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
    .accessibilityElement(children: .contain)
    .accessibilityIdentifier("sidekicks.row.\(handle)")
  }

  private func sidekickActionButton(
    title: String,
    systemImage: String,
    fill: Color,
    foreground: Color,
    identifier: String,
    action: @escaping () -> Void
  ) -> some View {
    Button(action: action) {
      Label(title, systemImage: systemImage)
        .font(.system(size: 14, weight: .medium))
        .foregroundStyle(foreground)
        .padding(.horizontal, 16)
        .frame(height: 42)
        .background(fill)
        .clipShape(Capsule(style: .continuous))
    }
    .buttonStyle(.plain)
    .accessibilityIdentifier(identifier)
  }

  private func confirmRemoval(for handle: String) {
    Task {
      await removeSidekick(handle: handle)
    }
  }

  @ViewBuilder
  private var emptyState: some View {
    if trimmedSearchText.isEmpty == false {
      ContentUnavailableView.search(text: trimmedSearchText)
        .accessibilityIdentifier("sidekicks.empty.search")
    } else if selectedTab == .mySidekicks {
      ContentUnavailableView {
        Label("No sidekicks yet", systemImage: "person.2.slash")
      } description: {
        Text("Add sidekicks to share your adventures with them")
      }
      .accessibilityIdentifier("sidekicks.empty.mySidekicks")
    } else {
      ContentUnavailableView {
        Label("No users available", systemImage: "person.3")
      } description: {
        Text("Check back later for more users to connect with")
      }
      .accessibilityIdentifier("sidekicks.empty.findUsers")
    }
  }

  private func errorState(message: String) -> some View {
    VStack(spacing: 14) {
      Image(systemName: "person.crop.circle.badge.exclamationmark")
        .font(.system(size: 32, weight: .medium))
        .foregroundStyle(HATheme.Colors.primary)

      Text("We couldn't load sidekicks right now.")
        .font(HATheme.Typography.sectionTitle)
        .foregroundStyle(HATheme.Colors.foreground)

      Text(message)
        .font(HATheme.Typography.body)
        .foregroundStyle(HATheme.Colors.mutedForeground)
        .multilineTextAlignment(.center)
    }
    .padding(24)
  }

  private var loadingState: some View {
    VStack(spacing: 12) {
      ProgressView()
        .tint(HATheme.Colors.primary)

      Text("Loading sidekicks...")
        .font(.system(size: 14, weight: .medium))
        .foregroundStyle(HATheme.Colors.mutedForeground)
    }
    .frame(maxWidth: .infinity)
    .padding(.vertical, 32)
  }

  private var footer: some View {
    Text("Sidekicks can view your \"Sidekicks-only\" adventures. They cannot edit or delete them.")
      .font(.system(size: 14, weight: .medium))
      .foregroundStyle(HATheme.Colors.mutedForeground)
      .multilineTextAlignment(.center)
      .frame(maxWidth: .infinity)
      .padding(.horizontal, 24)
      .padding(.vertical, 18)
      .background(HATheme.Colors.background)
      .overlay(alignment: .top) {
        Rectangle()
          .fill(HATheme.Colors.border)
          .frame(height: 1)
      }
      .accessibilityIdentifier("sidekicks.footer")
  }

  @MainActor
  private func loadCurrentTabContent() async {
    let target = loadTarget
    isLoadingCurrentTab = true
    errorMessage = nil
    pendingRemovalHandle = nil

    do {
      switch target {
      case .mySidekicks:
        mySidekicks = try await sidekickService.getMySidekicks(limit: 50, offset: 0).items
      case .discover:
        discoverUsers = try await sidekickService.getDiscoveredProfiles(limit: 50, offset: 0).items
      case .search(let query):
        if query.isEmpty == false {
          try? await Task.sleep(nanoseconds: 250_000_000)
        }

        guard Task.isCancelled == false else {
          isLoadingCurrentTab = false
          return
        }

        searchUsers = try await sidekickService.searchProfiles(query: query, limit: 50, offset: 0).items
      }
    } catch {
      guard Task.isCancelled == false else {
        isLoadingCurrentTab = false
        return
      }

      errorMessage = error.localizedDescription
      switch target {
      case .mySidekicks:
        mySidekicks = []
      case .discover:
        discoverUsers = []
      case .search:
        searchUsers = []
      }
    }

    isLoadingCurrentTab = false
  }

  @MainActor
  private func refreshCachesAfterMutation() async {
    do {
      errorMessage = nil
      mySidekicks = try await sidekickService.getMySidekicks(limit: 50, offset: 0).items
      if selectedTab != .mySidekicks {
        await loadCurrentTabContentWithoutSpinner()
      }

      onSidekicksChanged()
    } catch {
      errorMessage = error.localizedDescription
    }
  }

  @MainActor
  private func loadCurrentTabContentWithoutSpinner() async {
    let target = loadTarget

    do {
      errorMessage = nil
      switch target {
      case .mySidekicks:
        mySidekicks = try await sidekickService.getMySidekicks(limit: 50, offset: 0).items
      case .discover:
        discoverUsers = try await sidekickService.getDiscoveredProfiles(limit: 50, offset: 0).items
      case .search(let query):
        if query.isEmpty == false {
          searchUsers = try await sidekickService.searchProfiles(query: query, limit: 50, offset: 0).items
        } else {
          discoverUsers = try await sidekickService.getDiscoveredProfiles(limit: 50, offset: 0).items
        }
      }
    } catch {
      guard Task.isCancelled == false else {
        return
      }

      errorMessage = error.localizedDescription
    }
  }

  @MainActor
  private func addSidekick(handle: String) async {
    guard inFlightHandle == nil else { return }
    inFlightHandle = handle
    defer {
      inFlightHandle = nil
    }

    do {
      _ = try await sidekickService.addSidekick(handle: handle)
      pendingRemovalHandle = nil
      await refreshCachesAfterMutation()
    } catch {
      errorMessage = error.localizedDescription
    }
  }

  @MainActor
  private func removeSidekick(handle: String) async {
    guard inFlightHandle == nil else { return }
    inFlightHandle = handle
    defer {
      inFlightHandle = nil
    }

    do {
      _ = try await sidekickService.removeSidekick(handle: handle)
      pendingRemovalHandle = nil
      await refreshCachesAfterMutation()
    } catch {
      errorMessage = error.localizedDescription
    }
  }

  private func initials(for profile: SidekickProfileSummary) -> String {
    let source = profile.displayName ?? profile.handle
    let letters = source
      .split(separator: " ")
      .prefix(2)
      .compactMap(\.first)
      .map { String($0).uppercased() }
      .joined()

    return letters.isEmpty ? "HA" : letters
  }

  private func locationLabel(for profile: SidekickProfileSummary) -> String {
    switch (profile.homeCity, profile.homeRegion) {
    case let (city?, region?) where city.isEmpty == false && region.isEmpty == false:
      return "\(city), \(region)"
    case let (city?, _) where city.isEmpty == false:
      return city
    case let (_, region?) where region.isEmpty == false:
      return region
    default:
      return "Somewhere out there"
    }
  }

  private func matchesSearch(_ user: SidekickListItem, query: String) -> Bool {
    user.profile.handle.localizedCaseInsensitiveContains(query)
      || user.profile.displayName?.localizedCaseInsensitiveContains(query) == true
      || user.profile.homeCity?.localizedCaseInsensitiveContains(query) == true
      || user.profile.homeRegion?.localizedCaseInsensitiveContains(query) == true
  }
}

struct SidekicksView_Previews: PreviewProvider {
  static var previews: some View {
    NavigationStack {
      SidekicksView(
        sidekickService: FixtureSidekickService(),
        adventureService: FixtureAdventureService(),
        onSidekicksChanged: {}
      )
    }
  }
}
