import Foundation
import Testing

@testable import ScreenShotMaker

@Suite("Screen Per-Device Orientation Tests")
struct ScreenOrientationTests {

  // MARK: - Default & Accessor

  @Test("isLandscape(for:) defaults to false when not set")
  func testDefaultOrientationIsFalse() {
    let screen = Screen()
    #expect(screen.isLandscape(for: .iPhone) == false)
    #expect(screen.isLandscape(for: .iPad) == false)
    #expect(screen.isLandscape(for: .mac) == false)
  }

  @Test("setIsLandscape(_:for:) updates only the target category")
  func testSetOrientationForCategory() {
    var screen = Screen()
    screen.setIsLandscape(true, for: .iPhone)
    #expect(screen.isLandscape(for: .iPhone) == true)
    #expect(screen.isLandscape(for: .iPad) == false)  // unchanged
    #expect(screen.isLandscape(for: .mac) == false)   // unchanged
  }

  @Test("Different categories can have independent orientations")
  func testIndependentOrientationsPerCategory() {
    var screen = Screen()
    screen.setIsLandscape(true, for: .iPad)
    screen.setIsLandscape(false, for: .iPhone)

    #expect(screen.isLandscape(for: .iPhone) == false)
    #expect(screen.isLandscape(for: .iPad) == true)
  }

  @Test("setIsLandscape can be overwritten")
  func testOverwriteOrientation() {
    var screen = Screen()
    screen.setIsLandscape(true, for: .iPhone)
    screen.setIsLandscape(false, for: .iPhone)
    #expect(screen.isLandscape(for: .iPhone) == false)
  }

  // MARK: - init parameter

  @Test("init with isLandscapeByCategory stores values correctly")
  func testInitWithIsLandscapeByCategory() {
    let dict: [String: Bool] = ["iPhone": true, "iPad": false]
    let screen = Screen(isLandscapeByCategory: dict)
    #expect(screen.isLandscape(for: .iPhone) == true)
    #expect(screen.isLandscape(for: .iPad) == false)
    #expect(screen.isLandscape(for: .mac) == false)  // not in dict → fallback false
  }

  // MARK: - Codable round-trip

  @Test("Codable round-trip preserves isLandscapeByCategory")
  func testCodableRoundTrip() throws {
    var screen = Screen()
    screen.setIsLandscape(true, for: .iPhone)
    screen.setIsLandscape(false, for: .iPad)

    let data = try JSONEncoder().encode(screen)
    let decoded = try JSONDecoder().decode(Screen.self, from: data)

    #expect(decoded.isLandscape(for: .iPhone) == true)
    #expect(decoded.isLandscape(for: .iPad) == false)
    #expect(decoded.isLandscape(for: .mac) == false)
  }

  @Test("Codable: new format key isLandscapeByCategory is written (not legacy isLandscape)")
  func testEncodesNewKey() throws {
    var screen = Screen()
    screen.setIsLandscape(true, for: .iPhone)

    let data = try JSONEncoder().encode(screen)
    let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]

