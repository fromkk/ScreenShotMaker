import Foundation
import Testing

#if canImport(AppKit)
  import AppKit
#elseif canImport(UIKit)
  import UIKit
#endif

@testable import ScreenShotMaker

@Suite("ScalingService Tests")
struct ScalingServiceTests {

  @Test("Scale factor is 1.0 for same device")
  func testScaleFactorSameDevice() {
    let device = DeviceSize.iPhoneSizes[0]
    let factor = ScalingService.scaleFactor(from: device, to: device)
    #expect(factor == 1.0)
  }

  @Test("Scale factor is proportional to height ratio")
  func testScaleFactorProportional() {
    let large = DeviceSize(
      name: "Large", category: .iPhone, displaySize: "6.9",
      portraitWidth: 1320, portraitHeight: 2868
    )
    let small = DeviceSize(
      name: "Small", category: .iPhone, displaySize: "6.1",
      portraitWidth: 1170, portraitHeight: 2532
    )
    let factor = ScalingService.scaleFactor(from: large, to: small)
    let expected = CGFloat(2532) / CGFloat(2868)
    #expect(abs(factor - expected) < 0.001)
  }

  @Test("Reference device is the largest in category")
  func testReferenceDeviceIsLargest() {
    let ref = ScalingService.referenceDevice(for: .iPhone)
    #expect(ref != nil)
    let maxHeight = DeviceSize.iPhoneSizes.map(\.portraitHeight).max()
    #expect(ref!.portraitHeight == maxHeight)
  }

  @Test("Scaled font size respects minimum")
  func testScaledFontSizeMinimum() {
    let result = ScalingService.scaledFontSize(10, factor: 0.5)
    #expect(result == ScalingService.minimumFontSize)
  }

  @Test("Scaled font size scales up correctly")
  func testScaledFontSizeScalesUp() {
    let result = ScalingService.scaledFontSize(40, factor: 1.5)
    #expect(result == 60.0)
  }

  @Test("Scaled padding is proportional")
  func testScaledPadding() {
    let result = ScalingService.scaledPadding(24, factor: 0.8)
    #expect(abs(result - 19.2) < 0.001)
  }

  @Test("Scaled corner radius is proportional")
  func testScaledCornerRadius() {
    let result = ScalingService.scaledCornerRadius(16, factor: 1.2)
    #expect(abs(result - 19.2) < 0.001)
  }

  // MARK: - Frame Fitting Size Tests

  @Test("frameFittingSize returns box size when fitToImage is false")
  func testFrameFittingSizeDisabled() {
    let result = ScalingService.frameFittingSize(
      imageData: nil,
      boxWidth: 400,
      boxHeight: 600,
      fitToImage: false
    )
    #expect(result.width == 400)
    #expect(result.height == 600)
  }

  @Test("frameFittingSize returns box size when no image data")
  func testFrameFittingSizeNoImage() {
    let result = ScalingService.frameFittingSize(
      imageData: nil,
      boxWidth: 400,
      boxHeight: 600,
      fitToImage: true
    )
    #expect(result.width == 400)
    #expect(result.height == 600)
  }

  @Test("frameFittingSize returns box size for invalid image data")
  func testFrameFittingSizeInvalidData() {
    let invalidData = Data([0x00, 0x01, 0x02])
    let result = ScalingService.frameFittingSize(
      imageData: invalidData,
      boxWidth: 400,
      boxHeight: 600,
      fitToImage: true
    )
    #expect(result.width == 400)
    #expect(result.height == 600)
  }

  @Test("frameFittingSize fits wider image within box")
  func testFrameFittingSizeWiderImage() {
    // Create a 200x100 (2:1 aspect) PNG image
    let imageData = createTestPNG(width: 200, height: 100)
    let result = ScalingService.frameFittingSize(
      imageData: imageData,
      boxWidth: 400,
      boxHeight: 600,
      fitToImage: true
    )
    // 2:1 aspect, constrained by width: 400 x 200
    #expect(abs(result.width - 400) < 1)
    #expect(abs(result.height - 200) < 1)
  }

  @Test("frameFittingSize fits taller image within box")
  func testFrameFittingSizeTallerImage() {
    // Create a 100x300 (1:3 aspect) PNG image
    let imageData = createTestPNG(width: 100, height: 300)
    let result = ScalingService.frameFittingSize(
      imageData: imageData,
      boxWidth: 400,
      boxHeight: 600,
      fitToImage: true
    )
    // 1:3 aspect, constrained by height: 200 x 600
    #expect(abs(result.width - 200) < 1)
    #expect(abs(result.height - 600) < 1)
  }

  @Test("frameFittingSize fits square image within box")
  func testFrameFittingSizeSquareImage() {
    let imageData = createTestPNG(width: 100, height: 100)
    let result = ScalingService.frameFittingSize(
      imageData: imageData,
      boxWidth: 400,
      boxHeight: 600,
      fitToImage: true
    )
    // 1:1 aspect in a 400x600 box → constrained by width: 400 x 400
    #expect(abs(result.width - 400) < 1)
    #expect(abs(result.height - 400) < 1)
  }

  /// Helper: create a minimal PNG image of the given pixel size
  private func createTestPNG(width: Int, height: Int) -> Data {
    #if canImport(AppKit)
      let image = NSImage(size: NSSize(width: width, height: height))
      image.lockFocus()
      NSColor.white.set()
      NSBezierPath.fill(NSRect(x: 0, y: 0, width: width, height: height))
      image.unlockFocus()
      guard let tiff = image.tiffRepresentation,
            let rep = NSBitmapImageRep(data: tiff),
            let png = rep.representation(using: .png, properties: [:])
      else { return Data() }
      return png
    #elseif canImport(UIKit)
      let renderer = UIGraphicsImageRenderer(size: CGSize(width: width, height: height))
      return renderer.pngData { ctx in
        UIColor.white.setFill()
        ctx.fill(CGRect(x: 0, y: 0, width: width, height: height))
      }
    #endif
  }
}
