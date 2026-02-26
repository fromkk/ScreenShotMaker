# Issue #058: 動画（App Preview）対応

## Status
Open

## Phase / Priority
Phase 9 (App Preview 対応) | P1

## 概要

スクリーンショットの代わりに動画（mp4 / mov）を各スクリーンにアサインし、App Store Connect の App Preview 形式で書き出せるようにする。表示・取り込み・エクスポートの 3 段階すべてで動画を扱えるようにする。

### App Store Connect 仕様（参考）

- 受理形式: `.mov`, `.m4v`, `.mp4`（H.264）および `.mov`（ProRes 422 HQ のみ）
- App Preview はスクリーンショットの前に常に配置される
- ポスターフレーム（App Store 上で静止画として表示されるフレーム）を設定できる
- iOS: 縦・横の両方向に対応。再生時は元の向きに回転される
- macOS / tvOS / visionOS: 横向きのみ
- iMessage アプリには App Preview は使用不可
- アップロード後の処理は最大 24 時間かかる場合がある

## 現状

- `Screen.screenshotImages: [String: Data]` で画像 Data を直接保持している
- プレビューは SwiftUI の `Image(platformImage:)` で表示（静止画のみ）
- エクスポートは `ImageRenderer` で SwiftUI View を静止画にラスタライズ
- `ImageLoader` は `.png` / `.jpg` / `.jpeg` のみを許可している
- ドラッグ&ドロップ・`fileImporter`・`PhotosPicker` はいずれも画像のみ対応

## 設計方針

### 動画データの保持方法

**ファイル参照（セキュリティスコープ付きブックマーク）** を選択する。

動画ファイルは数十〜数百 MB になるため、`screenshotImages` と同様に `Data` を直接モデルに保持することは現実的でない。代わりに以下の方式を採用する：

1. **編集中（メモリ上）**: `URL` ブックマーク Data（数 KB）を `screenshotVideoBookmarks: [String: Data]` に保持する
2. **保存時（.shotcraft パッケージ）**: 動画ファイルそのものを `videos/` サブディレクトリにコピーし、`project.json` にはパッケージ内相対パス文字列を記録する
3. **読み込み時**: `videos/` 内の動画ファイルを App Group 一時ディレクトリに展開し、そこへの `URL` からブックマークを再生成する

これにより .shotcraft ファイル 1 つを共有するだけで動画も含めて完全に移植可能になる。

### 画像との排他制御

同一スクリーン×言語×デバイスカテゴリに対し、**画像と動画は排他**とする。

- 動画をセットすると同キーの `screenshotImages` エントリを削除する
- 画像をセットすると同キーの `screenshotVideoBookmarks` / `screenshotVideoPosterTimes` エントリを削除する

## .shotcraft パッケージ形式の拡張

既存の `images/` サブディレクトリに加え `videos/` サブディレクトリを追加する。

```
MyProject.shotcraft/
├── project.json
├── images/
│   ├── {screenID}-{lang}-{deviceCategory}.png
│   └── {screenID}-background.heic
└── videos/                                          ← 新規追加
    └── {screenID}-{lang}-{deviceCategory}.mp4       ← 元ファイルをそのままコピー
```

- 動画ファイルの拡張子は元ファイルの拡張子をそのまま使用する（`.mp4` / `.mov` / `.m4v`）
- `project.json` 内の `screenshotVideoBookmarks` フィールドには `"videos/{filename}"` 形式の相対パス文字列を記録する

### 後方互換性（既存 .shotcraft ファイルの読み込み）

`videos/` ディレクトリが存在しない既存の .shotcraft ファイルは変更なく読み込める。

- `project.json` に `screenshotVideoBookmarks` キーが存在しない場合、`decodeIfPresent` により `nil`（空辞書）として扱われる
- `project.json` に `screenshotVideoPosterTimes` キーが存在しない場合、同様に空辞書として扱われる
- `videos/` サブディレクトリが `FileWrapper` に存在しない場合も、ファイル名参照の復元をスキップするだけで正常にデコードされる

既存ファイルは **再保存すると** `videos/` が空のまま追加される（実質無変化）。

## 対象ファイル

### 新規作成

| ファイル | 内容 |
|---|---|
| `ScreenShotMaker/Utils/VideoLoader.swift` | 動画バリデーション・ブックマーク生成・サムネイル生成 |
| `ScreenShotMaker/Services/VideoExportService.swift` | AVFoundation コンポジション・エクスポート |

