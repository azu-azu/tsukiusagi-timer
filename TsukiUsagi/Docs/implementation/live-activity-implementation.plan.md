<!-- 843bffe1-2908-49a1-9950-b6e7de6e44c0 8e55da1c-5e20-45ad-b545-8f03bc8562a7 -->
# Live Activity Implementation for TsukiUsagi Timer

## Overview

iOS 17以降のLive Activity機能を使用して、タイマー実行中にDynamic IslandとLock Screenで進行状況を表示し、ユーザーがタップして即座にアプリに復帰できる機能を実装します。

## Implementation Steps

### 1. Widget Extension Target の作成

Xcodeで新しいWidget Extension targetを追加:

- Target名: `TsukiUsagiLiveActivity`
- Product Bundle Identifier: `com.tsukiusagi.TsukiUsagi.LiveActivity`
- iOS Deployment Target: 17.0以上
- `ActivityKit`フレームワークを追加

### 2. Live Activity Data Model の実装

**新規ファイル**: `TsukiUsagiLiveActivity/TimerActivityAttributes.swift`

```swift
import ActivityKit
import Foundation

struct TimerActivityAttributes: ActivityAttributes {
    struct ContentState: Codable, Hashable {
        var endsAt: Date
        var isPaused: Bool
    }

    // セッション種別: "Work", "Study", "Read", "Break" など
    var sessionKind: String
}
```

### 3. Live Activity Widget の実装

**新規ファイル**: `TsukiUsagiLiveActivity/TimerLiveActivityWidget.swift`

仕様に基づいて以下を実装:

- **Expanded**: 左に🌙アイコン+セッション名、右に残り時間
- **Compact Leading**: 残り時間（短縮表記）
- **Compact Trailing**: 丸い🌙ロゴ
- **Minimal**: 🌙ロゴのみ
- **Lock Screen/Banner**: 残り時間中央、セッション名補助
- すべてモノスペース数字、`widgetURL("tsukiusagi://timer")`でタップ復帰

### 4. アセットの準備

**Widget Extension用アセット**: `TsukiUsagiLiveActivity/Assets.xcassets/`

以下の画像を追加:

- `tsukiusagi_logo_expanded` (18×18推奨、単色対応)
- `tsukiusagi_logo_compact` (正円、32×32目安)
- `tsukiusagi_logo_minimal` (小サイズ判別可能)

既存の月アイコンを流用し、サイズ調整したバリエーションを作成。

### 5. Live Activity Manager の実装

**新規ファイル**: `TsukiUsagi/Application/Managers/LiveActivityManager.swift`

```swift
import ActivityKit
import Foundation

@MainActor
final class LiveActivityManager {
    private static var currentActivity: Activity<TimerActivityAttributes>?

    // タイマー開始時に呼び出し
    static func startActivity(sessionKind: String, endsAt: Date) async

    // Pause/Resume時に呼び出し
    static func updateActivity(isPaused: Bool, newEndsAt: Date) async

    // タイマー完了/キャンセル時に呼び出し
    static func endActivity() async
}
```

実装内容:

- `ActivityAuthorizationInfo().areActivitiesEnabled`チェック
- 既存Activityがあれば終了してから新規作成（単一化ポリシー）
- エラーは静かにログのみ（ユーザー体験を妨げない）

### 6. TimerViewModel への統合

**編集ファイル**: `TsukiUsagi/Features/Timer/ViewModels/TimerViewModel.swift`

以下のタイミングでLiveActivityManagerを呼び出し:

- **タイマー開始時** (`startTimer()`): `LiveActivityManager.startActivity()`
- **Pause時** (`pauseTimer()`): `LiveActivityManager.updateActivity(isPaused: true)`
- **Resume時** (`resumeTimer()`): `LiveActivityManager.updateActivity(isPaused: false)`
- **完了/キャンセル時** (`resetTimer()`, `forceFinish()`): `LiveActivityManager.endActivity()`

### 7. Deep Link Routing の実装

**新規ファイル**: `TsukiUsagi/Application/Services/DeepLinkRouter.swift`

URL Scheme `tsukiusagi://timer` を処理:

