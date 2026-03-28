import SwiftUI

enum HATheme {
  enum Colors {
    static let background = Color(red: 0.965, green: 0.953, blue: 0.937)
    static let foreground = Color(red: 0.141, green: 0.173, blue: 0.220)
    static let card = Color.white
    static let secondary = Color(red: 0.925, green: 0.906, blue: 0.867)
    static let muted = Color(red: 0.941, green: 0.929, blue: 0.906)
    static let mutedForeground = Color(red: 0.397, green: 0.443, blue: 0.490)
    static let accent = Color(red: 0.518, green: 0.706, blue: 0.737)
    static let primary = Color(red: 0.125, green: 0.420, blue: 0.341)
    static let border = Color(red: 0.875, green: 0.855, blue: 0.816)
    static let shadow = Color.black.opacity(0.08)
    static let mapBackground = Color(red: 0.910, green: 0.894, blue: 0.851)
    static let mapForest = Color(red: 0.831, green: 0.894, blue: 0.816)
  }

  enum Radius {
    static let card: CGFloat = 18
    static let input: CGFloat = 14
    static let chip: CGFloat = 999
  }

  enum Typography {
    static let heroTitle = Font.system(size: 32, weight: .regular, design: .serif)
    static let screenTitle = Font.system(size: 28, weight: .semibold, design: .default)
    static let sectionTitle = Font.system(size: 16, weight: .semibold, design: .default)
    static let body = Font.system(size: 16, weight: .regular, design: .default)
    static let bodyMedium = Font.system(size: 16, weight: .medium, design: .default)
    static let caption = Font.system(size: 13, weight: .medium, design: .default)
    static let micro = Font.system(size: 11, weight: .medium, design: .default)
  }

  static let defaultShadow = Shadow(color: Colors.shadow, radius: 10, x: 0, y: 4)
}

struct Shadow {
  let color: Color
  let radius: CGFloat
  let x: CGFloat
  let y: CGFloat
}

extension View {
  func haCardStyle(fill: Color = HATheme.Colors.card) -> some View {
    self
      .background(fill)
      .clipShape(RoundedRectangle(cornerRadius: HATheme.Radius.card, style: .continuous))
      .shadow(
        color: HATheme.defaultShadow.color,
        radius: HATheme.defaultShadow.radius,
        x: HATheme.defaultShadow.x,
        y: HATheme.defaultShadow.y
      )
  }

  func haFieldStyle() -> some View {
    self
      .padding(.horizontal, 16)
      .frame(height: 52)
      .background(HATheme.Colors.secondary)
      .clipShape(RoundedRectangle(cornerRadius: HATheme.Radius.input, style: .continuous))
  }
}
