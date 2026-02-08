# Issue #022: テキスト配置 (左寄せ・右寄せ) が反映されない

## Phase / Priority
Phase 5 | P1 (High)

## 概要

PropertiesPanelView でタイトル・サブタイトルのアライメントを leading (左寄せ) や trailing (右寄せ) に変更しても、キャンバスプレビューおよびエクスポート画像に反映されない。`.multilineTextAlignment()` のみ適用されており、VStack 内での Text フレームの alignment が設定されていないことが原因。

## 現状の問題

1. `.multilineTextAlignment()` は複数行テキストの折り返し方向のみ制御
2. Text ビュー自体は VStack 内でデフォルトの center 配置のまま
3. `.frame(maxWidth: .infinity, alignment:)` が未設定のため、1行テキストの位置が変わらない

## 対象ファイル

- 変更: `ScreenShotMaker/Views/CanvasView.swift` (プレビュー描画の textContent)
- 変更: `ScreenShotMaker/Services/ExportService.swift` (エクスポート描画の textContent)

## 実装詳細

1. **CanvasView の textContent 修正**
   - タイトル Text に `.frame(maxWidth: .infinity, alignment:)` を追加
   - alignment は `TextStyleAlignment` → SwiftUI `Alignment` 変換 (.leading → .leading, .center → .center, .trailing → .trailing)
   - サブタイトル Text にも同様に適用

2. **ExportService の textContent 修正**
   - CanvasView と同一の修正を適用

3. **VStack の alignment パラメータ**
   - タイトルとサブタイトルで異なる alignment を設定可能にするため、VStack の alignment はデフォルト (.center) のまま、個別の Text に `.frame()` で制御

## 受け入れ基準

- [ ] leading 設定でタイトル/サブタイトルが左寄せ表示される
- [ ] trailing 設定でタイトル/サブタイトルが右寄せ表示される
- [ ] center 設定で中央寄せ表示が維持される
- [ ] プレビューとエクスポートで同じ配置結果になる
- [ ] 複数行テキストの折り返し方向も alignment に連動する

## 依存関係

なし

## 複雑度

S
