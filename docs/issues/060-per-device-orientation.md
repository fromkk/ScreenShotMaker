# Issue #060: デバイス・スクリーンごとの向き設定

## Phase / Priority
Phase 8 | P2 (Medium)

## 概要

現在、スクリーンの向き (`isLandscape`) はスクリーン単位で全デバイス共通の1つの値として管理されており、デバイスカテゴリごとに異なる向きを設定できない。

例えば「iPhone はポートレート、iPad はランドスケープ」のように、同一スクリーン内でデバイスカテゴリごとに独立した向きを設定できるようにする。

## ユースケース

1. **デバイスごとに向きを変える**
   - iPhone 用スクリーン: Portrait
   - iPad 用スクリーン: Landscape
   - 同一スクリーンで両者が独立して設定できる

2. **スクリーンごとに向きを変える**
   - 1枚目: Portrait（全デバイス）
   - 2枚目: Landscape（全デバイス）
   - または 1枚目 iPhone のみ Landscape など自由な組み合わせ

3. **新規スクリーン作成時の引き継ぎ**
   - 前のスクリーンの全カテゴリの向き設定をコピーする

## 現状の問題

`Screen.isLandscape: Bool` はスクリーン全体で共有される1つのフラグであるため、デバイスカテゴリごとに向きを独立して設定することができない。

UI 上の向きピッカーを変更すると、そのスクリーンを参照するすべてのデバイス（iPhone・iPad）の向きが同時に切り替わってしまう。

## 対象ファイル

- 変更: `ScreenShotMaker/Models/Screen.swift` (`isLandscape: Bool` → `isLandscapeByCategory: [String: Bool]`)
- 変更: `ScreenShotMaker/Models/Project.swift` (`addScreen()` のコピー処理)
- 変更: `ScreenShotMaker/Views/CanvasView.swift` (レンダリング時のデバイスカテゴリを渡す)
- 変更: `ScreenShotMaker/Views/PropertiesPanelView.swift` (向きピッカーのバインディング変更)
- 変更: `ScreenShotMaker/Services/ExportService.swift` (エクスポート時のデバイスカテゴリを渡す)
- 変更: `ScreenShotMaker/Services/VideoExportService.swift` (エクスポート時のデバイスカテゴリを渡す)
- 追加: `ScreenShotMakerTests/Models/ScreenOrientationTests.swift` (新規テスト)

## 実装詳細

### 1. Screen モデルの変更 (Screen.swift)

`fontSizes: [String: Double]` / `fontSize(for:)` / `setFontSize(_:for:)` パターンと同じ設計を採用する。

```swift
// 変更前
var isLandscape: Bool

// 変更後
var isLandscapeByCategory: [String: Bool]

// アクセサー（新規追加）
func isLandscape(for category: DeviceCategory) -> Bool {
    isLandscapeByCategory[category.rawValue] ?? false
}

mutating func setIsLandscape(_ value: Bool, for category: DeviceCategory) {
    isLandscapeByCategory[category.rawValue] = value
}
```

### 2. Codable マイグレーション (Screen.swift)

| 状況 | 処理 |
|------|------|
| 新形式 `isLandscapeByCategory` キーあり | そのままデコード |
| 旧形式 `isLandscape: Bool` のみ | `supportsRotation == true` な全カテゴリ（iPhone・iPad）に値を適用してマイグレーション |
| どちらもなし | `[:]`（全カテゴリ portrait = false） |

`encode(to:)` は `isLandscapeByCategory` のみ書き出す（旧 `isLandscape` キーは書き出さない）。

### 3. init の変更 (Screen.swift)

```swift
// 変更前
init(
    ...
    isLandscape: Bool = false,
    ...
)

// 変更後
init(
    ...
    isLandscapeByCategory: [String: Bool] = [:],
    ...
)
```

### 4. addScreen() の変更 (Project.swift)

```swift
// 変更前
screen = Screen(
    ...
    isLandscape: prev.isLandscape,
    ...
)

// 変更後
screen = Screen(
    ...
    // isLandscapeByCategory は init 後に辞書ごとコピー
    ...
)
screen.isLandscapeByCategory = prev.isLandscapeByCategory
```

`duplicateScreen()` / `copyScreen()` / `pasteScreen()` は Screen を丸ごとコピーするため変更不要。

### 5. レンダリング呼び出し箇所の変更

すべての呼び出しで `screen.isLandscape` → `screen.isLandscape(for: device.category)` に変更する。

| ファイル | 行 | 変数コンテキスト |
|----------|----|-----------------|
| CanvasView.swift | 58-59 | `screenshotPreview(screen:device:)` |
| CanvasView.swift | 270-273 | `if let device = state.selectedDevice` |
| CanvasView.swift | 448-449 | `if let device = state.selectedDevice, let screen = state.selectedScreen` |
| ExportService.swift | 23, 26 | `device: DeviceSize` プロパティ |
| ExportService.swift | 177, 179 | `device: DeviceSize` プロパティ |
| VideoExportService.swift | 141-142 | `device: DeviceSize` ローカル変数 |

### 6. PropertiesPanelView の変更

向きピッカーのバインディングを選択中デバイスカテゴリに連動させる。デバイスタブを切り替えると、そのデバイスの向き設定がピッカーに反映される。

```swift
// 変更前
Picker("Orientation", selection: screen.isLandscape)

// 変更後
let category = state.selectedDevice?.category ?? .iPhone
Picker("Orientation", selection: Binding(
    get: { screen.wrappedValue.isLandscape(for: category) },
    set: { screen.wrappedValue.setIsLandscape($0, for: category) }
))
```

## 受け入れ基準

- [ ] `Screen.isLandscape: Bool` が `isLandscapeByCategory: [String: Bool]` に置き換えられている
- [ ] `isLandscape(for:)` / `setIsLandscape(_:for:)` アクセサーが機能する
- [ ] 向きピッカーが選択中デバイスの向きを表示・変更する
- [ ] デバイスタブ（iPhone ↔ iPad）を切り替えると向きピッカーの表示が更新される
- [ ] iPhone=Portrait / iPad=Landscape のエクスポートが各々正しいピクセルサイズで出力される
- [ ] 新規スクリーン作成時に全カテゴリの向き設定が前のスクリーンからコピーされる
- [ ] 既存の `.shotcraft` ファイルが読み込みエラーなく開ける
- [ ] 旧形式 `isLandscape: true` がマイグレーションにより iPhone・iPad の landscape として反映される
- [ ] 既存テスト（DeviceTypeTests）がパスする
- [ ] 新規テスト（ScreenOrientationTests）がパスする

## 依存関係

- #014 (orientation support) — 完了済み（本 Issue は #014 の拡張）
- #056 (per-device font size) — 同じパターンを参考に設計

## 複雑度

M
