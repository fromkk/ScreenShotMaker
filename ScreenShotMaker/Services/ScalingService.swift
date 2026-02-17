import Foundation

enum ScalingService {
  /// Minimum readable font size (in points at export resolution)
  static let minimumFontSize: Double = 12.0

  /// Calculate scale factor from reference device to target device
  static func scaleFactor(from reference: DeviceSize, to target: DeviceSize) -> CGFloat {
    CGFloat(target.portraitHeight) / CGFloat(reference.portraitHeight)
  }

  /// Get the reference (largest) device for a given category
  /// For custom devices, returns nil (each custom device is its own reference, scale = 1.0)
  static func referenceDevice(for category: DeviceCategory) -> DeviceSize? {
    // Custom devices don't have a shared reference; each is independent
    if category == .custom {
      return nil
    }
    return DeviceSize.sizes(for: category)
      .max(by: { $0.portraitHeight < $1.portraitHeight })
  }

  /// Scale a font size, clamping to minimum readable size
  static func scaledFontSize(_ size: Double, factor: CGFloat) -> Double {
    max(size * Double(factor), minimumFontSize)
  }

  /// Scale a padding value
  static func scaledPadding(_ padding: Double, factor: CGFloat) -> Double {
    padding * Double(factor)
  }

  /// Scale a corner radius
  static func scaledCornerRadius(_ radius: Double, factor: CGFloat) -> Double {
    radius * Double(factor)
  }
}
