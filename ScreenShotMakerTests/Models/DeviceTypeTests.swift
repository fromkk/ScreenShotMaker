import Testing

@testable import ScreenShotMaker

@Suite("DeviceType Tests")
struct DeviceTypeTests {

  @Test("allSizes contains all device sizes")
  func testAllSizesCount() {
    let allSizes = DeviceSize.allSizes
    #expect(allSizes.count >= 26)
  }

  @Test("iPhone sizes count is 9")
  func testIPhoneSizesCount() {
    #expect(DeviceSize.iPhoneSizes.count == 9)
  }

  @Test("iPad sizes count is 5")
  func testIPadSizesCount() {
    #expect(DeviceSize.iPadSizes.count == 5)
  }

  @Test("Category filter returns only matching devices")
  func testCategoryFilter() {
    let iPhoneSizes = DeviceSize.sizes(for: .iPhone)
    for size in iPhoneSizes {
      #expect(size.category == .iPhone)
    }
    #expect(iPhoneSizes.count == DeviceSize.iPhoneSizes.count)
  }

  @Test("Landscape dimensions are swapped from portrait")
  func testLandscapeDimensions() {
    let device = DeviceSize.iPhoneSizes[0]
    #expect(device.landscapeWidth == device.portraitHeight)
    #expect(device.landscapeHeight == device.portraitWidth)
  }

  @Test("All device IDs are unique")
  func testDeviceSizeUniqueness() {
    let ids = DeviceSize.allSizes.map(\.id)
    let uniqueIDs = Set(ids)
    #expect(ids.count == uniqueIDs.count)
  }

  @Test("DeviceCategory has correct display names")
  func testDeviceCategoryDisplayName() {
    #expect(DeviceCategory.iPhone.displayName == "iPhone")
    #expect(DeviceCategory.iPad.displayName == "iPad")
    #expect(DeviceCategory.mac.displayName == "Mac")
    #expect(DeviceCategory.appleWatch.displayName == "Apple Watch")
    #expect(DeviceCategory.appleTV.displayName == "Apple TV")
    #expect(DeviceCategory.appleVisionPro.displayName == "Apple Vision Pro")
  }

  @Test("DeviceCategory has correct icon names")
  func testDeviceCategoryIconName() {
    #expect(DeviceCategory.iPhone.iconName == "iphone")
    #expect(DeviceCategory.iPad.iconName == "ipad")
    #expect(DeviceCategory.mac.iconName == "macbook")
  }

  @Test("sizeDescription formats correctly")
  func testSizeDescription() {
    let device = DeviceSize(
      name: "Test",
      category: .iPhone,
      displaySize: "6.9\"",
      portraitWidth: 1260,
      portraitHeight: 2736
    )
    #expect(device.sizeDescription == "1260 × 2736")
  }

  // MARK: - supportsRotation

  @Test("supportsRotation returns true for iPhone and iPad")
  func testSupportsRotation_rotatable() {
    #expect(DeviceCategory.iPhone.supportsRotation == true)
    #expect(DeviceCategory.iPad.supportsRotation == true)
  }

  @Test("supportsRotation returns false for Mac, TV, Watch, Vision Pro")
  func testSupportsRotation_fixed() {
    #expect(DeviceCategory.mac.supportsRotation == false)
    #expect(DeviceCategory.appleTV.supportsRotation == false)
    #expect(DeviceCategory.appleWatch.supportsRotation == false)
    #expect(DeviceCategory.appleVisionPro.supportsRotation == false)
  }

  // MARK: - effectiveWidth / effectiveHeight

  @Test("effectiveWidth/Height swaps for iPhone in landscape")
  func testEffectiveDimensions_iPhoneLandscape() {
    let device = DeviceSize.iPhoneSizes[0]  // iPhone 6.9"
    // Portrait: returns portraitWidth/Height
    #expect(device.effectiveWidth(isLandscape: false) == device.portraitWidth)
    #expect(device.effectiveHeight(isLandscape: false) == device.portraitHeight)
    // Landscape: swaps width and height
    #expect(device.effectiveWidth(isLandscape: true) == device.landscapeWidth)
    #expect(device.effectiveHeight(isLandscape: true) == device.landscapeHeight)
    #expect(device.effectiveWidth(isLandscape: true) == device.portraitHeight)
    #expect(device.effectiveHeight(isLandscape: true) == device.portraitWidth)
  }

  @Test("effectiveWidth/Height swaps for iPad in landscape")
  func testEffectiveDimensions_iPadLandscape() {
    let device = DeviceSize.iPadSizes[0]  // iPad 13"
    #expect(device.effectiveWidth(isLandscape: false) == device.portraitWidth)
    #expect(device.effectiveHeight(isLandscape: false) == device.portraitHeight)
    #expect(device.effectiveWidth(isLandscape: true) == device.landscapeWidth)
    #expect(device.effectiveHeight(isLandscape: true) == device.landscapeHeight)
  }

  @Test("effectiveWidth/Height does NOT swap for Mac in landscape")
  func testEffectiveDimensions_macFixed() {
    let device = DeviceSize.macSizes[0]  // Mac 2880×1800
    #expect(device.effectiveWidth(isLandscape: false) == 2880)
    #expect(device.effectiveHeight(isLandscape: false) == 1800)
    // Even with isLandscape=true, Mac dimensions stay the same
    #expect(device.effectiveWidth(isLandscape: true) == 2880)
    #expect(device.effectiveHeight(isLandscape: true) == 1800)
  }

  @Test("effectiveWidth/Height does NOT swap for Apple TV in landscape")
  func testEffectiveDimensions_tvFixed() {
    let device = DeviceSize.tvSizes[0]  // Apple TV 4K 3840×2160
    #expect(device.effectiveWidth(isLandscape: false) == 3840)
    #expect(device.effectiveHeight(isLandscape: false) == 2160)
    #expect(device.effectiveWidth(isLandscape: true) == 3840)
    #expect(device.effectiveHeight(isLandscape: true) == 2160)
  }

  @Test("effectiveWidth/Height does NOT swap for Apple Vision Pro in landscape")
  func testEffectiveDimensions_visionProFixed() {
    let device = DeviceSize.visionProSizes[0]  // 3840×2160
    #expect(device.effectiveWidth(isLandscape: false) == 3840)
    #expect(device.effectiveHeight(isLandscape: false) == 2160)
    #expect(device.effectiveWidth(isLandscape: true) == 3840)
    #expect(device.effectiveHeight(isLandscape: true) == 2160)
  }

  @Test("effectiveWidth/Height does NOT swap for Apple Watch in landscape")
  func testEffectiveDimensions_watchFixed() {
    let device = DeviceSize.watchSizes[0]  // Apple Watch Ultra 3
    #expect(device.effectiveWidth(isLandscape: false) == device.portraitWidth)
    #expect(device.effectiveHeight(isLandscape: false) == device.portraitHeight)
    #expect(device.effectiveWidth(isLandscape: true) == device.portraitWidth)
    #expect(device.effectiveHeight(isLandscape: true) == device.portraitHeight)
  }
}
