import SwiftUI

struct HealthMonitorGrid: View {
    let rhr: Double
    let hrv: Double
    let respiratoryRate: Double?
    let oxygenSaturation: Double?
    let bodyTemperature: Double?
    let stepCount: Int
    let vo2Max: Double?
    let sleepDuration: TimeInterval?
    
    // Grid Layout
    let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Health Monitor")
                .font(.headline)
                .foregroundColor(.primary)
                .padding(.leading, 4)
            
            LazyVGrid(columns: columns, spacing: 12) {
                // Steps
                HealthCard(
                    title: "Steps",
                    value: "\(stepCount)",
                    icon: "figure.walk",
                    color: .orange,
                    progress: min(Double(stepCount) / 10000.0, 1.0) // Goal: 10k
                )
                
                // RHR
                HealthCard(
                    title: "RHR",
                    value: rhr > 0 ? "\(Int(rhr)) bpm" : "No data",
                    icon: "heart.fill",
                    color: .red,
                    progress: rhr > 0 ? min(rhr / 100.0, 1.0) : 0
                )
                
                // HRV
                HealthCard(
                    title: "HRV",
                    value: hrv > 0 ? "\(Int(hrv)) ms" : "No data",
                    icon: "waveform.path.ecg",
                    color: .purple,
                    progress: hrv > 0 ? min(hrv / 100.0, 1.0) : 0
                )
                
                // RR (Respiratory Rate)
                HealthCard(
                    title: "Resp Rate",
                    value: respiratoryRate != nil ? String(format: "%.1f br/m", respiratoryRate!) : "No data",
                    icon: "lungs.fill",
                    color: .blue,
                    progress: respiratoryRate != nil ? min(respiratoryRate! / 25.0, 1.0) : 0
                )
                
                // SpO2
                HealthCard(
                    title: "SpO2",
                    value: oxygenSaturation != nil ? "\(Int(oxygenSaturation! * 100))%" : "No data",
                    icon: "drop.fill",
                    color: .cyan,
                    progress: oxygenSaturation ?? 0
                )
                
                // Temp
                HealthCard(
                    title: "Temp",
                    value: bodyTemperature != nil ? String(format: "%.1f°C", bodyTemperature!) : "No data",
                    icon: "thermometer",
                    color: .orange,
                    progress: bodyTemperature != nil ? min((bodyTemperature! - 35.0) / 3.0, 1.0) : 0
                )
                
                // VO2 Max
                HealthCard(
                    title: "VO2 Max",
                    value: vo2Max != nil ? String(format: "%.1f", vo2Max!) : "No data",
                    icon: "figure.run",
                    color: .green,
                    progress: vo2Max != nil ? min(vo2Max! / 60.0, 1.0) : 0
                )
                
                // Sleep
                HealthCard(
                    title: "Sleep",
                    value: formatSleep(sleepDuration),
                    icon: "bed.double.fill",
                    color: .indigo,
                    progress: sleepDuration != nil ? min(sleepDuration! / (8 * 3600), 1.0) : 0
                )
            }
        }
    }
    
    private func formatSleep(_ duration: TimeInterval?) -> String {
        guard let duration = duration else { return "No data" }
        let hours = Int(duration / 3600)
        let minutes = Int((duration.truncatingRemainder(dividingBy: 3600)) / 60)
        return "\(hours)h \(minutes)m"
    }
}

struct HealthCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    let progress: Double
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: icon)
                        .foregroundColor(color)
                        .font(.system(size: 14))
                    Text(title)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Text(value)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(value == "No data" ? .secondary : .primary)
            }
            
            Spacer()
            
            // Vertical Progress Bar
            ZStack(alignment: .bottom) {
                Capsule()
                    .fill(Color.gray.opacity(0.1))
                    .frame(width: 6, height: 60)
                
                Capsule()
                    .fill(color.opacity(0.8))
                    .frame(width: 6, height: 60 * progress)
            }
        }
        .padding(16)
        .frame(height: 100)
        .background {
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white) // Solid white for better contrast
                .shadow(color: Color.black.opacity(0.08), radius: 10, x: 0, y: 4) // Slightly stronger shadow
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.gray.opacity(0.15), lineWidth: 1) // Slightly stronger border
                )
        }
    }
}

#Preview {
    ZStack {
        Color(hex: "#F2F2F7").ignoresSafeArea()
        HealthMonitorGrid(
        rhr: 58,
        hrv: 45,
        respiratoryRate: 14.5,
        oxygenSaturation: 0.98,
        bodyTemperature: 36.6,
        stepCount: 8543,
        vo2Max: 48.5,
        sleepDuration: 26000
    )
            .padding()
    }
}
