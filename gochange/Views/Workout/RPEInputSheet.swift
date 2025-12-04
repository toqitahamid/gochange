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
            RPEExplanationView()
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
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

// MARK: - Custom RPE Explanation View
struct RPEExplanationView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var animateItems = false
    @State private var selectedLevel: Int? = nil
    
    // Premium color palette
    private let rpeScale: [(range: String, label: String, description: String, color: Color, icon: String)] = [
        ("1-2", "Recovery Zone", "Minimal effort. Great for warm-ups and active recovery days.", Color(hex: "#10B981"), "leaf.fill"),
        ("3-4", "Light Work", "Comfortable pace. You can easily hold a conversation.", Color(hex: "#14B8A6"), "figure.walk"),
        ("5-6", "Moderate", "Challenging but sustainable. Some effort required.", Color(hex: "#F59E0B"), "flame"),
        ("7-8", "Hard", "Pushing your limits. Difficult to talk. Last few reps are tough.", Color(hex: "#F97316"), "bolt.fill"),
        ("9-10", "Maximum", "Near or at failure. You're giving everything you've got.", Color(hex: "#E11D48"), "burst.fill")
    ]
    
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 28) {
                // Header
                headerSection
                
                // Visual Scale
                visualScale
                
                // Effort Zones
                effortZonesSection
                
                // Tips Section
                tipsSection
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 24)
        }
        .background(AppColors.surface.ignoresSafeArea())
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.1)) {
                animateItems = true
            }
        }
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        VStack(spacing: 16) {
            // Icon with gradient ring
            ZStack {
                Circle()
                    .stroke(
                        LinearGradient(
                            colors: [Color(hex: "#10B981"), Color(hex: "#F59E0B"), Color(hex: "#E11D48")],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 4
                    )
                    .frame(width: 80, height: 80)
                
                Image(systemName: "gauge.with.needle.fill")
                    .font(.system(size: 36, weight: .semibold))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color(hex: "#D97706"), Color(hex: "#EA580C")],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
            }
            .scaleEffect(animateItems ? 1.0 : 0.8)
            .opacity(animateItems ? 1.0 : 0)
            
            VStack(spacing: 6) {
                Text("Rate of Perceived Exertion")
                    .font(AppFonts.title(22))
                    .foregroundColor(AppColors.textPrimary)
                
                Text("How hard did that feel?")
                    .font(AppFonts.label(15))
                    .foregroundColor(AppColors.textSecondary)
            }
            .opacity(animateItems ? 1.0 : 0)
            .offset(y: animateItems ? 0 : 10)
        }
    }
    
    // MARK: - Visual Scale
    private var visualScale: some View {
        VStack(spacing: 12) {
            // Gradient bar with numbers
            ZStack(alignment: .bottom) {
                // Gradient bar
                RoundedRectangle(cornerRadius: 12)
                    .fill(
                        LinearGradient(
                            stops: [
                                .init(color: Color(hex: "#10B981"), location: 0.0),
                                .init(color: Color(hex: "#14B8A6"), location: 0.25),
                                .init(color: Color(hex: "#F59E0B"), location: 0.5),
                                .init(color: Color(hex: "#F97316"), location: 0.75),
                                .init(color: Color(hex: "#E11D48"), location: 1.0)
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(height: 16)
                    .opacity(animateItems ? 1.0 : 0)
                
                // Number markers
                HStack {
                    ForEach(1...10, id: \.self) { num in
                        Text("\(num)")
                            .font(AppFonts.rounded(11, weight: .bold))
                            .foregroundColor(AppColors.textSecondary)
                            .frame(maxWidth: .infinity)
                    }
                }
                .padding(.top, 24)
            }
            
            // Labels
            HStack {
                Text("Easy")
                    .font(AppFonts.label(12))
                    .foregroundColor(Color(hex: "#10B981"))
                
                Spacer()
                
                Text("Maximum")
                    .font(AppFonts.label(12))
                    .foregroundColor(Color(hex: "#E11D48"))
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(AppColors.background)
        )
    }
    
    // MARK: - Effort Zones Section
    private var effortZonesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Effort Zones")
                .font(AppFonts.rounded(18, weight: .bold))
                .foregroundColor(AppColors.textPrimary)
                .opacity(animateItems ? 1.0 : 0)
            
            VStack(spacing: 10) {
                ForEach(Array(rpeScale.enumerated()), id: \.offset) { index, item in
                    RPEZoneCard(
                        range: item.range,
                        label: item.label,
                        description: item.description,
                        color: item.color,
                        icon: item.icon,
                        isExpanded: selectedLevel == index
                    )
                    .onTapGesture {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                            selectedLevel = selectedLevel == index ? nil : index
                        }
                        let impact = UIImpactFeedbackGenerator(style: .light)
                        impact.impactOccurred()
                    }
                    .opacity(animateItems ? 1.0 : 0)
                    .offset(y: animateItems ? 0 : 20)
                    .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(Double(index) * 0.08), value: animateItems)
                }
            }
        }
    }
    
    // MARK: - Tips Section
    private var tipsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Pro Tips")
                .font(AppFonts.rounded(18, weight: .bold))
                .foregroundColor(AppColors.textPrimary)
            
            VStack(alignment: .leading, spacing: 12) {
                RPETipRow(
                    icon: "brain.head.profile",
                    title: "Be Honest",
                    text: "Don't let ego influence your rating. If warmup weight feels heavy, log it.",
                    color: Color(hex: "#7C3AED")
                )
                
                RPETipRow(
                    icon: "chart.line.uptrend.xyaxis",
                    title: "Track Trends",
                    text: "Rising RPE for the same weight = fatigue. Falling RPE = getting stronger.",
                    color: Color(hex: "#0891B2")
                )
                
                RPETipRow(
                    icon: "slider.horizontal.3",
                    title: "Auto-Regulate",
                    text: "If RPE 8 feels like RPE 10, it's okay to reduce the weight.",
                    color: Color(hex: "#D97706")
                )
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(AppColors.background)
        )
        .opacity(animateItems ? 1.0 : 0)
        .offset(y: animateItems ? 0 : 20)
        .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.4), value: animateItems)
    }
}

