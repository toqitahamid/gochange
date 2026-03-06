import SwiftData
import Foundation

@Model
final class RestDay {
    @Attribute(.unique) var id: UUID
    @Attribute(.index) var date: Date
    var type: RestDayType
    var notes: String?
    var quality: Int? // 1-5 rating of how rested the user feels (nil if not reported)
    var sleepDuration: TimeInterval? // in seconds, synced from HealthKit
    var sleepQuality: Double? // 0-1, from HealthKit sleep analysis
    var musclesSore: [String] // Array of muscle groups that are sore
    var energyLevel: Int? // 1-5 rating (nil if not reported)
    var stressLevel: Int? // 1-5 rating (nil if not reported)
    var createdAt: Date

    init(
        date: Date,
        type: RestDayType,
        notes: String? = nil,
        quality: Int? = nil,
        sleepDuration: TimeInterval? = nil,
        sleepQuality: Double? = nil,
        musclesSore: [String] = [],
        energyLevel: Int? = nil,
        stressLevel: Int? = nil
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

    /// Check if rest day has any real data (not just defaults)
    var hasRealData: Bool {
        return sleepDuration != nil ||
               sleepQuality != nil ||
               quality != nil ||
               energyLevel != nil ||
               stressLevel != nil ||
               !musclesSore.isEmpty
    }
    
    var recoveryScore: Double? {
        // Only calculate score if we have real data
        guard hasRealData else { return nil }
        
        var score = 0.0
        var totalWeight = 0.0
        
        // Sleep score (40%)
        if let sleep = sleepQuality {
            score += sleep * 0.4
            totalWeight += 0.4
        }
        
        // Quality score (30%)
        if let qual = quality {
            score += (Double(qual) / 5.0) * 0.3
            totalWeight += 0.3
        }
        
        // Energy score (20%)
        if let energy = energyLevel {
            score += (Double(energy) / 5.0) * 0.2
            totalWeight += 0.2
        }
        
        // Stress score (10%) - Lower stress is better
        if let stress = stressLevel {
            score += (1.0 - (Double(stress) / 5.0)) * 0.1
            totalWeight += 0.1
        }
        
        guard totalWeight > 0 else { return nil }
        
        // Normalize score based on available components
        return score / totalWeight
    }

    var recoveryStatus: RecoveryStatus? {
        guard let score = recoveryScore else { return nil }
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
        case .excellent: return "#00D4AA"  // Teal - matches app's primary accent
        case .good: return "#64B5F6"       // Light Blue - matches settings icons
        case .fair: return "#FFD54F"       // Gold/Yellow - matches notification icons
        case .poor: return "#FF6B6B"       // Coral Red - matches app's red accent
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
