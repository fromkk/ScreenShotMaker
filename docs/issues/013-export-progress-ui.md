# Issue #013: エクスポート進捗 UI

## Phase / Priority
Phase 4 | P2 (Medium)

## 概要

一括エクスポート実行中にプログレスバー、現在の処理状況、キャンセルボタンを備えた進捗ウィンドウを表示する。

## 対象ファイル

- 新規: `ScreenShotMaker/Views/ExportProgressView.swift`
- 変更: `ScreenShotMaker/Services/ExportService.swift` (進捗コールバック連携)

## 実装詳細

1. **ExportProgressView の作成**
   - モーダルシートとして表示
   - `ProgressView` で進捗バー表示（`completed / total`）
   - 現在処理中のスクリーン名・デバイス名・言語を表示
   - 完了済みアイテムのリスト（チェックマーク付き）
   - 「Cancel」ボタンで処理を中断

2. **進捗状態の管理**
   ```swift
   @Observable
   class ExportProgressState {
       var isExporting: Bool = false
       var completed: Int = 0
       var total: Int = 0
       var currentItem: String = ""
       var errors: [String] = []
       var isCancelled: Bool = false
   }
   ```

3. **完了時の動作**
   - 成功: サマリー表示（成功数、所要時間）
   - エラーあり: エラーリスト表示
   - 「Open Folder」ボタンで出力先を Finder で開く

## 受け入れ基準

- [ ] 一括エクスポート開始時に進捗ウィンドウが表示される
- [ ] プログレスバーがリアルタイムで更新される
- [ ] 現在処理中のアイテム情報が表示される
- [ ] 「Cancel」ボタンで残りのエクスポートが中止される
- [ ] 完了時にサマリーが表示される
- [ ] 「Open Folder」で出力先が Finder で開かれる

## 依存関係

- #012 が完了していること

## 複雑度

M
