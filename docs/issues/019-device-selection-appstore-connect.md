# Issue #019: デバイス選択肢を App Store Connect 仕様に修正

## Phase / Priority
Phase 5 | P0 (Critical)

## 概要

デバイス選択 UI が1つの端末に固定されており、複数端末を選択できない。また、DeviceType.swift に定義されている一部デバイスの解像度が App Store Connect の公式仕様と異なる。App Store Connect のスクリーンショット仕様に完全準拠したデバイス一覧を提供し、チェックボックス等で複数端末を選択可能にする。

## 現状の問題

1. `ScreenShotProject` の初期値が `selectedDevices: [DeviceSize.iPhoneSizes[0]]` で1台のみ
2. ContentView の DevicePicker が `state.project.selectedDevices` のみ列挙するため選択肢が1つ
3. 以下のデバイス解像度が App Store Connect 仕様と不一致:
   - iPhone 6.9": 現在 1260×2736 → 正 **1320×2868**
   - iPhone 6.7": **未定義** → 正 **1290×2796**（追加必要）
   - iPhone 6.3": 現在 1179×2556 → 正 **1206×2622**
   - iPad 11": 現在 1488×2266 → 正 **1668×2420**

## 対象ファイル

- 変更: `ScreenShotMaker/Models/DeviceType.swift` (解像度修正・iPhone 6.7" 追加)
- 変更: `ScreenShotMaker/Views/ContentView.swift` (デバイス選択 UI)
- 変更: `ScreenShotMaker/Models/Project.swift` (初期値・デバイス管理)

## App Store Connect 公式スクリーンショット仕様

### iPhone
| サイズ | Portrait | Landscape |
|--------|----------|-----------|
| 6.9" | 1320×2868 | 2868×1320 |
| 6.5" | 1284×2778 | 2778×1284 |
| 6.3" | 1206×2622 | 2622×1206 |
| 6.1" | 1170×2532 | 2532×1170 |
| 5.5" | 1242×2208 | 2208×1242 |
| 4.7" | 750×1334 | 1334×750 |
| 4" | 640×1136 | 1136×640 |
| 3.5" | 640×960 | 960×640 |

### iPad
| サイズ | Portrait | Landscape |
|--------|----------|-----------|
| 13" | 2064×2752 | 2752×2064 |
| 12.9" | 2048×2732 | 2732×2048 |
| 11" | 1668×2420 | 2420×1668 |
| 10.5" | 1668×2224 | 2224×1668 |
| 9.7" | 1536×2048 | 2048×1536 |

### Mac
| Aspect | Dimensions |
|--------|-----------|
| 16:10 | 1280×800, 1440×900, 2560×1600, 2880×1800 |

### Apple Watch
| モデル | Dimensions |
|--------|-----------|
| Ultra 3 | 422×514 |
| Ultra 2/Ultra | 410×502 |
| Series 11/10 | 416×496 |
| Series 9/8/7 | 396×484 |
| Series 6/5/4/SE | 368×448 |
| Series 3 | 312×390 |

### Apple TV
| Resolution |
|-----------|
| 3840×2160 |
| 1920×1080 |

### Apple Vision Pro
| Resolution |
|-----------|
| 3840×2160 |

## 実装詳細

1. **DeviceType.swift の解像度修正**
   - iPhone 6.9": portraitWidth=1320, portraitHeight=2868
   - iPhone 6.7" を新規追加: portraitWidth=1290, portraitHeight=2796
   - iPhone 6.3": portraitWidth=1206, portraitHeight=2622
   - iPad 11": portraitWidth=1668, portraitHeight=2420

2. **デバイス選択 UI の改善**
   - ContentView のツールバーに「デバイス管理」ボタンを追加
   - カテゴリ別 (iPhone/iPad/Mac 等) でチェックボックス選択可能なシート/ポップオーバー
   - 選択されたデバイスが `project.selectedDevices` に反映され、ツールバーの Picker で切替可能

3. **デフォルト選択の改善**
   - 新規プロジェクト時に App Store Connect 必須の主要デバイス (iPhone 6.9", iPhone 6.5", iPad 13") をデフォルト選択

## 受け入れ基準

- [ ] DeviceType.swift の全デバイス解像度が App Store Connect 公式仕様と一致
- [ ] iPhone 6.7" (1290×2796) が追加されている
- [ ] UI からカテゴリ別に複数デバイスを選択できる
- [ ] 選択したデバイス一覧がツールバーの Picker に反映される
- [ ] エクスポート時に選択した全デバイスサイズで出力される
- [ ] 既存プロジェクトファイルとの後方互換性が維持される

## 依存関係

なし

## 複雑度

M
