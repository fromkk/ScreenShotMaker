# Issue #008: デバイスフレーム描画

## Phase / Priority
Phase 2 | P2 (Medium)

## 概要

iPhone / iPad / Mac 等のデバイスモックアップフレームをスクリーンショットに重畳して表示する。`Screen.showDeviceFrame` トグルと連動。

## 対象ファイル

- 新規: `ScreenShotMaker/Models/DeviceFrame.swift`
- 新規: `ScreenShotMaker/Resources/DeviceFrames/` (フレーム画像アセット)
- 変更: `ScreenShotMaker/Views/CanvasView.swift` (フレーム描画追加)
- 変更: `project.yml` (リソースパス追加)

## 実装詳細

1. **DeviceFrame モデルの作成**
   ```swift
   struct DeviceFrame {
       let deviceCategory: DeviceCategory
       let imageName: String       // アセット名
       let screenInset: EdgeInsets // フレーム内のスクリーン領域オフセット
       let frameAspectRatio: CGSize
   }
   ```

2. **フレーム画像の準備**
   - iPhone: ノッチ/Dynamic Island デバイスフレーム（汎用）
   - iPad: ベゼルフレーム（汎用）
   - Mac: MacBook フレーム
   - SVG または 高解像度 PNG で作成
   - Assets.xcassets に追加

3. **CanvasView のフレーム描画**
   - `screen.showDeviceFrame == true` の場合:
     - スクリーンショット画像の上にフレーム画像をオーバーレイ
     - `screenInset` に基づいてスクリーンショットの位置・サイズを調整
   - `false` の場合: 現行のフレームなし表示

4. **DeviceSize とフレームの関連付け**
   - `DeviceSize` に `var frame: DeviceFrame?` computed property を追加
   - カテゴリごとに適切なフレームを返す

## 受け入れ基準

- [ ] 「Show Device Frame」トグル ON でデバイスフレームが表示される
- [ ] OFF でフレームなしの表示に戻る
- [ ] iPhone / iPad / Mac のフレームがそれぞれ適切に表示される
- [ ] スクリーンショットがフレーム内のスクリーン領域に正しく配置される
- [ ] ズーム操作でフレームも連動してリサイズされる
- [ ] エクスポート時にフレームが含まれる（#004 完了後）

## 依存関係

- #002 が完了していること（画像表示が前提）

## 複雑度

L
