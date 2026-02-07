# Issue #006: プロジェクトファイル読み込み

## Phase / Priority
Phase 1 | P1 (High)

## 概要

`.ssmaker` ファイルを読み込み、プロジェクトを復元する。Cmd+O で開くダイアログを表示し、Open Recent メニューに対応する。

## 対象ファイル

- 変更: `ScreenShotMaker/Services/ProjectFileService.swift` (`load` メソッドは #005 で定義済み)
- 変更: `ScreenShotMaker/Views/ContentView.swift` (Open メニュー追加)
- 変更: `ScreenShotMaker/App/ScreenShotMakerApp.swift` (ファイル関連付け)

## 実装詳細

1. **Open メニューコマンド** (ContentView.swift)
   - Open (Cmd+O): `NSOpenPanel` で `.ssmaker` ファイルを選択
   - `ProjectFileService.load()` でデシリアライズ
   - `projectState.project` に代入、`selectedScreenID` をリセット

2. **エラーハンドリング**
   - 破損ファイル: `DecodingError` をキャッチしてアラート表示
   - ファイル不存在: 適切なエラーメッセージ
   - バージョン不整合: 将来のフォーマット変更に備えて version フィールド追加を検討

3. **NSOpenPanel の設定**
   - `allowedContentTypes: [UTType(filenameExtension: "ssmaker")!]`
   - `allowsMultipleSelection: false`

4. **Open Recent 対応** (ScreenShotMakerApp.swift)
   - `NSDocumentController.shared.noteNewRecentDocumentURL()` で履歴追加
   - Info.plist に `.ssmaker` ファイルタイプを登録（`project.yml` の `INFOPLIST_KEY_` で設定）

5. **未保存変更の確認**
   - 新しいファイルを開く前に、現在のプロジェクトに未保存の変更がある場合確認ダイアログを表示

## 受け入れ基準

- [ ] Cmd+O でファイル選択ダイアログが表示される
- [ ] `.ssmaker` ファイルのみ選択可能
- [ ] 正常なファイルを開くと全スクリーン・設定が復元される
- [ ] 破損ファイルを開くとエラーメッセージが表示される
- [ ] 開いたファイルが Open Recent に追加される
- [ ] 未保存の変更がある場合、ファイルを開く前に確認される

## 依存関係

- #005 が完了していること（ProjectFileService と保存形式が確定している必要あり）

## 複雑度

M
