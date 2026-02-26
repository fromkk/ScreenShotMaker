import Foundation

enum ProjectFileServiceError: LocalizedError {
  case missingProjectJSON
  case invalidPackageStructure
  case missingImageFile(String)

  var errorDescription: String? {
    switch self {
    case .missingProjectJSON:
      return "project.json not found in package."
    case .invalidPackageStructure:
      return "Invalid .shotcraft package structure."
    case .missingImageFile(let name):
      return "Image file '\(name)' not found in package."
    }
  }
}

enum ProjectFileService {
  // MARK: - Legacy single-file format (kept for reference, no longer used for saving)

  static func save(_ project: ScreenShotProject, to url: URL) throws {
    let data = try encode(project)
    try data.write(to: url, options: .atomic)
  }

  static func encode(_ project: ScreenShotProject) throws -> Data {
    let encoder = JSONEncoder()
    encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
    return try encoder.encode(project)
  }

  static func load(from url: URL) throws -> ScreenShotProject {
    let data = try Data(contentsOf: url)
    return try JSONDecoder().decode(ScreenShotProject.self, from: data)
  }

  // MARK: - Package format (.shotcraft directory bundle)

  /// Save a project as a directory-based FileWrapper package.
  ///
  /// Package structure:
  /// ```
  /// MyProject.shotcraft/
  /// ├── project.json           (project data without image binary)
  /// └── images/
  ///     ├── {screenID}-{lang}-{device}.png
  ///     └── {screenID}-background.jpg
  /// ```
  static func savePackage(_ project: ScreenShotProject) throws -> FileWrapper {
    // 1. Encode the project to JSON, then convert to mutable Dictionary
    let encoder = JSONEncoder()
    encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
    let jsonData = try encoder.encode(project)

    guard
      var projectDict = try JSONSerialization.jsonObject(with: jsonData) as? [String: Any],
      var screensArray = projectDict["screens"] as? [[String: Any]]
    else {
      throw ProjectFileServiceError.invalidPackageStructure
    }

    // 2. Extract images into individual FileWrappers
    var imageFileWrappers: [String: FileWrapper] = [:]
    var videoFileWrappers: [String: FileWrapper] = [:]

    for i in screensArray.indices {
      guard let screenID = screensArray[i]["id"] as? String else { continue }

      // Extract screenshotImages
      if let images = screensArray[i]["screenshotImages"] as? [String: String] {
        // Base64-encoded Data values from JSON
        var fileReferences: [String: String] = [:]
        for (key, base64String) in images {
          guard let imageData = Data(base64Encoded: base64String) else { continue }
          let format = ImageFormatDetector.detect(from: imageData)
          let filename = "\(screenID)-\(key).\(format.fileExtension)"
          imageFileWrappers[filename] = FileWrapper(regularFileWithContents: imageData)
          fileReferences[key] = filename
        }
        screensArray[i]["screenshotImages"] = fileReferences
      }

      // Extract screenshotVideoBookmarks
      if let videoBookmarks = screensArray[i]["screenshotVideoBookmarks"] as? [String: String] {
        var videoFileReferences: [String: String] = [:]
        for (key, base64String) in videoBookmarks {
          guard let bookmarkData = Data(base64Encoded: base64String),
            let videoURL = VideoLoader.resolveBookmark(bookmarkData)
          else { continue }
          let accessing = videoURL.startAccessingSecurityScopedResource()
          defer { if accessing { videoURL.stopAccessingSecurityScopedResource() } }
          guard let videoData = try? Data(contentsOf: videoURL) else { continue }
          let ext = videoURL.pathExtension.lowercased()
          let safeExt = VideoLoader.supportedExtensions.contains(ext) ? ext : "mp4"
          let filename = "\(screenID)-\(key).\(safeExt)"
          videoFileWrappers[filename] = FileWrapper(regularFileWithContents: videoData)
          videoFileReferences[key] = filename
        }
        screensArray[i]["screenshotVideoBookmarks"] = videoFileReferences
      }

      // Extract background image
      if var background = screensArray[i]["background"] as? [String: Any],
        let imageContainer = background["image"] as? [String: Any],
        let dataDict = imageContainer["data"] as? String,
        let imageData = Data(base64Encoded: dataDict)
      {
        let format = ImageFormatDetector.detect(from: imageData)
        let filename = "\(screenID)-background.\(format.fileExtension)"
        imageFileWrappers[filename] = FileWrapper(regularFileWithContents: imageData)
        background["image"] = ["data": filename]
        screensArray[i]["background"] = background
      }
    }

    // 3. Write modified project JSON (with file references instead of image data)
    projectDict["screens"] = screensArray
    let modifiedJSON = try JSONSerialization.data(
      withJSONObject: projectDict, options: [.prettyPrinted, .sortedKeys])

    // 4. Build directory FileWrapper
    var directoryContents: [String: FileWrapper] = [:]

    let projectJSONWrapper = FileWrapper(regularFileWithContents: modifiedJSON)
    projectJSONWrapper.preferredFilename = "project.json"
    directoryContents["project.json"] = projectJSONWrapper

    if !imageFileWrappers.isEmpty {
      let imagesDir = FileWrapper(directoryWithFileWrappers: imageFileWrappers)
      imagesDir.preferredFilename = "images"
      directoryContents["images"] = imagesDir
    }

    // Always include videos/ directory for forward-compatibility.
    let videosDirWrappers: [String: FileWrapper] =
      videoFileWrappers.isEmpty ? [:] : videoFileWrappers
    let videosDir = FileWrapper(directoryWithFileWrappers: videosDirWrappers)
    videosDir.preferredFilename = "videos"
    directoryContents["videos"] = videosDir

    let packageWrapper = FileWrapper(directoryWithFileWrappers: directoryContents)
    return packageWrapper
  }

