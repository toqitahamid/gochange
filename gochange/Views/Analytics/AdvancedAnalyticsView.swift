import SwiftUI
import Charts
import SwiftData

struct AdvancedAnalyticsView: View {
    @ObservedObject var viewModel: AnalyticsViewModel
    
    @State private var selectedInfoItem: AnalyticsInfoItem?
    
    var body: some View {
        VStack(spacing: 24) {
            // 1RM Trend Chart
            oneRepMaxTrendCard
            
            // ACWR Trend Chart
            acwrTrendCard
            
            // Systemic Load Breakdown
            systemicLoadCard
            
            // Volume vs Intensity Scatter
            volumeIntensityScatterCard
            
            // Muscle Group Split
            muscleGroupSplitCard
        }
        .sheet(item: $selectedInfoItem) { item in
            AnalyticsInfoSheet(item: item)
                .presentationDetents([.medium])
        }
    }
    
    // MARK: - 1RM Trend Chart
    
    private var oneRepMaxTrendCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Estimated 1RM Trend")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Menu {
                        ForEach(viewModel.availableExercisesForTrend, id: \.self) { exercise in
                            Button(exercise) {
                                viewModel.selectedExerciseForTrend = exercise
                            }
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Text(viewModel.selectedExerciseForTrend)
                                .font(.subheadline)
                                .foregroundColor(.blue)
                            Image(systemName: "chevron.down")
                                .font(.caption)
                                .foregroundColor(.blue)
                        }
                    }
                }
                
                Spacer()
                
                InfoButton {
                    selectedInfoItem = .oneRepMax
                }
            }
            
            if viewModel.oneRepMaxData.isEmpty {
                emptyChartState(message: "No data for selected exercise")
            } else {
                Chart {
                    ForEach(viewModel.oneRepMaxData) { point in
                        LineMark(
                            x: .value("Date", point.date),
                            y: .value("1RM", point.oneRepMax)
                        )
                        .foregroundStyle(Color.blue)
                        .interpolationMethod(.catmullRom)
                        .symbol(Circle())
                        
                        AreaMark(
                            x: .value("Date", point.date),
                            y: .value("1RM", point.oneRepMax)
                        )
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color.blue.opacity(0.2), Color.blue.opacity(0.0)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .interpolationMethod(.catmullRom)
                    }
                }
                .frame(height: 200)
                .chartYAxis {
                    AxisMarks(position: .leading)
                }
            }
        }
        .padding(20)
        .background(Color.white)
        .cornerRadius(24)
        .shadow(color: Color.black.opacity(0.08), radius: 15, x: 0, y: 5)
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(Color.gray.opacity(0.15), lineWidth: 1)
        )
    }
    
    // MARK: - Volume vs Intensity Scatter
    
    private var volumeIntensityScatterCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Volume vs. Intensity")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text("Training Density")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                InfoButton {
                    selectedInfoItem = .volumeIntensity
                }
            }
            
            if viewModel.volumeIntensityData.isEmpty {
                emptyChartState(message: "No workout data available")
            } else {
                Chart {
                    ForEach(viewModel.volumeIntensityData) { point in
                        PointMark(
                            x: .value("Volume", point.volume),
                            y: .value("Intensity", point.intensity)
                        )
                        .foregroundStyle(Color(hex: "#00D4AA").opacity(0.6))
                        .symbolSize(50)
                    }
                }
                .frame(height: 200)
                .chartXAxisLabel("Total Volume (lbs)")
                .chartYAxisLabel("Avg Intensity (lbs)")
            }
        }
        .padding(20)
        .background(Color.white)
        .cornerRadius(24)
        .shadow(color: Color.black.opacity(0.08), radius: 15, x: 0, y: 5)
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(Color.gray.opacity(0.15), lineWidth: 1)
        )
    }
    
    // MARK: - Muscle Group Split
    
    private var muscleGroupSplitCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Muscle Group Split")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text("Volume Distribution")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                InfoButton {
                    selectedInfoItem = .muscleSplit
                }
            }
            
            if viewModel.muscleGroupData.isEmpty {
                emptyChartState(message: "No muscle group data")
            } else {
                HStack(spacing: 20) {
                    // Donut Chart
                    Chart(viewModel.muscleGroupData) { item in
                        SectorMark(
                            angle: .value("Volume", item.volume),
                            innerRadius: .ratio(0.6),
                            angularInset: 1.5
                        )
                        .cornerRadius(4)
                        .foregroundStyle(by: .value("Muscle", item.muscleGroup))
                    }
                    .frame(height: 180)
                    .chartLegend(.hidden)
                    
                    // Legend
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(viewModel.muscleGroupData.prefix(5)) { item in
                            HStack(spacing: 6) {
                                Circle()
                                    .fill(Color.gray) // Swift Charts auto-assigns colors, hard to match exactly without manual mapping
                                    // Ideally we'd use a color map, but for simplicity using gray dot or just text
                                    .frame(width: 8, height: 8)
                                
                                Text(item.muscleGroup)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .lineLimit(1)
                                
                                Spacer()
                                
                                Text("\(Int(item.percentage))%")
                                    .font(.caption)
                                    .fontWeight(.bold)
                                    .foregroundColor(.primary)
                            }
                        }
                    }
                    .frame(width: 120)
                }
            }
        }
        .padding(20)
        .background(Color.white)
        .cornerRadius(24)
        .shadow(color: Color.black.opacity(0.08), radius: 15, x: 0, y: 5)
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(Color.gray.opacity(0.15), lineWidth: 1)
        )
    }
    

    
    // MARK: - ACWR Trend Card
    
    private var acwrTrendCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("ACWR Trend")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text("Injury Risk Monitor")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                InfoButton {
                    selectedInfoItem = .acwr
                }
            }
            
            if viewModel.acwrData.isEmpty {
                emptyChartState(message: "Not enough data for ACWR")
            } else {
                Chart {
                    ForEach(viewModel.acwrData) { point in
                        // Sweet Spot Zone (0.8 - 1.3)
                        RectangleMark(
                            xStart: .value("Date", point.date),
                            xEnd: .value("Date", point.date), // Width handled by bar width or implicit
                            yStart: .value("Low", 0.8),
                            yEnd: .value("High", 1.3)
                        )
                        .foregroundStyle(Color.green.opacity(0.1))
                        
                        LineMark(
                            x: .value("Date", point.date),
                            y: .value("Ratio", point.ratio)
                        )
                        .foregroundStyle(acwrColor(for: point.ratio))
                        .interpolationMethod(.catmullRom)
                        
                        PointMark(
                            x: .value("Date", point.date),
                            y: .value("Ratio", point.ratio)
                        )
                        .foregroundStyle(acwrColor(for: point.ratio))
                        .symbolSize(20)
                    }
                }
                .frame(height: 200)
                .chartYAxis {
                    AxisMarks(position: .leading)
                }
            }
        }
        .padding(20)
        .background(Color.white)
        .cornerRadius(24)
        .shadow(color: Color.black.opacity(0.08), radius: 15, x: 0, y: 5)
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(Color.gray.opacity(0.15), lineWidth: 1)
        )
    }
    
    private func acwrColor(for ratio: Double) -> Color {
        if ratio >= 0.8 && ratio <= 1.3 { return .green }
        if ratio > 1.5 { return .red }
        return .orange
    }
    
    // MARK: - Systemic Load Card
    
    private var systemicLoadCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Systemic Load")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text("Cardio vs Strength")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                InfoButton {
                    selectedInfoItem = .systemicLoad
                }
            }
            
            if viewModel.systemicLoadData.isEmpty {
                emptyChartState(message: "No load data available")
            } else {
                Chart {
                    ForEach(viewModel.systemicLoadData) { point in
                        BarMark(
                            x: .value("Date", point.date, unit: .day),
                            y: .value("Load", point.strengthLoad)
                        )
                        .foregroundStyle(Color.blue)
                        .annotation(position: .overlay) {
                            Text("S")
                                .font(.caption2)
                                .foregroundColor(.white.opacity(0.5))
                        }
                        
                        BarMark(
                            x: .value("Date", point.date, unit: .day),
                            y: .value("Load", point.cardioLoad)
                        )
                        .foregroundStyle(Color.orange)
                        .annotation(position: .overlay) {
                            Text("C")
                                .font(.caption2)
                                .foregroundColor(.white.opacity(0.5))
                        }
                    }
                }
                .frame(height: 200)
            }
        }
        .padding(20)
        .background(Color.white)
        .cornerRadius(24)
        .shadow(color: Color.black.opacity(0.08), radius: 15, x: 0, y: 5)
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(Color.gray.opacity(0.15), lineWidth: 1)
        )
    }

    private func emptyChartState(message: String) -> some View {
        VStack(spacing: 12) {
            Image(systemName: "chart.bar.xaxis")
                .font(.system(size: 30))
                .foregroundColor(.gray.opacity(0.3))
            Text(message)
                .font(.caption)
                .foregroundColor(.gray)
        }
        .frame(height: 200)
        .frame(maxWidth: .infinity)
        .background(Color.gray.opacity(0.05))
        .cornerRadius(12)
    }
}

