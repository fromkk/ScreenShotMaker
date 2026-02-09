import Foundation
import Testing

@testable import ScreenShotMaker

#if canImport(AppKit)
  import AppKit
#endif
#if canImport(UIKit)
  import UIKit
#endif

@Suite("ExportService Tests")
@MainActor
struct ExportServiceTests {
  private let testScreen = Screen(
    name: "Test Screen",
    title: "Hello World",
    subtitle: "A subtitle"
  )

  private let testDevice = DeviceSize(
    name: "Test Device",
    category: .iPhone,
    displaySize: "6.1\"",
    portraitWidth: 300,
    portraitHeight: 600
  )

  @Test("Export screen as PNG returns valid data")
  func testExportPNG() {
    let data = ExportService.exportScreen(testScreen, device: testDevice, format: .png)
    #expect(data != nil)
    if let data {
      // PNG magic bytes
      #expect(data[0] == 0x89)
      #expect(data[1] == 0x50)  // P
      #expect(data[2] == 0x4E)  // N
      #expect(data[3] == 0x47)  // G
    }
  }

  @Test("Export screen as JPEG returns valid data")
  func testExportJPEG() {
    let data = ExportService.exportScreen(testScreen, device: testDevice, format: .jpeg)
    #expect(data != nil)
    if let data {
      // JPEG magic bytes
      #expect(data[0] == 0xFF)
      #expect(data[1] == 0xD8)
    }
  }

  @Test("Exported PNG has correct pixel dimensions")
  func testPNGDimensions() {
    let data = ExportService.exportScreen(testScreen, device: testDevice, format: .png)
    #expect(data != nil)
    #if canImport(AppKit)
      if let data, let nsImage = NSImage(data: data),
        let bitmap = NSBitmapImageRep(data: nsImage.tiffRepresentation!)
      {
        #expect(bitmap.pixelsWide == testDevice.portraitWidth)
        #expect(bitmap.pixelsHigh == testDevice.portraitHeight)
      }
    #elseif canImport(UIKit)
      if let data, let uiImage = UIImage(data: data) {
        #expect(Int(uiImage.size.width * uiImage.scale) == testDevice.portraitWidth)
        #expect(Int(uiImage.size.height * uiImage.scale) == testDevice.portraitHeight)
      }
    #endif
  }

  @Test("Export screen with screenshot image data")
  func testExportWithScreenshotImage() {
    var screen = testScreen
    // Minimal PNG data
    let pngData = Data([
      0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A,
      0x00, 0x00, 0x00, 0x0D, 0x49, 0x48, 0x44, 0x52,
      0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
      0x08, 0x02, 0x00, 0x00, 0x00, 0x90, 0x77, 0x53,
      0xDE, 0x00, 0x00, 0x00, 0x0C, 0x49, 0x44, 0x41,
      0x54, 0x08, 0xD7, 0x63, 0xF8, 0xCF, 0xC0, 0x00,
      0x00, 0x00, 0x02, 0x00, 0x01, 0xE2, 0x21, 0xBC,
      0x33, 0x00, 0x00, 0x00, 0x00, 0x49, 0x45, 0x4E,
      0x44, 0xAE, 0x42, 0x60, 0x82,
    ])
    screen.setScreenshotImageData(pngData, for: "en", category: testDevice.category)
    let data = ExportService.exportScreen(screen, device: testDevice, format: .png)
    #expect(data != nil)
  }

  @Test("ExportFormat has correct file extensions")
  func testExportFormatExtensions() {
    #expect(ExportFormat.png.fileExtension == "png")
    #expect(ExportFormat.jpeg.fileExtension == "jpeg")
  }

  @Test("ExportFormat has all cases")
  func testExportFormatCases() {
    #expect(ExportFormat.allCases.count == 2)
  }
}
