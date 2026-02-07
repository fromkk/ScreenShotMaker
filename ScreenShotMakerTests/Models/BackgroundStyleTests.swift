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
        let style = BackgroundStyle.image(path: "test.png")
        let data = try JSONEncoder().encode(style)
        let decoded = try JSONDecoder().decode(BackgroundStyle.self, from: data)

        if case .image(let path) = decoded {
            #expect(path == "test.png")
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
}
