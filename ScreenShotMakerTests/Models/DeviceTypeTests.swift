import Testing
@testable import ScreenShotMaker

@Suite("DeviceType Tests")
struct DeviceTypeTests {

    @Test("allSizes contains all device sizes")
    func testAllSizesCount() {
        let allSizes = DeviceSize.allSizes
        #expect(allSizes.count >= 26)
    }

    @Test("iPhone sizes count is 8")
    func testIPhoneSizesCount() {
        #expect(DeviceSize.iPhoneSizes.count == 8)
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
}
