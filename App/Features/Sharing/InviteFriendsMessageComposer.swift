import MessageUI
import SwiftUI

struct InviteFriendsMessageComposer: UIViewControllerRepresentable {
  let recipients: [String]
  let bodyText: String
  var onFinish: ((MessageComposeResult) -> Void)?

  func makeCoordinator() -> Coordinator {
    Coordinator(onFinish: onFinish)
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
    private let onFinish: ((MessageComposeResult) -> Void)?

    init(onFinish: ((MessageComposeResult) -> Void)?) {
      self.onFinish = onFinish
    }

    func messageComposeViewController(
      _ controller: MFMessageComposeViewController,
      didFinishWith result: MessageComposeResult
    ) {
      onFinish?(result)
      controller.dismiss(animated: true)
    }
  }
}
