# テストプラン: モデル層単体テスト

対象ディレクトリ: `ScreenShotMakerTests/Models/`

---

## ScreenTests.swift

| テスト名 | テスト対象 | 期待動作 |
|---------|----------|---------|
| `testScreenDefaultValues` | `Screen()` のデフォルト値 | `name == "New Screen"`, `layoutPreset == .textTop`, `title == ""`, `fontSize == 28`, `textColorHex == "#FFFFFF"`, `showDeviceFrame == true` |
| `testScreenCodableRoundTrip` | Screen の JSON encode → decode | デコード後の Screen が元と全フィールド一致 |
| `testScreenImageDataStorage` | `screenshotImageData` への Data 格納 | Data を設定 → 取得で同一バイト列が返る |
| `testScreenCustomInit` | カスタム初期化 | 指定した値で全フィールドが初期化される |

## ProjectStateTests.swift

| テスト名 | テスト対象 | 期待動作 |
|---------|----------|---------|
| `testInitialState` | `ProjectState()` の初期状態 | `project.screens.count == 1`, `selectedScreenID == screens[0].id` |
| `testAddScreen` | `addScreen()` | `screens.count` が 1 増加、`selectedScreenID` が新スクリーンの ID |
| `testDeleteScreen` | `deleteScreen(_:)` | `screens.count` が 1 減少、削除されたスクリーンが存在しない |
| `testDeleteSelectedScreen` | 選択中のスクリーンを削除 | `selectedScreenID` が残りの先頭に切り替わる |
| `testDeleteLastScreen` | 最後の 1 件を削除 | `screens.count == 0`, `selectedScreenID == nil` |
| `testMoveScreen` | `moveScreen(from:to:)` | スクリーンの順序が入れ替わる |
| `testSelectedScreenComputed` | `selectedScreen` computed property | `selectedScreenID` に対応する Screen が返る |
| `testSelectedScreenNil` | `selectedScreenID` が nil の場合 | `selectedScreen` が `screens.first` を返す |
| `testSelectedDeviceComputed` | `selectedDevice` | `selectedDeviceIndex` に対応する DeviceSize が返る |
| `testSelectedDeviceOutOfBounds` | `selectedDeviceIndex` が範囲外 | `selectedDevice` が `nil` |
| `testSelectedLanguageComputed` | `selectedLanguage` | `selectedLanguageIndex` に対応する Language が返る |

## BackgroundStyleTests.swift

| テスト名 | テスト対象 | 期待動作 |
|---------|----------|---------|
| `testSolidColorCodable` | `.solidColor(HexColor("#FF0000"))` の encode → decode | 同じ hex 値が復元される |
| `testGradientCodable` | `.gradient(startColor:endColor:)` の encode → decode | 両方の hex 値が復元される |
| `testImageCodable` | `.image(path: "test.png")` の encode → decode | パスが復元される |
| `testHexColorToSwiftUIColor` | `HexColor("#FF0000").color` | 赤色の Color が返る (r=1.0, g=0.0, b=0.0) |
| `testHexColorWithHash` | `Color(hex: "#00FF00")` | 緑色が返る |
| `testHexColorWithoutHash` | `Color(hex: "0000FF")` | 青色が返る |

## DeviceTypeTests.swift

| テスト名 | テスト対象 | 期待動作 |
|---------|----------|---------|
| `testAllSizesCount` | `DeviceSize.allSizes` | 26 件以上のデバイスが含まれる |
| `testIPhoneSizesCount` | `DeviceSize.iPhoneSizes` | 8 件 |
| `testIPadSizesCount` | `DeviceSize.iPadSizes` | 5 件 |
| `testCategoryFilter` | `DeviceSize.sizes(for: .iPhone)` | 全て `.iPhone` カテゴリ |
| `testLandscapeDimensions` | `device.landscapeWidth / landscapeHeight` | `landscapeWidth == portraitHeight`, `landscapeHeight == portraitWidth` |
| `testDeviceSizeUniqueness` | 全デバイスの `id` | 重複なし |
| `testDeviceCategoryDisplayName` | `DeviceCategory.iPhone.displayName` | "iPhone" |
| `testDeviceCategoryIconName` | `DeviceCategory.iPhone.iconName` | "iphone" |

## LayoutPresetTests.swift

| テスト名 | テスト対象 | 期待動作 |
|---------|----------|---------|
| `testAllCasesCount` | `LayoutPreset.allCases` | 5 件 |
| `testCodableRoundTrip` | 各 case の encode → decode | 同じ case が復元される |
| `testDisplayName` | 各 case の `displayName` | 非空文字列 |
| `testRawValues` | 各 case の `rawValue` | "textTop", "textOverlay", "textBottom", "textOnly", "screenshotOnly" |
