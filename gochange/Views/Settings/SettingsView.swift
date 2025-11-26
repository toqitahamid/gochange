import SwiftUI
import SwiftData
import UniformTypeIdentifiers
import HealthKit

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var workoutDays: [WorkoutDay]
    @Query private var sessions: [WorkoutSession]
    
    @AppStorage("weightUnit") private var weightUnit: String = "lbs"
    @AppStorage("restTimerDuration") private var restTimerDuration: Double = 90
    @AppStorage("hapticFeedback") private var hapticFeedback: Bool = true
    @AppStorage("healthKitEnabled") private var healthKitEnabled: Bool = false

    @State private var showingExportSheet = false
    @State private var showingImportSheet = false
    @State private var showingResetAlert = false
    @State private var exportData: Data?
    @State private var showingReminderSettings = false
    
    @StateObject private var notificationService = NotificationService.shared
    @StateObject private var healthKitService = HealthKitService.shared
    
    private let dataService = DataService()
    private let mediaService = MediaService()
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Units Section
                    SettingsSection(title: "UNITS") {
                        SettingsRow(icon: "scalemass", iconColor: Color(hex: "#FF6B35")) {
                            HStack {
                                Text("Weight Unit")
                                    .foregroundColor(.white)
                                Spacer()
                                Picker("", selection: $weightUnit) {
                                    Text("lbs").tag("lbs")
                                    Text("kg").tag("kg")
                                }
                                .pickerStyle(.segmented)
                                .frame(width: 120)
                            }
                        }
                    }
                    
                    // Rest Timer Section
                    SettingsSection(title: "REST TIMER") {
                        VStack(spacing: 16) {
                            HStack {
                                ZStack {
                                    Circle()
                                        .fill(Color(hex: "#00D4AA").opacity(0.15))
                                        .frame(width: 36, height: 36)
                                    Image(systemName: "timer")
                                        .foregroundColor(Color(hex: "#00D4AA"))
                                }
                                
                                Text("Default Duration")
                                    .foregroundColor(.white)
                                
                                Spacer()
                                
                                Text("\(Int(restTimerDuration))s")
                                    .font(.system(size: 16, weight: .bold, design: .rounded))
                                    .foregroundColor(Color(hex: "#00D4AA"))
                            }
                            
                            Slider(value: $restTimerDuration, in: 30...180, step: 15)
                                .tint(Color(hex: "#00D4AA"))
                        }
                        .padding(16)
                    }
                    
                    // Feedback Section
                    SettingsSection(title: "FEEDBACK") {
                        SettingsRow(icon: "hand.tap", iconColor: Color(hex: "#BA68C8")) {
                            Toggle(isOn: $hapticFeedback) {
                                Text("Haptic Feedback")
                                    .foregroundColor(.white)
                            }
                            .tint(Color(hex: "#00D4AA"))
                        }
                    }
                    
                    // Health Section
                    SettingsSection(title: "HEALTH") {
                        VStack(spacing: 0) {
                            if healthKitService.isHealthKitAvailable {
                                if !healthKitService.isAuthorized && healthKitService.authorizationStatus == .notDetermined {
                                    // Not yet requested
                                    SettingsButton(icon: "heart.fill", iconColor: Color(hex: "#FF6B6B"), title: "Connect Apple Health") {
                                        Task {
                                            let authorized = await healthKitService.requestAuthorization()
                                            if authorized {
                                                healthKitEnabled = true
                                            }
                                        }
                                    }
                                } else if healthKitService.isAuthorized {
                                    // Authorized - show toggle
                                    SettingsRow(icon: "heart.fill", iconColor: Color(hex: "#FF6B6B")) {
                                        Toggle(isOn: $healthKitEnabled) {
                                            VStack(alignment: .leading, spacing: 2) {
                                                Text("Sync to Apple Health")
                                                    .foregroundColor(.white)
                                                Text("Workouts & calories")
                                                    .font(.caption)
                                                    .foregroundColor(.gray)
                                            }
                                        }
                                        .tint(Color(hex: "#00D4AA"))
                                    }
                                    
                                    Rectangle().fill(Color.white.opacity(0.1)).frame(height: 1).padding(.leading, 52)
                                    
                                    SettingsButton(icon: "heart.text.square", iconColor: Color(hex: "#64B5F6"), title: "Open Health App") {
                                        if let url = URL(string: "x-apple-health://") {
                                            UIApplication.shared.open(url)
                                        }
                                    }
                                } else {
                                    // Denied
                                    SettingsRow(icon: "heart.slash", iconColor: .gray) {
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text("Health Access Denied")
                                                .foregroundColor(.white)
                                            Text("Enable in Settings > Privacy > Health")
                                                .font(.caption)
                                                .foregroundColor(.gray)
                                        }
                                    }
                                }
                            } else {
                                SettingsRow(icon: "heart.slash", iconColor: .gray) {
                                    Text("HealthKit not available")
                                        .foregroundColor(.gray)
                                }
                            }
                        }
                    }
                    
                    // Notifications Section
                    SettingsSection(title: "NOTIFICATIONS") {
                        VStack(spacing: 0) {
                            if !notificationService.isAuthorized && notificationService.authorizationStatus == .notDetermined {
                                SettingsButton(icon: "bell.badge", iconColor: Color(hex: "#FFD54F"), title: "Enable Notifications") {
                                    Task {
                                        await notificationService.requestAuthorization()
                                    }
                                }
                            } else if notificationService.isAuthorized {
                                SettingsRow(icon: "bell.fill", iconColor: Color(hex: "#FFD54F")) {
                                    HStack {
                                        Text("Notifications")
                                            .foregroundColor(.white)
                                        Spacer()
                                        Text("Enabled")
                                            .font(.system(size: 14, weight: .medium))
                                            .foregroundColor(Color(hex: "#00D4AA"))
                                    }
                                }
                                
                                Rectangle().fill(Color.white.opacity(0.1)).frame(height: 1).padding(.leading, 52)
                                
                                SettingsButton(icon: "calendar.badge.clock", iconColor: Color(hex: "#64B5F6"), title: "Workout Reminders") {
                                    showingReminderSettings = true
                                }
                            } else {
                                SettingsRow(icon: "bell.slash", iconColor: .gray) {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Notifications Disabled")
                                            .foregroundColor(.white)
                                        Text("Enable in Settings app")
                                            .font(.caption)
                                            .foregroundColor(.gray)
                                    }
                                }
                            }
                        }
                    }
                    
                    // Library Section
                    SettingsSection(title: "LIBRARY") {
                        NavigationLink(destination: ExerciseLibraryView()) {
                            HStack(spacing: 14) {
                                ZStack {
                                    Circle()
                                        .fill(Color(hex: "#00D4AA").opacity(0.15))
                                        .frame(width: 36, height: 36)
                                    
                                    Image(systemName: "figure.strengthtraining.traditional")
                                        .font(.system(size: 15))
                                        .foregroundColor(Color(hex: "#00D4AA"))
                                }
                                
                                Text("Exercise Library")
                                    .foregroundColor(.white)
                                
                                Spacer()
                                
                                Text("\(workoutDays.flatMap { $0.exercises }.count)")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.gray)
                                
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(.gray.opacity(0.5))
                            }
                            .padding(16)
                        }
                        .buttonStyle(.plain)
                    }
                    
                    // Data Management Section
                    SettingsSection(title: "DATA MANAGEMENT") {
                        VStack(spacing: 0) {
                            SettingsButton(icon: "square.and.arrow.up", iconColor: Color(hex: "#64B5F6"), title: "Export Data") {
                                exportWorkoutData()
                            }
                            
                            Rectangle().fill(Color.white.opacity(0.1)).frame(height: 1).padding(.leading, 52)
                            
                            SettingsButton(icon: "square.and.arrow.down", iconColor: Color(hex: "#4DB6AC"), title: "Import Data") {
                                showingImportSheet = true
                            }
                            
                            Rectangle().fill(Color.white.opacity(0.1)).frame(height: 1).padding(.leading, 52)
                            
                            SettingsButton(icon: "arrow.counterclockwise", iconColor: Color(hex: "#FF6B6B"), title: "Reset to Defaults", isDestructive: true) {
                                showingResetAlert = true
                            }
                        }
                    }
                    
                    // Stats Section
                    SettingsSection(title: "STATISTICS") {
                        VStack(spacing: 0) {
                            SettingsInfoRow(icon: "flame.fill", iconColor: Color(hex: "#FF6B35"), title: "Total Workouts", value: "\(sessions.filter { $0.isCompleted }.count)")
                            
                            Rectangle().fill(Color.white.opacity(0.1)).frame(height: 1).padding(.leading, 52)
                            
                            SettingsInfoRow(icon: "dumbbell.fill", iconColor: Color(hex: "#7CB9A8"), title: "Exercises", value: "\(workoutDays.flatMap { $0.exercises }.count)")
                            
                            Rectangle().fill(Color.white.opacity(0.1)).frame(height: 1).padding(.leading, 52)
                            
                            SettingsInfoRow(icon: "externaldrive.fill", iconColor: Color(hex: "#64B5F6"), title: "Media Storage", value: mediaService.formattedStorageSize())
                        }
                    }
                    
                    // About Section
                    SettingsSection(title: "ABOUT") {
                        VStack(spacing: 0) {
                            SettingsInfoRow(icon: "info.circle.fill", iconColor: .gray, title: "Version", value: "1.0.0")
                            
                            Rectangle().fill(Color.white.opacity(0.1)).frame(height: 1).padding(.leading, 52)
                            
                            SettingsButton(icon: "chevron.left.forwardslash.chevron.right", iconColor: Color(hex: "#00D4AA"), title: "View Source Code") {
                                if let url = URL(string: "https://github.com") {
                                    UIApplication.shared.open(url)
                                }
                            }
                        }
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
            .sheet(isPresented: $showingExportSheet) {
                if let data = exportData {
                    ShareSheet(activityItems: [data])
                }
            }
            .fileImporter(
                isPresented: $showingImportSheet,
                allowedContentTypes: [.json]
            ) { result in
                handleImport(result)
            }
            .alert("Reset All Data?", isPresented: $showingResetAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Reset", role: .destructive) {
                    resetToDefaults()
                }
            } message: {
                Text("This will delete all your workout history and reset exercises to defaults. This action cannot be undone.")
            }
            .sheet(isPresented: $showingReminderSettings) {
                ReminderSettingsView(workoutDays: workoutDays)
            }
            .onAppear {
                notificationService.checkAuthorizationStatus()
                healthKitService.checkAuthorizationStatus()
            }
        }
    }
    
    private func exportWorkoutData() {
        if let data = dataService.exportData(workoutDays: workoutDays, sessions: sessions) {
            exportData = data
            showingExportSheet = true
        }
    }
    
    private func handleImport(_ result: Result<URL, Error>) {
        switch result {
        case .success(let url):
            guard url.startAccessingSecurityScopedResource() else { return }
            defer { url.stopAccessingSecurityScopedResource() }
            
            do {
                let data = try Data(contentsOf: url)
                try dataService.importData(from: data, context: modelContext)
            } catch {
                print("Import error: \(error)")
            }
        case .failure(let error):
            print("File selection error: \(error)")
        }
    }
    
    private func resetToDefaults() {
        // Delete all sessions
        for session in sessions {
            modelContext.delete(session)
        }
        
        // Delete all workout days
        for day in workoutDays {
            modelContext.delete(day)
        }
        
        // Recreate default workouts
        let defaultWorkouts = DefaultWorkoutData.createDefaultWorkouts()
        for workout in defaultWorkouts {
            modelContext.insert(workout)
        }
        
        try? modelContext.save()
    }
}

