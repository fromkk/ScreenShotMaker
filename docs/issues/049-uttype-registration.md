# Issue #049: UTType 正式登録と定数定義

## Status
Open

## Phase / Priority
Phase 8 (iPad対応) | P0 (Blocker)

## 概要

`.shotcraft` パッケージ形式のカスタム UTType を `UTExportedTypeDeclarations` で正式登録し、コード側に `UTType.shotcraftProject` 定数を定義する。Files アプリでのファイルアイコン表示・関連付け・Open In・Spotlight 検索を可能にする。

## 現状

- UTType は `UTType(filenameExtension: "ssmaker")!` で実行時に動的生成
- `UTExportedTypeDeclarations` / `CFBundleDocumentTypes` の宣言なし
- Info.plist は `GENERATE_INFOPLIST_FILE = YES` で自動生成（スタンドアロン Info.plist なし）

## 対象ファイル

- 変更: `ScreenShotMaker.xcodeproj/project.pbxproj`（ビルド設定で UTType / DocumentTypes を宣言）
- 変更: `ScreenShotMaker/Utils/PlatformHelpers.swift`（`UTType.shotcraftProject` 定数追加）
- 変更: `ScreenShotMaker/App/ScreenShotMakerApp.swift`（全 `UTType(filenameExtension: "ssmaker")!` を置き換え）

## 実装詳細

### 1. UTExportedTypeDeclarations（ビルド設定経由）

Info.plist に以下が生成されるようビルド設定を追加:

```xml
<key>UTExportedTypeDeclarations</key>
<array>
    <dict>
        <key>UTTypeIdentifier</key>
        <string>me.fromkk.ScreenShotMaker.project</string>
        <key>UTTypeDescription</key>
        <string>Shotcraft Project</string>
        <key>UTTypeConformsTo</key>
        <array>
            <string>com.apple.package</string>
            <string>public.data</string>
        </array>
        <key>UTTypeTagSpecification</key>
        <dict>
            <key>public.filename-extension</key>
            <array>
                <string>shotcraft</string>
            </array>
        </dict>
    </dict>
</array>
```

### 2. CFBundleDocumentTypes

```xml
<key>CFBundleDocumentTypes</key>
<array>
    <dict>
        <key>CFBundleTypeName</key>
        <string>Shotcraft Project</string>
        <key>CFBundleTypeRole</key>
        <string>Editor</string>
        <key>LSHandlerRank</key>
        <string>Owner</string>
        <key>LSItemContentTypes</key>
        <array>
            <string>me.fromkk.ScreenShotMaker.project</string>
        </array>
    </dict>
</array>
```

### 3. コード側の UTType 定数

`PlatformHelpers.swift` に追加:

```swift
import UniformTypeIdentifiers

extension UTType {
    static let shotcraftProject = UTType("me.fromkk.ScreenShotMaker.project")!
}
```

### 4. 既存コードの置き換え

以下の箇所を `UTType.shotcraftProject` に統一:

- `ScreenShotMakerApp.swift` 内の `.fileImporter(allowedContentTypes:)`
- `ScreenShotMakerApp.swift` 内の `.fileExporter(document:contentType:)`
- `ProjectFileDocument.readableContentTypes`

## 受け入れ基準

- [ ] `UTExportedTypeDeclarations` がビルド設定に正しく追加される
- [ ] `CFBundleDocumentTypes` がビルド設定に正しく追加される
- [ ] `UTType.shotcraftProject` でカスタム UTType にアクセスできる
- [ ] iPad の Files アプリで `.shotcraft` ファイルに Shotcraft アイコンが表示される
- [ ] `.shotcraft` ファイルをタップすると Shotcraft アプリが開く候補に表示される
- [ ] 全コードの `UTType(filenameExtension: "ssmaker")` が `UTType.shotcraftProject` に置き換わる

## 依存関係

- #048 (.shotcraft パッケージ形式)

## 複雑度

S
