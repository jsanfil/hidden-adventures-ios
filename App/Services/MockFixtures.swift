import Foundation

enum MockFixtures {
  static let uiTestEagleID = "AAAAAAAA-AAAA-AAAA-AAAA-AAAAAAAAAAAA"
  static let uiTestBluePoolID = "BBBBBBBB-BBBB-BBBB-BBBB-BBBBBBBBBBBB"
  static let jordanID = "user-jordan"
  static let eagleID = "adventure-eagle-creek"
  static let bluePoolID = "adventure-blue-pool"
  static let tomDickID = "adventure-tom-dick-harry"
  static let capeID = "adventure-cape-kiwanda"

  static let bootstrapDraft = ProfileBootstrapDraft(
    displayName: "Jordan",
    handle: "jordan",
    homeCity: "Portland",
    homeRegion: "OR",
    bio: "Weekend warrior exploring the PNW. Always searching for secret swimming spots and sunrise hikes.",
    initials: "JD"
  )

  static let profile = ProfileDetail(
    id: jordanID,
    handle: "jordan",
    displayName: "Jordan",
    bio: bootstrapDraft.bio,
    homeCity: "Portland",
    homeRegion: "OR",
    avatar: nil,
    cover: nil,
    createdAt: "2026-03-27T18:00:00Z",
    updatedAt: "2026-03-27T18:00:00Z"
  )

  static let feedItems: [AdventureCard] = [
    AdventureCard(
      id: eagleID,
      title: "Eagle Creek Trail to Tunnel Falls",
      summary: "A lush waterfall hike through cliffside bridges and basalt walls.",
      body: "One of the most cinematic hikes in the gorge, with tunnels, spray, and big payoff views.",
      categorySlug: .trails,
      categoryLabel: "Waterfall Hike",
      visibility: .public,
      createdAt: "2026-03-20T08:30:00Z",
      publishedAt: "2026-03-20T08:30:00Z",
      location: AdventureLocation(latitude: 45.6401, longitude: -121.9196),
      placeLabel: "Columbia River Gorge, OR",
      author: AdventureAuthor(handle: "jordan", displayName: "Jordan", homeCity: "Portland", homeRegion: "OR"),
      primaryMedia: MediaReference(id: "media-hero-mountain", storageKey: "hero-mountain"),
      stats: AdventureStats(favoriteCount: 2847, commentCount: 118, ratingCount: 847, averageRating: 4.9)
    ),
    AdventureCard(
      id: bluePoolID,
      title: "Blue Pool at Terwilliger Hot Springs",
      summary: "Electric blue water tucked into lava stone and cedar forest.",
      body: "The spring-fed pool feels unreal in person. Go early, pack layers, and expect the water to be freezing.",
      categorySlug: .waterSpots,
      categoryLabel: "Hidden Gem",
      visibility: .connections,
      createdAt: "2026-03-19T08:30:00Z",
      publishedAt: "2026-03-19T08:30:00Z",
      location: AdventureLocation(latitude: 44.3956, longitude: -122.0099),
      placeLabel: "Willamette National Forest, OR",
      author: AdventureAuthor(handle: "sarahk", displayName: "Sarah K.", homeCity: "Bend", homeRegion: "OR"),
      primaryMedia: MediaReference(id: "media-swimming-hole", storageKey: "swimming-hole"),
      stats: AdventureStats(favoriteCount: 1523, commentCount: 64, ratingCount: 847, averageRating: 4.8)
    ),
    AdventureCard(
      id: tomDickID,
      title: "Tom Dick & Harry Mountain",
      summary: "A ridge hike with wide-open views of Hood and Mirror Lake below.",
      body: "A reliable sunset mission with enough elevation to feel earned, but still approachable for a half day.",
      categorySlug: .viewpoints,
      categoryLabel: "Scenic View",
      visibility: .public,
      createdAt: "2026-03-18T08:30:00Z",
      publishedAt: "2026-03-18T08:30:00Z",
      location: AdventureLocation(latitude: 45.3739, longitude: -121.7162),
      placeLabel: "Mt. Hood, OR",
      author: AdventureAuthor(handle: "mikej", displayName: "Mike J.", homeCity: "Hood River", homeRegion: "OR"),
      primaryMedia: MediaReference(id: "media-scenic-overlook", storageKey: "scenic-overlook"),
      stats: AdventureStats(favoriteCount: 982, commentCount: 24, ratingCount: 126, averageRating: 4.7)
    ),
    AdventureCard(
      id: capeID,
      title: "Sunset Cliffs at Cape Kiwanda",
      summary: "Windy coastal dunes with dramatic headlands and golden-hour light.",
      body: "An easy stop with huge reward. Climb the dune carefully and watch for changing weather off the Pacific.",
      categorySlug: .roadsideStops,
      categoryLabel: "Coastal Walk",
      visibility: .public,
      createdAt: "2026-03-16T08:30:00Z",
      publishedAt: "2026-03-16T08:30:00Z",
      location: AdventureLocation(latitude: 45.2157, longitude: -123.9636),
      placeLabel: "Pacific City, OR",
      author: AdventureAuthor(handle: "amy", displayName: "Amy L.", homeCity: "Salem", homeRegion: "OR"),
      primaryMedia: MediaReference(id: "media-coastal-path", storageKey: "coastal-path"),
      stats: AdventureStats(favoriteCount: 892, commentCount: 16, ratingCount: 84, averageRating: 4.7)
    )
  ]

