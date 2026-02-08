# Issue #039: 言語ごとのスクリーンショット画像管理

## Status
✅ Completed

## Phase / Priority
Phase 7 | P1 (High)

## 概要

現在、スクリーンショット画像はデバイスカテゴリ（iPhone, iPad, mac）ごとには分離されているが、言語ごとには分離されていない。そのため、ある言語で画像を変更すると全言語で同じ画像が表示されてしまう。App Store Connect の実際の運用では、各言語で異なるローカライズされたスクリーンショット（UI が各言語に翻訳されたもの）を提供する必要があるため、言語×デバイスの組み合わせで画像を管理できるようにする。

## ユースケース

1. 英語（en）でプロジェクトを開始し、iPhone 用のスクリーンショット画像（英語 UI）を設定
2. 日本語（ja）を追加すると、テキストと画像がコピーされる（現在の動作）
3. 日本語に切り替えて、日本語 UI のスクリーンショット画像をアップロード
4. 英語に戻すと英語 UI の画像、日本語に切り替えると日本語 UI の画像が表示される
5. エクスポート時は、選択された言語とデバイスの組み合わせに対応する画像が使用される

## 現状の問題

1. **画像の構造**
   - `Screen.screenshotImages: [String: Data]` はデバイスカテゴリのみをキーとしている
   - キー例: `"iPhone"`, `"iPad"`, `"mac"`
   - 言語情報が含まれていない

2. **共有の問題**
   - 全言語で同じ画像が参照される
   - 日本語で画像を変更すると、英語でも同じ画像が表示される
   - 各言語でローカライズされたスクリーンショットを提供できない

3. **言語追加時の動作**
   - `ContentView.toggleLanguage` で言語を追加すると、テキストは自動的にコピーされる（#029 で実装済み）
   - しかし、画像は**共有されたまま**
   - 理想的には、言語追加時に画像もコピーされ、その後独立して管理されるべき

4. **現在の画像設定フロー**
   - `PropertiesPanelView.screenshotImageSection` で画像を設定・表示
   - `screen.screenshotImageData(for: category)` でデバイスカテゴリのみを指定
   - 言語コードが関与していない

## 対象ファイル

- 変更: `ScreenShotMaker/Models/Screen.swift` (画像管理のキー構造を変更)
- 変更: `ScreenShotMaker/Views/ContentView.swift` (言語追加時の画像コピー処理)
- 変更: `ScreenShotMaker/Views/CanvasView.swift` (画像表示時に言語を考慮)
- 変更: `ScreenShotMaker/Views/PropertiesPanelView.swift` (画像設定・表示時に言語を考慮)
- 変更: `ScreenShotMaker/Services/ExportService.swift` (エクスポート時に言語×デバイスで画像を取得)

## 実装詳細

### 1. Screen モデルの変更

**Option A: 二次元辞書構造**
```swift
// 言語 → デバイスカテゴリ → 画像データ
var screenshotImages: [String: [String: Data]]
// 例: ["en": ["iPhone": data1, "iPad": data2], "ja": ["iPhone": data3]]
```

**Option B: 複合キー構造（推奨）**
```swift
// "言語コード-デバイスカテゴリ" をキーとする
var screenshotImages: [String: Data]
// 例: ["en-iPhone": data1, "en-iPad": data2, "ja-iPhone": data3]
```

Option B を推奨する理由：
- 既存の辞書構造を維持でき、移行が容易
- Codable の対応が簡単
- キーの生成とパースが明確

### 2. ヘルパーメソッドの実装

