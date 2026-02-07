# Issue #009: テンプレートシステム

## Phase / Priority
Phase 2 | P2 (Medium)

## 概要

ビルトインのレイアウトテンプレートを提供し、新規プロジェクト作成時やスクリーン追加時にテンプレートを適用できるようにする。

## 対象ファイル

- 新規: `ScreenShotMaker/Models/Template.swift`
- 新規: `ScreenShotMaker/Views/TemplateGalleryView.swift`
- 新規: `ScreenShotMaker/Resources/Templates.json`
- 変更: `ScreenShotMaker/App/ScreenShotMakerApp.swift` (初回起動時にギャラリー表示)

## 実装詳細

1. **Template モデルの作成**
   ```swift
   struct Template: Codable, Identifiable {
       let id: String
       let name: String
       let description: String
       let previewImageName: String
       let screens: [Screen]  // テンプレートのスクリーン定義
   }
   ```

2. **サンプルテンプレートの定義** (Templates.json)
   - **Minimal**: 白背景、黒テキスト、textTop レイアウト
   - **Bold Gradient**: ビビッドなグラデーション、大きなテキスト
   - **Dark Mode**: 暗い背景、白テキスト
   - **Screenshot Focus**: screenshotOnly レイアウト、シンプルな背景
   - **Professional**: グレー系グラデーション、textBottom レイアウト

3. **TemplateGalleryView の作成**
   - Grid レイアウトでテンプレートプレビューを表示
   - 各テンプレートにプレビュー画像 + 名前 + 説明
   - 「Start from Scratch」オプション（空プロジェクト）
   - 選択時に `ProjectState` に適用

4. **ギャラリーの表示タイミング**
   - アプリ初回起動時にシート表示
   - File > New from Template メニュー

## 受け入れ基準

- [ ] テンプレートギャラリーに 5 つ以上のテンプレートが表示される
- [ ] テンプレートを選択すると新しいプロジェクトが作成される
- [ ] 各テンプレートのプレビューが正しく表示される
- [ ] 「Start from Scratch」で空プロジェクトが作成される
- [ ] File > New from Template でギャラリーにアクセスできる

## 依存関係

なし

## 複雑度

M
