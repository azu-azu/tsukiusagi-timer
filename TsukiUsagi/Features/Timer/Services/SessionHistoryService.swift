//
//  SessionHistoryService.swift
//  TsukiUsagi
//
//  Protocol for session history operations.
//  HistoryViewModel conforms to this protocol directly.
//

import Foundation

/// Protocol for session history service
/// Implemented by HistoryViewModel to avoid reverse dependency
protocol SessionHistoryServiceable: AnyObject {
    @MainActor func add(parameters: AddSessionParameters)
}
