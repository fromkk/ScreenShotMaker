import Foundation
import Testing

@testable import ScreenShotMaker

@Suite("Screen Model Tests")
struct ScreenTests {

  @Test("Screen initializes with default values")
  func testScreenDefaultValues() {
    let screen = Screen()
    #expect(screen.name == "New Screen")
    #expect(screen.layoutPreset == .textTop)
    #expect(screen.title == "")
    #expect(screen.subtitle == "")
    #expect(screen.fontSize(for: .iPhone) == 96)
    #expect(screen.textColorHex == "#FFFFFF")
    #expect(screen.showDeviceFrame == true)
    #expect(screen.fontFamily == "SF Pro Display")
    #expect(screen.screenshotImageData == nil)
  }

  @Test("Screen encodes and decodes correctly")
  func testScreenCodableRoundTrip() throws {
    let screen = Screen(
      name: "Test",
      layoutPreset: .textBottom,
      title: "Hello",
      subtitle: "World",
      background: .solidColor(HexColor("#FF0000")),
      showDeviceFrame: false,
      fontFamily: "Helvetica",
      fontSize: 32,
      textColorHex: "#000000"
    )

    let data = try JSONEncoder().encode(screen)
    let decoded = try JSONDecoder().decode(Screen.self, from: data)

    #expect(decoded.name == screen.name)
    #expect(decoded.layoutPreset == screen.layoutPreset)
    #expect(decoded.title == screen.title)
    #expect(decoded.subtitle == screen.subtitle)
    #expect(decoded.showDeviceFrame == screen.showDeviceFrame)
    #expect(decoded.fontFamily == screen.fontFamily)
    #expect(decoded.fontSize(for: .iPhone) == screen.fontSize(for: .iPhone))
    #expect(decoded.textColorHex == screen.textColorHex)
  }

  @Test("Screen stores screenshot image data")
  func testScreenImageDataStorage() {
    var screen = Screen()
    let testData = Data([0x89, 0x50, 0x4E, 0x47])
    screen.screenshotImageData = testData
    #expect(screen.screenshotImageData == testData)
  }

  @Test("Screen initializes with custom values")
  func testScreenCustomInit() {
    let screen = Screen(
      name: "Custom",
      layoutPreset: .screenshotOnly,
      title: "Title",
      subtitle: "Sub",
      fontSize: 40
    )
    #expect(screen.name == "Custom")
    #expect(screen.layoutPreset == .screenshotOnly)
    #expect(screen.title == "Title")
    #expect(screen.subtitle == "Sub")
    #expect(screen.fontSize(for: .iPhone) == 40)
  }

  // MARK: - Localized Text Tests

  @Test("Screen stores localized texts per language")
  func testLocalizedTexts() {
    var screen = Screen(title: "Hello", subtitle: "World")
    #expect(screen.text(for: "en").title == "Hello")
    #expect(screen.text(for: "en").subtitle == "World")

    screen.setText(LocalizedText(title: "こんにちは", subtitle: "世界"), for: "ja")
    #expect(screen.text(for: "ja").title == "こんにちは")
    #expect(screen.text(for: "ja").subtitle == "世界")
    // English unchanged
    #expect(screen.text(for: "en").title == "Hello")
  }

  @Test("Screen returns empty text for missing language")
  func testMissingLanguageReturnsEmpty() {
    let screen = Screen(title: "Hello")
    let text = screen.text(for: "fr")
    #expect(text.title == "")
    #expect(text.subtitle == "")
  }

  @Test("copyTextToAllLanguages copies to all specified languages")
  func testCopyToAllLanguages() {
    var screen = Screen(title: "Hello", subtitle: "World")
    screen.copyTextToAllLanguages(from: "en", languages: ["en", "ja", "fr"])
    #expect(screen.text(for: "ja").title == "Hello")
    #expect(screen.text(for: "fr").title == "Hello")
  }

