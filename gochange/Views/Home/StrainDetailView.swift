import SwiftUI

struct StrainDetailView: View {
    @StateObject private var viewModel = HomeViewModel()
    @Environment(\.dismiss) var dismiss

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                header

                // Main Strain Card
                mainStrainCard

                // Metrics Grid
                metricsGrid

                // Insight Card
                if viewModel.strainScore > 0 {
                    insightCard
                }

                Spacer(minLength: 100)
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
        }
        .background(Color(hex: "#F5F5F7").ignoresSafeArea())
        .preferredColorScheme(.light)
        .navigationTitle("Strain")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    // Share or info action
                } label: {
                    Image(systemName: "info.circle.fill")
                        .foregroundStyle(Color(hex: "#FF9500"))
                        .symbolRenderingMode(.hierarchical)
                }
            }
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Strain")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)

                Text(Date().formatted(date: .long, time: .omitted))
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
    }

    // MARK: - Main Strain Card

    private var mainStrainCard: some View {
        VStack(spacing: 24) {
            // Strain Ring
            ZStack {
                // Background circle
                Circle()
                    .stroke(Color.gray.opacity(0.1), lineWidth: 20)
                    .frame(width: 200, height: 200)

                // Strain progress with gradient
                Circle()
                    .trim(from: 0, to: Double(viewModel.strainScore) / 100.0)
                    .stroke(
                        LinearGradient(
                            colors: [Color(hex: "#FF9500"), Color(hex: "#FF5E3A")],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        style: StrokeStyle(lineWidth: 20, lineCap: .round)
                    )
                    .frame(width: 200, height: 200)
                    .rotationEffect(.degrees(-90))
                    .shadow(color: Color(hex: "#FF9500").opacity(0.3), radius: 10, x: 0, y: 0)
                    .animation(.spring(response: 1.0, dampingFraction: 0.8), value: viewModel.strainScore)

                // Center content
                VStack(spacing: 8) {
                    Text("\(viewModel.strainScore)")
                        .font(.system(size: 56, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)

                    Text("strain score")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.secondary)
                        .tracking(0.5)
                }
            }

            // Status badge
            HStack(spacing: 8) {
                Image(systemName: strainStatusIcon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(strainStatusColor)

                Text(strainStatusText)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(strainStatusColor)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(strainStatusColor.opacity(0.12))
            .clipShape(Capsule())
        }
        .padding(.vertical, 32)
        .frame(maxWidth: .infinity)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 4)
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(Color.gray.opacity(0.1), lineWidth: 1)
        )
    }

    // MARK: - Metrics Grid

    private var metricsGrid: some View {
        HStack(spacing: 12) {
            LightMetricCard(
                title: "Duration",
                value: formatDuration(viewModel.workoutDuration),
                unit: nil,
                icon: "clock.fill",
                color: Color(hex: "#FF9500")
            )

            LightMetricCard(
                title: "Total Energy",
                value: "\(Int(viewModel.activeCalories))",
                unit: "kCal",
                icon: "flame.fill",
                color: Color(hex: "#FF5E3A"),
                trend: .up
            )
        }
    }

    // MARK: - Insight Card

    private var insightCard: some View {
        LightInsightCard(
            title: insightTitle,
            message: insightMessage,
            icon: "flame.fill",
            color: Color(hex: "#FF9500")
        )
    }

    // MARK: - Computed Properties

    private var strainStatusIcon: String {
        if viewModel.strainScore >= 80 { return "flame.fill" }
        else if viewModel.strainScore >= 50 { return "checkmark.circle.fill" }
        else { return "moon.fill" }
    }

    private var strainStatusColor: Color {
        if viewModel.strainScore >= 80 { return Color(hex: "#FF5E3A") }
        else if viewModel.strainScore >= 50 { return Color(hex: "#FF9500") }
        else { return Color(hex: "#5B7FFF") }
    }

    private var strainStatusText: String {
        if viewModel.strainScore >= 80 { return "High Intensity" }
        else if viewModel.strainScore >= 50 { return "Moderate Effort" }
        else { return "Light Activity" }
    }

    private var insightTitle: String {
        if viewModel.strainScore >= 80 {
            return "Absolutely crushing it! 🔥"
        } else if viewModel.strainScore >= 50 {
            return "Solid effort"
        } else {
            return "Light day"
        }
    }

    private var insightMessage: String {
        if viewModel.strainScore >= 80 {
            return "You've been on a roll lately, consistently hitting solid strain levels. Today you hit your target strain, so now give your body time to recover."
        } else if viewModel.strainScore >= 50 {
            return "Good work today. You've maintained a healthy balance of strain and recovery."
        } else {
            return "A lighter load today allows your body to recharge for upcoming challenges."
        }
    }

    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration / 60)
        return "\(minutes)m"
    }
}

#Preview {
    NavigationStack {
        StrainDetailView()
    }
}
