import SwiftUI

/// A light-themed metric card for displaying health and fitness metrics
/// Designed for light backgrounds with white cards and colored accents
struct LightMetricCard: View {
    let title: String
    let value: String
    let unit: String?
    let icon: String
    let color: Color
    var trend: Trend? = nil

    enum Trend {
        case up, down, neutral

        var icon: String {
            switch self {
            case .up: return "arrow.up"
            case .down: return "arrow.down"
            case .neutral: return "minus"
            }
        }

        var color: Color {
            switch self {
            case .up: return .green
            case .down: return .red
            case .neutral: return .gray
            }
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.system(size: 16, weight: .semibold))

                Text(title)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.secondary)

                Spacer()
            }

            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(value)
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)

                if let unit = unit {
                    Text(unit)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.secondary)
                }

                Spacer()

                if let trend = trend {
                    Image(systemName: trend.icon)
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(trend.color)
                        .padding(6)
                        .background(trend.color.opacity(0.12))
                        .clipShape(Circle())
                }
            }
        }
        .padding(20)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 4)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.gray.opacity(0.1), lineWidth: 1)
        )
    }
}

#Preview {
    HStack(spacing: 12) {
        LightMetricCard(
            title: "Duration",
            value: "45",
            unit: "min",
            icon: "clock.fill",
            color: Color(hex: "#FF9500")
        )

        LightMetricCard(
            title: "Total Energy",
            value: "285",
            unit: "kCal",
            icon: "flame.fill",
            color: Color(hex: "#FF5E3A"),
            trend: .up
        )
    }
    .padding()
    .background(Color(hex: "#F5F5F7"))
}
