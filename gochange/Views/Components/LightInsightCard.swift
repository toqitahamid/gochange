import SwiftUI

/// A light-themed insight card for displaying personalized messages and insights
/// Designed for light backgrounds with white cards and colored icon badges
struct LightInsightCard: View {
    let title: String
    let message: String
    let icon: String
    let color: Color

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            // Icon Badge
            ZStack {
                Circle()
                    .fill(color.opacity(0.12))
                    .frame(width: 48, height: 48)

                Image(systemName: icon)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(color)
            }

            // Content
            VStack(alignment: .leading, spacing: 8) {
                Text(title)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.primary)

                Text(message)
                    .font(.system(size: 15))
                    .foregroundColor(.secondary)
                    .lineSpacing(4)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(20)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 4)
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(Color.gray.opacity(0.1), lineWidth: 1)
        )
    }
}

#Preview {
    VStack(spacing: 20) {
        LightInsightCard(
            title: "Absolutely crushing it! 🔥",
            message: "You've been on a roll lately, consistently hitting solid strain levels. Today you hit your target strain, so now give your body time to recover.",
            icon: "flame.fill",
            color: Color(hex: "#FF9500")
        )

        LightInsightCard(
            title: "Well recovered",
            message: "Your recovery score is high. You're ready to take on an intense workout today!",
            icon: "leaf.fill",
            color: Color(hex: "#00D4AA")
        )
    }
    .padding()
    .background(Color(hex: "#F5F5F7"))
}
