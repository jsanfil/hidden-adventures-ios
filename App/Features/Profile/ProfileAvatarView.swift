import SwiftUI
import UIKit

struct ProfileAvatarView: View {
  let initials: String
  let mediaID: String?
  let mediaLoader: any AdventureService

  var size: CGFloat = 78
  var background: Color = .white.opacity(0.18)
  var foreground: Color = .white
  var borderColor: Color? = .white.opacity(0.2)
  var borderWidth: CGFloat = 4
  var loadingTint: Color = .white

  @State private var image: UIImage?
  @State private var didFail = false

  var body: some View {
    Group {
      if let image {
        Image(uiImage: image)
          .resizable()
          .scaledToFill()
      } else if mediaID == nil || didFail {
        fallbackAvatar
      } else {
        loadingAvatar
      }
    }
    .frame(width: size, height: size)
    .clipShape(Circle())
    .overlay {
      if let borderColor {
        Circle()
          .stroke(borderColor, lineWidth: borderWidth)
      }
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
      size: size,
      background: background,
      foreground: foreground
    )
  }

  private var loadingAvatar: some View {
    ZStack {
      Circle()
        .fill(background)

      ProgressView()
        .tint(loadingTint)
    }
  }

  @MainActor
  private func loadImage(forceReload: Bool = false) async {
    if image != nil && forceReload == false {
      return
    }

    guard let mediaID else {
      image = nil
      didFail = false
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
