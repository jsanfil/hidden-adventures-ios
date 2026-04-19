import SwiftUI
import UIKit

struct ProfileView: View {
  private enum Layout {
    static let contentSectionSpacing: CGFloat = 18
    static let contentTopPadding: CGFloat = 14
  }

  @Environment(\.dismiss) private var dismiss

  let handle: String?
  let adventureService: AdventureService
  let profileService: ProfileService
  let sidekickService: SidekickService
  let runtimeMode: AppRuntimeMode
  let viewerHandle: String?
  let onProfileLoaded: (ProfileDetail) -> Void
  let onOpenProfile: (String) -> Void
  let onOpenDetail: (String) -> Void
  let onLogout: () -> Void

  @State private var response: ProfileResponse?
  @State private var isLoading = true
  @State private var errorMessage: String?
  @State private var sidekickSummaryItems: [SidekickListItem] = []
  @State private var isLoadingSidekickSummary = false

  var body: some View {
    ZStack {
      HATheme.Colors.background
        .ignoresSafeArea()

      if isLoading {
        ProgressView()
          .tint(HATheme.Colors.primary)
      } else if let errorMessage {
        errorState(message: errorMessage)
      } else if let response {
        ScrollView {
          VStack(spacing: 0) {
            header(profile: response.profile)
            authoredSection(adventures: response.adventures)
          }
          .padding(.bottom, 24)
        }
        .accessibilityIdentifier("profile.scroll")
      }
    }
    .task {
      guard response == nil, errorMessage == nil else { return }
      await loadProfile()
    }
    .toolbar(.hidden, for: .navigationBar)
  }

  private var showsSidekicksCard: Bool {
    guard let viewerHandle else { return false }
    guard let response else { return false }
    return response.profile.handle == viewerHandle
  }

  private var showsBackButton: Bool {
    guard let response else { return false }
    guard let viewerHandle else { return true }
    return response.profile.handle != viewerHandle
  }
    
    private func header(profile: ProfileDetail) -> some View {
      VStack(spacing: 0) {
        ZStack(alignment: .topLeading) {
          LinearGradient(
            gradient: Gradient(stops: [
              .init(color: Color(red: 0.56, green: 0.77, blue: 0.80), location: 0.0),
              .init(color: Color(red: 0.37, green: 0.65, blue: 0.61), location: 0.42),
              .init(color: HATheme.Colors.primary, location: 1.0)
            ]),
            startPoint: .leading,
            endPoint: .trailing
          )

          VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .center) {
              if showsBackButton {
                plainHeaderBackButton
              } else {
                Color.clear
                  .frame(width: 40, height: 40)
                  .accessibilityHidden(true)
              }

              Spacer(minLength: 0)

              if showsSidekicksCard {
                circularHeaderButton(
                  systemImage: "rectangle.portrait.and.arrow.right",
                  accessibilityID: "profile.logout",
                  action: onLogout
                )
              } else {
                Color.clear
                  .frame(width: 40, height: 40)
                  .accessibilityHidden(true)
              }
            }
            .padding(.horizontal, 24)
            .padding(.top, 12)

            HStack(alignment: .center, spacing: 16) {
              ProfileAvatarView(
                initials: initials(for: profile),
                mediaID: profile.avatar?.id,
                mediaLoader: adventureService,
                size: 80
              )

              VStack(alignment: .leading, spacing: 2) {
                Text(profile.displayName ?? profile.handle)
                  .font(.system(size: 28, weight: .semibold))
                  .foregroundStyle(.white)
                  .lineLimit(2)
                  .minimumScaleFactor(0.85)

                Text("@\(profile.handle)")
                  .font(.system(size: 16, weight: .semibold))
                  .foregroundStyle(.white.opacity(0.86))
                  .accessibilityIdentifier("profile.handle.readonly")

                if let locationLabel = locationLabel(for: profile) {
                  Label {
                    Text(locationLabel)
                  } icon: {
                    Image(systemName: "location.fill")
                  }
                  .font(.system(size: 16, weight: .medium))
                  .foregroundStyle(.white.opacity(0.80))
                }
              }
              .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.horizontal, 24)
            .padding(.top, 8)
            .padding(.bottom, 16)
          }
        }
        .frame(height: 172)

