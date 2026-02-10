# Issue #054: iPad ツールバーに現在のファイル名を表示

## Status
Open

## Phase / Priority
Phase 8 (iPad対応) | P2 (Medium)

## 概要

iPad（iOS）のサイドバーツールバーにあるプロジェクト操作メニューボタンの横に、現在開いているファイル名を表示する。未保存の変更がある場合はファイル名の末尾に ` *` を付けて編集済み状態を示す。

## 現状

- iOS のサイドバーツールバー（`SidebarView`）にはプロジェクト操作メニュー（`doc.badge.ellipsis` アイコン）のみが配置されている
- 現在のファイル名はどこにも表示されていない
- `ProjectState` には `currentFileURL: URL?` と `hasUnsavedChanges: Bool` が既に存在する
- macOS ではウィンドウタイトルバーにファイル名が表示されるが、iPad では同等の情報がない

## 対象ファイル

- 変更: `ScreenShotMaker/Views/SidebarView.swift`

## 実装詳細

### 1. ファイル名表示用 computed property の追加

`SidebarView` にファイル名を算出する computed property を追加する:

```swift
#if os(iOS)
private var displayFileName: String {
    let name = state.currentFileURL?
        .deletingPathExtension()
        .lastPathComponent ?? "Untitled"
    return state.hasUnsavedChanges ? "\(name) *" : name
}
#endif
```

### 2. ToolbarItem → ToolbarItemGroup への変更

既存の `ToolbarItem(placement: .topBarLeading)` を `ToolbarItemGroup(placement: .topBarLeading)` に変更し、既存の `Menu` の後にファイル名 `Text` を追加する:

```swift
#if os(iOS)
.toolbar {
    ToolbarItemGroup(placement: .topBarLeading) {
        Menu {
            // …（既存のプロジェクト操作メニュー項目）
        } label: {
            Image(systemName: "doc.badge.ellipsis")
        }

        Text(displayFileName)
            .font(.subheadline)
            .foregroundStyle(.secondary)
            .lineLimit(1)
    }
}
#endif
```

### 3. 表示仕様

| 状態 | 表示テキスト |
|---|---|
| 新規プロジェクト（未保存） | `Untitled` |
| 新規プロジェクト（編集済み） | `Untitled *` |
| 保存済みファイル `MyApp.shotcraft` | `MyApp` |
| 保存済みファイルを編集 | `MyApp *` |
| 保存直後 | `MyApp` |

- 拡張子は非表示（`.deletingPathExtension()` で除去）
- 長いファイル名は `.lineLimit(1)` で省略表示

## テスト計画

### 手動テスト（iPad シミュレータ）

1. アプリ起動 → サイドバーツールバー左上に `Untitled` が表示されること
2. スクリーンを追加・編集 → `Untitled *` に変わること
3. 「Save As…」で `TestProject.shotcraft` として保存 → `TestProject` に変わること（`*` なし）
4. 再度編集 → `TestProject *` に変わること
5. 「Save」で保存 → `TestProject` に戻ること（`*` が消える）
6. 長いファイル名（例: `VeryLongProjectNameForTesting`）で保存 → テキストが省略表示され、レイアウトが崩れないこと
7. 「New Project」で新規作成 → `Untitled` に戻ること

### macOS

- macOS ではこの変更の影響がないことを確認（`#if os(iOS)` で囲まれているため）

## 依存関係

- `ProjectState.currentFileURL`（既存）
- `ProjectState.hasUnsavedChanges`（既存）
- Issue #051 のファイル操作 UI が `SidebarView` のツールバーに配置済みであること
