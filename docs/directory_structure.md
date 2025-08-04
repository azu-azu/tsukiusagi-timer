# TsukiUsagi プロジェクト構造

```
TsukiUsagi/
├── Assets.xcassets/
│   ├── AccentColor.colorset/
│   ├── AppIcon.appiconset/
│   ├── moonCardBG.colorset/
│   ├── moonTextMuted.colorset/
│   ├── moonTextPrimary.colorset/
│   ├── moonTextSecondary.colorset/
│   ├── usagi_1.imageset/              # うさぎキャラクター画像（SVG）
│   └── usagi_2.imageset/              # うさぎキャラクター画像（SVG）
├── GlobalComponents/                   # 全アプリ共通UI（境界明確化済み）
│   ├── Buttons/
│   │   └── KeyboardCloseButton.swift   # キーボード閉じる共通UI/Modifier
│   ├── Headers/
│   │   ├── CommonHeaderView.swift
│   │   └── HeaderConfiguration.swift
│   ├── Modals/
│   │   └── EditableModal.swift
│   ├── System/                         # システム系コンポーネント
│   │   └── AwakeEnablerView.swift      # 画面スリープ防止
│   └── RoundedCard.swift               # 汎用カードコンテナ
├── CrossFeatureUI/                     # 機能横断UI（境界明確化済み）
│   ├── Cards/                          # カード系コンポーネント
│   │   ├── CardContainer.swift
│   │   ├── NavigationCardView.swift
│   │   └── TotalCard.swift
│   ├── Controls/                       # コントロール系コンポーネント
│   │   ├── PlusMinusButton.swift
│   │   └── StartPulseAnimationModifier.swift  # 汎用パルスアニメーション
│   └── Navigation/                     # ナビゲーション関連コンポーネント
│       ├── HamburgerMenuButton.swift
│       ├── NavigationBackModifier.swift
│       └── SideMenu/                   # サイドメニュー機能
│           ├── SideMenuDurationView.swift
│           └── SideMenuView.swift
├── Entry/                              # アプリエントリポイントのみ
│   ├── AppDelegate.swift
│   ├── ContentView.swift
│   └── TsukiUsagiApp.swift
├── Features/
│   ├── App/                            # アプリメイン画面機能
│   │   └── Components/                 # メイン画面専用UI
│   │       ├── FooterBar.swift
│   │       └── MainPanel.swift
│   ├── Common/
│   │   └── SessionLabelSection.swift
│   ├── History/                        # 履歴機能
│   │   ├── Models/
│   │   │   ├── ActivityIntensity.swift
│   │   │   └── DailyHistory.swift
│   │   ├── Services/                   # データ管理（旧 Stores/）
│   │   │   └── HistoryStore.swift
│   │   ├── Helpers/
│   │   │   └── CalendarUtilities.swift
│   │   ├── ViewModels/
│   │   │   ├── HistoryViewModel+Calendar.swift
│   │   │   └── HistoryViewModel.swift
│   │   └── Views/
│   │       ├── CalendarDayCell.swift
│   │       ├── CalendarHistoryView.swift
│   │       ├── DailyDetailView.swift
│   │       ├── DailyTimelineView.swift
│   │       └── HistoryView.swift
│   ├── Settings/                       # 設定機能
│   │   ├── Components/                 # 再利用可能なUI部品
│   │   │   ├── NewSessionFormView.swift # 新規セッション作成フォーム（旧 Forms/）
│   │   │   ├── SessionDescriptionsView.swift
│   │   │   ├── SessionNameCustomInputView.swift
│   │   │   ├── SessionNameSelectionView.swift
│   │   │   ├── SessionRowDisplayView.swift
│   │   │   ├── SessionRowEditingView.swift
│   │   │   ├── SessionRowView.swift
│   │   │   └── SettingsHeaderView.swift
│   │   ├── Screens/                    # 画面単位（外から使われる表示の"顔"）
│   │   │   ├── SessionNameManagerView.swift
│   │   │   └── SettingsView.swift
│   │   ├── Sections/                   # 画面内のセクション群
│   │   │   ├── Duration/               # 時間設定セクション
│   │   │   │   ├── DurationHelpers.swift
│   │   │   │   ├── DurationSectionView.swift
│   │   │   │   └── DurationSessionSettingsView.swift
│   │   │   ├── ResetStop/
│   │   │   │   └── ResetStopSectionView.swift
│   │   │   ├── SessionList/
│   │   │   │   ├── SessionListSectionView.swift
│   │   │   │   └── SessionSectionBuilder.swift
│   │   │   ├── SubtitleEdit/
│   │   │   │   ├── DescriptionEditContent.swift
│   │   │   │   ├── FullSessionEditContent.swift
│   │   │   │   ├── SessionEditModal+Preview.swift
│   │   │   │   └── SubtitleEditModels.swift
│   │   │   └── ViewHistory/
│   │   │       └── ViewHistorySectionView.swift
│   │   └── SheetBuilders/              # モーダル・シート組み立て
│   │       └── SessionEditSheetBuilder.swift
│   ├── Streak/                         # ストリーク・実績機能
│   │   ├── Manager/
│   │   │   ├── AchievementManager.swift
│   │   │   ├── ShareManager.swift
│   │   │   ├── SmartNotificationManager.swift
│   │   │   ├── StreakManager.swift
│   │   │   └── XPManager.swift
│   │   └── Views/
│   │       ├── AchievementsView.swift
│   │       ├── Components/
│   │       │   ├── DayCircleView.swift
│   │       │   └── SmartNotificationToggleView.swift
│   │       ├── Screens/
│   │       │   └── StreakView.swift
│   │       └── Sections/
│   │           ├── TotalStreakSectionView.swift
│   │           ├── WeeklyCalendarSectionView.swift
│   │           └── WeeklyUsageSectionView.swift
│   └── Timer/                          # ポモドーロタイマー機能
│       ├── Components/
│       │   └── TimerEditHeaderView.swift
│       ├── Models/
│       │   └── PomodoroPhase.swift
│       ├── Services/                   # ビジネスロジック・外部連携（統合済み）
│       │   ├── HapticManager.swift     # 触覚フィードバック管理（旧 Managers/）
│       │   ├── HapticService.swift     # 触覚フィードバックサービス
│       │   ├── NotificationManager.swift
│       │   ├── PhaseNotificationService.swift
│       │   ├── SessionHistoryService.swift
│       │   ├── TimerAnimationManager.swift  # アニメーション管理（旧 Managers/）
│       │   ├── TimerEngine.swift       # タイマーエンジン（旧 Engine/）
│       │   └── TimerPersistenceManager.swift # 状態永続化（旧 Engine/）
│       ├── ViewModels/
│       │   ├── TimerSessionManager.swift
│       │   ├── TimerStateManager.swift
│       │   └── TimerViewModel.swift
│       └── Views/
│           ├── RecordedTimesView.swift
│           ├── TimerEditView.swift
│           ├── TimerPanel.swift
│           └── TimerTextView.swift
├── Foundation/
│   ├── Constants/
│   │   └── AppConstants.swift
│   ├── Animation/                       # アニメーション管理（命名統一済み）
│   │   ├── AdaptiveAnimationEngine+Animation.swift
│   │   ├── AdaptiveAnimationEngine+Models.swift
│   │   ├── AdaptiveAnimationEngine+System.swift
│   │   └── AdaptiveAnimationEngine.swift
│   ├── Extensions/
│   │   ├── Array+Safe.swift
│   │   ├── Color+Hex.swift
│   │   ├── Date+Streak.swift           # ストリーク用日付処理
│   │   ├── String+Trimmed.swift
│   │   ├── View+Debug+Dynamic.swift
│   │   ├── View+Debug+Hierarchical.swift
│   │   ├── View+Debug+Menu.swift
│   │   ├── View+Debug.swift
│   │   ├── View+Keyboard.swift
│   │   └── View+SessionVisibility.swift
│   ├── Formatters/                     # 時間フォーマット統合
│   │   ├── DateFormatters.swift
│   │   ├── FormatterConstants.swift    # フォーマット定数
│   │   ├── TimeFormatters.swift        # 統合済み時間フォーマット
│   │   └── TimeFormattingProtocols.swift # フォーマット共通インターフェース
│   ├── Managers/
│   │   ├── SessionManager+DescriptionManagement.swift
│   │   ├── SessionManager+Preview.swift
│   │   ├── SessionManager.swift
│   │   └── SessionManagerValidator.swift
│   ├── UIKitSupport/                    # UIKit連携（階層化済み）
│   │   ├── Modifiers/                   # SwiftUI Modifier系
│   │   │   ├── GlitterTextModifier.swift
│   │   │   ├── GradientGlitterTextModifier.swift
│   │   │   └── ViewModifiers.swift
│   │   ├── Toolbars/                    # UIKit Toolbar系
│   │   │   └── GearButtonToolbar.swift
│   │   └── Wrappers/                    # UIKit Wrapper系
│   │       └── SelectableTextView.swift
│   ├── AccessibilityIDs.swift
│   ├── DesignTokens.swift
│   ├── FeatureFlags.swift
│   └── PreviewData.swift
├── DeveloperTools/                     # 開発・デバッグ支援（本番と分離）
│   └── Debug/                          # デバッグ専用UI
│       ├── AdaptiveViews.swift         # アダプティブアニメーションビューデモ
│       └── PerformanceDebugView.swift  # パフォーマンスデバッグUI
├── Models/                             # データモデル（肥大化対策済み）
│   └── Core/                           # アプリ共通モデル
│       ├── MoonMessage.swift
│       ├── SessionEntry.swift
│       ├── SessionItem.swift
│       └── SessionName.swift
├── Resources/                          # リソースファイル（命名統一済み）
│   ├── Fonts/                          # カスタムフォント
│   │   ├── Nunito-Bold.ttf
│   │   ├── Nunito-Italic.ttf
│   │   ├── Nunito-Medium.ttf
│   │   └── Nunito-Regular.ttf
│   └── Gifs/                           # GIFアニメーション（旧 gif/）
│       ├── black_red.gif
│       ├── black_yellow.gif
│       ├── blue.gif
│       └── gold.gif
└── Visual/                             # テーマ特化視覚要素
    ├── Backgrounds/                    # コードベース背景（アセットと分離）
    │   ├── BackgroundBlue.swift
    │   ├── BackgroundGradientView.swift
    │   ├── BackgroundLightPurple.swift
    │   ├── BackgroundPurple.swift
    │   └── GalaxyBackground.swift         # アニメーション背景
    ├── Moons/                          # 月関連コンポーネント（複数形統一）
    │   ├── CraterView.swift
    │   ├── MoonShadow.swift
    │   ├── MoonShape.swift
    │   ├── MoonView.swift
    │   └── QuietMoonView.swift
    ├── Stars/                          # 星関連コンポーネント
    │   ├── DiamondStarsView.swift
    │   ├── FlowingStarsView.swift
    │   ├── OptimizedStarBackground.swift # 移動済み（旧 Components/）
    │   ├── SparkleStarsView.swift
    │   └── StaticStarsView.swift
    └── Usagis/                         # うさぎキャラクター（複数形統一）
        ├── JumpingUsagiView.swift
        └── MoonUsagiView.swift
```

