# Issue #003: 背景画像サポート

## Phase / Priority
Phase 1 | P2 (Medium)

## 概要

`BackgroundStyle.image(path: String)` を `BackgroundStyle.image(data: Data)` に変更し、背景画像の選択・表示・エクスポートをサポートする。

## 対象ファイル

- 変更: `ScreenShotMaker/Models/BackgroundStyle.swift` (L6: `.image(path:)` → `.image(data:)`)
- 変更: `ScreenShotMaker/Views/CanvasView.swift` (L51-53: `backgroundView` の `.image` case)
- 変更: `ScreenShotMaker/Views/PropertiesPanelView.swift` (L153-161: 画像選択ボタン)

## 実装詳細

1. **BackgroundStyle の変更** (BackgroundStyle.swift:6)
   - `.image(path: String)` → `.image(data: Data)`
   - `Data` として画像バイナリを直接保持（プロジェクトファイルに含める）

2. **PropertiesPanelView の画像選択** (L153-161)
   - `NSOpenPanel` で画像ファイルを選択
   - 選択された画像を `Data` として読み込み
   - `screen.wrappedValue.background = .image(data: imageData)` に代入
   - 画像選択後はプレビューサムネイルを表示

3. **CanvasView の背景画像表示** (L51-53)
   - `.image(data:)` case で `NSImage(data:)` → `Image(nsImage:)` で描画
   - `.resizable()` + `.scaledToFill()` で背景全体を覆う
   - `.clipped()` ではみ出し部分を切り取る

4. **backgroundTypePicker の更新** (PropertiesPanelView.swift:L124)
   - `default:` case を `screen.wrappedValue.background = .image(data: Data())` に変更

## 受け入れ基準

- [ ] Background Type で「Image」を選択すると画像選択ボタンが表示される
- [ ] 画像を選択するとキャンバスの背景に表示される
- [ ] 背景画像はキャンバス全体を覆い、アスペクト比を維持して拡大される
- [ ] プロジェクト保存時に背景画像データも含まれる
- [ ] 画像が未選択の場合はグレーのプレースホルダーが表示される

## 依存関係

- #001 の `ImageLoader` ユーティリティを再利用

## 複雑度

S
