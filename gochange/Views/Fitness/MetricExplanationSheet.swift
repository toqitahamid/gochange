import SwiftUI

struct MetricExplanationSheet: View {
    let metricType: MetricType
    let metric: MetricDefinition
    var currentValue: Double? = nil
    @Environment(\.dismiss) var dismiss
    @State private var animateHeader = false
    @State private var animateValue = false
    @State private var animateChart = false
    @State private var animateSections = false

    init(metric: MetricType, currentValue: Double? = nil) {
        self.metricType = metric
        self.metric = MetricFactory.make(for: metric)
        self.currentValue = currentValue
    }

    enum MetricType: Identifiable {
        var id: Self { self }
        case readiness
        case acwr
        case e1rm
        case systemicLoad
        case sleepDebt
        case rpe
        case volumeIntensity
        case muscleSplit
    }

    var body: some View {
        ZStack {
            Color.white.ignoresSafeArea()

            GeometryReader { geometry in
                VStack(spacing: 0) {
                    // Header with Close Button and Drag Indicator
                    ZStack(alignment: .top) {
                        // Drag Indicator (centered at top)
                        VStack(spacing: 0) {
                            Capsule()
                                .fill(Color.secondary.opacity(0.3))
                                .frame(width: 36, height: 5)
                            Spacer()
                        }

                        // Close Button (left aligned, positioned lower)
                        HStack(alignment: .top) {
                            Button {
                                dismiss()
                            } label: {
                                ZStack {
                                    Circle()
                                        .fill(Color(UIColor.tertiarySystemFill))
                                        .frame(width: 36, height: 36)

                                    Image(systemName: "xmark")
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundColor(.secondary)
                                }
                            }
                            .padding(.top, 32)

                            Spacer()
                        }
                        .padding(.horizontal, 20)
                    }
                    .frame(height: 72)
                    .padding(.top, 4)

                    ScrollView(.vertical, showsIndicators: false) {
                        VStack(spacing: 28) {
                        // Header Section
                        VStack(spacing: 20) {
                            // Icon & Title Group
                            VStack(spacing: 16) {
                                // Modern icon with subtle gradient and enhanced shadow
                                ZStack {
                                    Circle()
                                        .fill(
                                            LinearGradient(
                                                colors: [
                                                    metric.color.opacity(0.08),
                                                    metric.color.opacity(0.04)
                                                ],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )
                                        .frame(width: 96, height: 96)
                                        .shadow(color: metric.color.opacity(0.15), radius: 20, x: 0, y: 10)

                                    Image(systemName: metric.icon)
                                        .font(.system(size: 44, weight: .semibold))
                                        .foregroundStyle(
                                            LinearGradient(
                                                colors: [metric.color, metric.color.opacity(0.7)],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )
                                        .symbolEffect(.bounce, value: animateHeader)
                                }
                                .scaleEffect(animateHeader ? 1.0 : 0.85)
                                .opacity(animateHeader ? 1.0 : 0)

                                VStack(spacing: 6) {
                                    Text(metric.title)
                                        .font(.system(size: 30, weight: .bold, design: .rounded))
                                        .foregroundColor(.primary)
                                        .multilineTextAlignment(.center)

                                    Text(metric.subtitle)
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundColor(.secondary)
                                        .multilineTextAlignment(.center)
                                }
                                .opacity(animateHeader ? 1.0 : 0)
                                .offset(y: animateHeader ? 0 : 10)
                            }

                            if let value = currentValue {
                                VStack(spacing: 12) {
                                    Text("\(formatValue(value))\(metric.unit)")
                                        .font(.system(size: 68, weight: .bold, design: .rounded))
                                        .foregroundStyle(
                                            LinearGradient(
                                                colors: [metric.color, metric.color.opacity(0.8)],
                                                startPoint: .leading,
                                                endPoint: .trailing
                                            )
                                        )
                                        .scaleEffect(animateValue ? 1.0 : 0.9)
                                        .opacity(animateValue ? 1.0 : 0)

                                    if let status = getStatus(for: value) {
                                        HStack(spacing: 8) {
                                            Circle()
                                                .fill(status.color)
                                                .frame(width: 8, height: 8)
                                                .shadow(color: status.color.opacity(0.5), radius: 4, x: 0, y: 2)

                                            Text(status.label)
                                                .font(.system(size: 17, weight: .semibold))
                                                .foregroundColor(status.color)
                                        }
                                        .padding(.horizontal, 24)
                                        .padding(.vertical, 12)
                                        .background(
                                            Capsule()
                                                .fill(status.color.opacity(0.12))
                                                .shadow(color: status.color.opacity(0.2), radius: 12, x: 0, y: 6)
                                        )
                                        .opacity(animateValue ? 1.0 : 0)
                                        .scaleEffect(animateValue ? 1.0 : 0.95)
                                    }
                                }
                                .padding(.top, 12)
                            }
                        }
                        .padding(.top, 8)
                        
                        // Chart & Ranges Section
                        if !metric.ranges.isEmpty {
                            VStack(spacing: 24) {
                                VStack(spacing: 10) {
                                    Text("\(metric.title) Ranges")
                                        .font(.system(size: 20, weight: .bold, design: .rounded))
                                        .foregroundColor(.primary)

                                    Text("Standardized ranges based on general fitness benchmarks")
                                        .font(.system(size: 15))
                                        .foregroundColor(.secondary)
                                        .multilineTextAlignment(.center)
                                        .padding(.horizontal)
                                }

                                // Chart
                                MetricRangeChart(ranges: metric.ranges, currentValue: currentValue)
                                    .frame(height: 70)
                                    .padding(.horizontal, 24)
                                    .opacity(animateChart ? 1.0 : 0)
                                    .offset(y: animateChart ? 0 : 10)

                                // Range List
                                VStack(spacing: 10) {
                                    ForEach(Array(metric.ranges.enumerated()), id: \.element.id) { index, range in
                                        RangeRow(range: range, unit: metric.unit)
                                            .opacity(animateChart ? 1.0 : 0)
                                            .offset(y: animateChart ? 0 : 10)
                                            .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(Double(index) * 0.08), value: animateChart)
                                    }
                                }
                                .padding(.horizontal, 24)
                            }
                            .padding(.vertical, 28)
                            .background(
                                RoundedRectangle(cornerRadius: 24, style: .continuous)
                                    .fill(Color(hex: "#FAFBFC"))
                                    .shadow(color: Color.black.opacity(0.04), radius: 12, x: 0, y: 6)
                            )
                            .padding(.horizontal, 20)
                        }

                        // Detailed Info Sections
                        VStack(spacing: 20) {
                            InfoSection(
                                title: "What is it?",
                                content: metric.description,
                                icon: "info.circle.fill",
                                color: .blue,
                                isAnimated: animateSections
                            )

                            StructuredInfoSection(
                                title: "How to use it?",
                                points: metric.howToUse,
                                icon: "lightbulb.fill",
                                color: .orange,
                                isAnimated: animateSections
                            )

                            InfoSection(
                                title: "The Math",
                                content: metric.math,
                                icon: "function",
                                color: .purple,
                                isMonospaced: false,
                                isAnimated: animateSections
                            )
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 40)
                        }
                        .frame(width: geometry.size.width)
                    }
                    .scrollBounceBehavior(.basedOnSize, axes: .horizontal)
                }
                .frame(width: geometry.size.width, height: geometry.size.height)
            }
            .clipped()

        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.75)) {
                animateHeader = true
            }
            withAnimation(.spring(response: 0.6, dampingFraction: 0.75).delay(0.15)) {
                animateValue = true
            }
            withAnimation(.spring(response: 0.6, dampingFraction: 0.75).delay(0.3)) {
                animateChart = true
            }
            withAnimation(.spring(response: 0.6, dampingFraction: 0.75).delay(0.45)) {
                animateSections = true
            }
        }
    }
    
    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy"
        return formatter.string(from: Date())
    }
    
    private func formatValue(_ value: Double) -> String {
        if value.truncatingRemainder(dividingBy: 1) == 0 {
            return String(format: "%.0f", value)
        } else {
            return String(format: "%.1f", value)
        }
    }
    
    private func getStatus(for value: Double) -> MetricRange? {
        return metric.ranges.first { value >= $0.min && value <= $0.max }
    }
}

