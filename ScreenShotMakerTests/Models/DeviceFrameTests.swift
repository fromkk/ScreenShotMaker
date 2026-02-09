import SwiftUI
import Testing

@testable import ScreenShotMaker

@Suite("DeviceFrame Tests")
struct DeviceFrameTests {

  @Test("iPhone has a frame spec")
  func testIPhoneFrameSpec() {
    let spec = DeviceCategory.iPhone.frameSpec
    #expect(spec != nil)
    #expect(spec!.hasNotch == true)
    #expect(spec!.hasHomeIndicator == true)
    #expect(spec!.bezelRatio > 0)
  }

  @Test("iPad has a frame spec")
  func testIPadFrameSpec() {
    let spec = DeviceCategory.iPad.frameSpec
    #expect(spec != nil)
    #expect(spec!.hasNotch == false)
    #expect(spec!.hasHomeIndicator == true)
  }

  @Test("Mac has a frame spec")
  func testMacFrameSpec() {
    let spec = DeviceCategory.mac.frameSpec
    #expect(spec != nil)
    #expect(spec!.hasNotch == false)
    #expect(spec!.hasHomeIndicator == false)
  }

  @Test("Apple Watch has no frame spec")
  func testAppleWatchNoFrame() {
    #expect(DeviceCategory.appleWatch.frameSpec == nil)
  }

  @Test("Apple TV has no frame spec")
  func testAppleTVNoFrame() {
    #expect(DeviceCategory.appleTV.frameSpec == nil)
  }

  @Test("Frame outer scale is larger than 1x1")
  func testOuterScale() {
    let spec = DeviceCategory.iPhone.frameSpec!
    #expect(spec.outerScale.width > 1.0)
    #expect(spec.outerScale.height > 1.0)
  }
}
