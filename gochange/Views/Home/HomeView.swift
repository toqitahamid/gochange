import SwiftUI
import SwiftData

struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject private var viewModel = DashboardViewModel()

    @State private var scrollOffset: CGFloat = 0
    @State private var lastScrollOffset: CGFloat = 0
    @State private var showHeader = true

    var body: some View {
        NavigationStack {
            ZStack(alignment: .top) {
                ScrollView {
                    VStack(spacing: 24) {
                        // Spacer for header
                        Color.clear
                            .frame(height: 80)
                            .readScrollOffset { offset in
                                handleScroll(offset: offset)
                            }

                        // Summary Rings
                        SummaryRingsView(
                            strain: viewModel.strainScore,
                            recovery: viewModel.recoveryScore,
                            sleep: viewModel.sleepScore
                        )

                        // Daily Insight
                        dailyInsight

                        // Health Monitor
                        HealthMonitorGrid(
                            rhr: viewModel.restingHR,
                            hrv: viewModel.hrv,
                            respiratoryRate: viewModel.respiratoryRate,
                            oxygenSaturation: viewModel.oxygenSaturation,
                            bodyTemperature: viewModel.bodyTemperature,
                            stepCount: viewModel.stepCount,
                            vo2Max: viewModel.vo2Max,
                            sleepDuration: viewModel.sleepData?.totalDuration
                        )

                        // Timeline
                        TimelineView(workouts: viewModel.recentWorkouts)

                        Spacer(minLength: 100)
                    }
                    .padding(.horizontal, 20)
                }
                .coordinateSpace(name: "scroll")
                .background(Color(hex: "#F5F5F7").ignoresSafeArea())
                .preferredColorScheme(.light)

                // Floating Header with Liquid Glass effect
                header
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    .background(
                        .ultraThinMaterial,
                        in: RoundedRectangle(cornerRadius: 0)
                    )
                    .offset(y: showHeader ? 0 : -100)
                    .animation(.smooth(duration: 0.3), value: showHeader)
            }
            .onAppear {
                Task {
                    await viewModel.loadData(context: modelContext)
                }
            }
        }
    }

    private func handleScroll(offset: CGFloat) {
        let delta = offset - lastScrollOffset

        // Scrolling down (content moving up)
        if delta < -5 && offset < -10 {
            showHeader = false
        }
        // Scrolling up (content moving down) or at top
        else if delta > 5 || offset > -5 {
            showHeader = true
        }

        lastScrollOffset = offset
    }
    
    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(Date().formatted(date: .long, time: .omitted))
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Text(viewModel.greeting)
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.primary)
            }
            
            Spacer()
            
            // Profile Button
            Circle()
                .fill(Color.blue.opacity(0.1))
                .frame(width: 40, height: 40)
                .overlay(
                    Text("TS") // Initials
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.blue)
                )
        }
        .padding(.bottom, 10)
    }
    
    private var dailyInsight: some View {
        HStack(spacing: 16) {
            Image(systemName: "sparkles")
                .font(.system(size: 24))
                .foregroundColor(.yellow)
                .frame(width: 50, height: 50)
                .background(Color.yellow.opacity(0.1))
                .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Daily Insight")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)
                
                Text(insightText)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.primary)
            }
            
            Spacer()
        }
        .padding(20)
        .background {
            RoundedRectangle(cornerRadius: 24)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 4)
                .overlay(
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(Color.gray.opacity(0.1), lineWidth: 1)
                )
        }
    }
    
    private var insightText: String {
        if viewModel.recoveryScore >= 66 {
            return "You are well recovered. Ready to train hard!"
        } else if viewModel.recoveryScore >= 33 {
            return "Moderate recovery. Maintain a steady pace."
        } else {
            return "Low recovery. Prioritize rest today."
        }
    }
}

#Preview {
    HomeView()
        .modelContainer(for: [WorkoutSession.self, WorkoutDay.self])
}

#Preview {
    HomeView()
        .modelContainer(for: [WorkoutSession.self, WorkoutDay.self])
}

