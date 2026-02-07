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
}
