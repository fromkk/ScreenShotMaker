# Issue #055: デバイスカテゴリ別の回転可否制御

## Status
Open

## Phase / Priority
Phase 3 (デバイス対応) | P1 (High)

## 概要

デバイスカテゴリ（`DeviceCategory`）に回転可否（`supportsRotation`）プロパティを追加し、iPhone / iPad では回転可能（Portrait ↔ Landscape 切り替え可）、Mac / Apple TV / Apple Vision Pro / Apple Watch では固定（`portraitWidth` × `portraitHeight` に格納された値をそのまま使用）として扱う。

## 現状

- `DeviceSize` の `portraitWidth` / `portraitHeight` にデバイスの基本サイズが格納されている
- `landscapeWidth` / `landscapeHeight` は computed property で単純に幅と高さを入れ替えている
- Mac（2880×1800 など）、Apple TV（3840×2160 など）、Apple Vision Pro（3840×2160）は `portraitWidth > portraitHeight` で定義されており、実質的には横長のサイズ
- `Screen.isLandscape = true` にすると **全デバイスで** `landscapeWidth` / `landscapeHeight` が使われるため、Mac / Apple TV / Vision Pro では **幅と高さが逆転して縦長になる** という不具合が発生する
- 例: iPhone で Landscape を選択 → Mac や Apple TV のプレビュー・エクスポートが意図せず縦長になる

## 対象ファイル

- 変更: `ScreenShotMaker/Models/DeviceType.swift`（`supportsRotation` プロパティ追加、`effectiveWidth` / `effectiveHeight` メソッド追加）
- 変更: `ScreenShotMaker/Views/CanvasView.swift`（幅・高さ参照を `effectiveWidth` / `effectiveHeight` に統一）
- 変更: `ScreenShotMaker/Services/ExportService.swift`（同上）
- 変更: `ScreenShotMaker/Views/PropertiesPanelView.swift`（回転不可デバイス選択時に Orientation ピッカーを非表示）
- 追加: `ScreenShotMakerTests/Models/DeviceTypeTests.swift`（`supportsRotation` と `effectiveWidth` / `effectiveHeight` のテスト）

## 実装詳細

### 1. `DeviceCategory` に `supportsRotation` computed property を追加

`DeviceType.swift` の `DeviceCategory` enum に以下を追加:

```swift
var supportsRotation: Bool {
    switch self {
    case .iPhone, .iPad:
        return true
    case .mac, .appleWatch, .appleTV, .appleVisionPro:
        return false
    }
}
```

- iPhone / iPad: ユーザーが Portrait ↔ Landscape を切り替え可能
- Mac / Apple TV / Vision Pro: 元々横長で定義されており、回転の概念がない
- Apple Watch: 回転の概念がないため `false`

### 2. `DeviceSize` に `effectiveWidth` / `effectiveHeight` メソッドを追加

`DeviceType.swift` の `DeviceSize` 構造体に以下のメソッドを追加:

```swift
func effectiveWidth(isLandscape: Bool) -> Int {
    if category.supportsRotation && isLandscape {
        return landscapeWidth
    }
    return portraitWidth
}

func effectiveHeight(isLandscape: Bool) -> Int {
    if category.supportsRotation && isLandscape {
        return landscapeHeight
    }
    return portraitHeight
}
```

- `supportsRotation == true` かつ `isLandscape == true` の場合のみ幅と高さを入れ替える
- それ以外は常に `portraitWidth` / `portraitHeight` をそのまま返す
- Mac (2880×1800) は `isLandscape = true` でも 2880×1800 のまま維持される

### 3. `CanvasView` の幅・高さ参照を統一

`CanvasView.swift` の以下3箇所を `effectiveWidth` / `effectiveHeight` に置換:

**`screenshotPreview` 内（L57-58）:**
```swift
// Before
let w = screen.isLandscape ? device.landscapeWidth : device.portraitWidth
let h = screen.isLandscape ? device.landscapeHeight : device.portraitHeight

// After
let w = device.effectiveWidth(isLandscape: screen.isLandscape)
let h = device.effectiveHeight(isLandscape: screen.isLandscape)
```

**デバイスフレーム描画部分（L219-222）:**
```swift
// Before
let frameW = Double(screen.isLandscape ? device.landscapeWidth : device.portraitWidth) * effectiveZoom * 0.15 * 0.7
let frameH = Double(screen.isLandscape ? device.landscapeHeight : device.portraitHeight) * effectiveZoom * 0.15 * 0.7

// After
let frameW = Double(device.effectiveWidth(isLandscape: screen.isLandscape)) * effectiveZoom * 0.15 * 0.7
let frameH = Double(device.effectiveHeight(isLandscape: screen.isLandscape)) * effectiveZoom * 0.15 * 0.7
```

**ボトムバーのサイズ表示（L337-338）:**
```swift
// Before
let w = screen.isLandscape ? device.landscapeWidth : device.portraitWidth
let h = screen.isLandscape ? device.landscapeHeight : device.portraitHeight

// After
let w = device.effectiveWidth(isLandscape: screen.isLandscape)
let h = device.effectiveHeight(isLandscape: screen.isLandscape)
```

