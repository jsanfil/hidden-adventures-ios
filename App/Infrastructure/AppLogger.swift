import Foundation
import OSLog

enum AppLogger {
  static let subsystem = Bundle.main.bundleIdentifier ?? "HiddenAdventures"

  static func logger(category: String) -> Logger {
    Logger(subsystem: subsystem, category: category)
  }
}
