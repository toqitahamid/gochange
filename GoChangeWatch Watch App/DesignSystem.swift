import SwiftUI

// MARK: - Design System for watchOS 26
// Incorporates Liquid Glass aesthetic and modern design patterns

extension Color {
    // MARK: - Brand Colors
    static let accentGreen = Color(hex: "00D4AA")
    
    // MARK: - Glassmorphic Backgrounds
    static let glassBackground = Color.white.opacity(0.1)
    static let glassBackgroundDark = Color.black.opacity(0.3)
    
    // MARK: - Gradient Helpers
    static func workoutGradient(hex: String, style: GradientStyle = .standard) -> LinearGradient {
        let baseColor = Color(hex: hex)
        switch style {
        case .standard:
            return LinearGradient(
                colors: [baseColor, baseColor.opacity(0.7)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .vibrant:
            return LinearGradient(
                colors: [baseColor.opacity(0.9), baseColor.opacity(0.6), baseColor.opacity(0.3)],
                startPoint: .top,
                endPoint: .bottom
            )
        case .subtle:
            return LinearGradient(
                colors: [baseColor.opacity(0.4), baseColor.opacity(0.2)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }
    
    static let successGradient = LinearGradient(
        colors: [Color.green, Color.green.opacity(0.6)],
        startPoint: .leading,
        endPoint: .trailing
    )
    
    static let cardGradient = LinearGradient(
        colors: [Color.white.opacity(0.15), Color.white.opacity(0.05)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    // MARK: - Hex Initializer
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 128, 128, 128)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

enum GradientStyle {
    case standard
    case vibrant
    case subtle
}

// MARK: - Typography Scale (watchOS 26 Optimized)

extension Font {
    // Display - Large numbers and key metrics
    static let displayXL = Font.system(size: 44, weight: .bold, design: .rounded)
    static let displayLarge = Font.system(size: 36, weight: .bold, design: .rounded)
    static let displayMedium = Font.system(size: 28, weight: .bold, design: .rounded)
    
    // Titles
    static let titlePrimary = Font.system(size: 20, weight: .semibold, design: .rounded)
    static let titleSecondary = Font.system(size: 17, weight: .semibold, design: .rounded)
    
    // Body
    static let bodyPrimary = Font.system(size: 16, weight: .regular, design: .rounded)
    static let bodySecondary = Font.system(size: 14, weight: .regular, design: .rounded)
    
    // Captions
    static let captionPrimary = Font.system(size: 13, weight: .medium, design: .rounded)
    static let captionSecondary = Font.system(size: 11, weight: .regular, design: .rounded)
}

// MARK: - Spacing System

enum Spacing {
    static let xs: CGFloat = 2
    static let sm: CGFloat = 4
    static let md: CGFloat = 8
    static let lg: CGFloat = 12
    static let xl: CGFloat = 16
    static let xxl: CGFloat = 24
}

// MARK: - Corner Radius

enum CornerRadius {
    static let sm: CGFloat = 8
    static let md: CGFloat = 12
    static let lg: CGFloat = 16
    static let xl: CGFloat = 20
}

// MARK: - Glassmorphic Card Style (Liquid Glass)

struct GlassCard: ViewModifier {
    var cornerRadius: CGFloat = CornerRadius.md
    var opacity: Double = 0.15
    
    func body(content: Content) -> some View {
        content
            .background(.ultraThinMaterial)
            .background(
                LinearGradient(
                    colors: [
                        Color.white.opacity(opacity),
                        Color.white.opacity(opacity * 0.5)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
    }
}

extension View {
    func glassCard(cornerRadius: CGFloat = CornerRadius.md, opacity: Double = 0.15) -> some View {
        modifier(GlassCard(cornerRadius: cornerRadius, opacity: opacity))
    }
}

// MARK: - Smooth Animation Presets

extension Animation {
    static let smoothSpring = Animation.spring(response: 0.35, dampingFraction: 0.75)
    static let quickSpring = Animation.spring(response: 0.25, dampingFraction: 0.8)
    static let gentleSpring = Animation.spring(response: 0.5, dampingFraction: 0.7)
}

// MARK: - Button Styles

struct PrimaryButtonStyle: ButtonStyle {
    var color: Color = .accentGreen
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.bodyPrimary)
            .fontWeight(.semibold)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, Spacing.lg)
            .background(
                LinearGradient(
                    colors: [color, color.opacity(0.8)],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.md))
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .animation(.quickSpring, value: configuration.isPressed)
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.bodySecondary)
            .fontWeight(.medium)
            .foregroundColor(.white.opacity(0.9))
            .frame(maxWidth: .infinity)
            .padding(.vertical, Spacing.md)
            .glassCard(opacity: 0.2)
            .overlay(
                RoundedRectangle(cornerRadius: CornerRadius.md)
                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
            )
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .animation(.quickSpring, value: configuration.isPressed)
    }
}
