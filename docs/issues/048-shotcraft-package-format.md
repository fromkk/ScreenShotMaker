# Issue #048: .shotcraft パッケージ形式への移行

## Status
Open

## Phase / Priority
Phase 8 (iPad対応) | P0 (Blocker)

## 概要

プロジェクトファイルを従来の `.ssmaker`（単一 JSON）から `.shotcraft`（ディレクトリバンドル / パッケージ）形式に移行する。画像データを個別ファイルとして分離し、ファイルサイズの肥大化を解消する。旧 `.ssmaker` 形式のサポートは不要（未リリースのため）。

## 現状

- プロジェクトファイルは `.ssmaker` 拡張子の単一 JSON ファイル
- `screenshotImages: [String: Data]` と `BackgroundStyle.image(data:)` の画像データが Base64 エンコードで JSON 内に埋め込まれている
- 複数言語×複数デバイス×複数画面で数十〜数百 MB の JSON になる
- `ProjectFileService` は `JSONEncoder` / `JSONDecoder` で直接シリアライズ
- `ProjectFileDocument` は `FileWrapper(regularFileWithContents:)` を返す単一ファイル型
- UTType は `UTType(filenameExtension: "ssmaker")!` で動的生成（正式登録なし）

## パッケージ構造

```
MyProject.shotcraft/                           ← ディレクトリ（OS 上はパッケージとして1ファイルに見える）
├── project.json                               ← 画像 Data を除外した ScreenShotProject JSON
└── images/
    ├── {screenID}-{lang}-{deviceCategory}.png  ← screenshotImages の各エントリ
    ├── {screenID}-{lang}-{deviceCategory}.jpg  ← マジックナンバー判定で拡張子決定
    └── {screenID}-background.heic              ← BackgroundStyle.image(data:) の Data
```

- 画像ファイルの拡張子はマジックナンバー判定で決定（PNG / JPEG / GIF / HEIC / 不明時は `.dat`）
- `project.json` 内の画像フィールドにはファイル名参照（相対パス文字列）を格納

## 対象ファイル

- 新規: `ScreenShotMaker/Utils/ImageFormatDetector.swift`
- 変更: `ScreenShotMaker/Services/ProjectFileService.swift`
- 変更: `ScreenShotMaker/App/ScreenShotMakerApp.swift`（`ProjectFileDocument` の更新）

## 実装詳細

### 1. ImageFormatDetector ユーティリティの作成

```swift
enum ImageFormat: String {
    case png, jpeg, gif, heic, dat
    var fileExtension: String { rawValue }
}

enum ImageFormatDetector {
    static func detect(from data: Data) -> ImageFormat
}
```

- PNG: 先頭 `89 50 4E 47`
- JPEG: 先頭 `FF D8 FF`
- GIF: 先頭 `47 49 46 38`
- HEIC: オフセット 4 から `66 74 79 70 68 65 69 63` または `66 74 79 70 6D 69 66 31`
- 上記いずれにも該当しない場合は `.dat`

### 2. ProjectFileService の拡張

`Screen.encode(to:)` は変更せず、Service 層で中間表現（`JSONSerialization` による Dictionary 操作）を使って画像データを分離・復元する。

```swift
enum ProjectFileService {
    // 既存（削除予定）
    static func save(_ project: ScreenShotProject, to url: URL) throws
    static func encode(_ project: ScreenShotProject) throws -> Data
    static func load(from url: URL) throws -> ScreenShotProject

    // 新規: パッケージ形式
    static func savePackage(_ project: ScreenShotProject) throws -> FileWrapper
    static func loadPackage(from fileWrapper: FileWrapper) throws -> ScreenShotProject
}
```

#### 保存フロー (`savePackage`)

1. `JSONEncoder` で `ScreenShotProject` を Data にエンコード
2. `JSONSerialization` で Dictionary に変換
3. `screens` 配列を走査し、各 Screen の:
   - `screenshotImages` の各エントリ → `images/` ディレクトリに個別 `FileWrapper` として追加、Dictionary 側はファイル名参照文字列に差し替え
   - `background` が `.image(data:)` の場合 → 同様に分離・差し替え
4. 差し替え済み Dictionary を `JSONSerialization` で Data に戻し `project.json` の `FileWrapper` を生成
5. `FileWrapper(directoryWithFileWrappers:)` で全体をまとめて返す

#### 読み込みフロー (`loadPackage`)

1. ディレクトリ `FileWrapper` から `project.json` を読み込み
2. `JSONSerialization` で Dictionary に変換
3. `screens` 配列を走査し、ファイル名参照文字列を `images/` ディレクトリ内の `FileWrapper` から読み取った実 Data に復元
4. 復元済み Dictionary を `JSONSerialization` で Data に戻し `JSONDecoder` で `ScreenShotProject` にデコード

### 3. ProjectFileDocument の更新

```swift
struct ProjectFileDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.shotcraftProject] }
    var project: ScreenShotProject

    init(project: ScreenShotProject) { self.project = project }

    init(configuration: ReadConfiguration) throws {
        project = try ProjectFileService.loadPackage(from: configuration.file)
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        try ProjectFileService.savePackage(project)
    }
}
```

- `regularFileWithContents` → `directoryWithFileWrappers` に変更
- `Data` ベースではなく `ScreenShotProject` を直接保持

## 受け入れ基準

- [ ] プロジェクト保存時に `.shotcraft` ディレクトリバンドルが生成される
- [ ] パッケージ内に `project.json` と `images/` ディレクトリが含まれる
- [ ] `project.json` に画像のバイナリデータが含まれない（ファイル名参照のみ）
- [ ] 画像ファイルの拡張子がマジックナンバー判定で正しく設定される（PNG → `.png`、JPEG → `.jpg` 等）
- [ ] 元画像データがそのまま保持される（再エンコードなし）
- [ ] 保存したパッケージを再度読み込んで全データが復元される（ラウンドトリップ）
- [ ] スクリーンショット画像・背景画像の両方がパッケージ内に分離保存される
- [ ] `ProjectFileDocument` が `directoryWithFileWrappers` を返す

## 依存関係

なし

## 複雑度

L
