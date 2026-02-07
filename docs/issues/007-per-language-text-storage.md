# Issue #007: 言語別テキスト管理

## Phase / Priority
Phase 2 | P1 (High)

## 概要

Screen の `title` / `subtitle` を言語コードをキーとした辞書に拡張し、言語ごとに異なるテキストを管理できるようにする。

## 対象ファイル

- 変更: `ScreenShotMaker/Models/Screen.swift` (title/subtitle の型変更)
- 変更: `ScreenShotMaker/Models/Project.swift` (ProjectState にヘルパー追加)
- 変更: `ScreenShotMaker/Views/PropertiesPanelView.swift` (テキストフィールドのバインディング)
- 変更: `ScreenShotMaker/Views/CanvasView.swift` (テキスト表示ロジック)

## 実装詳細

1. **LocalizedText 構造体の追加** (Screen.swift)
   ```swift
   struct LocalizedText: Codable, Hashable {
       var title: String
       var subtitle: String
   }
   ```

2. **Screen モデルの変更** (Screen.swift)
   - `title: String` → `localizedTexts: [String: LocalizedText]` (キー: 言語コード)
   - 後方互換のため `title` / `subtitle` computed property を残す（デフォルト言語 "en" を参照）
   - `func text(for languageCode: String) -> LocalizedText` ヘルパー追加

3. **ProjectState のヘルパー** (Project.swift)
   - `var currentLocalizedText: LocalizedText?` — 選択中の言語に対応するテキスト
   - テキスト更新メソッド

4. **PropertiesPanelView の対応** (PropertiesPanelView.swift)
   - テキストフィールドが選択中の言語のテキストを編集
   - 「全言語にコピー」ボタンを追加
   - 現在編集中の言語ラベルを表示

5. **CanvasView の対応** (CanvasView.swift)
   - `textContent` メソッドが `state.selectedLanguage` に対応するテキストを表示

6. **マイグレーション**
   - 旧形式（`title`/`subtitle` が直接 String）のプロジェクトを読み込めるよう `init(from decoder:)` をカスタム実装

## 受け入れ基準

- [ ] 言語を切り替えるとキャンバスのテキストが変わる
- [ ] PropertiesPanelView で編集したテキストは現在の言語にのみ反映される
- [ ] 「全言語にコピー」ボタンで現在のテキストを全言語に展開できる
- [ ] 未翻訳の言語はデフォルトテキスト（空文字列）が表示される
- [ ] 旧形式のプロジェクトファイルを開いてもクラッシュしない
- [ ] プロジェクト保存時に全言語のテキストが保持される

## 依存関係

なし

## 複雑度

M
