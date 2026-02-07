# Issue #012: 一括エクスポート

## Phase / Priority
Phase 4 | P1 (High)

## 概要

全スクリーン × 全デバイスサイズ × 全言語の組み合わせを一括でエクスポートする。出力はフォルダ構造で整理する。

## 対象ファイル

- 変更: `ScreenShotMaker/Services/ExportService.swift` (バッチエクスポート追加)
- 変更: `ScreenShotMaker/Views/ContentView.swift` (Export メニュー拡張)

## 実装詳細

1. **ExportService の拡張**
   ```swift
   static func batchExport(
       project: ScreenShotProject,
       devices: [DeviceSize],
       languages: [Language],
       format: ExportFormat,
       outputDirectory: URL,
       progress: @escaping (BatchExportProgress) -> Void
   ) async throws

   struct BatchExportProgress {
       let completed: Int
       let total: Int
       let currentScreen: String
       let currentDevice: String
       let currentLanguage: String
   }
   ```

2. **出力フォルダ構造**
   ```
   output/
     en/
       iPhone 6.9/
         Screen-1.png
         Screen-2.png
       iPad 13/
         Screen-1.png
     ja/
       iPhone 6.9/
         Screen-1.png
   ```

3. **Export メニューの拡張** (ContentView.swift)
   - 「Export Current...」: 現在のスクリーン（既存の #004）
   - 「Export All...」: 一括エクスポート
   - 一括エクスポートダイアログ: デバイス・言語・形式・出力先を選択

4. **非同期処理**
   - `async/await` で各組み合わせを順次エクスポート
   - `Task.isCancelled` でキャンセル対応

## 受け入れ基準

- [ ] 「Export All...」でエクスポート設定ダイアログが表示される
- [ ] デバイスと言語を選択できる
- [ ] 全組み合わせがフォルダ構造で正しく出力される
- [ ] 各ファイルのピクセルサイズがデバイスの仕様と一致する
- [ ] エクスポート中にキャンセルできる
- [ ] 完了時にサマリーが表示される

## 依存関係

- #004 が完了していること（単一エクスポートのロジックを再利用）
- #007 が完了していること（言語別テキストが必要）

## 複雑度

L
