import SwiftUI

struct MetricCard: View {
    let title: String
    let value: String
    let unit: String?
    let icon: String
    let color: Color
    var trend: Trend? = nil
    
    enum Trend {
        case up, down, neutral
        
        var icon: String {
            switch self {
            case .up: return "arrow.up"
            case .down: return "arrow.down"
            case .neutral: return "minus"
            }
        }
        
        var color: Color {
            switch self {
            case .up: return .green
            case .down: return .red
            case .neutral: return .gray
            }
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.system(size: 14))
                
                Text(title)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white.opacity(0.7))
                
                Spacer()
            }
            
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(value)
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                
                if let unit = unit {
                    Text(unit)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white.opacity(0.5))
                }
                
                Spacer()
                
                if let trend = trend {
                    Image(systemName: trend.icon)
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(trend.color)
                        .padding(6)
                        .background(trend.color.opacity(0.2))
                        .clipShape(Circle())
                }
            }
        }
        .padding(16)
        .background(.ultraThinMaterial)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
    }
}

#Preview {
    MetricCard(
        title: "Resting HRV",
        value: "65.1",
        unit: "ms",
        icon: "waveform.path.ecg",
        color: .green,
        trend: .up
    )
    .frame(width: 160)
    .padding()
    .background(Color.black)
}
