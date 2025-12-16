import SwiftUI
import SwiftData
import Charts

struct RecoveryDashboardView: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject private var recoveryService = RecoveryService.shared
    @StateObject private var healthKitService = HealthKitService.shared
    
    @Query(sort: \RecoveryMetrics.date, order: .reverse) private var recoveryMetrics: [RecoveryMetrics]
    @Query(sort: \RestDay.date, order: .reverse) private var restDays: [RestDay]
    
    @State private var isLoading = true
    @State private var showingRestDayLog = false
    @State private var showingHealthKitAuth = false
    
    var todaysMetrics: RecoveryMetrics? {
        let today = Calendar.current.startOfDay(for: Date())
        return recoveryMetrics.first { Calendar.current.isDate($0.date, inSameDayAs: today) }
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    if isLoading {
                        ProgressView("Loading recovery data...")
                            .tint(Color(hex: "#00D4AA"))
                            .frame(maxWidth: .infinity, minHeight: 200)
                    } else {
                        // HealthKit Prompt if needed
                        if !healthKitService.isAuthorized || healthKitService.hasDeniedReadPermissions {
                            healthKitPromptCard
                                .padding(.horizontal, 20)
                        }
                        
                        // 1. Main Readiness Indicator
                        if let metrics = todaysMetrics {
                            readinessSection(metrics)
                                .padding(.horizontal, 20)
                            
                            // 2. Key Metrics Grid
                            keyMetricsGrid(metrics)
                                .padding(.horizontal, 20)
                            
                            // 3. Trends
                            recoveryTrendsSection
                                .padding(.horizontal, 20)
                            
                            // 4. Muscle Recovery
                            muscleRecoveryCard(metrics)
                                .padding(.horizontal, 20)
                        } else {
                            Text("No data for today")
                                .foregroundColor(.secondary)
                                .padding()
                        }
                        
                        // 5. Recent Rest Days
                        recentRestDaysSection
                            .padding(.horizontal, 20)
                    }
                }
                .padding(.top, 20)
                .padding(.bottom, 100)
            }
            .background(Color(hex: "#F5F5F7").ignoresSafeArea())
            .navigationTitle("Recovery")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingRestDayLog = true
                    } label: {
                        Label("Log Rest Day", systemImage: "plus.circle.fill")
                    }
                }
                
                ToolbarItem(placement: .secondaryAction) {
                    Button {
                        Task {
                            await refreshData()
                        }
                    } label: {
                        Label("Refresh", systemImage: "arrow.clockwise")
                    }
                }
            }
            .sheet(isPresented: $showingRestDayLog) {
                RestDayLoggingView()
            }
            .alert("HealthKit Authorization", isPresented: $showingHealthKitAuth) {
                Button("Open Settings") {
                    Task {
                        await healthKitService.requestAuthorization()
                    }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("GoChange needs access to your Health data to track sleep, heart rate, and HRV for better recovery insights.")
            }
        }
        .task {
            healthKitService.checkAuthorizationStatus()
            await loadData()
        }
    }
    
    // MARK: - Sections
    
    private func readinessSection(_ metrics: RecoveryMetrics) -> some View {
        VStack(spacing: 16) {
            ZStack {
                // Background Ring
                Circle()
                    .stroke(Color.gray.opacity(0.1), lineWidth: 20)
                    .frame(width: 200, height: 200)
                
                // Progress Ring
                Circle()
                    .trim(from: 0, to: metrics.overallRecoveryScore)
                    .stroke(
                        readinessColor(metrics.overallRecoveryScore),
                        style: StrokeStyle(lineWidth: 20, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .frame(width: 200, height: 200)
                
                // Content
                VStack(spacing: 4) {
                    Text("\(Int(metrics.overallRecoveryScore * 100))%")
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                    
                    Text(metrics.readinessToTrain.rawValue)
                        .font(.headline)
                        .fontWeight(.medium)
                        .foregroundColor(readinessColor(metrics.overallRecoveryScore))
                }
            }
            
            if let recommendation = recoveryService.recoveryRecommendation {
                Text(recommendation.message)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
        }
        .padding(24)
        .background(Color.white)
        .cornerRadius(32)
        .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 4)
    }
    
    private func keyMetricsGrid(_ metrics: RecoveryMetrics) -> some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
            metricCard(
                title: "Sleep",
                value: metrics.formattedSleepDuration,
                subValue: "Quality: \(Int((metrics.sleepQuality ?? 0) * 100))%",
                icon: "bed.double.fill",
                color: Color(hex: "#7B68EE")
            )
            
            metricCard(
                title: "HRV",
                value: metrics.heartRateVariability != nil ? "\(Int(metrics.heartRateVariability!)) ms" : "--",
                subValue: "Variability",
                icon: "waveform.path.ecg",
                color: Color(hex: "#FF6B6B")
            )
            
            metricCard(
                title: "RHR",
                value: metrics.restingHeartRate != nil ? "\(Int(metrics.restingHeartRate!)) bpm" : "--",
                subValue: "Resting HR",
                icon: "heart.fill",
                color: Color(hex: "#FF6B35")
            )
            
            metricCard(
                title: "Strain",
                value: "Coming Soon", // Placeholder until we link Strain here too
                subValue: "Daily Load",
                icon: "flame.fill",
                color: Color(hex: "#FFD700")
            )
        }
    }
    
    private var recoveryTrendsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Trends (Last 7 Days)")
                .font(.headline)
                .foregroundColor(.primary)
            
            Chart {
                ForEach(recoveryMetrics.prefix(7), id: \.date) { metric in
                    LineMark(
                        x: .value("Date", metric.date, unit: .day),
                        y: .value("Recovery", metric.overallRecoveryScore * 100)
                    )
                    .foregroundStyle(Color(hex: "#00D4AA"))
                    .interpolationMethod(.catmullRom)
                    
                    AreaMark(
                        x: .value("Date", metric.date, unit: .day),
                        y: .value("Recovery", metric.overallRecoveryScore * 100)
                    )
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color(hex: "#00D4AA").opacity(0.3), Color(hex: "#00D4AA").opacity(0.0)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .interpolationMethod(.catmullRom)
                }
            }
            .frame(height: 150)
            .chartXAxis {
                AxisMarks(values: .stride(by: .day)) { _ in
                    AxisValueLabel(format: .dateTime.weekday(.abbreviated))
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading)
            }
        }
        .padding(20)
        .background(Color.white)
        .cornerRadius(24)
        .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 4)
    }
    
    // MARK: - Helper Views
    
    private func metricCard(title: String, value: String, subValue: String, icon: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(value)
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
                
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
            }
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(20)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
    }
    
    private var healthKitPromptCard: some View {
        // ... (Keep existing implementation or simplify)
        VStack(spacing: 16) {
            Text("Enable HealthKit Integration")
                .font(.headline)
            Button("Connect") {
                Task { await healthKitService.requestAuthorization() }
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(16)
    }
    
    private func muscleRecoveryCard(_ metrics: RecoveryMetrics) -> some View {
        // Reuse existing logic or simplify
        VStack(alignment: .leading, spacing: 12) {
            Text("Muscle Recovery")
                .font(.headline)
            
            if metrics.muscleRecovery.isEmpty {
                Text("No data")
                    .font(.caption)
                    .foregroundColor(.secondary)
            } else {
                ForEach(metrics.muscleRecovery.prefix(3), id: \.muscleGroup) { recovery in
                    HStack {
                        Text(recovery.muscleGroup)
                        Spacer()
                        Circle()
                            .fill(sorenessColor(recovery.sorenessLevel))
                            .frame(width: 8, height: 8)
                    }
                    .font(.subheadline)
                }
            }
        }
        .padding(20)
        .background(Color.white)
        .cornerRadius(24)
        .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 4)
    }
    
    private var recentRestDaysSection: some View {
        // Reuse existing logic
        VStack(alignment: .leading, spacing: 12) {
            Text("Recent Rest Days")
                .font(.headline)
            
            ForEach(restDays.prefix(3)) { day in
                HStack {
                    Text(day.date.formatted(date: .abbreviated, time: .omitted))
                    Spacer()
                    Text(day.type.rawValue.capitalized)
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(Color.white)
                .cornerRadius(16)
            }
        }
    }
    
    // MARK: - Helpers
    
    private func readinessColor(_ score: Double) -> Color {
        if score >= 0.8 { return Color(hex: "#00D4AA") }
        if score >= 0.5 { return Color(hex: "#FFD54F") }
        return Color(hex: "#FF6B6B")
    }
    
    private func sorenessColor(_ level: Int) -> Color {
        switch level {
        case 1...2: return Color(hex: "#00D4AA")
        case 3: return Color(hex: "#FFD54F")
        case 4...5: return Color(hex: "#FF6B6B")
        default: return .gray
        }
    }
    
    private func loadData() async {
        await recoveryService.syncRecoveryData(context: modelContext)
        await recoveryService.updateMuscleRecovery(context: modelContext)
        isLoading = false
    }
    
    private func refreshData() async {
        await loadData()
    }
}

#Preview {
    RecoveryDashboardView()
        .modelContainer(for: [RestDay.self, RecoveryMetrics.self, WorkoutSession.self])
}
