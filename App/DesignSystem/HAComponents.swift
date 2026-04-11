import SwiftUI

struct HAPrimaryButton: View {
  let title: String
  let action: () -> Void

  var body: some View {
    Button(action: action) {
      Text(title)
        .font(HATheme.Typography.bodyMedium)
        .foregroundStyle(.white)
        .frame(maxWidth: .infinity)
        .frame(height: 56)
        .background(HATheme.Colors.primary)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
    .buttonStyle(.plain)
  }
}

struct HAChip: View {
  let title: String
  var systemImage: String?
  var isSelected: Bool
  var action: () -> Void

  var body: some View {
    Button(action: action) {
      HStack(spacing: 6) {
        if let systemImage {
          Image(systemName: systemImage)
            .font(.system(size: 12, weight: .semibold))
        }

        Text(title)
          .font(.system(size: 13, weight: .medium))
      }
      .foregroundStyle(isSelected ? Color.white : HATheme.Colors.foreground)
      .padding(.horizontal, 12)
      .padding(.vertical, 8)
      .background(isSelected ? HATheme.Colors.primary : HATheme.Colors.card)
      .overlay {
        Capsule(style: .continuous)
          .stroke(isSelected ? HATheme.Colors.primary : HATheme.Colors.border, lineWidth: 1)
      }
      .clipShape(Capsule(style: .continuous))
    }
    .buttonStyle(.plain)
  }
}

struct HASegmentedControl<Option: Hashable & Identifiable>: View where Option: CustomStringConvertible {
  let options: [Option]
  @Binding var selection: Option

  var body: some View {
    HStack(spacing: 6) {
      ForEach(options) { option in
        Button {
          selection = option
        } label: {
          Text(option.description)
            .font(.system(size: 13, weight: .semibold))
            .foregroundStyle(selection == option ? HATheme.Colors.foreground : HATheme.Colors.mutedForeground)
            .frame(maxWidth: .infinity)
            .frame(height: 36)
            .background(selection == option ? HATheme.Colors.card : .clear)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .buttonStyle(.plain)
      }
    }
    .padding(4)
    .background(HATheme.Colors.secondary)
    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
  }
}

struct HAAvatarView: View {
  let initials: String
  var size: CGFloat = 44
  var background: Color = HATheme.Colors.secondary
  var foreground: Color = HATheme.Colors.mutedForeground

  var body: some View {
    Text(initials)
      .font(.system(size: size * 0.34, weight: .medium))
      .foregroundStyle(foreground)
      .frame(width: size, height: size)
      .background(background)
      .clipShape(Circle())
  }
}

struct HAStatusBarSpacer: View {
  var body: some View {
    Color.clear
      .frame(height: 56)
  }
}

struct HAImageCarousel: View {
  let imageNames: [String]
  let aspectRatio: CGFloat?
  let cornerRadius: CGFloat
  let dotsInside: Bool

  @State private var selection = 0

  init(
    imageNames: [String],
    aspectRatio: CGFloat? = 4 / 3,
    cornerRadius: CGFloat = 22,
    dotsInside: Bool = true
  ) {
    self.imageNames = imageNames
    self.aspectRatio = aspectRatio
    self.cornerRadius = cornerRadius
    self.dotsInside = dotsInside
  }

  var body: some View {
    VStack(spacing: dotsInside ? 0 : 8) {
      ZStack(alignment: dotsInside ? .bottom : .center) {
        carouselContent
          .background(HATheme.Colors.muted)
          .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))

        if dotsInside && imageNames.count > 1 {
          HADots(count: imageNames.count, currentIndex: selection, activeColor: .white, inactiveColor: .white.opacity(0.5))
            .padding(.bottom, 12)
        }
      }

      if !dotsInside && imageNames.count > 1 {
        HADots(
          count: imageNames.count,
          currentIndex: selection,
          activeColor: HATheme.Colors.mutedForeground,
          inactiveColor: HATheme.Colors.mutedForeground.opacity(0.4)
        )
      }
    }
  }

  @ViewBuilder
  private var carouselContent: some View {
    let tabView = TabView(selection: $selection) {
      ForEach(Array(imageNames.enumerated()), id: \.offset) { index, imageName in
        Image(imageName)
          .resizable()
          .scaledToFill()
          .frame(maxWidth: .infinity, maxHeight: .infinity)
          .clipped()
          .tag(index)
      }
    }
    .tabViewStyle(.page(indexDisplayMode: .never))

    if let aspectRatio {
      tabView
        .aspectRatio(aspectRatio, contentMode: .fit)
    } else {
      tabView
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
  }
}

struct HADots: View {
  let count: Int
  let currentIndex: Int
  let activeColor: Color
  let inactiveColor: Color

  var body: some View {
    HStack(spacing: 6) {
      ForEach(0..<count, id: \.self) { index in
        Circle()
          .fill(index == currentIndex ? activeColor : inactiveColor)
          .frame(width: index == currentIndex ? 8 : 6, height: index == currentIndex ? 8 : 6)
      }
    }
  }
}

extension ExploreMode: CustomStringConvertible {
  var description: String { rawValue }
}

enum HAAppTab {
  case home
  case explore
  case post
  case saved
  case profile
}

struct HABottomTabBar: View {
  let selectedTab: HAAppTab
  let onSelect: (HAAppTab) -> Void

  var body: some View {
    Group {
      if #available(iOS 26.0, *) {
        glassBody
      } else {
        fallbackBody
      }
    }
    .padding(.horizontal, 16)
    .padding(.top, 8)
    .padding(.bottom, 12)
  }

