import SwiftUI

struct ComparisonMetricsRow: View {
    let currentSets: [SetLog]
    let previousSets: [PreviousSetInfo]
    let accentColor: Color

    private var volumeToday: Double {
        currentSets.filter { $0.isCompleted }.reduce(0.0) { total, set in
            if let weight = set.weight, let reps = set.actualReps {
                return total + (weight * Double(reps))
            }
            return total
        }
    }

    private var volumeLast: Double {
        previousSets.reduce(0.0) { total, set in
            if let weight = set.weight, let reps = set.reps {
                return total + (weight * Double(reps))
            }
            return total
        }
    }

    private var volumeChange: Double {
        guard volumeLast > 0 else { return 0 }
        return ((volumeToday - volumeLast) / volumeLast) * 100
    }

    private var completedSetsCount: Int {
        currentSets.filter { $0.isCompleted }.count
    }

    private var totalSetsCount: Int {
        currentSets.count
    }

    private var averageRIR: Double? {
        let completedWithRIR = currentSets.filter { $0.isCompleted && $0.rir != nil }
        guard !completedWithRIR.isEmpty else { return nil }
        let sum = completedWithRIR.compactMap { $0.rir }.reduce(0, +)
        return Double(sum) / Double(completedWithRIR.count)
    }

    private var rirIntensity: String {
        guard let rir = averageRIR else { return "—" }
        if rir <= 1 { return "MAX" }
        if rir <= 2 { return "HIGH" }
        if rir <= 3 { return "MOD" }
        return "LOW"
    }

    private var rirColor: Color {
        guard let rir = averageRIR else { return AppColors.textTertiary }
        if rir <= 1 { return AppColors.error }
        if rir <= 2 { return AppColors.warning }
        if rir <= 3 { return AppColors.primary }
        return AppColors.success
    }

    var body: some View {
        HStack(spacing: 10) {
            // Volume Metric
            WorkoutMetricCard(
                icon: "flame.fill",
                iconColor: AppColors.primary,
                title: "VOLUME",
                value: volumeToday > 0 ? formatVolume(volumeToday) : "—",
                change: volumeToday > 0 && volumeLast > 0 ? volumeChange : nil,
                subtitle: volumeLast > 0 ? "Last: \(formatVolume(volumeLast))" : nil
            )

            // Sets Metric
            WorkoutMetricCard(
                icon: "checkmark.circle.fill",
                iconColor: completedSetsCount == totalSetsCount ? AppColors.success : accentColor,
                title: "SETS",
                value: "\(completedSetsCount)/\(totalSetsCount)",
                change: nil,
                subtitle: nil,
                progress: totalSetsCount > 0 ? Double(completedSetsCount) / Double(totalSetsCount) : 0,
                progressColor: completedSetsCount == totalSetsCount ? AppColors.success : accentColor
            )

            // Average RIR Metric
            WorkoutMetricCard(
                icon: "gauge.with.dots.needle.67percent",
                iconColor: rirColor,
                title: "AVG RIR",
                value: averageRIR != nil ? String(format: "%.1f", averageRIR!) : "—",
                change: nil,
                subtitle: rirIntensity,
                subtitleColor: rirColor
            )
        }
    }

    private func formatVolume(_ volume: Double) -> String {
        if volume >= 1000 {
            return String(format: "%.1fk", volume / 1000)
        }
        return "\(Int(volume))"
    }
}

// MARK: - Workout Metric Card
struct WorkoutMetricCard: View {
    let icon: String
    let iconColor: Color
    let title: String
    let value: String
    var change: Double? = nil
    var subtitle: String? = nil
    var subtitleColor: Color? = nil
    var progress: Double? = nil
    var progressColor: Color? = nil

    var body: some View {
        VStack(spacing: 8) {
            // Icon & Title Row
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(iconColor)

                Text(title)
                    .font(AppFonts.label(9))
                    .tracking(1)
                    .foregroundColor(AppColors.textTertiary)

                Spacer()
            }

            // Value
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(value)
                    .font(AppFonts.rounded(24, weight: .bold))
                    .foregroundColor(AppColors.textPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)

                Spacer()

                // Change indicator
                if let change = change {
                    HStack(spacing: 2) {
                        Image(systemName: change >= 0 ? "arrow.up" : "arrow.down")
                            .font(.system(size: 8, weight: .bold))

                        Text("\(abs(Int(change)))%")
                            .font(AppFonts.rounded(10, weight: .semibold))
                    }
                    .foregroundColor(change >= 0 ? AppColors.success : AppColors.error)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(
                        (change >= 0 ? AppColors.success : AppColors.error).opacity(0.12)
                    )
                    .clipShape(Capsule())
                }
            }

            // Progress bar or subtitle
            if let progress = progress, let progressColor = progressColor {
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 2)
                            .fill(Color.gray.opacity(0.15))
                            .frame(height: 4)

                        RoundedRectangle(cornerRadius: 2)
                            .fill(progressColor)
                            .frame(width: geo.size.width * progress, height: 4)
                    }
                }
                .frame(height: 4)
            } else if let subtitle = subtitle {
                HStack {
                    Text(subtitle)
                        .font(AppFonts.label(10))
                        .foregroundColor(subtitleColor ?? AppColors.textTertiary)
                    Spacer()
                }
            } else {
                Spacer()
                    .frame(height: 4)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 12)
        .padding(.vertical, 12)
        .background(AppColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: AppLayout.miniRadius))
        .overlay(
            RoundedRectangle(cornerRadius: AppLayout.miniRadius)
                .stroke(Color.gray.opacity(0.08), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.03), radius: 6, x: 0, y: 2)
    }
}
