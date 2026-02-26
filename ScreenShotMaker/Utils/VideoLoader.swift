import AVFoundation
import Foundation
import UniformTypeIdentifiers

#if canImport(AppKit)
  import AppKit
#elseif canImport(UIKit)
  import UIKit
#endif

enum VideoLoadError: LocalizedError {
  case invalidFormat
  case fileTooLarge(size: Int)
  case fileNotFound
  case bookmarkFailed

  var errorDescription: String? {
    switch self {
    case .invalidFormat:
      return "Unsupported video format. Please use MP4, MOV, or M4V."
    case .fileTooLarge(let size):
      let mb = size / (1024 * 1024)
      return "File is too large (\(mb)MB). Maximum size is 500MB."
    case .fileNotFound:
      return "File not found."
    case .bookmarkFailed:
      return "Failed to create a file bookmark for the video."
    }
  }
}

enum VideoLoader {
  static let maxFileSize = 500 * 1024 * 1024  // 500 MB
  static let supportedExtensions = ["mp4", "mov", "m4v"]

  // MARK: - Load & Validate

  /// Validates the video at `url` and returns a security-scoped bookmark Data plus the asset duration in seconds.
  static func loadVideo(from url: URL) throws -> (bookmarkData: Data, duration: Double) {
    guard FileManager.default.fileExists(atPath: url.path) else {
      throw VideoLoadError.fileNotFound
    }

    let ext = url.pathExtension.lowercased()
    guard supportedExtensions.contains(ext) else {
      throw VideoLoadError.invalidFormat
    }

    // Check file size via file-system attributes (avoids loading the entire file).
    if let attrs = try? FileManager.default.attributesOfItem(atPath: url.path),
      let fileSize = attrs[.size] as? Int, fileSize > maxFileSize
    {
      throw VideoLoadError.fileTooLarge(size: fileSize)
    }

    // Obtain duration via AVFoundation.
    let asset = AVURLAsset(
      url: url,
      options: [AVURLAssetPreferPreciseDurationAndTimingKey: false]
    )
    let duration = CMTimeGetSeconds(asset.duration)

    // Create a security-scoped bookmark so the app can re-open the file later.
    do {
      #if canImport(AppKit)
        let bookmarkData = try url.bookmarkData(
          options: .withSecurityScope,
          includingResourceValuesForKeys: nil,
          relativeTo: nil
        )
      #else
        let bookmarkData = try url.bookmarkData(
          options: .minimalBookmark,
          includingResourceValuesForKeys: nil,
          relativeTo: nil
        )
      #endif
      return (bookmarkData: bookmarkData, duration: max(duration, 0))
    } catch {
      throw VideoLoadError.bookmarkFailed
    }
  }

  // MARK: - Bookmark Resolution

  /// Resolves a security-scoped bookmark Data back into a `URL`.
  /// Returns `nil` if the bookmark is stale or cannot be resolved.
  static func resolveBookmark(_ bookmarkData: Data) -> URL? {
    var isStale = false
    do {
      #if canImport(AppKit)
        let url = try URL(
          resolvingBookmarkData: bookmarkData,
          options: .withSecurityScope,
          relativeTo: nil,
          bookmarkDataIsStale: &isStale
        )
      #else
        let url = try URL(
          resolvingBookmarkData: bookmarkData,
          options: [],
          relativeTo: nil,
          bookmarkDataIsStale: &isStale
        )
      #endif
      guard !isStale else { return nil }
      return url
    } catch {
      return nil
    }
  }

  // MARK: - Duration

  /// Returns the duration of a video at the given URL in seconds.
  static func duration(of url: URL) -> Double {
    let asset = AVURLAsset(
      url: url,
      options: [AVURLAssetPreferPreciseDurationAndTimingKey: false]
    )
    let d = CMTimeGetSeconds(asset.duration)
    return d.isNaN || d < 0 ? 0 : d
  }

  // MARK: - Thumbnail Generation

  /// Generates a thumbnail image Data for the video at `url`, snapped to `time` seconds.
  /// Returns `nil` if generation fails.
  static func generateThumbnail(url: URL, at time: Double) async -> Data? {
    let asset = AVURLAsset(url: url)
    let generator = AVAssetImageGenerator(asset: asset)
    generator.appliesPreferredTrackTransform = true
    generator.maximumSize = CGSize(width: 600, height: 600)

    let cmTime = CMTime(seconds: time, preferredTimescale: 600)
    return await withCheckedContinuation { continuation in
      generator.generateCGImageAsynchronously(for: cmTime) { cgImage, _, _ in
        guard let cgImage else {
          continuation.resume(returning: nil)
          return
        }
        #if canImport(AppKit)
          let image = NSImage(
            cgImage: cgImage,
            size: NSSize(width: cgImage.width, height: cgImage.height)
          )
          continuation.resume(returning: image.tiffRepresentation)
        #elseif canImport(UIKit)
          let image = UIImage(cgImage: cgImage)
          continuation.resume(returning: image.jpegData(compressionQuality: 0.85))
        #endif
      }
    }
  }

  // MARK: - Temporary-directory copy (for .shotcraft load)

  /// Writes `data` to a temporary file with `filename` and returns a bookmark Data for it.
  static func bookmarkForTemporaryVideo(data: Data, filename: String) throws -> Data {
    let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(filename)
    try data.write(to: tempURL, options: .atomic)
    do {
      #if canImport(AppKit)
        let bookmarkData = try tempURL.bookmarkData(
          options: .withSecurityScope,
          includingResourceValuesForKeys: nil,
          relativeTo: nil
        )
      #else
        let bookmarkData = try tempURL.bookmarkData(
          options: .minimalBookmark,
          includingResourceValuesForKeys: nil,
          relativeTo: nil
        )
      #endif
      return bookmarkData
    } catch {
      throw VideoLoadError.bookmarkFailed
    }
  }
}
