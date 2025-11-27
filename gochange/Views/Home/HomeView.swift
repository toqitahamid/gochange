import SwiftUI
import SwiftData

struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject private var viewModel = DashboardViewModel()
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    header
                    
                    // Main Cards
                    VStack(spacing: 16) {
                        // Recovery Card
                        NavigationLink(destination: RecoveryView().environmentObject(viewModel)) {
                            DashboardCard(
                                title: "Recovery",
                                score: viewModel.recoveryScore,
                                color: .green,
                                icon: "leaf.fill",
                                metrics: [
                                    "HRV": "\(Int(viewModel.hrv)) ms",
                                    "RHR": "\(Int(viewModel.restingHR)) bpm"
                                ],
                                background: "recovery_bg"
                            )
                        }
                        
                        // Sleep Card
                        NavigationLink(destination: SleepView().environmentObject(viewModel)) {
                            DashboardCard(
                                title: "Sleep",
                                score: viewModel.sleepScore,
                                color: .blue,
                                icon: "moon.stars.fill",
                                metrics: [
                                    "Time in bed": viewModel.sleepData?.formattedTotal ?? "--",
                                    "Quality": "\(viewModel.sleepScore)%"
                                ],
                                background: "sleep_bg"
                            )
                        }
                        
                        // Strain Card
                        NavigationLink(destination: StrainView().environmentObject(viewModel)) {
                            DashboardCard(
                                title: "Strain",
                                score: viewModel.strainScore,
                                color: .orange,
                                icon: "flame.fill",
                                metrics: [
                                    "Duration": formatDuration(viewModel.workoutDuration),
                                    "Energy": "\(Int(viewModel.activeCalories)) kcal"
                                ],
                                background: "strain_bg"
                            )
                        }
                    }
                    
                    Spacer(minLength: 100)
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
            }
            .background(Color.black.ignoresSafeArea())
            .onAppear {
                Task {
                    await viewModel.loadData(context: modelContext)
                }
            }
        }
    }
    
    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(viewModel.greeting)
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.white)
                
                Text(Date().formatted(date: .long, time: .omitted))
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            // Profile or Settings button could go here
            Circle()
                .fill(Color.white.opacity(0.1))
                .frame(width: 40, height: 40)
                .overlay(
                    Image(systemName: "person.fill")
                        .foregroundColor(.white)
                )
        }
        .padding(.bottom, 10)
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration / 60)
        return "\(minutes)m"
    }
}

struct DashboardCard: View {
    let title: String
    let score: Int
    let color: Color
    let icon: String
    let metrics: [String: String]
    let background: String
    
    var body: some View {
        ZStack {
            // Background Image
            Image(background)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(height: 180)
                .clipped()
                .overlay(
                    LinearGradient(
                        colors: [.black.opacity(0.6), .black.opacity(0.2)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
            
            HStack {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: icon)
                            .foregroundColor(color)
                        Text(title)
                            .font(.headline)
                            .foregroundColor(.white)
                    }
                    
                    Spacer()
                    
                    HStack(spacing: 16) {
                        ForEach(metrics.sorted(by: { $0.key < $1.key }), id: \.key) { key, value in
                            VStack(alignment: .leading, spacing: 2) {
                                Text(key)
                                    .font(.caption2)
                                    .foregroundColor(.white.opacity(0.7))
                                Text(value)
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(.white)
                            }
                            .padding(8)
                            .background(Color.white.opacity(0.1))
                            .cornerRadius(8)
                        }
                    }
                }
                
                Spacer()
                
                // Circular Score
                ZStack {
                    Circle()
                        .stroke(Color.white.opacity(0.2), lineWidth: 8)
                        .frame(width: 80, height: 80)
                    
                    Circle()
                        .trim(from: 0, to: Double(score) / 100.0)
                        .stroke(
                            color,
                            style: StrokeStyle(lineWidth: 8, lineCap: .round)
                        )
                        .rotationEffect(.degrees(-90))
                        .frame(width: 80, height: 80)
                    
                    VStack(spacing: 0) {
                        Text("\(score)%")
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                        Text(title.lowercased())
                            .font(.caption2)
                            .foregroundColor(.white.opacity(0.7))
                    }
                }
            }
            .padding(20)
        }
        .cornerRadius(24)
        .shadow(color: Color.black.opacity(0.2), radius: 10, x: 0, y: 5)
    }
}

#Preview {
    HomeView()
        .modelContainer(for: [WorkoutSession.self, WorkoutDay.self])
}

