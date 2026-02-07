import Testing
import SwiftUI
@testable import ScreenShotMaker

@Suite("BackgroundStyle Tests")
struct BackgroundStyleTests {

    @Test("solidColor encodes and decodes correctly")
    func testSolidColorCodable() throws {
        let style = BackgroundStyle.solidColor(HexColor("#FF0000"))
        let data = try JSONEncoder().encode(style)
        let decoded = try JSONDecoder().decode(BackgroundStyle.self, from: data)

        if case .solidColor(let hex) = decoded {
            #expect(hex.hex == "#FF0000")
        } else {
            Issue.record("Expected solidColor case")
        }
    }

    @Test("gradient encodes and decodes correctly")
    func testGradientCodable() throws {
        let style = BackgroundStyle.gradient(
            startColor: HexColor("#667EEA"),
            endColor: HexColor("#764BA2")
        )
        let data = try JSONEncoder().encode(style)
        let decoded = try JSONDecoder().decode(BackgroundStyle.self, from: data)

        if case .gradient(let start, let end) = decoded {
            #expect(start.hex == "#667EEA")
            #expect(end.hex == "#764BA2")
        } else {
            Issue.record("Expected gradient case")
        }
    }

    @Test("image encodes and decodes correctly")
    func testImageCodable() throws {
        let imageData = Data([0x89, 0x50, 0x4E, 0x47]) // PNG header bytes
        let style = BackgroundStyle.image(data: imageData)
        let encoded = try JSONEncoder().encode(style)
        let decoded = try JSONDecoder().decode(BackgroundStyle.self, from: encoded)

        if case .image(let decodedData) = decoded {
            #expect(decodedData == imageData)
        } else {
            Issue.record("Expected image case")
        }
    }

    @Test("HexColor converts to SwiftUI Color")
    func testHexColorToSwiftUIColor() {
        let hexColor = HexColor("#FF0000")
        // Color の直接比較は困難なため、生成がクラッシュしないことを確認
        let _ = hexColor.color
    }

    @Test("Color initializes from hex with hash")
    func testHexColorWithHash() {
        let color = Color(hex: "#00FF00")
        let _ = color // 生成成功を確認
    }

    @Test("Color initializes from hex without hash")
    func testHexColorWithoutHash() {
        let color = Color(hex: "0000FF")
        let _ = color // 生成成功を確認
    }

    @Test("Color toHex returns valid hex string")
    func testColorToHex() {
        let hex = Color(hex: "#FF0000").toHex()
        #expect(hex.hasPrefix("#"))
        #expect(hex.count == 7)
        #expect(hex == "#FF0000")
    }

    @Test("Color toHex roundtrip")
    func testColorToHexRoundtrip() {
        let original = "#00FF00"
        let hex = Color(hex: original).toHex()
        #expect(hex == original)
    }
}
