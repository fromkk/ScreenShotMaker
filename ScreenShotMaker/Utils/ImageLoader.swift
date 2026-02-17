import Foundation
import UniformTypeIdentifiers

#if canImport(AppKit)
  import AppKit
#elseif canImport(UIKit)
  import UIKit
#endif

enum ImageLoadError: LocalizedError, Equatable {
  case invalidFormat
  case fileTooLarge(size: Int)
  case fileNotFound

  var errorDescription: String? {
    switch self {
    case .invalidFormat:
      return "Unsupported file format. Please use PNG or JPEG."
    case .fileTooLarge(let size):
      let mb = size / (1024 * 1024)
      return "File is too large (\(mb)MB). Maximum size is 20MB."
    case .fileNotFound:
      return "File not found."
    }
  }
}

enum ImageLoader {
  static let maxFileSize = 20 * 1024 * 1024  // 20MB

  static func loadImage(from url: URL) throws -> Data {
    guard FileManager.default.fileExists(atPath: url.path) else {
      throw ImageLoadError.fileNotFound
    }

    let ext = url.pathExtension.lowercased()
    guard ["png", "jpg", "jpeg"].contains(ext) else {
      throw ImageLoadError.invalidFormat
    }

    let data = try Data(contentsOf: url)

    guard data.count <= maxFileSize else {
      throw ImageLoadError.fileTooLarge(size: data.count)
    }

    return data
  }

  /// Get the pixel size of an image from its data.
  /// Returns nil if the data cannot be parsed as a valid image.
  static func imagePixelSize(from data: Data) -> CGSize? {
    guard let image = PlatformImage(data: data) else { return nil }
    #if canImport(AppKit)
      // NSImage may have multiple representations; use the first bitmap rep's pixel dimensions
      if let bitmapRep = image.representations.first {
        return CGSize(width: bitmapRep.pixelsWide, height: bitmapRep.pixelsHigh)
      }
      return image.size
    #elseif canImport(UIKit)
      // UIImage.size is in points; multiply by scale for actual pixels
      return CGSize(width: image.size.width * image.scale, height: image.size.height * image.scale)
    #endif
  }

  /// Validate and return image data provided directly (e.g. from iPad Photos drag).
  static func loadImageData(_ data: Data) throws -> Data {
    guard data.count <= maxFileSize else {
      throw ImageLoadError.fileTooLarge(size: data.count)
    }

    // Verify the data is a valid image by attempting to create a PlatformImage
    guard PlatformImage(data: data) != nil else {
      throw ImageLoadError.invalidFormat
    }

    return data
  }
}
