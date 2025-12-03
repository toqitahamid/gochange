import SwiftUI
import SwiftData

struct SessionDetailView: View {
    @Bindable var session: WorkoutSession
    
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var showingDeleteAlert = false
    @State private var showingTimeEdit = false
    @State private var editStartTime: Date = Date()
    @State private var editEndTime: Date = Date()
    @State private var isEditMode = false
    
    private var accentColor: Color {
        AppConstants.WorkoutColors.color(for: session.workoutDayName)
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Header Card
                headerCard
                
                // Health / Strain Summary
                SessionHealthSummaryCard(
                    session: session,
                    strain: sessionStrainScore,
                    totalCalories: estimatedCalories,
                    avgHeartRate: nil,
                    cardioLoadDelta: nil,
                    cardioLoadLabel: sessionStrainCategoryLabel
                )
                
                // Stats Cards
                statsRow
                
                // Exercise Logs
                exerciseSection
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 100)
        }
        .background(AppColors.background.ignoresSafeArea())
        .preferredColorScheme(.light)
        .navigationTitle(session.workoutDayName)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                HStack(spacing: 16) {
                    Button {
                        if isEditMode {
                            // Save changes when exiting edit mode
                            try? modelContext.save()
                        }
                        withAnimation(.easeInOut(duration: 0.2)) {
                            isEditMode.toggle()
                        }
                    } label: {
                        Text(isEditMode ? "Done" : "Edit")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(AppColors.primary)
                    }
                    
                    if !isEditMode {
                        Button {
                            showingDeleteAlert = true
                        } label: {
                            Image(systemName: "trash")
                                .foregroundColor(Color(hex: "#FF6B6B"))
                        }
                    }
                }
            }
        }
        .alert("Delete Workout?", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                deleteSession()
            }
        } message: {
            Text("This will permanently delete this workout session and all its data. This action cannot be undone.")
        }
        .sheet(isPresented: $showingTimeEdit) {
            TimeEditSheet(
                startTime: $editStartTime,
                endTime: $editEndTime,
                onSave: {
                    saveTimeChanges()
                }
            )
            .presentationDetents([.medium])
            .presentationDragIndicator(.visible)
        }
    }
    
    private func deleteSession() {
        modelContext.delete(session)
        try? modelContext.save()
        dismiss()
    }
    
    private func saveTimeChanges() {
        session.startTime = editStartTime
        session.endTime = editEndTime
        session.duration = editEndTime.timeIntervalSince(editStartTime)
        // Also update the date to match start time's date
        session.date = Calendar.current.startOfDay(for: editStartTime)
        try? modelContext.save()
    }
    
    // MARK: - Header Card
    private var headerCard: some View {
        VStack(spacing: 20) {
            // Workout Icon
            ZStack {
                RoundedRectangle(cornerRadius: 20)
                    .fill(
                        LinearGradient(
                            colors: [accentColor, accentColor.opacity(0.7)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 80, height: 80)
                
                Image(systemName: routineIcon)
                    .font(.system(size: 32))
                    .foregroundColor(.white)
            }
            .shadow(color: accentColor.opacity(0.4), radius: 16, y: 8)
            
            VStack(spacing: 6) {
                Text(session.workoutDayName)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Text(session.date.formatted(as: "EEEE, MMMM d, yyyy"))
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                // Tappable time display
                Button {
                    editStartTime = session.startTime
                    editEndTime = session.endTime ?? session.startTime
                    showingTimeEdit = true
                } label: {
                    HStack(spacing: 6) {
                        Text(session.startTime.formatted(as: "h:mm a"))
                        if let endTime = session.endTime {
                            Text("-")
                            Text(endTime.formatted(as: "h:mm a"))
                        }
                        Image(systemName: "pencil")
                            .font(.system(size: 10))
                    }
                    .font(.caption)
                            .foregroundColor(AppColors.primary)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 28)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 4)
                .overlay(
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(Color.gray.opacity(0.1), lineWidth: 1)
                )
        )
    }
    
    // MARK: - Stats Row
    private var statsRow: some View {
        HStack(spacing: 10) {
                SessionStatCard(
                    title: "Duration",
                    value: session.duration?.formattedDuration ?? "--",
                    icon: "timer",
                    color: AppColors.primary
                )
            
                SessionStatCard(
                    title: "Exercises",
                    value: "\(session.exerciseLogs.count)",
                    icon: "dumbbell.fill",
                    color: AppColors.success
                )
            
                SessionStatCard(
                    title: "Sets",
                    value: "\(totalSets)",
                    icon: "checkmark.circle.fill",
                    color: AppColors.success
                )
            
                SessionStatCard(
                    title: "Volume",
                    value: formatVolume(totalVolume),
                    icon: "scalemass.fill",
                    color: AppColors.warning
                )
        }
    }
    
    // MARK: - Exercise Section
    private var exerciseSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("EXERCISES")
                    .font(.system(size: 12, weight: .bold))
                    .tracking(1.5)
                    .foregroundColor(.gray)
                    .padding(.horizontal, 4)
                
                Spacer()
                
                if isEditMode {
                    Text("Tap values to edit")
                        .font(.system(size: 11))
                        .foregroundColor(AppColors.primary)
                }
            }
            
            VStack(spacing: 12) {
                ForEach(session.exerciseLogs.sorted { $0.order < $1.order }) { exerciseLog in
                    EditableSessionExerciseCard(
                        exerciseLog: exerciseLog,
                        isEditMode: isEditMode,
                        onSave: { try? modelContext.save() }
                    )
                }
            }
        }
    }
    
    // MARK: - Computed Properties
    private var totalSets: Int {
        session.exerciseLogs.reduce(0) { $0 + $1.sets.filter { $0.isCompleted }.count }
    }
    
    private var totalVolume: Double {
        session.exerciseLogs.reduce(0) { total, log in
            total + log.sets.reduce(0) { setTotal, set in
                if set.isCompleted, let weight = set.weight, let reps = set.actualReps {
                    return setTotal + (weight * Double(reps))
                }
                return setTotal
            }
        }
    }
    
    private var sessionDuration: TimeInterval {
        if let duration = session.duration {
            return duration
        } else if let endTime = session.endTime {
            return endTime.timeIntervalSince(session.startTime)
        } else {
            return 0
        }
    }
    
    private var sessionStrainScore: Int {
        // Mirror the simple strain logic from DashboardViewModel but scoped to this session
        let durationScore = min(sessionDuration / 3600.0 * 50.0, 50.0)
        let volumeScore = min(totalVolume / 10000.0 * 50.0, 50.0)
        return Int(durationScore + volumeScore)
    }
    
    private var estimatedCalories: Double? {
        guard sessionDuration > 0 else { return nil }
        // Simple heuristic: ~5 active calories per minute, matching DashboardViewModel
        return (sessionDuration / 60.0) * 5.0
    }
    
    private var sessionStrainCategoryLabel: String? {
        switch sessionStrainScore {
        case 80...:
            return "Overtraining"
        case 60..<80:
            return "High Load"
        case 40..<60:
            return "Maintaining"
        case 1..<40:
            return "Light"
        default:
            return nil
        }
    }
    
    private func formatVolume(_ volume: Double) -> String {
        if volume >= 1000 {
            return String(format: "%.1fk", volume / 1000)
        }
        return String(format: "%.0f", volume)
    }
    
    private var routineIcon: String {
        let name = session.workoutDayName.lowercased()
        if name.contains("push") { return "figure.strengthtraining.traditional" }
        if name.contains("pull") { return "figure.rower" }
        if name.contains("leg") { return "figure.walk" }
        if name.contains("full") { return "figure.cross.training" }
        if name.contains("cardio") || name.contains("run") { return "figure.run" }
        return "dumbbell.fill"
    }
}

