import SwiftUI
import Foundation

extension ContentView {
    // MARK: - Recorded Times Components

    struct RecordedTimesLayerParams {
        let isLandscape: Bool
        let safeAreaInsets: EdgeInsets
        let hasRecordedEndTime: Bool
        let isWorkSession: Bool
        let startTime: Date?
        let endTime: Date?
        let actualSessionMinutes: Int
        let showingEditRecord: Binding<Bool>
    }

    @ViewBuilder
    func recordedTimesLayer(params: RecordedTimesLayerParams) -> some View {
        // RecordedTimesViewを縦画面時のみfooterBarの直上に追加（位置は従来のまま）
        if params.hasRecordedEndTime && !params.isWorkSession && !params.isLandscape {
            RecordedTimesView(
                startTime: params.startTime,
                endTime: params.endTime,
                actualSessionMinutes: params.actualSessionMinutes,
                onEdit: { params.showingEditRecord.wrappedValue = true }
            )
            // Final time の更新で確実に再構築させる（分表示も含めて）
            .id(
                "recorded-\(Int(params.endTime?.timeIntervalSince1970 ?? 0))-\(params.actualSessionMinutes)"
            )
            .sessionVisibility(isVisible: params.hasRecordedEndTime)
            .padding(.bottom, AppConstants.footerBarHeight +
                    params.safeAreaInsets.bottom + AppConstants.recordedTimesBottomSpacing)
            .zIndex(AppConstants.overlayZIndex)
        }
    }
}
