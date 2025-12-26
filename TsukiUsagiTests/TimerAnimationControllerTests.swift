//
//  TimerAnimationControllerTests.swift
//  TsukiUsagiTests
//
//  Created by Azu on 2025/01/01.
//

import Testing
import Combine
@testable import TsukiUsagi

@MainActor
struct TimerAnimationControllerTests {

    // MARK: - Test Setup

    private func createController() -> TimerAnimationController {
        let mockHapticService = MockHapticService()
        return TimerAnimationController(hapticService: mockHapticService)
    }

    // MARK: - Initialization Tests

    @Test func testInitialization() async throws {
        let controller = createController()

        #expect(controller.flashStars == false)
        #expect(controller.shouldSuppressAnimation == false)
        #expect(controller.shouldSuppressSessionFinishedAnimation == false)
    }

    // MARK: - Animation Trigger Tests

    @Test func testTriggerStartAnimations() async throws {
        let controller = createController()

        // アニメーション抑制が無効な場合
        controller.shouldSuppressAnimation = false
        controller.triggerStartAnimations()

        #expect(controller.flashStars == true)

        // 再度発火しても true のまま（常に true を設定）
        controller.triggerStartAnimations()
        #expect(controller.flashStars == true)
    }

    @Test func testTriggerStartAnimationsWhenSuppressed() async throws {
        let controller = createController()

        // アニメーション抑制が有効な場合
        controller.shouldSuppressAnimation = true
        controller.triggerStartAnimations()

        #expect(controller.flashStars == false)
    }

    @Test func testTriggerSessionFinishedAnimations() async throws {
        let controller = createController()

        // セッション完了アニメーション抑制が無効な場合
        controller.shouldSuppressSessionFinishedAnimation = false
        controller.triggerSessionFinishedAnimations()

        #expect(controller.flashStars == true)
    }

    @Test func testTriggerSessionFinishedAnimationsWhenSuppressed() async throws {
        let controller = createController()

        // セッション完了アニメーション抑制が有効な場合
        controller.shouldSuppressSessionFinishedAnimation = true
        controller.triggerSessionFinishedAnimations()

        #expect(controller.flashStars == false)
    }

    // MARK: - Suppression Control Tests

    @Test func testSetAnimationSuppression() async throws {
        let controller = createController()

        controller.setAnimationSuppression(true)
        #expect(controller.shouldSuppressAnimation == true)

        controller.setAnimationSuppression(false)
        #expect(controller.shouldSuppressAnimation == false)
    }

    @Test func testSetSessionFinishedAnimationSuppression() async throws {
        let controller = createController()

        controller.setSessionFinishedAnimationSuppression(true)
        #expect(controller.shouldSuppressSessionFinishedAnimation == true)

        controller.setSessionFinishedAnimationSuppression(false)
        #expect(controller.shouldSuppressSessionFinishedAnimation == false)
    }

    // MARK: - Reset Tests

    @Test func testResetAnimationState() async throws {
        let controller = createController()

        // 状態を変更
        controller.flashStars = true
        controller.shouldSuppressAnimation = true
        controller.shouldSuppressSessionFinishedAnimation = true

        // リセット
        controller.resetAnimationState()

        #expect(controller.flashStars == false)
        #expect(controller.shouldSuppressAnimation == false)
        #expect(controller.shouldSuppressSessionFinishedAnimation == false)
    }

    // MARK: - Haptic Tests

    @Test func testTriggerHeavyHaptic() async throws {
        let mockHapticService = MockHapticService()
        let controller = TimerAnimationController(hapticService: mockHapticService)

        controller.triggerHeavyHaptic()

        #expect(mockHapticService.heavyImpactCalled == true)
    }
}

// MARK: - Mock Classes

private class MockHapticService: HapticServiceable {
    var heavyImpactCalled = false

    func heavyImpact() {
        heavyImpactCalled = true
    }

    func lightImpact() {
        // Mock implementation
    }

    func selectionChanged() {
        // Mock implementation
    }
}
