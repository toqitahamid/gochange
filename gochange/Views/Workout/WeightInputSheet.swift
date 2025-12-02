import SwiftUI

struct WeightInputSheet: View {
    let initialWeight: Double?
    let initialUnit: String
    let onSave: (Double, String, Bool) -> Void
    @Environment(\.dismiss) private var dismiss
    
    @State private var inputValue: String = ""
    @State private var selectedUnit: String
    @State private var applyToNextSets: Bool = false
    
    init(initialWeight: Double?, initialUnit: String = "lbs", onSave: @escaping (Double, String, Bool) -> Void) {
        self.initialWeight = initialWeight
        self.initialUnit = initialUnit
        self.onSave = onSave
        _selectedUnit = State(initialValue: initialUnit)
        
        if let weight = initialWeight {
            // Format to remove trailing zeros if integer
            let formatted = String(format: "%g", weight)
            _inputValue = State(initialValue: formatted)
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
                
                Text("Weight")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Button("Save") {
                    if let weight = Double(inputValue) {
                        onSave(weight, selectedUnit, applyToNextSets)
                        dismiss()
                    }
                }
                .font(.system(size: 17, weight: .bold))
                .foregroundColor(.primary)
            }
            .padding(.horizontal, 24)
            .padding(.top, 20)
            .padding(.bottom, 10)
            
            // Input Display
            HStack(spacing: 4) {
                Text(inputValue.isEmpty ? "0" : inputValue)
                    .font(.system(size: 28, weight: .semibold, design: .rounded))
                    .foregroundColor(.primary)
                
                // Cursor simulation (blinking)
                if !inputValue.isEmpty || true {
                    Rectangle()
                        .fill(Color.blue)
                        .frame(width: 2.5, height: 32)
                        .cornerRadius(1.25)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 60)
            .background(Color(UIColor.secondarySystemBackground))
            .cornerRadius(20)
            .padding(.horizontal, 24)
            
            // Unit Selector
            HStack(spacing: 0) {
                UnitButton(title: "lbs", isSelected: selectedUnit == "lbs") {
                    selectedUnit = "lbs"
                }
                
                UnitButton(title: "kg", isSelected: selectedUnit == "kg") {
                    selectedUnit = "kg"
                }
            }
            .padding(.vertical, 10)
            
            // Keypad
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 6) {
                ForEach(1...9, id: \.self) { number in
                    KeypadButton(text: "\(number)") {
                        appendCharacter("\(number)")
                    }
                }
                
                KeypadButton(text: ".") {
                    if !inputValue.contains(".") {
                        appendCharacter(".")
                    }
                }
                
                KeypadButton(text: "0") {
                    appendCharacter("0")
                }
                
                Button {
                    if !inputValue.isEmpty {
                        inputValue.removeLast()
                    }
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
        .presentationDetents([.fraction(0.65)])
        .presentationDragIndicator(.hidden) // Show indicator to push content down naturally
    }
    
    private func appendCharacter(_ char: String) {
        // Prevent multiple decimals
        if char == "." && inputValue.contains(".") { return }
        
        // Prevent leading zeros unless it's "0."
        if inputValue == "0" && char != "." {
            inputValue = char
        } else {
            inputValue += char
        }
    }
}

struct UnitButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(isSelected ? Color(UIColor.systemBackground) : .primary)
                .frame(width: 44, height: 44)
                .background(isSelected ? Color.primary : Color.clear)
                .clipShape(Circle())
        }
    }
}

struct KeypadButton: View {
    let text: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(text)
                .font(.system(size: 28, weight: .medium))
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .foregroundColor(.primary)
        }
        .frame(height: 60)
    }
}