        VStack(alignment: .leading, spacing: Layout.contentSectionSpacing) {
          Group {
            if let bio = profile.bio, bio.isEmpty == false {
              Text(bio)
                .font(HATheme.Typography.body)
                .foregroundStyle(HATheme.Colors.mutedForeground)
                .lineSpacing(3)
                .accessibilityIdentifier("profile.bio.readonly")
            } else {
              Text("Add a bio during setup or come back later to tell other explorers what you love to find.")
                .font(HATheme.Typography.body)
                .foregroundStyle(HATheme.Colors.mutedForeground)
                .accessibilityIdentifier("profile.bio.placeholder")
            }
          }
          .fixedSize(horizontal: false, vertical: true)

          profileStatRow {
            profileStatItem(title: "Adventures", value: MockFixtures.profileStats.adventures, showsDivider: true)
            profileStatItem(title: "Likes", value: MockFixtures.profileStats.likesReceived, showsDivider: true)
            profileStatItem(title: "Views", value: MockFixtures.profileStats.views, showsDivider: false)
          }

          if showsSidekicksCard {
            NavigationLink {
              SidekicksView(
                sidekickService: sidekickService,
                adventureService: adventureService,
                onOpenProfile: onOpenProfile,
                onSidekicksChanged: {
                  Task {
                    await loadSidekickSummary()
                  }
                }
              )
            } label: {
              sidekicksCard
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("profile.sidekicksCard")
          }
        }
        .padding(.horizontal, 24)
        .padding(.top, Layout.contentTopPadding)
      }
    }
    
    private func circularHeaderButton(
    systemImage: String,
    accessibilityID: String,
    action: @escaping () -> Void
  ) -> some View {
    Button(action: action) {
      Image(systemName: systemImage)
        .font(.system(size: 16, weight: .semibold))
        .foregroundStyle(.white)
        .frame(width: 40, height: 40)
        .background(.white.opacity(0.16))
        .overlay {
          Circle()
            .stroke(.white.opacity(0.14), lineWidth: 1)
        }
        .clipShape(Circle())
    }
    .buttonStyle(.plain)
    .accessibilityIdentifier(accessibilityID)
  }

  private var plainHeaderBackButton: some View {
    Button(action: { dismiss() }) {
      Image(systemName: "chevron.left")
        .font(.system(size: 26, weight: .semibold))
        .foregroundStyle(.white)
        .frame(width: 40, height: 40, alignment: .leading)
        .contentShape(Rectangle())
    }
    .buttonStyle(.plain)
    .accessibilityIdentifier("profile.back")
  }

  private var sidekicksCard: some View {
    HStack(spacing: 14) {
      HStack(spacing: -8) {
        if isLoadingSidekickSummary && sidekickSummaryItems.isEmpty {
          ProgressView()
            .tint(HATheme.Colors.mutedForeground)
            .frame(width: 32, height: 32)
        } else {
          ForEach(Array(sidekickSummaryItems.prefix(5).enumerated()), id: \.element.id) { _, sidekick in
            ProfileAvatarView(
              initials: initials(for: sidekick.profile),
              mediaID: sidekick.profile.avatar?.id,
              mediaLoader: adventureService,
              size: 32,
              background: HATheme.Colors.primary.opacity(0.14),
              foreground: HATheme.Colors.primary,
              borderColor: HATheme.Colors.background,
              borderWidth: 2,
              loadingTint: HATheme.Colors.primary
            )
          }
        }

        if sidekickSummaryItems.count > 5 {
          Text("+\(sidekickSummaryItems.count - 5)")
            .font(.system(size: 12, weight: .semibold))
            .foregroundStyle(HATheme.Colors.mutedForeground)
            .frame(width: 32, height: 32)
            .background(HATheme.Colors.muted)
            .clipShape(Circle())
            .overlay {
              Circle()
                .stroke(HATheme.Colors.background, lineWidth: 2)
            }
        }
      }

      VStack(alignment: .leading, spacing: 4) {
        Text(sidekicksCardTitle)
          .font(.system(size: 18, weight: .semibold))
          .foregroundStyle(HATheme.Colors.foreground)

        Text("Manage your crew")
          .font(.system(size: 13, weight: .medium))
          .foregroundStyle(HATheme.Colors.mutedForeground)
      }

      Spacer()

      Image(systemName: "chevron.right")
        .font(.system(size: 16, weight: .semibold))
        .foregroundStyle(HATheme.Colors.mutedForeground)
    }
    .padding(.horizontal, 18)
    .padding(.vertical, 16)
    .background(HATheme.Colors.card)
    .overlay {
      RoundedRectangle(cornerRadius: 18, style: .continuous)
        .stroke(HATheme.Colors.border, lineWidth: 1)
    }
    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
  }

  private var sidekicksCardTitle: String {
    if isLoadingSidekickSummary && sidekickSummaryItems.isEmpty {
      return "Sidekicks"
    }

    return "\(sidekickSummaryItems.count) Sidekicks"
  }

  private func authoredSection(adventures: [AdventureCard]) -> some View {
    VStack(alignment: .leading, spacing: 16) {
      Text("Shared adventures")
        .font(.system(size: 20, weight: .semibold))
        .foregroundStyle(HATheme.Colors.foreground)
        .padding(.top, Layout.contentSectionSpacing)
        .padding(.horizontal, 24)
        .accessibilityIdentifier("profile.sharedAdventuresHeading")

      FeedView(
        items: adventures,
        scope: nil,
        adventureService: adventureService,
        runtimeMode: runtimeMode,
        onOpenDetail: onOpenDetail
      )
    }
  }

  private func profileStatRow<Content: View>(@ViewBuilder content: () -> Content) -> some View {
    HStack(spacing: 0) {
      content()
    }
    .padding(.vertical, 14)
    .padding(.horizontal, 10)
    .background(HATheme.Colors.card)
    .overlay {
      RoundedRectangle(cornerRadius: 24, style: .continuous)
        .stroke(HATheme.Colors.border.opacity(0.55), lineWidth: 1)
    }
    .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
    .shadow(color: HATheme.Colors.shadow.opacity(0.08), radius: 10, x: 0, y: 3)
  }

  private func profileStatItem<T: CustomStringConvertible>(
    title: String,
    value: T,
    showsDivider: Bool
  ) -> some View {
    VStack(spacing: 8) {
      Text(value.description)
        .font(.system(size: 26, weight: .semibold))
        .monospacedDigit()
        .foregroundStyle(HATheme.Colors.foreground)

      Text(title)
        .font(.system(size: 13, weight: .medium))
        .foregroundStyle(HATheme.Colors.mutedForeground)
        .multilineTextAlignment(.center)
    }
    .frame(maxWidth: .infinity)
    .overlay(alignment: .trailing) {
      if showsDivider {
        Rectangle()
          .fill(HATheme.Colors.border.opacity(0.55))
          .frame(width: 1)
          .padding(.vertical, 10)
      }
    }
    .accessibilityElement(children: .combine)
    .accessibilityIdentifier("profile.stat.\(title.lowercased().replacingOccurrences(of: " ", with: "-"))")
  }

  private func errorState(message: String) -> some View {
    VStack(spacing: 14) {
      Image(systemName: "person.crop.circle.badge.exclamationmark")
        .font(.system(size: 32, weight: .medium))
        .foregroundStyle(HATheme.Colors.primary)

      Text("We couldn't load this profile.")
        .font(HATheme.Typography.sectionTitle)
        .foregroundStyle(HATheme.Colors.foreground)

      Text(message)
        .font(HATheme.Typography.body)
        .foregroundStyle(HATheme.Colors.mutedForeground)
        .multilineTextAlignment(.center)
    }
    .padding(24)
  }

  @MainActor
  private func loadProfile() async {
    guard let handle else {
      errorMessage = "A linked handle is required before the live profile path can load."
      isLoading = false
      return
    }

    do {
      let response = try await profileService.getProfile(handle: handle, limit: 20, offset: 0)
      self.response = response
      onProfileLoaded(response.profile)
      isLoading = false

      if showsSidekicksCard {
        await loadSidekickSummary()
      }
      return
    } catch {
      errorMessage = error.localizedDescription
    }

    isLoading = false
  }

  @MainActor
  private func loadSidekickSummary() async {
    guard showsSidekicksCard else {
      sidekickSummaryItems = []
      isLoadingSidekickSummary = false
      return
    }

    isLoadingSidekickSummary = true
    defer { isLoadingSidekickSummary = false }

    do {
      let summary = try await sidekickService.getMySidekicks(limit: 50, offset: 0)
      sidekickSummaryItems = summary.items
    } catch {
      sidekickSummaryItems = []
    }
  }

  private func initials(for profile: ProfileDetail) -> String {
    let source = profile.displayName ?? profile.handle
    let letters = source
      .split(separator: " ")
      .prefix(2)
      .compactMap(\.first)
      .map { String($0).uppercased() }
      .joined()

    return letters.isEmpty ? "HA" : letters
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

  private func locationLabel(for profile: ProfileDetail) -> String? {
    switch (profile.homeCity, profile.homeRegion) {
    case let (city?, region?) where city.isEmpty == false && region.isEmpty == false:
      return "\(city), \(region)"
    case let (city?, _) where city.isEmpty == false:
      return city
    case let (_, region?) where region.isEmpty == false:
      return region
    default:
      return nil
    }
  }

  private func locationLabel(for profile: SidekickProfileSummary) -> String? {
    switch (profile.homeCity, profile.homeRegion) {
    case let (city?, region?) where city.isEmpty == false && region.isEmpty == false:
      return "\(city), \(region)"
    case let (city?, _) where city.isEmpty == false:
      return city
    case let (_, region?) where region.isEmpty == false:
      return region
    default:
      return nil
    }
  }
}

struct ProfileView_Previews: PreviewProvider {
  static var previews: some View {
    NavigationStack {
      ProfileView(
        handle: MockFixtures.profile.handle,
        adventureService: FixtureAdventureService(),
        profileService: FixtureProfileService(),
        sidekickService: FixtureSidekickService(),
        runtimeMode: .fixturePreview,
        viewerHandle: MockFixtures.profile.handle,
        onProfileLoaded: { _ in },
        onOpenProfile: { _ in },
        onOpenDetail: { _ in },
        onLogout: {}
      )
    }
  }
}
