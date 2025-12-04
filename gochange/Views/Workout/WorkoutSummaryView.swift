import SwiftUI

// MARK: - Workout Summary Data
struct WorkoutSummaryData {
    let workoutName: String
    let date: Date
    let duration: TimeInterval
    let rpe: Double?
    let exercises: [ExerciseSummary]
    let previousSession: PreviousSessionData?

    struct ExerciseSummary: Identifiable {
        let id = UUID()
        let name: String
        let muscleGroup: String
        let completedSets: Int
        let totalSets: Int
        let totalVolume: Double
        let topWeight: Double?
        let topReps: Int?
        let isPR: Bool
    }

    struct PreviousSessionData {
        let duration: TimeInterval
        let totalVolume: Double
        let totalSets: Int
    }

    var totalVolume: Double {
        exercises.reduce(0) { $0 + $1.totalVolume }
    }

    var completedSets: Int {
        exercises.reduce(0) { $0 + $1.completedSets }
    }

    var totalSets: Int {
        exercises.reduce(0) { $0 + $1.totalSets }
    }

    var prCount: Int {
        exercises.filter { $0.isPR }.count
    }

    var volumeChange: Double? {
        guard let prev = previousSession, prev.totalVolume > 0 else { return nil }
        return ((totalVolume - prev.totalVolume) / prev.totalVolume) * 100
    }

    var durationChange: Double? {
        guard let prev = previousSession, prev.duration > 0 else { return nil }
        return duration - prev.duration
    }
}

// MARK: - Workout Summary View
struct WorkoutSummaryView: View {
    let summary: WorkoutSummaryData
    let accentColor: Color
    let onDismiss: () -> Void

    @State private var showContent = false
    @State private var showConfetti = false
    @State private var showStats = false
    @State private var showExercises = false

    var body: some View {
        ZStack {
            // Background
            AppColors.background
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 24) {
                    // Celebration Header
                    celebrationHeader
                        .opacity(showContent ? 1 : 0)
                        .offset(y: showContent ? 0 : 20)

                    // Key Stats
                    keyStatsSection
                        .opacity(showStats ? 1 : 0)
                        .offset(y: showStats ? 0 : 20)

                    // PR Banner (if any)
                    if summary.prCount > 0 {
                        prBanner
                            .opacity(showStats ? 1 : 0)
                            .scaleEffect(showStats ? 1 : 0.8)
                    }

                    // Exercise Breakdown
                    exerciseBreakdownSection
                        .opacity(showExercises ? 1 : 0)
                        .offset(y: showExercises ? 0 : 20)

                    // Done Button
                    doneButton
                        .opacity(showExercises ? 1 : 0)
                        .padding(.top, 8)
                }
                .padding(.horizontal, 20)
                .padding(.top, 40)
                .padding(.bottom, 40)
            }