// MARK: - Settings Section
struct SettingsSection<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.system(size: 12, weight: .bold))
                .tracking(1.5)
                .foregroundColor(.gray)
                .padding(.horizontal, 4)
            
            VStack(spacing: 0) {
                content
            }
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white.opacity(0.05))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
                    )
            )
        }
    }
}

// MARK: - Settings Row
struct SettingsRow<Content: View>: View {
    let icon: String
    let iconColor: Color
    @ViewBuilder let content: Content
    
    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(iconColor.opacity(0.15))
                    .frame(width: 36, height: 36)
                
                Image(systemName: icon)
                    .font(.system(size: 15))
                    .foregroundColor(iconColor)
            }
            
            content
        }
        .padding(16)
    }
}

// MARK: - Settings Button
struct SettingsButton: View {
    let icon: String
    let iconColor: Color
    let title: String
    var isDestructive: Bool = false
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(iconColor.opacity(0.15))
                        .frame(width: 36, height: 36)
                    
                    Image(systemName: icon)
                        .font(.system(size: 15))
                        .foregroundColor(iconColor)
                }
                
                Text(title)
                    .foregroundColor(isDestructive ? Color(hex: "#FF6B6B") : .white)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.gray.opacity(0.5))
            }
            .padding(16)
        }
    }
}