  /// Load a project from a directory-based FileWrapper package.
  static func loadPackage(from fileWrapper: FileWrapper) throws -> ScreenShotProject {
    guard let fileWrappers = fileWrapper.fileWrappers else {
      throw ProjectFileServiceError.invalidPackageStructure
    }

    // 1. Read project.json
    guard let projectJSONWrapper = fileWrappers["project.json"],
      let projectJSONData = projectJSONWrapper.regularFileContents
    else {
      throw ProjectFileServiceError.missingProjectJSON
    }

    // 2. Parse JSON into mutable Dictionary
    guard
      var projectDict = try JSONSerialization.jsonObject(with: projectJSONData) as? [String: Any],
      var screensArray = projectDict["screens"] as? [[String: Any]]
    else {
      throw ProjectFileServiceError.invalidPackageStructure
    }

    // 3. Get images directory
    let imagesDir = fileWrappers["images"]?.fileWrappers ?? [:]

    // 3b. Get videos directory (optional; absent in files created before #058)
    let videosDir = fileWrappers["videos"]?.fileWrappers ?? [:]

    // 4. Restore image data from file references
    for i in screensArray.indices {
      // Restore screenshotImages
      if let fileReferences = screensArray[i]["screenshotImages"] as? [String: String] {
        var restoredImages: [String: String] = [:]
        for (key, filename) in fileReferences {
          if let imageWrapper = imagesDir[filename],
            let imageData = imageWrapper.regularFileContents
          {
            restoredImages[key] = imageData.base64EncodedString()
          }
        }
        screensArray[i]["screenshotImages"] = restoredImages
      }

      // Restore screenshotVideoBookmarks from videos/ file references → bookmark Data
      if let videoFileRefs = screensArray[i]["screenshotVideoBookmarks"] as? [String: String],
        !videoFileRefs.isEmpty
      {
        var restoredBookmarks: [String: String] = [:]
        for (key, filename) in videoFileRefs {
          guard let videoWrapper = videosDir[filename],
            let videoData = videoWrapper.regularFileContents
          else { continue }
          // Write to temp directory and generate a fresh bookmark.
          do {
            let bookmarkData = try VideoLoader.bookmarkForTemporaryVideo(
              data: videoData, filename: filename)
            restoredBookmarks[key] = bookmarkData.base64EncodedString()
          } catch {
            // Skip unresolvable videos rather than failing the whole load.
          }
        }
        screensArray[i]["screenshotVideoBookmarks"] = restoredBookmarks
      }

      // Restore background image
      if var background = screensArray[i]["background"] as? [String: Any],
        let imageContainer = background["image"] as? [String: Any],
        let filename = imageContainer["data"] as? String,
        !filename.isEmpty
      {
        // Check if it's a file reference (has file extension) rather than inline base64
        if filename.contains(".") {
          if let imageWrapper = imagesDir[filename],
            let imageData = imageWrapper.regularFileContents
          {
            background["image"] = ["data": imageData.base64EncodedString()]
            screensArray[i]["background"] = background
          }
        }
      }
    }

    // 5. Convert restored Dictionary back to JSON data and decode
    projectDict["screens"] = screensArray
    let restoredJSON = try JSONSerialization.data(withJSONObject: projectDict)
    return try JSONDecoder().decode(ScreenShotProject.self, from: restoredJSON)
  }

  /// Load a project from a package URL on disk.
  static func loadPackageFromURL(_ url: URL) throws -> ScreenShotProject {
    let fileWrapper = try FileWrapper(url: url, options: .immediate)
    return try loadPackage(from: fileWrapper)
  }

  /// Save a project as a package to a URL on disk.
  static func savePackageToURL(_ project: ScreenShotProject, to url: URL) throws {
    let fileWrapper = try savePackage(project)
    try fileWrapper.write(to: url, options: .atomic, originalContentsURL: nil)
  }
}