            // Confetti overlay
            if showConfetti {
                ConfettiView()
                    .ignoresSafeArea()
                    .allowsHitTesting(false)
            }
        }
        .onAppear {
            animateIn()
        }
    }

    // MARK: - Celebration Header

    private var celebrationHeader: some View {
        VStack(spacing: 16) {
            // Animated checkmark
            ZStack {
                Circle()
                    .fill(AppColors.success.opacity(0.15))
                    .frame(width: 100, height: 100)

                Circle()
                    .fill(AppColors.success)
                    .frame(width: 80, height: 80)
                    .shadow(color: AppColors.success.opacity(0.4), radius: 15, x: 0, y: 5)

                Image(systemName: "checkmark")
                    .font(.system(size: 36, weight: .bold))
                    .foregroundColor(.white)
            }
            .scaleEffect(showContent ? 1 : 0.5)
            .animation(.spring(response: 0.5, dampingFraction: 0.6), value: showContent)

            VStack(spacing: 8) {
                Text("Workout Complete!")
                    .font(AppFonts.title(28))
                    .foregroundColor(AppColors.textPrimary)

                Text(summary.workoutName)
                    .font(AppFonts.rounded(18, weight: .semibold))
                    .foregroundColor(accentColor)

                Text(summary.date.formatted(date: .abbreviated, time: .shortened))
                    .font(AppFonts.label(12))
                    .foregroundColor(AppColors.textTertiary)
            }
        }
    }

    // MARK: - Key Stats Section

    private var keyStatsSection: some View {
        HStack(spacing: 12) {
            // Duration
            SummaryStatCard(
                icon: "clock.fill",
                iconColor: AppColors.primary,
                title: "DURATION",
                value: formatDuration(summary.duration),
                change: summary.durationChange.map { formatDurationChange($0) },
                isPositiveChange: summary.durationChange.map { $0 <= 0 } // Less time is better
            )

            // Volume
            SummaryStatCard(
                icon: "flame.fill",
                iconColor: AppColors.warning,
                title: "VOLUME",
                value: formatVolume(summary.totalVolume),
                change: summary.volumeChange.map { String(format: "%+.0f%%", $0) },
                isPositiveChange: summary.volumeChange.map { $0 >= 0 }
            )

            // Sets
            SummaryStatCard(
                icon: "checkmark.circle.fill",
                iconColor: summary.completedSets == summary.totalSets ? AppColors.success : accentColor,
                title: "SETS",
                value: "\(summary.completedSets)/\(summary.totalSets)",
                change: nil,
                isPositiveChange: nil
            )
        }
    }

    // MARK: - PR Banner

    private var prBanner: some View {
        HStack(spacing: 12) {
            Image(systemName: "trophy.fill")
                .font(.system(size: 24))
                .foregroundColor(Color(hex: "#FFD700"))

            VStack(alignment: .leading, spacing: 2) {
                Text("\(summary.prCount) Personal Record\(summary.prCount > 1 ? "s" : "")!")
                    .font(AppFonts.rounded(16, weight: .bold))
                    .foregroundColor(AppColors.textPrimary)

                Text("You crushed it today!")
                    .font(AppFonts.label(12))
                    .foregroundColor(AppColors.textSecondary)
            }

            Spacer()
        }
        .padding(16)
        .background(
            LinearGradient(
                colors: [Color(hex: "#FFD700").opacity(0.15), Color(hex: "#FFA500").opacity(0.1)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: AppLayout.miniRadius))
        .overlay(
            RoundedRectangle(cornerRadius: AppLayout.miniRadius)
                .stroke(Color(hex: "#FFD700").opacity(0.3), lineWidth: 1)
        )
    }

    // MARK: - Exercise Breakdown

    private var exerciseBreakdownSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("EXERCISE BREAKDOWN")
                .font(AppFonts.label(11))
                .tracking(1.5)
                .foregroundColor(AppColors.textTertiary)
                .padding(.horizontal, 4)

            VStack(spacing: 0) {
                ForEach(Array(summary.exercises.enumerated()), id: \.element.id) { index, exercise in
                    ExerciseSummaryRow(exercise: exercise, accentColor: accentColor)

                    if index < summary.exercises.count - 1 {
                        Divider()
                            .padding(.horizontal, 16)
                    }
                }
            }
            .background(AppColors.surface)
            .clipShape(RoundedRectangle(cornerRadius: AppLayout.cornerRadius))
            .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 4)
            .overlay(
                RoundedRectangle(cornerRadius: AppLayout.cornerRadius)
                    .stroke(Color.gray.opacity(0.1), lineWidth: 1)
            )
        }
    }

    // MARK: - Done Button

    private var doneButton: some View {
        Button(action: onDismiss) {
            Text("Done")
                .font(AppFonts.rounded(17, weight: .bold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(accentColor)
                .clipShape(Capsule())
                .shadow(color: accentColor.opacity(0.4), radius: 12, x: 0, y: 6)
        }
    }

    // MARK: - Helpers

    private func animateIn() {
        withAnimation(.easeOut(duration: 0.5)) {
            showContent = true
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            showConfetti = true
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            withAnimation(.easeOut(duration: 0.5)) {
                showStats = true
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            withAnimation(.easeOut(duration: 0.5)) {
                showExercises = true
            }
        }

        // Hide confetti after a few seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            withAnimation {
                showConfetti = false
            }
        }
    }

    private func formatDuration(_ duration: TimeInterval) -> String {
        let hours = Int(duration) / 3600
        let minutes = (Int(duration) % 3600) / 60
        let seconds = Int(duration) % 60

        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        }
        return String(format: "%d:%02d", minutes, seconds)
    }

    private func formatDurationChange(_ change: Double) -> String {
        let absChange = abs(change)
        let minutes = Int(absChange) / 60
        let seconds = Int(absChange) % 60
        let sign = change >= 0 ? "+" : "-"

        if minutes > 0 {
            return "\(sign)\(minutes)m \(seconds)s"
        }
        return "\(sign)\(seconds)s"
    }

    private func formatVolume(_ volume: Double) -> String {
        if volume >= 1000 {
            return String(format: "%.1fk", volume / 1000)
        }
        return "\(Int(volume))"
    }
}

// MARK: - Summary Stat Card

struct SummaryStatCard: View {
    let icon: String
    let iconColor: Color
    let title: String
    let value: String
    let change: String?
    let isPositiveChange: Bool?

