import SwiftUI

struct MetricExplanationSheet: View {
    let metricType: MetricType
    let metric: MetricDefinition
    var currentValue: Double? = nil
    @Environment(\.dismiss) var dismiss
    
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
            Color(hex: "#F5F5F7").ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Drag Indicator
                Capsule()
                    .fill(Color.secondary.opacity(0.2))
                    .frame(width: 40, height: 4)
                    .padding(.top, 12)
                    .padding(.bottom, 20)
                
                ScrollView {
                    VStack(spacing: 32) {
                        // Header Section
                        VStack(spacing: 16) {
                            // Icon & Title Group
                            VStack(spacing: 12) {
                                ZStack {
                                    Circle()
                                        .fill(Color.white)
                                        .frame(width: 80, height: 80)
                                        .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
                                    
                                    Image(systemName: metric.icon)
                                        .font(.system(size: 36))
                                        .foregroundColor(metric.color)
                                }
                                
                                VStack(spacing: 4) {
                                    Text(metric.title)
                                        .font(.system(size: 24, weight: .bold, design: .rounded))
                                        .foregroundColor(.primary)
                                        .multilineTextAlignment(.center)
                                    
                                    Text(metric.subtitle)
                                        .font(.system(size: 17, weight: .medium, design: .rounded))
                                        .foregroundColor(.secondary)
                                        .multilineTextAlignment(.center)
                                }
                            }
                            
                            if let value = currentValue {
                                VStack(spacing: 6) {
                                    Text("\(formatValue(value))\(metric.unit)")
                                        .font(.system(size: 56, weight: .bold, design: .rounded))
                                        .foregroundColor(.primary)
                                    
                                    if let status = getStatus(for: value) {
                                        Text(status.label)
                                            .font(.system(size: 18, weight: .semibold))
                                            .foregroundColor(status.color)
                                            .padding(.horizontal, 16)
                                            .padding(.vertical, 6)
                                            .background(status.color.opacity(0.1))
                                            .clipShape(Capsule())
                                    }
                                }
                                .padding(.top, 8)
                            }
                        }
                        .padding(.top, 20)
                        
                        // Chart & Ranges Section
                        if !metric.ranges.isEmpty {
                            VStack(spacing: 24) {
                                VStack(spacing: 8) {
                                    Text("\(metric.title) ranges")
                                        .font(.system(size: 17, weight: .semibold))
                                    
                                    Text("Standardized ranges based on general fitness benchmarks.")
                                        .font(.system(size: 14))
                                        .foregroundColor(.secondary)
                                        .multilineTextAlignment(.center)
                                        .padding(.horizontal)
                                }
                                
                                // Chart
                                MetricRangeChart(ranges: metric.ranges, currentValue: currentValue)
                                    .frame(height: 60)
                                    .padding(.horizontal, 20)
                                
                                // Range List
                                VStack(spacing: 12) {
                                    ForEach(metric.ranges) { range in
                                        RangeRow(range: range, unit: metric.unit)
                                    }
                                }
                                .padding(.horizontal, 20)
                            }
                            .padding(.vertical, 24)
                            .background(Color.white)
                            .cornerRadius(24)
                            .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
                            .padding(.horizontal, 20)
                        }
                        
                        // Detailed Info Sections
                        VStack(spacing: 24) {
                            InfoSection(
                                title: "What is it?",
                                content: metric.description,
                                icon: "info.circle.fill",
                                color: .blue
                            )
                            
                            StructuredInfoSection(
                                title: "How to use it?",
                                points: metric.howToUse,
                                icon: "lightbulb.fill",
                                color: .yellow
                            )
                            
                            InfoSection(
                                title: "The Math",
                                content: metric.math,
                                icon: "function",
                                color: .purple,
                                isMonospaced: false
                            )
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 40)
                    }
                }
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
    
    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 8) {
                // Value Indicator
                if let value = currentValue {
                    ZStack {
                        // Position calculation
                        let xPosition = calculatePosition(for: value, in: geometry.size.width)
                        
                        Text(String(format: "%.1f", value))
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(indicatorColor(for: value))
                            .cornerRadius(4)
                            .offset(x: xPosition - geometry.size.width / 2)
                            .offset(y: -20) // Above the bar
                        
                        // Dotted Line
                        Rectangle()
                            .fill(indicatorColor(for: value))
                            .frame(width: 1, height: 24) // Connects label to bar
                            .offset(x: xPosition - geometry.size.width / 2)
                            .offset(y: -4)
                    }
                }
                
                // Bar Segments
                HStack(spacing: 2) {
                    ForEach(ranges) { range in
                        Rectangle()
                            .fill(range.color.opacity(0.3))
                            .frame(height: 12)
                            .cornerRadius(4)
                    }
                }
                
                // Current Range Label (Below)
                if let value = currentValue, let range = ranges.first(where: { value >= $0.min && value <= $0.max }) {
                    HStack(spacing: 0) {
                        Text("Your range is ")
                            .font(.system(size: 14))
                            .foregroundColor(.primary)
                        Text(range.label)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(range.color)
                    }
                }
            }
            .frame(maxHeight: .infinity, alignment: .center)
        }
    }
    
    private func calculatePosition(for value: Double, in width: CGFloat) -> CGFloat {
        guard let min = ranges.first?.min, let max = ranges.last?.max else { return 0 }
        let totalRange = max - min
        let percentage = (value - min) / totalRange
        return width * CGFloat(percentage)
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
        HStack {
            Text(range.label)
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(range.color)
            
            Spacer()
            
            Text(rangeText)
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(range.color)
        }
        .padding(16)
        .background(range.color.opacity(0.1))
        .cornerRadius(12)
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
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 14))
                    .foregroundColor(color)
                    .frame(width: 24, height: 24)
                    .background(color.opacity(0.1))
                    .clipShape(Circle())
                
                Text(title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.primary)
            }
            
            VStack(alignment: .leading, spacing: 12) {
                ForEach(points) { point in
                    HStack(alignment: .firstTextBaseline, spacing: 8) {
                        Text("•")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(color)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(point.title)
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(.primary)
                            
                            Text(point.body)
                                .font(.system(size: 15))
                                .foregroundColor(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
            }
            .padding(.leading, 8)
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
    }
}

struct InfoSection: View {
    let title: String
    let content: String
    let icon: String
    let color: Color
    var isMonospaced: Bool = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 14))
                    .foregroundColor(color)
                    .frame(width: 24, height: 24)
                    .background(color.opacity(0.1))
                    .clipShape(Circle())
                
                Text(title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.primary)
            }
            
            Text(content)
                .font(isMonospaced ? .system(size: 14, design: .monospaced) : .system(size: 15))
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)
                .lineSpacing(4)
                .padding(.leading, 32) // Align with title text
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
    }
}

#Preview {
    MetricExplanationSheet(metric: .acwr, currentValue: 1.1)
}

