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
        LinearGradient(
          colors: [HATheme.Colors.accent, HATheme.Colors.primary],
          startPoint: .topLeading,
          endPoint: .bottomTrailing
        )
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
              Label(locationLabel, systemImage: "mappin.and.ellipse")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(.white.opacity(0.82))
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
        }

        HStack(spacing: 16) {
          stat(title: "Adventures", value: response?.adventures.count ?? 0)
          stat(title: "Saved", value: 0)
          stat(title: "Mode", value: runtimeMode == .fixturePreview ? "Preview" : "Live")
        }
      }
      .padding(.horizontal, 24)
      .padding(.top, 24)
    }
  }

  private func authoredSection(adventures: [AdventureCard]) -> some View {
    VStack(alignment: .leading, spacing: 16) {
      Text("Shared adventures")
        .font(HATheme.Typography.sectionTitle)
        .foregroundStyle(HATheme.Colors.foreground)
        .padding(.top, 8)
        .padding(.horizontal, 24)

      FeedView(
        items: adventures,
        scope: nil,
        adventureService: adventureService,
        runtimeMode: runtimeMode,
        onOpenDetail: onOpenDetail
      )
    }
  }

  private func stat<T: CustomStringConvertible>(title: String, value: T) -> some View {
    VStack(alignment: .leading, spacing: 4) {
      Text(value.description)
        .font(.system(size: 18, weight: .semibold))
        .foregroundStyle(HATheme.Colors.foreground)

      Text(title)
        .font(.system(size: 12, weight: .medium))
        .foregroundStyle(HATheme.Colors.mutedForeground)
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .padding(14)
    .background(HATheme.Colors.card)
    .clipShape(RoundedRectangle(cornerRadius: HATheme.Radius.card, style: .continuous))
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
    .task(id: mediaID) {
      await loadImage()
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

struct ProfileView_Previews: PreviewProvider {
  static var previews: some View {
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
