# Issue #032: スクリーンのコピー・ペースト

## Phase / Priority
Phase 7 | P2 (Medium)

## 概要

サイドバーのスクリーン一覧でスクリーンのコピー・ペーストができるようにする。コンテキストメニューまたはキーボードショートカット（⌘C / ⌘V）でスクリーンを複製できるようにすることで、類似スクリーンの作成を効率化する。

## 現状の問題

1. スクリーンのコンテキストメニューには「Delete」しかない
2. 既存のスクリーンをベースに新しいスクリーンを作成するには、手動で全プロパティを再設定する必要がある
3. ⌘C / ⌘V によるスクリーン複製ができない

## 対象ファイル

- 変更: `ScreenShotMaker/Models/Project.swift` (`duplicateScreen` / `copyScreen` / `pasteScreen` メソッド追加)
- 変更: `ScreenShotMaker/Views/SidebarView.swift` (コンテキストメニューに「Duplicate」「Copy」「Paste」追加)
- 変更: `ScreenShotMaker/App/ScreenShotMakerApp.swift` (⌘C / ⌘V のキーボードショートカット追加の可能性)

## 実装詳細

1. **ProjectState にメソッド追加**
   - `duplicateScreen(_ screen: Screen)` — 選択中のスクリーンを複製して直後に挿入
     - 新しい UUID を割り当て、名前に " Copy" を付加
     - 全プロパティ（localizedTexts、background、screenshotImageData、deviceFrameConfig 等）をコピー
   - `copiedScreen: Screen?` — クリップボード用プロパティ
   - `copyScreen(_ screen: Screen)` — スクリーンをコピーバッファに保存
   - `pasteScreen()` — コピーバッファからスクリーンを貼り付け

2. **SidebarView のコンテキストメニュー拡張**
   ```swift
   .contextMenu {
       Button("Duplicate") {
           state.duplicateScreen(screen)
       }
       Divider()
       Button("Copy") {
           state.copyScreen(screen)
       }
       Button("Paste") {
           state.pasteScreen()
       }
       .disabled(state.copiedScreen == nil)
       Divider()
       Button("Delete", role: .destructive) {
           state.deleteScreen(screen)
       }
   }
   ```

3. **Undo 対応**
   - Duplicate / Paste を1つの Undo アクションとして登録

## 受け入れ基準

- [ ] コンテキストメニューから「Duplicate」でスクリーンを複製できる
- [ ] 複製されたスクリーンは元スクリーンの全プロパティをコピーし、新しい UUID と名前を持つ
- [ ] コンテキストメニューから「Copy」→「Paste」でスクリーンをコピー・ペーストできる
- [ ] Paste で貼り付けたスクリーンは新しい UUID を持つ
- [ ] Undo/Redo が正しく動作する
- [ ] コピーバッファが空の場合、Paste は無効（disabled）になる

## 依存関係

なし

## 複雑度

S
