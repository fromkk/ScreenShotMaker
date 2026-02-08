# Issue #035: 翻訳を複数回実行すると ProgressView が出続けて翻訳されない

## Phase / Priority
Phase 7 | P1 (High)

## 概要

翻訳ボタンを使って翻訳を数回実行すると、ProgressView（スピナー）が表示されたまま翻訳が完了しなくなる。2回目以降の翻訳リクエストが `.translationTask()` によって処理されず、`isTranslating` が `true` のままスタックする。

## 現状の問題

### 根本原因: `.translationTask()` の再トリガー条件

`PropertiesPanelView.swift:46-48` で `.translationTask(translationConfig)` を使用しているが、SwiftUI の `.translationTask()` modifier は `TranslationSession.Configuration` の**値の変化**を検知してタスクを起動する。

現在のフロー:
1. 初回翻訳: `translationConfig` が `nil` → `Configuration(en→ja)` に変化 → タスク起動 → 翻訳成功 → `translationConfig = nil` にリセット
2. 2回目（同じ言語ペア）: `translationConfig` が `nil` → `Configuration(en→ja)` に変化 → **タスクが起動しない場合がある**

`TranslationSession.Configuration` は同じ source/target 言語ペアで生成すると同値とみなされる可能性があり、SwiftUI が「前回と同じ値」と判定してタスクを再トリガーしないことがある。この場合 `isTranslating = true` のまま解除されず、ProgressView が表示され続ける。

### 副次的な問題

1. `@State private var translationScreen: Binding<Screen>?` — `Binding` を `@State` に保存するのはアンチパターン。Binding は一時的な参照であり、保存先の View 再構築で無効化される可能性がある
2. `performTranslation` 完了後に `translationConfig = nil` を設定すると `.translationTask()` が nil 値で再度トリガーされうるが、`translationScreen` がまだ設定されているため予期しない動作になる可能性がある
3. `requests` が空（title と subtitle が両方空）の場合、`session.translations(from: [])` の動作が未定義

## 対象ファイル

- 変更: `ScreenShotMaker/Views/PropertiesPanelView.swift` (翻訳ロジックの修正)

## 実装詳細

### 方法 A: `translationTask` に ID を付与して強制再トリガー

```swift
@State private var translationID = UUID()

// body 内:
.translationTask(translationConfig, id: translationID) { session in
    await performTranslation(session: session)
}

// startTranslation 内:
private func startTranslation(screen: Binding<Screen>, targetLanguageCode: String) {
    translationScreen = screen
    isTranslating = true
    translationID = UUID()  // ID を更新して強制的に再トリガー
    translationConfig = TranslationService.configuration(
        from: currentLanguageCode,
        to: targetLanguageCode
    )
}
```

### 方法 B: `.translationTask` を毎回新しい Configuration で再構築（推奨）

`translationConfig` を nil にリセットした後、次のリクエスト前にワンフレーム遅延を入れて SwiftUI の差分検知を確実にする:

```swift
private func startTranslation(screen: Binding<Screen>, targetLanguageCode: String) {
    translationScreen = screen
    isTranslating = true
    // 前回の config をクリアしてから新しい config をセット
    translationConfig = nil
    Task { @MainActor in
        translationConfig = TranslationService.configuration(
            from: currentLanguageCode,
            to: targetLanguageCode
        )
    }
}
```

### 方法 C: Binding 保存の廃止 + タイムアウト追加

```swift
// Binding の保存を廃止し、targetLanguageCode を保存
@State private var translationTargetCode: String?

private func startTranslation(targetLanguageCode: String) {
    translationTargetCode = targetLanguageCode
    isTranslating = true
    translationConfig = TranslationService.configuration(
        from: currentLanguageCode,
        to: targetLanguageCode
    )
}

private func performTranslation(session: TranslationSession) async {
    guard let targetCode = translationTargetCode,
          let screen = selectedScreenBinding else {
        isTranslating = false
        return
    }
    // ... 翻訳処理 ...

    isTranslating = false
    translationConfig = nil
    translationTargetCode = nil
}
```

### 共通の改善

- `requests` が空の場合は早期リターンして `isTranslating = false` にリセット
- タイムアウト（例: 30秒）を設けて、翻訳が完了しない場合はエラーを表示して `isTranslating` をリセット

## 受け入れ基準

- [x] 同じ言語ペアで連続して翻訳しても ProgressView がスタックしない
- [x] 異なる言語ペアで連続して翻訳しても正常に動作する
- [x] 翻訳が完了すると ProgressView が消えて Translate ボタンに戻る
- [x] 翻訳エラー時も ProgressView が消えてエラーアラートが表示される
- [x] title/subtitle が両方空の場合は翻訳をスキップする
- [x] 翻訳結果が正しい言語コードに保存される

## 依存関係

なし

## 複雑度

S

## 実装完了

**実装日**: 2026-02-08

### 採用した方法

方法Aの変形版: translationIDを導入し、`.id(translationID)` modifierを使用して`.translationTask()`を持つViewを強制的に再作成することで、連続する翻訳リクエストを確実にトリガーする。

### 実装内容

1. `@State private var translationID = UUID()` を追加
2. `.translationTask()` の後に `.id(translationID)` を追加して View の ID を変更
3. `startTranslation()` で `translationID = UUID()` を設定して強制的に再トリガー

### 変更ファイル

- [PropertiesPanelView.swift](ScreenShotMaker/Views/PropertiesPanelView.swift)

この実装により、translationIDを更新することでViewのidentityが変わり、`.translationTask()`が再評価されるため、同じ言語ペアでも連続して翻訳が実行できるようになった。
