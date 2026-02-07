import Foundation
import Testing

@testable import ScreenShotMaker

@Suite("ImageLoader Tests")
struct ImageLoaderTests {
    // Minimal valid PNG: 1x1 pixel, RGBA
    private static let validPNGData: Data = {
        // PNG signature + IHDR + IDAT + IEND (1x1 white pixel)
        let bytes: [UInt8] = [
            0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, // PNG signature
            0x00, 0x00, 0x00, 0x0D, 0x49, 0x48, 0x44, 0x52, // IHDR chunk length + type
            0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01, // 1x1
            0x08, 0x02, 0x00, 0x00, 0x00, 0x90, 0x77, 0x53, // 8-bit RGB
            0xDE, 0x00, 0x00, 0x00, 0x0C, 0x49, 0x44, 0x41, // IDAT chunk
            0x54, 0x08, 0xD7, 0x63, 0xF8, 0xCF, 0xC0, 0x00,
            0x00, 0x00, 0x02, 0x00, 0x01, 0xE2, 0x21, 0xBC,
            0x33, 0x00, 0x00, 0x00, 0x00, 0x49, 0x45, 0x4E, // IEND chunk
            0x44, 0xAE, 0x42, 0x60, 0x82,
        ]
        return Data(bytes)
    }()

    // Minimal JPEG data (JFIF header)
    private static let validJPEGData: Data = {
        let bytes: [UInt8] = [
            0xFF, 0xD8, 0xFF, 0xE0, 0x00, 0x10, 0x4A, 0x46,
            0x49, 0x46, 0x00, 0x01, 0x01, 0x00, 0x00, 0x01,
            0x00, 0x01, 0x00, 0x00, 0xFF, 0xD9,
        ]
        return Data(bytes)
    }()

    private func createTempFile(name: String, data: Data) throws -> URL {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(name)
        try data.write(to: url)
        return url
    }

    private func removeTempFile(at url: URL) {
        try? FileManager.default.removeItem(at: url)
    }

    // MARK: - Success Cases

    @Test("Load valid PNG file")
    func testLoadPNG() throws {
        let url = try createTempFile(name: "test_image.png", data: Self.validPNGData)
        defer { removeTempFile(at: url) }

        let data = try ImageLoader.loadImage(from: url)
        #expect(data == Self.validPNGData)
    }

    @Test("Load valid JPEG file with .jpg extension")
    func testLoadJPG() throws {
        let url = try createTempFile(name: "test_image.jpg", data: Self.validJPEGData)
        defer { removeTempFile(at: url) }

        let data = try ImageLoader.loadImage(from: url)
        #expect(data == Self.validJPEGData)
    }

    @Test("Load valid JPEG file with .jpeg extension")
    func testLoadJPEG() throws {
        let url = try createTempFile(name: "test_image.jpeg", data: Self.validJPEGData)
        defer { removeTempFile(at: url) }

        let data = try ImageLoader.loadImage(from: url)
        #expect(data == Self.validJPEGData)
    }

    // MARK: - Error Cases

    @Test("Reject file not found")
    func testFileNotFound() {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("nonexistent.png")
        #expect(throws: ImageLoadError.fileNotFound) {
            try ImageLoader.loadImage(from: url)
        }
    }

    @Test("Reject invalid format")
    func testInvalidFormat() throws {
        let url = try createTempFile(name: "test_file.txt", data: Data("hello".utf8))
        defer { removeTempFile(at: url) }

        #expect(throws: ImageLoadError.invalidFormat) {
            try ImageLoader.loadImage(from: url)
        }
    }

    @Test("Reject unsupported image format (GIF)")
    func testUnsupportedFormat() throws {
        let url = try createTempFile(name: "test_image.gif", data: Data([0x47, 0x49, 0x46]))
        defer { removeTempFile(at: url) }

        #expect(throws: ImageLoadError.invalidFormat) {
            try ImageLoader.loadImage(from: url)
        }
    }

    @Test("Reject file exceeding 20MB")
    func testFileTooLarge() throws {
        let largeData = Data(repeating: 0x00, count: 21 * 1024 * 1024)
        let url = try createTempFile(name: "large_image.png", data: largeData)
        defer { removeTempFile(at: url) }

        #expect {
            try ImageLoader.loadImage(from: url)
        } throws: { error in
            guard let imageError = error as? ImageLoadError,
                  case .fileTooLarge = imageError else {
                return false
            }
            return true
        }
    }

    // MARK: - Edge Cases

    @Test("Accept file exactly at 20MB limit")
    func testFileAtExactLimit() throws {
        let exactData = Data(repeating: 0x89, count: 20 * 1024 * 1024)
        let url = try createTempFile(name: "exact_limit.png", data: exactData)
        defer { removeTempFile(at: url) }

        let data = try ImageLoader.loadImage(from: url)
        #expect(data.count == 20 * 1024 * 1024)
    }

    @Test("Case insensitive extension (.PNG)")
    func testUppercaseExtension() throws {
        let url = try createTempFile(name: "test_IMAGE.PNG", data: Self.validPNGData)
        defer { removeTempFile(at: url) }

        let data = try ImageLoader.loadImage(from: url)
        #expect(data == Self.validPNGData)
    }

    @Test("maxFileSize is 20MB")
    func testMaxFileSize() {
        #expect(ImageLoader.maxFileSize == 20 * 1024 * 1024)
    }
}
