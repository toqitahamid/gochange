import SwiftUI

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
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 20)
                    
                    VStack(spacing: 0) {
                        ForEach(Array(reminders.enumerated()), id: \.element.id) { index, reminder in
                            VStack(spacing: 0) {
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(reminder.weekdayName)
                                            .font(.system(size: 16, weight: .semibold))
                                            .foregroundColor(.primary)
                                        
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
                                        .fill(Color.gray.opacity(0.1))
                                        .frame(height: 1)
                                        .padding(.leading, 16)
                                }
                            }
                        }
                    }
                    .background(Color.white)
                    .cornerRadius(16)
                    .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 4)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.gray.opacity(0.15), lineWidth: 1)
                    )
                    .padding(.horizontal, 20)
                }
                .padding(.top, 20)
                .padding(.bottom, 100)
            }
            .background(Color(hex: "#F2F2F7").ignoresSafeArea())
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
                    .foregroundColor(.primary)
                
                DatePicker("", selection: $selectedTime, displayedComponents: .hourAndMinute)
                    .datePickerStyle(.wheel)
                    .labelsHidden()
                
                Spacer()
            }
            .padding(20)
            .background(Color(hex: "#F2F2F7").ignoresSafeArea())
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
                        onSave()
                        dismiss()
                    }
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
    ReminderSettingsView(workoutDays: [])
}
