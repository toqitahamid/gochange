import SwiftUI

struct SetInputCard: View {
    @Binding var setLog: SetLog
    let accentColor: Color
    let previousSet: PreviousSetInfo?
    let isPlaying: Bool
    let weightUnit: String
    let onRemove: (() -> Void)?
    let onToggleCompletion: () -> Void
    let onPlaySet: () -> Void
    let onPauseSet: () -> Void
    let onUpdateWeight: ((Double, String, Bool) -> Void)?

    @State private var weightText: String = ""
    @State private var repsText: String = ""
    @State private var showWeightSheet = false
    @State private var showRepsDurationSheet = false
    @FocusState private var focusedField: Field?

    enum Field {
        case weight, reps
    }

    private var previousDataText: String? {
        guard let prev = previousSet, let weight = prev.weight else { return nil }
        
        if let reps = prev.reps {
            return "\(Int(weight))×\(reps)"
        } else if let duration = prev.duration {
            let minutes = Int(duration) / 60
            let seconds = Int(duration) % 60
            return "\(Int(weight))×\(String(format: "%d:%02d", minutes, seconds))"
        }
        return nil
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
                                .font(AppFonts.rounded(17, weight: .semibold))
                                .foregroundColor(AppColors.textPrimary)
                            
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
            Button {
                showWeightSheet = true
            } label: {
                Text(weightText.isEmpty ? "—" : weightText)
                    .font(AppFonts.rounded(17, weight: .medium))
                    .foregroundColor(weightText.isEmpty ? AppColors.textTertiary : AppColors.textPrimary)
                    .frame(width: 90)
                    .contentShape(Rectangle())
            }
            .disabled(setLog.isCompleted)
            .sheet(isPresented: $showWeightSheet) {
                WeightInputSheet(
                    initialWeight: setLog.weight,
                    initialUnit: weightUnit,
                    onSave: { newWeight, newUnit, applyToNext in
                        // Update local state
                        setLog.weight = newWeight
                        weightText = String(format: "%.0f", newWeight)
                        
                        // Notify parent
                        onUpdateWeight?(newWeight, newUnit, applyToNext)
                        
                        // Note: handling unit change globally might be needed if user changes unit here
                        // But for now we just pass the value.
                    }
                )
            }
            
            // REPS / DURATION
            Button {
                showRepsDurationSheet = true
            } label: {
                Text(repsText.isEmpty ? "—" : repsText)
                    .font(AppFonts.rounded(17, weight: .medium))
                    .foregroundColor(repsText.isEmpty ? AppColors.textTertiary : AppColors.textPrimary)
                    .frame(width: 90)
                    .contentShape(Rectangle())
            }
            .disabled(setLog.isCompleted)
            .sheet(isPresented: $showRepsDurationSheet) {
                RepsDurationInputSheet(
                    initialReps: setLog.actualReps,
                    initialDuration: setLog.duration,
                    onSave: { reps, duration, applyToNext in
                        // Update local state
                        setLog.actualReps = reps
                        setLog.duration = duration
                        
                        // Update display text
                        if let reps = reps {
                            repsText = "\(reps)"
                        } else if let duration = duration {
                            let minutes = Int(duration) / 60
                            let seconds = Int(duration) % 60
                            repsText = String(format: "%d:%02d", minutes, seconds)
                        } else {
                            repsText = ""
                        }
                        
                        // Handle apply to next sets logic if needed
                        // For now we just update the current set
                    }
                )
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
                Text(setLog.rir != nil ? "\(setLog.rir!)" : "—")
                    .font(AppFonts.rounded(17, weight: .medium))
                    .foregroundColor(setLog.rir != nil ? AppColors.textPrimary : AppColors.textTertiary)
                    .frame(width: 60, alignment: .center)
            }
            .disabled(setLog.isCompleted)
            
            Spacer()
            
            // Play/Pause/Complete button
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    if setLog.isCompleted {
                        // If already completed, allow uncompleting
                        onToggleCompletion()
                    } else if isPlaying {
                        // If playing, pause
                        onPauseSet()
                    } else {
                        // If not completed and not playing, start the set timer
                        onPlaySet()
                    }
                }
            } label: {
                Image(systemName: setLog.isCompleted ? "checkmark.circle.fill" : (isPlaying ? "pause.fill" : "play.fill"))
                    .font(.system(size: 20))
                    .foregroundColor(setLog.isCompleted ? AppColors.success : (isPlaying ? accentColor : AppColors.textPrimary))
            }
            .frame(width: 44, alignment: .center)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
        .background(setLog.isCompleted ? AppColors.success.opacity(0.06) : AppColors.surface)
        .onAppear {
            // Pre-fill with previous data if available
            if weightText.isEmpty && repsText.isEmpty {
                if let prev = previousSet {
                    if let weight = prev.weight {
                        weightText = String(format: "%.0f", weight)
                        setLog.weight = weight
                    }
                    if let reps = prev.reps {
                        repsText = "\(reps)"
                        setLog.actualReps = reps
                    } else if let duration = prev.duration {
                        let minutes = Int(duration) / 60
                        let seconds = Int(duration) % 60
                        repsText = String(format: "%d:%02d", minutes, seconds)
                        setLog.duration = duration
                    }
                }
            }

            // Populate from existing data if already filled
            if let weight = setLog.weight, weightText.isEmpty {
                weightText = String(format: "%.0f", weight)
            }
            if let reps = setLog.actualReps {
                repsText = "\(reps)"
            } else if let duration = setLog.duration {
                let minutes = Int(duration) / 60
                let seconds = Int(duration) % 60
                repsText = String(format: "%d:%02d", minutes, seconds)
            }
        }
    }
}