  @Test("Screen decodes legacy format without localizedTexts")
  func testLegacyFormatMigration() throws {
    let legacyJSON = """
      {
          "id": "00000000-0000-0000-0000-000000000001",
          "name": "Screen 1",
          "layoutPreset": "textTop",
          "title": "Legacy Title",
          "subtitle": "Legacy Sub",
          "background": {"solidColor": {"_0": {"hex": "#FF0000"}}},
          "showDeviceFrame": true,
          "fontFamily": "SF Pro Display",
          "fontSize": 28,
          "textColorHex": "#FFFFFF"
      }
      """
    let data = Data(legacyJSON.utf8)
    let screen = try JSONDecoder().decode(Screen.self, from: data)
    #expect(screen.title == "Legacy Title")
    #expect(screen.subtitle == "Legacy Sub")
    #expect(screen.text(for: "en").title == "Legacy Title")
  }

  @Test("Screen encodes and decodes localizedTexts correctly")
  func testLocalizedTextsCodableRoundTrip() throws {
    var screen = Screen(title: "Hello", subtitle: "World")
    screen.setText(LocalizedText(title: "Bonjour", subtitle: "Monde"), for: "fr")

    let data = try JSONEncoder().encode(screen)
    let decoded = try JSONDecoder().decode(Screen.self, from: data)

    #expect(decoded.text(for: "en").title == "Hello")
    #expect(decoded.text(for: "en").subtitle == "World")
    #expect(decoded.text(for: "fr").title == "Bonjour")
    #expect(decoded.text(for: "fr").subtitle == "Monde")
  }

  // MARK: - Landscape Tests

  @Test("Screen defaults to portrait")
  func testScreenDefaultPortrait() {
    let screen = Screen()
    #expect(screen.isLandscape == false)
  }

  @Test("Screen landscape encodes and decodes")
  func testScreenLandscapeCodable() throws {
    var screen = Screen(name: "Landscape Test")
    screen.isLandscape = true

    let data = try JSONEncoder().encode(screen)
    let decoded = try JSONDecoder().decode(Screen.self, from: data)

    #expect(decoded.isLandscape == true)
  }

  @Test("Screen decodes legacy format without isLandscape")
  func testLegacyFormatWithoutLandscape() throws {
    let legacyJSON = """
      {
          "id": "00000000-0000-0000-0000-000000000002",
          "name": "Screen 1",
          "layoutPreset": "textTop",
          "title": "Title",
          "subtitle": "Sub",
          "background": {"solidColor": {"_0": {"hex": "#FF0000"}}},
          "showDeviceFrame": true,
          "fontFamily": "SF Pro Display",
          "fontSize": 28,
          "textColorHex": "#FFFFFF"
      }
      """
    let data = Data(legacyJSON.utf8)
    let screen = try JSONDecoder().decode(Screen.self, from: data)
    #expect(screen.isLandscape == false)
  }

  // MARK: - TextStyle Tests

  @Test("TextStyle defaults")
  func testTextStyleDefaults() {
    let style = TextStyle()
    #expect(style.isBold == true)
    #expect(style.isItalic == false)
    #expect(style.alignment == .center)
  }

  @Test("TextStyle encodes and decodes correctly")
  func testTextStyleCodable() throws {
    let style = TextStyle(isBold: false, isItalic: true, alignment: .trailing)
    let data = try JSONEncoder().encode(style)
    let decoded = try JSONDecoder().decode(TextStyle.self, from: data)
    #expect(decoded.isBold == false)
    #expect(decoded.isItalic == true)
    #expect(decoded.alignment == .trailing)
  }

  @Test("Screen titleStyle and subtitleStyle defaults")
  func testScreenTextStyleDefaults() {
    let screen = Screen()
    #expect(screen.titleStyle.isBold == true)
    #expect(screen.subtitleStyle.isBold == false)
  }

  @Test("Screen titleStyle persists through encoding")
  func testScreenTextStyleCodable() throws {
    var screen = Screen(name: "Style Test")
    screen.titleStyle = TextStyle(isBold: false, isItalic: true, alignment: .leading)

    let data = try JSONEncoder().encode(screen)
    let decoded = try JSONDecoder().decode(Screen.self, from: data)

    #expect(decoded.titleStyle.isBold == false)
    #expect(decoded.titleStyle.isItalic == true)
    #expect(decoded.titleStyle.alignment == .leading)
  }

