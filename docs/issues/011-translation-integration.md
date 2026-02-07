# Issue #011: Apple Translation Framework 連携

## Phase / Priority
Phase 3 | P2 (Medium)

## 概要

Apple Translation Framework (macOS 15+) を使用して、スクリーンショットのテキスト（タイトル・サブタイトル）を自動翻訳する機能を追加する。

## 対象ファイル

- 新規: `ScreenShotMaker/Services/TranslationService.swift`
- 変更: `ScreenShotMaker/Views/PropertiesPanelView.swift` (翻訳ボタン追加)

## 実装詳細

1. **TranslationService の作成**
   ```swift
   import Translation

   struct TranslationService {
       /// テキストを翻訳
       static func translate(
           text: String,
           from sourceLanguage: Locale.Language,
           to targetLanguage: Locale.Language
       ) async throws -> String

       /// 利用可能な言語ペアを取得
       static func availableLanguagePairs() async -> [LanguagePair]
   }
   ```

2. **Translation Framework の使用**
   - `TranslationSession` を使用
   - `.translationTask()` ビューモディファイアでセッション管理
   - ソース言語: 現在選択中の言語
   - ターゲット言語: ユーザーが選択

3. **PropertiesPanelView の翻訳 UI**
   - Text セクションヘッダーに「Translate」ボタン追加
   - クリックで翻訳先言語を選択するポップオーバー表示
   - 翻訳実行中はプログレスインジケーター表示
   - 翻訳結果をターゲット言語のテキストに自動入力

4. **エラーハンドリング**
   - ネットワーク不可: オフラインモデルが利用可能か確認
   - 未対応言語ペア: 利用不可を明示
   - 翻訳失敗: エラーアラート表示

## 受け入れ基準

- [ ] 「Translate」ボタンが PropertiesPanelView の Text セクションに表示される
- [ ] 翻訳先言語を選択できる
- [ ] タイトル・サブタイトルが選択言語に翻訳される
- [ ] 翻訳結果が対象言語のテキストフィールドに自動入力される
- [ ] 翻訳中はプログレスインジケーターが表示される
- [ ] オフラインまたは翻訳不可の場合にエラーが表示される

## 依存関係

- #007 が完了していること（言語別テキスト管理が前提）

## 複雑度

M
