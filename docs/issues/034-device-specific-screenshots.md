# Issue #034: デバイスごとのスクリーンショット画像管理

## Phase / Priority
Phase 7 | P1 (High)

## 概要

現在、各 Screen には1つの `screenshotImageData` しかなく、全デバイス（iPhone / iPad / Mac 等）で同じスクリーンショット画像が使用される。実際の App Store Connect 提出では iPhone と iPad で異なるスクリーンショットを使用するため、デバイスごとに別々の画像を設定できるようにする。

## ユースケース

1. iPhone 6.9" のみでスクリーンを作成し、各画面のレイアウト・テキスト・背景を設定
2. iPad を追加するとスクリーン画像以外の全情報がコピーされる（#033 の動作）
3. iPhone 用と iPad 用で別々のスクリーンショット画像を設定できる
4. エクスポート時は各デバイスに対応する画像が使用される

## 現状の問題

1. `Screen.screenshotImageData: Data?` が1つしかなく、全デバイスで共有される
2. iPhone 用の縦長スクリーンショットが iPad のエクスポートにもそのまま使われ、表示が不適切になる
3. デバイスごとに画像を差し替えるにはスクリーンを別々に作成する必要があり、テキストや背景の変更が二重管理になる

## 対象ファイル

- 変更: `ScreenShotMaker/Models/Screen.swift` (`screenshotImageData` → `screenshotImages` 辞書に変更)
- 変更: `ScreenShotMaker/Views/CanvasView.swift` (選択中デバイスに対応する画像を表示)
- 変更: `ScreenShotMaker/Views/PropertiesPanelView.swift` (画像設定が選択中デバイスに紐づく)
- 変更: `ScreenShotMaker/Services/ExportService.swift` (エクスポート時にデバイスカテゴリに対応する画像を使用)

## 実装詳細

1. **Screen モデルの変更**
   - `screenshotImageData: Data?` → `screenshotImages: [String: Data]`
   - キーは `DeviceCategory.rawValue`（"iPhone", "iPad", "mac" 等）
   - ヘルパーメソッド:
     ```swift
     func screenshotImageData(for category: DeviceCategory) -> Data? {
         screenshotImages[category.rawValue]
     }

     mutating func setScreenshotImageData(_ data: Data?, for category: DeviceCategory) {
         if let data {
             screenshotImages[category.rawValue] = data
         } else {
             screenshotImages.removeValue(forKey: category.rawValue)
         }
     }
     ```
   - 後方互換: 既存の `screenshotImageData` キーがある場合、全カテゴリのデフォルト画像として `screenshotImages["iPhone"]` にマイグレーション

2. **CanvasView の更新**
   - `screen.screenshotImageData` → `screen.screenshotImageData(for: device.category)` に変更
   - ドラッグ&ドロップ時も選択中デバイスのカテゴリに紐づけて保存

3. **PropertiesPanelView の更新**
   - Screenshot Image セクションで選択中デバイスのカテゴリに対応する画像を表示・編集
   - 現在どのデバイスの画像を編集中か表示（例: "Screenshot (iPhone)"）

4. **ExportService の更新**
   - `exportScreen` / `batchExport` で `device.category` に対応する画像を使用
   - 該当カテゴリに画像がない場合のフォールバック: 他のカテゴリの画像を使用、またはなしで描画

5. **Codable 後方互換**
   - デコード時: `screenshotImageData`（旧: Data?）があれば `screenshotImages["iPhone"]` にマイグレーション
   - エンコード時: `screenshotImages` のみ保存

## 受け入れ基準

- [ ] iPhone 選択時に設定した画像は iPhone デバイスのエクスポートにのみ使用される
- [ ] iPad 選択時に設定した画像は iPad デバイスのエクスポートにのみ使用される
- [ ] デバイスを切り替えると、そのデバイスカテゴリに紐づいた画像が表示される
- [ ] ドラッグ&ドロップで追加した画像は選択中デバイスのカテゴリに紐づく
- [ ] 既存プロジェクトファイルを開いた際、旧 `screenshotImageData` が正しくマイグレーションされる
- [ ] プレビュー・エクスポートともにデバイスごとの画像が正しく反映される

## 依存関係

なし

## 複雑度

M
