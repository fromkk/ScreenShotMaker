# Issue #004: 単一スクリーンエクスポート

## Phase / Priority
Phase 1 | P0 (Blocker)

## 概要

選択中のスクリーンを、選択中のデバイスサイズの解像度で PNG または JPEG として書き出す。

## 対象ファイル

- 新規: `ScreenShotMaker/Services/ExportService.swift`
- 変更: `ScreenShotMaker/Views/ContentView.swift` (L59-63: `ExportButton`)

## 実装詳細

1. **ExportService の作成**
   - `struct ExportService`
   - メソッド: `static func exportScreen(_ screen: Screen, device: DeviceSize, format: ExportFormat) -> NSImage?`
   - `@MainActor` で SwiftUI View を `ImageRenderer` でレンダリング
   - レンダリングビューはキャンバスと同じレイアウト（テキスト + 背景 + スクリーンショット）を使用
   - 出力サイズ: `device.portraitWidth × device.portraitHeight` ピクセル

2. **ExportFormat enum**
   ```swift
   enum ExportFormat: String, CaseIterable {
       case png, jpeg
   }
   ```

3. **ExportButton の実装** (ContentView.swift:L59-63)
   - クリック時に `NSSavePanel` を表示
   - ファイル形式選択（PNG / JPEG）
   - `ExportService.exportScreen()` でレンダリング
   - `NSImage` → `Data` → ファイル書き出し

4. **レンダリングビュー**
   - `ExportableScreenView` を新規作成（CanvasView のプレビューロジックを再利用）
   - ズームなし、実寸サイズでレンダリング
   - `ImageRenderer` の `scale` を 1.0 に設定（ピクセル等倍）

## 受け入れ基準

- [ ] Export ボタンクリックで保存ダイアログが表示される
- [ ] PNG / JPEG 形式を選択できる
- [ ] 出力画像のピクセルサイズが選択中デバイスの解像度と一致する
- [ ] テキスト（タイトル・サブタイトル）が正しくレンダリングされる
- [ ] 背景（ソリッドカラー・グラデーション・画像）が正しくレンダリングされる
- [ ] スクリーンショット画像が含まれる場合、正しく描画される
- [ ] スクリーンが未選択の場合は Export ボタンが無効化される

## 依存関係

- #002 が完了していること（画像表示ロジックが必要）

## 複雑度

L