// MARK: - RPE Zone Card
struct RPEZoneCard: View {
    let range: String
    let label: String
    let description: String
    let color: Color
    let icon: String
    var isExpanded: Bool = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: isExpanded ? 12 : 0) {
            HStack(spacing: 14) {
                // Color indicator
                ZStack {
                    Circle()
                        .fill(color.opacity(0.15))
                        .frame(width: 44, height: 44)
                    
                    Image(systemName: icon)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(color)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text(range)
                            .font(AppFonts.rounded(15, weight: .bold))
                            .foregroundColor(color)
                        
                        Text(label)
                            .font(AppFonts.rounded(15, weight: .semibold))
                            .foregroundColor(AppColors.textPrimary)
                    }
                    
                    if !isExpanded {
                        Text(description)
                            .font(AppFonts.label(13))
                            .foregroundColor(AppColors.textSecondary)
                            .lineLimit(1)
                    }
                }
                
                Spacer()
                
                Image(systemName: "chevron.down")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(AppColors.textTertiary)
                    .rotationEffect(.degrees(isExpanded ? 180 : 0))
            }
            
            if isExpanded {
                Text(description)
                    .font(AppFonts.label(14))
                    .foregroundColor(AppColors.textSecondary)
                    .lineSpacing(4)
                    .padding(.leading, 58)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(color.opacity(0.06))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(color.opacity(isExpanded ? 0.3 : 0.12), lineWidth: 1)
                )
        )
    }
}

// MARK: - RPE Tip Row
struct RPETipRow: View {
    let icon: String
    let title: String
    let text: String
    let color: Color
    
    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [color.opacity(0.2), color.opacity(0.08)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 40, height: 40)
                
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(color)
            }
            .frame(width: 40, height: 40)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(AppFonts.rounded(15, weight: .bold))
                    .foregroundColor(AppColors.textPrimary)
                
                Text(text)
                    .font(AppFonts.label(14))
                    .foregroundColor(AppColors.textSecondary)
                    .lineSpacing(3)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            Spacer(minLength: 0)
        }
    }
}

#Preview {
    RPEInputSheet(rpe: .constant(7.0)) {}
}

