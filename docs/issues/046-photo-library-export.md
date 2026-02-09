# Issue #046: PHPhotoLibrary による写真アプリへのエクスポート（iOS 専用）

## Status
Open

## Phase / Priority
Phase 8 (iPad対応) | P1 (High)

## 概要

iPad でのエクスポート先として、写真アプリ（PHPhotoLibrary）への保存機能を追加する。単画面エクスポートに対応する。

## 現状

- エクスポートは全てファイルシステムへの書き出しのみ（`Data.write(to:)`）
- `ExportService.exportScreen()` は `Data?` を返す — PHPhotoLibrary との連携に最適
- `NSPhotoLibraryAddUsageDescription` 未設定（#041 で追加予定）
- `import Photos` なし

## 対象ファイル

- 新規: `ScreenShotMaker/Services/PhotoLibraryService.swift`
- 変更: `ScreenShotMaker/Views/ContentView.swift`（単画面エクスポート UI に「写真に保存」を追加）
- 変更: `ScreenShotMaker/Views/ExportProgressView.swift`

## 実装詳細

### 1. PhotoLibraryService（新規）

```swift
#if os(iOS)
import Photos

enum PhotoLibraryService {

    /// 写真ライブラリへのアクセス権限を要求
    static func requestAuthorization() async -> PHAuthorizationStatus {
        await PHPhotoLibrary.requestAuthorization(for: .addOnly)
    }

    /// 単一画像を写真ライブラリに保存
    static func saveImage(_ imageData: Data) async throws {
        try await PHPhotoLibrary.shared().performChanges {
            let request = PHAssetCreationRequest.forAsset()
            request.addResource(with: .photo, data: imageData, options: nil)
        }
    }

    /// アルバムを取得、なければ作成
    private static func fetchOrCreateAlbum(named name: String) async throws -> PHAssetCollection {
        // 既存アルバムを検索
        let fetchOptions = PHFetchOptions()
        fetchOptions.predicate = NSPredicate(format: "title = %@", name)
        let collections = PHAssetCollection.fetchAssetCollections(
            with: .album, subtype: .any, options: fetchOptions
        )
        if let existing = collections.firstObject {
            return existing
        }

        // 新規作成
        var placeholder: PHObjectPlaceholder?
        try await PHPhotoLibrary.shared().performChanges {
            let request = PHAssetCollectionChangeRequest.creationRequestForAssetCollection(withTitle: name)
            placeholder = request.placeholderForCreatedAssetCollection
        }

        guard let placeholder,
              let album = PHAssetCollection.fetchAssetCollections(
                  withLocalIdentifiers: [placeholder.localIdentifier], options: nil
              ).firstObject else {
            throw PhotoLibraryError.albumCreationFailed
        }
        return album
    }

    enum PhotoLibraryError: LocalizedError {
        case albumCreationFailed
        case authorizationDenied

        var errorDescription: String? {
            switch self {
            case .albumCreationFailed: "Failed to create album"
            case .authorizationDenied: "Photo library access denied"
            }
        }
    }
}
#endif
```

### 2. ContentView.swift — 単画面エクスポート UI

iPad 時にエクスポートボタンを2択にする:

```swift
#if os(iOS)
Menu("Export") {
    Button("Save to Photos") {
        exportToPhotos()
    }
    Button("Save to Files") {
        showExportFile = true
    }
}
#else
Button("Export") {
    showExportFile = true
}
#endif
```

`exportToPhotos()` の実装:

```swift
#if os(iOS)
private func exportToPhotos() {
    Task {
        let status = await PhotoLibraryService.requestAuthorization()
        guard status == .authorized || status == .limited else {
            // show authorization error
            return
        }
        guard let data = ExportService.exportScreen(screen, device: device, format: format, languageCode: languageCode) else {
            return
        }
        try await PhotoLibraryService.saveImage(data)
        // show success feedback
    }
}
#endif
```

## 受け入れ基準

- [ ] `PhotoLibraryService.swift` が作成され、iOS でのみコンパイルされる
- [ ] 単画面エクスポート: iPad で「Save to Photos」/「Save to Files」の2択が表示される
- [ ] 単画面エクスポート: 「Save to Photos」で写真アプリに画像が保存される
- [ ] 写真ライブラリへのアクセス権限が適切に要求される
- [ ] 権限が拒否された場合にエラーメッセージが表示される
- [ ] macOS のエクスポート UI は変更なし（既存のファイル保存フロー維持）
- [ ] macOS ビルドで `PhotoLibraryService` がコンパイル対象外になっている

## 依存関係

- #041 が完了していること（`NSPhotoLibraryAddUsageDescription` の設定）
- #045 が完了していること（エクスポートパイプラインの iOS 対応）

## 備考

- `PHPhotoLibrary.requestAuthorization(for: .addOnly)` は「写真を追加」のみの権限で、ユーザーのフォトライブラリ全体へのアクセスは不要。プライバシー上のベストプラクティス。
- アルバム名の重複: 同名のアルバムが既に存在する場合は再利用する（`fetchOrCreateAlbum`）。

## 複雑度

L
