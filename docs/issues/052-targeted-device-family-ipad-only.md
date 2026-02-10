# Issue #052: TARGETED_DEVICE_FAMILY を iPad のみに変更

## Status
Open

## Phase / Priority
Phase 8 (iPad対応) | P1 (High)

## 概要

`TARGETED_DEVICE_FAMILY` を `"2"`（iPad のみ）に変更し、`UIRequiresFullScreen` を有効にする。

## 現状

- `TARGETED_DEVICE_FAMILY = "1,2"`（iPhone + iPad）
- `INFOPLIST_KEY_UIRequiresFullScreen` 未設定
- アプリの UI は iPad の画面サイズを前提に設計されており、iPhone では使いにくい

## 対象ファイル

- 変更: `ScreenShotMaker.xcodeproj/project.pbxproj`

## 実装詳細

### 1. TARGETED_DEVICE_FAMILY の変更

Debug / Release 両ビルド構成で:

```
TARGETED_DEVICE_FAMILY = "2"
```

### 2. UIRequiresFullScreen の追加

```
INFOPLIST_KEY_UIRequiresFullScreen = YES
```

Split View / Slide Over でのレイアウト崩れを防止する。

## 受け入れ基準

- [ ] App Store Connect で iPhone 向けビルドとして表示されない
- [ ] iPad のみでインストール可能になる
- [ ] フルスクリーンで動作する（Split View / Slide Over 非対応）
- [ ] macOS ビルドに影響がない

## 依存関係

なし

## 複雑度

S
