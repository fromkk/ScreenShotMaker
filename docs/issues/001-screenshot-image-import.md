# Issue #001: スクリーンショット画像インポート

## Phase / Priority
Phase 1 | P0 (Blocker)

## 概要

ファイルピッカーおよびドラッグ&ドロップにより、スクリーンショット画像（PNG/JPEG）を読み込み `Screen.screenshotImageData` に格納する。

## 対象ファイル

- 変更: `ScreenShotMaker/Views/PropertiesPanelView.swift` (L219: `// TODO: File picker`)
- 変更: `ScreenShotMaker/Views/CanvasView.swift` (L121-141: screenshotPlaceholder に D&D 対応)
- 新規: `ScreenShotMaker/Utils/ImageLoader.swift`

## 実装詳細

1. **ImageLoader ユーティリティ作成**
   - `static func loadImage(from url: URL) throws -> Data` メソッド
   - 対応形式: PNG (`.png`), JPEG (`.jpg`, `.jpeg`)
   - ファイルサイズ上限: 20MB
   - エラー型 `ImageLoadError` を定義（`.invalidFormat`, `.fileTooLarge`, `.fileNotFound`）

2. **PropertiesPanelView のファイルピッカー** (L219)
   - `NSOpenPanel` を使用
   - `allowedContentTypes: [.png, .jpeg]`
   - 選択されたファイルを `ImageLoader.loadImage()` で読み込み
   - 読み込んだ `Data` を `screen.wrappedValue.screenshotImageData` に代入

3. **CanvasView のドラッグ&ドロップ** (L121-141)
   - `screenshotPlaceholder` に `.onDrop(of: [.fileURL], isTargeted:)` を追加
   - ドロップされたファイル URL を `ImageLoader.loadImage()` で読み込み
   - `state.selectedScreen?.screenshotImageData` に代入

4. **エラーハンドリング**
   - 不正な形式やサイズオーバーの場合 `.alert()` でユーザーに通知

## 受け入れ基準

- [ ] PropertiesPanelView の「Drop image or click to browse」をクリックするとファイル選択ダイアログが表示される
- [ ] PNG/JPEG のみ選択可能（他の形式はグレーアウト）
- [ ] 20MB を超えるファイルはエラーメッセージが表示される
- [ ] CanvasView のプレースホルダーに PNG/JPEG をドラッグ&ドロップで読み込める
- [ ] 読み込んだ画像データが `Screen.screenshotImageData` に正しく格納される
- [ ] 非画像ファイルのドロップは無視される

## 依存関係

なし

## 複雑度

M