// MARK: - Range Chart
struct MetricRangeChart: View {
    let ranges: [MetricRange]
    let currentValue: Double?
    @State private var animateIndicator = false

    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 12) {
                // Value Indicator
                if let value = currentValue {
                    ZStack {
                        let xPosition = calculatePosition(for: value, in: geometry.size.width)

                        // Enhanced value label with shadow
                        Text(String(format: "%.1f", value))
                            .font(.system(size: 13, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(
                                Capsule()
                                    .fill(indicatorColor(for: value))
                                    .shadow(color: indicatorColor(for: value).opacity(0.4), radius: 8, x: 0, y: 4)
                            )
                            .offset(x: xPosition - geometry.size.width / 2)
                            .offset(y: -24)
                            .scaleEffect(animateIndicator ? 1.0 : 0.9)
                            .opacity(animateIndicator ? 1.0 : 0)

                        // Dotted Line
                        Rectangle()
                            .fill(indicatorColor(for: value))
                            .frame(width: 2, height: 20)
                            .offset(x: xPosition - geometry.size.width / 2)
                            .offset(y: -8)
                            .opacity(animateIndicator ? 0.6 : 0)
                    }
                }

                // Modern Bar Segments with rounded ends
                HStack(spacing: 3) {
                    ForEach(Array(ranges.enumerated()), id: \.element.id) { index, range in
                        ZStack(alignment: .leading) {
                            // Background
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .fill(range.color.opacity(0.15))
                                .frame(height: 16)

                            // Gradient overlay
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            range.color.opacity(0.4),
                                            range.color.opacity(0.25)
                                        ],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )
                                .frame(height: 16)

                            // Current value indicator within segment
                            if let value = currentValue,
                               value >= range.min && value <= range.max {
                                Circle()
                                    .fill(range.color)
                                    .frame(width: 8, height: 8)
                                    .shadow(color: range.color.opacity(0.5), radius: 4, x: 0, y: 2)
                                    .offset(x: calculateLocalPosition(for: value, in: range, width: geometry.size.width / CGFloat(ranges.count)))
                                    .scaleEffect(animateIndicator ? 1.0 : 0.5)
                            }
                        }
                    }
                }

                // Current Range Label
                if let value = currentValue, let range = ranges.first(where: { value >= $0.min && value <= $0.max }) {
                    HStack(spacing: 4) {
                        Text("Your range:")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(.secondary)
                        Text(range.label)
                            .font(.system(size: 15, weight: .bold, design: .rounded))
                            .foregroundColor(range.color)
                    }
                    .opacity(animateIndicator ? 1.0 : 0)
                }
            }
            .frame(maxHeight: .infinity, alignment: .center)
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.2)) {
                animateIndicator = true
            }
        }
    }

    private func calculatePosition(for value: Double, in width: CGFloat) -> CGFloat {
        guard let min = ranges.first?.min, let max = ranges.last?.max else { return 0 }
        let totalRange = max - min
        let percentage = (value - min) / totalRange
        return width * CGFloat(percentage)
    }

    private func calculateLocalPosition(for value: Double, in range: MetricRange, width: CGFloat) -> CGFloat {
        let rangeSpan = range.max - range.min
        let valueInRange = value - range.min
        let percentage = valueInRange / rangeSpan
        return width * CGFloat(percentage) - 4 // Center the circle
    }

    private func indicatorColor(for value: Double) -> Color {
        ranges.first { value >= $0.min && value <= $0.max }?.color ?? .gray
    }
}