// MARK: - Info Button & Sheet

struct InfoButton: View {
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Image(systemName: "info.circle")
                .font(.system(size: 20))
                .foregroundColor(.gray.opacity(0.6))
        }
    }
}

enum AnalyticsInfoItem: Identifiable {
    case oneRepMax
    case volumeIntensity
    case muscleSplit
    case acwr
    case systemicLoad
    
    var id: Self { self }
    
    var title: String {
        switch self {
        case .oneRepMax: return "Estimated 1RM"
        case .volumeIntensity: return "Volume vs. Intensity"
        case .muscleSplit: return "Muscle Group Split"
        case .acwr: return "ACWR Trend"
        case .systemicLoad: return "Systemic Load"
        }
    }
    
    var description: String {
        switch self {
        case .oneRepMax:
            return "Your Estimated One Rep Max (1RM) is calculated using the Epley formula based on your best sets. It represents the theoretical maximum weight you could lift for one repetition. Tracking this helps you gauge strength gains over time without testing your true max frequently."
        case .volumeIntensity:
            return "This scatter plot shows the relationship between your total workout volume (Total Weight Moved) and average intensity (Average Weight per Rep). High volume with high intensity indicates a very demanding workout, while low volume with low intensity suggests a recovery session."
        case .muscleSplit:
            return "This chart breaks down your total training volume by muscle group. A balanced distribution helps prevent muscle imbalances and ensures overall physique development. Use this to identify lagging body parts that may need more focus."
        case .acwr:
            return "Acute:Chronic Workload Ratio tracks your injury risk. The 'Sweet Spot' is 0.8-1.3. Spikes above 1.5 indicate you are increasing load too quickly ('Too Much, Too Soon')."
        case .systemicLoad:
            return "Total Systemic Load combines stress from Cardio (TRIMP) and Strength (Volume Load). This helps you manage your overall fatigue and recovery, especially for hybrid training."
        }
    }
    
    var icon: String {
        switch self {
        case .oneRepMax: return "trophy.fill"
        case .volumeIntensity: return "chart.xyaxis.line"
        case .muscleSplit: return "figure.mixed.cardio"
        case .acwr: return "shield.fill"
        case .systemicLoad: return "chart.bar.fill"
        }
    }
}

struct AnalyticsInfoSheet: View {
    let item: AnalyticsInfoItem
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        VStack(spacing: 24) {
            Capsule()
                .fill(Color.gray.opacity(0.2))
                .frame(width: 40, height: 4)
                .padding(.top, 10)
            
            Image(systemName: item.icon)
                .font(.system(size: 48))
                .foregroundColor(Color(hex: "#00D4AA"))
                .padding(.top, 20)
            
            VStack(spacing: 8) {
                Text(item.title)
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text(item.description)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
            }
            
            Spacer()
            
            Button {
                dismiss()
            } label: {
                Text("Got it")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color(hex: "#00D4AA"))
                    .cornerRadius(16)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 24)
        }
    }
}
