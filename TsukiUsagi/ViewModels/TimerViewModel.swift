//
//  TimerViewModel.swift
//  TsukiUsagi
//
//  Created by azu-azu on 2025/06/12.
//

import Foundation
import Combine
import SwiftUI            // ← 追加 (@AppStorage 用)

class TimerViewModel: ObservableObject {
	
	// MARK: - User-configurable values
	@AppStorage("workMinutes")  private var workMinutes:  Int = 25
	@AppStorage("breakMinutes") private var breakMinutes: Int = 5
	
	// MARK: - Published state
	@Published var timeRemaining: Int = 0
	@Published var isRunning: Bool = false
	@Published var isWorkSession: Bool = true   // true=ポモドーロ, false=休憩
	
	private var timer: Timer?
	
	// MARK: - Public API
	func startTimer() {
		guard !isRunning else { return }
		isRunning = true
		
		// セッションの長さをセット
		timeRemaining = (isWorkSession ? workMinutes : breakMinutes) * 60
		
		timer = Timer.scheduledTimer(withTimeInterval: 1.0,
									 repeats: true) { [weak self] _ in
			self?.tick()
		}
	}
	
	func stopTimer() {
		timer?.invalidate()
		timer = nil
		isRunning = false
	}
	
	func formatTime() -> String {
		let minutes = timeRemaining / 60
		let seconds = timeRemaining % 60
		return String(format: "%02d:%02d", minutes, seconds)
	}
	
	// MARK: - Private helpers
	private func tick() {
		DispatchQueue.main.async {
			if self.timeRemaining > 0 {
				self.timeRemaining -= 1
			} else {
				self.sessionCompleted()
			}
		}
	}
	
	private func sessionCompleted() {
		stopTimer()
		// 次は休憩↔︎作業を切り替える
		isWorkSession.toggle()
		// 必要なら通知やバイブをここで鳴らす
	}
}
