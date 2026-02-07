# Issue #017: ネイティブカラーピッカー

## Phase / Priority
Phase 4 | P3 (Low)

## 概要

テキストカラーおよび背景カラーの選択に macOS ネイティブのカラーピッカー (`ColorPicker`) を統合する。

## 対象ファイル

- 変更: `ScreenShotMaker/Views/PropertiesPanelView.swift` (カラー入力 UI 変更)

## 実装詳細

1. **SwiftUI ColorPicker の使用**
   - テキストカラーのカラーパッチをクリック → `ColorPicker` 表示
   - 背景カラー（solidColor / gradient の start/end）でも同様

2. **Color ↔ HexColor の変換**
   - `ColorPicker` が返す `Color` を hex 文字列に変換するヘルパー追加
   - `NSColor` 経由で RGB 値を取得 → hex 文字列に変換

3. **UI 更新**
   - 既存のカラーパッチ（24x24 の角丸四角形）をクリッカブルに変更
   - hex テキストフィールドは手動入力用として残す
   - ColorPicker 選択時に hex テキストフィールドも同期更新

## 受け入れ基準

- [ ] カラーパッチクリックでカラーピッカーが表示される
- [ ] カラーピッカーで選択した色がリアルタイムでプレビューに反映される
- [ ] 選択色の hex 値がテキストフィールドに反映される
- [ ] hex テキストフィールドへの手動入力も引き続き機能する

## 依存関係

なし

## 複雑度

S
