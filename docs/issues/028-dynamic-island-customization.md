# Issue #028: Dynamic Island の長さ・太さカスタマイズ

## Phase / Priority
Phase 6 | P2 (Medium)

## 概要

現在 Dynamic Island（iPhone フレームの上部カプセル）は `screenWidth * 0.25`（幅）と `screenWidth * 0.03`（高さ）でハードコードされており、ユーザーが長さや太さを調整できない。#027 で導入した `DeviceFrameConfig` を拡張し、Dynamic Island のサイズもカスタマイズ可能にする。

## 現状の問題

1. Dynamic Island の幅・高さが `DeviceFrameView.framedContent` 内でハードコード
2. デバイスモデルによって実際の Dynamic Island サイズが異なるが、一律同じ比率で描画される
3. ユーザーが非表示にしたり、サイズを微調整する手段がない

## 対象ファイル

- 変更: `ScreenShotMaker/Models/Screen.swift` (`DeviceFrameConfig` にプロパティ追加)
- 変更: `ScreenShotMaker/Models/DeviceFrame.swift` (`DeviceFrameSpec.applying` と描画ロジック)
- 変更: `ScreenShotMaker/Views/PropertiesPanelView.swift` (UI 追加)

## 実装詳細

1. **DeviceFrameConfig にプロパティ追加**
   - `dynamicIslandWidthRatio: Double` (デフォルト 1.0 — 現在の `0.25` に対する倍率)
   - `dynamicIslandHeightRatio: Double` (デフォルト 1.0 — 現在の `0.03` に対する倍率)
   - `showDynamicIsland: Bool` (デフォルト true)

2. **DeviceFrameView の描画ロジック更新**
   - `framedContent` 内の Dynamic Island セクションで config の値を参照
   - `showDynamicIsland == false` の場合は Dynamic Island を非表示

3. **PropertiesPanelView の Device Frame セクション拡張**
   - 「Show Dynamic Island」トグル
   - 幅・太さの Slider（各 0.0〜3.0、0.1 刻み）

4. **Codable 後方互換**
   - `decodeIfPresent` でデフォルト値にフォールバック

## 受け入れ基準

- [ ] Dynamic Island の幅を Slider で調整できる
- [ ] Dynamic Island の太さを Slider で調整できる
- [ ] Dynamic Island を非表示にできる
- [ ] カスタマイズ内容がプロジェクトファイルに保存される
- [ ] Reset to Default で元のサイズに戻る
- [ ] iPad / Mac フレームには Dynamic Island 設定が表示されない

## 依存関係

- #027 (DeviceFrameConfig の導入) — 完了済み

## 複雑度

S
