import SwiftData
import Foundation

@Model
final class RestDay {
    @Attribute(.unique) var id: UUID
    var date: Date
    var type: RestDayType
    var notes: String?
    var quality: Int // 1-5 rating of how rested the user feels
    var sleepDuration: TimeInterval? // in seconds, synced from HealthKit
    var sleepQuality: Double? // 0-1, from HealthKit sleep analysis
    var musclesSore: [String] // Array of muscle groups that are sore
    var energyLevel: Int // 1-5 rating
    var stressLevel: Int // 1-5 rating
    var createdAt: Date

    init(
        date: Date,
        type: RestDayType,
        notes: String? = nil,
        quality: Int = 3,
        sleepDuration: TimeInterval? = nil,
        sleepQuality: Double? = nil,
        musclesSore: [String] = [],
        energyLevel: Int = 3,
        stressLevel: Int = 3
    ) {
        self.id = UUID()
        self.date = date
        self.type = type
        self.notes = notes
        self.quality = quality
        self.sleepDuration = sleepDuration
        self.sleepQuality = sleepQuality
        self.musclesSore = musclesSore
        self.energyLevel = energyLevel
        self.stressLevel = stressLevel
        self.createdAt = Date()
    }
}

enum RestDayType: String, Codable {
    case active // Light activity, stretching, walking
    case complete // Full rest, no exercise
    case scheduled // Planned rest day in program
    case recovery // Recovery from overtraining/injury
}

extension RestDay {
    var formattedSleepDuration: String {
        guard let duration = sleepDuration else { return "N/A" }
        let hours = Int(duration / 3600)
        let minutes = Int((duration.truncatingRemainder(dividingBy: 3600)) / 60)
        return "\(hours)h \(minutes)m"
    }

    var sleepQualityPercentage: Int {
        guard let quality = sleepQuality else { return 0 }
        return Int(quality * 100)
    }

    var recoveryScore: Double {
        // Calculate overall recovery score based on multiple factors
        // Sleep (40%), Quality (30%), Energy (20%), Stress (10%)
        let sleepScore = sleepQuality ?? 0.5
        let qualityScore = Double(quality) / 5.0
        let energyScore = Double(energyLevel) / 5.0
        let stressScore = 1.0 - (Double(stressLevel) / 5.0) // Lower stress is better

        return (sleepScore * 0.4) + (qualityScore * 0.3) + (energyScore * 0.2) + (stressScore * 0.1)
    }

    var recoveryStatus: RecoveryStatus {
        let score = recoveryScore
        if score >= 0.8 {
            return .excellent
        } else if score >= 0.6 {
            return .good
        } else if score >= 0.4 {
            return .fair
        } else {
            return .poor
        }
    }
}

enum RecoveryStatus: String {
    case excellent = "Excellent"
    case good = "Good"
    case fair = "Fair"
    case poor = "Poor"

    var color: String {
        switch self {
        case .excellent: return "green"
        case .good: return "blue"
        case .fair: return "orange"
        case .poor: return "red"
        }
    }

    var emoji: String {
        switch self {
        case .excellent: return "💯"
        case .good: return "✅"
        case .fair: return "⚠️"
        case .poor: return "🔴"
        }
    }
}
