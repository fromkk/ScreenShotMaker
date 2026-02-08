import Foundation

enum DeviceCategory: String, Codable, CaseIterable, Identifiable {
    case iPhone
    case iPad
    case mac
    case appleWatch
    case appleTV
    case appleVisionPro

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .iPhone: "iPhone"
        case .iPad: "iPad"
        case .mac: "Mac"
        case .appleWatch: "Apple Watch"
        case .appleTV: "Apple TV"
        case .appleVisionPro: "Apple Vision Pro"
        }
    }

    var iconName: String {
        switch self {
        case .iPhone: "iphone"
        case .iPad: "ipad"
        case .mac: "macbook"
        case .appleWatch: "applewatch"
        case .appleTV: "appletv"
        case .appleVisionPro: "visionpro"
        }
    }
}

struct DeviceSize: Codable, Identifiable, Hashable {
    var id: String { name }
    let name: String
    let category: DeviceCategory
    let displaySize: String
    let portraitWidth: Int
    let portraitHeight: Int

    var landscapeWidth: Int { portraitHeight }
    var landscapeHeight: Int { portraitWidth }

    var sizeDescription: String {
        "\(portraitWidth) × \(portraitHeight)"
    }
}

extension DeviceSize {
    static let allSizes: [DeviceSize] = iPhoneSizes + iPadSizes + macSizes + watchSizes + tvSizes + visionProSizes

    static let iPhoneSizes: [DeviceSize] = [
        DeviceSize(name: "iPhone 6.9\"", category: .iPhone, displaySize: "6.9\"", portraitWidth: 1320, portraitHeight: 2868),
        DeviceSize(name: "iPhone 6.7\"", category: .iPhone, displaySize: "6.7\"", portraitWidth: 1290, portraitHeight: 2796),
        DeviceSize(name: "iPhone 6.5\"", category: .iPhone, displaySize: "6.5\"", portraitWidth: 1284, portraitHeight: 2778),
        DeviceSize(name: "iPhone 6.3\"", category: .iPhone, displaySize: "6.3\"", portraitWidth: 1206, portraitHeight: 2622),
        DeviceSize(name: "iPhone 6.1\"", category: .iPhone, displaySize: "6.1\"", portraitWidth: 1170, portraitHeight: 2532),
        DeviceSize(name: "iPhone 5.5\"", category: .iPhone, displaySize: "5.5\"", portraitWidth: 1242, portraitHeight: 2208),
        DeviceSize(name: "iPhone 4.7\"", category: .iPhone, displaySize: "4.7\"", portraitWidth: 750, portraitHeight: 1334),
        DeviceSize(name: "iPhone 4\"", category: .iPhone, displaySize: "4\"", portraitWidth: 640, portraitHeight: 1136),
        DeviceSize(name: "iPhone 3.5\"", category: .iPhone, displaySize: "3.5\"", portraitWidth: 640, portraitHeight: 960),
    ]

    static let iPadSizes: [DeviceSize] = [
        DeviceSize(name: "iPad 13\"", category: .iPad, displaySize: "13\"", portraitWidth: 2064, portraitHeight: 2752),
        DeviceSize(name: "iPad 12.9\"", category: .iPad, displaySize: "12.9\"", portraitWidth: 2048, portraitHeight: 2732),
        DeviceSize(name: "iPad 11\"", category: .iPad, displaySize: "11\"", portraitWidth: 1668, portraitHeight: 2420),
        DeviceSize(name: "iPad 10.5\"", category: .iPad, displaySize: "10.5\"", portraitWidth: 1668, portraitHeight: 2224),
        DeviceSize(name: "iPad 9.7\"", category: .iPad, displaySize: "9.7\"", portraitWidth: 1536, portraitHeight: 2048),
    ]

    static let macSizes: [DeviceSize] = [
        DeviceSize(name: "Mac 2880×1800", category: .mac, displaySize: "16:10", portraitWidth: 2880, portraitHeight: 1800),
        DeviceSize(name: "Mac 2560×1600", category: .mac, displaySize: "16:10", portraitWidth: 2560, portraitHeight: 1600),
        DeviceSize(name: "Mac 1440×900", category: .mac, displaySize: "16:10", portraitWidth: 1440, portraitHeight: 900),
        DeviceSize(name: "Mac 1280×800", category: .mac, displaySize: "16:10", portraitWidth: 1280, portraitHeight: 800),
    ]

    static let watchSizes: [DeviceSize] = [
        DeviceSize(name: "Apple Watch Ultra 3", category: .appleWatch, displaySize: "Ultra 3", portraitWidth: 422, portraitHeight: 514),
        DeviceSize(name: "Apple Watch Ultra 2/Ultra", category: .appleWatch, displaySize: "Ultra", portraitWidth: 410, portraitHeight: 502),
        DeviceSize(name: "Apple Watch Series 11/10", category: .appleWatch, displaySize: "Series 11/10", portraitWidth: 416, portraitHeight: 496),
        DeviceSize(name: "Apple Watch Series 9/8/7", category: .appleWatch, displaySize: "Series 9/8/7", portraitWidth: 396, portraitHeight: 484),
        DeviceSize(name: "Apple Watch Series 6/5/4/SE", category: .appleWatch, displaySize: "Series 6/5/4/SE", portraitWidth: 368, portraitHeight: 448),
        DeviceSize(name: "Apple Watch Series 3", category: .appleWatch, displaySize: "Series 3", portraitWidth: 312, portraitHeight: 390),
    ]

    static let tvSizes: [DeviceSize] = [
        DeviceSize(name: "Apple TV 4K", category: .appleTV, displaySize: "4K", portraitWidth: 3840, portraitHeight: 2160),
        DeviceSize(name: "Apple TV HD", category: .appleTV, displaySize: "HD", portraitWidth: 1920, portraitHeight: 1080),
    ]

    static let visionProSizes: [DeviceSize] = [
        DeviceSize(name: "Apple Vision Pro", category: .appleVisionPro, displaySize: "Standard", portraitWidth: 3840, portraitHeight: 2160),
    ]

    static func sizes(for category: DeviceCategory) -> [DeviceSize] {
        allSizes.filter { $0.category == category }
    }
}
