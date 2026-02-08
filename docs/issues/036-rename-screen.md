# Issue #036: スクリーン名の変更

## Phase / Priority
Phase 7 | P2 (Medium)

## 概要

現在、スクリーン名は作成時に自動生成（"Screen 1", "Screen 2" 等）され、ユーザーが変更する手段がない。スクリーン名を編集できるようにすることで、各スクリーンの用途を一目で把握しやすくする。

## 現状の問題

1. スクリーン名は `addScreen()` で "Screen N" として自動生成される
2. サイドバーの `ScreenRow` では `Text(screen.name)` で表示のみ
3. PropertiesPanelView にもスクリーン名の編集フィールドがない
4. Duplicate / Paste 時に " Copy" が付加されるが、それ以降の変更手段がない

## 対象ファイル

- 変更: `ScreenShotMaker/Views/SidebarView.swift` (ダブルクリックでインライン編集、またはコンテキストメニューに「Rename」追加)
- 変更: `ScreenShotMaker/Views/PropertiesPanelView.swift` (Name フィールド追加の場合)
- 変更: `ScreenShotMaker/Models/Project.swift` (必要に応じて `renameScreen` メソッド追加)

## 実装詳細

### 方法 A: サイドバーでダブルクリック編集

サイドバーの `ScreenRow` をダブルクリックするとインライン `TextField` に切り替わり、名前を編集できるようにする。

### 方法 B: PropertiesPanelView に Name フィールド追加

Properties パネルの最上部にスクリーン名の `TextField` を追加する。

### 方法 C: コンテキストメニューに「Rename」追加

コンテキストメニューに「Rename」を追加し、選択するとアラートまたはポップオーバーで名前を入力する。

### 共通

- Undo 対応: `updateScreen` 経由で名前変更すれば既存の Undo ロジックが適用される
- 空文字の場合はデフォルト名（"Screen N"）にフォールバック

## 受け入れ基準

- [ ] スクリーン名を変更できる UI が存在する
- [ ] 変更した名前がサイドバーに即座に反映される
- [ ] 変更した名前がエクスポート時のファイル名に反映される
- [ ] Undo/Redo が正しく動作する
- [ ] 空文字の場合はデフォルト名にフォールバックする

## 依存関係

なし

## 複雑度

S
