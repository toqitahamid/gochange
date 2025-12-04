import SwiftUI

struct StrainCard: View {
    @ObservedObject var viewModel: FitnessViewModel
    @State private var showInfo = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                Image(systemName: "flame.fill")
                    .foregroundColor(AppColors.warning)
                Text("Strain")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
                
                Button {
                    showInfo = true
                } label: {
                    Image(systemName: "info.circle")
                        .font(.caption)
                        .foregroundColor(.gray.opacity(0.5))
                }
                
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.gray.opacity(0.5))
            }
            
            // Main Score & Status
            HStack(alignment: .bottom) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(String(format: "%.1f", viewModel.strainScore))
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                    
                    Text(viewModel.strainStatus)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(statusColor)
                }
                
                Spacer()
                
                // Target Range Text
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Target: \(Int(viewModel.targetStrainLow))-\(Int(viewModel.targetStrainHigh))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            // Progress Bar with Target Zone
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background Track
                    Capsule()
                        .fill(Color.gray.opacity(0.1))
                        .frame(height: 12)
                    
                    // Target Zone
                    let totalRange: Double = 21.0
                    let lowX = (viewModel.targetStrainLow / totalRange) * geometry.size.width
                    let width = ((viewModel.targetStrainHigh - viewModel.targetStrainLow) / totalRange) * geometry.size.width
                    
                    Capsule()
                        .fill(AppColors.primary.opacity(0.12))
                        .frame(width: max(0, width), height: 12)
                        .offset(x: lowX)
                        .overlay(
                            Capsule()
                                .stroke(AppColors.primary.opacity(0.3), lineWidth: 1)
                                .frame(width: max(0, width), height: 12)
                                .offset(x: lowX)
                        )
                    
                    // Actual Strain Bar
                    let strainWidth = (min(viewModel.strainScore, 21.0) / totalRange) * geometry.size.width
                    
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [AppColors.warning.opacity(0.7), AppColors.warning],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: max(0, strainWidth), height: 12)
                    
                    // Current Indicator Dot (White border for visibility)
                    Circle()
                        .fill(Color.white)
                        .frame(width: 16, height: 16)
                        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
                        .offset(x: max(0, strainWidth - 8))
                }
            }
            .frame(height: 12)
            
            // Insight Text
            Text(insightText)
                .font(.caption)
                .foregroundColor(.secondary)
                .lineLimit(2)
        }
        .padding(20)
        .background(Color.white)
        .cornerRadius(24)
        .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 4)
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(Color.gray.opacity(0.1), lineWidth: 1)
        )
        .sheet(isPresented: $showInfo) {
            StrainInfoSheet()
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
        }
    }
    
    private var statusColor: Color {
        switch viewModel.strainStatus {
        case "Optimal": return AppColors.success
        case "Overreaching": return AppColors.warning
        case "Restoring": return AppColors.primary
        default: return .gray
        }
    }
    
    private var insightText: String {
        switch viewModel.strainStatus {
        case "Optimal":
            return "You're in the optimal training zone. Keep pushing!"
        case "Overreaching":
            return "High strain detected. Consider prioritizing recovery tomorrow."
        case "Restoring":
            return "Light load today. Good for active recovery."
        default:
            return "Keep training to reach your target."
        }
    }
}

#Preview {
    StrainCard(viewModel: FitnessViewModel())
        .padding()
        .background(Color(hex: "#F5F5F7"))
}

struct StrainInfoSheet: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("About Strain Score")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("Strain is measured on a scale of 0 to 21, similar to the Borg Rating of Perceived Exertion. It calculates the total cardiovascular load accumulated throughout the day.")
                    .font(.body)
                    .foregroundColor(.secondary)
                
                VStack(alignment: .leading, spacing: 12) {
                    Text("Scale Breakdown")
                        .font(.headline)
                    
                    scaleItem(range: "0-10", title: "Light", desc: "Rest & Recovery", color: AppColors.primary)
                    scaleItem(range: "10-14", title: "Moderate", desc: "Maintenance", color: AppColors.success)
                    scaleItem(range: "14-18", title: "High", desc: "Building Fitness", color: AppColors.warning)
                    scaleItem(range: "18-21", title: "All Out", desc: "Overreaching", color: AppColors.error)
                }
                .padding(.top, 8)
            }
            .padding(24)
        }
    }
    
    private func scaleItem(range: String, title: String, desc: String, color: Color) -> some View {
        HStack(spacing: 12) {
            Text(range)
                .font(.system(size: 16, weight: .bold, design: .monospaced))
                .foregroundColor(color)
                .frame(width: 60, alignment: .leading)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                Text(desc)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(color.opacity(0.1))
        .cornerRadius(12)
    }
}
