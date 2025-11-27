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
                                background: "RecoveryBackground"
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
                                background: "SleepGradient" // Triggers gradient fallback
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
                                background: "StrainGradient" // Triggers gradient fallback
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
            // Background
            if background.hasSuffix("Background") {
                // Image Asset
                Image(background)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(height: 180)
                    .clipped()
                    .overlay(
                        LinearGradient(
                            colors: [.black.opacity(0.7), .black.opacity(0.3)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
            } else {
                // Fallback Gradient
                gradientFor(title: title)
                    .frame(height: 180)
            }
            
            HStack {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: icon)
                            .foregroundColor(color)
                        Text(title)
                            .font(.headline)
                            .foregroundColor(.white)
                            .shadow(color: .black.opacity(0.5), radius: 2, x: 0, y: 1) // Text shadow
                    }
                    
                    Spacer()
                    
                    HStack(spacing: 16) {
                        ForEach(metrics.sorted(by: { $0.key < $1.key }), id: \.key) { key, value in
                            VStack(alignment: .leading, spacing: 2) {
                                Text(key)
                                    .font(.caption2)
                                    .foregroundColor(.white.opacity(0.8))
                                Text(value)
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(.white)
                                    .shadow(color: .black.opacity(0.5), radius: 2, x: 0, y: 1)
                            }
                            .padding(8)
                            .background(.ultraThinMaterial) // Glassmorphism for metrics
                            .cornerRadius(8)
                        }
                    }
                }
                
                Spacer()
                
                // Score Circle
                CircularProgressView(
                    progress: Double(score) / 100.0,
                    lineWidth: 12,
                    color: color
                )
                .frame(width: 80, height: 80)
                .overlay(
                    VStack(spacing: 2) {
                        Text("\(score)%")
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                            .shadow(color: .black.opacity(0.5), radius: 2, x: 0, y: 1)
                        Text(title.lowercased())
                            .font(.system(size: 10))
                            .foregroundColor(.white.opacity(0.8))
                    }
                )
            }
            .padding(20)
        }
        .cornerRadius(24)
        .shadow(color: Color.black.opacity(0.2), radius: 10, x: 0, y: 5)
    }
    
    private func gradientFor(title: String) -> LinearGradient {
        switch title {
        case "Recovery":
            return LinearGradient(
                colors: [Color(hex: "#0F2027"), Color(hex: "#203A43"), Color(hex: "#2C5364")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case "Sleep":
            return LinearGradient(
                colors: [Color(hex: "#0F2027"), Color(hex: "#203A43"), Color(hex: "#2C5364")], // Midnight Blue/Violet
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case "Strain":
            return LinearGradient(
                colors: [Color(hex: "#451e11"), Color(hex: "#6e2c18"), Color(hex: "#9c3d21")], // Burnt Orange/Red
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        default:
            return LinearGradient(colors: [.gray, .black], startPoint: .top, endPoint: .bottom)
        }
    }
}

#Preview {
    HomeView()
        .modelContainer(for: [WorkoutSession.self, WorkoutDay.self])
}

