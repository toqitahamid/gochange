import SwiftUI

struct RepsDurationInputSheet: View {
    let initialReps: Int?
    let initialDuration: TimeInterval?
    let onSave: (Int?, TimeInterval?, Bool) -> Void
    @Environment(\.dismiss) private var dismiss
    
    enum InputMode: String, CaseIterable {
        case reps = "Reps"
        case duration = "Duration"
    }
    
    @State private var selectedMode: InputMode
    @State private var repsValue: String = ""
    @State private var durationMinutes: String = ""
    @State private var durationSeconds: String = ""
    @State private var applyToNextSets: Bool = false
    
    // For duration input focus
    @State private var isEditingSeconds: Bool = false
    
    init(initialReps: Int?, initialDuration: TimeInterval?, onSave: @escaping (Int?, TimeInterval?, Bool) -> Void) {
        self.initialReps = initialReps
        self.initialDuration = initialDuration
        self.onSave = onSave
        
        // Determine initial mode
        if let _ = initialDuration {
            _selectedMode = State(initialValue: .duration)
        } else {
            _selectedMode = State(initialValue: .reps)
        }
        
        // Initialize values
        if let reps = initialReps {
            _repsValue = State(initialValue: "\(reps)")
        }
        
        if let duration = initialDuration {
            let minutes = Int(duration) / 60
            let seconds = Int(duration) % 60
            _durationMinutes = State(initialValue: minutes > 0 ? "\(minutes)" : "")
            _durationSeconds = State(initialValue: String(format: "%02d", seconds))
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Button("Cancel") {
                    dismiss()
                }
                .foregroundColor(.primary)
                .font(.system(size: 17))
                
                Spacer()
                
                Text(selectedMode.rawValue)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Button("Save") {
                    save()
                }
                .font(.system(size: 17, weight: .bold))
                .foregroundColor(.primary)
            }
            .padding(.horizontal, 24)
            .padding(.top, 20)
            .padding(.bottom, 10)
            
            // Input Display
            VStack(spacing: 16) {
                if selectedMode == .reps {
                    HStack(spacing: 4) {
                        Text(repsValue.isEmpty ? "0" : repsValue)
                            .font(.system(size: 48, weight: .semibold, design: .rounded))
                            .foregroundColor(.primary)
                        
                        // Cursor
                        if true {
                            Rectangle()
                                .fill(Color.blue)
                                .frame(width: 3, height: 48)
                                .cornerRadius(1.5)
                        }
                    }
                    .frame(height: 80)
                } else {
                    HStack(spacing: 4) {
                        // Minutes
                        Text(durationMinutes.isEmpty ? "0" : durationMinutes)
                            .font(.system(size: 48, weight: .semibold, design: .rounded))
                            .foregroundColor(isEditingSeconds ? .secondary : .primary)
                        
                        Text(":")
                            .font(.system(size: 48, weight: .semibold, design: .rounded))
                            .foregroundColor(.secondary)
                            .padding(.bottom, 4)
                        
                        // Seconds
                        Text(durationSeconds.isEmpty ? "00" : (durationSeconds.count == 1 ? "0\(durationSeconds)" : durationSeconds))
                            .font(.system(size: 48, weight: .semibold, design: .rounded))
                            .foregroundColor(isEditingSeconds ? .primary : .secondary)
                        
                        // Cursor
                        if true {
                            Rectangle()
                                .fill(Color.blue)
                                .frame(width: 3, height: 48)
                                .cornerRadius(1.5)
                        }
                    }
                    .frame(height: 80)
                    .onTapGesture {
                        isEditingSeconds.toggle()
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.bottom, 10)
            
            // Mode Selector
            HStack(spacing: 0) {
                ForEach(InputMode.allCases, id: \.self) { mode in
                    Button {
                        withAnimation(.spring(response: 0.3)) {
                            selectedMode = mode
                        }
                    } label: {
                        Text(mode.rawValue)
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(selectedMode == mode ? .white : .primary)
                            .padding(.vertical, 8)
                            .padding(.horizontal, 16)
                            .background(
                                Capsule()
                                    .fill(selectedMode == mode ? Color.primary : Color.clear)
                            )
                    }
                }
            }
            .padding(4)
            .background(Color(UIColor.secondarySystemBackground))
            .clipShape(Capsule())
            .padding(.bottom, 20)
            
            // RIR Selector Removed
            
            // Keypad
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 6) {
                ForEach(1...9, id: \.self) { number in
                    KeypadButton(text: "\(number)") {
                        appendCharacter("\(number)")
                    }
                }
                
                // Empty space for layout balance
                Color.clear.frame(height: 60)
                
                KeypadButton(text: "0") {
                    appendCharacter("0")
                }
                
                Button {
                    deleteCharacter()
                } label: {
                    Image(systemName: "delete.left.fill")
                        .font(.title2)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .foregroundColor(.secondary)
                }
                .frame(height: 50)
            }
            .padding(.horizontal, 40)
            
            Spacer()
            
            // Apply to next sets
            Button {
                applyToNextSets.toggle()
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: applyToNextSets ? "checkmark.circle.fill" : "circle")
                        .foregroundColor(applyToNextSets ? .primary : .secondary.opacity(0.3))
                        .font(.system(size: 22))
                    
                    Text("Apply to next sets")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.primary)
                }
            }
            .padding(.bottom, 20)
        }
        .background(Color(UIColor.systemBackground))
        .presentationDetents([.fraction(0.75)])
        .presentationDragIndicator(.hidden)
    }
    
    private func appendCharacter(_ char: String) {
        if selectedMode == .reps {
            if repsValue.count < 3 { // Limit to 3 digits
                if repsValue == "0" {
                    repsValue = char
                } else {
                    repsValue += char
                }
            }
        } else {
            if isEditingSeconds {
                if durationSeconds.count < 2 {
                    if durationSeconds == "00" || durationSeconds == "0" {
                        durationSeconds = char
                    } else {
                        durationSeconds += char
                    }
                    
                    // Auto-switch back to minutes if seconds is full (2 digits) - Optional, maybe annoying
                }
            } else {
                if durationMinutes.count < 3 {
                    if durationMinutes == "0" {
                        durationMinutes = char
                    } else {
                        durationMinutes += char
                    }
                }
            }
        }
    }
    
    private func deleteCharacter() {
        if selectedMode == .reps {
            if !repsValue.isEmpty {
                repsValue.removeLast()
            }
        } else {
            if isEditingSeconds {
                if !durationSeconds.isEmpty {
                    durationSeconds.removeLast()
                }
            } else {
                if !durationMinutes.isEmpty {
                    durationMinutes.removeLast()
                }
            }
        }
    }
    
    private func save() {
        if selectedMode == .reps {
            let reps = Int(repsValue)
            onSave(reps, nil, applyToNextSets)
        } else {
            let minutes = Int(durationMinutes) ?? 0
            let seconds = Int(durationSeconds) ?? 0
            let totalSeconds = TimeInterval(minutes * 60 + seconds)
            
            if totalSeconds > 0 {
                onSave(nil, totalSeconds, applyToNextSets)
            } else {
                // If 0 duration, maybe save as nil or just dismiss?
                // Let's assume user wants to clear if 0
                onSave(nil, nil, applyToNextSets)
            }
        }
        dismiss()
    }
}

#Preview {
    RepsDurationInputSheet(initialReps: 10, initialDuration: nil) { reps, duration, apply in
        print("Saved: Reps: \(String(describing: reps)), Duration: \(String(describing: duration)), Apply: \(apply)")
    }
}
