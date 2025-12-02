import SwiftUI

struct SetInputCard: View {
    @Binding var setLog: SetLog
    let accentColor: Color
    let previousSet: PreviousSetInfo?
    let onRemove: (() -> Void)?
    let onToggleCompletion: () -> Void
    let onPlaySet: () -> Void // New callback for starting set timer

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
        HStack(spacing: 0) {
            // SET indicator with menu
            Menu {
                // Set type options
                Button {
                    setLog.setType = .normal
                } label: {
                    Label("Normal", systemImage: "checkmark")
                }
                
                Button {
                    setLog.setType = .warmup
                } label: {
                    Label("Warm Up", systemImage: "flame.fill")
                }
                
                Button {
                    setLog.setType = .cooldown
                } label: {
                    Label("Cool Down", systemImage: "snowflake")
                }
                
                Button {
                    setLog.setType = .failure
                } label: {
                    Label("Failure", systemImage: "exclamationmark.triangle.fill")
                }
                
                Button {
                    setLog.setType = .dropset
                } label: {
                    Label("Dropset", systemImage: "arrow.down.right")
                }
                
                // Remove set option
                if let onRemove = onRemove {
                    Divider()
                    
                    Button(role: .destructive) {
                        onRemove()
                    } label: {
                        Label("Remove set", systemImage: "minus.circle")
                    }
                }
            } label: {
                HStack(spacing: 0) {
                    Group {
                        switch setLog.setType {
                        case .normal:
                            // Normal set - show number
                            Text("\(setLog.setNumber)")
                                .font(.system(size: 17, weight: .medium))
                                .foregroundColor(.primary)
                            
                        case .warmup:
                            // Warmup - flame icon in circle
                            ZStack {
                                Circle()
                                    .stroke(Color.orange, lineWidth: 2)
                                    .frame(width: 28, height: 28)
                                
                                Image(systemName: "flame.fill")
                                    .font(.system(size: 12))
                                    .foregroundColor(.orange)
                            }
                            
                        case .cooldown:
                            // Cooldown - snowflake icon
                            Image(systemName: "snowflake")
                                .font(.system(size: 16))
                                .foregroundColor(.blue)
                            
                        case .failure:
                            // Failure - warning triangle icon
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.system(size: 16))
                                .foregroundColor(.red)
                            
                        case .dropset:
                            // Dropset - down arrow icon
                            Image(systemName: "arrow.down.right")
                                .font(.system(size: 16))
                                .foregroundColor(.purple)
                        }
                    }
                    Spacer()
                }
                .frame(width: 50)
            }
            .disabled(setLog.isCompleted)
            
            // Weight
            TextField("14", text: $weightText)
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.center)
                .font(.system(size: 17))
                .foregroundColor(.primary)
                .frame(width: 90)
                .disabled(setLog.isCompleted)
                .onChange(of: weightText) { _, newValue in
                    setLog.weight = Double(newValue)
                }
            
            // REPS
            TextField("x10", text: $repsText)
                .keyboardType(.numberPad)
                .multilineTextAlignment(.center)
                .font(.system(size: 17))
                .foregroundColor(.primary)
                .frame(width: 90)
                .disabled(setLog.isCompleted)
                .onChange(of: repsText) { _, newValue in
                    // Remove 'x' prefix if user types it
                    let cleaned = newValue.replacingOccurrences(of: "x", with: "")
                    if let reps = Int(cleaned) {
                        setLog.actualReps = reps
                        // Update the text field to maintain 'x' prefix
                        if !cleaned.isEmpty {
                            repsText = "x\(cleaned)"
                        }
                    }
                }
            
            // RIR (Reps in Reserve)
            Menu {
                Button {
                    setLog.rir = nil
                } label: {
                    Label("Not set", systemImage: setLog.rir == nil ? "checkmark" : "")
                }
                
                Divider()
                
                ForEach(0...5, id: \.self) { rir in
                    Button {
                        setLog.rir = rir
                    } label: {
                        Label("\(rir)", systemImage: setLog.rir == rir ? "checkmark" : "")
                    }
                }
            } label: {
                Text(setLog.rir != nil ? "\(setLog.rir!)" : "-")
                    .font(.system(size: 17))
                    .foregroundColor(setLog.rir != nil ? .primary : .secondary)
                    .frame(width: 60, alignment: .center)
            }
            .disabled(setLog.isCompleted)
            
            Spacer()
            
            // Play/Complete button
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    if setLog.isCompleted {
                        // If already completed, allow uncompleting
                        onToggleCompletion()
                    } else {
                        // If not completed, start the set timer
                        onPlaySet()
                    }
                }
            } label: {
                Image(systemName: setLog.isCompleted ? "checkmark.circle.fill" : "play.fill")
                    .font(.system(size: 20))
                    .foregroundColor(setLog.isCompleted ? Color(hex: "#00D4AA") : .primary)
            }
            .frame(width: 44, alignment: .trailing)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(setLog.isCompleted ? Color(hex: "#00D4AA").opacity(0.05) : Color.white)
        .onAppear {
            // Pre-fill with previous data if available
            if weightText.isEmpty && repsText.isEmpty {
                if let prev = previousSet {
                    if let weight = prev.weight {
                        weightText = String(format: "%.0f", weight)
                        setLog.weight = weight
                    }
                    if let reps = prev.reps {
                        repsText = "x\(reps)"
                        setLog.actualReps = reps
                    }
                }
            }

            // Populate from existing data if already filled
            if let weight = setLog.weight, weightText.isEmpty {
                weightText = String(format: "%.0f", weight)
            }
            if let reps = setLog.actualReps, repsText.isEmpty {
                repsText = "x\(reps)"
            }
        }
    }
}
