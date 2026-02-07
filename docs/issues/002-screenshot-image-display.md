# Issue #002: キャンバスでの画像表示

## Phase / Priority
Phase 1 | P0 (Blocker)

## 概要

`Screen.screenshotImageData` に格納された画像データを `NSImage` に変換し、CanvasView のプレビューに表示する。

## 対象ファイル

- 変更: `ScreenShotMaker/Views/CanvasView.swift` (L121-141: `screenshotPlaceholder` メソッド)

## 実装詳細

1. **screenshotPlaceholder の画像表示対応** (L125-129)
   - `screen.screenshotImageData` が存在する場合:
     - `NSImage(data:)` で `NSImage` を生成
     - `Image(nsImage:)` で SwiftUI の Image に変換
     - `.resizable()` + `.scaledToFit()` で領域にフィットさせる
   - データが `nil` または変換失敗の場合:
     - 現行のプレースホルダー表示を維持

2. **各レイアウトプリセットでの表示**
   - `textTop`: テキスト下部に画像
   - `textOverlay`: 背景全体に画像、テキスト重畳
   - `textBottom`: 画像上部、テキスト下部
   - `textOnly`: 画像なし（プレースホルダー非表示）
   - `screenshotOnly`: 画像のみ

3. **ズーム対応**
   - 画像が `zoomScale` に連動してリサイズされること

## 受け入れ基準

- [ ] `screenshotImageData` がある Screen を選択すると、キャンバスに画像が表示される
- [ ] 画像はプレビュー領域にアスペクト比を維持してフィットする
- [ ] 5 つのレイアウトプリセット全てで画像が正しく配置される
- [ ] ズーム操作で画像サイズも連動する
- [ ] 画像データが `nil` の場合はプレースホルダーが表示される
- [ ] 破損した画像データの場合もクラッシュしない

## 依存関係

- #001 が完了していること（画像データの読み込み手段が必要）

## 複雑度

M
