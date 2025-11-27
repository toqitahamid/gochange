import SwiftUI

struct SetInputView: View {
    @Binding var weight: Double
    @Binding var reps: Int
    let weightUnit: String
    
    @State private var isEditingWeight = true
    @FocusState private var weightFocused: Bool
    @FocusState private var repsFocused: Bool
    
    var body: some View {
        HStack(spacing: Spacing.md) {
            // Weight Input
            inputCard(
                title: "WEIGHT",
                value: String(format: "%.1f", weight),
                unit: weightUnit,
                isFocused: isEditingWeight
            )
            .id("weightInput")
            .focusable(true)
            .focused($weightFocused)
            .digitalCrownRotation(
                $weight,
                from: 0,
                through: 500,
                by: 2.5,
                sensitivity: .medium,
                isContinuous: false,
                isHapticFeedbackEnabled: true
            )
            .onTapGesture {
                withAnimation(.smoothSpring) {
                    isEditingWeight = true
                    weightFocused = true
                }
            }
            
            // Reps Input
            inputCard(
                title: "REPS",
                value: "\(reps)",
                unit: "",
                isFocused: !isEditingWeight
            )
            .id("repsInput")
            .focusable(true)
            .focused($repsFocused)
            .digitalCrownRotation(
                Binding(
                    get: { Double(reps) },
                    set: { reps = max(0, Int($0)) }
                ),
                from: 0,
                through: 100,
                by: 1,
                sensitivity: .low,
                isContinuous: false,
                isHapticFeedbackEnabled: true
            )
            .onTapGesture {
                withAnimation(.smoothSpring) {
                    isEditingWeight = false
                    repsFocused = true
                }
            }
        }
    }
    
    private func inputCard(title: String, value: String, unit: String, isFocused: Bool) -> some View {
        VStack(spacing: Spacing.xs) {
            Text(title)
                .font(.captionSecondary)
                .foregroundColor(.white.opacity(0.6))
                .tracking(1)
            
            VStack(spacing: 0) {
                Text(value)
                    .font(.displayMedium)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .minimumScaleFactor(0.8)
                    .lineLimit(1)
                
                if !unit.isEmpty {
                    Text(unit)
                        .font(.captionPrimary)
                        .foregroundColor(.white.opacity(0.7))
                }
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 80)
        .background(
            RoundedRectangle(cornerRadius: CornerRadius.lg)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: CornerRadius.lg)
                        .stroke(
                            LinearGradient(
                                colors: [.white, .white.opacity(0.3)],
                                startPoint: .top,
                                endPoint: .bottom
                            ),
                            lineWidth: isFocused ? 2 : 0
                        )
                )
                .shadow(color: isFocused ? .white.opacity(0.2) : .clear, radius: 8)
        )
        .scaleEffect(isFocused ? 1.05 : 1.0)
    }
}

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        SetInputView(
            weight: .constant(135),
            reps: .constant(8),
            weightUnit: "lbs"
        )
    }
}

