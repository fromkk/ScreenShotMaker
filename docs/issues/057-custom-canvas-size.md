# Issue #057: カスタムキャンバスサイズの追加

## Phase / Priority
Phase 8 | P2 (Medium)

## 概要

現在はApp Store Connect標準のデバイスサイズ（iPhone、iPad等の定義済みサイズ）のみが使用可能。ユーザーが任意のキャンバスサイズ（横幅・縦幅をピクセル指定）を作成し、プロジェクトに保存して使用できるようにする。Instagram Story（1080×1920）やWeb用バナー、独自のアスペクト比など、標準デバイス以外のスクリーンショット作成に対応する。

## ユースケース

1. Instagram Story用のスクリーンショット（1080×1920）を作成したい
2. Twitter投稿用の正方形画像（1080×1080）を作成したい
3. Web用の横長バナー（1920×1080）を作成したい
4. 特定のアスペクト比でマーケティング素材を作成したい
5. カスタムサイズに「Instagram Story」などの名前をつけて管理したい

## 現状の問題

1. `DeviceType.swift` の定義済みサイズ（`iPhoneSizes`, `iPadSizes`等）のみが使用可能
2. 標準デバイス以外のサイズでスクリーンショットを作成できない
3. SNSやWeb用など、モバイルデバイス標準以外のアスペクト比に対応できない

## 対象ファイル

- 変更: `ScreenShotMaker/Models/DeviceType.swift` (`DeviceCategory`に`.custom`を追加、`DeviceSize`に`isCustom`プロパティ追加)
- 変更: `ScreenShotMaker/Models/Project.swift` (`customDevices: [DeviceSize]`配列を追加)
- 変更: `ScreenShotMaker/Views/ContentView.swift` (デバイス選択ポップオーバーに「カスタムサイズを追加」ボタン追加)
- 新規: `ScreenShotMaker/Views/CustomDeviceSizeDialog.swift` (名前・幅・高さ入力ダイアログ)
- 変更: `ScreenShotMaker/Services/ScalingService.swift` (カスタムデバイスのスケール計算対応)
- 変更: `ScreenShotMaker/Models/Screen.swift` (カスタムカテゴリのデフォルトフォントサイズ対応)
- 変更: `ScreenShotMaker/Models/DeviceFrame.swift` (カスタムデバイスのデフォルトフレーム仕様を定義)
- 追加テスト: `ScreenShotMakerTests/Models/CustomDeviceSizeTests.swift`

## 実装詳細

### 1. DeviceType モデルの拡張

**DeviceCategory に `.custom` ケースを追加:**
```swift
enum DeviceCategory: String, Codable, CaseIterable {
    case iPhone = "iPhone"
    case iPad = "iPad"
    case mac = "mac"
    case appleWatch = "appleWatch"
    case appleTV = "appleTV"
    case visionPro = "visionPro"
    case custom = "custom"  // 追加
}
```

**DeviceSize に `isCustom` と初期化メソッドを追加:**
```swift
struct DeviceSize: Codable, Identifiable, Hashable {
    let name: String
    let category: DeviceCategory
    let displaySize: String
    let portraitWidth: Int
    let portraitHeight: Int
    let isCustom: Bool  // 追加（デフォルト false）
    
    // カスタムサイズ用の初期化メソッド
    static func custom(name: String, width: Int, height: Int) -> DeviceSize {
        return DeviceSize(
            name: name,
            category: .custom,
            displaySize: "\(width) × \(height)",
            portraitWidth: width,
            portraitHeight: height,
            isCustom: true
        )
    }
    
    // 回転は常に false（カスタムサイズは固定）
    var supportsRotation: Bool {
        return isCustom ? false : category.supportsRotation
    }
}
```

### 2. Project モデルの更新

**カスタムデバイス配列を追加:**
```swift
struct Project: Codable {
    // 既存プロパティ...
    var customDevices: [DeviceSize] = []  // 追加
    
    // カスタムデバイスを追加するメソッド
    mutating func addCustomDevice(name: String, width: Int, height: Int) {
        let customDevice = DeviceSize.custom(name: name, width: width, height: height)
        customDevices.append(customDevice)
    }
    
    // カスタムデバイスを削除するメソッド
    mutating func removeCustomDevice(_ device: DeviceSize) {
        customDevices.removeAll { $0.id == device.id }
    }
}
```

### 3. デバイス選択UIの更新 (ContentView.swift)

**`deviceManagerPopover` に「カスタムサイズを追加」ボタンを追加:**
```swift
private var deviceManagerPopover: some View {
    ScrollView {
        VStack(alignment: .leading, spacing: 8) {
            // 既存のデバイスリスト...
            
            // カスタムデバイスセクション
            if !project.customDevices.isEmpty {
                Text("カスタムサイズ")
                    .font(.headline)
                    .padding(.top, 8)
                
                ForEach(project.customDevices) { device in
                    HStack {
                        Button(action: { toggleDeviceSelection(device) }) {
                            HStack {
                                Image(systemName: project.selectedDevices.contains(device) ? "checkmark.circle.fill" : "circle")
                                Text(device.name)
                                Spacer()
                                Text(device.displaySize)
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        Button(action: { project.removeCustomDevice(device) }) {
                            Image(systemName: "trash")
                        }
                        .buttonStyle(.borderless)
                    }
                }
            }
            
            // カスタムサイズ追加ボタン
            Button(action: { showCustomDeviceSizeDialog = true }) {
                Label("カスタムサイズを追加", systemImage: "plus.circle")
            }
            .padding(.top, 8)
        }
    }
    .sheet(isPresented: $showCustomDeviceSizeDialog) {
        CustomDeviceSizeDialog(project: $project)
    }
}
```

