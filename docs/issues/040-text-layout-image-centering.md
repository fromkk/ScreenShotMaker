# Issue #040: Text TopとText Bottomレイアウトでの画像中央固定とスペース調整

## Status
✅ Completed

## Phase / Priority
Phase 7 | P2 (Medium)

## 概要

Text TopおよびText Bottomレイアウトにおいて、画像の位置を中央に固定し、テキストが画像から伸びる方向を制御できるようにする。また、画像とテキストの間のスペースをGUIで調整可能にする。

## 現状の問題

1. **画像の配置**
   - 現在、Text TopおよびText Bottomレイアウトでの画像位置の挙動が明確に定義されていない可能性がある
   - 画像が中央に固定されておらず、テキスト量によって位置が変わる可能性がある

2. **テキストの伸び方向**
   - Text Top: テキストは画像の上部から上方向に伸びるべきだが、現在の実装が不明確
   - Text Bottom: テキストは画像の下部から下方向に伸びるべきだが、現在の実装が不明確

3. **スペース調整**
   - 画像とテキストの間のスペースが固定値となっている可能性がある
   - デザインやテンプレートに応じて柔軟に調整できることが望ましい

## 要件

### 1. 画像の中央固定

**Text Topレイアウト:**
- 画像は垂直方向の中央（または下寄り）に配置される
- テキストは画像の上部から上方向に伸びる
- テキストの長さが変わっても画像の位置は固定される

**Text Bottomレイアウト:**
- 画像は垂直方向の中央（または上寄り）に配置される
- テキストは画像の下部から下方向に伸びる
- テキストの長さが変わっても画像の位置は固定される

### 2. スペース調整機能

- `Template`モデルに新しいプロパティを追加
  - `textToImageSpacing: CGFloat` (デフォルト: 20.0 など)
- PropertiesPanelViewにスライダーまたは数値入力フィールドを追加
  - 調整範囲: 0〜100ポイント程度
  - リアルタイムでCanvasViewに反映

### 3. レイアウト計算の更新

- `CanvasView`のレイアウト計算ロジックを更新
  - Text Top/Bottomの場合、画像位置を固定
  - `textToImageSpacing`を考慮してテキストと画像の間隔を設定
  - 既存のCenter/Left/Rightレイアウトには影響を与えない

## 実装方針

### Phase 1: データモデルの拡張

1. **Template.swift**
   ```swift
   struct Template: Codable, Identifiable, Equatable {
       // ... 既存のプロパティ
       var textToImageSpacing: CGFloat = 20.0  // 新規追加
   }
   ```

### Phase 2: UIの追加

2. **PropertiesPanelView.swift**
   - Text TopまたはText Bottomレイアウト選択時に表示されるスペース調整UI
   - スライダーまたはStepper + TextField
   ```swift
   if template.layout == .textTop || template.layout == .textBottom {
       VStack(alignment: .leading, spacing: 4) {
           Text("Image-Text Spacing")
               .font(.subheadline)
           HStack {
               Slider(value: $template.textToImageSpacing, in: 0...100, step: 5)
               TextField("", value: $template.textToImageSpacing, format: .number)
                   .textFieldStyle(.roundedBorder)
                   .frame(width: 60)
           }
       }
   }
   ```

### Phase 3: レイアウトロジックの更新

3. **CanvasView.swift**
   - `textTop()`および`textBottom()`メソッドを更新
   - 画像を中央（または適切な位置）に固定配置
   - `template.textToImageSpacing`を使用してテキストとの間隔を設定

   **Text Topの場合:**
   ```swift
   private func textTop() -> some View {
       VStack(spacing: template.textToImageSpacing) {
           // テキスト部分（上方向に伸びる）
           textContent()
           
           // 画像（固定位置）
           deviceFrameOrScreenshot()
       }
   }
   ```

   **Text Bottomの場合:**
   ```swift
   private func textBottom() -> some View {
       VStack(spacing: template.textToImageSpacing) {
           // 画像（固定位置）
           deviceFrameOrScreenshot()
           
           // テキスト部分（下方向に伸びる）
           textContent()
       }
   }
   ```

### Phase 4: プロジェクトファイルの互換性

4. **Project.swift / Screen.swift**
   - 既存のプロジェクトファイルとの互換性を確保
   - `textToImageSpacing`が存在しない場合はデフォルト値を使用
   - Codableの実装でデフォルト値が自動的に適用される

## 対象ファイル

- 変更: `ScreenShotMaker/Models/Template.swift` (textToImageSpacingプロパティ追加)
- 変更: `ScreenShotMaker/Views/PropertiesPanelView.swift` (スペース調整UI追加)
- 変更: `ScreenShotMaker/Views/CanvasView.swift` (レイアウト計算の更新)

## テストケース

### 1. 画像位置の固定

- [ ] Text Topレイアウトで短いテキストと長いテキストを切り替えても画像位置が変わらない
- [ ] Text Bottomレイアウトで短いテキストと長いテキストを切り替えても画像位置が変わらない

### 2. スペース調整

- [ ] PropertiesPanelでスペースを0に設定すると、画像とテキストが密着する
- [ ] スペースを100に設定すると、画像とテキストの間に大きな空間ができる
- [ ] スペースの変更がリアルタイムでCanvasViewに反映される

### 3. レイアウト別の動作

- [ ] Center/Left/Rightレイアウトでは既存の動作が維持される
- [ ] Text TopとText Bottomのみで新しいスペース調整が機能する

### 4. プロジェクトファイル互換性

- [ ] textToImageSpacingを含まない古いプロジェクトファイルを開いてもエラーが発生しない
- [ ] 古いプロジェクトファイルでデフォルト値（20.0）が適用される

## UI/UX考慮事項

1. **スペース調整UIの配置**
   - Text TopまたはText Bottomレイアウト選択時のみ表示
   - 他のレイアウトプロパティ（背景、デバイスフレームなど）と一貫性のあるデザイン

2. **視覚的フィードバック**
   - スライダーをドラッグ中もリアルタイムでプレビューに反映
   - 数値入力時はEnterキーまたはフォーカスアウト時に反映

3. **アクセシビリティ**
   - スライダーにアクセシビリティラベルを付与
   - VoiceOverで値の変更が読み上げられるようにする

## 参考

- 既存のレイアウトシステム: `ScreenShotMaker/Models/LayoutPreset.swift`
- 既存のテンプレートプロパティUI: `PropertiesPanelView.swift`の各セクション
- Canvas描画ロジック: `CanvasView.swift`のレイアウトメソッド

## Notes

- この機能は主にApp Store Connectのスクリーンショット要件に対応するもの
- テキストが長すぎる場合の動作（クリッピング、スクロールなど）は別途検討が必要かもしれない
- エクスポート時にもこのスペース設定が正しく反映されることを確認する