  @available(iOS 26.0, *)
  private var glassBody: some View {
    GlassEffectContainer(spacing: 12) {
      tabBarContent
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background {
          Capsule(style: .continuous)
            .fill(
              LinearGradient(
                colors: [
                  HATheme.Colors.secondary.opacity(0.50),
                  HATheme.Colors.background.opacity(0.34)
                ],
                startPoint: .top,
                endPoint: .bottom
              )
            )
        }
        .glassEffect(
          .regular.tint(HATheme.Colors.secondary.opacity(0.08)),
          in: .capsule
        )
        .overlay {
          Capsule(style: .continuous)
            .strokeBorder(.white.opacity(0.28), lineWidth: 1)
        }
        .shadow(color: HATheme.Colors.shadow.opacity(0.12), radius: 16, x: 0, y: 8)
    }
  }

  @ViewBuilder
  private var fallbackBody: some View {
    tabBarContent
      .padding(.horizontal, 10)
      .padding(.vertical, 6)
      .background {
        Capsule(style: .continuous)
          .fill(
            LinearGradient(
              colors: [
                HATheme.Colors.card.opacity(0.94),
                HATheme.Colors.card.opacity(0.88)
              ],
              startPoint: .top,
              endPoint: .bottom
            )
          )
          .overlay {
            Capsule(style: .continuous)
              .strokeBorder(HATheme.Colors.border.opacity(0.82), lineWidth: 1)
          }
      }
      .shadow(color: HATheme.Colors.shadow.opacity(0.16), radius: 16, x: 0, y: 8)
  }

  private var tabBarContent: some View {
    HStack(alignment: .bottom, spacing: 8) {
      tabItem(title: "Home", tab: .home)
      tabItem(title: "Explore", tab: .explore)
      postItem
      tabItem(title: "Saved", tab: .saved)
      tabItem(title: "Profile", tab: .profile)
    }
  }

  private func tabItem(title: String, tab: HAAppTab) -> some View {
    Button(action: { onSelect(tab) }) {
      VStack(spacing: 1.5) {
        Image(systemName: symbolName(for: tab))
          .font(.system(size: 22, weight: selectedTab == tab ? .semibold : .regular))
          .foregroundStyle(color(for: tab))
          .frame(height: 24)

        Text(title)
          .font(.system(size: 10, weight: selectedTab == tab ? .semibold : .medium))
          .foregroundStyle(color(for: tab))
      }
      .frame(maxWidth: .infinity)
      .frame(minHeight: 42)
      .padding(.horizontal, 6)
      .padding(.vertical, 3)
      .background(tabItemBackground(for: tab))
    }
    .buttonStyle(.plain)
    .accessibilityIdentifier("tab.\(tab.accessibilityID)")
    .accessibilityValue(selectedTab == tab ? "selected" : "unselected")
  }

  @ViewBuilder
  private func tabItemBackground(for tab: HAAppTab) -> some View {
    Capsule(style: .continuous)
      .fill(selectedTab == tab ? HATheme.Colors.primary.opacity(0.14) : .clear)
  }

  private func symbolName(for tab: HAAppTab) -> String {
    switch tab {
    case .home:
      return selectedTab == .home ? "house.fill" : "house"
    case .explore:
      return "map"
    case .post:
      return "plus"
    case .saved:
      return "bookmark"
    case .profile:
      return "person"
    }
  }

  private var postItem: some View {
    Button(action: { onSelect(.post) }) {
      ZStack {
        ZStack {
          Circle()
            .fill(HATheme.Colors.primary)
            .frame(width: 38, height: 38)

          Image(systemName: "plus")
            .font(.system(size: 18, weight: .bold))
            .foregroundStyle(.white)
        }
        .frame(width: 38, height: 38)
      }
      .frame(maxWidth: .infinity)
      .frame(minHeight: 42)
      .padding(.horizontal, 6)
      .padding(.vertical, 3)
    }
    .buttonStyle(.plain)
    .accessibilityIdentifier("tab.post")
  }

  private func color(for tab: HAAppTab) -> Color {
    selectedTab == tab ? HATheme.Colors.primary : HATheme.Colors.mutedForeground
  }
}

extension HAAppTab {
  var accessibilityID: String {
    switch self {
    case .home: "home"
    case .explore: "explore"
    case .post: "post"
    case .saved: "saved"
    case .profile: "profile"
    }
  }
}

private struct HAComponentsPreview: View {
  @State private var selectedMode: ExploreMode = .feed
  @State private var selectedTab: HAAppTab = .home

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 24) {
        HAPrimaryButton(title: "Primary Action") {}

        HStack(spacing: 12) {
          HAChip(title: "Trails", systemImage: "leaf", isSelected: true) {}
          HAChip(title: "Water", systemImage: "drop", isSelected: false) {}
        }

        HASegmentedControl(options: ExploreMode.allCases, selection: $selectedMode)

        HStack(spacing: 16) {
          HAAvatarView(initials: "HA")
          HAAvatarView(initials: "JS", size: 64, background: HATheme.Colors.primary.opacity(0.18), foreground: HATheme.Colors.primary)
        }

        HAImageCarousel(
          imageNames: ["hero-mountain", "trail-forest", "scenic-overlook"],
          aspectRatio: 4 / 3,
          cornerRadius: 18,
          dotsInside: false
        )

        HABottomTabBar(selectedTab: selectedTab, onSelect: { selectedTab = $0 })
          .padding(.horizontal, -20)
      }
      .padding(20)
    }
    .background(HATheme.Colors.background)
  }
}

struct HAComponents_Previews: PreviewProvider {
  static var previews: some View {
    HAComponentsPreview()
  }
}