### 4. 新規ダイアログの作成 (CustomDeviceSizeDialog.swift)

```swift
struct CustomDeviceSizeDialog: View {
    @Binding var project: Project
    @Environment(\.dismiss) private var dismiss
    
    @State private var name: String = ""
    @State private var width: String = ""
    @State private var height: String = ""
    
    var body: some View {
        VStack(spacing: 20) {
            Text("カスタムサイズを追加")
                .font(.headline)
            
            TextField("名前（例: Instagram Story）", text: $name)
                .textFieldStyle(.roundedBorder)
            
            HStack {
                TextField("横幅 (px)", text: $width)
                    .textFieldStyle(.roundedBorder)
                #if os(iOS)
                    .keyboardType(.numberPad)
                #endif
                
                Text("×")
                
                TextField("縦幅 (px)", text: $height)
                    .textFieldStyle(.roundedBorder)
                #if os(iOS)
                    .keyboardType(.numberPad)
                #endif
            }
            
            HStack {
                Button("キャンセル") {
                    dismiss()
                }
                
                Spacer()
                
                Button("完了") {
                    if let w = Int(width), let h = Int(height), !name.isEmpty, w > 0, h > 0 {
                        project.addCustomDevice(name: name, width: w, height: h)
                        dismiss()
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(name.isEmpty || Int(width) == nil || Int(height) == nil)
            }
        }
        .padding()
        .frame(width: 400)
    }
}
```

### 5. ScalingService の更新

**カスタムデバイスのスケール計算:**
```swift
static func referenceDevice(for category: DeviceCategory) -> DeviceSize {
    switch category {
    case .iPhone: return iPhoneSizes[3]  // iPhone 6.7"
    case .iPad: return iPadSizes[2]      // iPad Pro 12.9"
    case .mac: return macSizes[0]        // Mac
    case .custom: 
        // カスタムはスケールなし（1.0倍固定）
        return DeviceSize.custom(name: "Reference", width: 1080, height: 1920)
    default: 
        return iPhoneSizes[3]
    }
}
```

### 6. DeviceFrame の更新

**カスタムデバイスのデフォルトフレーム:**
```swift
extension DeviceFrameSpec {
    static var customDefault: DeviceFrameSpec {
        DeviceFrameSpec(
            bezelRatio: 0.05,              // シンプルな細いベゼル
            cornerRadiusRatio: 0.05,       // 適度な角丸
            frameColor: .black,            // 黒フレーム
            hasNotch: false,               // ノッチなし
            hasHomeIndicator: false        // ホームインジケーターなし
        )
    }
}
```

### 7. Screen の更新

**カスタムカテゴリのデフォルトフォントサイズ:**
```swift
func fontSize(for category: DeviceCategory) -> Double {
    if category == .custom {
        // カスタムはiPhoneと同じフォントサイズを使用
        return fontSizes["iPhone"] ?? Screen.defaultFontSize
    }
    return fontSizes[category.rawValue] ?? Screen.defaultFontSize
}
```

## 受け入れ基準

- [ ] デバイス選択ポップオーバーに「カスタムサイズを追加」ボタンが表示される
- [ ] ボタンをクリックすると名前・横幅・縦幅を入力するダイアログが表示される
- [ ] 名前と正の整数値を入力して「完了」するとカスタムサイズがプロジェクトに追加される
- [ ] 追加されたカスタムサイズがデバイスリストに表示され、選択可能になる
- [ ] カスタムサイズを選択するとプレビューキャンバスが指定サイズで表示される
- [ ] カスタムサイズでエクスポートすると指定サイズの画像が生成される
- [ ] カスタムサイズにはデフォルトのシンプルなフレームが適用される
- [ ] カスタムサイズは回転（縦横切り替え）ができない（固定）
- [ ] カスタムサイズの削除ボタンで個別に削除できる
- [ ] プロジェクトを保存・再読み込みしてもカスタムサイズが保持される
- [ ] 既存プロジェクトを開いても互換性が保たれる（customDevices が空配列として扱われる）

## 依存関係

- Issue #019: デバイス選択UI — この画面にカスタムサイズ追加ボタンを設置
- Issue #056: デバイスカテゴリごとのフォントサイズ — カスタムカテゴリのフォントサイズ管理
- Issue #027: デバイスフレームのカスタマイズ — カスタムサイズのフレーム設定

## 複雑度

Medium — DeviceSize の拡張とProject への保存は比較的シンプル。UI追加とバリデーション、既存のスケーリング・フレーム・フォントサイズロジックとの統合が必要。
