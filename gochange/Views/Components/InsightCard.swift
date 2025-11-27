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
                    .foregroundColor(.gray)
            }
            
            Text(message)
                .font(.subheadline)
                .foregroundColor(.gray)
                .lineLimit(nil)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(
                    LinearGradient(
                        colors: [color.opacity(0.1), color.opacity(0.05)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(color.opacity(0.2), lineWidth: 1)
                )
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