// MARK: - Time Edit Sheet
struct TimeEditSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var startTime: Date
    @Binding var endTime: Date
    let onSave: () -> Void
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                VStack(alignment: .leading, spacing: 16) {
                    Text("EDIT WORKOUT TIME")
                        .font(.system(size: 12, weight: .bold))
                        .tracking(1.5)
                        .foregroundColor(.secondary)
                    
                    VStack(spacing: 16) {
                        // Start Time
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Start Time")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            DatePicker("", selection: $startTime)
                                .datePickerStyle(.compact)
                                .labelsHidden()
                        }
                        
                        // End Time
                        VStack(alignment: .leading, spacing: 8) {
                            Text("End Time")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            DatePicker("", selection: $endTime, in: startTime...)
                                .datePickerStyle(.compact)
                                .labelsHidden()
                        }
                        
                        // Duration Preview
                        HStack {
                            Text("Duration")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            Spacer()
                            Text(calculatedDuration.formattedDuration)
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(AppColors.primary)
                        }
                        .padding(.top, 8)
                    }
                    .padding(20)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.white)
                            .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(Color.gray.opacity(0.1), lineWidth: 1)
                            )
                    )
                }
                .padding(.horizontal, 20)
                
                Spacer()
            }
            .padding(.top, 20)
            .background(AppColors.background.ignoresSafeArea())
            .background(AppColors.background.ignoresSafeArea())
            .navigationTitle("Edit Time")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        onSave()
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }
    
    private var calculatedDuration: TimeInterval {
        endTime.timeIntervalSince(startTime)
    }
}

