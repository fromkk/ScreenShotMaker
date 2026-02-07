import Foundation
import Testing
@testable import ScreenShotMaker

@Suite("LayoutPreset Tests")
struct LayoutPresetTests {

    @Test("All cases count is 5")
    func testAllCasesCount() {
        #expect(LayoutPreset.allCases.count == 5)
    }

    @Test("Each case encodes and decodes correctly")
    func testCodableRoundTrip() throws {
        for preset in LayoutPreset.allCases {
            let data = try JSONEncoder().encode(preset)
            let decoded = try JSONDecoder().decode(LayoutPreset.self, from: data)
            #expect(decoded == preset)
        }
    }

    @Test("Each case has a non-empty display name")
    func testDisplayName() {
        for preset in LayoutPreset.allCases {
            #expect(!preset.displayName.isEmpty)
        }
    }

    @Test("Raw values match expected strings")
    func testRawValues() {
        #expect(LayoutPreset.textTop.rawValue == "textTop")
        #expect(LayoutPreset.textOverlay.rawValue == "textOverlay")
        #expect(LayoutPreset.textBottom.rawValue == "textBottom")
        #expect(LayoutPreset.textOnly.rawValue == "textOnly")
        #expect(LayoutPreset.screenshotOnly.rawValue == "screenshotOnly")
    }

    @Test("ID is based on rawValue")
    func testIdentifiable() {
        for preset in LayoutPreset.allCases {
            #expect(preset.id == preset.rawValue)
        }
    }
}
