import SwiftUI

struct RPEInputSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var rpe: Double
    let onFinish: () -> Void
    
    // Internal state for drag gesture
    @State private var dragOffset: CGFloat = 0
    @State private var isDragging: Bool = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(spacing: 8) {
                Text("Perceived Exertion")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(.white)
                
                Text("How did it feel?")
                    .font(.system(size: 16))
                    .foregroundColor(.gray)
            }
            .padding(.top, 30)
            
            Spacer()
                .frame(height: 40)
            
            // Dynamic Feedback (Icon + Text)
            VStack(spacing: 16) {
                // Emoji/Icon
                ZStack {
                    Circle()
                        .fill(rpeColor)
                        .frame(width: 80, height: 80)
                        .shadow(color: rpeColor.opacity(0.5), radius: 20, x: 0, y: 10)
                    
                    Text(rpeEmoji)
                        .font(.system(size: 40))
                }
                .scaleEffect(isDragging ? 1.1 : 1.0)
                .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isDragging)
                
                // Text Feedback
                VStack(spacing: 6) {
                    Text(rpeTitle)
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text(rpeDescription)
                        .font(.system(size: 15))
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true) // Prevent truncation
                }
            }
            
            Spacer()
                .frame(height: 60)
            
            // Custom Slider
            VStack(spacing: 8) {
                HStack {
                    Text("AVG STRENGTH TRAINING")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.gray)
                        .tracking(0.5)
                    Spacer()
                }
                .padding(.horizontal, 24)
                
                CustomGradientSlider(value: $rpe, range: 1...10) { isDragging in
                    self.isDragging = isDragging
                }
                .frame(height: 44)
                .padding(.horizontal, 24)
                
                HStack {
                    Text("YOUR USUAL RANGE")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.gray)
                        .tracking(0.5)
                    Spacer()
                }
                .padding(.horizontal, 24)
            }
            
            Spacer()
            
            // Action Buttons
            VStack(spacing: 16) {
                Button(action: onFinish) {
                    Text("Save")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(Color(hex: "#A5D6D9")) // Light blue/teal from screenshot
                        .cornerRadius(28)
                }
                
                Button(action: { dismiss() }) {
                    Text("Cancel")
                        .font(.system(size: 17, weight: .medium))
                        .foregroundColor(.white)
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 30)
        }
        .background(Color(hex: "#1C1C1E").ignoresSafeArea()) // Dark background
        .preferredColorScheme(.dark)
    }
    
    // MARK: - Dynamic Content
    
    private var rpeColor: Color {
        switch rpe {
        case 0..<3: return Color(hex: "#64D2FF") // Blue
        case 3..<5: return Color(hex: "#64D2FF").opacity(0.8) // Blue-Green
        case 5..<7: return Color(hex: "#FFD60A") // Yellow/Orange
        case 7..<9: return Color(hex: "#FF9F0A") // Orange
        default: return Color(hex: "#BF5AF2") // Purple
        }
    }
    
    private var rpeEmoji: String {
        switch rpe {
        case 0..<3: return "😌"
        case 3..<5: return "🙂"
        case 5..<7: return "😐"
        case 7..<9: return "😰"
        default: return "🥵"
        }
    }
    
    private var rpeTitle: String {
        switch rpe {
        case 0..<2: return "No Effort"
        case 2..<4: return "Easy"
        case 4..<6: return "Moderate"
        case 6..<8: return "Hard"
        case 8..<9: return "Very Hard"
        default: return "Max Effort"
        }
    }
    
    private var rpeDescription: String {
        switch rpe {
        case 0..<2: return "Resting heart rate, feeling very comfortable."
        case 2..<4: return "Could maintain this pace for hours. Easy breathing."
        case 4..<6: return "Breathing heavier but can still talk. Starting to sweat."
        case 6..<8: return "Uncomfortable. Short sentences only. Heavy sweating."
        case 8..<9: return "Very uncomfortable. Can barely speak. Near failure."
        default: return "Complete exhaustion. Cannot continue. Muscle failure."
        }
    }
}

// MARK: - Custom Gradient Slider

struct CustomGradientSlider: View {
    @Binding var value: Double
    let range: ClosedRange<Double>
    let onEditingChanged: (Bool) -> Void
    
    var body: some View {
        GeometryReader { geometry in
            let width = geometry.size.width
            let trackHeight: CGFloat = 24 // Tapered height logic could be added here
            
            ZStack(alignment: .leading) {
                // Track Background (Hatched pattern for "Usual Range")
                // Simplified as a dark track for now, can add hatching if needed
                Capsule()
                    .fill(Color.white.opacity(0.1))
                    .frame(height: trackHeight)
                
                // Gradient Track
                // We want a tapered look: thinner at start, thicker at end?
                // Or just a gradient bar. Screenshot shows a wedge shape.
                // Let's stick to a uniform height for simplicity first, or use a path for wedge.
                LinearGradient(
                    stops: [
                        .init(color: Color(hex: "#64D2FF"), location: 0.0), // Blue
                        .init(color: Color(hex: "#FFD60A"), location: 0.5), // Yellow
                        .init(color: Color(hex: "#BF5AF2"), location: 1.0)  // Purple
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .mask(
                    // Mask to show only up to the thumb? No, screenshot shows full gradient but dimmed?
                    // Actually screenshot shows the gradient IS the track.
                    // Let's just fill the whole track with gradient.
                    Capsule()
                )
                .frame(height: trackHeight)
                .opacity(0.8)
                
                // Tick Marks
                HStack(spacing: 0) {
                    ForEach(0..<10) { i in
                        Spacer()
                        Rectangle()
                            .fill(Color.black.opacity(0.3))
                            .frame(width: 1, height: 12)
                        if i == 9 { Spacer() }
                    }
                }
                
                // Thumb
                Circle()
                    .fill(Color.white)
                    .frame(width: 32, height: 32)
                    .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
                    .overlay(
                        Circle()
                            .fill(thumbColor)
                            .padding(6)
                    )
                    .offset(x: thumbOffset(in: width) - 16) // Center thumb
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { value in
                                onEditingChanged(true)
                                updateValue(with: value.location.x, in: width)
                            }
                            .onEnded { _ in
                                onEditingChanged(false)
                            }
                    )
            }
            .frame(height: trackHeight)
            // Center vertically in the 44pt frame
            .frame(maxHeight: .infinity, alignment: .center)
        }
    }
    
    private var thumbColor: Color {
        // Map value to gradient color roughly
        let progress = (value - range.lowerBound) / (range.upperBound - range.lowerBound)
        if progress < 0.33 { return Color(hex: "#64D2FF") }
        if progress < 0.66 { return Color(hex: "#FFD60A") }
        return Color(hex: "#BF5AF2")
    }
    
    private func thumbOffset(in width: CGFloat) -> CGFloat {
        let progress = (value - range.lowerBound) / (range.upperBound - range.lowerBound)
        return CGFloat(progress) * width
    }
    
    private func updateValue(with locationX: CGFloat, in width: CGFloat) {
        let progress = max(0, min(1, locationX / width))
        let newValue = range.lowerBound + progress * (range.upperBound - range.lowerBound)
        // Snap to 0.5 increments
        value = (newValue * 2).rounded() / 2
    }
}

#Preview {
    RPEInputSheet(rpe: .constant(4.0)) {}
}
