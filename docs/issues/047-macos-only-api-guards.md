# Issue #047: macOS 専用 API のプラットフォームガード

## Status
Open

## Phase / Priority
Phase 8 (iPad対応) | P0 (Blocker)

## 概要

#042〜#046 で置換しきれない macOS 専用 API を `#if os(macOS)` / `#if canImport(AppKit)` で囲み、iOS ビルドでコンパイルエラーが発生しないようにする。また、#042 で作成したヘルパーへの置換を各ファイルで実施する。

## 対象箇所の一覧

### A. ScreenShotMakerApp.swift

| 行 | API | 対応 |
|----|-----|------|
| `.frame(minWidth: 960, minHeight: 600)` | macOS ウィンドウサイズ | `#if os(macOS)` でガード |
| `.windowStyle(.titleBar)` | macOS ウィンドウスタイル | `#if os(macOS)` でガード |
| `.defaultSize(width: 1280, height: 800)` | macOS デフォルトサイズ | `#if os(macOS)` でガード |
| `NSDocumentController.shared.noteNewRecentDocumentURL(url)` ×2 | macOS 最近使った項目 | `#if os(macOS)` でガード |

### B. PropertiesPanelView.swift

| 行 | API | 対応 |
|----|-----|------|
| `import AppKit` | AppKit インポート | 削除（ヘルパー経由に移行） |
| `NSFontManager.shared.availableFontFamilies.sorted()` | フォント一覧 | `FontHelper.availableFontFamilies` に置換 |
| `NSImage(data:)` / `Image(nsImage:)` ×4 | 画像表示 | `PlatformImage` / `Image(platformImage:)` に置換 |
| `Color(nsColor: .controlColor)` | コントロール色 | `Color.platformControl` に置換 |
| `Color(nsColor: .controlBackgroundColor)` | 背景色 | `Color.platformControlBackground` に置換 |
| `Color(nsColor: .separatorColor)` ×5 | セパレータ色 | `Color.platformSeparator` に置換 |

### C. CanvasView.swift

| 行 | API | 対応 |
|----|-----|------|
| `Color(nsColor: .windowBackgroundColor)` | 背景色 | `Color.platformBackground` に置換 |
| `NSImage(data:)` / `Image(nsImage:)` ×4 | 画像表示 | `PlatformImage` / `Image(platformImage:)` に置換 |

### D. ExportProgressView.swift

| 行 | API | 対応 |
|----|-----|------|
| `NSWorkspace.shared.open(outputDirectory)` | Finder でフォルダを開く | `#if os(macOS)` でガード。iOS では非表示またはメッセージのみ |

### E. TemplateGalleryView.swift

| 行 | API | 対応 |
|----|-----|------|
| `Color(nsColor: .separatorColor)` | セパレータ色 | `Color.platformSeparator` に置換 |

### F. ContentView.swift（SidebarView 部分）

| 行 | API | 対応 |
|----|-----|------|
| `Color(nsColor: .separatorColor)` | セパレータ色 | `Color.platformSeparator` に置換 |

### G. BackgroundStyle.swift

| 行 | API | 対応 |
|----|-----|------|
| `NSColor(self).usingColorSpace(.sRGB)` in `Color.toHex()` | 色変換 | #042 のヘルパーに移設済みなら削除、そうでなければ `#if` 分岐 |

## 対象ファイル

- 変更: `ScreenShotMaker/App/ScreenShotMakerApp.swift`
- 変更: `ScreenShotMaker/Views/PropertiesPanelView.swift`
- 変更: `ScreenShotMaker/Views/CanvasView.swift`
- 変更: `ScreenShotMaker/Views/ExportProgressView.swift`
- 変更: `ScreenShotMaker/Views/TemplateGalleryView.swift`
- 変更: `ScreenShotMaker/Views/ContentView.swift`
- 変更: `ScreenShotMaker/Models/BackgroundStyle.swift`

## 実装詳細

### 1. ScreenShotMakerApp.swift — ウィンドウ修飾子のガード

```swift
var body: some Scene {
    WindowGroup {
        ContentView(projectState: projectState)
            #if os(macOS)
            .frame(minWidth: 960, minHeight: 600)
            #endif
            // ... fileImporter, alert, etc. ...
    }
    #if os(macOS)
    .windowStyle(.titleBar)
    .defaultSize(width: 1280, height: 800)
    #endif
    .commands { ... }  // ← commands は iPad でもキーボードショートカットとして機能するため、ガード不要
}
```

