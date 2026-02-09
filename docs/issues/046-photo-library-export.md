# Issue #046: PHPhotoLibrary による写真アプリへのエクスポート（iOS 専用）

## Status
Open

## Phase / Priority
Phase 8 (iPad対応) | P1 (High)

## 概要

iPad でのエクスポート先として、写真アプリ（PHPhotoLibrary）への保存機能を追加する。単画面エクスポートと バッチエクスポートの両方に対応し、バッチエクスポート時にはプロジェクト名のアルバムを自動作成する。iPad のエクスポート UI では「写真に保存」と「フォルダに保存」の2択を提示する。

## 現状

- エクスポートは全てファイルシステムへの書き出しのみ（`Data.write(to:)`）
- `ExportService.exportScreen()` は `Data?` を返す — PHPhotoLibrary との連携に最適
- `NSPhotoLibraryAddUsageDescription` 未設定（#041 で追加予定）
- `import Photos` なし

## 対象ファイル

- 新規: `ScreenShotMaker/Services/PhotoLibraryService.swift`
- 変更: `ScreenShotMaker/Views/ContentView.swift`（単画面エクスポート UI に「写真に保存」を追加）
- 変更: `ScreenShotMaker/Views/ExportProgressView.swift`（バッチエクスポート完了時に「写真に保存」を追加）

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

    /// 複数画像をアルバムに保存（バッチエクスポート用）
    static func saveImagesToAlbum(
        images: [(data: Data, filename: String)],
        albumName: String,
        progressHandler: @escaping (Int, Int) -> Void
    ) async throws {
        // 1. アルバムを取得または作成
        let album = try await fetchOrCreateAlbum(named: albumName)

        // 2. 画像を順次保存してアルバムに追加
        for (index, image) in images.enumerated() {
            try await PHPhotoLibrary.shared().performChanges {
                let assetRequest = PHAssetCreationRequest.forAsset()
                assetRequest.addResource(with: .photo, data: image.data, options: nil)

                guard let placeholder = assetRequest.placeholderForCreatedAsset,
                      let albumChangeRequest = PHAssetCollectionChangeRequest(for: album) else { return }
                albumChangeRequest.addAssets([placeholder] as NSArray)
            }
            progressHandler(index + 1, images.count)
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

### 3. ContentView.swift — バッチエクスポート UI

iPad 時にバッチエクスポートボタンも2択に:

```swift
#if os(iOS)
Menu("Export All") {
    Button("Save to Photos") {
        startBatchExportToPhotos()
    }
    Button("Save to Files") {
        showBatchExportFolderPicker = true
    }
}
#else
Button("Export All") {
    showBatchExportFolderPicker = true
}
#endif
```

### 4. ExportProgressView.swift — バッチエクスポート完了時

macOS では「Finderで開く」ボタン、iPad では保存先に応じた表示:

```swift
#if os(macOS)
Button("Show in Finder") {
    NSWorkspace.shared.open(outputDirectory)
}
#elseif os(iOS)
// 写真保存の場合: 「写真アプリを開く」または完了メッセージ
// フォルダ保存の場合: 完了メッセージのみ
#endif
```

### 5. バッチエクスポート → 写真保存のフロー

```
1. ユーザーが「Save to Photos」を選択
2. PHPhotoLibrary の権限を要求
3. 権限が許可されたら ExportProgressView をシートで表示
4. 全 (言語 × デバイス × スクリーン) の組み合わせでレンダリング
5. プロジェクト名のアルバムを作成（例: "My App Screenshots"）
6. 各画像を PHAssetCreationRequest で保存しアルバムに追加
7. ExportProgressState で進捗を更新
8. 完了時に「写真アプリに保存しました」メッセージを表示
```

## 受け入れ基準

- [ ] `PhotoLibraryService.swift` が作成され、iOS でのみコンパイルされる
- [ ] 単画面エクスポート: iPad で「Save to Photos」/「Save to Files」の2択が表示される
- [ ] 単画面エクスポート: 「Save to Photos」で写真アプリに画像が保存される
- [ ] バッチエクスポート: iPad で「Save to Photos」/「Save to Files」の2択が表示される
- [ ] バッチエクスポート: 「Save to Photos」でプロジェクト名のアルバムが作成される
- [ ] バッチエクスポート: 全画像がアルバムに保存される
- [ ] バッチエクスポート: 進捗バーが正しく更新される
- [ ] バッチエクスポート: キャンセルが機能する
- [ ] 写真ライブラリへのアクセス権限が適切に要求される
- [ ] 権限が拒否された場合にエラーメッセージが表示される
- [ ] macOS のエクスポート UI は変更なし（既存のファイル保存フロー維持）
- [ ] macOS ビルドで `PhotoLibraryService` がコンパイル対象外になっている

## 依存関係

- #041 が完了していること（`NSPhotoLibraryAddUsageDescription` の設定）
- #045 が完了していること（エクスポートパイプラインの iOS 対応）

## 備考

- `PHPhotoLibrary.requestAuthorization(for: .addOnly)` は「写真を追加」のみの権限で、ユーザーのフォトライブラリ全体へのアクセスは不要。プライバシー上のベストプラクティス。
- バッチエクスポートで大量の画像を保存する場合、`performChanges` の呼び出しを分割して進捗更新を行う。一度の `performChanges` に全画像を入れるとキャンセル不可になるため。
- アルバム名の重複: 同名のアルバムが既に存在する場合は再利用する（`fetchOrCreateAlbum`）。

## 複雑度

L
