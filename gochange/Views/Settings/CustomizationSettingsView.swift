import SwiftUI

struct CustomizationSettingsView: View {
    @AppStorage("restTimerDuration") private var restTimerDuration: Double = 90
    @AppStorage("hapticFeedback") private var hapticFeedback: Bool = true
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        List {
            Section {
                VStack(spacing: 16) {
                    HStack {
                        Text("Default Rest Timer")
                            .foregroundColor(.primary)
                        
                        Spacer()
                        
                        Text("\(Int(restTimerDuration))s")
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .foregroundColor(Color(hex: "#00D4AA"))
                    }
                    
                    Slider(value: $restTimerDuration, in: 30...180, step: 15)
                        .tint(Color(hex: "#00D4AA"))
                }
                .padding(.vertical, 8)
            }
            
            Section {
                Toggle("Haptic Feedback", isOn: $hapticFeedback)
                    .tint(Color(hex: "#00D4AA"))
            }
        }
        .navigationTitle("Customization")
        .navigationBarTitleDisplayMode(.inline)
        .background(Color(hex: "#F2F2F7"))
        .scrollContentBackground(.hidden)
    }
}

#Preview {
    NavigationStack {
        CustomizationSettingsView()
    }
}
