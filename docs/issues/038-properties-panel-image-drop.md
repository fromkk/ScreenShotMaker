# 038: PropertiesPanel画像ドラッグ&ドロップ機能の実装不足

## Status
Open

## Priority
Medium

## 問題の説明
PropertiesPanelViewのスクリーンショット画像セクションにドラッグ&ドロップ機能が実装されていない。CanvasViewには`.onDrop`モディファイアが実装されているが、PropertiesPanelViewの「Drop image or click to browse」エリアにはドラッグ&ドロップハンドラーがなく、クリックによるファイルピッカーのみが機能している。

## 現状の実装
- **CanvasView**: `.onDrop(of: [.fileURL], isTargeted: nil)`が実装済み、`handleDrop(providers:)`メソッドでファイルURLを処理
- **PropertiesPanelView**: `.onTapGesture`のみ実装、ドラッグ&ドロップハンドラーなし

## 期待される動作
PropertiesPanelViewのスクリーンショット画像エリア（「Drop image or click to browse」表示部分）にファイルをドラッグ&ドロップすると、画像が読み込まれる。

## 実装案

### PropertiesPanelView.swift の修正

`screenshotImageSection` 内のドロップゾーンに `.onDrop` モディファイアを追加:

```swift
.onTapGesture {
    openImagePicker(screen: screen)
}
.onDrop(of: [.fileURL], isTargeted: nil) { providers in
    handleScreenshotDrop(providers: providers, screen: screen)
}
```

`handleScreenshotDrop` メソッドを追加:

```swift
private func handleScreenshotDrop(providers: [NSItemProvider], screen: Binding<Screen>) -> Bool {
    guard let provider = providers.first else { return false }
    provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier) { data, _ in
        guard let data = data as? Data,
              let url = URL(dataRepresentation: data, relativeTo: nil) else { return }
        DispatchQueue.main.async {
            do {
                let imageData = try ImageLoader.loadImage(from: url)
                if let category = state.selectedDevice?.category {
                    screen.wrappedValue.setScreenshotImageData(imageData, for: category)
                }
            } catch {
                imageLoadError = error.localizedDescription
                showImageLoadError = true
            }
        }
    }
    return true
}
```

## 関連ファイル
- `ScreenShotMaker/Views/PropertiesPanelView.swift` (Lines 550-575)
- `ScreenShotMaker/Views/CanvasView.swift` (Lines 197-213) - 参考実装

## テスト計画
- [ ] PropertiesPanelViewの画像エリアに画像ファイルをドラッグ&ドロップできることを確認
- [ ] PNG/JPEG形式の画像が正しく読み込まれることを確認
- [ ] 不正なファイルをドロップした場合、エラーアラートが表示されることを確認
- [ ] 既存のクリックによるファイルピッカー機能が引き続き動作することを確認
- [ ] CanvasViewのドラッグ&ドロップ機能が引き続き動作することを確認

## 影響範囲
- `PropertiesPanelView.swift` のみ修正
- 既存のAPI、データモデルへの影響なし
- UIの動作追加のみ（破壊的変更なし）

## 備考
CanvasViewの実装と同様のパターンを使用することで、一貫性のあるユーザー体験を提供できる。
