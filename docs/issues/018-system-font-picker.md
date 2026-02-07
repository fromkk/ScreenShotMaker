# Issue #018: システムフォントピッカー

## Phase / Priority
Phase 4 | P3 (Low)

## 概要

テキストのフォント選択に macOS のシステムフォント一覧を利用し、ドロップダウンまたは `NSFontPanel` でフォントを選択できるようにする。

## 対象ファイル

- 変更: `ScreenShotMaker/Views/PropertiesPanelView.swift` (フォント選択 UI)

## 実装詳細

1. **フォント一覧の取得**
   - `NSFontManager.shared.availableFontFamilies` でシステムフォント取得
   - 一覧をアルファベット順でソート

2. **UI 実装の選択肢**
   - **Option A**: Picker (ドロップダウン) で一覧表示
     - 検索フィルタ付き
     - 各フォント名をそのフォントで表示
   - **Option B**: `NSFontPanel` を使用
     - macOS ネイティブのフォント選択パネル

3. **PropertiesPanelView の変更**
   - 現在の Font テキストフィールドをフォントピッカーに置き換え
   - 選択されたフォント名を `screen.fontFamily` に設定

4. **プレビュー反映**
   - CanvasView の `textContent` で `.font(.custom(screen.fontFamily, size:))` を使用

## 受け入れ基準

- [ ] フォントフィールドクリックでフォント一覧が表示される
- [ ] システムにインストールされた全フォントが選択可能
- [ ] 選択したフォントがキャンバスプレビューに即座に反映される
- [ ] 選択フォント名がプロジェクトファイルに保存される

## 依存関係

なし

## 複雑度

S