// MARK: - Session Stat Card
struct SessionStatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.15))
                    .frame(width: 40, height: 40)
                
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundColor(color)
            }
            
            Text(value)
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundColor(.primary)
            
            Text(title)
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.gray.opacity(0.1), lineWidth: 1)
                )
        )
    }
}

// MARK: - Editable Session Exercise Card
struct EditableSessionExerciseCard: View {
    @Bindable var exerciseLog: ExerciseLog
    let isEditMode: Bool
    let onSave: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Exercise Name
            Text(exerciseLog.exerciseName)
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(.primary)
            
            // Sets Table
            VStack(spacing: 0) {
                // Header
                HStack {
                    Text("SET")
                        .frame(width: 40, alignment: .leading)
                    Text("WEIGHT")
                        .frame(width: 80, alignment: .center)
                    Text("REPS")
                        .frame(width: 50, alignment: .center)
                    Text("RIR")
                        .frame(width: 40, alignment: .center)
                    Spacer()
                }
                .font(.system(size: 10, weight: .bold))
                .tracking(0.5)
                .foregroundColor(.secondary)
                .padding(.bottom, 10)
                
                Rectangle()
                    .fill(Color.gray.opacity(0.1))
                    .frame(height: 1)
                
                // Rows
                ForEach(exerciseLog.sets.sorted { $0.setNumber < $1.setNumber }) { setLog in
                    if setLog.isCompleted {
                        EditableSetRow(setLog: setLog, isEditMode: isEditMode, onSave: onSave)
                    }
                }
            }
            
            // Notes
            if let notes = exerciseLog.notes, !notes.isEmpty {
                Text(notes)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.top, 4)
            }
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(isEditMode ? Color.blue.opacity(0.5) : Color.gray.opacity(0.1), lineWidth: 1)
                )
        )
    }
}

// MARK: - Editable Set Row
struct EditableSetRow: View {
    @Bindable var setLog: SetLog
    let isEditMode: Bool
    let onSave: () -> Void
    
    @State private var weightText: String = ""
    @State private var repsText: String = ""
    @State private var showingRIRPicker = false
    
    var body: some View {
        HStack {
            Text("\(setLog.setNumber)")
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundColor(.primary)
                .frame(width: 40, alignment: .leading)
            
            // Weight
            if isEditMode {
                TextField("0", text: $weightText)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.center)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.primary)
                    .frame(width: 60)
                    .padding(.vertical, 6)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(6)
                    .onChange(of: weightText) { _, newValue in
                        setLog.weight = Double(newValue)
                        onSave()
                    }
                Text(setLog.weightUnit.rawValue)
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
                    .frame(width: 20, alignment: .leading)
            } else {
                Text(setLog.weight != nil ? "\(String(format: "%.1f", setLog.weight!)) \(setLog.weightUnit.rawValue)" : "-")
                    .font(.system(size: 14))
                    .foregroundColor(.primary)
                    .frame(width: 80, alignment: .center)
            }
            
            // Reps
            if isEditMode {
                TextField("0", text: $repsText)
                    .keyboardType(.numberPad)
                    .multilineTextAlignment(.center)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.primary)
                    .frame(width: 44)
                    .padding(.vertical, 6)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(6)
                    .onChange(of: repsText) { _, newValue in
                        setLog.actualReps = Int(newValue)
                        onSave()
                    }
            } else {
                Text(setLog.actualReps != nil ? "\(setLog.actualReps!)" : "-")
                    .font(.system(size: 14))
                    .foregroundColor(.primary)
                    .frame(width: 50, alignment: .center)
            }
            
            // RIR
            if isEditMode {
                Menu {
                    ForEach(0...5, id: \.self) { rir in
                        Button {
                            setLog.rir = rir
                            onSave()
                        } label: {
                            Label(AppConstants.RIR.label(for: rir), systemImage: setLog.rir == rir ? "checkmark" : "")
                        }
                    }
                } label: {
                    Text(setLog.rir != nil ? "\(setLog.rir!)" : "-")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(setLog.rir != nil ? AppColors.primary : .secondary)
                        .frame(width: 32)
                        .padding(.vertical, 6)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(6)
                }
            } else {
                Text(setLog.rir != nil ? "\(setLog.rir!)" : "-")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(setLog.rir != nil ? AppConstants.RIR.color(for: setLog.rir!) : .secondary)
                    .frame(width: 40, alignment: .center)
            }
            
            Spacer()
        }
        .padding(.vertical, 10)
        .onAppear {
            if let weight = setLog.weight {
                weightText = String(format: "%.0f", weight)
            }
            if let reps = setLog.actualReps {
                repsText = String(reps)
            }
        }
    }
}

#Preview {
    let session = WorkoutSession(date: Date(), workoutDayId: UUID(), workoutDayName: "Push")
    
    return NavigationStack {
        SessionDetailView(session: session)
    }
}
