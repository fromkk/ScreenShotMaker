# Issue #051: iPad 向けファイル操作 UI の追加

## Status
Open

## Phase / Priority
Phase 8 (iPad対応) | P1 (High)

## 概要

iPad のツールバーに「新規」「開く」「保存」「名前を付けて保存」のファイル操作ボタンを追加する。現在 iOS ではファイル操作 UI がなく、macOS の `.commands` メニューでのみ対応している。

## 現状

- iOS のツールバーには `DevicePicker`, `LanguagePicker`, `ExportButton`, `BatchExportButton` のみ
- ファイルの Open / Save は macOS のメニューコマンド（⌘O / ⌘S / ⇧⌘S）のみで利用可能
- iPad（外付けキーボードなし）ではプロジェクトファイルの保存・読み込みができない

## 対象ファイル

- 変更: `ScreenShotMaker/Views/ContentView.swift`
- 変更: `ScreenShotMaker/App/ScreenShotMakerApp.swift`（必要に応じてバインディング調整）

## 実装詳細

### 1. iOS ツールバーへのファイル操作メニューの追加

`ContentView.swift` の `#if os(iOS)` セクションに `Menu` を追加:

```swift
#if os(iOS)
ToolbarItemGroup(placement: .topBarLeading) {
    if columnVisibility == .detailOnly {
        Button {
            columnVisibility = .all
        } label: {
            Image(systemName: "sidebar.leading")
        }
    }

    Menu {
        Button("新規プロジェクト", systemImage: "doc.badge.plus") {
            newProject()
        }
        Button("開く…", systemImage: "folder") {
            openProject()
        }
        Divider()
        Button("保存", systemImage: "square.and.arrow.down") {
            saveProject()
        }
        Button("名前を付けて保存…", systemImage: "square.and.arrow.down.on.square") {
            saveAsProject()
        }
    } label: {
        Image(systemName: "doc.badge.ellipsis")
    }
}
#endif
```

### 2. アクションメソッドの接続

`newProject()`, `openProject()`, `saveProject()`, `saveAsProject()` は `ScreenShotMakerApp.swift` に既存のメソッド。`ContentView` からこれらを呼び出すために:

- `Environment` 経由のバインディング、または
- `Notification` / `Action` パターンで App レベルに伝達

### 3. キーボードショートカットの維持

iPad の外付けキーボード使用時に ⌘O / ⌘S / ⇧⌘S が引き続き動作するよう、既存の `.commands` は維持する。iOS では `.commands` も外付けキーボードで動作するため、Menu ボタンとキーボードショートカットの両方が使える状態にする。

## 受け入れ基準

- [ ] iPad のツールバーにファイル操作メニュー（`doc.badge.ellipsis` アイコン）が表示される
- [ ] メニューから「新規プロジェクト」をタップで新規プロジェクトを作成できる
- [ ] メニューから「開く」をタップでファイルピッカーが表示される
- [ ] メニューから「保存」をタップでプロジェクトが保存される（初回は名前を付けて保存）
- [ ] メニューから「名前を付けて保存」をタップで保存先を選択できる
- [ ] 外付けキーボードの ⌘S / ⌘O / ⇧⌘S も引き続き動作する

## 依存関係

- #048 (.shotcraft パッケージ形式)
- #049 (UTType 正式登録)

## 複雑度

M