### 変更

| ファイル | 変更内容 |
|---|---|
| `ScreenShotMaker/Models/Screen.swift` | 動画用プロパティ追加・排他制御ヘルパー追加・CodingKeys/decode 拡張 |
| `ScreenShotMaker/Services/ProjectFileService.swift` | `savePackage` / `loadPackage` に `videos/` 対応追加 |
| `ScreenShotMaker/Services/ExportService.swift` | バッチエクスポート時に動画か画像かを判定して分岐 |
| `ScreenShotMaker/Views/PropertiesPanelView.swift` | ドラッグ&ドロップ・fileImporter・PhotosPicker を動画対応に拡張、ポスターフレームスライダー追加 |
| `ScreenShotMaker/Views/CanvasView.swift` | `screenshotPlaceholder` を `VideoPlayer` 対応に拡張 |
| `ScreenShotMaker/Utils/ImageLoader.swift` | UTType リストを整理（動画判定は `VideoLoader` に委譲） |

## 実装詳細

### 1. Screen モデルの拡張 (`Screen.swift`)

```swift
struct Screen: Identifiable, Hashable, Codable {
    // 既存プロパティ（変更なし）
    var screenshotImages: [String: Data]

    // 新規追加
    /// セキュリティスコープ付き URL ブックマーク Data。キーは "lang-DeviceCategory"。
    var screenshotVideoBookmarks: [String: Data]
    /// ポスターフレームの秒数。キーは同上。
    var screenshotVideoPosterTimes: [String: Double]
}
```

**ヘルパーメソッド（追加）:**

```swift
// 動画 URL を解決して返す（ブックマーク未解決なら nil）
func screenshotVideoURL(for languageCode: String, category: DeviceCategory) -> URL?

// 動画が設定されているか確認
func hasVideo(for languageCode: String, category: DeviceCategory) -> Bool

// 動画をセット（同キーの画像エントリを削除する）
mutating func setScreenshotVideo(
    bookmarkData: Data,
    posterTime: Double,
    for languageCode: String,
    category: DeviceCategory
)

// 画像をセット（既存の setScreenshotImageData を拡張して同キーの動画エントリを削除）
mutating func setScreenshotImageData(_ data: Data, for languageCode: String, category: DeviceCategory)

// 画像・動画の両方をクリア
mutating func clearScreenshotMedia(for languageCode: String, category: DeviceCategory)
```

**CodingKeys 追加:**

```swift
enum CodingKeys: String, CodingKey {
    // 既存キー（変更なし）
    // ...
    // 新規追加
    case screenshotVideoBookmarks
    case screenshotVideoPosterTimes
}
```

**デコード時のマイグレーション（追加）:**

```swift
// screenshotVideoBookmarks: キーが存在しない旧ファイルは空辞書
screenshotVideoBookmarks = try container.decodeIfPresent(
    [String: Data].self, forKey: .screenshotVideoBookmarks
) ?? [:]

// screenshotVideoPosterTimes: キーが存在しない旧ファイルは空辞書
screenshotVideoPosterTimes = try container.decodeIfPresent(
    [String: Double].self, forKey: .screenshotVideoPosterTimes
) ?? [:]
```

### 2. VideoLoader ユーティリティ (`VideoLoader.swift`)

```swift
enum VideoLoadError: Error {
    case invalidFormat     // 非対応拡張子
    case fileTooLarge      // 500MB 超
    case bookmarkFailed    // ブックマーク生成失敗
}

enum VideoLoader {
    static let maxFileSize: Int = 500 * 1024 * 1024  // 500MB

    /// URL を検証してセキュリティスコープ付きブックマーク Data を返す
    static func loadVideo(from url: URL) throws -> (bookmarkData: Data, duration: Double)

    /// AVAssetImageGenerator でポスターフレームのサムネイルを生成
    static func generateThumbnail(url: URL, at time: Double) async -> Data?
}
```

- 対応拡張子チェック: `["mp4", "mov", "m4v"]`
- UTType チェック: `UTType(filenameExtension:)` が `.movie` に準拠するか確認
- ファイルサイズチェック: `FileManager.attributesOfItem(atPath:)[.size]`
- ブックマーク生成: `url.bookmarkData(options: .withSecurityScope, ...)`
- サムネイル生成: `AVAssetImageGenerator(asset:)` + `copyCGImage(at:actualTime:)`

### 3. ProjectFileService の拡張 (`ProjectFileService.swift`)

