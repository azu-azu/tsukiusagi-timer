import SwiftUI
import Foundation

extension ContentView {
    // MARK: - Recorded Times Components

    struct RecordedTimesLayerParams {
        let isLandscape: Bool
        let safeAreaInsets: EdgeInsets
        let isSessionFinished: Bool
        let isWorkSession: Bool
        let formattedStartTime: String
        let formattedEndTime: String
        let actualSessionMinutes: Int
        let showingEditRecord: Binding<Bool>
    }

    @ViewBuilder
    func recordedTimesLayer(params: RecordedTimesLayerParams) -> some View {
        // RecordedTimesViewを縦画面時のみfooterBarの直上に追加（位置は従来のまま）
        if params.isSessionFinished && !params.isWorkSession && !params.isLandscape {
            RecordedTimesView(
                formattedStartTime: params.formattedStartTime,
                formattedEndTime: params.formattedEndTime,
                actualSessionMinutes: params.actualSessionMinutes,
                onEdit: { params.showingEditRecord.wrappedValue = true }
            )
            .sessionVisibility(isVisible: params.isSessionFinished)
            .padding(.bottom, AppConstants.footerBarHeight +
                    params.safeAreaInsets.bottom + AppConstants.recordedTimesBottomSpacing)
            .zIndex(AppConstants.overlayZIndex)
        }
    }
}
