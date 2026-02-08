# Issue #027: デバイスフレームのカスタマイズ

## Phase / Priority
Phase 5 | P3 (Low)

## 概要

現在のデバイスフレームはカテゴリ (iPhone/iPad/Mac) ごとにハードコードされた `DeviceFrameSpec` で描画されており、ユーザーが外観を調整できない。フレームの色・ベゼル幅・角丸等をカスタマイズ可能にするか、外部フレーム画像を利用できる仕組みを提供する。

## 現状の問題

1. `DeviceFrameSpec` がカテゴリごとに固定値 (bezelRatio, cornerRadiusRatio, frameColor)
2. フレームのデザインがシンプルすぎてリアリティに欠ける
3. ユーザーがフレームの見た目を調整する手段がない

## 対象ファイル

- 変更: `ScreenShotMaker/Models/DeviceFrame.swift` (カスタマイズ対応)
- 変更: `ScreenShotMaker/Models/Screen.swift` (フレーム設定の保存)
- 変更: `ScreenShotMaker/Views/PropertiesPanelView.swift` (フレーム設定 UI)

## 実装詳細

### Option A: パラメータカスタマイズ

1. **Screen モデルにフレーム設定を追加**
   - `frameColor: String` (hex カラー)
   - `frameBezelWidth: Double` (ベゼル幅の倍率)
   - `frameCornerRadius: Double` (角丸の倍率)
   - デフォルト値はカテゴリごとの現在の値

2. **PropertiesPanelView にフレーム設定セクション追加**
   - フレームカラー: ColorPicker
   - ベゼル幅: Slider
   - 角丸: Slider

3. **DeviceFrameView の修正**
   - ハードコード値ではなくパラメータ受け取りに変更

### Option B: 外部フレーム画像のオーバーレイ

1. **フレーム画像のインポート**
   - PNG 画像 (透明背景) をフレームとしてインポート
   - スクリーンショットの上にオーバーレイ表示

2. **フレーム画像の位置調整**
   - スクリーンショットとフレーム画像のアライメント設定
   - スケーリング設定

## 受け入れ基準

- [ ] デバイスフレームの色をユーザーが変更できる
- [ ] ベゼル幅・角丸を調整できる（Option A の場合）
- [ ] または外部フレーム画像をインポートできる（Option B の場合）
- [ ] カスタマイズ内容がプロジェクトファイルに保存される
- [ ] デフォルト設定にリセットできる

## 依存関係

なし

## 複雑度

M
