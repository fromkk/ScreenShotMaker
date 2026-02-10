# テストプラン: ビュー層テスト

対象ディレクトリ: `ScreenShotMakerTests/Views/`

> Phase 1 完了後にテストファイルを追加する。

---

## CanvasViewTests.swift

| テスト名 | テスト対象 | 期待動作 |
|---------|----------|---------|
| `testEmptyStateWhenNoScreenSelected` | `selectedScreen == nil` | 「No screen selected」が表示される |
| `testZoomScaleDefault` | 初期ズーム倍率 | `zoomScale == 1.0` (100%) |
| `testZoomScaleMinimum` | ズームアウト下限 | `zoomScale >= 0.2` (20%) |
| `testZoomScaleMaximum` | ズームイン上限 | `zoomScale <= 2.0` (200%) |
| `testPreviewDimensionsProportional` | プレビューのサイズ計算 | width/height 比がデバイスの portrait 比率と一致 |
| `testAllLayoutPresetsRender` | 5 つのレイアウトプリセットの描画 | 各プリセットでクラッシュしない |

## SidebarViewTests.swift

| テスト名 | テスト対象 | 期待動作 |
|---------|----------|---------|
| `testScreenListMatchesModel` | スクリーン一覧の表示件数 | `project.screens.count` と一致 |
| `testAddScreenButton` | 追加ボタンのタップ | `screens.count` が 1 増加 |
| `testScreenSelectionUpdatesState` | スクリーン選択 | `selectedScreenID` が更新される |

## PropertiesPanelViewTests.swift

| テスト名 | テスト対象 | 期待動作 |
|---------|----------|---------|
| `testNoSelectionState` | スクリーン未選択時 | 「Select a screen to edit」が表示される |
| `testLayoutPresetSelection` | レイアウトプリセットの切り替え | `screen.layoutPreset` が更新される |
| `testTextFieldBinding` | タイトルテキストフィールド | 入力値が `screen.title` に反映される |
| `testBackgroundTypePicker` | 背景タイプの切り替え | Color/Gradient/Image に切り替わる |
