import XCTest
@testable import gochange

@MainActor
final class HomeViewModelTests: XCTestCase {
    var sut: HomeViewModel!
    var mockHealth: MockHealthDataProvider!

    override func setUp() {
        mockHealth = MockHealthDataProvider()
        sut = HomeViewModel(healthProvider: mockHealth)
    }

    func testRecoveryScore_withGoodHRVAndLowRHR_returnsHighScore() async {
        mockHealth.hrvValue = 65.0
        mockHealth.rhrValue = 55.0
        await sut.loadData(context: nil)
        XCTAssertGreaterThanOrEqual(sut.recoveryScore, 70)
    }

    func testRecoveryScore_withLowHRVAndHighRHR_returnsLowScore() async {
        mockHealth.hrvValue = 20.0
        mockHealth.rhrValue = 85.0
        await sut.loadData(context: nil)
        XCTAssertLessThanOrEqual(sut.recoveryScore, 40)
    }

    func testRecoveryScore_withNoData_returnsZero() async {
        mockHealth.hrvValue = nil
        mockHealth.rhrValue = nil
        await sut.loadData(context: nil)
        XCTAssertEqual(sut.recoveryScore, 0)
    }

    func testSleepScore_withGoodSleep_returnsHighScore() async {
        mockHealth.sleepData = SleepData(
            totalDuration: 8 * 3600,
            deepDuration: 1.8 * 3600,
            remDuration: 2.0 * 3600,
            coreDuration: 4.2 * 3600,
            quality: 0.9,
            startDate: nil, endDate: nil
        )
        await sut.loadData(context: nil)
        XCTAssertGreaterThanOrEqual(sut.sleepScore, 70)
    }

    func testSleepScore_withNoData_returnsZero() async {
        mockHealth.sleepData = nil
        await sut.loadData(context: nil)
        XCTAssertEqual(sut.sleepScore, 0)
    }

    func testStrainScore_withActiveEnergy_calculatesFromRealData() async {
        mockHealth.activeEnergy = 600.0
        mockHealth.exerciseTime = 60.0
        await sut.loadData(context: nil)
        XCTAssertGreaterThan(sut.strainScore, 0)
    }

    func testStrainScore_withNoActivity_returnsZero() async {
        mockHealth.activeEnergy = nil
        mockHealth.exerciseTime = nil
        await sut.loadData(context: nil)
        XCTAssertEqual(sut.strainScore, 0)
    }

    func testActivityRings_populatedFromHealthKit() async {
        mockHealth.activeEnergy = 450.0
        mockHealth.exerciseTime = 35.0
        mockHealth.standHours = 9
        await sut.loadData(context: nil)
        XCTAssertEqual(sut.moveCalories, 450.0)
        XCTAssertEqual(sut.exerciseMinutes, 35.0)
        XCTAssertEqual(sut.standHours, 9)
    }

    func testLoadState_startsIdle() {
        XCTAssertEqual(sut.loadState, .idle)
    }

    func testLoadState_transitionsToLoadedAfterFetch() async {
        await sut.loadData(context: nil)
        XCTAssertEqual(sut.loadState, .loaded)
    }

    func testDailyInsight_neverContainsRandomValues() async {
        await sut.loadData(context: nil)
        let insight = sut.insightText
        let insight2 = sut.insightText
        XCTAssertEqual(insight, insight2, "Insight text should be deterministic, not random")
    }
}
