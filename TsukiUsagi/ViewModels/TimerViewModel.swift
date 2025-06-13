//
//  TimerViewModel.swift
//  TsukiUsagi
//
//  Created by azu-azu on 2025/06/12.
//

import Foundation
import Combine

class TimerViewModel: ObservableObject {
	@Published var timeRemaining: Int = 25 * 60
	@Published var isRunning: Bool = false

	private var timer: Timer?

	func startTimer() {
		guard !isRunning else { return }
		isRunning = true

		timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
			DispatchQueue.main.async {
				if self.timeRemaining > 0 {
					self.timeRemaining -= 1
				} else {
					self.stopTimer()
				}
			}
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
}