  @Test("Screen decodes legacy format without textStyle")
  func testLegacyFormatWithoutTextStyle() throws {
    let legacyJSON = """
      {
          "id": "00000000-0000-0000-0000-000000000003",
          "name": "Screen 1",
          "layoutPreset": "textTop",
          "title": "Title",
          "subtitle": "Sub",
          "background": {"solidColor": {"_0": {"hex": "#FF0000"}}},
          "showDeviceFrame": true,
          "fontFamily": "SF Pro Display",
          "fontSize": 28,
          "textColorHex": "#FFFFFF"
      }
      """
    let data = Data(legacyJSON.utf8)
    let screen = try JSONDecoder().decode(Screen.self, from: data)
    #expect(screen.titleStyle.isBold == true)
    #expect(screen.subtitleStyle.isBold == false)
  }

  // MARK: - ScreenshotContentMode Tests (#031)

  @Test("ScreenshotContentMode defaults to fit")
  func testScreenshotContentModeDefault() {
    let screen = Screen()
    #expect(screen.screenshotContentMode == .fit)
  }

  @Test("ScreenshotContentMode encodes and decodes correctly")
  func testScreenshotContentModeCodable() throws {
    var screen = Screen(name: "ContentMode Test")
    screen.screenshotContentMode = .fill

    let data = try JSONEncoder().encode(screen)
    let decoded = try JSONDecoder().decode(Screen.self, from: data)

    #expect(decoded.screenshotContentMode == .fill)
  }

  @Test("Screen decodes legacy format without screenshotContentMode")
  func testLegacyFormatWithoutContentMode() throws {
    let legacyJSON = """
      {
          "id": "00000000-0000-0000-0000-000000000004",
          "name": "Screen 1",
          "layoutPreset": "textTop",
          "title": "Title",
          "subtitle": "Sub",
          "background": {"solidColor": {"_0": {"hex": "#FF0000"}}},
          "showDeviceFrame": true,
          "fontFamily": "SF Pro Display",
          "fontSize": 28,
          "textColorHex": "#FFFFFF"
      }
      """
    let data = Data(legacyJSON.utf8)
    let screen = try JSONDecoder().decode(Screen.self, from: data)
    #expect(screen.screenshotContentMode == .fit)
  }

  // MARK: - DeviceFrameConfig Tests (#028)

  @Test("DeviceFrameConfig defaults")
  func testDeviceFrameConfigDefaults() {
    let config = DeviceFrameConfig.default
    #expect(config.frameColorHex == "#1F1F1F")
    #expect(config.bezelWidthRatio == 1.0)
    #expect(config.cornerRadiusRatio == 1.0)
    #expect(config.showDynamicIsland == true)
    #expect(config.dynamicIslandWidthRatio == 1.0)
    #expect(config.dynamicIslandHeightRatio == 1.0)
  }

  @Test("DeviceFrameConfig encodes and decodes correctly")
  func testDeviceFrameConfigCodable() throws {
    let config = DeviceFrameConfig(
      frameColorHex: "#FFFFFF",
      bezelWidthRatio: 0.5,
      cornerRadiusRatio: 0.8,
      showDynamicIsland: false,
      dynamicIslandWidthRatio: 0.7,
      dynamicIslandHeightRatio: 0.6
    )

    let data = try JSONEncoder().encode(config)
    let decoded = try JSONDecoder().decode(DeviceFrameConfig.self, from: data)

    #expect(decoded.frameColorHex == "#FFFFFF")
    #expect(decoded.bezelWidthRatio == 0.5)
    #expect(decoded.cornerRadiusRatio == 0.8)
    #expect(decoded.showDynamicIsland == false)
    #expect(decoded.dynamicIslandWidthRatio == 0.7)
    #expect(decoded.dynamicIslandHeightRatio == 0.6)
  }

  @Test("Screen decodes legacy format without deviceFrameConfig")
  func testLegacyFormatWithoutDeviceFrameConfig() throws {
    let legacyJSON = """
      {
          "id": "00000000-0000-0000-0000-000000000005",
          "name": "Screen 1",
          "layoutPreset": "textTop",
          "title": "Title",
          "subtitle": "Sub",
          "background": {"solidColor": {"_0": {"hex": "#FF0000"}}},
          "showDeviceFrame": true,
          "fontFamily": "SF Pro Display",
          "fontSize": 28,
          "textColorHex": "#FFFFFF"
      }
      """
    let data = Data(legacyJSON.utf8)
    let screen = try JSONDecoder().decode(Screen.self, from: data)
    #expect(screen.deviceFrameConfig == .default)
  }

