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

  /// Calculate frame size that fits the image's aspect ratio within a bounding box.
  /// When `fitToImage` is true and valid image data is provided, the returned size
  /// adjusts the frame's aspect ratio to match the image while fitting inside the
  /// bounding box defined by `boxWidth × boxHeight`.
  /// When `fitToImage` is false or no valid image data exists, returns the box size as-is.
  static func frameFittingSize(
    imageData: Data?,
    boxWidth: CGFloat,
    boxHeight: CGFloat,
    fitToImage: Bool
  ) -> (width: CGFloat, height: CGFloat) {
    guard fitToImage,
          let imageData,
          let imageSize = ImageLoader.imagePixelSize(from: imageData),
          imageSize.width > 0, imageSize.height > 0
    else {
      return (boxWidth, boxHeight)
    }
    return frameFittingSize(nativeSize: imageSize, boxWidth: boxWidth, boxHeight: boxHeight, fitToImage: true)
  }

  /// Same as `frameFittingSize(imageData:...)` but accepts a pre-computed native size directly.
  /// Useful when the content is a video (no image data available).
  static func frameFittingSize(
    nativeSize: CGSize?,
    boxWidth: CGFloat,
    boxHeight: CGFloat,
    fitToImage: Bool
  ) -> (width: CGFloat, height: CGFloat) {
    guard fitToImage,
          let nativeSize,
          nativeSize.width > 0, nativeSize.height > 0
    else {
      return (boxWidth, boxHeight)
    }

    let aspect    = nativeSize.width / nativeSize.height
    let boxAspect = boxWidth / boxHeight

    if aspect > boxAspect {
      return (boxWidth, boxWidth / aspect)
    } else {
      return (boxHeight * aspect, boxHeight)
    }
  }
}
