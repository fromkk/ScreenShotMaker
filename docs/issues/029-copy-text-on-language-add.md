# Issue #029: 言語追加時に既存言語のテキストをコピー

## Phase / Priority
Phase 6 | P2 (Medium)

## 概要

言語を新しく追加した際、現在は空のテキスト（`LocalizedText()` — title/subtitle ともに空文字）が設定される。ユーザーが手動で既存言語の内容をコピーする必要があり不便。言語追加時に現在選択中の言語のテキストを自動的にコピーするか、コピー元を選択できるようにする。

## 現状の問題

1. `LanguageManagerButton.toggleLanguage` で言語を追加すると `languages` 配列に追加されるだけ
2. 各 Screen の `localizedTexts` に新言語のエントリがないため、空の `LocalizedText()` が返る
3. ユーザーは手動で「Copy to All」ボタンを押すか、各スクリーンで個別にテキストを入力する必要がある
4. スクリーンが複数ある場合、全スクリーンに対して手動コピーが必要で非常に手間

## 対象ファイル

- 変更: `ScreenShotMaker/Views/ContentView.swift` (`LanguageManagerButton` のロジック)
- 変更: `ScreenShotMaker/Models/Screen.swift` (コピーヘルパー追加の可能性)

## 実装詳細

1. **言語追加時の自動コピー**
   - `LanguageManagerButton.toggleLanguage` で言語を追加する際、全スクリーンに対して現在選択中の言語のテキストをコピー
   - `state.selectedLanguage?.code` をコピー元として使用
   - 各 Screen の `localizedTexts[newLanguageCode]` に `localizedTexts[sourceCode]` の値を設定

2. **実装例**
   ```swift
   // LanguageManagerButton.toggleLanguage 内
   } else {
       state.project.languages.append(language)
       // 現在の言語のテキストを新言語にコピー
       let sourceCode = state.selectedLanguage?.code ?? "en"
       for i in state.project.screens.indices {
           let sourceText = state.project.screens[i].text(for: sourceCode)
           state.project.screens[i].setText(sourceText, for: language.code)
       }
   }
   ```

3. **Undo 対応**
   - 言語追加 + テキストコピーを1つの Undo アクションとしてグルーピング

## 受け入れ基準

- [ ] 言語を追加すると、現在選択中の言語のテキストが全スクリーンに自動コピーされる
- [ ] コピー後、新言語に切り替えるとコピーされたテキストが表示される
- [ ] 言語を削除しても他の言語のテキストに影響しない
- [ ] 既にテキストが存在する言語を再追加した場合の動作が適切（上書きしない or 確認）

## 依存関係

なし

## 複雑度

S