// MARK: - Range Row
struct RangeRow: View {
    let range: MetricRange
    let unit: String

    var body: some View {
        HStack(spacing: 12) {
            // Color indicator
            Circle()
                .fill(
                    LinearGradient(
                        colors: [range.color, range.color.opacity(0.8)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 10, height: 10)
                .shadow(color: range.color.opacity(0.3), radius: 4, x: 0, y: 2)

            Text(range.label)
                .font(.system(size: 16, weight: .semibold, design: .rounded))
                .foregroundColor(.primary)

            Spacer()

            Text(rangeText)
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundColor(range.color)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(range.color.opacity(0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(range.color.opacity(0.2), lineWidth: 1)
                )
        )
    }

    private var rangeText: String {
        if range.max > 1000 {
            return "> \(format(range.min))"
        } else if range.min == 0 {
            return "< \(format(range.max))"
        } else {
            return "\(format(range.min)) - \(format(range.max))"
        }
    }

    private func format(_ value: Double) -> String {
        if value.truncatingRemainder(dividingBy: 1) == 0 {
            return String(format: "%.0f", value)
        } else {
            return String(format: "%.1f", value)
        }
    }
}

struct StructuredInfoSection: View {
    let title: String
    let points: [MetricPoint]
    let icon: String
    let color: Color
    var isAnimated: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [color.opacity(0.15), color.opacity(0.08)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 36, height: 36)

                    Image(systemName: icon)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(color)
                }

                Text(title)
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
            }

            // Content
            VStack(alignment: .leading, spacing: 16) {
                ForEach(Array(points.enumerated()), id: \.element.id) { index, point in
                    HStack(alignment: .firstTextBaseline, spacing: 12) {
                        // Modern bullet point
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [color, color.opacity(0.7)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 6, height: 6)
                            .padding(.top, 6)

                        VStack(alignment: .leading, spacing: 4) {
                            Text(point.title)
                                .font(.system(size: 16, weight: .semibold, design: .rounded))
                                .foregroundColor(.primary)

                            Text(point.body)
                                .font(.system(size: 15))
                                .foregroundColor(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                                .lineSpacing(2)
                        }
                    }
                    .opacity(isAnimated ? 1.0 : 0)
                    .offset(x: isAnimated ? 0 : -10)
                    .animation(.spring(response: 0.5, dampingFraction: 0.75).delay(Double(index) * 0.1), value: isAnimated)
                }
            }
            .padding(.leading, 4)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color(hex: "#FAFBFC"))
                .shadow(color: Color.black.opacity(0.04), radius: 12, x: 0, y: 6)
        )
        .opacity(isAnimated ? 1.0 : 0)
        .scaleEffect(isAnimated ? 1.0 : 0.98)
    }
}

struct InfoSection: View {
    let title: String
    let content: String
    let icon: String
    let color: Color
    var isMonospaced: Bool = false
    var isAnimated: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [color.opacity(0.15), color.opacity(0.08)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 36, height: 36)

                    Image(systemName: icon)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(color)
                }

                Text(title)
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
            }

            // Content
            Text(content)
                .font(isMonospaced ? .system(size: 15, design: .monospaced) : .system(size: 15))
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)
                .lineSpacing(6)
                .padding(.leading, 4)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color(hex: "#FAFBFC"))
                .shadow(color: Color.black.opacity(0.04), radius: 12, x: 0, y: 6)
        )
        .opacity(isAnimated ? 1.0 : 0)
        .scaleEffect(isAnimated ? 1.0 : 0.98)
    }
}

#Preview {
    MetricExplanationSheet(metric: .acwr, currentValue: 1.1)
}

