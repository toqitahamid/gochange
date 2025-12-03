import SwiftUI

// MARK: - Industrial Card
/// Core container: pure white surface with soft, diffuse shadow.
struct IndustrialCardModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(AppLayout.cardPadding)
            .background(
                RoundedRectangle(cornerRadius: AppLayout.cornerRadius, style: .continuous)
                    .fill(AppColors.surface)
                    .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 4)
                    .overlay(
                        RoundedRectangle(cornerRadius: AppLayout.cornerRadius, style: .continuous)
                            .stroke(Color.gray.opacity(0.1), lineWidth: 1)
                    )
            )
    }
}

// MARK: - Primary Mission Button (Orange Pill)
/// High-energy pill for primary actions like "Initialize Session" or "Finish Workout".
struct PrimaryPillButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(AppFonts.rounded(17, weight: .bold))
            .foregroundStyle(.white)
            .padding(.vertical, 16)
            .frame(maxWidth: .infinity)
            .background(AppColors.primary)
            .clipShape(Capsule())
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .animation(.easeOut(duration: 0.1), value: configuration.isPressed)
            .shadow(color: AppColors.primary.opacity(0.3), radius: 10, x: 0, y: 5)
    }
}

// MARK: - Liquid Glass HUD
/// For floating HUD elements like active workout timers or compact status bars.
struct LiquidGlassModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: AppLayout.miniRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: AppLayout.miniRadius, style: .continuous)
                    .stroke(.white.opacity(0.3), lineWidth: 0.5)
            )
            .shadow(color: Color.black.opacity(0.1), radius: 10, y: 5)
    }
}

// MARK: - View Extensions

extension View {
    /// Apply the standard white industrial card styling.
    func industrialCard() -> some View {
        modifier(IndustrialCardModifier())
    }

    /// Apply a Liquid Glass HUD chrome for floating overlays.
    func liquidGlass() -> some View {
        modifier(LiquidGlassModifier())
    }

    /// Technical label styling for things like "CAPACITY", "LBS", "REPS".
    func techLabel() -> some View {
        self
            .font(AppFonts.label())
            .textCase(.uppercase)
            .tracking(0.5)
            .foregroundStyle(AppColors.textSecondary)
    }
}


