import SwiftUI

// MARK: - Time Range Enum
enum TimeRange: String, CaseIterable, Identifiable {
    case week = "7D"
    case month = "30D"
    case year = "1Y"
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .week: return "Last 7 days"
        case .month: return "Last 30 days"
        case .year: return "Last 365 days"
        }
    }
    
    var days: Int {
        switch self {
        case .week: return 7
        case .month: return 30
        case .year: return 365
        }
    }
}

// MARK: - Time Range Picker
struct TimeRangePicker: View {
    @Binding var selection: TimeRange
    @Namespace private var namespace
    
    var body: some View {
        GlassEffectContainer(spacing: 4) {
            HStack(spacing: 4) {
                ForEach(TimeRange.allCases) { range in
                    Button {
                        withAnimation(.bouncy) {
                            selection = range
                        }
                    } label: {
                        Text(range.rawValue)
                            .font(.subheadline.weight(.medium))
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                    }
                    .glassEffect(
                        selection == range
                            ? .regular.tint(.blue.opacity(0.3))
                            : .clear
                    )
                    .glassEffectID(range.rawValue, in: namespace)
                }
            }
            .padding(4)
        }
    }
}

#Preview {
    VStack {
        TimeRangePicker(selection: .constant(.month))
    }
    .padding()
    .background(Color(.systemBackground))
}
