import Foundation

struct MediaCacheEntry: Codable, Equatable, Sendable {
  let mediaID: String
  let eTag: String?
  let fetchedAt: Date
  let maxAgeSeconds: Int
  let contentType: String?
  let byteSize: Int
}

enum MediaCacheLookup: Sendable {
  case fresh(Data)
  case stale(Data, MediaCacheEntry)
  case missing
}

enum MediaCacheChangeAction: String, Sendable {
  case updated
  case invalidated
}

extension Notification.Name {
  static let haMediaCacheDidChange = Notification.Name("ha.mediaCacheDidChange")
}

enum MediaCacheNotifications {
  static let mediaIDUserInfoKey = "mediaID"
  static let actionUserInfoKey = "action"
}

actor MediaDataCache {
  static let shared = MediaDataCache()

  private let fileManager: FileManager
  private let now: @Sendable () -> Date
  private let directoryURL: URL
  private let metadataIndexURL: URL

  private var memoryStore: [String: Data] = [:]
  private var metadataStore: [String: MediaCacheEntry] = [:]
  private var hasLoadedMetadata = false
  private var inFlightFetches: [String: Task<Data, Error>] = [:]
  private var inFlightRevalidations: Set<String> = []

  init(
    directoryURL: URL? = nil,
    fileManager: FileManager = .default,
    now: @escaping @Sendable () -> Date = { Date() }
  ) {
    self.fileManager = fileManager
    self.now = now

    let baseDirectory = directoryURL
      ?? fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first!
        .appendingPathComponent("HiddenAdventuresMediaCache", isDirectory: true)
    self.directoryURL = baseDirectory
    self.metadataIndexURL = baseDirectory.appendingPathComponent("metadata.json", isDirectory: false)
  }

  func lookup(_ mediaID: String) async -> MediaCacheLookup {
    await loadMetadataIfNeeded()

    guard let entry = metadataStore[mediaID] else {
      return .missing
    }

    guard let data = loadDataFromMemoryOrDisk(for: mediaID) else {
      await remove(mediaID)
      return .missing
    }

    if isFresh(entry) {
      return .fresh(data)
    }

    return .stale(data, entry)
  }

  func store(
    _ data: Data,
    for mediaID: String,
    eTag: String?,
    maxAgeSeconds: Int,
    contentType: String?
  ) async throws {
    await loadMetadataIfNeeded()
    try ensureCacheDirectoryExists()

    let fileURL = dataFileURL(for: mediaID)
    try data.write(to: fileURL, options: .atomic)
    memoryStore[mediaID] = data
    metadataStore[mediaID] = MediaCacheEntry(
      mediaID: mediaID,
      eTag: eTag,
      fetchedAt: now(),
      maxAgeSeconds: maxAgeSeconds,
      contentType: contentType,
      byteSize: data.count
    )
    try persistMetadata()
  }

  func markRevalidated(
    _ mediaID: String,
    eTag: String?,
    maxAgeSeconds: Int
  ) async throws {
    await loadMetadataIfNeeded()
    guard let entry = metadataStore[mediaID] else {
      return
    }

    metadataStore[mediaID] = MediaCacheEntry(
      mediaID: mediaID,
      eTag: eTag ?? entry.eTag,
      fetchedAt: now(),
      maxAgeSeconds: maxAgeSeconds,
      contentType: entry.contentType,
      byteSize: entry.byteSize
    )
    try persistMetadata()
  }

  func remove(_ mediaID: String) async {
    await loadMetadataIfNeeded()

    memoryStore[mediaID] = nil
    metadataStore[mediaID] = nil
    try? fileManager.removeItem(at: dataFileURL(for: mediaID))
    try? persistMetadata()
  }

  func inFlightFetch(for mediaID: String) -> Task<Data, Error>? {
    inFlightFetches[mediaID]
  }

  func setInFlightFetch(_ task: Task<Data, Error>?, for mediaID: String) {
    inFlightFetches[mediaID] = task
  }

  func beginRevalidation(for mediaID: String) -> Bool {
    let inserted = inFlightRevalidations.insert(mediaID).inserted
    return inserted
  }

  func endRevalidation(for mediaID: String) {
    inFlightRevalidations.remove(mediaID)
  }

  nonisolated static func postChange(mediaID: String, action: MediaCacheChangeAction) {
    NotificationCenter.default.post(
      name: .haMediaCacheDidChange,
      object: nil,
      userInfo: [
        MediaCacheNotifications.mediaIDUserInfoKey: mediaID,
        MediaCacheNotifications.actionUserInfoKey: action.rawValue
      ]
    )
  }

  private func isFresh(_ entry: MediaCacheEntry) -> Bool {
    guard entry.maxAgeSeconds > 0 else {
      return false
    }

    let age = now().timeIntervalSince(entry.fetchedAt)
    return age <= Double(entry.maxAgeSeconds)
  }

  private func loadDataFromMemoryOrDisk(for mediaID: String) -> Data? {
    if let data = memoryStore[mediaID] {
      return data
    }

    let fileURL = dataFileURL(for: mediaID)
    guard let data = try? Data(contentsOf: fileURL) else {
      return nil
    }

    memoryStore[mediaID] = data
    return data
  }

  private func dataFileURL(for mediaID: String) -> URL {
    directoryURL.appendingPathComponent("\(mediaID).bin", isDirectory: false)
  }

  private func ensureCacheDirectoryExists() throws {
    if fileManager.fileExists(atPath: directoryURL.path) == false {
      try fileManager.createDirectory(at: directoryURL, withIntermediateDirectories: true)
    }
  }

  private func loadMetadataIfNeeded() async {
    guard hasLoadedMetadata == false else {
      return
    }

    hasLoadedMetadata = true

    guard let data = try? Data(contentsOf: metadataIndexURL) else {
      metadataStore = [:]
      return
    }

    metadataStore = (try? JSONDecoder().decode([String: MediaCacheEntry].self, from: data)) ?? [:]
  }

  private func persistMetadata() throws {
    try ensureCacheDirectoryExists()
    let data = try JSONEncoder().encode(metadataStore)
    try data.write(to: metadataIndexURL, options: .atomic)
  }
}
