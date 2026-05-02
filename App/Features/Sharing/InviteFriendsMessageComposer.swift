import MessageUI
import SwiftUI

struct InviteFriendsMessageComposer: UIViewControllerRepresentable {
  let recipients: [String]
  let bodyText: String
  var onResult: ((InviteComposerResult) -> Void)?

  func makeCoordinator() -> Coordinator {
    Coordinator(onResult: onResult)
  }

  func makeUIViewController(context: Context) -> MFMessageComposeViewController {
    let controller = MFMessageComposeViewController()
    controller.messageComposeDelegate = context.coordinator
    controller.recipients = recipients
    controller.body = bodyText
    return controller
  }

  func updateUIViewController(_ uiViewController: MFMessageComposeViewController, context: Context) {}

  final class Coordinator: NSObject, MFMessageComposeViewControllerDelegate {
    private let onResult: ((InviteComposerResult) -> Void)?

    init(onResult: ((InviteComposerResult) -> Void)?) {
      self.onResult = onResult
    }

    func messageComposeViewController(
      _ controller: MFMessageComposeViewController,
      didFinishWith result: MessageComposeResult
    ) {
      switch result {
      case .sent:
        onResult?(.sent(controller.recipients?.count ?? 0))
      case .cancelled:
        onResult?(.cancelled)
      case .failed:
        onResult?(.failed)
      @unknown default:
        onResult?(.failed)
      }
      controller.dismiss(animated: true)
    }
  }
}
