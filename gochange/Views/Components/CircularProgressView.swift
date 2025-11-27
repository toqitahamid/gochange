import SwiftUI

struct CircularProgressView: View {
    let progress: Double // 0.0 to 1.0
    let lineWidth: CGFloat
    let gradient: LinearGradient
    let trackColor: Color
    
    var body: some View {
        ZStack {
            // Track
            Circle()
                .stroke(trackColor, lineWidth: lineWidth)
            
            // Progress
            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    gradient,
                    style: StrokeStyle(
                        lineWidth: lineWidth,
                        lineCap: .round
                    )
                )
                .rotationEffect(.degrees(-90))
                .animation(.spring(response: 1.0, dampingFraction: 0.8), value: progress)
        }
    }
}

#Preview {
    CircularProgressView(
        progress: 0.75,
        lineWidth: 20,
        gradient: LinearGradient(
            colors: [.green, .mint],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        ),
        trackColor: .gray.opacity(0.2)
    )
    .frame(width: 200, height: 200)
    .padding()
    .background(Color.black)
}
