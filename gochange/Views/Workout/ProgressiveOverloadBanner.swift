import SwiftUI

struct ProgressiveOverloadBanner: View {
    let suggestion: OverloadSuggestion
    @State private var isDismissed = false

    private var iconName: String {
        switch suggestion.type {
        case .increaseWeight, .increaseReps:
            return "arrow.up.right.circle.fill"
        case .maintain:
            return "target"
        }
    }

    private var backgroundColor: Color {
        switch suggestion.type {
        case .increaseWeight, .increaseReps:
            return Color(hex: "#5B7FFF")
        case .maintain:
            return Color(hex: "#7B92FF")
        }
    }

    var body: some View {
        if !isDismissed {
            HStack(spacing: 14) {
                // Icon
                Image(systemName: iconName)
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(width: 44, height: 44)
                    .background(
                        Circle()
                            .fill(Color.white.opacity(0.2))
                    )

                // Message
                VStack(alignment: .leading, spacing: 4) {
                    Text("Progressive Overload")
                        .font(.system(size: 11, weight: .bold))
                        .tracking(1.2)
                        .foregroundColor(.white.opacity(0.9))

                    Text(suggestion.message)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer()

                // Dismiss Button
                Button {
                    withAnimation(.easeOut(duration: 0.2)) {
                        isDismissed = true
                    }
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.white.opacity(0.7))
                        .frame(width: 24, height: 24)
                        .background(
                            Circle()
                                .fill(Color.white.opacity(0.15))
                        )
                }
            }
            .padding(16)
            .background(
                LinearGradient(
                    colors: [backgroundColor, backgroundColor.opacity(0.85)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .cornerRadius(16)
            .shadow(color: backgroundColor.opacity(0.3), radius: 10, x: 0, y: 4)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
            )
            .transition(.move(edge: .top).combined(with: .opacity))
        }
    }
}
