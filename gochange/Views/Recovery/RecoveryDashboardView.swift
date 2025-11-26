import SwiftUI
import SwiftData

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

    var todaysRestDay: RestDay? {
        let today = Calendar.current.startOfDay(for: Date())
        return restDays.first { Calendar.current.isDate($0.date, inSameDayAs: today) }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    if isLoading {
                        ProgressView("Loading recovery data...")
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity, minHeight: 200)
                    } else {
                        // Only show prompt if:
                        // 1. Not authorized (workout write not granted), OR
                        // 2. Read permissions are explicitly denied
                        // Note: .notDetermined for read permissions is normal and means "granted"
                        if !healthKitService.isAuthorized || healthKitService.hasDeniedReadPermissions {
                            healthKitPromptCard
                        }

                        if let metrics = todaysMetrics {
                            // Only show recommendation if we have real data
                            if metrics.hasRealData, let recommendation = recoveryService.recoveryRecommendation {
                            readinessCard(recommendation)
                        }

                            // Only show recovery score if we have real data
                            if metrics.hasRealData {
                            recoveryScoreCard(metrics)
                            }
                            
                            sleepCard(metrics)
                            muscleRecoveryCard(metrics)
                            vitalSignsCard(metrics)
                        }

                        if let restDay = todaysRestDay {
                            restDayCard(restDay)
                        }

                        recentRestDaysSection
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 100)
            }
            .background(
                LinearGradient(
                    colors: [Color.black, Color(hex: "#0A1628")],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
            )
            .toolbar(.hidden, for: .navigationBar)
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
            // Refresh authorization status when view appears
            healthKitService.checkAuthorizationStatus()
            await loadData()
        }
        .onAppear {
            // Also check when view appears (in case permissions changed)
            healthKitService.checkAuthorizationStatus()
        }
    }

    private var healthKitPromptCard: some View {
        VStack(spacing: 16) {
            Image(systemName: "heart.text.square.fill")
                .font(.system(size: 48))
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color(hex: "#FF6B6B"), Color(hex: "#FF8E8E")],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            VStack(spacing: 8) {
                Text(healthKitService.hasDeniedReadPermissions ? "HealthKit Permissions Denied" : "Enable HealthKit Integration")
                    .font(.headline)
                    .foregroundColor(.white)

                Text(healthKitService.hasDeniedReadPermissions ? 
                     "Read permissions for sleep, heart rate, and HRV were denied. Please enable them in Settings > Health > Data Access & Devices > GoChange." :
                     "Track sleep, heart rate, and HRV for personalized recovery insights")
                    .font(.subheadline)
                    .foregroundStyle(.gray)
                    .multilineTextAlignment(.center)
            }

            if healthKitService.hasDeniedReadPermissions {
                Button {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                } label: {
                    Text("Open Settings")
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color(hex: "#FF6B6B"))
                        .cornerRadius(12)
                }
            } else {
            Button {
                Task {
                    let success = await healthKitService.requestAuthorization()
                    if success {
                        // Wait a bit for permissions to settle, then refresh
                        try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
                        await refreshData()
                    }
                }
            } label: {
                Text("Connect HealthKit")
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color(hex: "#FF6B6B"))
                    .cornerRadius(12)
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
        )
    }

    private func readinessCard(_ recommendation: RecoveryRecommendation) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Training Readiness")
                        .font(.headline)
                        .foregroundColor(.white)
                    Text(recommendation.readiness.rawValue)
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundStyle(Color(hex: recommendation.readiness.color))
                }

                Spacer()

                CircularProgressView(
                    progress: recommendation.score,
                    color: Color(hex: recommendation.readiness.color)
                )
                .frame(width: 80, height: 80)
            }

            Text(recommendation.message)
                .font(.subheadline)
                .foregroundStyle(.gray)

            if !recommendation.suggestedActivities.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Suggested Activities")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)

                    ForEach(recommendation.suggestedActivities, id: \.self) { activity in
                        HStack(spacing: 8) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(Color(hex: "#00D4AA"))
                                .font(.caption)
                            Text(activity)
                                .font(.caption)
                                .foregroundColor(.white)
                        }
                    }
                }
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.white.opacity(0.03))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.white.opacity(0.05), lineWidth: 1)
                        )
                )
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
        )
    }

    private func recoveryScoreCard(_ metrics: RecoveryMetrics) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recovery Score")
                .font(.headline)
                .foregroundColor(.white)

            HStack(spacing: 16) {
                CircularProgressView(
                    progress: metrics.overallRecoveryScore,
                    color: Color(hex: metrics.readinessToTrain.color)
                )
                .frame(width: 60, height: 60)

                VStack(alignment: .leading, spacing: 4) {
                    Text("\(Int(metrics.overallRecoveryScore * 100))%")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    Text("Overall Recovery")
                        .font(.caption)
                        .foregroundStyle(.gray)
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
        )
    }

    private func sleepCard(_ metrics: RecoveryMetrics) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "bed.double.fill")
                    .foregroundStyle(Color(hex: "#7B68EE"))
                Text("Sleep")
                    .font(.headline)
                    .foregroundColor(.white)
            }

            if metrics.sleepDuration != nil {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(metrics.formattedSleepDuration)
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        Text("Total Sleep")
                            .font(.caption)
                            .foregroundStyle(.gray)
                    }

                    Spacer()

                    if let quality = metrics.sleepQuality {
                        VStack(alignment: .trailing, spacing: 4) {
                            Text("\(Int(quality * 100))%")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundStyle(sleepQualityColor(quality))
                            Text("Quality")
                                .font(.caption)
                                .foregroundStyle(.gray)
                        }
                    }
                }

                if metrics.deepSleepDuration ?? 0 > 0 || metrics.remSleepDuration ?? 0 > 0 {
                    Divider()
                        .background(Color.white.opacity(0.1))

                    HStack {
                        if metrics.deepSleepDuration != nil {
                            sleepStageView("Deep", duration: metrics.formattedDeepSleep, color: Color(hex: "#7B68EE"))
                        }

                        if metrics.remSleepDuration != nil {
                            if metrics.deepSleepDuration != nil {
                                Divider()
                                    .background(Color.white.opacity(0.1))
                            }
                            sleepStageView("REM", duration: metrics.formattedREMSleep, color: Color(hex: "#BA68C8"))
                        }
                    }
                }
            } else {
                Text("No sleep data available")
                    .font(.subheadline)
                    .foregroundStyle(.gray)

                Button("Sync from HealthKit") {
                    Task {
                        // Request authorization if not already granted
                        if !healthKitService.isAuthorized {
                            await healthKitService.requestAuthorization()
                            try? await Task.sleep(nanoseconds: 500_000_000)
                        }
                        await recoveryService.syncRecoveryData(context: modelContext)
                    }
                }
                .foregroundColor(Color(hex: "#00D4AA"))
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
        )
    }

    private func muscleRecoveryCard(_ metrics: RecoveryMetrics) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "figure.strengthtraining.traditional")
                    .foregroundStyle(Color(hex: "#FF6B35"))
                Text("Muscle Recovery")
                    .font(.headline)
                    .foregroundColor(.white)
            }

            if metrics.muscleRecovery.isEmpty {
                Text("No muscle recovery data")
                    .font(.subheadline)
                    .foregroundStyle(.gray)
            } else {
                ForEach(metrics.muscleRecovery, id: \.muscleGroup) { recovery in
                    muscleRecoveryRow(recovery)
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
        )
    }

    private func muscleRecoveryRow(_ recovery: MuscleGroupRecovery) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(recovery.muscleGroup)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.white)

                if let lastWorked = recovery.lastWorked {
                    Text("Last worked: \(lastWorked.formatted(.relative(presentation: .named)))")
                        .font(.caption)
                        .foregroundStyle(.gray)
                }
            }

            Spacer()

            HStack(spacing: 4) {
                ForEach(1...5, id: \.self) { level in
                    Circle()
                        .fill(level <= recovery.sorenessLevel ? sorenessColor(recovery.sorenessLevel) : Color.gray.opacity(0.2))
                        .frame(width: 8, height: 8)
                }
            }
        }
    }

    private func vitalSignsCard(_ metrics: RecoveryMetrics) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "waveform.path.ecg")
                    .foregroundStyle(Color(hex: "#FF6B6B"))
                Text("Vital Signs")
                    .font(.headline)
                    .foregroundColor(.white)
            }

            HStack(spacing: 16) {
                if let rhr = metrics.restingHeartRate {
                    VStack(spacing: 4) {
                        Text("\(Int(rhr))")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        Text("Resting HR")
                            .font(.caption)
                            .foregroundStyle(.gray)
                    }
                    .frame(maxWidth: .infinity)
                }

                if let hrv = metrics.heartRateVariability {
                    VStack(spacing: 4) {
                        Text("\(Int(hrv))")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        Text("HRV (ms)")
                            .font(.caption)
                            .foregroundStyle(.gray)
                    }
                    .frame(maxWidth: .infinity)
                }

                // Only show fatigue if it's user-reported
                if let fatigue = metrics.overallFatigue {
                VStack(spacing: 4) {
                        Text("\(fatigue)")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    Text("Fatigue")
                        .font(.caption)
                        .foregroundStyle(.gray)
                }
                .frame(maxWidth: .infinity)
                }
            }

            if metrics.restingHeartRate == nil && metrics.heartRateVariability == nil {
                Text("Sync HealthKit to see vital signs")
                    .font(.caption)
                    .foregroundStyle(.gray)
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
        )
    }

    private func restDayCard(_ restDay: RestDay) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "figure.mind.and.body")
                    .foregroundStyle(Color(hex: "#00D4AA"))
                Text("Today's Rest Day")
                    .font(.headline)
                    .foregroundColor(.white)

                Spacer()

                if let status = restDay.recoveryStatus {
                    Text(status.emoji)
                    .font(.title2)
                }
            }

            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(restDay.type.rawValue.capitalized)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                    Text("Type")
                        .font(.caption)
                        .foregroundStyle(.gray)
                }

                Spacer()

                if let score = restDay.recoveryScore, let status = restDay.recoveryStatus {
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("\(Int(score * 100))%")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundStyle(Color(hex: status.color))
                        Text("Recovery")
                            .font(.caption)
                            .foregroundStyle(.gray)
                    }
                } else {
                VStack(alignment: .trailing, spacing: 4) {
                        Text("No data")
                        .font(.subheadline)
                        .fontWeight(.medium)
                            .foregroundStyle(.gray)
                    Text("Recovery")
                        .font(.caption)
                        .foregroundStyle(.gray)
                    }
                }
            }

            if let notes = restDay.notes, !notes.isEmpty {
                Divider()
                    .background(Color.white.opacity(0.1))
                Text(notes)
                    .font(.caption)
                    .foregroundStyle(.gray)
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
        )
    }

    private var recentRestDaysSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recent Rest Days")
                .font(.headline)
                .foregroundColor(.white)

            if restDays.isEmpty {
                Text("No rest days logged yet")
                    .font(.subheadline)
                    .foregroundStyle(.gray)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(20)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color.white.opacity(0.05))
                            .overlay(
                                RoundedRectangle(cornerRadius: 20)
                                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
                            )
                    )
            } else {
                ForEach(restDays.prefix(5)) { restDay in
                    recentRestDayRow(restDay)
                }
            }
        }
    }

    private func recentRestDayRow(_ restDay: RestDay) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(restDay.date.formatted(date: .abbreviated, time: .omitted))
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                Text(restDay.type.rawValue.capitalized)
                    .font(.caption)
                    .foregroundStyle(.gray)
            }

            Spacer()

            HStack(spacing: 8) {
                if restDay.sleepDuration != nil {
                    Label(restDay.formattedSleepDuration, systemImage: "bed.double.fill")
                        .font(.caption)
                        .foregroundStyle(.gray)
                }

                if let status = restDay.recoveryStatus {
                    Text(status.emoji)
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.03))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(0.05), lineWidth: 1)
                )
        )
    }

    private func sleepStageView(_ label: String, duration: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Text(duration)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(color)
            Text(label)
                .font(.caption)
                .foregroundStyle(.gray)
        }
        .frame(maxWidth: .infinity)
    }

    private func sleepQualityColor(_ quality: Double) -> Color {
        if quality >= 0.8 {
            return Color(hex: "#00D4AA")
        } else if quality >= 0.6 {
            return Color(hex: "#64B5F6")
        } else if quality >= 0.4 {
            return Color(hex: "#FFD54F")
        } else {
            return Color(hex: "#FF6B6B")
        }
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
        await recoveryService.syncRecoveryData(context: modelContext)
        await recoveryService.updateMuscleRecovery(context: modelContext)
    }
}

struct CircularProgressView: View {
    let progress: Double
    let color: Color
    let lineWidth: CGFloat = 8

    var body: some View {
        ZStack {
            Circle()
                .stroke(color.opacity(0.2), lineWidth: lineWidth)

            Circle()
                .trim(from: 0, to: progress)
                .stroke(color, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut, value: progress)

            Text("\(Int(progress * 100))%")
                .font(.caption)
                .fontWeight(.bold)
        }
    }
}

#Preview {
    RecoveryDashboardView()
        .modelContainer(for: [RestDay.self, RecoveryMetrics.self, WorkoutSession.self])
}