## 構造変更履歴

### 最新の構造改善（2025/08/04実施）

#### 境界線明確化による迷い解消と構造最適化
- **命名改善で境界線を明確化**:
  - `Components/` → `GlobalComponents/`: 全アプリ共通UI
  - `SharedUI/` → `CrossFeatureUI/`: 機能横断UI
  - `Entry/Components/` → `Features/App/Components/`: メイン画面専用UI
- **Modelsの肥大化対策**:
  - `Models/*` → `Models/Core/*`: アプリ共通モデル
  - `Features/*/Models/`: 機能特化モデル（既存）
- **責務分離ルールの明文化**:
  - `ARCHITECTURE_GUIDELINES.md` を作成
  - UI層・ビジネスロジック層・データ層の判断フローを定義
  - Foundation/Managers vs Features/*/Services の判断基準を明確化

#### Foundation層の命名最適化と階層化
- **Foundation/Controllers** → **Foundation/Animation** にリネーム
  - SwiftUIでの適切な命名（Controller → Manager/Coordinator相当）
  - 将来のUIKit ViewControllerとの混同を防止
- **Foundation/UIKitSupport** を階層化して整理
  - `Modifiers/`: SwiftUI Modifier系（3ファイル）
  - `Toolbars/`: UIKit Toolbar系（1ファイル）
  - `Wrappers/`: UIKit Wrapper系（1ファイル）
  - 将来のUIKit関連機能拡張に対応した構造

#### 将来分離を意識した設計
- **Features/Settings** の将来分離ポイントを評価
  - **SessionManagement機能**: 独立度★★★★★（15ファイル）
  - **TimerSettings機能**: 独立度★★★★☆（3ファイル）
  - 長期的な機能肥大化への備えを完了

#### 従来の機能追加・改善
- **Components/**: `HiddenKeyboardWarmer.swift` を削除（不要なコンポーネント整理）
- **Features/History/**: カレンダー機能とデイリー詳細機能を大幅拡張
- **Features/Streak/**: 新機能として完全に追加（ストリーク・実績システム）
- **Features/Settings/Sections/Duration/**: 新しい時間設定セクションを追加
- **Foundation/Extensions/**: `Date+Streak.swift` を追加（ストリーク機能用）
- **Resources/Fonts/**: Nunitoフォントファミリーを追加（4つのバリエーション）

### 前回の構造改善（2025/07/27実施）
- **Features/Timer/**: Engine/ と Managers/ を Services/ に統合
- **Features/Timer/**: Modifiers/ を Components/Modifiers/ に移動
- **Features/Settings/**: Forms/ を Components/ に統合
- **Features/History/**: Stores/ を Services/ に変更
- **Visual/**: Moon/ → Moons/, Usagi/ → Usagis/ に複数形統一
- **Components/**: OptimizedStarBackground.swift を Visual/Stars/ に移動
- **Components/**: System/ ディレクトリ新設、AwakeEnablerView.swift を移動
- **Foundation/Formatters/**: 時間フォーマット機能を統合・整理

### 主要な追加機能
- **Streak機能**: 完全な連続記録追跡システム（実績、XP、スマート通知含む）
- **History拡張**: カレンダー表示、アクティビティ強度、日次詳細ビュー
- **Navigation強化**: サイドメニューとハンバーガーメニュー
- **Duration設定**: より詳細な時間設定オプション
- **カスタムフォント**: Nunitoフォントファミリーの統合

### 削除されたファイル
- `TsukiUsagi/Components/HiddenKeyboardWarmer.swift` → 不要なため削除

## 責務境界明確化アーキテクチャ

### UI層の境界線明確化

#### GlobalComponents/（全アプリ共通レイヤー）
- **判断基準**: プロジェクト全体で5回以上使用
- **6ファイル**: Buttons, Headers, Modals, System, RoundedCard
- **特徴**: 機能に依存しない、高い再利用性

#### CrossFeatureUI/（機能横断レイヤー）
- **判断基準**: 2-4個の機能で使用される
- **8ファイル**: Cards(3), Controls(1), Navigation(4)
- **特徴**: 機能横断的だが、特定用途に特化

#### Features/*/Components/（機能特化レイヤー）
- **判断基準**: その機能内でのみ使用
- **特徴**: 高い凝集性、機能特化