  @Test("DeviceFrameConfig persists through Screen encoding")
  func testDeviceFrameConfigInScreen() throws {
    var screen = Screen(name: "Frame Config Test")
    screen.deviceFrameConfig = DeviceFrameConfig(
      frameColorHex: "#333333",
      bezelWidthRatio: 1.5,
      cornerRadiusRatio: 0.5,
      showDynamicIsland: false,
      dynamicIslandWidthRatio: 0.8,
      dynamicIslandHeightRatio: 0.9
    )

    let data = try JSONEncoder().encode(screen)
    let decoded = try JSONDecoder().decode(Screen.self, from: data)

    #expect(decoded.deviceFrameConfig.frameColorHex == "#333333")
    #expect(decoded.deviceFrameConfig.bezelWidthRatio == 1.5)
    #expect(decoded.deviceFrameConfig.showDynamicIsland == false)
    #expect(decoded.deviceFrameConfig.dynamicIslandWidthRatio == 0.8)
  }

  // MARK: - Per-Language Screenshot Image Tests (#039)

  @Test("Screen stores screenshot images per language and device")
  func testPerLanguageScreenshotImages() {
    var screen = Screen()
    let iPhoneData = Data([1, 2, 3])
    let iPadData = Data([4, 5, 6])

    // Set images for English
    screen.setScreenshotImageData(iPhoneData, for: "en", category: .iPhone)
    screen.setScreenshotImageData(iPadData, for: "en", category: .iPad)

    // Verify retrieval
    #expect(screen.screenshotImageData(for: "en", category: .iPhone) == iPhoneData)
    #expect(screen.screenshotImageData(for: "en", category: .iPad) == iPadData)

    // Japanese should be nil
    #expect(screen.screenshotImageData(for: "ja", category: .iPhone) == nil)
  }

  @Test("Language addition copies images independently")
  func testLanguageAdditionCopiesImages() {
    var screen = Screen()
    let imageData = Data([1, 2, 3])
    screen.setScreenshotImageData(imageData, for: "en", category: .iPhone)

    // Copy to Japanese (simulating language addition)
    if let data = screen.screenshotImageData(for: "en", category: .iPhone) {
      screen.setScreenshotImageData(data, for: "ja", category: .iPhone)
    }

    #expect(screen.screenshotImageData(for: "ja", category: .iPhone) == imageData)

    // Modify English image
    let newData = Data([7, 8, 9])
    screen.setScreenshotImageData(newData, for: "en", category: .iPhone)

    // Japanese image should remain unchanged (independent)
    #expect(screen.screenshotImageData(for: "ja", category: .iPhone) == imageData)
    #expect(screen.screenshotImageData(for: "en", category: .iPhone) == newData)
  }

  @Test("Screenshot image removal per language and device")
  func testScreenshotImageRemoval() {
    var screen = Screen()
    let data = Data([1, 2, 3])
    screen.setScreenshotImageData(data, for: "en", category: .iPhone)
    screen.setScreenshotImageData(data, for: "ja", category: .iPhone)

    // Remove English image
    screen.setScreenshotImageData(nil, for: "en", category: .iPhone)

    #expect(screen.screenshotImageData(for: "en", category: .iPhone) == nil)
    #expect(screen.screenshotImageData(for: "ja", category: .iPhone) == data)
  }

  @Test("Screen migrates old device-only format to language-device format")
  func testScreenshotImageMigrationFromDeviceOnly() throws {
    // Create a screen with old format (device-only keys)
    var oldScreen = Screen(name: "Screen 1")
    oldScreen.screenshotImages = ["iPhone": Data([1, 2, 3]), "iPad": Data([4, 5, 6])]

    // Encode and decode to trigger migration
    let encodedData = try JSONEncoder().encode(oldScreen)
    let screen = try JSONDecoder().decode(Screen.self, from: encodedData)

    // Old format "iPhone" should migrate to "en-iPhone"
    #expect(screen.screenshotImageData(for: "en", category: .iPhone) == Data([1, 2, 3]))
    #expect(screen.screenshotImageData(for: "en", category: .iPad) == Data([4, 5, 6]))
  }

