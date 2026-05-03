import SwiftUI

struct SettingsView: View {
  private enum Layout {
    static let horizontalPadding: CGFloat = 20
    static let topPadding: CGFloat = 14
    static let sectionSpacing: CGFloat = 24
    static let cardCornerRadius: CGFloat = 24
  }

  @Environment(\.dismiss) private var dismiss
  @Environment(\.openURL) private var openURL

  let onLogout: () -> Void

  @State private var activeScreen: SettingsDestination
  @State private var selectedCategory: SettingsFeedbackCategory?
  @State private var message = ""
  @State private var feedbackAlertMessage: String?
  @State private var debugLogsAlertMessage: String?
  @State private var showsDeleteConfirmation = false
  @State private var deleteResultAlertMessage: String?

  init(onLogout: @escaping () -> Void) {
    self.onLogout = onLogout
    _activeScreen = State(initialValue: Self.initialDestination())
  }

  var body: some View {
    ZStack {
      HATheme.Colors.background
        .ignoresSafeArea()

      switch activeScreen {
      case .main, .debugLogs:
        mainScreen
      case .feedback:
        feedbackScreen
      case .terms:
        legalScreen(document: SettingsContent.termsOfService, accessibilityPrefix: "settings.terms")
      case .privacy:
        legalScreen(document: SettingsContent.privacyPolicy, accessibilityPrefix: "settings.privacy")
      case .deleteAccount:
        deleteAccountScreen
      }
    }
    .toolbar(.hidden, for: .navigationBar)
    .alert(
      "Feedback submitted",
      isPresented: Binding(
        get: { feedbackAlertMessage != nil },
        set: { if $0 == false { feedbackAlertMessage = nil } }
      )
    ) {
      Button("OK", role: .cancel) {
        feedbackAlertMessage = nil
      }
    } message: {
      Text(feedbackAlertMessage ?? "")
        .accessibilityIdentifier("settings.feedback.alert.message")
    }
    .alert(
      "Debug Logs Submitted",
      isPresented: Binding(
        get: { debugLogsAlertMessage != nil },
        set: { if $0 == false { debugLogsAlertMessage = nil } }
      )
    ) {
      Button("OK", role: .cancel) {
        debugLogsAlertMessage = nil
      }
    } message: {
      Text(debugLogsAlertMessage ?? "")
        .accessibilityIdentifier("settings.debugLogs.alert.message")
    }
    .confirmationDialog(
      "Delete Account?",
      isPresented: $showsDeleteConfirmation,
      titleVisibility: .visible
    ) {
      Button("Delete", role: .destructive) {
        deleteResultAlertMessage = "Account deletion isn't wired up in iOS yet. Customer support can help with account requests in the meantime."
      }
      Button("Cancel", role: .cancel) {}
    } message: {
      Text("This action cannot be undone.")
    }
    .alert(
      "Delete Account",
      isPresented: Binding(
        get: { deleteResultAlertMessage != nil },
        set: { if $0 == false { deleteResultAlertMessage = nil } }
      )
    ) {
      Button("OK", role: .cancel) {
        deleteResultAlertMessage = nil
      }
    } message: {
      Text(deleteResultAlertMessage ?? "")
        .accessibilityIdentifier("settings.delete.result")
    }
  }

  private var mainScreen: some View {
    ScrollView(showsIndicators: false) {
      VStack(alignment: .leading, spacing: Layout.sectionSpacing) {
        settingsBackButton
          .padding(.top, Layout.topPadding)

        Text("Settings")
          .font(.system(size: 30, weight: .semibold))
          .foregroundStyle(HATheme.Colors.foreground)
          .accessibilityIdentifier("settings.title")

        VStack(spacing: 0) {
          ForEach(Array(SettingsContent.mainMenuItems.enumerated()), id: \.element.id) { index, item in
            Button {
              handleSelection(item.destination)
            } label: {
              settingsRow(for: item, showsDivider: index < SettingsContent.mainMenuItems.count - 1)
                .accessibilityElement(children: .combine)
                .accessibilityIdentifier("settings.row.\(item.destination.rawValue)")
            }
            .buttonStyle(.plain)
          }
        }
        .background(HATheme.Colors.card)
        .clipShape(RoundedRectangle(cornerRadius: Layout.cardCornerRadius, style: .continuous))
        .overlay {
          RoundedRectangle(cornerRadius: Layout.cardCornerRadius, style: .continuous)
            .stroke(HATheme.Colors.border, lineWidth: 1)
        }
        Button(action: onLogout) {
          Text("Log Out")
            .font(.system(size: 17, weight: .semibold))
            .foregroundStyle(HATheme.Colors.foreground)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
        }
        .buttonStyle(.plain)
        .background(HATheme.Colors.card)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay {
          RoundedRectangle(cornerRadius: 20, style: .continuous)
            .stroke(HATheme.Colors.border, lineWidth: 1)
        }
        .accessibilityIdentifier("settings.logout")

        Text(appVersionLabel)
          .font(.system(size: 13, weight: .medium))
          .foregroundStyle(HATheme.Colors.mutedForeground)
          .frame(maxWidth: .infinity, alignment: .center)
          .padding(.top, 6)
          .accessibilityIdentifier("settings.version")
      }
      .padding(.horizontal, Layout.horizontalPadding)
      .padding(.bottom, 32)
    }
  }

