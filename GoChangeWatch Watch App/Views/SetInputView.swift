import SwiftUI

struct SetInputView: View {
    @Binding var weight: Double
    @Binding var reps: Int
    let weightUnit: String
    
    @State private var isEditingWeight = true
    @FocusState private var weightFocused: Bool
    @FocusState private var repsFocused: Bool
    
    var body: some View {
        VStack(spacing: 12) {
            // Weight Input
            VStack(spacing: 4) {
                Text("Weight")
                    .font(.caption2)
                    .foregroundColor(.gray)
                
                HStack(alignment: .lastTextBaseline, spacing: 2) {
                    Text(String(format: "%.1f", weight))
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(isEditingWeight ? .green : .white)
                    Text(weightUnit)
                        .font(.caption)
                        .foregroundColor(.gray)
                }
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
                    isEditingWeight = true
                    weightFocused = true
                }
            }
            .padding(.vertical, 4)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isEditingWeight ? Color.green.opacity(0.2) : Color.clear)
            )
            
            // Reps Input
            VStack(spacing: 4) {
                Text("Reps")
                    .font(.caption2)
                    .foregroundColor(.gray)
                
                Text("\(reps)")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(!isEditingWeight ? .green : .white)
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
                        isEditingWeight = false
                        repsFocused = true
                    }
            }
            .padding(.vertical, 4)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(!isEditingWeight ? Color.green.opacity(0.2) : Color.clear)
            )
        }
    }
}

// MARK: - Quick Weight Adjustments

struct WeightAdjustmentButtons: View {
    @Binding var weight: Double
    let unit: String
    
    private var increment: Double {
        unit == "kg" ? 2.5 : 5
    }
    
    var body: some View {
        HStack(spacing: 8) {
            Button(action: { weight = max(0, weight - increment) }) {
                Image(systemName: "minus")
                    .font(.caption)
            }
            .buttonStyle(.bordered)
            .buttonBorderShape(.circle)
            
            Button(action: { weight += increment }) {
                Image(systemName: "plus")
                    .font(.caption)
            }
            .buttonStyle(.bordered)
            .buttonBorderShape(.circle)
        }
    }
}

#Preview {
    SetInputView(
        weight: .constant(135),
        reps: .constant(8),
        weightUnit: "lbs"
    )
}

