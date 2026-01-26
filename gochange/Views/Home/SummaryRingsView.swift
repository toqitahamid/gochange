import SwiftUI

import SwiftUI

struct ActivityRingsCard: View {
    let moveCurrent: Int
    let moveTarget: Int
    let exerciseCurrent: Int
    let exerciseTarget: Int
    let standCurrent: Int
    let standTarget: Int
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Activity")
                .font(.headline)
                .foregroundColor(AppColors.textPrimary)
            
            HStack(spacing: 24) {
                // Concentric Rings
                ZStack {
                    // Move (Outer)
                    ActivityRing(
                        progress: Double(moveCurrent) / Double(moveTarget),
                        color: Color(hex: "FF2D55"), // Red
                        diameter: 120,
                        thickness: 12
                    )
                    
                    // Exercise (Middle)
                    ActivityRing(
                        progress: Double(exerciseCurrent) / Double(exerciseTarget),
                        color: Color(hex: "A4FF00"), // Green
                        diameter: 92,
                        thickness: 12
                    )
                    
                    // Stand (Inner)
                    ActivityRing(
                        progress: Double(standCurrent) / Double(standTarget),
                        color: Color(hex: "00F0FF"), // Cyan
                        diameter: 64,
                        thickness: 12
                    )
                }
                .frame(width: 120, height: 120)
                
                // Legend
                VStack(alignment: .leading, spacing: 12) {
                    ActivityLegendRow(
                        icon: "flame.fill",
                        color: Color(hex: "FF2D55"),
                        label: "Move",
                        value: "\(moveCurrent)/\(moveTarget) KCAL"
                    )
                    
                    ActivityLegendRow(
                        icon: "figure.walk",
                        color: Color(hex: "A4FF00"),
                        label: "Exercise",
                        value: "\(exerciseCurrent)/\(exerciseTarget) MIN"
                    )
                    
                    ActivityLegendRow(
                        icon: "arrow.up",
                        color: Color(hex: "00F0FF"),
                        label: "Stand",
                        value: "\(standCurrent)/\(standTarget) HRS"
                    )
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
}

struct ActivityRing: View {
    let progress: Double
    let color: Color
    let diameter: CGFloat
    let thickness: CGFloat
    
    var body: some View {
        ZStack {
            // Background
            Circle()
                .stroke(color.opacity(0.2), lineWidth: thickness)
            
            // Progress
            Circle()
                .trim(from: 0, to: CGFloat(min(progress, 1.0)))
                .stroke(
                    color,
                    style: StrokeStyle(lineWidth: thickness, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .shadow(color: color.opacity(0.5), radius: 4, x: 0, y: 0)
        }
        .frame(width: diameter, height: diameter)
    }
}

struct ActivityLegendRow: View {
    let icon: String
    let color: Color
    let label: String
    let value: String
    
    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(color)
                .frames(width: 20)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
                
                // Parse value for colored vs plain parts
                // Quick hack for colored numbers:
                Text(value)
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundColor(color)
            }
        }
    }
}

// Extension to fix typo in frames -> frame
extension View {
    func frames(width: CGFloat? = nil, height: CGFloat? = nil) -> some View {
        frame(width: width, height: height)
    }
}

#Preview {
    ZStack {
        Color(hex: "F5F5F7").ignoresSafeArea()
        ActivityRingsCard(
            moveCurrent: 500, moveTarget: 600,
            exerciseCurrent: 30, exerciseTarget: 30,
            standCurrent: 10, standTarget: 12
        )
        .padding()
    }
}
