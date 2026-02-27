# Issue #059: デバイスフレーム角丸部分の白線アーティファクト

## Phase / Priority
Phase 5 | P2 (Medium)

## 概要

デバイスフレームのカラーをカスタム色（特に暗い色）に設定し、グラデーション背景と組み合わせると、フレームの角丸部分に白い細線（白線アーティファクト）が出現する。

## 現状の問題

`DeviceFrame.swift` の `framedContent(spec:)` 内で、`ZStack` の描画順序が以下のようになっている。

1. 外側の `RoundedRectangle`（フレーム色で塗りつぶし）を最背面に描画
2. その上に `screenshotContent`（`.fill(.white)` の背景を持つ）を `clipShape(RoundedRectangle(cornerRadius: innerCorner))` でクリッピングして重ねる

SwiftUI は `clipShape` のクリップ境界をアンチエイリアス処理するため、角丸の輪郭に沿って半透明の白ピクセルが発生する。このピクセルがフレームカラーの上に漏れ出し、目に見える白線として現れる。

### 再現条件

- デバイスフレームを有効にする
- フレームカラーを暗い色（例: `#1F1F1F`）に設定
- 背景をグラデーションに設定
- → フレーム角丸部分に白い輪郭線が出現する

### 問題の根本原因

1. **描画順序の問題（主因）**: フレーム色のレイヤーが背面にあり、白背景を持つ `screenshotContent` のクリップエッジが上に重なる。クリップ境界のアンチエイリアス半透明白ピクセルがフレームカラーの上に露出する。
2. **白背景の存在**: `CanvasView.swift` の `screenshotContent` が `RoundedRectangle(cornerRadius: 8).fill(.white)` を使っており、`ExportService.swift` も同様に `cornerRadius: 16` で `.fill(.white)` を持つ。この白背景が角丸クリップのアンチエイリアス領域で白ピクセルを生成する。
3. **コーナー半径の不一致**: `innerCorner = outerCorner - bezel` で算出された内側コーナー半径と、`screenshotContent` にハードコードされた `8` / `16` pt のコーナー半径が一致しておらず、コーナー形状のずれが生じる。

## 対象ファイル

- 修正: `ScreenShotMaker/Models/DeviceFrame.swift` — `framedContent(spec:)` の描画順序変更
- 修正: `ScreenShotMaker/Views/CanvasView.swift` — `screenshotContent` の白背景除去
- 修正: `ScreenShotMaker/Services/ExportService.swift` — `screenshotContent` の白背景除去

## 実装詳細

### 1. `DeviceFrame.swift` — フレームをドーナツ形状で前面描画

現在の `ZStack` 構造（フレームが背面）を変更し、フレームを **Canvas を使ったドーナツ形状** でコンテンツの前面に重ねる。

```swift
private func framedContent(spec: DeviceFrameSpec) -> some View {
    let bezel = screenWidth * spec.bezelRatio
    let outerWidth = screenWidth + bezel * 2
    let outerHeight = screenHeight + bezel * 2
    let outerCorner = screenWidth * spec.cornerRadiusRatio
    let innerCorner = max(outerCorner - bezel, 0)

    return ZStack {
        // スクリーンコンテンツ（クリッピングはそのまま）
        content
            .frame(width: screenWidth, height: screenHeight)
            .clipShape(RoundedRectangle(cornerRadius: innerCorner))

        // フレームをドーナツ形状で前面に描画（クリップ境界の白ピクセルを覆う）
        Canvas { ctx, size in
            let outer = Path(
                roundedRect: CGRect(origin: .zero, size: size),
                cornerRadius: outerCorner
            )
            let inner = Path(
                roundedRect: CGRect(
                    x: bezel, y: bezel,
                    width: screenWidth, height: screenHeight
                ),
                cornerRadius: innerCorner
            )
            var donut = outer
            donut.addPath(inner)
            ctx.fill(donut, with: .color(spec.frameColor),
                     style: FillStyle(eoFill: true))
        }
        .frame(width: outerWidth, height: outerHeight)

        // Dynamic Island（iPhone のみ）
        // ...（既存コードそのまま）

        // Home Indicator
        // ...（既存コードそのまま）
    }
    .frame(width: outerWidth, height: outerHeight)
}
```

**ポイント**: `FillStyle(eoFill: true)` (Even-Odd ルール) によりドーナツの穴（スクリーン領域）を透明にしつつ、外枠はフレームカラーで塗りつぶす。これにより `clipShape` のアンチエイリアス白ピクセルがフレームカラーで覆われ、白線が消える。

### 2. `CanvasView.swift` — `screenshotContent` の白背景を除去

```swift
// 変更前
let screenshotContent = RoundedRectangle(cornerRadius: 8)
    .fill(.white)
    .overlay { innerContent }

// 変更後
let screenshotContent = Color.clear
    .overlay { innerContent }
```

デバイスフレーム内では白背景は不要。フレームなしの場合も背景色はキャンバス側で担保される。

### 3. `ExportService.swift` — エクスポート用 `screenshotContent` の白背景を除去

```swift
// 変更前
let screenshotContent = RoundedRectangle(cornerRadius: 16)
    .fill(.white)
    .overlay { ... }

// 変更後（白背景を Color.clear に変更）
let screenshotContent = Color.clear
    .overlay { ... }
```

## 受け入れ基準

- [ ] フレームカラーをカスタム色（#1F1F1F 等）に設定してもフレーム角丸に白線が出ない
- [ ] グラデーション背景 + デバイスフレーム + カスタムフレーム色の組み合わせで白線が出ない
- [ ] フレームなし表示に影響がない
- [ ] エクスポート画像でも白線アーティファクトが出ない
- [ ] Dynamic Island・Home Indicator の表示に影響がない

## 依存関係

- Issue #027 デバイスフレームのカスタマイズ（`DeviceFrameConfig` の仕組みを使用）
- Issue #028 Dynamic Island カスタマイズ
