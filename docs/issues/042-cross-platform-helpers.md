# Issue #042: クロスプラットフォームヘルパーの新設

## Status
Open

## Phase / Priority
Phase 8 (iPad対応) | P0 (Blocker)

## 概要

macOS（AppKit）と iOS（UIKit）で異なる画像・カラー・フォント API を吸収するクロスプラットフォームヘルパーを新設する。これにより、各ビュー・サービスファイルでの `#if` 分岐を最小限に抑え、`PlatformImage` や `Color.platformSeparator` といった統一 API を通じてプラットフォーム差異を解消する。

## 現状の問題

### NSImage / Image(nsImage:) — 計13箇所
| ファイル | 箇所数 | 用途 |
|---------|--------|------|
| `CanvasView.swift` | 4 | 背景画像・スクリーンショット画像の表示 |
| `PropertiesPanelView.swift` | 4 | 背景画像・スクリーンショット画像のプレビュー |
| `ExportService.swift` | 5 | ExportableScreenView での画像表示 + `renderer.nsImage` |

### Color(nsColor:) — 計11箇所
| ファイル | 箇所数 | 使用色 |
|---------|--------|--------|
| `CanvasView.swift` | 1 | `.windowBackgroundColor` |
| `PropertiesPanelView.swift` | 7 | `.controlColor`, `.controlBackgroundColor`, `.separatorColor` ×5 |
| `TemplateGalleryView.swift` | 1 | `.separatorColor` |
| `SidebarView.swift`（ContentView内） | 1 | `.separatorColor` |
| `BackgroundStyle.swift` | 1 | `NSColor(self).usingColorSpace(.sRGB)` in `Color.toHex()` |

### NSFontManager — 1箇所
| ファイル | 用途 |
|---------|------|
| `PropertiesPanelView.swift` | `NSFontManager.shared.availableFontFamilies.sorted()` |

## 対象ファイル

- 新規: `ScreenShotMaker/Utils/PlatformCompatibility.swift`

## 実装詳細

### 1. PlatformImage typealias と Image イニシャライザ

```swift
#if canImport(AppKit)
import AppKit
public typealias PlatformImage = NSImage
#elseif canImport(UIKit)
import UIKit
public typealias PlatformImage = UIImage
#endif

extension PlatformImage {
    /// Data から PlatformImage を生成する共通イニシャライザ
    convenience init?(imageData: Data) {
        #if canImport(AppKit)
        self.init(data: imageData)
        #elseif canImport(UIKit)
        self.init(data: imageData)
        #endif
    }
}

extension Image {
    /// PlatformImage から SwiftUI Image を生成
    init(platformImage: PlatformImage) {
        #if canImport(AppKit)
        self.init(nsImage: platformImage)
        #elseif canImport(UIKit)
        self.init(uiImage: platformImage)
        #endif
    }
}
```

### 2. セマンティックカラー定数

```swift
extension Color {
    /// ウィンドウ/画面の背景色
    static var platformBackground: Color {
        #if canImport(AppKit)
        Color(nsColor: .windowBackgroundColor)
        #elseif canImport(UIKit)
        Color(uiColor: .systemBackground)
        #endif
    }

    /// コントロールの背景色
    static var platformControlBackground: Color {
        #if canImport(AppKit)
        Color(nsColor: .controlBackgroundColor)
        #elseif canImport(UIKit)
        Color(uiColor: .systemBackground)
        #endif
    }

    /// コントロール色
    static var platformControl: Color {
        #if canImport(AppKit)
        Color(nsColor: .controlColor)
        #elseif canImport(UIKit)
        Color(uiColor: .secondarySystemBackground)
        #endif
    }

    /// セパレータ色
    static var platformSeparator: Color {
        #if canImport(AppKit)
        Color(nsColor: .separatorColor)
        #elseif canImport(UIKit)
        Color(uiColor: .separator)
        #endif
    }
}
```

### 3. Color.toHex() のクロスプラットフォーム実装

`BackgroundStyle.swift` にある既存の `Color.toHex()` を `PlatformCompatibility.swift` に移設、またはインラインで `#if` 分岐:

```swift
extension Color {
    func toHex() -> String {
        #if canImport(AppKit)
        guard let nsColor = NSColor(self).usingColorSpace(.sRGB) else { return "#000000" }
        let r = Int(round(nsColor.redComponent * 255))
        let g = Int(round(nsColor.greenComponent * 255))
        let b = Int(round(nsColor.blueComponent * 255))
        #elseif canImport(UIKit)
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0
        UIColor(self).getRed(&r, green: &g, blue: &b, alpha: nil)
        let r = Int(round(r * 255))
        let g = Int(round(g * 255))
        let b = Int(round(b * 255))
        #endif
        return String(format: "#%02X%02X%02X", r, g, b)
    }
}
```

### 4. フォントファミリー一覧の取得

```swift
enum FontHelper {
    static var availableFontFamilies: [String] {
        #if canImport(AppKit)
        NSFontManager.shared.availableFontFamilies.sorted()
        #elseif canImport(UIKit)
        UIFont.familyNames.sorted()
        #endif
    }
}
```

## 受け入れ基準

- [ ] `PlatformCompatibility.swift` が作成され、macOS / iOS 両方でコンパイルできる
- [ ] `PlatformImage` typealias が `NSImage`（macOS）/ `UIImage`（iOS）に解決される
- [ ] `Image(platformImage:)` が両プラットフォームで動作する
- [ ] `Color.platformSeparator` / `.platformBackground` / `.platformControlBackground` / `.platformControl` が両プラットフォームで適切な色を返す
- [ ] `Color.toHex()` が両プラットフォームで同じ結果を返す
- [ ] `FontHelper.availableFontFamilies` が両プラットフォームでフォント一覧を返す
- [ ] 既存の macOS ビルドに影響がない

## 依存関係

- #041 が完了していること（iOS ターゲット設定が必要）

## 備考

- このヘルパー作成後、#043〜#047 で各ファイルの `NSImage` / `Color(nsColor:)` / `NSFontManager` 参照をヘルパー経由に置換する。
- `NSImage` と `UIImage` は共に `Data` からの初期化と基本プロパティ（`.size`）を持つため、`PlatformImage` として統一しやすい。
- `NSItemProvider` は Foundation クラスなので両プラットフォームで利用可能、ヘルパー不要。
- `MagnifyGesture` は iOS 17+ で利用可能、ヘルパー不要。

## 複雑度

M
