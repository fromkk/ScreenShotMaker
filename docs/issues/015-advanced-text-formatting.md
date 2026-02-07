# Issue #015: リッチテキスト対応

## Phase / Priority
Phase 4 | P3 (Low)

## 概要

テキストにボールド・イタリック・テキスト配置（左/中央/右）などのリッチフォーマット機能を追加する。

## 対象ファイル

- 変更: `ScreenShotMaker/Models/Screen.swift` (`TextStyle` 構造体追加)
- 変更: `ScreenShotMaker/Views/PropertiesPanelView.swift` (フォーマットツールバー追加)
- 変更: `ScreenShotMaker/Views/CanvasView.swift` (スタイル適用)

## 実装詳細

1. **TextStyle の追加** (Screen.swift)
   ```swift
   struct TextStyle: Codable, Hashable {
       var isBold: Bool = true
       var isItalic: Bool = false
       var textAlignment: TextAlignment = .center

       enum TextAlignment: String, Codable {
           case leading, center, trailing
       }
   }
   ```

2. **Screen モデルの変更**
   - `var titleStyle: TextStyle = TextStyle()` 追加
   - `var subtitleStyle: TextStyle = TextStyle(isBold: false)` 追加

3. **PropertiesPanelView のフォーマット UI**
   - Bold (B) / Italic (I) トグルボタン
   - テキスト配置ボタン（左 / 中央 / 右）
   - Title と Subtitle それぞれに適用

4. **CanvasView のスタイル適用**
   - `textContent` メソッドで `TextStyle` を参照
   - `.bold()` / `.italic()` / `.multilineTextAlignment()` を条件適用

## 受け入れ基準

- [ ] ボールド/イタリックのトグルが機能する
- [ ] テキスト配置の切り替えがキャンバスに反映される
- [ ] スタイルがプロジェクトファイルに保存される
- [ ] エクスポート画像にスタイルが正しく反映される

## 依存関係

- #002 が完了していること

## 複雑度

L