  static let imageNamesByAdventureID: [String: [String]] = [
    eagleID: ["hero-mountain", "scenic-overlook", "trail-forest"],
    bluePoolID: ["swimming-hole", "hidden-canyon", "trail-forest", "hero-mountain"],
    tomDickID: ["scenic-overlook", "trail-forest"],
    capeID: ["coastal-path", "hero-mountain"]
  ]

  static let adventureMedia: [String: [AdventureMediaItem]] = [
    eagleID: [
      AdventureMediaItem(id: "media-hero-mountain", sortOrder: 0, isPrimary: true, width: 1600, height: 1200),
      AdventureMediaItem(id: "media-scenic-overlook", sortOrder: 1, isPrimary: false, width: 1600, height: 1200),
      AdventureMediaItem(id: "media-trail-forest", sortOrder: 2, isPrimary: false, width: 1600, height: 1200)
    ],
    bluePoolID: [
      AdventureMediaItem(id: "media-swimming-hole", sortOrder: 0, isPrimary: true, width: 1600, height: 1200),
      AdventureMediaItem(id: "media-hidden-canyon", sortOrder: 1, isPrimary: false, width: 1600, height: 1200),
      AdventureMediaItem(id: "media-trail-forest", sortOrder: 2, isPrimary: false, width: 1600, height: 1200),
      AdventureMediaItem(id: "media-hero-mountain", sortOrder: 3, isPrimary: false, width: 1600, height: 1200)
    ],
    tomDickID: [
      AdventureMediaItem(id: "media-scenic-overlook", sortOrder: 0, isPrimary: true, width: 1600, height: 1200),
      AdventureMediaItem(id: "media-trail-forest", sortOrder: 1, isPrimary: false, width: 1600, height: 1200)
    ],
    capeID: [
      AdventureMediaItem(id: "media-coastal-path", sortOrder: 0, isPrimary: true, width: 1600, height: 1200),
      AdventureMediaItem(id: "media-hero-mountain", sortOrder: 1, isPrimary: false, width: 1600, height: 1200)
    ]
  ]

  static let adventureDetails: [String: AdventureDetail] = [
    eagleID: AdventureDetail(
      id: eagleID,
      title: feedItems[0].title,
      summary: feedItems[0].summary,
      body: feedItems[0].body,
      categorySlug: feedItems[0].categorySlug,
      categoryLabel: feedItems[0].categoryLabel,
      visibility: feedItems[0].visibility,
      createdAt: feedItems[0].createdAt,
      publishedAt: feedItems[0].publishedAt,
      location: feedItems[0].location,
      author: feedItems[0].author,
      primaryMedia: feedItems[0].primaryMedia,
      stats: feedItems[0].stats,
      placeLabel: feedItems[0].placeLabel,
      updatedAt: "2026-03-20T08:30:00Z"
    ),
    bluePoolID: AdventureDetail(
      id: bluePoolID,
      title: "Blue Pool at Tamolitch Falls",
      summary: "Blue Pool is one of Oregon's most stunning natural wonders.",
      body: "Blue Pool is one of Oregon's most stunning natural wonders. The pool's striking blue color comes from the McKenzie River emerging from underground lava flows, creating an otherworldly turquoise that has to be seen to be believed.",
      categorySlug: feedItems[1].categorySlug,
      categoryLabel: feedItems[1].categoryLabel,
      visibility: feedItems[1].visibility,
      createdAt: feedItems[1].createdAt,
      publishedAt: feedItems[1].publishedAt,
      location: feedItems[1].location,
      author: feedItems[1].author,
      primaryMedia: feedItems[1].primaryMedia,
      stats: AdventureStats(favoriteCount: 1523, commentCount: 64, ratingCount: 847, averageRating: 4.9),
      placeLabel: "McKenzie River Trail, Willamette NF",
      updatedAt: "2026-03-19T08:30:00Z"
    ),
    tomDickID: AdventureDetail(
      id: tomDickID,
      title: feedItems[2].title,
      summary: feedItems[2].summary,
      body: feedItems[2].body,
      categorySlug: feedItems[2].categorySlug,
      categoryLabel: feedItems[2].categoryLabel,
      visibility: feedItems[2].visibility,
      createdAt: feedItems[2].createdAt,
      publishedAt: feedItems[2].publishedAt,
      location: feedItems[2].location,
      author: feedItems[2].author,
      primaryMedia: feedItems[2].primaryMedia,
      stats: feedItems[2].stats,
      placeLabel: feedItems[2].placeLabel,
      updatedAt: "2026-03-18T08:30:00Z"
    ),
    capeID: AdventureDetail(
      id: capeID,
      title: feedItems[3].title,
      summary: feedItems[3].summary,
      body: feedItems[3].body,
      categorySlug: feedItems[3].categorySlug,
      categoryLabel: feedItems[3].categoryLabel,
      visibility: feedItems[3].visibility,
      createdAt: feedItems[3].createdAt,
      publishedAt: feedItems[3].publishedAt,
      location: feedItems[3].location,
      author: feedItems[3].author,
      primaryMedia: feedItems[3].primaryMedia,
      stats: feedItems[3].stats,
      placeLabel: feedItems[3].placeLabel,
      updatedAt: "2026-03-16T08:30:00Z"
    )
  ]

  static func resolvedAdventureID(for id: String) -> String {
    switch id {
    case uiTestEagleID:
      return eagleID
    case uiTestBluePoolID:
      return bluePoolID
    default:
      return id
    }
  }

  static func uiTestAdventureID(for id: String) -> String {
    switch id {
    case eagleID:
      return uiTestEagleID
    case bluePoolID:
      return uiTestBluePoolID
    default:
      return id
    }
  }
}
