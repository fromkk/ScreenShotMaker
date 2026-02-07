# Issue #016: Undo/Redo

## Phase / Priority
Phase 4 | P3 (Low)

## 概要

macOS 標準の Undo/Redo（Cmd+Z / Cmd+Shift+Z）をサポートし、プロパティの変更やスクリーンの追加/削除を取り消し・やり直しできるようにする。

## 対象ファイル

- 変更: `ScreenShotMaker/Models/Project.swift` (`ProjectState` に `UndoManager` 統合)
- 変更: `ScreenShotMaker/Views/ContentView.swift` (`undoManager` の環境値連携)

## 実装詳細

1. **ProjectState への UndoManager 統合**
   - `var undoManager: UndoManager?` プロパティ追加
   - スクリーン追加/削除時に undo 登録
   - プロパティ変更時に undo 登録

2. **undo 対象の操作**
   - スクリーン追加 (`addScreen`)
   - スクリーン削除 (`deleteScreen`)
   - スクリーン並べ替え (`moveScreen`)
   - テキスト変更（title / subtitle）
   - 背景変更
   - レイアウトプリセット変更
   - 画像インポート

3. **ContentView での連携**
   - SwiftUI の `@Environment(\.undoManager)` を `ProjectState` に渡す

## 受け入れ基準

- [ ] Cmd+Z で直前の操作が取り消される
- [ ] Cmd+Shift+Z で取り消した操作をやり直せる
- [ ] Edit メニューの Undo/Redo が有効化される
- [ ] 複数回の undo/redo が連続で機能する

## 依存関係

なし

## 複雑度

M
