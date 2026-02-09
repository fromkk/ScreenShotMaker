# Issue #044: NSAlert の SwiftUI .alert() / .confirmationDialog() 統一

## Status
Open

## Phase / Priority
Phase 8 (iPad対応) | P1 (High)

## 概要

`NSAlert` を使用している3箇所を全て SwiftUI 標準の `.alert()` / `.confirmationDialog()` に置換する。macOS / iOS 両プラットフォームで共通のコードになる。

## 現状の問題

`ScreenShotMakerApp.swift` で `NSAlert` が3箇所使用されている:

### 1. 未保存確認ダイアログ（openProject 内）
```swift
let alert = NSAlert()
alert.messageText = "Do you want to save the current project?"
alert.informativeText = "Your changes will be lost if you don't save them."
alert.alertStyle = .warning
alert.addButton(withTitle: "Save")
alert.addButton(withTitle: "Don't Save")
alert.addButton(withTitle: "Cancel")
let response = alert.runModal()
```
- 3つのボタン: Save / Don't Save / Cancel
- `runModal()` で同期的にブロック → 戻り値で分岐

### 2. プロジェクト読み込みエラー（loadProject 内）
```swift
let alert = NSAlert()
alert.messageText = "Failed to Open Project"
alert.informativeText = error.localizedDescription
alert.alertStyle = .critical
alert.runModal()
```
- OK ボタンのみのエラー表示

### 3. プロジェクト保存エラー（presentSaveError）
```swift
let alert = NSAlert()
alert.messageText = "Failed to Save Project"
alert.informativeText = error.localizedDescription
alert.alertStyle = .critical
alert.runModal()
```
- OK ボタンのみのエラー表示

## 対象ファイル

- 変更: `ScreenShotMaker/App/ScreenShotMakerApp.swift`

## 実装詳細

### 1. State 変数の追加

```swift
// 未保存確認ダイアログ
@State private var showUnsavedChangesDialog = false
@State private var pendingAction: (() -> Void)? = nil

// エラーアラート
@State private var showError = false
@State private var errorTitle = ""
@State private var errorMessage = ""
```

### 2. 未保存確認ダイアログ → .confirmationDialog()

**Before:**
```swift
func openProject() {
    if projectState.hasUnsavedChanges {
        let alert = NSAlert()
        // ... 3-button alert ...
        let response = alert.runModal()
        switch response {
        case .alertFirstButtonReturn:  // Save
            saveProject()
        case .alertSecondButtonReturn: // Don't Save
            break
        default: return  // Cancel
        }
    }
    // proceed to open
}
```

**After:**
```swift
func openProject() {
    if projectState.hasUnsavedChanges {
        pendingAction = { actuallyOpenProject() }
        showUnsavedChangesDialog = true
    } else {
        actuallyOpenProject()
    }
}

// View に追加
.confirmationDialog(
    "Do you want to save the current project?",
    isPresented: $showUnsavedChangesDialog,
    titleVisibility: .visible
) {
    Button("Save") {
        saveProject()
        pendingAction?()
        pendingAction = nil
    }
    Button("Don't Save", role: .destructive) {
        pendingAction?()
        pendingAction = nil
    }
    Button("Cancel", role: .cancel) {
        pendingAction = nil
    }
} message: {
    Text("Your changes will be lost if you don't save them.")
}
```

### 3. エラーアラート → .alert()

**Before:**
```swift
func presentSaveError(_ error: Error) {
    let alert = NSAlert()
    alert.messageText = "Failed to Save Project"
    alert.informativeText = error.localizedDescription
    alert.alertStyle = .critical
    alert.runModal()
}
```

**After:**
```swift
func presentError(title: String, message: String) {
    errorTitle = title
    errorMessage = message
    showError = true
}

// View に追加
.alert(errorTitle, isPresented: $showError) {
    Button("OK", role: .cancel) {}
} message: {
    Text(errorMessage)
}
```

### 4. 非同期フロー対応

`NSAlert.runModal()` は同期的にブロックするが、SwiftUI の `.alert()` / `.confirmationDialog()` は非同期（State ベース）。フロー変更:

- **Before**: `openProject()` → NSAlert → ユーザー応答 → NSOpenPanel → 完了（全て同期）
- **After**: `openProject()` → `showUnsavedChangesDialog = true` → ユーザー応答（コールバック） → `showOpenProject = true` → ファイル選択（コールバック） → 完了

`pendingAction` クロージャパターンで、確認後のアクションを遅延実行する。

## 受け入れ基準

- [ ] `NSAlert` の使用が全て除去されている
- [ ] 未保存確認: プロジェクトが未保存状態で「開く」実行時に確認ダイアログが表示される
- [ ] 未保存確認: 「Save」選択時にプロジェクトが保存された後、次のアクションが実行される
- [ ] 未保存確認: 「Don't Save」選択時に保存せず次のアクションが実行される
- [ ] 未保存確認: 「Cancel」選択時にアクションがキャンセルされる
- [ ] エラー表示: プロジェクト読み込み失敗時にエラーアラートが表示される
- [ ] エラー表示: プロジェクト保存失敗時にエラーアラートが表示される
- [ ] macOS で全てのアラートが正常に表示される
- [ ] iPad Simulator で全てのアラートが正常に表示される

## 依存関係

- #041 が完了していること

## 備考

- `.confirmationDialog()` は iPad ではアクションシート形式で表示される。macOS ではアラート形式。プラットフォームに応じた自然な見た目になる。
- `NSAlert.runModal()` からの移行により、処理フローが同期から非同期に変わる。`pendingAction` パターンでこれを吸収する。

## 複雑度

M