    var body: some View {
        VStack(spacing: 10) {
            // Icon
            Image(systemName: icon)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(iconColor)

            // Title
            Text(title)
                .font(AppFonts.label(9))
                .tracking(1)
                .foregroundColor(AppColors.textTertiary)

            // Value
            Text(value)
                .font(AppFonts.rounded(22, weight: .bold))
                .foregroundColor(AppColors.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)

            // Change indicator
            if let change = change, let isPositive = isPositiveChange {
                Text(change)
                    .font(AppFonts.label(10))
                    .foregroundColor(isPositive ? AppColors.success : AppColors.error)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background((isPositive ? AppColors.success : AppColors.error).opacity(0.1))
                    .clipShape(Capsule())
            } else {
                Spacer()
                    .frame(height: 22)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .padding(.horizontal, 8)
        .background(AppColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: AppLayout.miniRadius))
        .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 2)
        .overlay(
            RoundedRectangle(cornerRadius: AppLayout.miniRadius)
                .stroke(Color.gray.opacity(0.08), lineWidth: 1)
        )
    }
}

// MARK: - Exercise Summary Row

struct ExerciseSummaryRow: View {
    let exercise: WorkoutSummaryData.ExerciseSummary
    let accentColor: Color

    var body: some View {
        HStack(spacing: 12) {
            // Exercise info
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Text(exercise.name)
                        .font(AppFonts.rounded(15, weight: .semibold))
                        .foregroundColor(AppColors.textPrimary)

                    if exercise.isPR {
                        Text("PR")
                            .font(AppFonts.label(9))
                            .foregroundColor(Color(hex: "#FFD700"))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color(hex: "#FFD700").opacity(0.15))
                            .clipShape(Capsule())
                    }
                }

                Text(exercise.muscleGroup)
                    .font(AppFonts.label(11))
                    .foregroundColor(AppColors.textTertiary)
            }

            Spacer()

            // Stats
            HStack(spacing: 16) {
                // Sets
                VStack(spacing: 2) {
                    Text("\(exercise.completedSets)/\(exercise.totalSets)")
                        .font(AppFonts.rounded(14, weight: .semibold))
                        .foregroundColor(exercise.completedSets == exercise.totalSets ? AppColors.success : AppColors.textSecondary)
                    Text("sets")
                        .font(AppFonts.label(9))
                        .foregroundColor(AppColors.textTertiary)
                }

                // Best set
                if let weight = exercise.topWeight, let reps = exercise.topReps {
                    VStack(spacing: 2) {
                        Text("\(Int(weight))×\(reps)")
                            .font(AppFonts.rounded(14, weight: .semibold))
                            .foregroundColor(accentColor)
                        Text("best")
                            .font(AppFonts.label(9))
                            .foregroundColor(AppColors.textTertiary)
                    }
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }
}

// MARK: - Confetti View

struct ConfettiView: View {
    @State private var particles: [ConfettiParticle] = []

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(particles) { particle in
                    Circle()
                        .fill(particle.color)
                        .frame(width: particle.size, height: particle.size)
                        .position(particle.position)
                        .opacity(particle.opacity)
                }
            }
            .onAppear {
                createParticles(in: geometry.size)
                animateParticles(in: geometry.size)
            }
        }
    }

    private func createParticles(in size: CGSize) {
        let colors: [Color] = [
            AppColors.success,
            AppColors.primary,
            AppColors.warning,
            Color(hex: "#FFD700"),
            Color(hex: "#FF6B6B"),
            Color(hex: "#4ECDC4")
        ]

        particles = (0..<50).map { _ in
            ConfettiParticle(
                position: CGPoint(x: CGFloat.random(in: 0...size.width), y: -20),
                color: colors.randomElement() ?? AppColors.success,
                size: CGFloat.random(in: 6...12),
                opacity: 1.0
            )
        }
    }

    private func animateParticles(in size: CGSize) {
        for i in particles.indices {
            let delay = Double.random(in: 0...0.5)
            let duration = Double.random(in: 2...4)

            withAnimation(.easeIn(duration: duration).delay(delay)) {
                particles[i].position.y = size.height + 50
                particles[i].position.x += CGFloat.random(in: -100...100)
                particles[i].opacity = 0
            }
        }
    }
}

struct ConfettiParticle: Identifiable {
    let id = UUID()
    var position: CGPoint
    let color: Color
    let size: CGFloat
    var opacity: Double
}

#Preview {
    WorkoutSummaryView(
        summary: WorkoutSummaryData(
            workoutName: "Push Day",
            date: Date(),
            duration: 2732,
            rpe: 7.5,
            exercises: [
                .init(name: "Bench Press", muscleGroup: "Chest", completedSets: 4, totalSets: 4, totalVolume: 3200, topWeight: 185, topReps: 8, isPR: true),
                .init(name: "Incline Dumbbell Press", muscleGroup: "Chest", completedSets: 3, totalSets: 3, totalVolume: 2100, topWeight: 70, topReps: 10, isPR: false),
                .init(name: "Shoulder Press", muscleGroup: "Shoulders", completedSets: 3, totalSets: 3, totalVolume: 1800, topWeight: 50, topReps: 12, isPR: false)
            ],
            previousSession: .init(duration: 2500, totalVolume: 6800, totalSets: 10)
        ),
        accentColor: AppColors.primary,
        onDismiss: {}
    )
}
