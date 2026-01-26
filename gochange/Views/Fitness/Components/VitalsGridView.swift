import SwiftUI
import Charts

// MARK: - Vitals Grid View
struct VitalsGridView: View {
    let hrv: Double? // ms
    let rhr: Double? // bpm
    let respiratoryRate: Double? // br/min
    let spo2: Double? // %
    let vo2Max: Double? // ml/kg/min
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Vitals")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.secondary)
            
            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 12),
                GridItem(.flexible(), spacing: 12),
                GridItem(.flexible(), spacing: 12)
            ], spacing: 12) {
                VitalCard(
                    icon: "waveform.path.ecg",
                    title: "HRV",
                    value: hrv != nil ? "\(Int(hrv!)) ms" : "--",
                    color: Color(hex: "#FF6B6B"),
                    trend: nil
                )
                
                VitalCard(
                    icon: "heart.fill",
                    title: "RHR",
                    value: rhr != nil ? "\(Int(rhr!)) bpm" : "--",
                    color: Color(hex: "#FF6B6B"),
                    trend: nil
                )
                
                VitalCard(
                    icon: "lungs.fill",
                    title: "Resp",
                    value: respiratoryRate != nil ? "\(Int(respiratoryRate!)) br/m" : "--",
                    color: AppColors.primary,
                    trend: nil
                )
                
                VitalCard(
                    icon: "drop.fill",
                    title: "SpO2",
                    value: spo2 != nil ? "\(Int(spo2!))%" : "--",
                    color: Color(hex: "#7B68EE"),
                    trend: nil
                )
                
                VitalCard(
                    icon: "figure.run",
                    title: "VO2",
                    value: vo2Max != nil ? String(format: "%.1f", vo2Max!) : "--",
                    color: AppColors.success,
                    trend: nil
                )
            }
        }
    }
}

// MARK: - Individual Vital Card
struct VitalCard: View {
    let icon: String
    let title: String
    let value: String
    let color: Color
    let trend: Double? // Optional sparkline data or trend indicator
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.caption)
                    .foregroundColor(color)
                
                Text(title)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            Text(value)
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundColor(.primary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.03), radius: 5, x: 0, y: 2)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.gray.opacity(0.08), lineWidth: 1)
        )
    }
}

// MARK: - Stress Monitor Card
struct StressMonitorCard: View {
    let stressLevel: StressLevel
    
    enum StressLevel: String {
        case low = "Low"
        case moderate = "Moderate"
        case high = "High"
        
        var color: Color {
            switch self {
            case .low: return AppColors.success
            case .moderate: return AppColors.warning
            case .high: return AppColors.error
            }
        }
        
        var angle: Double {
            switch self {
            case .low: return 30
            case .moderate: return 90
            case .high: return 150
            }
        }
    }
    
    var body: some View {
        VStack(spacing: 12) {
            // Gauge
            ZStack {
                // Background Arc
                Circle()
                    .trim(from: 0.25, to: 0.75)
                    .stroke(Color.gray.opacity(0.1), lineWidth: 10)
                    .frame(width: 80, height: 80)
                    .rotationEffect(.degrees(180))
                
                // Colored Arc
                Circle()
                    .trim(from: 0.25, to: 0.25 + (stressLevel.angle / 360))
                    .stroke(
                        LinearGradient(
                            colors: [AppColors.success, AppColors.warning, AppColors.error],
                            startPoint: .leading,
                            endPoint: .trailing
                        ),
                        style: StrokeStyle(lineWidth: 10, lineCap: .round)
                    )
                    .frame(width: 80, height: 80)
                    .rotationEffect(.degrees(180))
                
                // Indicator
                VStack(spacing: 0) {
                    Text(stressLevel.rawValue)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(stressLevel.color)
                }
            }
            
            VStack(spacing: 2) {
                Text("Stress")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .scoreCardStyle()
    }
}

// MARK: - Previews
#Preview("Vitals Grid") {
    VitalsGridView(
        hrv: 45,
        rhr: 58,
        respiratoryRate: 14,
        spo2: 98,
        vo2Max: 42.5
    )
    .padding()
    .background(Color(hex: "#F5F5F7"))
}

#Preview("Stress Monitor") {
    HStack {
        StressMonitorCard(stressLevel: .low)
        StressMonitorCard(stressLevel: .moderate)
        StressMonitorCard(stressLevel: .high)
    }
    .padding()
    .background(Color(hex: "#F5F5F7"))
}
