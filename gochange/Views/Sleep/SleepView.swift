import SwiftUI

struct SleepView: View {
    @EnvironmentObject var viewModel: HomeViewModel
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        ZStack {
            // Background
            LinearGradient(
                colors: [Color(hex: "#0F2027"), Color(hex: "#203A43"), Color(hex: "#2C5364")], // Midnight Blue/Violet theme
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    header
                    
                    // Main Score
                    mainScore
                    
                    // Metrics Grid
                    metricsGrid
                    
                    // Insight
                    if viewModel.sleepScore > 0 {
                        InsightCard(
                            title: insightTitle,
                            message: insightMessage,
                            icon: "moon.stars.fill",
                            color: AppColors.primary
                        )
                    }
                    
                    sleepStages
                    
                    Spacer(minLength: 100)
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "chevron.left")
                        .foregroundColor(.white)
                        .padding(8)
                        .background(Color.black.opacity(0.3))
                        .clipShape(Circle())
                }
            }
        }
    }
    
    private var header: some View {
        VStack(spacing: 8) {
            Text("Sleep")
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.white)
                .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)
            
            Text(Date().formatted(date: .long, time: .omitted))
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.8))
                .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)
        }
    }
    
    private var mainScore: some View {
        ZStack {
            CircularProgressView(
                progress: Double(viewModel.sleepScore) / 100.0,
                lineWidth: 24,
                gradient: LinearGradient(
                    colors: [.blue, .purple],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                trackColor: .white.opacity(0.15)
            )
            .frame(width: 220, height: 220)
            
            VStack(spacing: 4) {
                Text("\(viewModel.sleepScore)%")
                    .font(.system(size: 48, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                
                Text("quality")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white.opacity(0.8))
            }
        }
        .padding(.vertical, 20)
    }
    
    private func formatDuration(_ seconds: TimeInterval) -> String {
        let hours = Int(seconds / 3600)
        let minutes = Int(seconds.truncatingRemainder(dividingBy: 3600) / 60)
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        }
        return "\(minutes)m"
    }

    private var metricsGrid: some View {
        HStack(spacing: 12) {
            MetricCard(
                title: "Time in bed",
                value: viewModel.sleepData.map { formatDuration($0.totalDuration) } ?? "--",
                unit: nil,
                icon: "bed.double.fill",
                color: AppColors.primary
            )

            MetricCard(
                title: "Time asleep",
                value: viewModel.sleepData.map {
                    formatDuration($0.deepDuration + $0.remDuration + $0.coreDuration)
                } ?? "--",
                unit: nil,
                icon: "clock.fill",
                color: .purple,
                trend: .down
            )
        }
    }
    
    private var sleepStages: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Sleep Stages")
                .font(.headline)
                .foregroundColor(.white)

            if let sleep = viewModel.sleepData, sleep.totalDuration > 0 {
                let total = sleep.totalDuration
                GeometryReader { geo in
                    HStack(spacing: 0) {
                        Rectangle()
                            .fill(Color.blue)
                            .frame(width: geo.size.width * (sleep.deepDuration / total), height: 30)
                        Rectangle()
                            .fill(Color.blue.opacity(0.6))
                            .frame(width: geo.size.width * (sleep.coreDuration / total), height: 30)
                        Rectangle()
                            .fill(Color.purple)
                            .frame(width: geo.size.width * (sleep.remDuration / total), height: 30)
                    }
                    .cornerRadius(8)
                }
                .frame(height: 30)

                HStack {
                    Label("Deep  \(formatDuration(sleep.deepDuration))", systemImage: "circle.fill")
                        .foregroundColor(.blue)
                    Spacer()
                    Label("Core  \(formatDuration(sleep.coreDuration))", systemImage: "circle.fill")
                        .foregroundColor(.blue.opacity(0.6))
                    Spacer()
                    Label("REM  \(formatDuration(sleep.remDuration))", systemImage: "circle.fill")
                        .foregroundColor(.purple)
                }
                .font(.caption)
            } else {
                VStack(spacing: 8) {
                    Image(systemName: "bed.double")
                        .font(.system(size: 32))
                        .foregroundColor(.white.opacity(0.4))
                    Text("No sleep data available")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.5))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white.opacity(0.05))
        )
    }
    
    private var insightTitle: String {
        if viewModel.sleepScore >= 80 {
            return "Great night's sleep"
        } else if viewModel.sleepScore >= 60 {
            return "Good rest"
        } else {
            return "Let's turn this around"
        }
    }
    
    private var insightMessage: String {
        if viewModel.sleepScore >= 80 {
            return "You hit your sleep targets! Your body is well-rested and ready for the day."
        } else if viewModel.sleepScore >= 60 {
            return "You got a decent amount of sleep. Try to maintain a consistent bedtime to improve quality."
        } else {
            return "Over the past week, your sleep has been below baseline. A few changes in your evening routine could help get things back on track."
        }
    }
}

#Preview {
    SleepView()
        .environmentObject(HomeViewModel())
}
