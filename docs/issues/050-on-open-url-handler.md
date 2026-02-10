# Issue #050: onOpenURL ハンドラの追加

## Status
Open

## Phase / Priority
Phase 8 (iPad対応) | P1 (High)

## 概要

`.shotcraft` ファイルを Files アプリ・Share Sheet・AirDrop から直接開けるように `onOpenURL` ハンドラを追加する。

## 現状

- `onOpenURL` ハンドラが存在しない
- `.shotcraft` ファイルをタップしてもアプリ内でプロジェクトが開かれない
- `CFBundleDocumentTypes` で関連付けが宣言されていない（#049 で対応）

## 対象ファイル

- 変更: `ScreenShotMaker/App/ScreenShotMakerApp.swift`

## 実装詳細

### 1. onOpenURL ハンドラの追加

`ScreenShotMakerApp.swift` の `WindowGroup` に追加:

```swift
.onOpenURL { url in
    handleOpenURL(url)
}
```

### 2. handleOpenURL の実装

```swift
private func handleOpenURL(_ url: URL) {
    // 未保存変更がある場合は確認ダイアログを表示
    if projectState.hasUnsavedChanges {
        pendingOpenURL = url
        showOpenURLConfirmation = true
        return
    }
    loadProjectFromURL(url)
}

private func loadProjectFromURL(_ url: URL) {
    let accessing = url.startAccessingSecurityScopedResource()
    defer { if accessing { url.stopAccessingSecurityScopedResource() } }

    do {
        let project = try ProjectFileService.loadPackage(from: url)
        projectState.project = project
        projectState.selectedScreenID = project.screens.first?.id
        projectState.selectedDeviceIndex = 0
        projectState.selectedLanguageIndex = 0
        projectState.currentFileURL = url
        projectState.hasUnsavedChanges = false
    } catch {
        // エラーハンドリング（アラート表示）
    }
}
```

### 3. 未保存変更の確認ダイアログ

既存の `confirmationDialog` パターンを再利用:

```swift
@State private var pendingOpenURL: URL?
@State private var showOpenURLConfirmation = false

.confirmationDialog("未保存の変更があります", isPresented: $showOpenURLConfirmation) {
    Button("保存して開く") {
        saveProject()
        if let url = pendingOpenURL { loadProjectFromURL(url) }
        pendingOpenURL = nil
    }
    Button("保存せずに開く", role: .destructive) {
        if let url = pendingOpenURL { loadProjectFromURL(url) }
        pendingOpenURL = nil
    }
    Button("キャンセル", role: .cancel) {
        pendingOpenURL = nil
    }
}
```

## 受け入れ基準

- [ ] Files アプリで `.shotcraft` ファイルをタップすると Shotcraft が起動しプロジェクトが開かれる
- [ ] Share Sheet の「Shotcraft で開く」からプロジェクトが開かれる
- [ ] AirDrop で `.shotcraft` ファイルを受信するとプロジェクトが開かれる
- [ ] 未保存変更がある場合に確認ダイアログが表示される
- [ ] 読み込みエラー時にアラートが表示される

## 依存関係

- #048 (.shotcraft パッケージ形式)
- #049 (UTType 正式登録)

## 複雑度

M
