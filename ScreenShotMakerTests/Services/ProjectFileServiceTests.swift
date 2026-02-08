import Foundation
import Testing

@testable import ScreenShotMaker

@Suite("ProjectFileService Tests")
struct ProjectFileServiceTests {
    private func tempFileURL(name: String = "test_project.ssmaker") -> URL {
        FileManager.default.temporaryDirectory.appendingPathComponent(name)
    }

    private func removeTempFile(at url: URL) {
        try? FileManager.default.removeItem(at: url)
    }

    @Test("Save and load round-trip preserves project data")
    func testSaveLoadRoundTrip() throws {
        let url = tempFileURL()
        defer { removeTempFile(at: url) }

        let project = ScreenShotProject(
            name: "Test Project",
            screens: [
                Screen(name: "Screen 1", title: "Hello", subtitle: "World"),
            ],
            selectedDevices: [DeviceSize.iPhoneSizes[0]],
            languages: [Language(code: "en", displayName: "English")]
        )

        try ProjectFileService.save(project, to: url)
        let loaded = try ProjectFileService.load(from: url)

        #expect(loaded.name == "Test Project")
        #expect(loaded.screens.count == 1)
        #expect(loaded.screens[0].name == "Screen 1")
        #expect(loaded.screens[0].title == "Hello")
        #expect(loaded.screens[0].subtitle == "World")
        #expect(loaded.selectedDevices.count == 1)
        #expect(loaded.languages.count == 1)
        #expect(loaded.languages[0].code == "en")
    }

    @Test("Save and load preserves screenshot image data")
    func testPreservesImageData() throws {
        let url = tempFileURL(name: "test_with_image.ssmaker")
        defer { removeTempFile(at: url) }

        let imageData = Data([0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A])
        var screen = Screen(name: "Screen 1", title: "T", subtitle: "S")
        screen.setScreenshotImageData(imageData, for: "en", category: .iPhone)

        let project = ScreenShotProject(
            name: "Image Project",
            screens: [screen]
        )

        try ProjectFileService.save(project, to: url)
        let loaded = try ProjectFileService.load(from: url)

        #expect(loaded.screens[0].screenshotImageData(for: "en", category: .iPhone) == imageData)
    }

    @Test("Save and load preserves multiple screens")
    func testMultipleScreens() throws {
        let url = tempFileURL(name: "test_multi.ssmaker")
        defer { removeTempFile(at: url) }

        let project = ScreenShotProject(
            name: "Multi",
            screens: [
                Screen(name: "A", title: "Title A", subtitle: "Sub A"),
                Screen(name: "B", title: "Title B", subtitle: "Sub B"),
                Screen(name: "C", title: "Title C", subtitle: "Sub C"),
            ]
        )

        try ProjectFileService.save(project, to: url)
        let loaded = try ProjectFileService.load(from: url)

        #expect(loaded.screens.count == 3)
        #expect(loaded.screens[0].name == "A")
        #expect(loaded.screens[1].name == "B")
        #expect(loaded.screens[2].name == "C")
    }

    @Test("Save and load preserves background styles")
    func testPreservesBackgroundStyles() throws {
        let url = tempFileURL(name: "test_bg.ssmaker")
        defer { removeTempFile(at: url) }

        var screen1 = Screen(name: "S1", title: "T", subtitle: "S")
        screen1.background = .solidColor(HexColor("#FF0000"))

        var screen2 = Screen(name: "S2", title: "T", subtitle: "S")
        screen2.background = .gradient(startColor: HexColor("#000000"), endColor: HexColor("#FFFFFF"))

        let project = ScreenShotProject(name: "BG Test", screens: [screen1, screen2])

        try ProjectFileService.save(project, to: url)
        let loaded = try ProjectFileService.load(from: url)

        if case .solidColor(let hex) = loaded.screens[0].background {
            #expect(hex.hex == "#FF0000")
        } else {
            Issue.record("Expected solidColor background")
        }

        if case .gradient(let start, let end) = loaded.screens[1].background {
            #expect(start.hex == "#000000")
            #expect(end.hex == "#FFFFFF")
        } else {
            Issue.record("Expected gradient background")
        }
    }

    @Test("Saved file is valid JSON")
    func testSavedFileIsValidJSON() throws {
        let url = tempFileURL(name: "test_json.ssmaker")
        defer { removeTempFile(at: url) }

        let project = ScreenShotProject()
        try ProjectFileService.save(project, to: url)

        let data = try Data(contentsOf: url)
        let json = try JSONSerialization.jsonObject(with: data)
        #expect(json is [String: Any])
    }

    @Test("Load fails with corrupted data")
    func testLoadCorruptedData() throws {
        let url = tempFileURL(name: "test_corrupt.ssmaker")
        defer { removeTempFile(at: url) }

        try Data("not valid json".utf8).write(to: url)

        #expect(throws: DecodingError.self) {
            try ProjectFileService.load(from: url)
        }
    }
}
