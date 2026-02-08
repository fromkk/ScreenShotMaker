# Issue #031: スクリーンショット画像の表示モード選択（Aspect Fit / Aspect Fill）

## Phase / Priority
Phase 6 | P2 (Medium)

## 概要

現在、スクリーンショット画像は `.aspectRatio(contentMode: .fit)` でハードコードされており、ユーザーが表示モードを選択できない。画像によっては Aspect Fill で表示したい場合もあるため、Screen ごとに Aspect Fit / Aspect Fill を切り替えられるようにする。

## 現状の問題

1. スクリーンショット画像の `contentMode` が `.fit` で固定されている
2. CanvasView（プレビュー）と ExportService（エクスポート）の両方で同じくハードコード
3. 画像のアスペクト比がフレームと異なる場合、Fit では余白が生じ、Fill では切り抜きが必要になるが、ユーザーが選択できない

## 対象ファイル

- 変更: `ScreenShotMaker/Models/Screen.swift` (`screenshotContentMode` プロパティ追加)
- 変更: `ScreenShotMaker/Views/CanvasView.swift` (プレビュー描画の contentMode 反映)
- 変更: `ScreenShotMaker/Services/ExportService.swift` (エクスポート描画の contentMode 反映)
- 変更: `ScreenShotMaker/Views/PropertiesPanelView.swift` (Picker UI 追加)

## 実装詳細

1. **Screen に contentMode プロパティ追加**
   ```swift
   enum ScreenshotContentMode: String, Codable, CaseIterable {
       case fit
       case fill
   }
   ```
   - `Screen` に `screenshotContentMode: ScreenshotContentMode = .fit` を追加
   - Codable: `decodeIfPresent` + `.fit` フォールバックで後方互換

2. **CanvasView の screenshotPlaceholder 更新**
   ```swift
   Image(nsImage: nsImage)
       .resizable()
       .aspectRatio(contentMode: screen.screenshotContentMode == .fill ? .fill : .fit)
       .clipShape(RoundedRectangle(cornerRadius: 8))
   ```

3. **ExportService の screenshotView 更新**
   - 同様に `screen.screenshotContentMode` を参照して `contentMode` を切り替え

4. **PropertiesPanelView に Picker 追加**
   - Screenshot Image セクション内に Segmented Picker を追加
   - 選択肢: 「Fit」「Fill」

## 受け入れ基準

- [ ] PropertiesPanelView に Aspect Fit / Aspect Fill の切り替え Picker が表示される
- [ ] Fit 選択時、画像が収まるように表示される（余白あり）
- [ ] Fill 選択時、画像がフレームを埋めるように表示される（はみ出し部分はクリップ）
- [ ] プレビュー（CanvasView）とエクスポート（ExportService）で同じ表示になる
- [ ] 設定がプロジェクトファイルに保存・復元される
- [ ] 既存プロジェクトを開いた際、デフォルトで Fit が適用される（後方互換）

## 依存関係

なし

## 複雑度

S
