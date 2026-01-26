import SwiftUI

// MARK: - Score Card Style
extension View {
    func scoreCardStyle() -> some View {
        self
            .padding(16)
            .background(Color.white)
            .cornerRadius(20)
            .shadow(color: Color.black.opacity(0.08), radius: 15, x: 0, y: 5)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(Color.gray.opacity(0.15), lineWidth: 1)
            )
    }
}

// MARK: - Recovery Ring Card
struct RecoveryRingCard: View {
    let score: Double // 0-100
    let status: String
    var onTap: (() -> Void)? = nil
    
    private var color: Color {
        if score >= 80 { return AppColors.success }
        if score >= 50 { return AppColors.warning }
        return AppColors.error
    }
    
    var body: some View {
        Button {
            onTap?()
        } label: {
            VStack(spacing: 12) {
                // Ring
                ZStack {
                    Circle()
                        .stroke(Color.gray.opacity(0.1), lineWidth: 8)
                    
                    Circle()
                        .trim(from: 0, to: score / 100)
                        .stroke(color, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                    
                    VStack(spacing: 0) {
                        Text("\(Int(score))")
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundColor(.primary)
                        Text("%")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
                .frame(width: 80, height: 80)
                
                VStack(spacing: 2) {
                    Text("Recovery")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                    
                    Text(status)
                        .font(.caption2)
                        .foregroundColor(color)
                }
            }
            .frame(maxWidth: .infinity)
            .scoreCardStyle()
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Strain Progress Card
// MARK: - Strain Progress Card (Gauge)
struct StrainProgressCard: View {
    let current: Double // 0-21
    let targetLow: Double
    let targetHigh: Double
    let status: String
    var onTap: (() -> Void)? = nil
    
    private var statusColor: Color {
        switch status {
        case "Optimal": return AppColors.success
        case "Overreaching": return AppColors.error
        default: return AppColors.primary
        }
    }
    
    var body: some View {
        Button {
            onTap?()
        } label: {
            VStack(spacing: 12) {
                // Gauge
                ZStack {
                    // Track
                    Circle()
                        .trim(from: 0, to: 0.75)
                        .stroke(Color.gray.opacity(0.1), style: StrokeStyle(lineWidth: 8, lineCap: .round))
                        .rotationEffect(.degrees(135))
                    
                    // Progress
                    Circle()
                        .trim(from: 0, to: CGFloat(min(current, 21.0) / 21.0) * 0.75)
                        .stroke(
                            LinearGradient(
                                colors: [AppColors.warning, AppColors.error],
                                startPoint: .leading,
                                endPoint: .trailing
                            ),
                            style: StrokeStyle(lineWidth: 8, lineCap: .round)
                        )
                        .rotationEffect(.degrees(135))
                    
                    VStack(spacing: 0) {
                        Text(String(format: "%.1f", current))
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                            .foregroundColor(.primary)
                        Text("Strain")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
                .frame(width: 80, height: 80)
                
                VStack(spacing: 2) {
                    Text("Target: \(Int(targetLow))-\(Int(targetHigh))")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    
                    Text(status)
                        .font(.caption2)
                        .fontWeight(.medium)
                        .foregroundColor(statusColor)
                }
            }
            .frame(maxWidth: .infinity)
            .scoreCardStyle()
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Sleep Score Card
struct SleepScoreCard: View {
    let score: Double // 0-100
    let duration: TimeInterval // seconds
    let deepPercent: Double
    let remPercent: Double
    var onTap: (() -> Void)? = nil
    
    private var color: Color {
        if score >= 80 { return Color(hex: "#7B68EE") } // Purple for sleep
        if score >= 50 { return AppColors.warning }
        return AppColors.error
    }
    
    private var formattedDuration: String {
        let hours = Int(duration) / 3600
        let minutes = (Int(duration) % 3600) / 60
        return "\(hours)h \(minutes)m"
    }
    
    var body: some View {
        Button {
            onTap?()
        } label: {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "moon.fill")
                        .foregroundColor(color)
                    Text("Sleep")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("\(Int(score))%")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(color)
                }
                
                Text(formattedDuration)
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
                
                // Stage Bars
                GeometryReader { geometry in
                    HStack(spacing: 2) {
                        // Light
                        Rectangle()
                            .fill(Color.gray.opacity(0.2))
                            .frame(width: geometry.size.width * (1 - deepPercent - remPercent))
                        
                        // Deep
                        Rectangle()
                            .fill(color.opacity(0.6))
                            .frame(width: geometry.size.width * deepPercent)
                        
                        // REM
                        Rectangle()
                            .fill(color)
                            .frame(width: geometry.size.width * remPercent)
                    }
                    .cornerRadius(4)
                }
                .frame(height: 8)
                
                HStack {
                    Label("Deep", systemImage: "circle.fill")
                        .font(.system(size: 9))
                        .foregroundColor(color.opacity(0.6))
                    Label("REM", systemImage: "circle.fill")
                        .font(.system(size: 9))
                        .foregroundColor(color)
                }
            }
            .frame(maxWidth: .infinity)
            .scoreCardStyle()
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Energy Bank Card
struct EnergyBankCard: View {
    let level: Double // 0-100
    var onTap: (() -> Void)? = nil
    
    private var color: Color {
        if level >= 70 { return AppColors.success }
        if level >= 40 { return AppColors.warning }
        return AppColors.error
    }
    
    private var statusText: String {
        if level >= 80 { return "Full" }
        if level >= 60 { return "Good" }
        if level >= 40 { return "Steady" }
        if level >= 20 { return "Low" }
        return "Depleted"
    }
    
    var body: some View {
        Button {
            onTap?()
        } label: {
            VStack(spacing: 12) {
                // Battery Icon
                ZStack {
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(Color.gray.opacity(0.3), lineWidth: 2)
                        .frame(width: 50, height: 70)
                    
                    // Battery Cap
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 20, height: 6)
                        .offset(y: -38)
                    
                    // Fill Level
                    VStack {
                        Spacer()
                        RoundedRectangle(cornerRadius: 4)
                            .fill(
                                LinearGradient(
                                    colors: [color.opacity(0.6), color],
                                    startPoint: .bottom,
                                    endPoint: .top
                                )
                            )
                            .frame(height: 62 * (level / 100))
                    }
                    .frame(width: 42, height: 62)
                    .clipShape(RoundedRectangle(cornerRadius: 4))
                    
                    Text("\(Int(level))%")
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundColor(level > 50 ? .white : .primary)
                }
                
                VStack(spacing: 2) {
                    Text("Energy")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                    
                    Text(statusText)
                        .font(.caption2)
                        .foregroundColor(color)
                }
            }
            .frame(maxWidth: .infinity)
            .scoreCardStyle()
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Previews
#Preview("Recovery Ring") {
    RecoveryRingCard(score: 85, status: "Prime")
        .padding()
        .background(Color(hex: "#F5F5F7"))
}

#Preview("Strain Progress") {
    StrainProgressCard(current: 12.5, targetLow: 10, targetHigh: 14, status: "Optimal")
        .padding()
        .background(Color(hex: "#F5F5F7"))
}

#Preview("Sleep Score") {
    SleepScoreCard(score: 78, duration: 7.5 * 3600, deepPercent: 0.20, remPercent: 0.25)
        .padding()
        .background(Color(hex: "#F5F5F7"))
}

#Preview("Energy Bank") {
    EnergyBankCard(level: 65)
        .padding()
        .background(Color(hex: "#F5F5F7"))
}
