import Foundation
import Testing

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
}
