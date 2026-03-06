import Foundation
import SwiftData

protocol RecoveryProviding {
    func syncRecoveryData(context: ModelContext) async
    func getTodaysMetrics(context: ModelContext) async -> RecoveryMetrics?
}
