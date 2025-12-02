import SwiftUI

struct SetInputCard: View {
    @Binding var setLog: SetLog
    let accentColor: Color
    let previousSet: PreviousSetInfo?
    let onRemove: (() -> Void)?
    let onToggleCompletion: () -> Void

    @State private var weightText: String = ""
    @State private var repsText: String = ""
    @FocusState private var focusedField: Field?

    enum Field {
        case weight, reps
    }

    private var previousDataText: String? {
        guard let prev = previousSet,
              let weight = prev.weight,
              let reps = prev.reps else { return nil }
        return "\(Int(weight))×\(reps)"
    }

    var body: some View {
        VStack(spacing: 0) {
            // Set Header
            HStack {
                // Set Number Badge
                Text("SET \(setLog.setNumber)")
                    .font(.system(size: 11, weight: .bold))
                    .tracking(1.2)
                    .foregroundColor(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(
                        Capsule()
                            .fill(setLog.isCompleted ? Color(hex: "#00D4AA") : Color(hex: setLog.setType.color))
                    )

                // Set Type Selector
                Menu {
                    ForEach([SetLog.SetType.normal, .warmup, .cooldown, .failure, .dropset], id: \.self) { type in
                        Button {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                setLog.setType = type
                            }
                        } label: {
                            Label(type.displayName, systemImage: type.icon)
                        }
                    }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: setLog.setType.icon)
                            .font(.system(size: 10, weight: .semibold))
                        Image(systemName: "chevron.down")
                            .font(.system(size: 8, weight: .bold))
                    }
                    .foregroundColor(Color(hex: setLog.setType.color))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 5)
                    .background(
                        Capsule()
                            .fill(Color(hex: setLog.setType.color).opacity(0.12))
                    )
                }
                .disabled(setLog.isCompleted)

                Spacer()

