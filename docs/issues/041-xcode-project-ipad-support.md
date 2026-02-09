# Issue #041: Xcode プロジェクト設定の iPad（iOS 18+）対応

## Status
Open

## Phase / Priority
Phase 8 (iPad対応) | P0 (Blocker)

## 概要

現在 macOS 専用（`SDKROOT = macosx`, `MACOSX_DEPLOYMENT_TARGET = 26.0`）で構成されているプロジェクトを、iPad（iOS 18+）でもビルド・実行できるようにプロジェクト設定を変更する。iPhone は対象外（`TARGETED_DEVICE_FAMILY = 2`）。

## 現状

- `SDKROOT = macosx`（macOS のみ）
- `SUPPORTED_PLATFORMS` 未設定（デフォルトで macOS のみ）
- `IPHONEOS_DEPLOYMENT_TARGET` 未設定
- `TARGETED_DEVICE_FAMILY` 未設定
- `LD_RUNPATH_SEARCH_PATHS = @executable_path/../Frameworks`（macOS 形式のみ）
- `COMBINE_HIDPI_IMAGES = YES`（macOS 専用設定）
- `ENABLE_HARDENED_RUNTIME = YES`（macOS 専用）
- Entitlements: macOS サンドボックス用のみ（`com.apple.security.app-sandbox` 等）
- Info.plist: Xcode 生成（スタンドアロン Info.plist なし）
- `NSPhotoLibraryAddUsageDescription` 未設定

## 対象ファイル

- 変更: `ScreenShotMaker.xcodeproj/project.pbxproj`
- 新規: `ScreenShotMaker/ScreenShotMaker-iOS.entitlements`（iOS 用 Entitlements）

## 実装詳細

### 1. ビルド設定の変更（project.pbxproj）

| 設定キー | 現在値 | 変更後 |
|---------|--------|--------|
| `SDKROOT` | `macosx` | `auto`（Xcode にプラットフォーム自動選択させる） |
| `SUPPORTED_PLATFORMS` | (未設定) | `"macosx iphoneos iphonesimulator"` |
| `IPHONEOS_DEPLOYMENT_TARGET` | (未設定) | `18.0` |
| `TARGETED_DEVICE_FAMILY` | (未設定) | `"2"` (iPad のみ) |
| `LD_RUNPATH_SEARCH_PATHS` | `@executable_path/../Frameworks` | `@executable_path/../Frameworks` (macOS) + `@executable_path/Frameworks` (iOS) |
| `SUPPORTS_MACCATALYST` | (未設定) | `NO`（Mac Catalyst ではなくネイティブ macOS を維持） |

### 2. Info.plist キーの追加（ビルド設定経由）

```
INFOPLIST_KEY_NSPhotoLibraryAddUsageDescription = "Export images to Photos library"
INFOPLIST_KEY_UIRequiresFullScreen = YES
INFOPLIST_KEY_UISupportedInterfaceOrientations_iPad = "UIInterfaceOrientationPortrait UIInterfaceOrientationPortraitUpsideDown UIInterfaceOrientationLandscapeLeft UIInterfaceOrientationLandscapeRight"
```

### 3. iOS 用 Entitlements ファイル

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>com.apple.security.network.client</key>
    <true/>
</dict>
</plist>
```

- iOS ではアプリサンドボックスがデフォルトのため `com.apple.security.app-sandbox` は不要
- `com.apple.security.files.user-selected.read-write` は iOS では不要（`fileImporter`/`fileExporter` が自動処理）
- ネットワーク（翻訳サービス用）は必要

### 4. Entitlements のプラットフォーム分岐

```
// macOS ターゲット
CODE_SIGN_ENTITLEMENTS[sdk=macosx*] = ScreenShotMaker/ScreenShotMaker.entitlements

// iOS ターゲット
CODE_SIGN_ENTITLEMENTS[sdk=iphoneos*] = ScreenShotMaker/ScreenShotMaker-iOS.entitlements
CODE_SIGN_ENTITLEMENTS[sdk=iphonesimulator*] = ScreenShotMaker/ScreenShotMaker-iOS.entitlements
```

## 受け入れ基準

- [ ] Xcode で macOS 向けビルドが引き続き成功する
- [ ] Xcode で iPad Simulator 向けビルドが成功する（コンパイルエラーは後続 issue で修正）
- [ ] Xcode の Destinations に iPad Simulator が表示される
- [ ] iPhone Simulator は表示されない（iPad 専用）
- [ ] macOS 用 Entitlements が既存のまま維持される
- [ ] iOS 用 Entitlements ファイルが作成され、ネットワーク権限が含まれる

## 依存関係

- なし（最初に実施する issue）

## 備考

- この issue 単体ではコンパイルエラーが発生する（AppKit API が iOS で利用不可なため）。#042〜#047 で順次解消する。
- テストターゲットも同様に `SUPPORTED_PLATFORMS` と `IPHONEOS_DEPLOYMENT_TARGET` を設定する必要がある。

## 複雑度

M
