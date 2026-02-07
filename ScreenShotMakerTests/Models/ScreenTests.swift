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
        #expect(screen.fontSize == 28)
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
        #expect(decoded.fontSize == screen.fontSize)
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
        #expect(screen.fontSize == 40)
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
}
