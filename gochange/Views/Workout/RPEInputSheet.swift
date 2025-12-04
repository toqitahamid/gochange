import SwiftUI

struct RPEInputSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var rpe: Double
    let onFinish: () -> Void

    @State private var showExplanation = false
    @State private var isDragging = false

    private let rpeData: [(value: Int, label: String, description: String, icon: String)] = [
        (1, "Very Light", "Barely any effort", "wind"),
        (2, "Light", "Easy warmup", "leaf.fill"),
        (3, "Light+", "Comfortable pace", "figure.walk"),
        (4, "Moderate", "Starting to work", "figure.run"),
        (5, "Moderate+", "Noticeable effort", "flame"),
        (6, "Hard", "Challenging", "flame.fill"),
        (7, "Hard+", "Pushing limits", "bolt.fill"),
        (8, "Very Hard", "Near max effort", "bolt.heart.fill"),
        (9, "Extremely Hard", "Almost failure", "exclamationmark.triangle.fill"),
        (10, "Max Effort", "Complete failure", "burst.fill")
    ]

    private var currentItem: (value: Int, label: String, description: String, icon: String) {
        let index = max(0, min(9, Int(rpe) - 1))
        return rpeData[index]
    }

    var body: some View {
        VStack(spacing: 0) {
            // Drag Indicator
            Capsule()
                .fill(AppColors.textTertiary.opacity(0.3))
                .frame(width: 40, height: 4)
                .padding(.top, 10)

            // Header
            headerSection

            Spacer()

            // Large Visual Indicator
            visualIndicator

            Spacer()

            // Slider Section
            sliderSection

            Spacer()

            // Action Button
            actionButton
        }
        .background(AppColors.surface.ignoresSafeArea())
        .sheet(isPresented: $showExplanation) {
            MetricExplanationSheet(metric: .rpe, currentValue: rpe)
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(spacing: 8) {
            HStack(spacing: 8) {
                Text("Rate Your Effort")
                    .font(AppFonts.title(24))
                    .foregroundColor(AppColors.textPrimary)

                Button {
                    showExplanation = true
                } label: {
                    Image(systemName: "info.circle")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(AppColors.textTertiary)
                }
            }

            Text("How hard was this workout?")
                .font(AppFonts.label(14))
                .foregroundColor(AppColors.textSecondary)
        }
        .padding(.top, 24)
        .padding(.bottom, 20)
    }

    // MARK: - Visual Indicator

    private var visualIndicator: some View {
        VStack(spacing: 20) {
            // Large circle with RPE value
            ZStack {
                // Outer ring
                Circle()
                    .stroke(rpeColor.opacity(0.2), lineWidth: 12)
                    .frame(width: 160, height: 160)

                // Middle ring
                Circle()
                    .stroke(rpeColor.opacity(0.4), lineWidth: 6)
                    .frame(width: 130, height: 130)

                // Center circle
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [rpeColor, rpeColor.opacity(0.8)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 110, height: 110)
                    .shadow(color: rpeColor.opacity(0.5), radius: 20, x: 0, y: 10)

                // Icon and value
                VStack(spacing: 6) {
                    Image(systemName: currentItem.icon)
                        .font(.system(size: 28, weight: .semibold))
                        .foregroundColor(.white.opacity(0.9))

                    Text("\(Int(rpe))")
                        .font(AppFonts.rounded(44, weight: .black))
                        .foregroundColor(.white)
                }
            }
            .scaleEffect(isDragging ? 1.05 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isDragging)

            // Description
            VStack(spacing: 6) {
                Text(currentItem.label)
                    .font(AppFonts.rounded(22, weight: .bold))
                    .foregroundColor(AppColors.textPrimary)

                Text(currentItem.description)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(AppColors.textSecondary)
            }
            .animation(.easeInOut(duration: 0.15), value: Int(rpe))
        }
    }

    // MARK: - Slider Section

    private var sliderSection: some View {
        VStack(spacing: 16) {
            // Custom Slider
            RPESlider(value: $rpe, range: 1...10) { dragging in
                isDragging = dragging
                if dragging {
                    let impact = UIImpactFeedbackGenerator(style: .light)
                    impact.impactOccurred()
                }
            }
            .frame(height: 56)
            .padding(.horizontal, AppLayout.margin)

            // Number indicators
            HStack {
                ForEach(1...10, id: \.self) { num in
                    Text("\(num)")
                        .font(AppFonts.rounded(12, weight: Int(rpe) == num ? .bold : .medium))
                        .foregroundColor(Int(rpe) == num ? rpeColor : AppColors.textTertiary)
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(.horizontal, AppLayout.margin + 8)

            // Labels
            HStack {
                Text("EASY")
                    .font(AppFonts.label(10))
                    .tracking(1)
                    .foregroundColor(AppColors.textTertiary)

                Spacer()

                Text("MAX EFFORT")
                    .font(AppFonts.label(10))
                    .tracking(1)
                    .foregroundColor(AppColors.textTertiary)
            }
            .padding(.horizontal, AppLayout.margin)
        }
    }

    // MARK: - Action Button

    private var actionButton: some View {
        VStack(spacing: 12) {
            // Primary Button - Complete Workout
            Button {
                let impact = UINotificationFeedbackGenerator()
                impact.notificationOccurred(.success)
                onFinish()
            } label: {
                Text("Complete Workout")
                    .font(AppFonts.rounded(17, weight: .bold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(AppColors.secondary)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
            }
            .buttonStyle(ScaleButtonStyle())

            // Secondary Button - Cancel
            Button {
                dismiss()
            } label: {
                Text("Cancel")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(AppColors.textSecondary)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(AppColors.background)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .buttonStyle(ScaleButtonStyle())
        }
        .padding(.horizontal, AppLayout.margin)
        .padding(.bottom, 40)
    }

    // MARK: - Helper

    private var rpeColor: Color {
        switch Int(rpe) {
        case 1...3: return AppColors.success
        case 4...5: return Color(hex: "#34D399")
        case 6...7: return AppColors.warning
        case 8...9: return Color(hex: "#F97316")
        default: return AppColors.error
        }
    }
}

// MARK: - Custom RPE Slider

struct RPESlider: View {
    @Binding var value: Double
    let range: ClosedRange<Double>
    let onEditingChanged: (Bool) -> Void

    @State private var isDragging = false

    private var thumbColor: Color {
        switch Int(value) {
        case 1...3: return AppColors.success
        case 4...5: return Color(hex: "#34D399")
        case 6...7: return AppColors.warning
        case 8...9: return Color(hex: "#F97316")
        default: return AppColors.error
        }
    }

    var body: some View {
        GeometryReader { geometry in
            let width = geometry.size.width
            let trackHeight: CGFloat = 8
            let thumbSize: CGFloat = 36

            ZStack(alignment: .leading) {
                // Track Background
                Capsule()
                    .fill(AppColors.background)
                    .frame(height: trackHeight)

                // Gradient Track (full width, masked)
                LinearGradient(
                    stops: [
                        .init(color: AppColors.success, location: 0.0),
                        .init(color: Color(hex: "#34D399"), location: 0.35),
                        .init(color: AppColors.warning, location: 0.55),
                        .init(color: Color(hex: "#F97316"), location: 0.8),
                        .init(color: AppColors.error, location: 1.0)
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .mask(
                    HStack(spacing: 0) {
                        Capsule()
                            .frame(width: thumbOffset(in: width) + thumbSize / 2)
                        Spacer(minLength: 0)
                    }
                )
                .frame(height: trackHeight)

                // Tick Marks
                HStack(spacing: 0) {
                    ForEach(0..<9) { i in
                        Spacer()
                        Circle()
                            .fill(Color.white.opacity(0.4))
                            .frame(width: 4, height: 4)
                    }
                    Spacer()
                }
                .padding(.horizontal, thumbSize / 2)

                // Thumb
                Circle()
                    .fill(Color.white)
                    .frame(width: thumbSize, height: thumbSize)
                    .shadow(color: .black.opacity(0.15), radius: 6, x: 0, y: 3)
                    .overlay(
                        Circle()
                            .fill(thumbColor)
                            .frame(width: thumbSize - 8, height: thumbSize - 8)
                    )
                    .overlay(
                        Text("\(Int(value))")
                            .font(AppFonts.rounded(14, weight: .bold))
                            .foregroundColor(.white)
                    )
                    .scaleEffect(isDragging ? 1.15 : 1.0)
                    .offset(x: thumbOffset(in: width))
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { gesture in
                                if !isDragging {
                                    isDragging = true
                                    onEditingChanged(true)
                                }
                                updateValue(with: gesture.location.x, in: width)
                            }
                            .onEnded { _ in
                                isDragging = false
                                onEditingChanged(false)
                                // Snap haptic
                                let impact = UIImpactFeedbackGenerator(style: .medium)
                                impact.impactOccurred()
                            }
                    )
            }
            .frame(height: thumbSize)
            .frame(maxHeight: .infinity, alignment: .center)
        }
    }

    private func thumbOffset(in width: CGFloat) -> CGFloat {
        let thumbSize: CGFloat = 36
        let usableWidth = width - thumbSize
        let progress = (value - range.lowerBound) / (range.upperBound - range.lowerBound)
        return CGFloat(progress) * usableWidth
    }

    private func updateValue(with locationX: CGFloat, in width: CGFloat) {
        let thumbSize: CGFloat = 36
        let usableWidth = width - thumbSize
        let adjustedX = locationX - thumbSize / 2
        let progress = max(0, min(1, adjustedX / usableWidth))
        let newValue = range.lowerBound + progress * (range.upperBound - range.lowerBound)
        // Snap to whole numbers
        let snappedValue = round(newValue)
        if snappedValue != value {
            value = snappedValue
            // Haptic on value change
            let impact = UISelectionFeedbackGenerator()
            impact.selectionChanged()
        }
    }
}

#Preview {
    RPEInputSheet(rpe: .constant(7.0)) {}
}