### ビジネスロジック層の分離ルール
- **Foundation/Managers**: アプリ全体で使用される状態・ロジック
- **Features/*/Services**: 機能専用の状態・ロジック
- **Features/*/ViewModels**: 特定画面の状態管理

### データ層の分離ルール
- **Models/Core**: 複数機能で共有されるデータ構造
- **Features/*/Models**: 機能固有のドメインモデル

## 統計情報
- **総Swift ファイル数**: 125ファイル
- **主要ディレクトリ数**: 9つ（Assets, Components, SharedUI, Entry, Features, Foundation, Models, Resources, Visual）
- **UI層構造**: 3層（Components, SharedUI, Features/*/Components）
- **機能モジュール数**: 5つ（Common, History, Settings, Streak, Timer）
- **Foundation層最適化**: Animation(4), UIKitSupport(3層化), 他層(6)
- **将来分離対応**: Settings機能での分離ポイント識別済み

## アーキテクチャの利点

### 短期的メリット
- **開発者の迷い軽減**: 「どこに置くべきか」が明確
- **責務の明確化**: 汎用性レベルによる自然な分離
- **保守性向上**: 変更影響範囲の予測が容易
- **再利用促進**: 適切なレイヤーでの部品発見が簡単

### 長期的メリット
- **機能分離の容易さ**: Settingsの分離ポイントが明確
- **UIKit連携拡張性**: 階層化されたUIKitSupportで雑多化を防止
- **命名統一性**: SwiftUIに適した命名で混同を回避
- **コードベースの持続性**: 将来の肥大化に対する耐性

この構造は `/docs/structure-guidelines.md` で定められた標準に完全準拠し、最新の機能追加と組織改善を反映しています。