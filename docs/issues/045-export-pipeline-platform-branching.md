# Issue #045: エクスポートパイプラインのクロスプラットフォーム分岐

## Status
Open

## Phase / Priority
Phase 8 (iPad対応) | P0 (Blocker)

## 概要

`ExportService.swift` のレンダリングパイプラインが `renderer.nsImage` + `NSBitmapImageRep` + `tiffRepresentation` という macOS 専用 API に依存している。`#if canImport(AppKit)` / `#if canImport(UIKit)` で分岐し、iOS 側では `renderer.uiImage` + `UIImage.pngData()` / `.jpegData()` を使用する。また `ExportableScreenView` 内の画像表示を #042 のヘルパーに置換する。

## 現状の問題

### レンダリングパイプライン（`exportScreen` 関数）

```swift
// ExportService.swift
static func exportScreen(_ screen: Screen, device: DeviceSize, format: ExportFormat, languageCode: String = "en") -> Data? {
    let view = ExportableScreenView(...)
    let renderer = ImageRenderer(content: view)
    renderer.scale = 1.0

    guard let nsImage = renderer.nsImage,                    // ← macOS 専用
          let tiffData = nsImage.tiffRepresentation,         // ← macOS 専用
          let bitmap = NSBitmapImageRep(data: tiffData)      // ← macOS 専用
    else { return nil }

    switch format {
    case .png:  return bitmap.representation(using: .png, properties: [:])
    case .jpeg: return bitmap.representation(using: .jpeg, properties: [.compressionFactor: 0.9])
    }
}
```

### ExportableScreenView 内の画像表示（4箇所）

```swift
// backgroundView
if let data = screen.backgroundImageData,
   let nsImage = NSImage(data: data) {     // ← macOS 専用
    Image(nsImage: nsImage)                 // ← macOS 専用
}

// screenshotView
if let imageData = screen.screenshotImageData(for: languageCode, category: device.category),
   let nsImage = NSImage(data: imageData) { // ← macOS 専用
    Image(nsImage: nsImage)                  // ← macOS 専用
}
```

## 対象ファイル

- 変更: `ScreenShotMaker/Services/ExportService.swift`

## 実装詳細

### 1. ExportableScreenView の画像表示 → PlatformImage ヘルパー

```swift
// Before
if let data = screen.backgroundImageData,
   let nsImage = NSImage(data: data) {
    Image(nsImage: nsImage)
        .resizable()
}

// After（#042 のヘルパーを使用）
if let data = screen.backgroundImageData,
   let image = PlatformImage(data: data) {
    Image(platformImage: image)
        .resizable()
}
```

同様にスクリーンショット画像の表示箇所も置換。計4箇所。

### 2. exportScreen のレンダリングパイプライン分岐

```swift
static func exportScreen(_ screen: Screen, device: DeviceSize, format: ExportFormat, languageCode: String = "en") -> Data? {
    let view = ExportableScreenView(...)
    let renderer = ImageRenderer(content: view)
    renderer.scale = 1.0

    #if canImport(AppKit)
    guard let nsImage = renderer.nsImage,
          let tiffData = nsImage.tiffRepresentation,
          let bitmap = NSBitmapImageRep(data: tiffData)
    else { return nil }

    switch format {
    case .png:
        return bitmap.representation(using: .png, properties: [:])
    case .jpeg:
        return bitmap.representation(using: .jpeg, properties: [.compressionFactor: 0.9])
    }

    #elseif canImport(UIKit)
    guard let uiImage = renderer.uiImage else { return nil }

    switch format {
    case .png:
        return uiImage.pngData()
    case .jpeg:
        return uiImage.jpegData(compressionQuality: 0.9)
    }
    #endif
}
```

### 3. batchExport 関数

`batchExport` は内部で `exportScreen` を呼び出し、返された `Data` をファイルに書き出すのみ。`exportScreen` が両プラットフォーム対応になれば、`batchExport` 自体は変更不要。

### 4. 画像寸法検証（もしある場合）

`ImageLoader.swift` で `NSBitmapImageRep` を使った画像サイズ検証がある場合は、同様に `PlatformImage` の `.size` プロパティで代替する。

## 受け入れ基準

- [ ] `ExportableScreenView` 内の `NSImage` / `Image(nsImage:)` が全て `PlatformImage` / `Image(platformImage:)` に置換されている
- [ ] `exportScreen` が macOS では `renderer.nsImage` + `NSBitmapImageRep` を使用する
- [ ] `exportScreen` が iOS では `renderer.uiImage` + `UIImage.pngData()` / `.jpegData()` を使用する
- [ ] macOS で PNG エクスポートが正常に動作する
- [ ] macOS で JPEG エクスポートが正常に動作する
- [ ] iPad Simulator で PNG エクスポートが正常に動作する
- [ ] iPad Simulator で JPEG エクスポートが正常に動作する
- [ ] エクスポート画像のピクセルサイズがデバイス解像度と一致する（両プラットフォーム）

## 依存関係

- #041 が完了していること（iOS ターゲット設定）
- #042 が完了していること（`PlatformImage` ヘルパー）

## 備考

- `ImageRenderer` は iOS 16+ / macOS 13+ で利用可能。`.nsImage`（macOS）/ `.uiImage`（iOS）はそれぞれのプラットフォームでのみ利用可能。
- iOS 側の `UIImage.pngData()` / `.jpegData()` は macOS 側の `NSBitmapImageRep.representation(using:)` より簡潔な API。
- `renderer.scale = 1.0` は両プラットフォーム共通で問題なし。
- JPEG 圧縮品質: macOS では `compressionFactor: 0.9`、iOS では `compressionQuality: 0.9` で同等。

## 複雑度

M
