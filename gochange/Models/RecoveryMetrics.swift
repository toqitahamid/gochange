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
    var overallFatigue: Int? // 1-5, lower is less fatigued (nil if not reported)
    var motivationLevel: Int? // 1-5 (nil if not reported)

    var createdAt: Date
    var updatedAt: Date

    init(date: Date) {
        self.id = UUID()
        self.date = date
        self.muscleRecovery = []
        self.overallFatigue = nil
        self.motivationLevel = nil
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
    /// Check if metrics have any real data
    var hasRealData: Bool {
        return sleepDuration != nil ||
               sleepQuality != nil ||
               restingHeartRate != nil ||
               heartRateVariability != nil ||
               !muscleRecovery.isEmpty ||
               overallFatigue != nil ||
               motivationLevel != nil
    }
    
    /// Check if fatigue value is user-reported
    var hasUserReportedFatigue: Bool {
        return overallFatigue != nil
    }
    
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
        var totalWeight = 0.0

        // Sleep score (40%)
        if let quality = sleepQuality {
            score += quality * 0.4
            totalWeight += 0.4
        }

        // Fatigue score (30%) - only if user-reported
        if let fatigue = overallFatigue {
            let fatigueScore = (1.0 - (Double(fatigue) / 5.0)) * 0.3
            score += fatigueScore
            totalWeight += 0.3
        }

        // Muscle recovery score (20%)
        if !muscleRecovery.isEmpty {
            let avgRecovery = muscleRecovery.reduce(0.0) { $0 + $1.recoveryPercentage } / Double(muscleRecovery.count)
            score += avgRecovery * 0.2
            totalWeight += 0.2
        }

        // Motivation score (10%) - only if user-reported
        if let motivation = motivationLevel {
            score += (Double(motivation) / 5.0) * 0.1
            totalWeight += 0.1
        }

        // If we have no real data, return 0 (or nil would be better, but Double can't be nil)
        guard totalWeight > 0 else { return 0.0 }
        
        // Normalize score based on available components
        return score / totalWeight
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
        case .optimal: return "#00D4AA"    // Teal - matches app's primary accent
        case .ready: return "#64B5F6"      // Light Blue - matches settings icons
        case .moderate: return "#FFD54F"   // Gold/Yellow - matches notification icons
        case .needsRest: return "#FF6B6B"  // Coral Red - matches app's red accent
        }
    }
}
