import XCTest
@testable import gochange

@MainActor
final class FitnessViewModelTests: XCTestCase {
    func testCardioFocusPercentage_notHardcoded() {
        let vm = FitnessViewModel()
        XCTAssertNotEqual(vm.cardioFocusPercentage, 0.94,
            "cardioFocusPercentage should not be hardcoded to 0.94")
    }

    func testStrainScore_startsAtZeroWithNoData() {
        let vm = FitnessViewModel()
        XCTAssertEqual(vm.strainScore, 0,
            "Strain should start at 0 with no data")
    }
}
