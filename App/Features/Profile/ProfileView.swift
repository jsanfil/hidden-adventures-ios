import SwiftUI
import UIKit

struct ProfileView: View {
  let handle: String?
  let adventureService: AdventureService
  let profileService: ProfileService
  let runtimeMode: AppRuntimeMode
  let onProfileLoaded: (ProfileDetail) -> Void
  let onOpenDetail: (String) -> Void
  let onLogout: () -> Void

  @State private var response: ProfileResponse?
  @State private var isLoading = true
  @State private var errorMessage: String?

  private let stats = MockFixtures.profileStats
  private let sidekickPreviews = MockFixtures.sidekickPreviews
  private let sidekickUsers = MockFixtures.sidekickUsers
  private let initialSidekickIDs = MockFixtures.initialSidekickIDs

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

  private func header(profile: ProfileDetail) -> some View {
    VStack(spacing: 0) {
      ZStack(alignment: .bottomLeading) {
        Rectangle()
          .fill(Color(red: 0.353, green: 0.541, blue: 0.478))
          .frame(height: 220)
          .overlay(alignment: .top) {
            HAStatusBarSpacer()
          }
          .overlay(alignment: .topTrailing) {
            Button(action: onLogout) {
              Image(systemName: "rectangle.portrait.and.arrow.right")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 40, height: 40)
                .background(.white.opacity(0.18))
                .clipShape(Circle())
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("profile.logout")
            .padding(.top, 12)
            .padding(.trailing, 16)
          }

        VStack(alignment: .leading, spacing: 14) {
          ProfileAvatarView(
            initials: initials(for: profile),
            mediaID: profile.avatar?.id,
            mediaLoader: adventureService
          )

          VStack(alignment: .leading, spacing: 6) {
            Text(profile.displayName ?? profile.handle)
              .font(.system(size: 28, weight: .semibold))
              .foregroundStyle(.white)

            Text("@\(profile.handle)")
              .font(.system(size: 14, weight: .medium))
              .foregroundStyle(.white.opacity(0.82))
              .accessibilityIdentifier("profile.handle.readonly")

            if let locationLabel = locationLabel(for: profile) {
              Label(locationLabel, systemImage: "location.fill")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(.white.opacity(0.74))
            }
          }
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 26)
        .frame(maxWidth: .infinity, alignment: .leading)
      }

      VStack(alignment: .leading, spacing: 20) {
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

        HStack(spacing: 12) {
          profileStatCard(title: "Adventures", value: stats.adventures)
          profileStatCard(title: "Likes Received", value: stats.likesReceived)
          profileStatCard(title: "Views", value: stats.views)
        }

        NavigationLink {
          SidekicksView(
            allUsers: sidekickUsers,
            initialSidekickIDs: initialSidekickIDs
          )
        } label: {
          sidekicksCard
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("profile.sidekicksCard")
      }
      .padding(.horizontal, 24)
      .padding(.top, 24)
    }
  }

  private var sidekicksCard: some View {
    HStack(spacing: 14) {
      HStack(spacing: -8) {
        ForEach(Array(sidekickPreviews.prefix(5).enumerated()), id: \.element.id) { _, sidekick in
          HAAvatarView(
            initials: sidekick.initials,
            size: 32,
            background: HATheme.Colors.primary.opacity(0.14),
            foreground: HATheme.Colors.primary
          )
          .overlay {
            Circle()
              .stroke(HATheme.Colors.background, lineWidth: 2)
          }
        }

        if sidekickPreviews.count > 5 {
          Text("+\(sidekickPreviews.count - 5)")
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
        Text("\(initialSidekickIDs.count) Sidekicks")
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

  private func authoredSection(adventures: [AdventureCard]) -> some View {
    VStack(alignment: .leading, spacing: 16) {
      Text("Shared adventures")
        .font(.system(size: 20, weight: .semibold))
        .foregroundStyle(HATheme.Colors.foreground)
        .padding(.top, 8)
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

  private func profileStatCard<T: CustomStringConvertible>(title: String, value: T) -> some View {
    VStack(spacing: 8) {
      Text(value.description)
        .font(.system(size: 20, weight: .semibold))
        .foregroundStyle(HATheme.Colors.foreground)

      Text(title)
        .font(.system(size: 11, weight: .medium))
        .foregroundStyle(HATheme.Colors.mutedForeground)
        .multilineTextAlignment(.center)
        .frame(maxWidth: .infinity)
    }
    .frame(maxWidth: .infinity, minHeight: 96)
    .padding(.horizontal, 12)
    .background(HATheme.Colors.card)
    .overlay {
      RoundedRectangle(cornerRadius: 18, style: .continuous)
        .stroke(HATheme.Colors.border, lineWidth: 1)
    }
    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
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
    } catch {
      errorMessage = error.localizedDescription
    }

    isLoading = false
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
}

private struct ProfileAvatarView: View {
  let initials: String
  let mediaID: String?
  let mediaLoader: any AdventureService

  var body: some View {
    if let mediaID {
      ProfileRemoteAvatarImage(
        mediaID: mediaID,
        mediaLoader: mediaLoader,
        initials: initials
      )
    } else {
      fallbackAvatar
    }
  }

  private var fallbackAvatar: some View {
    HAAvatarView(
      initials: initials,
      size: 78,
      background: .white.opacity(0.18),
      foreground: .white
    )
    .overlay {
      Circle()
        .stroke(.white.opacity(0.2), lineWidth: 4)
    }
  }
}

private struct ProfileRemoteAvatarImage: View {
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
        fallbackAvatar
      } else {
        ZStack {
          Circle()
            .fill(.white.opacity(0.18))

          ProgressView()
            .tint(.white)
        }
      }
    }
    .frame(width: 78, height: 78)
    .clipShape(Circle())
    .overlay {
      Circle()
        .stroke(.white.opacity(0.2), lineWidth: 4)
    }
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

  private var fallbackAvatar: some View {
    HAAvatarView(
      initials: initials,
      size: 78,
      background: .white.opacity(0.18),
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

struct ProfileView_Previews: PreviewProvider {
  static var previews: some View {
    NavigationStack {
      ProfileView(
        handle: MockFixtures.profile.handle,
        adventureService: FixtureAdventureService(),
        profileService: FixtureProfileService(),
        runtimeMode: .fixturePreview,
        onProfileLoaded: { _ in },
        onOpenDetail: { _ in },
        onLogout: {}
      )
    }
  }
}
