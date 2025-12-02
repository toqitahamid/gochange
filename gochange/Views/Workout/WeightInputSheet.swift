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
                .foregroundColor(.secondary)
                
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
                .fontWeight(.bold)
                .foregroundColor(Color(hex: "#00D4AA"))
            }
            .padding()
            
            Spacer().frame(height: 20)
            
            // Input Display
            HStack {
                Text(inputValue.isEmpty ? "0" : inputValue)
                    .font(.system(size: 40, weight: .medium))
                    .foregroundColor(.primary)
                
                // Cursor simulation (blinking)
                Rectangle()
                    .fill(Color.blue)
                    .frame(width: 2, height: 30)
                    .opacity(1) // Could animate blinking if desired
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
            )
            .padding(.horizontal, 20)
            
            Spacer().frame(height: 20)
            
            // Unit Selector
            HStack(spacing: 20) {
                UnitButton(title: "lbs", isSelected: selectedUnit == "lbs") {
                    selectedUnit = "lbs"
                }
                
                UnitButton(title: "kg", isSelected: selectedUnit == "kg") {
                    selectedUnit = "kg"
                }
            }
            .padding(.bottom, 20)
            
            // Keypad
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 15) {
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
                    Image(systemName: "delete.left")
                        .font(.title2)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .foregroundColor(.primary)
                }
                .frame(height: 60)
            }
            .padding(.horizontal, 40)
            
            Spacer().frame(height: 30)
            
            // Apply to next sets
            Button {
                applyToNextSets.toggle()
            } label: {
                HStack {
                    Text("Apply to next sets")
                        .foregroundColor(.primary)
                    
                    Image(systemName: applyToNextSets ? "checkmark.circle.fill" : "circle")
                        .foregroundColor(applyToNextSets ? Color(hex: "#00D4AA") : .gray)
                        .font(.system(size: 22))
                }
            }
            .padding(.bottom, 30)
        }
        .background(Color(UIColor.systemBackground))
        .presentationDetents([.fraction(0.6)]) // Half sized sheet roughly
        .presentationDragIndicator(.visible)
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
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(isSelected ? .white : .primary)
                .frame(width: 50, height: 50)
                .background(isSelected ? Color.primary : Color.clear) // Dark circle for selected
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
                .font(.title)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .foregroundColor(.primary)
        }
        .frame(height: 60)
    }
}

// Helper for hex color
extension Color {
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
            (a, r, g, b) = (1, 1, 1, 0)
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
