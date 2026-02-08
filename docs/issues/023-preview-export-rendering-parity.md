# Issue #023: プレビューとエクスポートの描画差分

## Phase / Priority
Phase 5 | P1 (High)

## 概要

CanvasView のプレビュー表示とエクスポート画像で文字サイズや全体のレイアウトに差分がある。特にテキストがエクスポートで小さく表示される問題が報告されている。CanvasView と ExportService で異なるフォントサイズ計算ロジックを使用していることが原因。

## 現状の問題

### フォントサイズ計算の不一致

**CanvasView:**
```swift
let titleSize = screen.fontSize * zoomScale * 0.4
let subtitleSize = screen.fontSize * zoomScale * 0.25
```
- ハードコードされた倍率 (0.4 / 0.25) で計算
- サブタイトルはタイトルの 62.5% のサイズ

**ExportService:**
```swift
let titleSize = ScalingService.scaledFontSize(screen.fontSize, factor: sf)
let subtitleSize = ScalingService.scaledFontSize(screen.fontSize * 0.6, factor: sf)
```
- ScalingService 経由でデバイス間スケーリング適用
- サブタイトルはタイトルの 60% のサイズ
- minimum 12pt のクランプあり

### パディング・角丸の不一致
- CanvasView: ハードコード値 (spacing: 6, padding: 20 等)
- ExportService: `ScalingService.scaledPadding()` / `scaledCornerRadius()` 使用

## 対象ファイル

- 変更: `ScreenShotMaker/Views/CanvasView.swift` (プレビュー描画ロジック)
- 変更: `ScreenShotMaker/Services/ExportService.swift` (必要に応じて調整)

## 実装詳細

1. **描画ロジックの共通化**
   - ExportService の ExportableScreenView を正とし、CanvasView のプレビューをそれに合わせる
   - CanvasView では「実際のエクスポートサイズ → zoomScale で縮小表示」というアプローチに変更
   - つまり ExportService と同じ計算でレイアウトを構築し、全体を `.scaleEffect(zoomScale * previewFactor)` で縮小

2. **もしくは共通レンダリング関数の抽出**
   - テキストサイズ・パディング・角丸の計算を共通ヘルパーに抽出
   - CanvasView と ExportService の両方から同一のヘルパーを呼び出し
   - CanvasView 側は結果に `zoomScale` を適用してプレビュー表示

3. **プレビュー精度の検証**
   - 複数デバイスサイズでプレビューとエクスポートを比較
   - フォントサイズ・パディング・角丸・画像配置が一致することを確認

## 受け入れ基準

- [ ] プレビュー表示がエクスポート結果と視覚的に一致する
- [ ] フォントサイズの比率がプレビュー・エクスポートで同一
- [ ] パディング・角丸の比率がプレビュー・エクスポートで同一
- [ ] ズームレベル変更時もレイアウト比率が維持される
- [ ] 異なるデバイスサイズ切替時もプレビューが正確

## 依存関係

なし

## 複雑度

M
