# Issue #037: 翻訳の強制キャンセル

## Phase / Priority
Phase 7 | P1 (High)

## 概要

翻訳処理が停止しない場合に、ユーザーが強制的にキャンセルできる手段を提供する。現在、`isTranslating` が `true` のまま翻訳が完了しない場合、ProgressView が表示され続け、Translate ボタンが無効化されたまま操作不能になる。

## 現状の問題

1. `.translationTask()` が応答しない場合やネットワークの問題で翻訳が完了しない場合、ProgressView が永遠に表示される
2. `isTranslating` が `true` のまま Translate ボタンが `disabled` になり、再試行もできない
3. ユーザーが翻訳を中断する手段がない

## 対象ファイル

- 変更: `ScreenShotMaker/Views/PropertiesPanelView.swift` (キャンセルボタン追加)

## 実装詳細

1. **ProgressView をキャンセルボタンに変更**
   - 翻訳中に ProgressView が表示されている箇所をタップ可能にし、タップで翻訳をキャンセル
   - または ProgressView の横にキャンセルボタン（×アイコン）を追加

   ```swift
   if isTranslating {
       Button {
           cancelTranslation()
       } label: {
           HStack(spacing: 4) {
               ProgressView()
                   .controlSize(.small)
               Image(systemName: "xmark.circle.fill")
                   .font(.system(size: 10))
           }
       }
       .buttonStyle(.plain)
       .foregroundStyle(.secondary)
   }
   ```

2. **キャンセル処理**
   ```swift
   private func cancelTranslation() {
       isTranslating = false
       translationConfig = nil
       translationTargetCode = nil
   }
   ```

## 受け入れ基準

- [ ] 翻訳中にキャンセルボタンが表示される
- [ ] キャンセルボタンをクリックすると ProgressView が消えて Translate ボタンに戻る
- [ ] キャンセル後に再度翻訳を実行できる

## 依存関係

- #035（翻訳 ProgressView スタック修正）

## 複雑度

S