    #expect(json?["isLandscapeByCategory"] != nil)
    #expect(json?["isLandscape"] == nil)
  }

  // MARK: - Migration: legacy isLandscape: Bool

  @Test("Migration from legacy isLandscape: true populates iPhone and iPad")
  func testMigrationFromLegacyTrue() throws {
    // Simulate old .shotcraft JSON that has isLandscape: true
    let legacyJSON = """
      {
        "id": "00000000-0000-0000-0000-000000000001",
        "name": "Old Screen",
        "layoutPreset": "textTop",
        "localizedTexts": {"en": {"title": "", "subtitle": ""}},
        "background": {"solidColor": {"_0": {"hex": "#FFFFFF"}}},
        "showDeviceFrame": true,
        "isLandscape": true,
        "fontFamily": "SF Pro Display",
        "fontSizes": {},
        "textColorHex": "#FFFFFF",
        "titleStyle": {"isBold": true, "isItalic": false, "alignment": "center"},
        "subtitleStyle": {"isBold": false, "isItalic": false, "alignment": "center"},
        "deviceFrameConfig": {
          "frameColorHex": "#1F1F1F",
          "bezelWidthRatio": 1.0,
          "cornerRadiusRatio": 1.0,
          "showDynamicIsland": true,
          "dynamicIslandWidthRatio": 1.0,
          "dynamicIslandHeightRatio": 1.0
        },
        "screenshotContentMode": "fit",
        "textToImageSpacing": 20.0,
        "fitFrameToImage": false
      }
      """
    let data = legacyJSON.data(using: .utf8)!
    let screen = try JSONDecoder().decode(Screen.self, from: data)

    // supportsRotation == true categories (iPhone, iPad) should be migrated
    #expect(screen.isLandscape(for: .iPhone) == true)
    #expect(screen.isLandscape(for: .iPad) == true)
    // Non-rotation categories remain false
    #expect(screen.isLandscape(for: .mac) == false)
    #expect(screen.isLandscape(for: .appleWatch) == false)
    #expect(screen.isLandscape(for: .appleTV) == false)
  }

  @Test("Migration from legacy isLandscape: false keeps all categories false")
  func testMigrationFromLegacyFalse() throws {
    let legacyJSON = """
      {
        "id": "00000000-0000-0000-0000-000000000002",
        "name": "Old Screen",
        "layoutPreset": "textTop",
        "localizedTexts": {"en": {"title": "", "subtitle": ""}},
        "background": {"solidColor": {"_0": {"hex": "#FFFFFF"}}},
        "showDeviceFrame": true,
        "isLandscape": false,
        "fontFamily": "SF Pro Display",
        "fontSizes": {},
        "textColorHex": "#FFFFFF",
        "titleStyle": {"isBold": true, "isItalic": false, "alignment": "center"},
        "subtitleStyle": {"isBold": false, "isItalic": false, "alignment": "center"},
        "deviceFrameConfig": {
          "frameColorHex": "#1F1F1F",
          "bezelWidthRatio": 1.0,
          "cornerRadiusRatio": 1.0,
          "showDynamicIsland": true,
          "dynamicIslandWidthRatio": 1.0,
          "dynamicIslandHeightRatio": 1.0
        },
        "screenshotContentMode": "fit",
        "textToImageSpacing": 20.0,
        "fitFrameToImage": false
      }
      """
    let data = legacyJSON.data(using: .utf8)!
    let screen = try JSONDecoder().decode(Screen.self, from: data)

    #expect(screen.isLandscape(for: .iPhone) == false)
    #expect(screen.isLandscape(for: .iPad) == false)
  }

  @Test("Migration: missing isLandscape key results in all false (portrait)")
  func testMigrationNoOrientationKey() throws {
    let legacyJSON = """
      {
        "id": "00000000-0000-0000-0000-000000000003",
        "name": "Old Screen",
        "layoutPreset": "textTop",
        "localizedTexts": {"en": {"title": "", "subtitle": ""}},
        "background": {"solidColor": {"_0": {"hex": "#FFFFFF"}}},
        "showDeviceFrame": true,
        "fontFamily": "SF Pro Display",
        "fontSizes": {},
        "textColorHex": "#FFFFFF",
        "titleStyle": {"isBold": true, "isItalic": false, "alignment": "center"},
        "subtitleStyle": {"isBold": false, "isItalic": false, "alignment": "center"},
        "deviceFrameConfig": {
          "frameColorHex": "#1F1F1F",
          "bezelWidthRatio": 1.0,
          "cornerRadiusRatio": 1.0,
          "showDynamicIsland": true,
          "dynamicIslandWidthRatio": 1.0,
          "dynamicIslandHeightRatio": 1.0
        },
        "screenshotContentMode": "fit",
        "textToImageSpacing": 20.0,
        "fitFrameToImage": false
      }
      """
    let data = legacyJSON.data(using: .utf8)!
    let screen = try JSONDecoder().decode(Screen.self, from: data)

    #expect(screen.isLandscape(for: .iPhone) == false)
    #expect(screen.isLandscape(for: .iPad) == false)
  }
}
