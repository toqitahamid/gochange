import SwiftUI
import SwiftData

struct RestDayListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \RestDay.date, order: .reverse) private var restDays: [RestDay]
    
    var body: some View {
        List {
            if restDays.isEmpty {
                ContentUnavailableView("No Rest Days", systemImage: "bed.double.fill", description: Text("Rest days you log will appear here."))
            } else {
                ForEach(restDays) { day in
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text(day.date.formatted(date: .abbreviated, time: .shortened))
                                .font(.headline)
                            Spacer()
                            Text(day.type.rawValue.capitalized)
                                .font(.caption)
                                .fontWeight(.medium)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(day.type == .activeRecovery ? Color.green.opacity(0.1) : Color.blue.opacity(0.1))
                                .foregroundColor(day.type == .activeRecovery ? .green : .blue)
                                .clipShape(Capsule())
                        }
                        
                        if let note = day.notes, !note.isEmpty {
                            Text(note)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.vertical, 4)
                }
                .onDelete(perform: deleteRestDays)
            }
        }
        .navigationTitle("Rest Days")
        .listStyle(.insetGrouped)
    }
    
    private func deleteRestDays(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(restDays[index])
        }
    }
}

#Preview {
    NavigationStack {
        RestDayListView()
            .modelContainer(for: RestDay.self)
    }
}
