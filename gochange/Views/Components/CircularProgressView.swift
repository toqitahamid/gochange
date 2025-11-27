import SwiftUI

struct CircularProgressView: View {
    let progress: Double // 0.0 to 1.0
    let lineWidth: CGFloat
    let trackColor: Color
    
    // Option 1: Gradient
    var gradient: LinearGradient?
    
    // Option 2: Solid Color
    var color: Color?
    
    init(progress: Double, lineWidth: CGFloat, gradient: LinearGradient, trackColor: Color) {
        self.progress = progress
        self.lineWidth = lineWidth
        self.gradient = gradient
        self.trackColor = trackColor
        self.color = nil
    }
    
    init(progress: Double, lineWidth: CGFloat = 8, color: Color) {
        self.progress = progress
        self.lineWidth = lineWidth
        self.color = color
        self.trackColor = color.opacity(0.2)
        self.gradient = nil
    }
    
    var body: some View {
        ZStack {
            // Track
            Circle()
                .stroke(trackColor, lineWidth: lineWidth)
            
            // Progress
            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    gradient != nil ? AnyShapeStyle(gradient!) : AnyShapeStyle(color ?? .blue),
                    style: StrokeStyle(
                        lineWidth: lineWidth,
                        lineCap: .round
                    )
                )
                .rotationEffect(.degrees(-90))
                .shadow(color: (color ?? .white).opacity(0.5), radius: 10, x: 0, y: 0) // Glow effect
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
