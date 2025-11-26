import SwiftData
import Foundation

@Model
final class RecoveryMetrics {
    @Attribute(.unique) var id: UUID
    var date: Date

    // Sleep metrics from HealthKit
    var sleepDuration: TimeInterval? // Total sleep in seconds
    var sleepQuality: Double? // 0-1 quality score
    var deepSleepDuration: TimeInterval? // Deep sleep in seconds
    var remSleepDuration: TimeInterval? // REM sleep in seconds

    // Recovery metrics
    var restingHeartRate: Double? // BPM from HealthKit
    var heartRateVariability: Double? // HRV in milliseconds

    // User-reported metrics
    var muscleRecovery: [MuscleGroupRecovery]
    var overallFatigue: Int // 1-5, lower is less fatigued
    var motivationLevel: Int // 1-5

    var createdAt: Date
    var updatedAt: Date

    init(date: Date) {
        self.id = UUID()
        self.date = date
        self.muscleRecovery = []
        self.overallFatigue = 3
        self.motivationLevel = 3
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}

struct MuscleGroupRecovery: Codable {
    var muscleGroup: String // e.g., "Chest", "Back", "Legs"
    var sorenessLevel: Int // 1-5, higher is more sore
    var lastWorked: Date?

    var isFullyRecovered: Bool {
        sorenessLevel <= 2
    }

    var recoveryPercentage: Double {
        return 1.0 - (Double(sorenessLevel) / 5.0)
    }
}

extension RecoveryMetrics {
    var formattedSleepDuration: String {
        guard let duration = sleepDuration else { return "N/A" }
        let hours = Int(duration / 3600)
        let minutes = Int((duration.truncatingRemainder(dividingBy: 3600)) / 60)
        return "\(hours)h \(minutes)m"
    }

    var formattedDeepSleep: String {
        guard let duration = deepSleepDuration else { return "N/A" }
        let minutes = Int(duration / 60)
        return "\(minutes) min"
    }

    var formattedREMSleep: String {
        guard let duration = remSleepDuration else { return "N/A" }
        let minutes = Int(duration / 60)
        return "\(minutes) min"
    }

    var sleepEfficiency: Double? {
        guard let total = sleepDuration, total > 0 else { return nil }
        let deep = deepSleepDuration ?? 0
        let rem = remSleepDuration ?? 0
        return (deep + rem) / total
    }

    var overallRecoveryScore: Double {
        var score = 0.0
        var components = 0

        // Sleep score (40%)
        if let quality = sleepQuality {
            score += quality * 0.4
            components += 1
        }

        // Fatigue score (30%) - inverted so lower fatigue = higher score
        let fatigueScore = (1.0 - (Double(overallFatigue) / 5.0)) * 0.3
        score += fatigueScore
        components += 1

        // Muscle recovery score (20%)
        if !muscleRecovery.isEmpty {
            let avgRecovery = muscleRecovery.reduce(0.0) { $0 + $1.recoveryPercentage } / Double(muscleRecovery.count)
            score += avgRecovery * 0.2
            components += 1
        }

        // Motivation score (10%)
        score += (Double(motivationLevel) / 5.0) * 0.1
        components += 1

        return score
    }

    var readinessToTrain: TrainingReadiness {
        let score = overallRecoveryScore
        if score >= 0.8 {
            return .optimal
        } else if score >= 0.6 {
            return .ready
        } else if score >= 0.4 {
            return .moderate
        } else {
            return .needsRest
        }
    }
}

enum TrainingReadiness: String {
    case optimal = "Optimal"
    case ready = "Ready"
    case moderate = "Moderate"
    case needsRest = "Needs Rest"

    var recommendation: String {
        switch self {
        case .optimal:
            return "You're fully recovered! Great day for a challenging workout."
        case .ready:
            return "Good to train. Your body is ready for exercise."
        case .moderate:
            return "Consider a lighter workout or focus on less fatigued muscle groups."
        case .needsRest:
            return "Your body needs rest. Consider taking a rest day or very light activity."
        }
    }

    var color: String {
        switch self {
        case .optimal: return "green"
        case .ready: return "blue"
        case .moderate: return "orange"
        case .needsRest: return "red"
        }
    }
}
