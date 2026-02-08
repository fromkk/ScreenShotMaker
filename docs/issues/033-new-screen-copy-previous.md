# Issue #033: 新規スクリーン作成時に前のスクリーンの情報をコピー

## Phase / Priority
Phase 7 | P2 (Medium)

## 概要

新しいスクリーンを作成した際、現在はデフォルト値（汎用的なタイトル・サブタイトル、デフォルトグラデーション背景等）が設定される。実際の運用では連続するスクリーンは同じスタイル（背景、フォント、テキストカラー、デバイスフレーム設定等）を使うことが多いため、直前のスクリーンの情報を自動的にコピーして新しいスクリーンを作成する。

## 現状の問題

1. `ProjectState.addScreen()` で `Screen(name: "Screen N", title: "Title", subtitle: "Subtitle")` とデフォルト値で初期化される
2. ユーザーは新しいスクリーンごとに背景色、フォント、フォントサイズ、テキストカラー、レイアウト、デバイスフレーム設定等を手動で再設定する必要がある
3. スクリーンが増えるほど設定の手間が倍増する

## 対象ファイル

- 変更: `ScreenShotMaker/Models/Project.swift` (`addScreen` のロジック変更)

## 実装詳細

1. **`addScreen()` の改修**
   - 現在選択中のスクリーン（または最後のスクリーン）が存在する場合、そのスタイル情報をコピー
   - コピーする項目:
     - `layoutPreset`
     - `background`
     - `fontFamily`
     - `fontSize`
     - `textColorHex`
     - `titleStyle`
     - `subtitleStyle`
     - `showDeviceFrame`
     - `deviceFrameConfig`
     - `screenshotContentMode`
     - `isLandscape`
   - コピーしない項目:
     - `id` — 新規 UUID
     - `name` — "Screen N"
     - `localizedTexts` — 空の LocalizedText（テキスト内容はスクリーンごとに異なるため）
     - `screenshotImageData` — nil（スクリーンショットはスクリーンごとに異なるため）

2. **実装例**
   ```swift
   func addScreen() {
       let count = project.screens.count + 1
       let previousScreen = selectedScreen ?? project.screens.last
       let screen: Screen
       if let prev = previousScreen {
           screen = Screen(
               name: "Screen \(count)",
               layoutPreset: prev.layoutPreset,
               background: prev.background,
               showDeviceFrame: prev.showDeviceFrame,
               isLandscape: prev.isLandscape,
               fontFamily: prev.fontFamily,
               fontSize: prev.fontSize,
               textColorHex: prev.textColorHex,
               titleStyle: prev.titleStyle,
               subtitleStyle: prev.subtitleStyle,
               deviceFrameConfig: prev.deviceFrameConfig,
               screenshotContentMode: prev.screenshotContentMode
           )
       } else {
           screen = Screen(name: "Screen \(count)")
       }
       // ... 既存の append / undo ロジック
   }
   ```

## 受け入れ基準

- [ ] スクリーンが1つ以上ある状態で新規スクリーンを追加すると、前のスクリーンのスタイルがコピーされる
- [ ] 背景・フォント・フォントサイズ・テキストカラー・レイアウト・デバイスフレーム設定がコピーされる
- [ ] テキスト内容（title/subtitle）は空で初期化される
- [ ] スクリーンショット画像はコピーされない（nil）
- [ ] スクリーンが0個の状態ではデフォルト値で作成される
- [ ] Undo が正しく動作する

## 依存関係

なし

## 複雑度

S
