import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var timerVM: TimerViewModel
    @EnvironmentObject private var historyVM: HistoryViewModel
    @EnvironmentObject private var sessionManager: SessionManager
    @Environment(\.horizontalSizeClass) private var horizontalClass
    @Environment(\.verticalSizeClass) private var verticalClass
    @Environment(\.dismiss) private var dismiss

    @AppStorage("activityLabel") private var activityLabel: String = "Work"
    @AppStorage("subtitleLabel") private var subtitleLabel: String = ""

    @FocusState private var isActivityFocused: Bool
    @FocusState private var isSubtitleFocused: Bool
    @FocusState private var dummyMemoFocused: Bool

    @State private var isKeyboardVisible: Bool = false

    private let betweenCardSpaceNarrow: CGFloat = 4
    private let betweenCardSpace: CGFloat = 24
    private let breakBottomPadding: CGFloat = 26
    private let labelCornerRadius: CGFloat = 6
    private let clipRadius: CGFloat = 30
    private let flowingStarCount: Int = 20

    let size: CGSize
    let safeAreaInsets: EdgeInsets

    private var currentShowEmptyError: Bool {
        let isCustomActivity = !["Work", "Study", "Read"].contains(activityLabel)
        return isCustomActivity
            && activityLabel.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    // ヘッダーの上余白を計算（小画面への配慮込み）
    private var headerTopPadding: CGFloat {
        // 画面高さが700未満の場合は控えめに、それ以外は標準的な余白
        let basePadding: CGFloat = size.height < 700 ? 8 : 12
        // Safe Areaがある場合はやや控えめに調整
        return safeAreaInsets.top > 0 ? min(basePadding, 10) : basePadding
    }

    var body: some View {
        NavigationStack {
            ZStack {
                // 背景（画面全体、clipされない）
                ZStack {
                    Color.cosmosBackground.ignoresSafeArea()

                    // // キーボード表示時は星を非表示
                    // if !isKeyboardVisible {
                    //     StaticStarsView(starCount: 30)
                    //         .allowsHitTesting(false)
                    //         .transition(.opacity.animation(.easeInOut(duration: 0.3)))

                    //     FlowingStarsView(
                    //         starCount: flowingStarCount,
                    //         angle: .degrees(135),
                    //         durationRange: 24 ... 40,
                    //         sizeRange: 2 ... 4,
                    //         spawnArea: nil
                    //     )
                    //     .transition(.opacity.animation(.easeInOut(duration: 0.3)))
                    // }
                }

                // コンテンツ部分のみclipShape適用
                VStack(spacing: 0) {
                    // ヘッダーを固定位置に配置（Safe Area対応の上余白を追加）
                    SettingsHeaderView(onDismiss: { dismiss() })
                        .padding(.top, headerTopPadding)
                        .debugComponent("SettingsHeaderView", position: .topLeading)
                        .background(Color.cosmosBackground)
                        .zIndex(1)

                    // スクロール可能なコンテンツ
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 0) {
                            WorkTimeSectionView()
                                .padding(.bottom, betweenCardSpaceNarrow)

                            BreakTimeSectionView()
                                .padding(.bottom, breakBottomPadding)

                            sessionLabelSection()
                                .padding(.bottom, betweenCardSpaceNarrow)

                            NavigationCardView(
                                title: "Manage Session Names",
                                destination: SessionNameManagerView().environmentObject(sessionManager),
                                isCompact: true
                            )
                            .padding(.bottom, betweenCardSpace)

                            ResetStopSectionView()
                                .padding(.bottom, betweenCardSpace)

                            NavigationCardView(
                                title: "View History",
                                destination: HistoryView().environmentObject(historyVM),
                                isCompact: true
                            )
                            .padding(.bottom, betweenCardSpace)

                            #if DEBUG
                            DebugMenuView()
                                .debugSection("DebugMenuView", position: .topLeading)
                                .padding(.bottom, betweenCardSpace)
                            #endif
                        }
                        .padding()
                    }
                    .scrollDismissesKeyboard(.interactively) // キーボード制御を改善
                    .scrollIndicators(.hidden) // スクロールインジケーターを非表示
                    .scrollBounceBehavior(.basedOnSize) // バウンス動作を制御
                    .simultaneousGesture(DragGesture()) // ジェスチャーの競合を防ぐ
                }
                .clipShape(RoundedRectangle(cornerRadius: clipRadius)) // コンテンツ部分のみクリップ
            }
            .navigationBarHidden(true) // NavigationBarを非表示
            .debugScreen(String(describing: Self.self))
            .onReceive(
                NotificationCenter.default.publisher(
                    for: UIResponder.keyboardWillShowNotification
                )
            ) { _ in
                withAnimation(.easeInOut(duration: 0.3)) {
                    isKeyboardVisible = true
                }
            }
            .onReceive(
                NotificationCenter.default.publisher(
                    for: UIResponder.keyboardWillHideNotification
                )
            ) { _ in
                withAnimation(.easeInOut(duration: 0.3)) {
                    isKeyboardVisible = false
                }
            }
            .modifier(DismissKeyboardOnTap(
                isActivityFocused: $isActivityFocused,
                isSubtitleFocused: $isSubtitleFocused,
                isMemoFocused: $dummyMemoFocused,
                isKeyboardVisible: $isKeyboardVisible
            ))
        }
    }

    private func sessionLabelSection() -> some View {
        VStack(
            alignment: .leading,
            spacing: DesignTokens.Spacing.small
        ) {
            Text("Session Label")
                .font(DesignTokens.Fonts.sectionTitle)
                .foregroundColor(DesignTokens.MoonColors.textSecondary)

            VStack(alignment: .leading, spacing: 10) {
                SessionLabelSection(
                    activity: $activityLabel,
                    descriptionText: $subtitleLabel,
                    isActivityFocused: $isActivityFocused,
                    isDescriptionFocused: $isSubtitleFocused,
                    labelCornerRadius: labelCornerRadius,
                    showEmptyError: .constant(currentShowEmptyError),
                    onDone: nil
                )
            }
            .padding(.all)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(DesignTokens.CosmosColors.cardBackground)
            )
        }
    }
}

