import Foundation

enum SettingsDestination: String, CaseIterable, Equatable {
  case main
  case feedback
  case terms
  case privacy
  case deleteAccount
  case debugLogs
}

enum SettingsFeedbackCategory: String, CaseIterable, Equatable, Identifiable {
  case bugReport = "Bug Report"
  case featureRequest = "Feature Request"
  case contentIssue = "Content Issue"
  case accountProblem = "Account Problem"
  case other = "Other"

  var id: String { rawValue }
}

struct SettingsMenuItem: Identifiable, Equatable {
  let destination: SettingsDestination
  let title: String
  let systemImage: String
  let isDestructive: Bool

  var id: SettingsDestination { destination }
}

struct SettingsLegalSection: Equatable {
  let title: String
  let body: [String]
}

struct SettingsLegalDocument: Equatable {
  let title: String
  let heading: String
  let subtitle: String
  let sections: [SettingsLegalSection]
}

enum SettingsContent {
  static let supportEmail = "support@hiddenadventures.com"

  static let mainMenuItems: [SettingsMenuItem] = [
    SettingsMenuItem(destination: .feedback, title: "Give us feedback", systemImage: "message", isDestructive: false),
    SettingsMenuItem(destination: .terms, title: "Terms of Service", systemImage: "doc.text", isDestructive: false),
    SettingsMenuItem(destination: .privacy, title: "Privacy Policy", systemImage: "shield", isDestructive: false),
    SettingsMenuItem(destination: .deleteAccount, title: "Delete Account", systemImage: "trash", isDestructive: true),
    SettingsMenuItem(destination: .debugLogs, title: "Upload Debug Logs", systemImage: "ladybug", isDestructive: false)
  ]

  static let termsOfService = SettingsLegalDocument(
    title: "Terms of Service",
    heading: "Hidden Adventures Terms and Conditions",
    subtitle: "Last updated: March 3, 2019",
    sections: [
      SettingsLegalSection(
        title: "",
        body: [
          "Please read these Terms and Conditions carefully before using the Hidden Adventures mobile application operated by Lucidios.",
          "Your access to and use of the Service is conditioned upon your acceptance of and compliance with these Terms. These Terms apply to all visitors, users and others who wish to access or use the Service.",
          "By accessing or using the Service you agree to be bound by these Terms. If you disagree with any part of the terms then you do not have permission to access the Service."
        ]
      ),
      SettingsLegalSection(
        title: "Communications",
        body: [
          "By creating an Account on our service, you agree to subscribe to newsletters, marketing or promotional materials and other information we may send. However, you may opt out of receiving any, or all, of these communications by following the unsubscribe link or instructions provided in any email we send."
        ]
      ),
      SettingsLegalSection(
        title: "Content",
        body: [
          "Our Service allows you to post, link, store, share and otherwise make available certain information, text, graphics, videos, or other material (\"Content\"). You are responsible for the Content that you post on or through the Service.",
          "You retain any and all of your rights to any Content you submit, post or display on or through the Service and you are responsible for protecting those rights. We take no responsibility and assume no liability for Content you or any third party posts."
        ]
      ),
      SettingsLegalSection(
        title: "Accounts",
        body: [
          "When you create an account with us, you guarantee that you are above the age of 13, and that the information you provide us is accurate, complete, and current at all times.",
          "You are responsible for maintaining the confidentiality of your account and password, including but not limited to restricting access to your computer and/or account."
        ]
      ),
      SettingsLegalSection(
        title: "Intellectual Property",
        body: [
          "The Service and its original content, features and functionality are and will remain the exclusive property of Lucidios and its licensors. The Service is protected by copyright, trademark, and other laws."
        ]
      ),
      SettingsLegalSection(
        title: "Links To Other Web Sites",
        body: [
          "Our Service may contain links to third party web sites or services that are not owned or controlled by Lucidios. Lucidios has no control over, and assumes no responsibility for, the content, privacy policies, or practices of any third party web sites or services."
        ]
      ),
      SettingsLegalSection(
        title: "Termination",
        body: [
          "We may terminate or suspend your account and access to the Service immediately, without prior notice or liability, under our sole discretion, for any reason whatsoever, including without limitation if you breach the Terms."
        ]
      ),
      SettingsLegalSection(
        title: "Governing Law",
        body: [
          "These Terms shall be governed and construed in accordance with the laws of the United States, without regard to its conflict of law provisions."
        ]
      ),
      SettingsLegalSection(
        title: "Changes",
        body: [
          "We reserve the right, at our sole discretion, to modify or replace these Terms at any time. If a revision is material we will provide at least 30 days notice prior to any new terms taking effect."
        ]
      ),
      SettingsLegalSection(
        title: "Contact Us",
        body: [
          "If you have any questions about these Terms, please contact us at \(supportEmail)."
        ]
      )
    ]
  )