### 4. `ExportService` の幅・高さ参照も統一

`ExportService.swift` の以下2箇所を同様に置換:

**`exportWidth` / `exportHeight`（L20-25）:**
```swift
// Before
private var exportWidth: CGFloat {
    CGFloat(screen.isLandscape ? device.landscapeWidth : device.portraitWidth)
}
private var exportHeight: CGFloat {
    CGFloat(screen.isLandscape ? device.landscapeHeight : device.portraitHeight)
}

// After
private var exportWidth: CGFloat {
    CGFloat(device.effectiveWidth(isLandscape: screen.isLandscape))
}
private var exportHeight: CGFloat {
    CGFloat(device.effectiveHeight(isLandscape: screen.isLandscape))
}
```

**デバイスフレーム描画部分（L160-163）:**
```swift
// Before
let screenW = CGFloat(screen.isLandscape ? device.landscapeWidth : device.portraitWidth) * 0.7
let screenH = CGFloat(screen.isLandscape ? device.landscapeHeight : device.portraitHeight) * 0.7

// After
let screenW = CGFloat(device.effectiveWidth(isLandscape: screen.isLandscape)) * 0.7
let screenH = CGFloat(device.effectiveHeight(isLandscape: screen.isLandscape)) * 0.7
```

### 5. `PropertiesPanelView` で Orientation ピッカーの表示制御

回転不可デバイスが選択されている場合、Orientation ピッカーを非表示にする:

```swift
// Before
Picker("Orientation", selection: screen.isLandscape) {
    Label("Portrait", systemImage: "rectangle.portrait").tag(false)
    Label("Landscape", systemImage: "rectangle").tag(true)
}
.pickerStyle(.segmented)

// After
if state.selectedDevice?.category.supportsRotation ?? true {
    Picker("Orientation", selection: screen.isLandscape) {
        Label("Portrait", systemImage: "rectangle.portrait").tag(false)
        Label("Landscape", systemImage: "rectangle").tag(true)
    }
    .pickerStyle(.segmented)
}
```

### 6. テストの追加

`ScreenShotMakerTests/Models/DeviceTypeTests.swift` を新規作成:

```swift
@Test("supportsRotation returns true for iPhone and iPad")
func supportsRotation_iPhoneiPad() {
    #expect(DeviceCategory.iPhone.supportsRotation == true)
    #expect(DeviceCategory.iPad.supportsRotation == true)
}

@Test("supportsRotation returns false for Mac, TV, Watch, Vision Pro")
func supportsRotation_fixedDevices() {
    #expect(DeviceCategory.mac.supportsRotation == false)
    #expect(DeviceCategory.appleTV.supportsRotation == false)
    #expect(DeviceCategory.appleWatch.supportsRotation == false)
    #expect(DeviceCategory.appleVisionPro.supportsRotation == false)
}

@Test("effectiveWidth swaps for iPhone in landscape")
func effectiveWidth_iPhoneLandscape() {
    let device = DeviceSize.iPhoneSizes[0] // iPhone 6.9"
    #expect(device.effectiveWidth(isLandscape: false) == device.portraitWidth)
    #expect(device.effectiveWidth(isLandscape: true) == device.landscapeWidth)
}

@Test("effectiveWidth does NOT swap for Mac in landscape")
func effectiveWidth_macLandscape() {
    let device = DeviceSize.macSizes[0] // Mac 2880×1800
    #expect(device.effectiveWidth(isLandscape: false) == 2880)
    #expect(device.effectiveWidth(isLandscape: true) == 2880) // NOT swapped
}

@Test("effectiveWidth does NOT swap for Apple TV in landscape")
func effectiveWidth_tvLandscape() {
    let device = DeviceSize.tvSizes[0] // Apple TV 4K
    #expect(device.effectiveWidth(isLandscape: false) == 3840)
    #expect(device.effectiveWidth(isLandscape: true) == 3840) // NOT swapped
}
```

## 設計判断

| 選択肢 | 採用 | 理由 |
|--------|------|------|
| `DeviceSize` に `effectiveWidth` / `effectiveHeight` を追加 | ✅ | 全箇所で同じロジックを繰り返すのを避け、回転判定を一箇所に集約できる |
| `Screen.isLandscape` を変更しない | ✅ | 既存の Codable 互換性を維持。デバイス側で回転可否を制御する |
| 回転不可デバイスでは Orientation ピッカーを非表示 | ✅ | disabled より非表示の方が意図が明確。ユーザーが無意味な操作をしない |
| Apple Watch も `supportsRotation = false` | ✅ | Watch に Portrait / Landscape の概念がない |

## 互換性

- `Screen.isLandscape` プロパティ自体は変更しないため、保存済みプロジェクトファイルとの互換性は維持される
- 既存テストで `screen.isLandscape` を直接テストしているケースも、`Screen` のプロパティには影響がないためそのまま通る
- `effectiveWidth` / `effectiveHeight` は新規メソッドのため、既存コードに副作用はない

## 関連 Issue

- #014 Orientation Support（Portrait / Landscape 切替の基本実装）
- #021 Landscape Device Frame Rotation（デバイスフレームの向き対応）
