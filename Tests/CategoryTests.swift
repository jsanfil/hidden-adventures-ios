import Foundation
import XCTest
@testable import HiddenAdventures

final class CategoryTests: XCTestCase {
  func testCategoryAllCasesMatchesLockedTaxonomy() {
    XCTAssertEqual(
      Category.allCases.map(\.rawValue),
      [
        "viewpoints",
        "trails",
        "water_spots",
        "food_drink",
        "abandoned_places",
        "caves",
        "nature_escapes",
        "roadside_stops"
      ]
    )
  }

  func testCategoryDecodesCanonicalSlugs() throws {
    let decoder = JSONDecoder()

    XCTAssertEqual(try decoder.decode(Category.self, from: Data(#""viewpoints""#.utf8)), .viewpoints)
    XCTAssertEqual(try decoder.decode(Category.self, from: Data(#""trails""#.utf8)), .trails)
    XCTAssertEqual(try decoder.decode(Category.self, from: Data(#""water_spots""#.utf8)), .waterSpots)
    XCTAssertEqual(try decoder.decode(Category.self, from: Data(#""food_drink""#.utf8)), .foodDrink)
    XCTAssertEqual(
      try decoder.decode(Category.self, from: Data(#""abandoned_places""#.utf8)),
      .abandonedPlaces
    )
    XCTAssertEqual(try decoder.decode(Category.self, from: Data(#""caves""#.utf8)), .caves)
    XCTAssertEqual(
      try decoder.decode(Category.self, from: Data(#""nature_escapes""#.utf8)),
      .natureEscapes
    )
    XCTAssertEqual(
      try decoder.decode(Category.self, from: Data(#""roadside_stops""#.utf8)),
      .roadsideStops
    )
  }

  func testCategoryRejectsRemovedLegacySlugs() {
    let decoder = JSONDecoder()

    XCTAssertThrowsError(try decoder.decode(Category.self, from: Data(#""forest_walks""#.utf8)))
    XCTAssertThrowsError(try decoder.decode(Category.self, from: Data(#""desert_spots""#.utf8)))
    XCTAssertThrowsError(try decoder.decode(Category.self, from: Data(#""other""#.utf8)))
  }
}