```swift
// Screen.swift に追加

/// 複合キーを生成: "languageCode-deviceCategory"
private func imageKey(language: String, category: DeviceCategory) -> String {
    "\(language)-\(category.rawValue)"
}

/// 言語とデバイスカテゴリを指定して画像を取得
func screenshotImageData(for language: String, category: DeviceCategory) -> Data? {
    let key = imageKey(language: language, category: category)
    return screenshotImages[key]
}

/// 言語とデバイスカテゴリを指定して画像を設定
mutating func setScreenshotImageData(_ data: Data?, for language: String, category: DeviceCategory) {
    let key = imageKey(language: language, category: category)
    if let data {
        screenshotImages[key] = data
    } else {
        screenshotImages.removeValue(forKey: key)
    }
}

/// 後方互換: デバイスカテゴリのみ指定（廃止予定）
@available(*, deprecated, message: "Use screenshotImageData(for:category:) with language code")
func screenshotImageData(for category: DeviceCategory) -> Data? {
    // "en" をデフォルト言語として使用
    screenshotImageData(for: "en", category: category)
}
```

### 3. 言語追加時の画像コピー

```swift
// ContentView.swift の toggleLanguage メソッドを更新

private func toggleLanguage(_ language: Language) {
    if let index = state.project.languages.firstIndex(where: { $0.code == language.code }) {
        // 削除処理（既存）
        guard state.project.languages.count > 1 else { return }
        state.project.languages.remove(at: index)
        if state.selectedLanguageIndex >= state.project.languages.count {
            state.selectedLanguageIndex = 0
        }
    } else {
        state.project.languages.append(language)
        // テキストと画像を現在の言語からコピー
        let sourceCode = state.selectedLanguage?.code ?? "en"
        for i in state.project.screens.indices {
            // テキストのコピー（既存）
            let sourceText = state.project.screens[i].text(for: sourceCode)
            state.project.screens[i].setText(sourceText, for: language.code)
            
            // 画像のコピー（新規）
            for device in state.project.selectedDevices {
                if let imageData = state.project.screens[i].screenshotImageData(for: sourceCode, category: device.category) {
                    state.project.screens[i].setScreenshotImageData(imageData, for: language.code, category: device.category)
                }
            }
        }
    }
    state.hasUnsavedChanges = true
}
```

### 4. UI での画像表示・設定

**CanvasView.swift**
```swift
// 現在の言語コードを取得
let languageCode = state.selectedLanguage?.code ?? "en"

// 画像を表示
if let imageData = screen.screenshotImageData(for: languageCode, category: device.category),
   let nsImage = NSImage(data: imageData) {
    // ...
}
```

**PropertiesPanelView.swift**
```swift
// screenshotImageSection メソッドを更新
private func screenshotImageSection(screen: Binding<Screen>) -> some View {
    let languageCode = state.selectedLanguage?.code ?? "en"
    
    PropertySection(title: "Screenshot Image") {
        VStack(spacing: 8) {
            if let category = state.selectedDevice?.category,
               let imageData = screen.wrappedValue.screenshotImageData(for: languageCode, category: category),
               let nsImage = NSImage(data: imageData) {
                // 画像プレビュー
                // ...
            }
            // ...
        }
    }
}

// 画像設定時
private func openImagePicker(screen: Binding<Screen>) {
    let languageCode = state.selectedLanguage?.code ?? "en"
    // ...
    if let category = state.selectedDevice?.category {
        screen.wrappedValue.setScreenshotImageData(data, for: languageCode, category: category)
    }
}
```

### 5. エクスポート処理

**ExportService.swift**
```swift
// exportScreen メソッドを更新
static func exportScreen(
    _ screen: Screen, 
    device: DeviceSize, 
    format: ExportFormat, 
    languageCode: String  // 既にパラメータとして受け取っている
) -> Data? {
    // 言語×デバイスで画像を取得
    if let imageData = screen.screenshotImageData(for: languageCode, category: device.category),
       let image = NSImage(data: imageData) {
        // レンダリング処理
    }
    // ...
}
```

### 6. データ移行（後方互換性）

既存のプロジェクトファイルをロードする際の対応：

