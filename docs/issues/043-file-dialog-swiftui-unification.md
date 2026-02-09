# Issue #043: ファイルダイアログの SwiftUI 統一

## Status
Open

## Phase / Priority
Phase 8 (iPad対応) | P0 (Blocker)

## 概要

`NSOpenPanel`（4箇所）と `NSSavePanel`（2箇所）を全て削除し、SwiftUI 標準の `.fileImporter()` / `.fileExporter()` に統一する。macOS / iOS 両プラットフォームで共通のコードになる。

## 現状の問題

| API | ファイル | 用途 | 構成 |
|-----|---------|------|------|
| `NSOpenPanel` | `ScreenShotMakerApp.swift` | プロジェクト開く | `allowedContentTypes: [UTType("ssmaker")]`, `allowsMultipleSelection: false` |
| `NSSavePanel` | `ScreenShotMakerApp.swift` | プロジェクト保存 | `allowedContentTypes: [UTType("ssmaker")]`, `nameFieldStringValue`, `canCreateDirectories: true` |
| `NSOpenPanel` | `PropertiesPanelView.swift` | 背景画像選択 | `allowedContentTypes: [.png, .jpeg]`, `allowsMultipleSelection: false` |
| `NSOpenPanel` | `PropertiesPanelView.swift` | スクリーンショット画像選択 | `allowedContentTypes: [.png, .jpeg]`, `allowsMultipleSelection: false` |
| `NSSavePanel` | `ContentView.swift` | 単画面エクスポート | `allowedContentTypes: [.png, .jpeg]`, `nameFieldStringValue`, `canCreateDirectories: true` |
| `NSOpenPanel` | `ContentView.swift` | バッチエクスポート先フォルダ選択 | `canChooseFiles: false`, `canChooseDirectories: true`, `canCreateDirectories: true` |

## 対象ファイル

- 変更: `ScreenShotMaker/App/ScreenShotMakerApp.swift`
- 変更: `ScreenShotMaker/Views/ContentView.swift`
- 変更: `ScreenShotMaker/Views/PropertiesPanelView.swift`

## 実装詳細

### 1. ScreenShotMakerApp.swift — プロジェクト開く

**Before (NSOpenPanel):**
```swift
func openProject() {
    // ... unsaved check with NSAlert ...
    let panel = NSOpenPanel()
    panel.allowedContentTypes = [UTType(filenameExtension: "ssmaker")!]
    panel.allowsMultipleSelection = false
    guard panel.runModal() == .OK, let url = panel.url else { return }
    loadProject(from: url)
}
```

**After (.fileImporter):**
```swift
@State private var showOpenProject = false

// View に追加
.fileImporter(
    isPresented: $showOpenProject,
    allowedContentTypes: [UTType(filenameExtension: "ssmaker")!],
    allowsMultipleSelection: false
) { result in
    switch result {
    case .success(let urls):
        if let url = urls.first {
            loadProject(from: url)
        }
    case .failure(let error):
        // エラーハンドリング
    }
}
```

### 2. ScreenShotMakerApp.swift — プロジェクト保存

**Before (NSSavePanel):**
```swift
func saveProjectAs() {
    let panel = NSSavePanel()
    panel.allowedContentTypes = [UTType(filenameExtension: "ssmaker")!]
    panel.nameFieldStringValue = projectState.project.name + ".ssmaker"
    panel.canCreateDirectories = true
    guard panel.runModal() == .OK, let url = panel.url else { return }
    // save logic
}
```

**After (.fileExporter):**
```swift
@State private var showSaveProject = false

// 軽量な FileDocument ラッパーを定義
struct ProjectDocument: FileDocument {
    static var readableContentTypes: [UTType] { [UTType(filenameExtension: "ssmaker")!] }
    var data: Data

    init(data: Data) { self.data = data }
    init(configuration: ReadConfiguration) throws {
        data = configuration.file.regularFileContents ?? Data()
    }
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        FileWrapper(regularFileWithContents: data)
    }
}

// View に追加
.fileExporter(
    isPresented: $showSaveProject,
    document: projectDocument,
    contentType: UTType(filenameExtension: "ssmaker")!,
    defaultFilename: projectState.project.name + ".ssmaker"
) { result in
    switch result {
    case .success(let url):
        projectState.projectFileURL = url
        #if os(macOS)
        NSDocumentController.shared.noteNewRecentDocumentURL(url)
        #endif
    case .failure(let error):
        presentSaveError(error)
    }
}
```

### 3. PropertiesPanelView.swift — 背景画像選択

**Before (NSOpenPanel):**
```swift
func openBackgroundImagePicker(screen: Binding<Screen>) {
    let panel = NSOpenPanel()
    panel.allowedContentTypes = [.png, .jpeg]
    panel.allowsMultipleSelection = false
    guard panel.runModal() == .OK, let url = panel.url else { return }
    // load image
}
```

