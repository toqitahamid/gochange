import SwiftUI

struct RecoveryView: View {
    @EnvironmentObject var viewModel: DashboardViewModel
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        ZStack {
            // Background
            Image("recovery_bg")
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
                    if viewModel.recoveryScore > 0 {
                        InsightCard(
                            title: insightTitle,
                            message: insightMessage,
                            icon: "leaf.fill",
                            color: .green
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
            Text("Recovery")
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
                progress: Double(viewModel.recoveryScore) / 100.0,
                lineWidth: 24,
                gradient: LinearGradient(
                    colors: [.green, .mint],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                trackColor: .white.opacity(0.2)
            )
            .frame(width: 220, height: 220)
            
            VStack(spacing: 4) {
                Text("\(viewModel.recoveryScore)%")
                    .font(.system(size: 48, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                
                Text("recovered")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white.opacity(0.8))
            }
        }
        .padding(.vertical, 20)
    }
    
    private var metricsGrid: some View {
        HStack(spacing: 12) {
            MetricCard(
                title: "Resting HRV",
                value: String(format: "%.1f", viewModel.hrv),
                unit: "ms",
                icon: "waveform.path.ecg",
                color: .green,
                trend: .up // Mock trend for now
            )
            
            MetricCard(
                title: "Resting HR",
                value: String(format: "%.1f", viewModel.restingHR),
                unit: "bpm",
                icon: "heart.fill",
                color: .red,
                trend: .down // Mock trend for now
            )
        }
    }
    
    private var insightTitle: String {
        if viewModel.recoveryScore >= 80 {
            return "Feeling ready to move"
        } else if viewModel.recoveryScore >= 50 {
            return "Balanced Recovery"
        } else {
            return "Take it easy"
        }
    }
    
    private var insightMessage: String {
        if viewModel.recoveryScore >= 80 {
            return "With a resting HRV of \(Int(viewModel.hrv)) ms and resting heart rate at \(Int(viewModel.restingHR)) bpm your recovery is higher than normal. You can take advantage of this energy for a strong session today."
        } else if viewModel.recoveryScore >= 50 {
            return "Your recovery metrics are within normal range. A moderate workout would be appropriate today."
        } else {
            return "Your body needs rest. Consider a light recovery session or a full rest day to bounce back stronger."
        }
    }
}

#Preview {
    RecoveryView()
        .environmentObject(DashboardViewModel())
}
