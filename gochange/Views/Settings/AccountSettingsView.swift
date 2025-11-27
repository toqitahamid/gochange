import SwiftUI

struct AccountSettingsView: View {
    @StateObject private var userProfile = UserProfileService.shared
    @StateObject private var healthKit = HealthKitService.shared
    @AppStorage("weightUnit") private var weightUnit: String = "lbs"
    @AppStorage("userBirthdate") private var birthdateTimestamp: Double = Date().timeIntervalSince1970
    @Environment(\.dismiss) private var dismiss
    
    @State private var firstName: String = ""
    @State private var lastName: String = ""
    @State private var birthdate: Date = Date()
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Profile Section
                VStack(alignment: .leading, spacing: 16) {
                    Text("PROFILE")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 20)
                        .padding(.top, 4)
                    
                    VStack(spacing: 0) {
                        // First Name
                        HStack {
                            Text("First Name")
                                .foregroundColor(.primary)
                            Spacer()
                            TextField("First Name", text: $firstName)
                                .multilineTextAlignment(.trailing)
                                .foregroundColor(.secondary)
                        }
                        .padding(20)
                        
                        Divider()
                            .background(Color.gray.opacity(0.1))
                            .padding(.leading, 20)
                        
                        // Last Name
                        HStack {
                            Text("Last Name")
                                .foregroundColor(.primary)
                            Spacer()
                            TextField("Last Name", text: $lastName)
                                .multilineTextAlignment(.trailing)
                                .foregroundColor(.secondary)
                        }
                        .padding(20)
                        
                        Divider()
                            .background(Color.gray.opacity(0.1))
                            .padding(.leading, 20)
                        
                        // Birthdate
                        DatePicker("Birthdate", selection: $birthdate, displayedComponents: .date)
                            .foregroundColor(.primary)
                            .padding(20)
                    }
                    .background(Color.white)
                    .cornerRadius(24)
                    .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 4)
                    .overlay(
                        RoundedRectangle(cornerRadius: 24)
                            .stroke(Color.gray.opacity(0.1), lineWidth: 1)
                    )
                }
                
                // Units Section
                VStack(alignment: .leading, spacing: 16) {
                    Text("UNITS")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 20)
                    
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
        .navigationTitle("Account")
        .navigationBarTitleDisplayMode(.inline)
        .background(Color(hex: "#F5F5F7").ignoresSafeArea())
        .onAppear {
            loadData()
        }
        .onDisappear {
            saveData()
        }
    }
    
    private func loadData() {
        // Load from UserProfileService
        firstName = userProfile.firstName
        lastName = userProfile.lastName
        
        // Load birthdate from AppStorage or HealthKit
        if let healthKitBirthdate = healthKit.getBirthdate() {
            birthdate = healthKitBirthdate
            birthdateTimestamp = healthKitBirthdate.timeIntervalSince1970
        } else {
            birthdate = Date(timeIntervalSince1970: birthdateTimestamp)
        }
    }
    
    private func saveData() {
        // Save to UserProfileService (updates published properties)
        userProfile.firstName = firstName
        userProfile.lastName = lastName
        
        // Save birthdate to AppStorage
        birthdateTimestamp = birthdate.timeIntervalSince1970
    }
}

#Preview {
    NavigationStack {
        AccountSettingsView()
    }
}