**After (.fileImporter):**
```swift
@State private var showBackgroundImagePicker = false

.fileImporter(
    isPresented: $showBackgroundImagePicker,
    allowedContentTypes: [.png, .jpeg],
    allowsMultipleSelection: false
) { result in
    switch result {
    case .success(let urls):
        if let url = urls.first {
            guard url.startAccessingSecurityScopedResource() else { return }
            defer { url.stopAccessingSecurityScopedResource() }
            let imageData = try ImageLoader.loadImage(from: url)
            // set background image
        }
    case .failure(let error):
        imageLoadError = error.localizedDescription
        showImageLoadError = true
    }
}
```

### 4. PropertiesPanelView.swift — スクリーンショット画像選択

同様のパターンで `.fileImporter` に置換。`showScreenshotImagePicker` State を追加。

### 5. ContentView.swift — 単画面エクスポート

**Before (NSSavePanel):**
```swift
func exportCurrentScreen() {
    let panel = NSSavePanel()
    panel.allowedContentTypes = [.png, .jpeg]
    panel.nameFieldStringValue = screen.name + ".png"
    panel.canCreateDirectories = true
    guard panel.runModal() == .OK, let url = panel.url else { return }
    // export and write
}
```

**After (.fileExporter):**
```swift
@State private var showExportFile = false

// ExportedImageDocument ラッパー
struct ExportedImageDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.png, .jpeg] }
    var data: Data
    var contentType: UTType

    init(configuration: ReadConfiguration) throws {
        data = configuration.file.regularFileContents ?? Data()
        contentType = configuration.contentType
    }
    init(data: Data, contentType: UTType) {
        self.data = data
        self.contentType = contentType
    }
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        FileWrapper(regularFileWithContents: data)
    }
}

.fileExporter(
    isPresented: $showExportFile,
    document: exportDocument,
    contentType: exportFormat == .png ? .png : .jpeg,
    defaultFilename: screen.name + ".\(exportFormat.rawValue)"
) { result in
    // handle result
}
```

### 6. ContentView.swift — バッチエクスポートのフォルダ選択

**Before (NSOpenPanel with canChooseDirectories):**
```swift
func startBatchExport() {
    let panel = NSOpenPanel()
    panel.canChooseFiles = false
    panel.canChooseDirectories = true
    panel.canCreateDirectories = true
    panel.prompt = "Export"
    panel.message = "Choose output folder"
    guard panel.runModal() == .OK, let url = panel.url else { return }
    // start batch export to url
}
```

**After (.fileImporter with .folder):**
```swift
@State private var showBatchExportFolderPicker = false

.fileImporter(
    isPresented: $showBatchExportFolderPicker,
    allowedContentTypes: [.folder],
    allowsMultipleSelection: false
) { result in
    switch result {
    case .success(let urls):
        if let url = urls.first {
            guard url.startAccessingSecurityScopedResource() else { return }
            // start batch export to url
            // defer stopAccessingSecurityScopedResource after export completes
        }
    case .failure(let error):
        // handle error
    }
}
```

## セキュリティスコープ対応

`.fileImporter` / `.fileExporter` で取得した URL はセキュリティスコープ付き。iOS / macOS 両方で以下のパターンが必要:

```swift
guard url.startAccessingSecurityScopedResource() else { return }
defer { url.stopAccessingSecurityScopedResource() }
```

特にバッチエクスポートでは非同期処理中にスコープを維持する必要がある。`Task` 内で `defer` を適切に配置する。

## 受け入れ基準

- [ ] `NSOpenPanel` / `NSSavePanel` の `import` や使用が全てのファイルから除去されている
- [ ] プロジェクトを開く: `.fileImporter` で `.ssmaker` ファイルを選択できる
- [ ] プロジェクトを保存: `.fileExporter` で `.ssmaker` ファイルとして保存できる
- [ ] 背景画像: `.fileImporter` で PNG/JPEG を選択できる
- [ ] スクリーンショット画像: `.fileImporter` で PNG/JPEG を選択できる
- [ ] 単画面エクスポート: `.fileExporter` で PNG/JPEG を書き出せる
- [ ] バッチエクスポート: `.fileImporter` でフォルダを選択し、全画面を書き出せる
- [ ] macOS で全てのファイルダイアログが正常に動作する
- [ ] iPad Simulator で全てのファイルダイアログが正常に動作する
- [ ] セキュリティスコープ付き URL が適切にハンドリングされている

## 依存関係

- #041 が完了していること
- #042 が完了していること（`import AppKit` 除去の前提）

## 備考

- `NSDocumentController.shared.noteNewRecentDocumentURL()` は macOS 専用のため `#if os(macOS)` でガードする（#047 で対応）。
- `.fileImporter` で取得した URL はサンドボックス外のファイルにアクセスするため、`startAccessingSecurityScopedResource()` が必須。
- `FileDocument` ラッパーは軽量な構造体として定義し、`Data` をそのまま保持するのみとする。

## 複雑度

L
