import SwiftUI

struct SidekicksView: View {
  let allUsers: [SidekickUser]
  let initialSidekickIDs: Set<String>

  @Environment(\.dismiss) private var dismiss
  @FocusState private var isSearchFocused: Bool
  @State private var selectedTab: SidekicksTab = .mySidekicks
  @State private var searchText = ""
  @State private var sidekickIDs: Set<String>
  @State private var pendingRemovalID: String?

  init(
    allUsers: [SidekickUser] = MockFixtures.sidekickUsers,
    initialSidekickIDs: Set<String> = MockFixtures.initialSidekickIDs
  ) {
    self.allUsers = allUsers
    self.initialSidekickIDs = initialSidekickIDs
    _sidekickIDs = State(initialValue: initialSidekickIDs)
    _pendingRemovalID = State(initialValue: nil)
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
            if displayedUsers.isEmpty {
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
        .accessibilityIdentifier("sidekicks.scroll")
      }
    }
    .safeAreaInset(edge: .bottom) {
      footer
    }
    .navigationBarBackButtonHidden(true)
    .toolbar(.hidden, for: .navigationBar)
    .onChange(of: selectedTab) {
      searchText = ""
      pendingRemovalID = nil
      isSearchFocused = false
    }
  }

  private var currentSidekicks: [SidekickUser] {
    allUsers.filter { sidekickIDs.contains($0.id) }
  }

  private var displayedUsers: [SidekickUser] {
    let source: [SidekickUser]
    switch selectedTab {
    case .mySidekicks:
      source = currentSidekicks
    case .findUsers:
      source = allUsers
    }

    let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
    guard query.isEmpty == false else { return source }

    return source.filter { user in
      user.name.localizedCaseInsensitiveContains(query) ||
      user.handle.localizedCaseInsensitiveContains(query)
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

        Text("\(currentSidekicks.count) connections")
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

  private func sidekickRow(for user: SidekickUser) -> some View {
    let isSidekick = sidekickIDs.contains(user.id)
    let isPendingRemoval = pendingRemovalID == user.id

    return HStack(spacing: 16) {
      HAAvatarView(
        initials: user.initials,
        size: 48,
        background: HATheme.Colors.primary.opacity(0.14),
        foreground: HATheme.Colors.primary
      )

      VStack(alignment: .leading, spacing: 2) {
        Text(user.name)
          .font(.system(size: 18, weight: .medium))
          .foregroundStyle(HATheme.Colors.foreground)
          .lineLimit(1)

        Text("@\(user.handle)")
          .font(.system(size: 14, weight: .medium))
          .foregroundStyle(HATheme.Colors.mutedForeground)

        Text("\(user.location) · \(user.adventuresCount) adventures")
          .font(.system(size: 14, weight: .medium))
          .foregroundStyle(HATheme.Colors.mutedForeground)
      }

      Spacer(minLength: 12)

      if isPendingRemoval {
        HStack(spacing: 8) {
          Button {
            confirmRemoval(for: user.id)
          } label: {
            Image(systemName: "checkmark.circle.fill")
              .font(.system(size: 24))
              .foregroundStyle(HATheme.Colors.primary)
          }
          .buttonStyle(.plain)
          .accessibilityIdentifier("sidekicks.confirmRemove.\(user.handle)")

          Button {
            pendingRemovalID = nil
          } label: {
            Image(systemName: "xmark.circle.fill")
              .font(.system(size: 24))
              .foregroundStyle(HATheme.Colors.mutedForeground)
          }
          .buttonStyle(.plain)
          .accessibilityIdentifier("sidekicks.cancelRemove.\(user.handle)")
        }
      } else if isSidekick {
        sidekickActionButton(
          title: "Remove",
          systemImage: "person.badge.minus",
          fill: HATheme.Colors.secondary,
          foreground: HATheme.Colors.mutedForeground,
          identifier: "sidekicks.remove.\(user.handle)"
        ) {
          pendingRemovalID = user.id
        }
      } else {
        sidekickActionButton(
          title: "Add",
          systemImage: "person.badge.plus",
          fill: HATheme.Colors.primary,
          foreground: .white,
          identifier: "sidekicks.add.\(user.handle)"
        ) {
          sidekickIDs.insert(user.id)
          pendingRemovalID = nil
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
    .accessibilityIdentifier("sidekicks.row.\(user.handle)")
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

  private func confirmRemoval(for userID: String) {
    sidekickIDs.remove(userID)
    pendingRemovalID = nil
  }

  @ViewBuilder
  private var emptyState: some View {
    if searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false {
      ContentUnavailableView.search(text: searchText)
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
}

struct SidekicksView_Previews: PreviewProvider {
  static var previews: some View {
    NavigationStack {
      SidekicksView()
    }
  }
}