  static let privacyPolicy = SettingsLegalDocument(
    title: "Privacy Policy",
    heading: "Privacy Policy",
    subtitle: "Effective date: March 06, 2019",
    sections: [
      SettingsLegalSection(
        title: "",
        body: [
          "Lucidios operates the Hidden Adventures mobile application (hereinafter referred to as the \"Service\").",
          "This page informs you of our policies regarding the collection, use and disclosure of personal data when you use our Service and the choices you have associated with that data.",
          "We use your data to provide and improve the Service. By using the Service, you agree to the collection and use of information in accordance with this policy."
        ]
      ),
      SettingsLegalSection(
        title: "Definitions",
        body: [
          "Service — the Hidden Adventures mobile application operated by Lucidios",
          "Personal Data — data about a living individual who can be identified from those data",
          "Usage Data — data collected automatically from the use of the Service",
          "Cookies — small files stored on your device"
        ]
      ),
      SettingsLegalSection(
        title: "Information Collection and Use",
        body: [
          "We collect several different types of information for various purposes to provide and improve our Service to you."
        ]
      ),
      SettingsLegalSection(
        title: "Types of Data Collected",
        body: [
          "Personal Data — While using our Service, we may ask you to provide us with certain personally identifiable information that may include email address, first and last name, phone number, address, cookies, and usage data.",
          "Usage Data — We may collect information on how the Service is accessed and used.",
          "Location Data — We may use and store information about your location if you give us permission to do so.",
          "Tracking & Cookies Data — We use cookies and similar tracking technologies to track activity on our Service and hold certain information."
        ]
      ),
      SettingsLegalSection(
        title: "Use of Data",
        body: [
          "Hidden Adventures uses the collected data to provide and maintain the Service, notify you about changes, allow you to participate in interactive features, provide customer support, and monitor usage of the Service."
        ]
      ),
      SettingsLegalSection(
        title: "Transfer of Data",
        body: [
          "Your information, including Personal Data, may be transferred to and maintained on computers located outside of your state, province, country or other governmental jurisdiction where the data protection laws may differ from those of your jurisdiction."
        ]
      ),
      SettingsLegalSection(
        title: "Disclosure of Data",
        body: [
          "We may disclose your Personal Data in the good faith belief that such action is necessary to comply with a legal obligation, protect and defend the rights or property of Lucidios, or protect the personal safety of users of the Service."
        ]
      ),
      SettingsLegalSection(
        title: "Security of Data",
        body: [
          "The security of your data is important to us, but remember that no method of transmission over the Internet, or method of electronic storage is 100% secure."
        ]
      ),
      SettingsLegalSection(
        title: "Service Providers",
        body: [
          "We may employ third party companies and individuals to facilitate our Service, provide the Service on our behalf, perform Service-related services or assist us in analyzing how our Service is used."
        ]
      ),
      SettingsLegalSection(
        title: "Children's Privacy",
        body: [
          "Our Service does not address anyone under the age of 13. We do not knowingly collect personally identifiable information from anyone under the age of 13."
        ]
      ),
      SettingsLegalSection(
        title: "Changes to This Privacy Policy",
        body: [
          "We may update our Privacy Policy from time to time. We will notify you of any changes by posting the new Privacy Policy on this page."
        ]
      ),
      SettingsLegalSection(
        title: "Contact Us",
        body: [
          "If you have any questions about this Privacy Policy, please contact us at \(supportEmail)."
        ]
      )
    ]
  )
}

enum SettingsFeedbackState {
  static func canSubmit(category: SettingsFeedbackCategory?, message: String) -> Bool {
    message.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false
  }
}
