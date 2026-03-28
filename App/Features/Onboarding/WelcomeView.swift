import SwiftUI

struct WelcomeView: View {
  let onGetStarted: () -> Void

  var body: some View {
    ZStack {
      Image("hero-mountain")
        .resizable()
        .scaledToFill()
        .ignoresSafeArea()

      LinearGradient(
        colors: [
          .black.opacity(0.22),
          .black.opacity(0.10),
          .black.opacity(0.72)
        ],
        startPoint: .top,
        endPoint: .bottom
      )
      .ignoresSafeArea()

      VStack {
        VStack(spacing: 16) {
          ZStack {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
              .fill(.white.opacity(0.94))
              .frame(width: 64, height: 64)

            Image(systemName: "safari")
              .font(.system(size: 34, weight: .regular))
              .foregroundStyle(HATheme.Colors.primary)
          }

          Text("Hidden Adventures")
            .font(HATheme.Typography.heroTitle)
            .foregroundStyle(.white)
        }
        .padding(.top, 92)

        Spacer()

        VStack(spacing: 26) {
          VStack(spacing: 12) {
            Text("Discover the extraordinary")
              .font(.system(size: 28, weight: .medium))
              .multilineTextAlignment(.center)
              .foregroundStyle(.white)
              .frame(maxWidth: .infinity)

            Text("Find hidden gems, scenic trails, and unforgettable places shared by explorers like you.")
              .font(HATheme.Typography.body)
              .foregroundStyle(.white.opacity(0.82))
              .multilineTextAlignment(.center)
              .lineSpacing(4)
              .frame(maxWidth: .infinity)
          }

          VStack(spacing: 12) {
            Button(action: onGetStarted) {
              Text("Get Started")
                .font(HATheme.Typography.bodyMedium)
                .foregroundStyle(HATheme.Colors.foreground)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(.white)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("welcome.getStarted")

            Button(action: {}) {
              Text("Already have an account? ")
                .foregroundStyle(.white.opacity(0.72))
              +
              Text("Sign In")
                .foregroundStyle(.white)
                .underline()
            }
            .font(.system(size: 14, weight: .semibold))
            .buttonStyle(.plain)
            .accessibilityIdentifier("welcome.signIn")
          }

          Text("By continuing, you agree to our Terms of Service and Privacy Policy")
            .font(.system(size: 12, weight: .regular))
            .foregroundStyle(.white.opacity(0.6))
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 20)
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 24)
        .padding(.bottom, 40)
      }
    }
    .toolbar(.hidden, for: .navigationBar)
  }
}