extension UIApplication {
    func endEditing() {
        sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

struct DismissKeyboardOnTap: ViewModifier {
    var isActivityFocused: FocusState<Bool>.Binding
    var isSubtitleFocused: FocusState<Bool>.Binding
    var isMemoFocused: FocusState<Bool>.Binding
    var isKeyboardVisible: Binding<Bool>

    func body(content: Content) -> some View {
        content.onTapGesture {
            // より確実なキーボード非表示
            withAnimation(.easeInOut(duration: 0.3)) {
                isActivityFocused.wrappedValue = false
                isSubtitleFocused.wrappedValue = false
                isMemoFocused.wrappedValue = false
                isKeyboardVisible.wrappedValue = false
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                UIApplication.shared.endEditing()
            }
        }
    }
}

// 横画面判定用ユーティリティ
private func safeIsLandscape(
    size: CGSize,
    horizontalClass: UserInterfaceSizeClass?,
    verticalClass: UserInterfaceSizeClass?
) -> Bool {
    return horizontalClass == .regular || size.width > size.height
}

// キーボード高さ監視用のビューモディファイア（必要に応じて使用）
extension View {
    func keyboardHeight() -> some View {
        self.modifier(KeyboardHeightModifier())
    }
}

struct KeyboardHeightModifier: ViewModifier {
    @State private var keyboardHeight: CGFloat = 0

    func body(content: Content) -> some View {
        content
            .onReceive(
                NotificationCenter.default.publisher(
                    for: UIResponder.keyboardWillShowNotification
                )
            ) { notification in
                if let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey]
                    as? NSValue {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        keyboardHeight = keyboardFrame.cgRectValue.height
                    }
                }
            }
            .onReceive(
                NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)
            ) { _ in
                withAnimation(.easeInOut(duration: 0.3)) {
                    keyboardHeight = 0
                }
            }
            .padding(.bottom, keyboardHeight)
    }
}
