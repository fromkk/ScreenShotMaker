# Issue #005: プロジェクトファイル保存

## Phase / Priority
Phase 1 | P1 (High)

## 概要

プロジェクトの全データを `.ssmaker` ファイル（JSON）として保存する。Cmd+S / Save As に対応。

## 対象ファイル

- 新規: `ScreenShotMaker/Services/ProjectFileService.swift`
- 変更: `ScreenShotMaker/Views/ContentView.swift` (メニューコマンド追加)
- 変更: `ScreenShotMaker/Models/Project.swift` (`ProjectState` にファイルパス追加)

## 実装詳細

1. **ProjectFileService の作成**
   ```swift
   struct ProjectFileService {
       static func save(_ project: ScreenShotProject, to url: URL) throws
       static func load(from url: URL) throws -> ScreenShotProject
   }
   ```
   - `JSONEncoder` で `ScreenShotProject` をシリアライズ
   - `.outputFormatting = [.prettyPrinted, .sortedKeys]` でデバッグしやすく
   - ファイル拡張子: `.ssmaker`

2. **ProjectState の拡張** (Project.swift)
   - `var currentFileURL: URL?` を追加
   - `var hasUnsavedChanges: Bool` を追加

3. **メニューコマンドの追加** (ContentView.swift)
   - `.commands { ... }` で File メニュー拡張
   - Save (Cmd+S): `currentFileURL` があればそこに保存、なければ Save As
   - Save As (Cmd+Shift+S): `NSSavePanel` で場所選択

4. **NSSavePanel の設定**
   - `allowedContentTypes: [UTType.init(filenameExtension: "ssmaker")!]`
   - デフォルトファイル名: `project.name + ".ssmaker"`

## 受け入れ基準

- [ ] Cmd+S で保存ダイアログが表示される（初回のみ）
- [ ] 2回目以降の Cmd+S は同じファイルに上書き保存される
- [ ] Cmd+Shift+S で毎回保存先を選択できる
- [ ] `.ssmaker` 拡張子でファイルが保存される
- [ ] 保存ファイルに全スクリーン、背景設定、画像データが含まれる
- [ ] JSON として正しくデコード可能なファイルが生成される

## 依存関係

なし

## 複雑度

M
