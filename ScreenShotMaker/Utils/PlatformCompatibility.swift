import SwiftUI

#if canImport(AppKit)
import AppKit
#elseif canImport(UIKit)
import UIKit
#endif

// MARK: - Platform Image

#if canImport(AppKit)
public typealias PlatformImage = NSImage
#elseif canImport(UIKit)
public typealias PlatformImage = UIImage
#endif

extension Image {
    /// Create a SwiftUI Image from a platform-native image (NSImage on macOS, UIImage on iOS)
    init(platformImage: PlatformImage) {
        #if canImport(AppKit)
        self.init(nsImage: platformImage)
        #elseif canImport(UIKit)
        self.init(uiImage: platformImage)
        #endif
    }
}

// MARK: - Platform Colors

extension Color {
    /// Window/screen background color
    static var platformBackground: Color {
        #if canImport(AppKit)
        Color(nsColor: .windowBackgroundColor)
        #elseif canImport(UIKit)
        Color(uiColor: .systemBackground)
        #endif
    }

    /// Control background color
    static var platformControlBackground: Color {
        #if canImport(AppKit)
        Color(nsColor: .controlBackgroundColor)
        #elseif canImport(UIKit)
        Color(uiColor: .systemBackground)
        #endif
    }

    /// Control color
    static var platformControl: Color {
        #if canImport(AppKit)
        Color(nsColor: .controlColor)
        #elseif canImport(UIKit)
        Color(uiColor: .secondarySystemBackground)
        #endif
    }

    /// Separator color
    static var platformSeparator: Color {
        #if canImport(AppKit)
        Color(nsColor: .separatorColor)
        #elseif canImport(UIKit)
        Color(uiColor: .separator)
        #endif
    }
}

// MARK: - Font Helper

enum FontHelper {
    /// Default font family name for the platform
    static var defaultFontFamily: String {
        #if canImport(AppKit)
        return "SF Pro Display"
        #elseif canImport(UIKit)
        return ".AppleSystemUIFont"
        #endif
    }

    /// Available font family names sorted alphabetically
    static var availableFontFamilies: [String] {
        #if canImport(AppKit)
        NSFontManager.shared.availableFontFamilies.sorted()
        #elseif canImport(UIKit)
        UIFont.familyNames.sorted()
        #endif
    }
}
