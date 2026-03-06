import SwiftUI

// MARK: - Color System

struct AppColors {
    // Brand
    static let primary = Color(hex: "FF5500")
    static let secondary = Color(hex: "1C1C1E")

    // Backgrounds
    static let background = Color(hex: "F5F5F7")
    static let surface = Color(hex: "FFFFFF")

    // Text
    static let textPrimary = Color(hex: "111827")
    static let textSecondary = Color(hex: "6B7280")
    static let textTertiary = Color(hex: "9CA3AF")

    // Semantic
    static let success = Color(hex: "00C896")
    static let warning = Color(hex: "F59E0B")
    static let error = Color(hex: "EF4444")

    // Workout day colors (fallback when colorHex not set)
    static func workoutColor(for name: String) -> Color {
        switch name.lowercased() {
        case "push": return Color(hex: "FF5500")
        case "pull": return Color(hex: "5C7CFA")
        case "legs": return Color(hex: "343A40")
        case "fullbody", "full body": return Color(hex: "00C896")
        case "running": return Color(hex: "FF6B6B")
        case "cycling": return Color(hex: "4ECDC4")
        case "walking": return Color(hex: "FFD93D")
        default: return Color(hex: "5C7CFA")
        }
    }
}

// MARK: - Typography

struct AppFonts {
    static func title(_ size: CGFloat = 28) -> Font {
        .system(size: size, weight: .black, design: .default)
    }

    static func rounded(_ size: CGFloat = 20, weight: Font.Weight = .bold) -> Font {
        .system(size: size, weight: weight, design: .rounded)
    }

    static func label(_ size: CGFloat = 11) -> Font {
        .system(size: size, weight: .medium, design: .default)
    }

    static func mono(_ size: CGFloat = 17, weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight, design: .monospaced)
    }
}

// MARK: - Layout

struct AppLayout {
    static let margin: CGFloat = 20.0
    static let cardPadding: CGFloat = 20.0
    static let spacing: CGFloat = 12.0
    static let sectionSpacing: CGFloat = 20.0
    static let cornerRadius: CGFloat = 24.0
    static let miniRadius: CGFloat = 20.0
    static let smallRadius: CGFloat = 12.0
}

// MARK: - Shadows

struct AppShadow {
    static let cardRadius: CGFloat = 15.0
    static let cardOpacity: Double = 0.08
    static let cardX: CGFloat = 0
    static let cardY: CGFloat = 5.0

    static let subCardRadius: CGFloat = 10.0
    static let subCardOpacity: Double = 0.05
    static let subCardY: CGFloat = 4.0
}

// MARK: - Border

struct AppBorder {
    static let color = Color.gray.opacity(0.15)
    static let width: CGFloat = 1.0
}

// MARK: - RIR Labels

struct RIRLabels {
    static func label(for rir: Int) -> String {
        switch rir {
        case 0: return "Failure"
        case 1: return "1 left"
        case 2: return "2 left"
        case 3: return "3 left"
        case 4: return "4 left"
        case 5: return "5+ left"
        default: return "\(rir) left"
        }
    }

    static func color(for rir: Int) -> Color {
        switch rir {
        case 0: return AppColors.error
        case 1: return Color(hex: "FF9500")
        case 2: return AppColors.warning
        case 3: return Color(hex: "FFD60A")
        case 4: return AppColors.success
        case 5: return Color(hex: "30D158")
        default: return AppColors.textSecondary
        }
    }
}

// MARK: - Muscle Groups

struct MuscleGroups {
    static let all = ["Chest", "Back", "Shoulders", "Biceps", "Triceps",
                      "Quads", "Hamstrings", "Glutes", "Calves", "Core", "Cardio"]

    static let radarGroups = ["Chest", "Back", "Legs", "Shoulders", "Core", "Arms"]

    static func normalize(_ group: String) -> String {
        switch group.lowercased() {
        case "quads", "hamstrings", "glutes", "calves": return "Legs"
        case "biceps", "triceps": return "Arms"
        case "abs", "obliques": return "Core"
        case "rear delts", "front delts", "side delts": return "Shoulders"
        case "lats", "traps", "rhomboids": return "Back"
        case "pecs": return "Chest"
        default: return group
        }
    }
}
