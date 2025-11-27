import SwiftUI

struct CustomizationSettingsView: View {
    @AppStorage("restTimerDuration") private var restTimerDuration: Double = 90
    @AppStorage("hapticFeedback") private var hapticFeedback: Bool = true
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Rest Timer Section
                VStack(alignment: .leading, spacing: 16) {
                    Text("REST TIMER")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 20)
                        .padding(.top, 4)
                    
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
                    .padding(20)
                    .background(Color.white)
                    .cornerRadius(24)
                    .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 4)
                    .overlay(
                        RoundedRectangle(cornerRadius: 24)
                            .stroke(Color.gray.opacity(0.1), lineWidth: 1)
                    )
                }
                
                // Haptic Feedback Section
                VStack(alignment: .leading, spacing: 16) {
                    Text("FEEDBACK")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 20)
                    
                    Toggle("Haptic Feedback", isOn: $hapticFeedback)
                        .tint(Color(hex: "#00D4AA"))
                        .padding(20)
                        .background(Color.white)
                        .cornerRadius(24)
                        .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 4)
                        .overlay(
                            RoundedRectangle(cornerRadius: 24)
                                .stroke(Color.gray.opacity(0.1), lineWidth: 1)
                        )
                }
                
                Spacer(minLength: 100)
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
        }
        .navigationTitle("Customization")
        .navigationBarTitleDisplayMode(.inline)
        .background(Color(hex: "#F5F5F7").ignoresSafeArea())
    }
}

#Preview {
    NavigationStack {
        CustomizationSettingsView()
    }
}
