import SwiftUI

enum AppConstants {
    // MARK: - Workout Day Colors
    enum WorkoutColors {
        static let push = Color(hex: "#7CB9A8")      // Teal
        static let pull = Color(hex: "#9B59B6")      // Purple
        static let legs = Color(hex: "#5DADE2")      // Light Bluex
        static let fullbody = Color(hex: "#85C1E9")  // Sky Blue
        
        static func color(for workoutName: String) -> Color {
            switch workoutName.lowercased() {
            case "push": return push
            case "pull": return pull
            case "legs": return legs
            case "fullbody": return fullbody
            default: return .gray
            }
        }
    }
    
    // MARK: - RIR (Reps In Reserve) Labels
    enum RIR {
        static let labels: [Int: String] = [
            0: "Failure",
            1: "1 left",
            2: "2 left",
            3: "3 left",
            4: "4 left",
            5: "5+ left"
        ]
        
        static func label(for rir: Int) -> String {
            labels[rir] ?? "\(rir) left"
        }
        
        static func color(for rir: Int) -> Color {
            switch rir {
            case 0: return .red
            case 1: return .orange
            case 2: return .yellow
            case 3: return .green
            case 4...5: return .blue
            default: return .gray
            }
        }
    }
    
    // MARK: - Layout
    enum Layout {
        static let cardPadding: CGFloat = 16
        static let cardCornerRadius: CGFloat = 16
        static let minimumTapTarget: CGFloat = 44
        static let standardSpacing: CGFloat = 16
        static let compactSpacing: CGFloat = 8
    }
    
    // MARK: - Default Values
    enum Defaults {
        static let restTimerDuration: TimeInterval = 90 // seconds
        static let defaultRIR: Int = 2
        static let defaultWeightUnit: SetLog.WeightUnit = .lbs
    }
    
    // MARK: - Muscle Groups
    static let muscleGroups = [
        "Chest", "Back", "Shoulders", "Biceps", "Triceps",
        "Quads", "Hamstrings", "Glutes", "Calves", "Core"
    ]
}

// MARK: - App Theme
enum AppTheme {
    static let primary = Color(hex: "#2C3E50")
    static let secondary = Color(hex: "#34495E")
    static let accent = Color(hex: "#3498DB")
    static let success = Color(hex: "#27AE60")
    static let warning = Color(hex: "#F39C12")
    static let danger = Color(hex: "#E74C3C")
    
    // System-adaptive colors for dark mode support
    static let background = Color(.systemGroupedBackground)
    static let cardBackground = Color(.secondarySystemGroupedBackground)
    static let textPrimary = Color(.label)
    static let textSecondary = Color(.secondaryLabel)
    
    // Gradient backgrounds
    static let primaryGradient = LinearGradient(
        colors: [Color(hex: "#2C3E50"), Color(hex: "#34495E")],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}

