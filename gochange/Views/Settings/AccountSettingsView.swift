import SwiftUI

struct AccountSettingsView: View {
    @AppStorage("weightUnit") private var weightUnit: String = "lbs"
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        List {
            Section {
                HStack {
                    Text("Weight Unit")
                        .foregroundColor(.primary)
                    Spacer()
                    Picker("", selection: $weightUnit) {
                        Text("lbs").tag("lbs")
                        Text("kg").tag("kg")
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 120)
                }
            }
        }
        .navigationTitle("Account")
        .navigationBarTitleDisplayMode(.inline)
        .background(Color(hex: "#F2F2F7"))
        .scrollContentBackground(.hidden)
    }
}

#Preview {
    NavigationStack {
        AccountSettingsView()
    }
}