// MARK: - Settings Info Row
struct SettingsInfoRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    let value: String
    
    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(iconColor.opacity(0.15))
                    .frame(width: 36, height: 36)
                
                Image(systemName: icon)
                    .font(.system(size: 15))
                    .foregroundColor(iconColor)
            }
            
            Text(title)
                .foregroundColor(.white)
            
            Spacer()
            
            Text(value)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.gray)
        }
        .padding(16)
    }
}

// MARK: - Share Sheet
struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// MARK: - Reminder Settings View
struct ReminderSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    let workoutDays: [WorkoutDay]
    
    @State private var reminders: [WorkoutReminderSchedule] = []
    @State private var selectedReminder: WorkoutReminderSchedule?
    @State private var showingTimePicker = false
    
    // Days of week with typical workout mapping
    private let weekdays = [
        (2, "Monday"),
        (3, "Tuesday"),
        (4, "Wednesday"),
        (5, "Thursday"),
        (6, "Friday"),
        (7, "Saturday"),
        (1, "Sunday")
    ]
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    Text("Set reminders to get notified when it's time to work out.")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 20)
                    
                    VStack(spacing: 0) {
                        ForEach(Array(reminders.enumerated()), id: \.element.id) { index, reminder in
                            VStack(spacing: 0) {
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(reminder.weekdayName)
                                            .font(.system(size: 16, weight: .semibold))
                                            .foregroundColor(.white)
                                        
                                        if reminder.isEnabled {
                                            Text("\(reminder.timeString) • \(reminder.workoutName)")
                                                .font(.caption)
                                                .foregroundColor(Color(hex: "#00D4AA"))
                                        }
                                    }
                                    
                                    Spacer()
                                    
                                    Toggle("", isOn: Binding(
                                        get: { reminder.isEnabled },
                                        set: { newValue in
                                            reminders[index].isEnabled = newValue
                                            updateReminder(reminders[index])
                                        }
                                    ))
                                    .tint(Color(hex: "#00D4AA"))
                                }
                                .padding(16)
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    selectedReminder = reminder
                                    showingTimePicker = true
                                }
                                
                                if index < reminders.count - 1 {
                                    Rectangle()
                                        .fill(Color.white.opacity(0.1))
                                        .frame(height: 1)
                                        .padding(.leading, 16)
                                }
                            }
                        }
                    }
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.white.opacity(0.05))
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
                            )
                    )
                    .padding(.horizontal, 20)
                }
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
            .navigationTitle("Workout Reminders")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showingTimePicker) {
                if let reminder = selectedReminder,
                   let index = reminders.firstIndex(where: { $0.id == reminder.id }) {
                    ReminderTimePickerView(reminder: $reminders[index]) {
                        updateReminder(reminders[index])
                    }
                    .presentationDetents([.medium])
                    .presentationDragIndicator(.visible)
                }
            }
            .task {
                await loadReminders()
            }
        }
    }
    
    private func loadReminders() async {
        let scheduledReminders = await NotificationService.shared.getScheduledReminders()
        
        var loadedReminders: [WorkoutReminderSchedule] = []
        for (weekday, _) in weekdays {
            let workoutName = workoutDays.first?.name ?? "Workout"
            if let scheduled = scheduledReminders[weekday] {
                loadedReminders.append(WorkoutReminderSchedule(
                    weekday: weekday,
                    isEnabled: true,
                    hour: scheduled.hour,
                    minute: scheduled.minute,
                    workoutName: workoutName
                ))
            } else {
                loadedReminders.append(WorkoutReminderSchedule(
                    weekday: weekday,
                    isEnabled: false,
                    hour: 8,
                    minute: 0,
                    workoutName: workoutName
                ))
            }
        }
        reminders = loadedReminders
    }
    
    private func updateReminder(_ reminder: WorkoutReminderSchedule) {
        if reminder.isEnabled {
            NotificationService.shared.scheduleWorkoutReminder(
                weekday: reminder.weekday,
                hour: reminder.hour,
                minute: reminder.minute,
                workoutName: reminder.workoutName
            )
        } else {
            NotificationService.shared.cancelWorkoutReminder(weekday: reminder.weekday)
        }
    }
}

// MARK: - Reminder Time Picker View
struct ReminderTimePickerView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var reminder: WorkoutReminderSchedule
    let onSave: () -> Void
    
    @State private var selectedTime = Date()
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Text(reminder.weekdayName)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                DatePicker("", selection: $selectedTime, displayedComponents: .hourAndMinute)
                    .datePickerStyle(.wheel)
                    .labelsHidden()
                
                Spacer()
            }
            .padding(20)
            .background(
                LinearGradient(
                    colors: [Color.black, Color(hex: "#0A1628")],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
            )
            .navigationTitle("Set Time")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let components = Calendar.current.dateComponents([.hour, .minute], from: selectedTime)
                        reminder.hour = components.hour ?? 8
                        reminder.minute = components.minute ?? 0
                        reminder.isEnabled = true
                        onSave()
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
            .onAppear {
                var components = DateComponents()
                components.hour = reminder.hour
                components.minute = reminder.minute
                selectedTime = Calendar.current.date(from: components) ?? Date()
            }
        }
    }
}

#Preview {
    SettingsView()
        .modelContainer(for: [WorkoutDay.self, WorkoutSession.self])
}
