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

    var body: some View {
        HStack(spacing: 12) {
            // Volume Metric
            ComparisonMetricCard(
                title: "VOLUME",
                value: volumeToday > 0 ? "\(Int(volumeToday))" : "—",
                subtitle: volumeLast > 0 ? "vs \(Int(volumeLast)) lbs" : "No previous data",
                change: volumeToday > 0 && volumeLast > 0 ? volumeChange : nil,
                accentColor: Color(hex: "#5B7FFF")
            )

            // Sets Completed Metric
            ComparisonMetricCard(
                title: "SETS",
                value: "\(completedSetsCount)/\(totalSetsCount)",
                subtitle: totalSetsCount > 0 ? "\(Int((Double(completedSetsCount) / Double(totalSetsCount)) * 100))% complete" : "—",
                change: nil,
                accentColor: completedSetsCount == totalSetsCount ? Color(hex: "#00D4AA") : Color(hex: "#5B7FFF")
            )

            // Average RIR Metric
            ComparisonMetricCard(
                title: "AVG RIR",
                value: averageRIR != nil ? String(format: "%.1f", averageRIR!) : "—",
                subtitle: averageRIR != nil ? "Reps in reserve" : "Not tracked",
                change: nil,
                accentColor: Color(hex: "#5B7FFF")
            )
        }
    }
}

// MARK: - Comparison Metric Card
struct ComparisonMetricCard: View {
    let title: String
    let value: String
    let subtitle: String
    let change: Double?
    let accentColor: Color

    var body: some View {
        VStack(spacing: 6) {
            // Title
            Text(title)
                .font(.system(size: 9, weight: .bold))
                .tracking(1.5)
                .foregroundColor(.secondary.opacity(0.8))

            // Value
            Text(value)
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundColor(accentColor)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .padding(.vertical, 2)

            // Subtitle with optional change indicator
            HStack(spacing: 4) {
                if let change = change {
                    Image(systemName: change >= 0 ? "arrow.up.right" : "arrow.down.right")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(change >= 0 ? Color(hex: "#00D4AA") : Color(hex: "#FF6B6B"))

                    Text("\(change >= 0 ? "+" : "")\(String(format: "%.0f", change))%")
                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                        .foregroundColor(change >= 0 ? Color(hex: "#00D4AA") : Color(hex: "#FF6B6B"))
                } else {
                    Text(subtitle)
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.secondary.opacity(0.7))
                }
            }
            .lineLimit(1)
            .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .padding(.horizontal, 8)
        .background(Color.gray.opacity(0.03))
        .cornerRadius(20)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.gray.opacity(0.05), lineWidth: 1)
        )
    }
}
