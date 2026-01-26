import SwiftUI

// MARK: - 1. Color System ("The Clinical Lab")

struct AppColors {
    // Brand Identity
    static let primary = Color(hex: "FF5500")        // International Orange
    static let secondary = Color(hex: "1C1C1E")      // Carbon Black (anchor)

    // Backgrounds
    static let background = Color(hex: "F5F5F7")     // Cloud Gray (app background)
    static let surface = Color(hex: "FFFFFF")        // Pure White (cards)

    // Text
    static let textPrimary = Color(hex: "111827")    // Rich Black
    static let textSecondary = Color(hex: "6B7280")  // Metallic Gray
    static let textTertiary = Color(hex: "9CA3AF")   // Light Gray

    // Semantic / Feedback
    static let success = Color(hex: "00C896")        // Mint (PRs, completion)
    static let warning = Color(hex: "F59E0B")        // Amber (high RPE, fatigue)
    static let error = Color(hex: "EF4444")          // Crimson (failure, errors)

    // Workout Temperature System (Day Types)
    struct Temperature {
        static let push = Color(hex: "FF5500")   // Heat (Orange)
        static let pull = Color(hex: "5C7CFA")   // Cool (Indigo)
        static let legs = Color(hex: "343A40")   // Earth (Dark Asphalt)
        static let fullBody = Color(hex: "00C896") // Energy (Mint)
    }
}

// MARK: - 2. Typography System ("The Blueprint")

struct AppFonts {
    /// Heavy, industrial titles for headers and card titles.
    static func title(_ size: CGFloat = 28) -> Font {
        .system(size: size, weight: .black, design: .default)
    }

    /// Rounded numbers for big stats, timers, and primary actions.
    static func rounded(_ size: CGFloat = 20, weight: Font.Weight = .bold) -> Font {
        .system(size: size, weight: weight, design: .rounded)
    }

    /// Technical labels like "LBS", "REPS", "SET". Text should be uppercased.
    static func label(_ size: CGFloat = 11) -> Font {
        .system(size: size, weight: .medium, design: .default)
    }

    /// Monospaced data for logs and tabular sets.
    static func mono(_ size: CGFloat = 17, weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight, design: .monospaced)
    }
}

// MARK: - 3. Layout Constants ("The Grid")

struct AppLayout {
    static let margin: CGFloat = 20.0        // Horizontal edge padding
    static let cardPadding: CGFloat = 20.0   // Internal card padding
    static let spacing: CGFloat = 12.0       // Standard vertical spacing
    static let cornerRadius: CGFloat = 24.0  // Dashboard cards
    static let miniRadius: CGFloat = 20.0    // Smaller HUD / grid items
}


