# Issue #024: NavigationSplitView / Inspector への UI リファクタリング

## Phase / Priority
Phase 5 | P2 (Medium)

## 概要

現在のレイアウトは HStack で3カラムを固定幅で配置しており、サイドバーやインスペクタの表示・非表示切替ができない。macOS ネイティブの `NavigationSplitView` と `.inspector()` modifier を活用し、ツールバーボタンでサイドバー/インスペクタの表示・非表示を切り替えられるようにする。

## 現状の問題

1. ContentView が `HStack(spacing: 0)` で3カラム固定レイアウト
2. SidebarView: `frame(width: 240)` でハードコード
3. PropertiesPanelView: `frame(width: 300)` でハードコード
4. 表示・非表示の切替手段がない
5. ウィンドウサイズ変更時にキャンバス領域が圧迫される

## 対象ファイル

- 変更: `ScreenShotMaker/Views/ContentView.swift` (レイアウト構造の変更)
- 変更: `ScreenShotMaker/Views/SidebarView.swift` (NavigationSplitView 対応)
- 変更: `ScreenShotMaker/Views/PropertiesPanelView.swift` (Inspector 対応)

## 実装詳細

1. **NavigationSplitView の導入**
   - ContentView の HStack を `NavigationSplitView` に置き換え
   - sidebar: SidebarView
   - detail: CanvasView

2. **Inspector modifier の導入**
   - detail ビューに `.inspector(isPresented: $showInspector)` を適用
   - inspector 内に PropertiesPanelView を配置

3. **ツールバーボタンの追加**
   - サイドバー表示切替: `toggleSidebar` アクション (macOS 標準)
   - インスペクタ表示切替: `@State private var showInspector = true` のトグル
   - SF Symbols アイコン使用 (sidebar.leading, sidebar.trailing 等)

4. **状態管理**
   - `@State private var showInspector: Bool = true`
   - サイドバーは `NavigationSplitView` の標準動作で管理
   - ウィンドウサイズに応じた適切なリサイズ動作

## 受け入れ基準

- [ ] ツールバーボタンでサイドバーの表示・非表示を切り替えられる
- [ ] ツールバーボタンでインスペクタの表示・非表示を切り替えられる
- [ ] サイドバー非表示時、キャンバスが全幅に拡大される
- [ ] インスペクタ非表示時、キャンバスが右方向に拡大される
- [ ] 表示・非表示の切替がアニメーション付きで行われる
- [ ] 既存の全機能 (スクリーン選択、プロパティ編集等) が正常動作する

## 依存関係

なし

## 複雑度

M