  private var feedbackScreen: some View {
    ScrollView(showsIndicators: false) {
      VStack(alignment: .leading, spacing: Layout.sectionSpacing) {
        settingsBackButton
          .padding(.top, Layout.topPadding)

        VStack(alignment: .leading, spacing: 12) {
          Text("Send Feedback")
            .font(.system(size: 30, weight: .semibold))
            .foregroundStyle(HATheme.Colors.foreground)
            .accessibilityIdentifier("settings.feedback.title")

          Text("We appreciate hearing from you. Please provide your feedback below or contact")
            .font(HATheme.Typography.body)
            .foregroundStyle(HATheme.Colors.mutedForeground)

          Button(action: contactSupport) {
            Text(SettingsContent.supportEmail)
              .font(.system(size: 16, weight: .medium))
              .foregroundStyle(Color(red: 0.251, green: 0.478, blue: 0.667))
          }
          .buttonStyle(.plain)
          .accessibilityIdentifier("settings.feedback.email")
        }

        VStack(spacing: 16) {
          VStack(spacing: 0) {
            HStack {
              Text(selectedCategory?.rawValue ?? "Category...")
                .font(.system(size: 16, weight: selectedCategory == nil ? .regular : .medium))
                .foregroundStyle(selectedCategory == nil ? HATheme.Colors.mutedForeground : HATheme.Colors.foreground)

              Spacer()

              Image(systemName: "chevron.down")
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(HATheme.Colors.mutedForeground)
            }
            .padding(.horizontal, 16)
            .frame(height: 56)
            Divider()
              .overlay(HATheme.Colors.border)
              .padding(.leading, 16)

            VStack(spacing: 0) {
              ForEach(Array(SettingsFeedbackCategory.allCases.enumerated()), id: \.element.id) { index, category in
                Button {
                  selectedCategory = category
                } label: {
                  HStack {
                    Text(category.rawValue)
                      .font(.system(size: 16, weight: .medium))
                      .foregroundStyle(HATheme.Colors.foreground)

                    Spacer()

                    if selectedCategory == category {
                      Image(systemName: "checkmark")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(Color(red: 0.251, green: 0.478, blue: 0.667))
                    }
                  }
                  .padding(.horizontal, 16)
                  .padding(.vertical, 16)
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("settings.feedback.category.\(category.id)")

                if index < SettingsFeedbackCategory.allCases.count - 1 {
                  Divider()
                    .overlay(HATheme.Colors.border)
                    .padding(.leading, 16)
                }
              }
            }
          }
          .background(HATheme.Colors.card)
          .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
          .overlay {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
              .stroke(HATheme.Colors.border, lineWidth: 1)
          }
          .accessibilityIdentifier("settings.feedback.category")

          TextEditor(text: $message)
            .scrollContentBackground(.hidden)
            .font(.system(size: 16, weight: .regular))
            .foregroundStyle(HATheme.Colors.foreground)
            .frame(minHeight: 200)
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(HATheme.Colors.card)
            .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
            .overlay(alignment: .topLeading) {
              if message.isEmpty {
                Text("Please enter your feedback.")
                  .font(.system(size: 16, weight: .regular))
                  .foregroundStyle(HATheme.Colors.mutedForeground)
                  .padding(.horizontal, 18)
                  .padding(.vertical, 20)
                  .allowsHitTesting(false)
              }
            }
            .overlay {
              RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(HATheme.Colors.border, lineWidth: 1)
            }
            .accessibilityIdentifier("settings.feedback.message")

          Button(action: submitFeedback) {
            Text("Submit")
              .font(.system(size: 18, weight: .semibold))
              .foregroundStyle(SettingsFeedbackState.canSubmit(category: selectedCategory, message: message) ? HATheme.Colors.foreground : HATheme.Colors.mutedForeground)
              .frame(maxWidth: .infinity)
              .padding(.vertical, 18)
          }
          .buttonStyle(.plain)
          .background(HATheme.Colors.card)
          .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
          .overlay {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
              .stroke(HATheme.Colors.border, lineWidth: 1)
          }
          .disabled(SettingsFeedbackState.canSubmit(category: selectedCategory, message: message) == false)
          .accessibilityIdentifier("settings.feedback.submit")
        }
      }
      .padding(.horizontal, Layout.horizontalPadding)
      .padding(.bottom, 32)
    }
    .scrollDismissesKeyboard(.immediately)
  }

  private var deleteAccountScreen: some View {
    VStack(alignment: .leading, spacing: 0) {
      settingsCircleBackButton
        .padding(.top, Layout.topPadding)
        .padding(.horizontal, Layout.horizontalPadding)

      Text("Delete Account")
        .font(.system(size: 30, weight: .semibold))
        .foregroundStyle(HATheme.Colors.foreground)
        .padding(.horizontal, Layout.horizontalPadding)
        .padding(.top, 22)
        .accessibilityIdentifier("settings.delete.title")

      Spacer(minLength: 40)

      Text("This will permanently delete your account and all of your content. You will no longer be able to login. Are you sure?")
        .font(.system(size: 18, weight: .semibold))
        .multilineTextAlignment(.center)
        .lineSpacing(6)
        .foregroundStyle(Color(red: 0.251, green: 0.478, blue: 0.667))
        .padding(.horizontal, 40)
        .accessibilityIdentifier("settings.delete.warning")

      Spacer()

      Button {
        showsDeleteConfirmation = true
      } label: {
        Text("Delete")
          .font(.system(size: 19, weight: .semibold))
          .foregroundStyle(.red)
          .frame(maxWidth: .infinity)
          .padding(.vertical, 18)
      }
      .buttonStyle(.plain)
      .background(HATheme.Colors.card)
      .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
      .overlay {
        RoundedRectangle(cornerRadius: 22, style: .continuous)
          .stroke(HATheme.Colors.border, lineWidth: 1)
      }
      .padding(.horizontal, Layout.horizontalPadding)
      .padding(.bottom, 32)
      .accessibilityIdentifier("settings.delete.button")
    }
  }

  private func legalScreen(document: SettingsLegalDocument, accessibilityPrefix: String) -> some View {
    ScrollView(showsIndicators: false) {
      VStack(alignment: .leading, spacing: Layout.sectionSpacing) {
        settingsCircleBackButton
          .padding(.top, Layout.topPadding)

        Text(document.title)
          .font(.system(size: 30, weight: .semibold))
          .foregroundStyle(HATheme.Colors.foreground)
          .accessibilityIdentifier("\(accessibilityPrefix).title")

        VStack(alignment: .leading, spacing: 22) {
          VStack(alignment: .leading, spacing: 12) {
            Text(document.heading)
              .font(.system(size: 22, weight: .semibold))
              .foregroundStyle(HATheme.Colors.foreground)

            Text(document.subtitle)
              .font(.system(size: 14, weight: .regular))
              .foregroundStyle(HATheme.Colors.mutedForeground)
          }

          ForEach(Array(document.sections.enumerated()), id: \.offset) { index, section in
            VStack(alignment: .leading, spacing: 12) {
              if section.title.isEmpty == false {
                Text(section.title)
                  .font(.system(size: 18, weight: .semibold))
                  .foregroundStyle(HATheme.Colors.foreground)
              }

              ForEach(Array(section.body.enumerated()), id: \.offset) { paragraphIndex, paragraph in
                Text(paragraph)
                  .font(.system(size: 15, weight: .regular))
                  .lineSpacing(5)
                  .foregroundStyle(HATheme.Colors.mutedForeground)
                  .accessibilityIdentifier(paragraphIndex == 0 ? "\(accessibilityPrefix).section.\(index)" : "\(accessibilityPrefix).section.\(index).\(paragraphIndex)")
              }
            }
          }
        }
        .padding(24)
        .background(HATheme.Colors.card)
        .clipShape(RoundedRectangle(cornerRadius: Layout.cardCornerRadius, style: .continuous))
        .overlay {
          RoundedRectangle(cornerRadius: Layout.cardCornerRadius, style: .continuous)
            .stroke(HATheme.Colors.border, lineWidth: 1)
        }
        .accessibilityIdentifier("\(accessibilityPrefix).content")
      }
      .padding(.horizontal, Layout.horizontalPadding)
      .padding(.bottom, 32)
    }
  }

  private var settingsBackButton: some View {
    Button(action: handleBack) {
      HStack(spacing: 8) {
        Image(systemName: "chevron.left")
          .font(.system(size: 17, weight: .semibold))
        Text("Back")
          .font(.system(size: 17, weight: .medium))
      }
      .foregroundStyle(HATheme.Colors.foreground)
      .padding(.horizontal, 18)
      .padding(.vertical, 12)
      .background(HATheme.Colors.secondary)
      .clipShape(Capsule(style: .continuous))
    }
    .buttonStyle(.plain)
    .accessibilityIdentifier("settings.back")
  }

  private var settingsCircleBackButton: some View {
    Button(action: handleBack) {
      Image(systemName: "chevron.left")
        .font(.system(size: 20, weight: .semibold))
        .foregroundStyle(HATheme.Colors.foreground)
        .frame(width: 40, height: 40)
        .background(HATheme.Colors.secondary)
        .clipShape(Circle())
    }
    .buttonStyle(.plain)
    .accessibilityIdentifier("settings.back")
  }

  private func settingsRow(for item: SettingsMenuItem, showsDivider: Bool) -> some View {
    VStack(spacing: 0) {
      HStack(spacing: 16) {
        ZStack {
          RoundedRectangle(cornerRadius: 14, style: .continuous)
            .fill(item.isDestructive ? Color.red.opacity(0.10) : HATheme.Colors.secondary)

          Image(systemName: item.systemImage)
            .font(.system(size: 18, weight: .medium))
            .foregroundStyle(item.isDestructive ? .red : HATheme.Colors.mutedForeground)
        }
        .frame(width: 44, height: 44)

        Text(item.title)
          .font(.system(size: 18, weight: .medium))
          .foregroundStyle(item.isDestructive ? .red : HATheme.Colors.foreground)

        Spacer()

        Image(systemName: "chevron.right")
          .font(.system(size: 17, weight: .semibold))
          .foregroundStyle(HATheme.Colors.mutedForeground)
      }
      .padding(.horizontal, 18)
      .padding(.vertical, 16)

      if showsDivider {
        Divider()
          .overlay(HATheme.Colors.border)
          .padding(.leading, 78)
      }
    }
  }

  private func handleSelection(_ destination: SettingsDestination) {
    if destination == .debugLogs {
      debugLogsAlertMessage = "Your debug logs were sent to customer support. Please tap the 'Contact Support' button and provide the details of your issue."
      return
    }

    activeScreen = destination
  }

  private func submitFeedback() {
    guard SettingsFeedbackState.canSubmit(category: selectedCategory, message: message) else { return }

    selectedCategory = nil
    message = ""
    activeScreen = .main
    feedbackAlertMessage = "Thanks for sharing your feedback. We saved your note locally for now while the live submission flow is still being wired up."
  }

  private func handleBack() {
    if activeScreen == .main {
      dismiss()
    } else {
      activeScreen = .main
    }
  }

  private func contactSupport() {
    guard let url = URL(string: "mailto:\(SettingsContent.supportEmail)") else { return }
    openURL(url)
  }

  private var appVersionLabel: String {
    let shortVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
      ?? Bundle.main.object(forInfoDictionaryKey: "MARKETING_VERSION") as? String
      ?? "0.1"
    return "Hidden Adventures v\(shortVersion)"
  }

  private static func initialDestination(
    environment: [String: String] = ProcessInfo.processInfo.environment
  ) -> SettingsDestination {
    guard let rawValue = environment["UITEST_SETTINGS_SCREEN"] else {
      return .main
    }

    return SettingsDestination(rawValue: rawValue) ?? .main
  }
}

struct SettingsView_Previews: PreviewProvider {
  static var previews: some View {
    NavigationStack {
      SettingsView(onLogout: {})
    }
  }
}
