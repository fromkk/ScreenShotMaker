# Issue #014: 横向き (Landscape) 対応

## Phase / Priority
Phase 4 | P2 (Medium)

## 概要

スクリーンごとに縦向き (Portrait) / 横向き (Landscape) を切り替えられるようにする。

## 対象ファイル

- 変更: `ScreenShotMaker/Models/Screen.swift` (`isLandscape` プロパティ追加)
- 変更: `ScreenShotMaker/Views/CanvasView.swift` (寸法の入れ替え)
- 変更: `ScreenShotMaker/Views/PropertiesPanelView.swift` (トグル追加)

## 実装詳細

1. **Screen モデルの拡張** (Screen.swift)
   - `var isLandscape: Bool = false` を追加
   - `init` にパラメータ追加

2. **CanvasView の対応** (CanvasView.swift)
   - `screenshotPreview` メソッド内で `isLandscape` に応じて width/height を入れ替え
   - `bottomBar` のサイズ表示も連動

3. **PropertiesPanelView の対応**
   - Layout セクションに「Orientation」トグルまたは Picker を追加
   - Portrait / Landscape の2択

4. **ExportService の対応**
   - `isLandscape == true` の場合、`device.landscapeWidth × device.landscapeHeight` でエクスポート

## 受け入れ基準

- [ ] スクリーンごとに Portrait / Landscape を切り替えられる
- [ ] 切り替え時にキャンバスの寸法が即座に反映される
- [ ] 下部のサイズ表示が横向き寸法に更新される
- [ ] エクスポート画像が正しい横向き寸法で出力される

## 依存関係

- #002 が完了していること

## 複雑度

S