```swift
// Screen の Codable 実装に追加

init(from decoder: Decoder) throws {
    // 既存のデコード処理
    // ...
    
    // 古い形式（デバイスのみ）の画像を新形式（言語-デバイス）に移行
    if let images = try container.decodeIfPresent([String: Data].self, forKey: .screenshotImages) {
        screenshotImages = [:]
        for (key, value) in images {
            // キーに "-" が含まれていない場合は古い形式
            if !key.contains("-") {
                // "iPhone" → "en-iPhone" に変換（デフォルト言語として "en" を使用）
                screenshotImages["en-\(key)"] = value
            } else {
                // 既に新形式
                screenshotImages[key] = value
            }
        }
    } else {
        screenshotImages = [:]
    }
}
```

## テスト計画

### 単体テスト (ScreenTests.swift)
```swift
@Test("per-language screenshot image management")
func testPerLanguageScreenshotImages() {
    var screen = Screen()
    let iPhoneData = Data([1, 2, 3])
    let iPadData = Data([4, 5, 6])
    
    // 英語で画像を設定
    screen.setScreenshotImageData(iPhoneData, for: "en", category: .iPhone)
    screen.setScreenshotImageData(iPadData, for: "en", category: .iPad)
    
    // 取得確認
    #expect(screen.screenshotImageData(for: "en", category: .iPhone) == iPhoneData)
    #expect(screen.screenshotImageData(for: "en", category: .iPad) == iPadData)
    
    // 日本語では nil
    #expect(screen.screenshotImageData(for: "ja", category: .iPhone) == nil)
}

@Test("language addition copies images")
func testLanguageAdditionCopiesImages() {
    var screen = Screen()
    let imageData = Data([1, 2, 3])
    screen.setScreenshotImageData(imageData, for: "en", category: .iPhone)
    
    // 日本語に同じ画像をコピー
    if let data = screen.screenshotImageData(for: "en", category: .iPhone) {
        screen.setScreenshotImageData(data, for: "ja", category: .iPhone)
    }
    
    #expect(screen.screenshotImageData(for: "ja", category: .iPhone) == imageData)
    
    // 英語の画像を変更
    let newData = Data([7, 8, 9])
    screen.setScreenshotImageData(newData, for: "en", category: .iPhone)
    
    // 日本語の画像は変更されない（独立している）
    #expect(screen.screenshotImageData(for: "ja", category: .iPhone) == imageData)
    #expect(screen.screenshotImageData(for: "en", category: .iPhone) == newData)
}
```

### 統合テスト
1. 既存プロジェクトファイルの読み込みが正常に動作することを確認
2. 言語追加時に画像がコピーされることを確認
3. 各言語で異なる画像を設定し、言語切り替え時に正しい画像が表示されることを確認
4. エクスポート時に正しい言語×デバイスの画像が使用されることを確認

## 受け入れ基準

- [ ] `screenshotImages` のキーが "languageCode-deviceCategory" 形式になっている
- [ ] 言語追加時、現在の言語の画像が全デバイスカテゴリに対してコピーされる
- [ ] 言語を切り替えると、その言語に設定された画像が表示される
- [ ] ある言語で画像を変更しても、他の言語の画像に影響しない
- [ ] エクスポート時、選択された言語とデバイスに対応する画像が使用される
- [ ] 既存のプロジェクトファイル（旧形式）が新形式に自動的に移行される
- [ ] 画像未設定時は適切にフォールバックする（drop zone を表示）
- [ ] 全既存テストがパスする
- [ ] 新規テストが追加され、パスする

## 影響範囲

### 破壊的変更
- `screenshotImageData(for: DeviceCategory)` メソッドは非推奨となり、将来削除される
- 既存のプロジェクトファイルは自動的に移行されるが、保存すると新形式になる

### 後方互換性
- デコード時に旧形式を検出し、自動的に新形式（"en-" プレフィックス）に変換
- 非推奨メソッドは一時的に残し、段階的に削除

## 関連 Issue

- #029: 言語追加時のテキストコピー（実装済み） - 画像も同様にコピーする
- #034: デバイス別スクリーンショット管理（実装済み） - これを言語軸でも拡張する
- #007: 言語ごとのテキスト保存（実装済み） - 同じアプローチを画像にも適用
