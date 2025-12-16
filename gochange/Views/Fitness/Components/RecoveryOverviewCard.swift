import SwiftUI
import SwiftData

struct RecoveryOverviewCard: View {
    @Query(sort: \RecoveryMetrics.date, order: .reverse) private var recoveryMetrics: [RecoveryMetrics]
    @State private var showInfo = false
    
    var todaysMetrics: RecoveryMetrics? {
        let today = Calendar.current.startOfDay(for: Date())
        return recoveryMetrics.first { Calendar.current.isDate($0.date, inSameDayAs: today) }
    }
    
    var body: some View {
        NavigationLink(destination: RecoveryDashboardView()) {
            HStack(spacing: 20) {
                // Readiness Ring
                ZStack {
                    Circle()
                        .stroke(Color.gray.opacity(0.1), lineWidth: 8)
                        .frame(width: 70, height: 70)
                    
                    if let metrics = todaysMetrics {
                        Circle()
                            .trim(from: 0, to: metrics.overallRecoveryScore)
                            .stroke(
                                readinessColor(metrics.overallRecoveryScore),
                                style: StrokeStyle(lineWidth: 8, lineCap: .round)
                            )
                            .rotationEffect(.degrees(-90))
                            .frame(width: 70, height: 70)
                        
                        Text("\(Int(metrics.overallRecoveryScore * 100))%")
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .foregroundColor(.primary)
                    } else {
                        Text("--")
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .foregroundColor(.gray)
                    }
                }
                
                // Key Stats
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Recovery Readiness")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        Button {
                            showInfo = true
                        } label: {
                            Image(systemName: "info.circle")
                                .font(.caption)
                                .foregroundColor(.gray.opacity(0.5))
                        }
                    }
                    
                    HStack(spacing: 16) {
                        statItem(
                            icon: "bed.double.fill",
                            value: todaysMetrics?.formattedSleepDuration ?? "--",
                            color: Color(hex: "#7B68EE")
                        )
                        
                        statItem(
                            icon: "waveform.path.ecg",
                            value: todaysMetrics != nil && todaysMetrics!.heartRateVariability != nil ? "\(Int(todaysMetrics!.heartRateVariability!)) ms" : "--",
                            color: Color(hex: "#FF6B6B")
                        )
                    }
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.gray.opacity(0.5))
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
        .buttonStyle(PlainButtonStyle()) // To avoid blue tint on NavigationLink
        .sheet(isPresented: $showInfo) {
            RecoveryInfoSheet()
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
        }
    }
    
    private func statItem(icon: String, value: String, color: Color) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(color)
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.secondary)
        }
    }
    
    private func readinessColor(_ score: Double) -> Color {
        if score >= 0.8 { return Color(hex: "#00D4AA") }
        if score >= 0.5 { return Color(hex: "#FFD54F") }
        return Color(hex: "#FF6B6B")
    }
}

#Preview {
    RecoveryOverviewCard()
        .padding()
        .background(Color(hex: "#F5F5F7"))
        .modelContainer(for: RecoveryMetrics.self)
}

struct RecoveryInfoSheet: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Readiness Score")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("Your Readiness Score indicates your capacity to perform at your peak today. It is calculated based on a weighted average of your key recovery metrics.")
                    .font(.body)
                    .foregroundColor(.secondary)
                
                VStack(alignment: .leading, spacing: 12) {
                    Text("Key Metrics")
                        .font(.headline)
                    
                    metricItem(title: "Sleep", desc: "Quality and duration of last night's sleep.", icon: "bed.double.fill", color: Color(hex: "#7B68EE"))
                    metricItem(title: "HRV", desc: "Heart Rate Variability (higher is generally better).", icon: "waveform.path.ecg", color: Color(hex: "#FF6B6B"))
                    metricItem(title: "RHR", desc: "Resting Heart Rate (lower is generally better).", icon: "heart.fill", color: Color(hex: "#FFD54F"))
                }
                .padding(.top, 8)
            }
            .padding(24)
        }
    }
    
    private func metricItem(title: String, desc: String, icon: String, color: Color) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(color)
                .frame(width: 32)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                Text(desc)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.gray.opacity(0.05))
        .cornerRadius(12)
    }
}
