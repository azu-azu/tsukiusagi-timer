# TsukiUsagi プロジェクト構造

```
TsukiUsagi/
├── Assets.xcassets
├── Components/
│   ├── Buttons/
│   │   ├── KeyboardCloseButton.swift   # キーボード閉じる共通UI/Modifier
│   │   └── PlusMinusButton.swift
│   ├── Headers/
│   │   ├── CommonHeaderView.swift
│   │   └── HeaderConfiguration.swift
│   ├── CardContainer.swift
│   ├── HiddenKeyboardWarmer.swift
│   ├── NavigationCardView.swift
│   ├── OptimizedStarBackground.swift
│   ├── RoundedCard.swift
│   ├── TotalCard.swift
│   └── PlusMinusButton.swift
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
│   ├── History/
│   │   ├── Stores/
│   │   │   └── HistoryStore.swift
│   │   ├── ViewModels/
│   │   │   └── HistoryViewModel.swift
│   │   └── Views/
│   │       └── HistoryView.swift
├── Settings/
│   ├── Screens/                        ← 一画面単位（外から使われる表示の“顔”）
│   │   ├── SettingsView.swift
│   │   └── SessionNameManagerView.swift
│   │
│   ├── Components/                     ← 再利用可能なUI部品
│   │   ├── SessionNameCustomInputView.swift
│   │   ├── SessionNameSelectionView.swift
│   │   ├── SessionRowDisplayView.swift
│   │   ├── SessionRowEditingView.swift
│   │   ├── SessionRowView.swift
│   │   ├── SessionDescriptionsView.swift
│   │   └── SettingsHeaderView.swift
│   │
│   ├── Forms/                          ← 入力専用のコンポジットフォーム
│   │   └── NewSessionFormView.swift
│   │
│   ├── Sections/                       ← 画面内のセクション群（責務が大きめ）
│   │   ├── SessionList/               ← サブフォルダで整理（今はファイル名と一致）
│   │   │   ├── SessionListSectionView.swift
│   │   │   └── SessionSectionBuilder.swift
│   │   │
│   │   ├── SubtitleEdit/              ← 機能単位で固めて正解！
│   │   │   ├── DescriptionEditContent.swift
│   │   │   ├── FullSessionEditContent.swift
│   │   │   ├── SessionEditModal+Preview.swift
│   │   │   └── SubtitleEditModels.swift
│   │   │
│   │   ├── WorkTime/
│   │   │   └── WorkTimeSectionView.swift
│   │   ├── BreakTime/
│   │   │   └── BreakTimeSectionView.swift
│   │   ├── ResetStop/
│   │   │   └── ResetStopSectionView.swift
│   │   ├── ViewHistory/
│   │   │   └── ViewHistorySectionView.swift
│   │
│   ├── SheetBuilders/                 ← モーダル・シートなどを組む責務の場所
│   │   └── SessionEditSheetBuilder.swift
│   └── Timer/
│       ├── Components/
│       │   └── TimerEditHeaderView.swift
│       ├── Views/
│       │   ├── RecordedTimesView.swift
│       │   ├── TimerEditView.swift
│       │   ├── TimerPanel.swift
│       │   └── TimerTextView.swift
│       ├── ViewModels/
│       │   ├── TimerViewModel.swift
│       │   ├── TimerStateManager.swift
│       │   └── TimerSessionManager.swift
│       ├── Engine/
│       │   ├── TimerEngine.swift
│       │   └── TimerPersistenceManager.swift
│       ├── Services/
│       │   ├── NotificationManager.swift
│       │   ├── PhaseNotificationService.swift
│       │   ├── SessionHistoryService.swift
│       │   └── HapticService.swift
│       ├── Managers/
│       │   ├── HapticManager.swift
│       │   └── TimerAnimationManager.swift
│       ├── Modifiers/
│       │   └── StartPulseAnimationModifier.swift
│       ├── Utils/
│       │   └── TimeFormatterUtil.swift
│       └── Models/
│           └── PomodoroPhase.swift
├── Foundation/
│   ├── Controllers/
│   │   └── AdaptiveAnimationController.swift
│   ├── Constants/
│   │   └── AppConstants.swift
│   ├── Extensions/
│   │   ├── Array+Safe.swift
│   │   ├── Color+Hex.swift
│   │   ├── String+Trimmed.swift
│   │   ├── View+SessionVisibility.swift
│   │   ├── View+Debug.swift
│   │   └── View+Keyboard.swift
│   ├── Managers/
│   │   └── SessionManager.swift
│   ├── Utilities/
│   │   └── TimeFormatting.swift
│   ├── AccessibilityIDs.swift
│   ├── AwakeEnablerView.swift
│   ├── DesignTokens.swift
│   ├── FeatureFlags.swift
│   ├── PreviewData.swift
│   └── Formatters/
│   │   ├── DateFormatters.swift
│   │   └── TimeFormatters.swift
│   └── UIKitSupport/
│       ├── ViewModifiers.swift
│       ├── GlitterTextModifier.swift
│       ├── GradientGlitterTextModifier.swift
│       ├── GearButtonToolbar.swift
│       └── UIKitWrappers/
│           └── SelectableTextView.swift
├── Models/
│   ├── SessionEntry.swift
│   ├── SessionItem.swift
│   ├── SessionName.swift
│   └── MoonMessage.swift
└── Resources/
│   └── gif/
│       ├── gold.gif
│       ├── black_yellow.gif
│       ├── black_red.gif
│       └── blue.gif
├── Visual/
│   ├── Backgrounds/
│   │   ├── BackgroundBlack.swift
│   │   ├── BackgroundBlue.swift
│   │   ├── BackgroundGradientView.swift
│   │   ├── BackgroundLightPurple.swift
│   │   └── BackgroundPurple.swift
│   ├── Moon/
│   │   ├── CraterView.swift
│   │   ├── MoonShadow.swift
│   │   ├── MoonShape.swift
│   │   ├── MoonView.swift
│   │   └── QuietMoonView.swift
│   ├── Stars/
│   │   ├── DiamondStarsView.swift
│   │   ├── FlowingStarsView.swift
│   │   ├── SparkleStarsView.swift
│   │   └── StaticStarsView.swift
│   └── Usagi/
│       ├── MoonUsagiView.swift
│       └── JumpingUsagiView.swift


```
