import XCTest
@testable import gochange

final class ThemeTests: XCTestCase {
    func testAppColorsExist() {
        let _ = AppColors.primary
        let _ = AppColors.secondary
        let _ = AppColors.background
        let _ = AppColors.surface
        let _ = AppColors.textPrimary
        let _ = AppColors.textSecondary
        let _ = AppColors.textTertiary
        let _ = AppColors.success
        let _ = AppColors.warning
        let _ = AppColors.error
    }

    func testAppLayoutConstants() {
        XCTAssertEqual(AppLayout.cornerRadius, 24.0)
        XCTAssertEqual(AppLayout.miniRadius, 20.0)
        XCTAssertEqual(AppLayout.cardPadding, 20.0)
        XCTAssertEqual(AppLayout.margin, 20.0)
        XCTAssertEqual(AppLayout.spacing, 12.0)
    }

    func testAppShadowConstants() {
        XCTAssertEqual(AppShadow.cardRadius, 15.0)
        XCTAssertEqual(AppShadow.cardOpacity, 0.08)
        XCTAssertEqual(AppShadow.cardY, 5.0)
    }

    func testWorkoutColorForName() {
        let pushColor = AppColors.workoutColor(for: "Push")
        XCTAssertNotNil(pushColor)
    }
}
