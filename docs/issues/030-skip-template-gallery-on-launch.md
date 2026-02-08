# Issue #030: テンプレート選択画面の「次回から表示しない」オプション

## Phase / Priority
Phase 6 | P2 (Medium)

## 概要

アプリ起動時に毎回テンプレート選択画面（`TemplateGalleryView`）が表示される。頻繁に使うユーザーにとっては毎回閉じる必要があり煩わしい。「次回から表示しない」チェックボックスを追加し、ユーザーの選択を `UserDefaults`（`@AppStorage`）に保存することで、以降の起動時にスキップできるようにする。

## 現状の問題

1. `ScreenShotMakerApp.onAppear` で `showTemplateGallery = true` が毎回実行される
2. テンプレートを使わないユーザーも毎回ダイアログを閉じる必要がある
3. ユーザーの好みを記憶する仕組みがない

## 対象ファイル

- 変更: `ScreenShotMaker/App/ScreenShotMakerApp.swift` (`onAppear` のロジック変更)
- 変更: `ScreenShotMaker/Views/TemplateGalleryView.swift` (チェックボックス追加)

## 実装詳細

1. **`@AppStorage` でユーザー設定を保存**
   - キー: `"showTemplateOnLaunch"`、デフォルト値: `true`
   - `ScreenShotMakerApp` に `@AppStorage("showTemplateOnLaunch") private var showTemplateOnLaunch = true` を追加

2. **`onAppear` の条件分岐**
   ```swift
   .onAppear {
       if showTemplateOnLaunch {
           showTemplateGallery = true
       }
   }
   ```

3. **TemplateGalleryView にチェックボックス追加**
   - `@AppStorage("showTemplateOnLaunch")` を TemplateGalleryView にも追加
   - フッター部分に `Toggle("Don't show on launch", ...)` を配置
   - チェックを入れると `showTemplateOnLaunch = false` に設定

4. **メニューからの再表示**
   - 既存の「New from Template...」(⇧⌘N) メニューは引き続き動作し、設定に関係なくテンプレート画面を表示できる

## 受け入れ基準

- [ ] テンプレート画面にチェックボックス（「Don't show on launch」）が表示される
- [ ] チェックを入れると次回起動時にテンプレート画面が表示されない
- [ ] チェックを外すと次回起動時にテンプレート画面が再び表示される
- [ ] 「New from Template...」メニューからは設定に関係なくテンプレート画面を開ける
- [ ] 設定はアプリ終了後も永続化される（`UserDefaults`）

## 依存関係

なし

## 複雑度

S
