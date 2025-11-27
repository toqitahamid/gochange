import SwiftUI

struct StrainView: View {
    @EnvironmentObject var viewModel: DashboardViewModel
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        ZStack {
            // Background
            Image("strain_bg")
                .resizable()
                .aspectRatio(contentMode: .fill)
                .ignoresSafeArea()
                .overlay(
                    LinearGradient(
                        colors: [.black.opacity(0.3), .black.opacity(0.1)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
            
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    header
                    
                    // Main Score
                    mainScore
                    
                    // Metrics Grid
                    metricsGrid
                    
                    // Insight
                    if viewModel.strainScore > 0 {
                        InsightCard(
                            title: insightTitle,
                            message: insightMessage,
                            icon: "flame.fill",
                            color: .orange
                        )
                    }
                    
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
            Text("Strain")
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.white)
            
            Text(Date().formatted(date: .long, time: .omitted))
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.8))
        }
    }
    
    private var mainScore: some View {
        ZStack {
            CircularProgressView(
                progress: Double(viewModel.strainScore) / 100.0,
                lineWidth: 24,
                gradient: LinearGradient(
                    colors: [.orange, .yellow],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                trackColor: .white.opacity(0.2)
            )
            .frame(width: 220, height: 220)
            
            VStack(spacing: 4) {
                Text("\(viewModel.strainScore)%")
                    .font(.system(size: 48, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                
                Text("strain")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white.opacity(0.8))
            }
        }
        .padding(.vertical, 20)
    }
    
    private var metricsGrid: some View {
        HStack(spacing: 12) {
            MetricCard(
                title: "Duration",
                value: formatDuration(viewModel.workoutDuration),
                unit: nil,
                icon: "clock",
                color: .orange
            )
            
            MetricCard(
                title: "Total energy",
                value: "\(Int(viewModel.activeCalories))",
                unit: "kCal",
                icon: "flame",
                color: .red,
                trend: .up
            )
        }
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
    StrainView()
        .environmentObject(DashboardViewModel())
}