  @Test("Screen migrates very old single image format to language-device format")
  func testScreenshotImageMigrationFromSingleImage() throws {
    // Create a screen with very old format (single screenshotImageData)
    var oldScreen = Screen(name: "Screen 1")
    // Simulate the very old format by using the legacy property
    oldScreen.screenshotImages = ["iPhone": Data([1, 2, 3])]

    // Encode and decode to trigger migration
    let encodedData = try JSONEncoder().encode(oldScreen)
    let screen = try JSONDecoder().decode(Screen.self, from: encodedData)

    // Should be accessible via new API
    #expect(screen.screenshotImageData(for: "en", category: .iPhone) != nil)
  }

  @Test("Screen preserves new language-device format")
  func testScreenshotImageNewFormatPreservation() throws {
    var screen = Screen(name: "New Format Test")
    screen.setScreenshotImageData(Data([1, 2, 3]), for: "en", category: .iPhone)
    screen.setScreenshotImageData(Data([4, 5, 6]), for: "ja", category: .iPhone)
    screen.setScreenshotImageData(Data([7, 8, 9]), for: "en", category: .iPad)

    let encoded = try JSONEncoder().encode(screen)
    let decoded = try JSONDecoder().decode(Screen.self, from: encoded)

    #expect(decoded.screenshotImageData(for: "en", category: .iPhone) == Data([1, 2, 3]))
    #expect(decoded.screenshotImageData(for: "ja", category: .iPhone) == Data([4, 5, 6]))
    #expect(decoded.screenshotImageData(for: "en", category: .iPad) == Data([7, 8, 9]))
    #expect(decoded.screenshotImageData(for: "ja", category: .iPad) == nil)
  }

  // MARK: - Per-Device Font Size Tests (#056)

  @Test("Screen stores font sizes per device category")
  func testPerDeviceFontSizes() {
    var screen = Screen()
    screen.setFontSize(96, for: .iPhone)
    screen.setFontSize(120, for: .iPad)
    screen.setFontSize(80, for: .mac)

    #expect(screen.fontSize(for: .iPhone) == 96)
    #expect(screen.fontSize(for: .iPad) == 120)
    #expect(screen.fontSize(for: .mac) == 80)
  }

  @Test("Screen returns default font size for unset device category")
  func testPerDeviceFontSizeDefault() {
    let screen = Screen()
    #expect(screen.fontSize(for: .iPhone) == Screen.defaultFontSize)
    #expect(screen.fontSize(for: .iPad) == Screen.defaultFontSize)
    #expect(screen.fontSize(for: .mac) == Screen.defaultFontSize)
  }

  @Test("Screen font sizes encode and decode correctly")
  func testPerDeviceFontSizeCodable() throws {
    var screen = Screen(name: "Font Size Test")
    screen.setFontSize(80, for: .iPhone)
    screen.setFontSize(120, for: .iPad)

    let data = try JSONEncoder().encode(screen)
    let decoded = try JSONDecoder().decode(Screen.self, from: data)

    #expect(decoded.fontSize(for: .iPhone) == 80)
    #expect(decoded.fontSize(for: .iPad) == 120)
  }

  @Test("Screen migrates legacy single fontSize to per-device fontSizes")
  func testFontSizeMigrationFromLegacy() throws {
    let legacyJSON = """
      {
          "id": "00000000-0000-0000-0000-000000000099",
          "name": "Screen 1",
          "layoutPreset": "textTop",
          "title": "Title",
          "subtitle": "Sub",
          "background": {"solidColor": {"_0": {"hex": "#FF0000"}}},
          "showDeviceFrame": true,
          "fontFamily": "SF Pro Display",
          "fontSize": 48,
          "textColorHex": "#FFFFFF"
      }
      """
    let data = Data(legacyJSON.utf8)
    let screen = try JSONDecoder().decode(Screen.self, from: data)

    // Legacy fontSize should be migrated to all device categories
    #expect(screen.fontSize(for: .iPhone) == 48)
    #expect(screen.fontSize(for: .iPad) == 48)
    #expect(screen.fontSize(for: .mac) == 48)
  }

  @Test("Screen with custom fontSize init sets value for all categories")
  func testCustomFontSizeInit() {
    let screen = Screen(fontSize: 40)
    #expect(screen.fontSize(for: .iPhone) == 40)
    #expect(screen.fontSize(for: .iPad) == 40)
  }
}