### 2. ScreenShotMakerApp.swift — NSDocumentController のガード

```swift
// loadProject 内
#if os(macOS)
NSDocumentController.shared.noteNewRecentDocumentURL(url)
#endif

// saveProjectAs 内
#if os(macOS)
NSDocumentController.shared.noteNewRecentDocumentURL(url)
#endif
```

### 3. PropertiesPanelView.swift — import と API 置換

```swift
// Before
import AppKit

// After
// import AppKit は削除。PlatformCompatibility.swift 経由で必要な型が利用可能

// Before
let families = NSFontManager.shared.availableFontFamilies.sorted()
// After
let families = FontHelper.availableFontFamilies

// Before
if let nsImage = NSImage(data: data) { Image(nsImage: nsImage) }
// After
if let image = PlatformImage(data: data) { Image(platformImage: image) }

// Before
Color(nsColor: .separatorColor)
// After
Color.platformSeparator
```

### 4. CanvasView.swift — カラーと画像の置換

```swift
// Before
Color(nsColor: .windowBackgroundColor)
// After
Color.platformBackground

// Before
if let nsImage = NSImage(data: data) { Image(nsImage: nsImage) }
// After
if let image = PlatformImage(data: data) { Image(platformImage: image) }
```

### 5. ExportProgressView.swift — Finder ボタンのガード

```swift
#if os(macOS)
Button("Show in Finder") {
    NSWorkspace.shared.open(outputDirectory)
}
#endif
```

### 6. 各ビューの Color(nsColor:) → Color.platform* 置換

全ファイルで機械的に置換:
- `Color(nsColor: .windowBackgroundColor)` → `Color.platformBackground`
- `Color(nsColor: .controlColor)` → `Color.platformControl`
- `Color(nsColor: .controlBackgroundColor)` → `Color.platformControlBackground`
- `Color(nsColor: .separatorColor)` → `Color.platformSeparator`

## 受け入れ基準

- [ ] `import AppKit` が `PropertiesPanelView.swift` から削除されている
- [ ] `NSImage` / `Image(nsImage:)` の直接使用がプロジェクト全体で0箇所（ExportService の `#if canImport(AppKit)` ブロック内を除く）
- [ ] `Color(nsColor:)` の直接使用がプロジェクト全体で0箇所
- [ ] `NSFontManager` の直接使用がプロジェクト全体で0箇所
- [ ] `NSDocumentController` が `#if os(macOS)` 内に限定されている
- [ ] `NSWorkspace` が `#if os(macOS)` 内に限定されている
- [ ] `.windowStyle` / `.defaultSize` / `.frame(minWidth:)` が `#if os(macOS)` 内に限定されている
- [ ] macOS ビルドが成功し、既存の全機能が動作する
- [ ] iPad Simulator ビルドが成功する
- [ ] iPad Simulator で起動し、基本的な画面遷移が動作する

## 依存関係

- #042 が完了していること（`PlatformImage`, `Color.platform*`, `FontHelper` が必要）
- #043 が完了していること（`NSOpenPanel` / `NSSavePanel` が除去済み）
- #044 が完了していること（`NSAlert` が除去済み）
- #045 が完了していること（`ExportService` のパイプライン分岐済み）

## 備考

- この issue が完了すると、プロジェクト全体が macOS / iOS 両方でコンパイル可能になる。
- `.commands {}` ブロックは iPadOS でハードウェアキーボード接続時にショートカットとして機能するため、ガード不要。
- `.inspector()` / `.inspectorColumnWidth()` は iOS 17+ で利用可能、ガード不要。
- `MagnifyGesture` は iOS 17+ で利用可能（ピンチジェスチャー）、ガード不要。
- `.onDrop(of:)` は iPadOS で利用可能（Split View や Files アプリからのドラッグ&ドロップ）、ガード不要。
- `.help()` は iOS では no-op だが、コンパイルエラーにはならないためガード不要。
- `.keyboardShortcut()` は iPad でハードウェアキーボード接続時に機能、ガード不要。

## 複雑度

L
