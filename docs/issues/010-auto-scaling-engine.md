# Issue #010: 自動スケーリングエンジン

## Phase / Priority
Phase 3 | P2 (Medium)

## 概要

最大デバイスサイズ（基準サイズ）でデザインしたスクリーンショットレイアウトを、他のデバイスサイズに自動スケーリングする機能。テキストサイズ、余白、画像配置を比例的に縮小/拡大する。

## 対象ファイル

- 新規: `ScreenShotMaker/Services/ScalingService.swift`
- 変更: `ScreenShotMaker/Views/CanvasView.swift` (スケーリング適用)
- 変更: `ScreenShotMaker/Services/ExportService.swift` (エクスポート時のスケーリング)

## 実装詳細

1. **ScalingService の作成**
   ```swift
   struct ScalingService {
       /// 基準デバイスに対するスケール比率を計算
       static func scaleFactor(from reference: DeviceSize, to target: DeviceSize) -> CGFloat

       /// フォントサイズをスケーリング
       static func scaledFontSize(_ size: Double, factor: CGFloat) -> Double

       /// パディングをスケーリング
       static func scaledPadding(_ padding: Double, factor: CGFloat) -> Double
   }
   ```

2. **スケール比率の計算ロジック**
   - 基準: 同じカテゴリの最大デバイスサイズ（例: iPhone なら 6.9" の 1260x2736）
   - 比率: `target.portraitHeight / reference.portraitHeight`
   - テキストは最小可読サイズ（12pt 相当）を下限とする

3. **CanvasView への適用**
   - プレビュー表示時にスケール比率を適用
   - フォントサイズ、パディング値を `ScalingService` で変換

4. **ExportService への適用**
   - エクスポート時にターゲットデバイスに応じたスケーリングを適用
   - テキストが小さすぎないか検証

5. **ScreenShotProject に基準デバイス設定を追加**
   - `var referenceDevice: DeviceSize?` — 基準デバイス（nil の場合は最大を自動選択）

## 受け入れ基準

- [ ] 6.9" iPhone でデザインしたレイアウトが 4.7" iPhone でも適切に表示される
- [ ] テキストが最小可読サイズ以下にならない
- [ ] レイアウトの比率が維持される（テキストと画像のバランス）
- [ ] デバイス切り替え時にキャンバスプレビューが即時更新される
- [ ] エクスポート画像のスケーリングが正しく適用される

## 依存関係

- #002 が完了していること

## 複雑度

L
