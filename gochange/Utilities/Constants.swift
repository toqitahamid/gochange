import SwiftUI

enum AppConstants {
    // MARK: - RIR — delegates to RIRLabels in Theme.swift
    enum RIR {
        static func label(for rir: Int) -> String { RIRLabels.label(for: rir) }
        static func color(for rir: Int) -> Color { RIRLabels.color(for: rir) }
    }

    // MARK: - Default Values
    enum Defaults {
        static let restTimerDuration: TimeInterval = 90
        static let defaultRIR: Int = 2
        static let defaultWeightUnit: SetLog.WeightUnit = .lbs
    }

    // MARK: - Muscle Groups — delegates to MuscleGroups in Theme.swift
    static let muscleGroups = MuscleGroups.all
}
