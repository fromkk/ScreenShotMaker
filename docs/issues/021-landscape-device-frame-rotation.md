# Issue #021: Landscape 時のデバイスフレーム回転対応

## Phase / Priority
Phase 5 | P1 (High)

## 概要

Screen の `isLandscape` を有効にしても、デバイスフレーム付き表示で iPhone のフレームや画像が横向きにならない。CanvasView と ExportService の両方で、デバイスフレームに渡す幅・高さが常に `portraitWidth`/`portraitHeight` を使用しているため。

## 現状の問題

1. CanvasView (line ~169-179): DeviceFrameView に常に `device.portraitWidth` / `device.portraitHeight` を渡している
2. ExportService (line ~144-153): 同様に常に `portraitWidth` / `portraitHeight` を使用
3. DeviceSize には `landscapeWidth` / `landscapeHeight` computed property が存在するが未使用

## 対象ファイル

- 変更: `ScreenShotMaker/Views/CanvasView.swift` (プレビュー描画)
- 変更: `ScreenShotMaker/Services/ExportService.swift` (エクスポート描画)

## 実装詳細

1. **CanvasView の修正**
   - `screen.isLandscape` の場合、DeviceFrameView に `device.landscapeWidth` / `device.landscapeHeight` を渡す
   - スクリーンショット画像のアスペクト比も横向き寸法に合わせる

2. **ExportService の修正**
   - ExportableScreenView で同様に `isLandscape` に応じた寸法切替
   - エクスポート時の全体サイズ計算も横向き寸法を使用

3. **DeviceFrameView の確認**
   - 渡された幅 > 高さの場合、フレームが横長で描画されることを確認
   - 必要に応じてノッチ/ホームインジケータの位置を横向き用に調整

## 受け入れ基準

- [ ] Landscape 有効時、プレビューでデバイスフレームが横向き表示される
- [ ] Landscape 有効時、エクスポート画像でデバイスフレームが横向き表示される
- [ ] スクリーンショット画像がフレーム内で正しくフィットする
- [ ] Portrait に戻すとフレームが縦向きに戻る
- [ ] フレーム非表示時の Landscape 動作に影響がない

## 依存関係

なし

## 複雑度

S
