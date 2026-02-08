# Issue #020: 言語選択肢の複数選択対応

## Phase / Priority
Phase 5 | P0 (Critical)

## 概要

言語選択が English 1つに固定されており、複数言語を追加・切替できない。`Language.supportedLanguages` に15言語が定義済みだが、プロジェクト初期化時に1言語のみ設定され、UI でも `state.project.languages` (1件) しか表示されない。複数言語を追加・削除できる UI を実装し、言語別テキスト管理機能 (#007) を実用的にする。

## 現状の問題

1. `ScreenShotProject` の初期値が `languages: [Language(code: "en", displayName: "English")]` で1言語のみ
2. ContentView の LanguagePicker が `state.project.languages` のみ列挙するため選択肢が1つ
3. `Language.supportedLanguages` に15言語が定義されているが UI に露出していない

## 対象ファイル

- 変更: `ScreenShotMaker/Views/ContentView.swift` (言語管理 UI)
- 変更: `ScreenShotMaker/Models/Project.swift` (言語追加・削除メソッド)

## 実装詳細

1. **言語管理 UI の追加**
   - ツールバーに「言語管理」ボタンを追加
   - ポップオーバーまたはシートで `Language.supportedLanguages` をチェックボックス表示
   - 選択済み言語にチェックマーク、未選択言語を追加可能

2. **ProjectState への言語管理メソッド追加**
   - `addLanguage(_ language: Language)` — プロジェクトに言語追加
   - `removeLanguage(_ language: Language)` — プロジェクトから言語削除（最低1言語は維持）
   - UndoManager 対応

3. **LanguagePicker の改善**
   - `state.project.languages` に追加された全言語が切替可能
   - 選択中の言語がハイライト表示

## 受け入れ基準

- [ ] UI から `Language.supportedLanguages` の15言語を追加・削除できる
- [ ] 最低1言語は維持される（全削除不可）
- [ ] 追加した言語がツールバーの Language Picker に即座に反映される
- [ ] 言語追加・削除が Undo/Redo に対応
- [ ] プロジェクト保存・読込で言語設定が維持される

## 依存関係

なし

## 複雑度

S