#### 保存フロー (`savePackage`) の変更点

既存の `images/` 分離処理に加え:

1. `screens` 配列を走査し、`screenshotVideoBookmarks` の各エントリについて:
   - ブックマーク Data から `URL` を解決（`URL(resolvingBookmarkData:)`）
   - 動画ファイルを読み込み `Data` を取得
   - `videos/{screenID}-{lang}-{deviceCategory}.{ext}` として `FileWrapper` に追加
   - Dictionary 側はパス参照文字列（`"videos/{filename}"`）に差し替え
   - `screenshotVideoPosterTimes` はそのまま `project.json` に記録

#### 読み込みフロー (`loadPackage`) の変更点

既存の `images/` 復元処理に加え:

1. `videos/` サブディレクトリの `FileWrapper` が存在する場合のみ実行（後方互換）
2. `screenshotVideoBookmarks` の各エントリ（パス参照文字列）について:
   - `videos/` FileWrapper から対応するファイルの `FileWrapper` を取得
   - 一時ディレクトリ（`FileManager.temporaryDirectory`）にファイルを書き出し
   - 書き出し先 `URL` からブックマーク Data を生成し Dictionary に格納
3. 復元済み Dictionary を `JSONDecoder` でデコード

### 4. ドラッグ&ドロップ・Picker の拡張 (`PropertiesPanelView.swift`)

#### onChange のドロップ許容型 追加

```swift
.onDrop(of: [.fileURL, .image, .movie, .mpeg4Movie, .quickTimeMovie], isTargeted: nil) { providers in
    handleScreenshotDrop(providers: providers, screen: screen)
}
```

#### `handleScreenshotDrop` の変更点

ファイル URL 取得後:

```swift
let ext = url.pathExtension.lowercased()
if ["mp4", "mov", "m4v"].contains(ext) {
    let (bookmarkData, duration) = try VideoLoader.loadVideo(from: url)
    // ポスターフレームをデフォルト 0 秒で設定
    screen.wrappedValue.setScreenshotVideo(bookmarkData: bookmarkData, posterTime: 0, for: languageCode, category: category)
    // 非同期でサムネイルを生成してプレビュー用 State を更新
} else {
    let imageData = try ImageLoader.loadImage(from: url)
    screen.wrappedValue.setScreenshotImageData(imageData, for: languageCode, category: category)
}
```

#### `fileImporter` の変更点

```swift
.fileImporter(
    isPresented: $showScreenshotImagePicker,
    allowedContentTypes: [.png, .jpeg, .movie, .mpeg4Movie, .quickTimeMovie]
) { result in
    // 拡張子に応じて ImageLoader / VideoLoader に振り分け
}
```

#### `PhotosPicker` の変更点

```swift
PhotosPicker(
    selection: $screenshotPhotosItem,
    matching: .any(of: [.images, .videos])
) { ... }
```

#### ポスターフレームスライダー（新規追加）

動画が設定されているスクリーンのプロパティパネルに表示:

```swift
if screen.hasVideo(for: languageCode, category: selectedCategory) {
    VStack(alignment: .leading, spacing: 4) {
        Text("Poster Frame").font(.caption)
        Slider(
            value: Binding(
                get: { screen.screenshotVideoPosterTimes[key] ?? 0 },
                set: { newTime in
                    screen.screenshotVideoPosterTimes[key] = newTime
                    Task { thumbnailImage = await VideoLoader.generateThumbnail(url: videoURL, at: newTime) }
                }
            ),
            in: 0...videoDuration
        )
        Text(String(format: "%.1f s", posterTime)).font(.caption2).foregroundStyle(.secondary)
    }
}
```

### 5. プレビュー表示 (`CanvasView.swift`)

`screenshotPlaceholder(screen:)` に動画分岐を追加:

```swift
// 既存の画像表示分岐の前に追加
if let device = state.selectedDevice,
   let videoURL = screen.screenshotVideoURL(for: languageCode, category: device.category)
{
    // VideoPlayer を表示
    VideoPlayer(player: videoPlayerFor(screen: screen, device: device))
        .aspectRatio(contentMode: .fit)
        .clipShape(RoundedRectangle(cornerRadius: 8))
} else if let imageData = ..., let platformImage = ... {
    // 既存の Image 表示（変更なし）
}
```

`@State private var videoPlayers: [String: AVPlayer] = [:]` を用いて、同一 URL に対して AVPlayer を使い回す。