- `TsukiUsagiApp.swift`で`.onOpenURL`を追加
- `ContentView.swift`でタイマー画面へのナビゲーション状態を管理
- Killed状態からのCold start対応

**編集ファイル**: `TsukiUsagi/Entry/TsukiUsagiApp.swift`

```swift
.onOpenURL { url in
    DeepLinkRouter.handle(url: url)
}
```

### 8. Info.plist の設定

**Widget Extension**: `TsukiUsagiLiveActivity/Info.plist`

```xml
<key>NSSupportsLiveActivities</key>
<true/>
```

**Main App**: `TsukiUsagi/Info.plist` (GENERATE_INFOPLIST_FILE使用のため、project.pbxprojで設定)

```
URL Types:
  - URL Schemes: tsukiusagi
```

### 9. App Groups の設定 (必要に応じて)

Widget ExtensionとMain Appでデータ共有が必要な場合:

- App Group ID: `group.com.tsukiusagi.TsukiUsagi`
- Capabilities設定（両ターゲット）
- 現在の仕様では不要（ActivityAttributesで完結）

### 10. テスト実装

**テスト観点**:

- タイマー実行→ホーム画面: Compact表示確認
- 他アプリ共存時のiOS自動配置
- タップでアプリ復帰（Foreground/Killed両方）
- ロック画面での1秒刻みカウントダウン
- 完了/キャンセル時の即時消去
- iPhone 15/16 Pro実機での表示品質
- VoiceOver読み上げ

## Technical Notes

### DateInterval による自動カウントダウン

`Text(timerInterval:countsDown:)`を使用することで、Widget側での定期更新が不要。iOS側が自動でカウントダウン表示を更新。

### Pause/Resume対応

Pause時は`isPaused`フラグを更新し、`newEndsAt`を再計算してActivity更新。Resume時も同様。

### エラーハンドリング

- Live Activity無効時: 静かにスキップ（ログのみ）
- Activity作成失敗: try?でキャッチ、アプリ機能に影響なし
- 既存Activity存在: 終了してから新規作成

### Accessibility

- 残り時間にVoiceOverラベル追加
- アイコンに`accessibilityLabel("Open TsukiUsagi Timer")`
- コントラスト比はDesignTokensで担保

### Performance

- 画像は軽量化（1x/2x/3x適切に用意）
- ブラー等の重い処理は使用しない
- 更新はPause/Resumeのみ（基本不要）

## File Structure

```
TsukiUsagi/
├── Application/
│   ├── Managers/
│   │   └── LiveActivityManager.swift (新規)
│   └── Services/
│       └── DeepLinkRouter.swift (新規)
├── Features/Timer/ViewModels/
│   └── TimerViewModel.swift (編集)
└── Entry/
    └── TsukiUsagiApp.swift (編集)

TsukiUsagiLiveActivity/ (新規Target)
├── TimerActivityAttributes.swift
├── TimerLiveActivityWidget.swift
├── Assets.xcassets/
│   ├── tsukiusagi_logo_expanded.imageset/
│   ├── tsukiusagi_logo_compact.imageset/
│   └── tsukiusagi_logo_minimal.imageset/
└── Info.plist
```

## Rollout Plan

1. **MVP** (本実装): 表示のみ、タップで復帰
2. **V2**: App Intents統合、Pause/Resumeボタン追加
3. **V3**: タスク名表示、複数セッション対応

## Compliance

- プライバシー: 個人情報なし（セッション名は一般名詞）
- 審査対応: 通知類似表現の濫用なし
- バックグラウンドモード: 不正使用なし

### To-dos

- [ ] Create Widget Extension target in Xcode with ActivityKit framework
- [ ] Implement TimerActivityAttributes data model
- [ ] Create and add moon logo assets for Expanded/Compact/Minimal states
- [ ] Implement TimerLiveActivityWidget with all display states (Expanded, Compact, Minimal, Lock Screen)
- [ ] Implement LiveActivityManager for start/update/end operations
- [ ] Integrate LiveActivityManager calls into TimerViewModel lifecycle
- [ ] Implement DeepLinkRouter and URL scheme handling in TsukiUsagiApp
- [ ] Configure Info.plist for Live Activities and URL schemes
- [ ] Test all Live Activity scenarios on iPhone 15/16 Pro

