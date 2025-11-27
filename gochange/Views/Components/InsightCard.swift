import SwiftUI

struct InsightCard: View {
    let title: String
    let message: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.white)
                
                Image(systemName: icon)
                    .foregroundColor(color)
                
                Spacer()
                
                Image(systemName: "arrow.up.left.and.arrow.down.right")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.5))
            }
            
            Text(message)
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.8))
                .lineLimit(nil)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(20)
        .background(.ultraThinMaterial)
        .cornerRadius(20)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
    }
}

#Preview {
    InsightCard(
        title: "Feeling ready to move",
        message: "With a resting HRV of 65.1 ms and resting heart rate at 49.1 bpm your recovery is higher than normal. You can take advantage of this energy for a strong session today.",
        icon: "leaf.fill",
        color: .green
    )
    .padding()
    .background(Color.black)
}
