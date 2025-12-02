import Foundation
import SwiftData

// MARK: - Overload Suggestion Model
struct OverloadSuggestion {
    enum SuggestionType {
        case increaseWeight
        case increaseReps
        case maintain
    }

    let type: SuggestionType
    let suggestedWeight: Double?
    let suggestedReps: Int?
    let message: String
    let confidence: Double // 0.0 to 1.0
}

class ProgressiveOverloadService {
    static let shared = ProgressiveOverloadService()

    private init() {}

    /// Calculate progressive overload suggestion for an exercise
    func calculateSuggestion(
        for exerciseLog: ExerciseLog,
        previousData: [PreviousSetInfo]?
    ) -> OverloadSuggestion? {
        guard let previousSets = previousData, !previousSets.isEmpty else {
            return nil // No previous data to base suggestions on
        }

        // Filter to completed sets with valid data
        let completedPrevious = previousSets.filter { $0.weight != nil && $0.reps != nil }
        guard completedPrevious.count >= 2 else {
            return nil // Need at least 2 sets of data
        }

        // Calculate previous workout statistics
        let avgWeight = completedPrevious.compactMap { $0.weight }.reduce(0, +) / Double(completedPrevious.count)
        let avgReps = Double(completedPrevious.compactMap { $0.reps }.reduce(0, +)) / Double(completedPrevious.count)
        let allSetsCompleted = completedPrevious.count == previousSets.count

        // Determine weight increment based on unit
        let weightIncrement: Double = previousSets.first?.weightUnit == .kg ? 2.5 : 5.0

        // Strategy 1: All sets completed - ready to progress
        if allSetsCompleted && avgWeight > 0 {
            let targetReps = Double(Int(exerciseLog.sets.first?.targetReps ?? "10") ?? 10)

            // If previous reps exceeded target significantly, suggest weight increase
            if avgReps > targetReps + 1.0 {
                return OverloadSuggestion(
                    type: .increaseWeight,
                    suggestedWeight: avgWeight + weightIncrement,
                    suggestedReps: nil,
                    message: "💪 Suggested: +\(formatWeight(weightIncrement)) - You exceeded target reps last workout. Ready to progress!",
                    confidence: 0.9
                )
            }

            // If previous reps met target exactly, suggest weight increase
            if avgReps >= targetReps {
                return OverloadSuggestion(
                    type: .increaseWeight,
                    suggestedWeight: avgWeight + weightIncrement,
                    suggestedReps: nil,
                    message: "💡 Suggested: +\(formatWeight(weightIncrement)) - You completed all reps last workout. Time to progress!",
                    confidence: 0.85
                )
            }

            // If previous reps close to target, maintain weight
            if avgReps >= targetReps - 1.0 {
                return OverloadSuggestion(
                    type: .maintain,
                    suggestedWeight: avgWeight,
                    suggestedReps: nil,
                    message: "🎯 Maintain current weight - Focus on hitting all target reps consistently.",
                    confidence: 0.7
                )
            }
        }

        // Strategy 2: Not all sets completed - focus on consistency
        if !allSetsCompleted {
            return OverloadSuggestion(
                type: .maintain,
                suggestedWeight: avgWeight,
                suggestedReps: nil,
                message: "📊 Maintain weight - Complete all sets before increasing load.",
                confidence: 0.8
            )
        }

        // Strategy 3: Significant drop in performance - suggest deload
        let targetRepsString = exerciseLog.sets.first?.targetReps ?? "10"
        let targetRepsInt = Int(targetRepsString) ?? 10
        let targetRepsDouble = Double(targetRepsInt)
        let significantDrop = targetRepsDouble - 3

        if avgReps < significantDrop {
            return OverloadSuggestion(
                type: .maintain,
                suggestedWeight: max(0, avgWeight - weightIncrement),
                suggestedReps: nil,
                message: "⚠️ Consider reducing weight - Focus on form and full range of motion.",
                confidence: 0.75
            )
        }

        return nil
    }

    /// Calculate suggestions for all exercises in a workout
    func calculateSuggestions(
        for exerciseLogs: [ExerciseLog],
        previousData: [UUID: [PreviousSetInfo]]
    ) -> [UUID: OverloadSuggestion] {
        var suggestions: [UUID: OverloadSuggestion] = [:]

        for log in exerciseLogs {
            if let suggestion = calculateSuggestion(
                for: log,
                previousData: previousData[log.exerciseId]
            ) {
                suggestions[log.exerciseId] = suggestion
            }
        }

        return suggestions
    }

    // MARK: - Helper Methods

    private func formatWeight(_ weight: Double) -> String {
        if weight == floor(weight) {
            return "\(Int(weight)) lbs"
        } else {
            return String(format: "%.1f lbs", weight)
        }
    }
}
