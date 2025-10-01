//
//  PhaseNotificationServiceable+Dummy.swift
//  TsukiUsagiTests
//
//  Created by AI Assistant on 2025/10/01.
//

import Foundation

#if DEBUG
extension PhaseNotificationServiceable {
    /// テスト・プレビュー用のデフォ実装（本番ターゲットには入れない）
    func ensureAuthorizationIfNeeded(completion: @escaping (Bool) -> Void) {
        completion(true)
    }
}
#endif