### 6. エクスポートサービスの分岐 (`ExportService.swift` / 新規 `VideoExportService.swift`)

#### VideoExportService の概要

```swift
@MainActor
enum VideoExportService {
    /// 動画スクリーンを合成してエクスポートする
    static func exportVideoScreen(
        _ screen: Screen,
        device: DeviceSize,
        languageCode: String,
        outputURL: URL
    ) async throws

    /// バッチで動画エクスポート
    static func batchVideoExport(
        project: ScreenShotProject,
        devices: [DeviceSize],
        languages: [Language],
        outputDirectory: URL,
        progressState: ExportProgressState
    ) async
}
```

#### AVFoundation コンポジション処理

1. `AVURLAsset(url: videoURL)` で元動画を読み込む
2. `AVMutableComposition` に映像・音声トラックを追加する
3. SwiftUI `ImageRenderer` でオーバーレイ画像（背景 + テキスト + デバイスフレーム）を `CGImage` に生成する（動画フレームと同解像度）
4. `AVVideoCompositionCoreAnimationTool` でオーバーレイ `CALayer` をコンポジションに適用する
5. `AVAssetExportSession(asset:presetName: AVAssetExportPresetHighestQuality)` で `.mp4` に出力する

#### ExportService バッチ処理の変更点

```swift
// batchExport / batchRender の各ループ内
if screen.hasVideo(for: languageCode, category: device.category) {
    // 動画エクスポート（.mp4 固定）
    let outputURL = outputDirectory.appendingPathComponent("\(screen.name).mp4")
    try await VideoExportService.exportVideoScreen(screen, device: device, languageCode: languageCode, outputURL: outputURL)
} else {
    // 既存の静止画エクスポート（変更なし）
    let data = exportScreen(screen, device: device, format: format, languageCode: languageCode)
    ...
}
```

出力ファイルの構造（動画がある場合）:

```
{outputDir}/
└── {language.code}/
    └── {device.name}/
        ├── {screen.name}.mp4   ← 動画スクリーン
        └── {screen.name}.png   ← 静止画スクリーン（変更なし）
```

## 後方互換性まとめ

| シナリオ | 動作 |
|---|---|
| 既存 .shotcraft を開く（動画なし） | `screenshotVideoBookmarks` / `screenshotVideoPosterTimes` が空辞書としてデコードされ正常に読み込まれる |
| 既存 .shotcraft を開いて再保存する | `videos/` ディレクトリが空のまま追加されるが実質無変化 |
| 動画入り .shotcraft を旧バージョンで開く | `screenshotVideoBookmarks` の未知キーは `CodingKeys` に存在しないため無視される（Swift の Codable 仕様） |
| 動画と画像が混在するプロジェクト | スクリーンごと・言語ごと・デバイスカテゴリごとに個別に管理されるため競合しない |

## 受け入れ基準

- [ ] mp4 / mov ファイルをドラッグ&ドロップでスクリーンにアサインできる
- [ ] `fileImporter`（Files ダイアログ）から mp4 / mov を選択できる
- [ ] `PhotosPicker` から動画を選択できる
- [ ] キャンバス上で動画が `VideoPlayer` として再生される
- [ ] Properties パネルにポスターフレームスライダーが表示され、変更がプレビューに反映される
- [ ] 動画スクリーンのエクスポートで `.mp4` ファイルが生成される
- [ ] 生成された `.mp4` に背景・テキスト・デバイスフレームが合成されている
- [ ] 静止画スクリーンのエクスポートは従来どおり動作する（リグレッションなし）
- [ ] 動画入り .shotcraft の保存・再読み込みで動画が復元される（ラウンドトリップ）
- [ ] 動画なしの既存 .shotcraft が問題なく読み込まれる（後方互換）
- [ ] 動画をセットした後に画像に切り替えると動画エントリが削除される（排他制御）

## 依存関係

- #048 (.shotcraft パッケージ形式) — `savePackage` / `loadPackage` の基盤が必要

## 複雑度

XL

## 参考リンク

- [App Store Connect: App プレビュー](https://developer.apple.com/help/app-store-connect/manage-app-information/upload-app-previews-and-screenshots)
- [App プレビューについて](https://developer.apple.com/app-store/app-previews/)
- [AVFoundation — AVMutableVideoComposition](https://developer.apple.com/documentation/avfoundation/avmutablevideocomposition)
- [AVVideoCompositionCoreAnimationTool](https://developer.apple.com/documentation/avfoundation/avvideocompositioncoreanimationtool)
