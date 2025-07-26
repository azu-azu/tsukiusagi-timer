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
│   ├── usagi_1.imageset/
│   └── usagi_2.imageset/
├── Components/
│   ├── Buttons/
│   │   └── KeyboardCloseButton.swift   # キーボード閉じる共通UI/Modifier
│   ├── Headers/
│   │   ├── CommonHeaderView.swift
│   │   └── HeaderConfiguration.swift
│   ├── Modals/
│   │   └── EditableModal.swift
│   ├── System/                         # システム系コンポーネント
│   │   └── AwakeEnablerView.swift      # 画面スリープ防止
│   ├── CardContainer.swift
│   ├── NavigationCardView.swift
│   ├── PlusMinusButton.swift
│   ├── RoundedCard.swift
│   └── TotalCard.swift
├── Entry/
│   ├── Components/
│   │   ├── FooterBar.swift
│   │   └── MainPanel.swift
│   ├── AppDelegate.swift
│   ├── ContentView.swift
│   └── TsukiUsagiApp.swift
├── Features/
│   ├── Common/
│   │   └── SessionLabelSection.swift
│   ├── History/                         # 履歴機能
│   │   ├── Services/                    # データ管理（旧 Stores/）
│   │   │   └── HistoryStore.swift
│   │   ├── ViewModels/
│   │   │   └── HistoryViewModel.swift
│   │   └── Views/
│   │       └── HistoryView.swift
│   ├── Settings/                        # 設定機能
│   │   ├── Components/                  # 再利用可能なUI部品
│   │   │   ├── NewSessionFormView.swift # 新規セッション作成フォーム（旧 Forms/）
│   │   │   ├── SessionDescriptionsView.swift
│   │   │   ├── SessionNameCustomInputView.swift
│   │   │   ├── SessionNameSelectionView.swift
│   │   │   ├── SessionRowDisplayView.swift
│   │   │   ├── SessionRowEditingView.swift
│   │   │   ├── SessionRowView.swift
│   │   │   └── SettingsHeaderView.swift
│   │   ├── Screens/                     # 画面単位（外から使われる表示の"顔"）
│   │   │   ├── SessionNameManagerView.swift
│   │   │   └── SettingsView.swift
│   │   ├── Sections/                    # 画面内のセクション群
│   │   │   ├── BreakTime/
│   │   │   │   └── BreakTimeSectionView.swift
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
│   │   │   ├── ViewHistory/
│   │   │   │   └── ViewHistorySectionView.swift
│   │   │   └── WorkTime/
│   │   │       └── WorkTimeSectionView.swift
│   │   └── SheetBuilders/               # モーダル・シート組み立て
│   │       └── SessionEditSheetBuilder.swift
│   └── Timer/                           # ポモドーロタイマー機能
│       ├── Components/
│       │   ├── Modifiers/               # UIモディファイア（旧 Modifiers/）
│       │   │   └── StartPulseAnimationModifier.swift
│       │   └── TimerEditHeaderView.swift
│       ├── Models/
│       │   └── PomodoroPhase.swift
│       ├── Services/                    # ビジネスロジック・外部連携（統合済み）
│       │   ├── HapticManager.swift      # 触覚フィードバック管理（旧 Managers/）
│       │   ├── HapticService.swift      # 触覚フィードバックサービス
│       │   ├── NotificationManager.swift
│       │   ├── PhaseNotificationService.swift
│       │   ├── SessionHistoryService.swift
│       │   ├── TimerAnimationManager.swift  # アニメーション管理（旧 Managers/）
│       │   ├── TimerEngine.swift        # タイマーエンジン（旧 Engine/）
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
│   ├── Controllers/
│   │   ├── AdaptiveAnimationController+Animation.swift
│   │   ├── AdaptiveAnimationController+Models.swift
│   │   ├── AdaptiveAnimationController+System.swift
│   │   └── AdaptiveAnimationController.swift
│   ├── Extensions/
│   │   ├── Array+Safe.swift
│   │   ├── Color+Hex.swift
│   │   ├── String+Trimmed.swift
│   │   ├── View+Debug+Dynamic.swift
│   │   ├── View+Debug+Hierarchical.swift
│   │   ├── View+Debug+Menu.swift
│   │   ├── View+Debug.swift
│   │   ├── View+Keyboard.swift
│   │   └── View+SessionVisibility.swift
│   ├── Formatters/                      # 時間フォーマット統合
│   │   ├── DateFormatters.swift
│   │   ├── FormatterConstants.swift     # フォーマット定数
│   │   ├── TimeFormatters.swift         # 統合済み時間フォーマット
│   │   └── TimeFormattingProtocols.swift # フォーマット共通インターフェース
│   ├── Managers/
│   │   ├── SessionManager+DescriptionManagement.swift
│   │   ├── SessionManager+Preview.swift
│   │   ├── SessionManager.swift
│   │   └── SessionManagerValidator.swift
│   ├── UIKitSupport/
│   │   ├── GearButtonToolbar.swift
│   │   ├── GlitterTextModifier.swift
│   │   ├── GradientGlitterTextModifier.swift
│   │   ├── UIKitWrappers/
│   │   │   └── SelectableTextView.swift
│   │   └── ViewModifiers.swift
│   ├── Views/
│   │   ├── AdaptiveViews.swift
│   │   └── PerformanceDebugView.swift
│   ├── AccessibilityIDs.swift
│   ├── DesignTokens.swift
│   ├── FeatureFlags.swift
│   └── PreviewData.swift
├── Models/
│   ├── MoonMessage.swift
│   ├── SessionEntry.swift
│   ├── SessionItem.swift
│   └── SessionName.swift
├── Resources/
│   └── gif/
│       ├── black_red.gif
│       ├── black_yellow.gif
│       ├── blue.gif
│       └── gold.gif
├── Visual/                              # テーマ特化視覚要素
│   ├── Backgrounds/
│   │   ├── BackgroundBlue.swift
│   │   ├── BackgroundGradientView.swift
│   │   ├── BackgroundLightPurple.swift
│   │   ├── BackgroundPurple.swift
│   │   └── GalaxyBackground.swift
│   ├── Moons/                           # 月関連コンポーネント（複数形統一）
│   │   ├── CraterView.swift
│   │   ├── MoonShadow.swift
│   │   ├── MoonShape.swift
│   │   ├── MoonView.swift
│   │   └── QuietMoonView.swift
│   ├── Stars/                           # 星関連コンポーネント
│   │   ├── DiamondStarsView.swift
│   │   ├── FlowingStarsView.swift
│   │   ├── OptimizedStarBackground.swift # 移動済み（旧 Components/）
│   │   ├── SparkleStarsView.swift
│   │   └── StaticStarsView.swift
│   └── Usagis/                          # うさぎキャラクター（複数形統一）
│       ├── JumpingUsagiView.swift
│       └── MoonUsagiView.swift
└── SimpleSubtitleTest.swift             # テスト用ファイル
```

## 構造変更履歴

### 最新の構造改善（2025/07/27実施）
- **Features/Timer/**: Engine/ と Managers/ を Services/ に統合
- **Features/Timer/**: Modifiers/ を Components/Modifiers/ に移動
- **Features/Settings/**: Forms/ を Components/ に統合
- **Features/History/**: Stores/ を Services/ に変更
- **Visual/**: Moon/ → Moons/, Usagi/ → Usagis/ に複数形統一
- **Components/**: OptimizedStarBackground.swift を Visual/Stars/ に移動
- **Components/**: System/ ディレクトリ新設、AwakeEnablerView.swift を移動
- **Foundation/Formatters/**: 時間フォーマット機能を統合・整理
  - TimeFormattingProtocols.swift（新規）
  - FormatterConstants.swift（新規）
  - TimeFormatters.swift（機能統合）
  - 重複ファイル削除：TimeFormatting.swift, TimeFormatterUtil.swift

### 削除されたディレクトリ
- `Features/Timer/Engine/` → `Features/Timer/Services/` に統合
- `Features/Timer/Managers/` → `Features/Timer/Services/` に統合
- `Features/Timer/Modifiers/` → `Features/Timer/Components/Modifiers/` に移動
- `Features/Timer/Utils/` → 時間フォーマット機能は Foundation/Formatters/ に統合
- `Features/Settings/Forms/` → `Features/Settings/Components/` に統合
- `Features/History/Stores/` → `Features/History/Services/` に変更
- `Visual/Moon/` → `Visual/Moons/` にリネーム
- `Visual/Usagi/` → `Visual/Usagis/` にリネーム
- `Foundation/Utilities/TimeFormatting.swift` → 削除（統合済み）

この構造は `/docs/structure-guidelines.md` で定められた標準に完全準拠しています。