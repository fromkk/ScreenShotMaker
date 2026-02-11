# Issue #056: デバイスカテゴリごとのフォントサイズ管理

## Phase / Priority
Phase 7 | P2 (Medium)

## 概要

現在、各 Screen には1つの `fontSize: Double` しかなく、全デバイス（iPhone / iPad / Mac 等）で同じフォントサイズが使用される。デバイスカテゴリごとに異なるフォントサイズを設定できるようにし、各デバイスに最適なテキスト表示を実現する。

## ユースケース

1. iPhone 6.9" 用にフォントサイズ 96 を設定
2. iPad 用にフォントサイズ 120 を設定（画面が大きいため）
3. プレビュー・エクスポート時に各デバイスに対応するフォントサイズが使用される
4. デバイスを切り替えるとプロパティパネルのフォントサイズスライダーが連動して切り替わる

## 現状の問題

1. `Screen.fontSize: Double` が1つしかなく、全デバイスカテゴリで共有される
2. iPhone で最適なフォントサイズが iPad では小さすぎる／大きすぎる場合がある
3. デバイスごとにフォントサイズを調整するにはスクリーンを別々に作成する必要があり、テキストや背景の変更が二重管理になる

## 対象ファイル

- 変更: `ScreenShotMaker/Models/Screen.swift` (`fontSize: Double` → `fontSizes: [String: Double]` 辞書に変更)
- 変更: `ScreenShotMaker/Views/CanvasView.swift` (選択中デバイスに対応するフォントサイズを使用)
- 変更: `ScreenShotMaker/Views/PropertiesPanelView.swift` (フォントサイズ設定が選択中デバイスのカテゴリに紐づく)
- 変更: `ScreenShotMaker/Services/ExportService.swift` (エクスポート時にデバイスカテゴリに対応するフォントサイズを使用)
- 変更: `ScreenShotMaker/Models/Project.swift` (`addScreen()` で `fontSizes` 辞書をコピー)
- 変更: `ScreenShotMaker/Models/Template.swift` (`fontSize` パラメータをそのまま利用)
- 変更: `ScreenShotMakerTests/Models/ScreenTests.swift` (テスト更新・マイグレーションテスト追加)
- 変更: `ScreenShotMakerTests/Models/ProjectStateTests.swift` (テスト更新)

## 実装詳細

1. **Screen モデルの変更**
   - `fontSize: Double` → `fontSizes: [String: Double]`
   - キーは `DeviceCategory.rawValue`（"iPhone", "iPad", "mac" 等）
   - ヘルパーメソッド:
     ```swift
     func fontSize(for category: DeviceCategory) -> Double {
         fontSizes[category.rawValue] ?? Screen.defaultFontSize
     }

     mutating func setFontSize(_ size: Double, for category: DeviceCategory) {
         fontSizes[category.rawValue] = size
     }
     ```
   - デフォルトフォントサイズ定数: `static let defaultFontSize: Double = 96`
   - `init` では `fontSize: Double = 96` パラメータを維持し、内部で全カテゴリのデフォルト値として使用

2. **Codable マイグレーション**
   - `CodingKeys` に `fontSizes` を追加
   - デコード時:
     - 新形式: `fontSizes: [String: Double]` をデコード
     - 旧形式フォールバック: `fontSize: Double` をデコードし、全カテゴリのデフォルト値として使用
   - エンコード時: `fontSizes` のみ保存

3. **CanvasView の更新**
   - `screen.fontSize` → `screen.fontSize(for: device.category)` に変更
   - `device` は `textContent(screen:device:)` の引数として既に渡されている

4. **PropertiesPanelView の更新**
   - フォントサイズスライダー/テキストフィールドのバインディングを `screen.fontSize(for:)` / `screen.setFontSize(_:for:)` に変更
   - 選択中デバイスが変わるとスライダーの値も連動して切り替わる

5. **ExportService の更新**
   - `screen.fontSize` → `screen.fontSize(for: device.category)` に変更

6. **Project.addScreen() の更新**
   - `fontSize: prev.fontSize` → `fontSizes` 辞書をまるごとコピー

7. **Template の更新**
   - `Screen` の `init(fontSize:)` パラメータは互換性のため維持するため、テンプレートの変更は不要

## 受け入れ基準

- [ ] iPhone 選択時に設定したフォントサイズは iPhone デバイスのプレビュー・エクスポートにのみ使用される
- [ ] iPad 選択時に設定したフォントサイズは iPad デバイスのプレビュー・エクスポートにのみ使用される
- [ ] デバイスを切り替えると、そのデバイスカテゴリに紐づいたフォントサイズがスライダーに表示される
- [ ] 既存プロジェクトファイルを開いた際、旧 `fontSize` が正しくマイグレーションされる
- [ ] 新規スクリーン追加時、前のスクリーンの `fontSizes` 辞書が正しくコピーされる
- [ ] プレビュー・エクスポートともにデバイスごとのフォントサイズが正しく反映される
- [ ] サブタイトルのフォントサイズ（タイトルの 0.6 倍）もデバイスごとに連動する

## 依存関係

- Issue #034 (デバイスごとのスクリーンショット画像管理) — 同じ `DeviceCategory` キーパターンを再利用

## 複雑度

Medium — `screenshotImages` の既存パターンに倣った辞書化のため、設計はシンプル。変更箇所は多いがパターンが統一的。
