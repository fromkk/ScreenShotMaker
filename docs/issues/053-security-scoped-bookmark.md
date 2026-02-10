# Issue #053: セキュリティスコープ URL のブックマーク永続化

## Status
Open

## Phase / Priority
Phase 8 (iPad対応) | P2 (Medium)

## 概要

`currentFileURL` のセキュリティスコープ付きブックマークを永続化し、アプリ再起動後に前回のプロジェクトを自動復帰できるようにする。

## 現状

- `currentFileURL` は `ProjectState` の `@State` で保持（メモリ内のみ）
- アプリ再起動後に `currentFileURL` が失われ、上書き保存（⌘S）が機能しない
- セキュリティスコープリソースの `startAccessingSecurityScopedResource()` / `stopAccessingSecurityScopedResource()` は使用しているが、ブックマークの永続化は未実装

## 対象ファイル

- 変更: `ScreenShotMaker/Models/ProjectState.swift`（または新規ヘルパー）
- 変更: `ScreenShotMaker/App/ScreenShotMakerApp.swift`

## 実装詳細

### 1. ブックマークの保存

`currentFileURL` が設定されるタイミングで `UserDefaults` にブックマークデータを保存:

```swift
func saveBookmark(for url: URL) {
    do {
        let bookmarkData = try url.bookmarkData(
            options: [],    // iOS では空（macOS では .withSecurityScope）
            includingResourceValuesForKeys: nil,
            relativeTo: nil
        )
        UserDefaults.standard.set(bookmarkData, forKey: "lastProjectBookmark")
    } catch {
        print("Failed to save bookmark: \(error)")
    }
}
```

### 2. ブックマークの復元

アプリ起動時にブックマークから URL を復元:

```swift
func restoreBookmarkedURL() -> URL? {
    guard let bookmarkData = UserDefaults.standard.data(forKey: "lastProjectBookmark") else {
        return nil
    }
    do {
        var isStale = false
        let url = try URL(
            resolvingBookmarkData: bookmarkData,
            bookmarkDataIsStale: &isStale
        )
        if isStale {
            // ブックマークを再生成
            saveBookmark(for: url)
        }
        return url
    } catch {
        print("Failed to restore bookmark: \(error)")
        return nil
    }
}
```

### 3. アプリ起動時の自動復帰

`ScreenShotMakerApp.swift` の `.onAppear` または `task` で:

```swift
.task {
    if let url = restoreBookmarkedURL() {
        let accessing = url.startAccessingSecurityScopedResource()
        defer { if accessing { url.stopAccessingSecurityScopedResource() } }
        do {
            let project = try ProjectFileService.loadPackage(from: url)
            projectState.project = project
            projectState.currentFileURL = url
            projectState.hasUnsavedChanges = false
            // テンプレートギャラリーをスキップ
        } catch {
            // ブックマーク無効化、テンプレートギャラリーを表示
            UserDefaults.standard.removeObject(forKey: "lastProjectBookmark")
        }
    }
}
```

### 4. プラットフォーム分岐

```swift
#if os(macOS)
let bookmarkOptions: URL.BookmarkCreationOptions = [.withSecurityScope]
#else
let bookmarkOptions: URL.BookmarkCreationOptions = []
#endif
```

## 受け入れ基準

- [ ] プロジェクトを開いた後にアプリを終了・再起動すると前回のプロジェクトが自動で開く
- [ ] 再起動後も上書き保存（⌘S / 保存ボタン）が正しく動作する
- [ ] ブックマークが無効化（ファイル移動・削除）された場合にエラーハンドリングされる
- [ ] ブックマークが stale の場合に自動再生成される
- [ ] macOS / iOS 両方で動作する（ブックマークオプションの分岐）

## 依存関係

- #048 (.shotcraft パッケージ形式)

## 複雑度

M
