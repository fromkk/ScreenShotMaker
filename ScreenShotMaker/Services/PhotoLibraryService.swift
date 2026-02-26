#if os(iOS)
  import Photos

  enum PhotoLibraryService {

    /// Request authorization to add photos to the library
    static func requestAuthorization() async throws {
      let status = await PHPhotoLibrary.requestAuthorization(for: .addOnly)
      guard status == .authorized || status == .limited else {
        throw PhotoLibraryError.authorizationDenied
      }
    }

    /// Save a single video file to the photo library
    static func saveVideo(at url: URL) async throws {
      try await PHPhotoLibrary.shared().performChanges {
        PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: url)
      }
    }

    /// Save a single image to the photo library
    static func saveImage(_ imageData: Data) async throws {
      try await PHPhotoLibrary.shared().performChanges {
        let request = PHAssetCreationRequest.forAsset()
        request.addResource(with: .photo, data: imageData, options: nil)
      }
    }

    /// Save multiple images to an album (batch export)
    static func saveImagesToAlbum(
      images: [(data: Data, filename: String)],
      albumName: String,
      progressHandler: @escaping @Sendable (Int, Int) -> Void
    ) async throws {
      let album = try await fetchOrCreateAlbum(named: albumName)

      for (index, image) in images.enumerated() {
        try await PHPhotoLibrary.shared().performChanges {
          let assetRequest = PHAssetCreationRequest.forAsset()
          assetRequest.addResource(with: .photo, data: image.data, options: nil)

          guard let placeholder = assetRequest.placeholderForCreatedAsset,
            let albumChangeRequest = PHAssetCollectionChangeRequest(for: album)
          else { return }
          albumChangeRequest.addAssets([placeholder] as NSArray)
        }
        progressHandler(index + 1, images.count)
      }
    }

    /// Fetch an existing album or create a new one
    private static func fetchOrCreateAlbum(named name: String) async throws -> PHAssetCollection {
      let fetchOptions = PHFetchOptions()
      fetchOptions.predicate = NSPredicate(format: "title = %@", name)
      let collections = PHAssetCollection.fetchAssetCollections(
        with: .album, subtype: .any, options: fetchOptions
      )
      if let existing = collections.firstObject {
        return existing
      }

      var placeholder: PHObjectPlaceholder?
      try await PHPhotoLibrary.shared().performChanges {
        let request = PHAssetCollectionChangeRequest.creationRequestForAssetCollection(
          withTitle: name)
        placeholder = request.placeholderForCreatedAssetCollection
      }

      guard let placeholder,
        let album = PHAssetCollection.fetchAssetCollections(
          withLocalIdentifiers: [placeholder.localIdentifier], options: nil
        ).firstObject
      else {
        throw PhotoLibraryError.albumCreationFailed
      }
      return album
    }

    enum PhotoLibraryError: LocalizedError {
      case albumCreationFailed
      case authorizationDenied

      var errorDescription: String? {
        switch self {
        case .albumCreationFailed: "Failed to create photo album"
        case .authorizationDenied: "Photo library access was denied"
        }
      }
    }
  }
#endif
