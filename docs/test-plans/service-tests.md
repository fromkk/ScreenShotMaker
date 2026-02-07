# テストプラン: サービス層テスト

対象ディレクトリ: `ScreenShotMakerTests/Services/`

> Phase 1 の各 issue 実装と同時にテストを追加する。

---

## ImageLoaderTests.swift (Issue #001 完了後)

| テスト名 | テスト対象 | 期待動作 |
|---------|----------|---------|
| `testLoadValidPNG` | 正常な PNG ファイルの読み込み | `Data` が返る、エラーなし |
| `testLoadValidJPEG` | 正常な JPEG ファイルの読み込み | `Data` が返る、エラーなし |
| `testRejectInvalidFormat` | テキストファイル等の読み込み | `ImageLoadError.invalidFormat` が throw される |
| `testRejectOversizedFile` | 20MB 超のファイル | `ImageLoadError.fileTooLarge` が throw される |
| `testLoadNonExistentFile` | 存在しないパスの読み込み | `ImageLoadError.fileNotFound` が throw される |
| `testLoadedDataIsValidImage` | 読み込んだ Data から NSImage が作れる | `NSImage(data:)` が non-nil |

## ProjectFileServiceTests.swift (Issue #005-006 完了後)

| テスト名 | テスト対象 | 期待動作 |
|---------|----------|---------|
| `testSaveProject` | プロジェクト保存 | 指定パスにファイルが作成される |
| `testSaveContainsValidJSON` | 保存ファイルの内容 | JSON としてパース可能 |
| `testLoadProject` | 保存 → 読み込み | 読み込んだプロジェクトの screens 数が一致 |
| `testRoundTripAllFields` | 全フィールドの保存/復元 | name, screens, selectedDevices, languages が全て一致 |
| `testLoadCorruptedFile` | 破損 JSON の読み込み | `DecodingError` が throw される |
| `testSaveWithImageData` | 画像データ付きの保存 | screenshotImageData が保存後も同一 |
| `testLoadEmptyFile` | 空ファイルの読み込み | エラーが throw される |

## ExportServiceTests.swift (Issue #004 完了後)

| テスト名 | テスト対象 | 期待動作 |
|---------|----------|---------|
| `testExportProducesImage` | 単一スクリーンのエクスポート | non-nil の NSImage が返る |
| `testExportDimensions` | 出力画像のサイズ | device.portraitWidth × portraitHeight と一致 |
| `testExportPNGFormat` | PNG エクスポート | PNG ヘッダーバイト (89 50 4E 47) で始まる |
| `testExportJPEGFormat` | JPEG エクスポート | JPEG ヘッダーバイト (FF D8 FF) で始まる |
| `testExportWithGradientBackground` | グラデーション背景のレンダリング | 画像が生成される（クラッシュしない） |
| `testExportWithSolidBackground` | ソリッドカラー背景 | 画像が生成される |

## ScalingServiceTests.swift (Issue #010 完了後)

| テスト名 | テスト対象 | 期待動作 |
|---------|----------|---------|
| `testScaleFactorSameDevice` | 同一デバイスのスケール比率 | `1.0` が返る |
| `testScaleFactorSmaller` | 小さいデバイスへの比率 | `0.0 < factor < 1.0` |
| `testScaledFontMinimum` | 最小フォントサイズの保証 | 下限値以下にならない |
