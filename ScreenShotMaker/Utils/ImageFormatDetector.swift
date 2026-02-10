import Foundation

/// Detected image format based on magic number (file signature)
enum ImageFormat: String, Sendable {
  case png
  case jpeg
  case gif
  case heic
  case dat  // Unknown format

  var fileExtension: String { rawValue }
}

/// Detects image format from binary data using magic number (file signature) analysis
enum ImageFormatDetector {
  /// Detect the image format from the first bytes of the data
  static func detect(from data: Data) -> ImageFormat {
    guard data.count >= 4 else { return .dat }

    let bytes = [UInt8](data.prefix(12))

    // PNG: 89 50 4E 47 0D 0A 1A 0A
    if bytes.count >= 4,
      bytes[0] == 0x89, bytes[1] == 0x50, bytes[2] == 0x4E, bytes[3] == 0x47
    {
      return .png
    }

    // JPEG: FF D8 FF
    if bytes.count >= 3,
      bytes[0] == 0xFF, bytes[1] == 0xD8, bytes[2] == 0xFF
    {
      return .jpeg
    }

    // GIF: 47 49 46 38 ("GIF8")
    if bytes.count >= 4,
      bytes[0] == 0x47, bytes[1] == 0x49, bytes[2] == 0x46, bytes[3] == 0x38
    {
      return .gif
    }

    // HEIC: Check for "ftyp" box at offset 4, then "heic" or "mif1" brand
    if bytes.count >= 12,
      bytes[4] == 0x66, bytes[5] == 0x74, bytes[6] == 0x79, bytes[7] == 0x70
    {
      // Check brand: "heic" (68 65 69 63) or "mif1" (6D 69 66 31)
      let isHeic =
        bytes[8] == 0x68 && bytes[9] == 0x65 && bytes[10] == 0x69 && bytes[11] == 0x63
      let isMif1 =
        bytes[8] == 0x6D && bytes[9] == 0x69 && bytes[10] == 0x66 && bytes[11] == 0x31
      if isHeic || isMif1 {
        return .heic
      }
    }

    return .dat
  }
}
