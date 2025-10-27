# Live Activity Implementation Setup Guide

## 概要

本ドキュメントは、TsukiUsagi TimerアプリにLive Activity機能を追加するための手順を説明します。

## 実装済みファイル

以下のファイルは既に作成済みです：

### Live Activity Extension
- `TsukiUsagiLiveActivity/TimerActivityAttributes.swift` - データモデル
- `TsukiUsagiLiveActivity/TimerLiveActivityWidget.swift` - Widget UI

### Main App
- `TsukiUsagi/Application/Managers/LiveActivityManager.swift` - Activity管理
- `TsukiUsagi/Application/Services/DeepLinkRouter.swift` - Deep Link処理

### 編集済みファイル
- `TsukiUsagi/Entry/TsukiUsagiApp.swift` - Deep Link登録
- `TsukiUsagi/Entry/ContentView.swift` - Deep Link処理
- `TsukiUsagi/Features/Timer/ViewModels/TimerViewModel+SessionControl.swift` - Activity統合

## Xcode設定手順

### 1. Widget Extension Targetの作成

1. Xcodeでプロジェクトを開く
2. メニューから **File > New > Target**
3. **Widget Extension** を選択
4. 設定：
   - **Product Name**: `TsukiUsagiLiveActivity`
   - **Bundle Identifier**: `com.tsukiusagi.TsukiUsagi.LiveActivity`
   - **Language**: Swift
   - **Embed in Application**: チェック
5. **Finish** をクリック

### 2. Widget Extension の設定

新しく作成されたWidget Extensionターゲットにて：

1. **General** タブ
   - **Deployment Target**: iOS 17.0
   - **Capabilities**:
     - ActivityKit を有効化（追加されていない場合は追加）

2. **Info** タブに追加
   ```xml
   <key>NSSupportsLiveActivities</key>
   <true/>
   ```

### 3. Main App Target の設定

メインアプリターゲット（TsukiUsagi）にて：

1. **Info** タブ（またはInfo.plist）に追加
   ```xml
   <key>CFBundleURLTypes</key>
   <array>
       <dict>
           <key>CFBundleTypeRole</key>
           <string>Editor</string>
           <key>CFBundleURLSchemes</key>
           <array>
               <string>tsukiusagi</string>
           </array>
       </dict>
   </array>
   ```

2. **Capabilities** タブ
   - **Background Modes**:
     - ☑️ Remote notifications
     - ☑️ Background processing

### 4. ファイルの配置確認

Widget Extensionターゲットに以下のファイルを追加：

1. Xcodeで `TimerActivityAttributes.swift` と `TimerLiveActivityWidget.swift` を右クリック
2. **Show File Inspector** (⌘⌥1)
3. **Target Membership** で `TsukiUsagiLiveActivity` にチェック

### 5. ActivityKit フレームワークの追加

Widget ExtensionターゲットにActivityKitを追加：

1. Widget Extensionターゲットを選択
2. **General** タブ
3. **Frameworks, Libraries, and Embedded Content** セクション
4. **+** ボタンをクリック
5. **ActivityKit** を追加

メインアプリターゲットにも同様に追加：

1. TsukiUsagiターゲットを選択
2. **General** タブ
3. **Frameworks, Libraries, and Embedded Content** セクション
4. **+** ボタンをクリック
5. **ActivityKit** を追加

### 6. Application/Managers ディレクトリの確認

メインアプリターゲットに以下のディレクトリとファイルが含まれていることを確認：

```
TsukiUsagi/
├── Application/
│   ├── Managers/
│   │   └── LiveActivityManager.swift
│   └── Services/
│       └── DeepLinkRouter.swift
```

これらのファイルが適切にターゲットメンバーシップに含まれていることを確認してください。

## ビルドとテスト

### 1. ビルド
```bash
xcodebuild -project TsukiUsagi.xcodeproj \
           -scheme TsukiUsagi \
           -destination 'platform=iOS Simulator,name=iPhone 16' \
           build
```

### 2. 動作確認

#### Live Activity の表示
1. アプリを起動
2. タイマーを開始
3. ホーム画面に戻る
4. Dynamic Island に Live Activity が表示されることを確認

#### Deep Link の動作
1. Live Activity をタップ
2. アプリが復帰することを確認

#### Pause/Resume の動作
1. タイマーを一時停止
2. Live Activity が更新されることを確認（実際には新しい終了時刻が計算される）
3. 再開
4. Live Activity が更新されることを確認

#### 完了時の動作
1. タイマーを完了（または強制終了）
2. Live Activity が即座に消えることを確認

## トラブルシューティング

### Live Activity が表示されない
- iOS 17以降のシミュレーター/実機を使用しているか確認
- ActivityKit フレームワークが追加されているか確認
- `NSSupportsLiveActivities` が Info.plist に設定されているか確認

### Deep Link が動作しない
- URL Scheme `tsukiusagi` が Info.plist に登録されているか確認
- `onOpenURL` が `TsukiUsagiApp.swift` に追加されているか確認

### ビルドエラー
- Widget Extension と Main App の両方に ActivityKit がリンクされているか確認
- ファイルが適切なターゲットメンバーシップに含まれているか確認

## 参考リンク

- [Apple Developer - ActivityKit](https://developer.apple.com/documentation/activitykit)
- [Apple Developer - Live Activities](https://developer.apple.com/documentation/widgetkit/live-activities)

