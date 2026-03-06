import SwiftUI

struct SessionHealthSummaryCard: View {
    let session: WorkoutSession
    let strain: Int                 // 0–100
    let totalCalories: Double?      // kCal
    let avgHeartRate: Double?       // bpm
    let cardioLoadDelta: Int?       // e.g. +1
    let cardioLoadLabel: String?    // e.g. "Overtraining"
    
    private var clampedStrain: Int {
        min(max(strain, 0), 100)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            header
            activityStrainSection
            metricsSection
            cardioImpactSection
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 4)
                .overlay(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .stroke(Color.gray.opacity(0.08), lineWidth: 1)
                )
        )
    }
    
    // MARK: - Sections
    
    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(session.workoutDayName.isEmpty ? "Strength Training" : session.workoutDayName)
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.primary)
            
            Text(session.date.formatted(date: .abbreviated, time: .shortened))
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }
    
    private var activityStrainSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 6) {
                Text("Activity Strain")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.secondary)
                
                Text("\(clampedStrain)%")
                    .font(.system(size: 26, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
            }
            
            Spacer()
            
            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.15), lineWidth: 10)
                
                Circle()
                    .trim(from: 0, to: CGFloat(Double(clampedStrain) / 100.0))
                    .stroke(
                        AngularGradient(
                            gradient: Gradient(colors: [
                                Color(hex: "#FF8A65"),
                                Color(hex: "#FF4081")
                            ]),
                            center: .center
                        ),
                        style: StrokeStyle(lineWidth: 10, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                
                Text("\(clampedStrain)%")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.primary)
            }
            .frame(width: 64, height: 64)
        }
    }
    
    private var metricsSection: some View {
        VStack(spacing: 16) {
            HStack {
                metricColumn(
                    title: "Total Duration",
                    value: (session.duration ?? 0).formattedDuration
                )
                
                Spacer()
                
                metricColumn(
                    title: "Active Duration",
                    value: (session.duration ?? 0).formattedDuration
                )
            }
            
            HStack {
                let caloriesText: String = {
                    if let totalCalories = totalCalories {
                        return "\(Int(totalCalories)) kCal"
                    } else {
                        return "—"
                    }
                }()
                
                metricColumn(
                    title: "Total Energy",
                    value: caloriesText
                )
                
                Spacer()
                
                let heartRateText: String = {
                    if let avgHeartRate = avgHeartRate {
                        return "\(Int(avgHeartRate)) bpm"
                    } else {
                        return "—"
                    }
                }()
                
                metricColumn(
                    title: "Heart Rate",
                    value: heartRateText
                )
            }
        }
    }
    
    private var cardioImpactSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Cardio Impact")
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(.primary)

            VStack(alignment: .leading, spacing: 4) {
                Text("Cardio Load")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.secondary)

                HStack(spacing: 6) {
                    if let delta = cardioLoadDelta {
                        Text(delta >= 0 ? "+\(delta)" : "\(delta)")
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                            .foregroundColor(.primary)
                    } else {
                        Text("—")
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                            .foregroundColor(.primary)
                    }

                    if let label = cardioLoadLabel {
                        Text(label)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(Color(hex: "#FF3B30"))
                    }
                }
            }
        }
    }
    
    // MARK: - Helpers
    
    private func metricColumn(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title.uppercased())
                .font(.system(size: 10, weight: .bold))
                .tracking(1)
                .foregroundColor(.secondary)
            
            Text(value)
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundColor(.primary)
        }
    }
}