                // Target Reps
                Text("Target: \(setLog.targetReps) reps")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.secondary)

                // Completion Checkbox
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        onToggleCompletion()
                    }
                } label: {
                    ZStack {
                        Circle()
                            .stroke(setLog.isCompleted ? Color(hex: "#00D4AA") : Color.gray.opacity(0.3), lineWidth: 2)
                            .frame(width: 28, height: 28)

                        if setLog.isCompleted {
                            Circle()
                                .fill(Color(hex: "#00D4AA"))
                                .frame(width: 28, height: 28)

                            Image(systemName: "checkmark")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.white)
                        }
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 14)
            .padding(.bottom, 8)

            // Previous Data (if available)
            if let prevText = previousDataText {
                HStack {
                    Text("Previous: \(prevText)")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(Color(hex: "#00D4AA").opacity(0.8))

                    Spacer()

                    // Quick Copy Button
                    Button {
                        copyPreviousData()
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "doc.on.doc.fill")
                                .font(.system(size: 11))
                            Text("Copy")
                                .font(.system(size: 11, weight: .semibold))
                        }
                        .foregroundColor(Color(hex: "#5B7FFF"))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(
                            Capsule()
                                .fill(Color(hex: "#5B7FFF").opacity(0.12))
                        )
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 12)
            }

            Divider()
                .padding(.horizontal, 16)

            // Input Fields
            VStack(spacing: 16) {
                // Weight Input
                HStack(spacing: 12) {
                    Text("Weight")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.secondary)
                        .frame(width: 60, alignment: .leading)

                    // Decrement Button
                    Button {
                        adjustWeight(by: -5)
                    } label: {
                        Image(systemName: "minus.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(accentColor.opacity(0.7))
                    }
                    .disabled(setLog.isCompleted)

                    // Weight TextField
                    TextField("0", text: $weightText)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.center)
                        .font(.system(size: 18, weight: .semibold, design: .rounded))
                        .foregroundColor(.primary)
                        .frame(width: 70)
                        .padding(.vertical, 10)
                        .background(Color.gray.opacity(0.08))
                        .cornerRadius(10)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(focusedField == .weight ? accentColor : Color.clear, lineWidth: 2)
                        )
                        .focused($focusedField, equals: .weight)
                        .disabled(setLog.isCompleted)
                        .onChange(of: weightText) { _, newValue in
                            setLog.weight = Double(newValue)
                        }

                    Text(setLog.weightUnit.rawValue)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.secondary)

                    // Increment Button
                    Button {
                        adjustWeight(by: 5)
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(accentColor)
                    }
                    .disabled(setLog.isCompleted)
                }

                // Reps Input
                HStack(spacing: 12) {
                    Text("Reps")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.secondary)
                        .frame(width: 60, alignment: .leading)

                    // Decrement Button
                    Button {
                        adjustReps(by: -1)
                    } label: {
                        Image(systemName: "minus.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(accentColor.opacity(0.7))
                    }
                    .disabled(setLog.isCompleted)

                    // Reps TextField
                    TextField("0", text: $repsText)
                        .keyboardType(.numberPad)
                        .multilineTextAlignment(.center)
                        .font(.system(size: 18, weight: .semibold, design: .rounded))
                        .foregroundColor(.primary)
                        .frame(width: 70)
                        .padding(.vertical, 10)
                        .background(Color.gray.opacity(0.08))
                        .cornerRadius(10)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(focusedField == .reps ? accentColor : Color.clear, lineWidth: 2)
                        )
                        .focused($focusedField, equals: .reps)
                        .disabled(setLog.isCompleted)
                        .onChange(of: repsText) { _, newValue in
                            setLog.actualReps = Int(newValue)
                        }

                    Text("reps")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.secondary)

                    // Increment Button
                    Button {
                        adjustReps(by: 1)
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(accentColor)
                    }
                    .disabled(setLog.isCompleted)
                }

                // RIR Picker
                HStack(spacing: 12) {
                    Text("RIR")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.secondary)
                        .frame(width: 60, alignment: .leading)

                    Menu {
                        ForEach(0...5, id: \.self) { rir in
                            Button {
                                setLog.rir = rir
                            } label: {
                                Label(AppConstants.RIR.label(for: rir), systemImage: setLog.rir == rir ? "checkmark" : "")
                            }
                        }
                    } label: {
                        HStack {
                            Text(setLog.rir != nil ? "\(setLog.rir!) - \(AppConstants.RIR.label(for: setLog.rir!))" : "Tap to set")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(setLog.rir != nil ? .primary : .secondary)

                            Spacer()

                            Image(systemName: "chevron.up.chevron.down")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(.secondary)
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(Color.gray.opacity(0.08))
                        .cornerRadius(10)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(setLog.rir != nil ? accentColor.opacity(0.3) : Color.clear, lineWidth: 1.5)
                        )
                    }
                    .disabled(setLog.isCompleted)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 16)
        }
        .background(
            setLog.isCompleted ?
                LinearGradient(
                    colors: [Color(hex: "#00D4AA").opacity(0.08), Color(hex: "#00D4AA").opacity(0.03)],
                    startPoint: .top,
                    endPoint: .bottom
                ) :
                LinearGradient(colors: [Color.white, Color.white], startPoint: .top, endPoint: .bottom)
        )
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(setLog.isCompleted ? 0.08 : 0.04), radius: 8, x: 0, y: 2)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(
                    setLog.isCompleted ? Color(hex: "#00D4AA").opacity(0.4) : Color.gray.opacity(0.12),
                    lineWidth: 1.5
                )
        )
        .onAppear {
            // Pre-fill with previous data if available
            if weightText.isEmpty && repsText.isEmpty {
                if let prev = previousSet {
                    if let weight = prev.weight {
                        weightText = String(format: "%.0f", weight)
                        setLog.weight = weight
                    }
                    if let reps = prev.reps {
                        repsText = String(reps)
                        setLog.actualReps = reps
                    }
                }
            }

            // Populate from existing data if already filled
            if let weight = setLog.weight, weightText.isEmpty {
                weightText = String(format: "%.0f", weight)
            }
            if let reps = setLog.actualReps, repsText.isEmpty {
                repsText = String(reps)
            }
        }
    }

    // MARK: - Methods

    private func adjustWeight(by amount: Double) {
        let current = Double(weightText) ?? 0
        let newValue = max(0, current + amount)
        weightText = String(format: "%.0f", newValue)
        setLog.weight = newValue
    }

    private func adjustReps(by amount: Int) {
        let current = Int(repsText) ?? 0
        let newValue = max(0, current + amount)
        repsText = String(newValue)
        setLog.actualReps = newValue
    }

    private func copyPreviousData() {
        guard let prev = previousSet else { return }

        if let weight = prev.weight {
            weightText = String(format: "%.0f", weight)
            setLog.weight = weight
        }

        if let reps = prev.reps {
            repsText = String(reps)
            setLog.actualReps = reps
        }

        // Add haptic feedback
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
    }
}
