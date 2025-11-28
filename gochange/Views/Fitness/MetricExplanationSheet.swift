import SwiftUI

struct MetricExplanationSheet: View {
    let metric: MetricType
    @Environment(\.dismiss) var dismiss
    
    enum MetricType: Identifiable {
        var id: Self { self }
        case readiness
        case acwr
        case e1rm
        case systemicLoad
        case sleepDebt
        case rpe
        
        var title: String {
            switch self {
            case .readiness: return "Daily Readiness Score"
            case .acwr: return "Acute:Chronic Workload Ratio"
            case .e1rm: return "Estimated 1RM"
            case .systemicLoad: return "Total Systemic Load"
            case .sleepDebt: return "Sleep Debt"
            case .rpe: return "Rate of Perceived Exertion"
            }
        }
        
        var subtitle: String {
            switch self {
            case .readiness: return "The Governor"
            case .acwr: return "The Shield"
            case .e1rm: return "The Progress"
            case .systemicLoad: return "The Context"
            case .sleepDebt: return "Reality Check"
            case .rpe: return "The Internal Load"
            }
        }
        
        var description: String {
            switch self {
            case .readiness:
                return "A composite score (0-100%) based on your Heart Rate Variability (HRV), Resting Heart Rate (RHR), and Sleep Quality relative to your 30-day baseline."
            case .acwr:
                return "The ratio of your recent training load (last 7 days) to your chronic training load (last 28 days). It helps prevent injury by flagging if you are doing 'too much, too soon'."
            case .e1rm:
                return "A theoretical calculation of the maximum weight you could lift for one repetition, based on your submaximal lifts (weight × reps)."
            case .systemicLoad:
                return "A combined measure of cardiovascular stress (TRIMP) and muscular stress (Volume × RPE). It quantifies the total toll a workout takes on your body."
            case .sleepDebt:
                return "The cumulative difference between your sleep need (default 8h) and your actual sleep over the last 14 days."
            case .rpe:
                return "A subjective measure of how hard you felt your workout was, on a scale of 1-10. It captures the internal physiological and psychological stress of a session."
            }
        }
        
        var howToUse: String {
            switch self {
            case .readiness:
                return "• 80-100%: Prime time. Go for a PR.\n• 40-80%: Train as planned.\n• <40%: Your CNS is fried. Reduce volume by 15-30% or take a rest day."
            case .acwr:
                return "• 0.8 – 1.3: The 'Sweet Spot'. Optimal for progress.\n• > 1.5: Danger Zone. High injury risk.\n• < 0.8: Undertraining."
            case .e1rm:
                return "Use this to track strength gains without the risk of testing a true 1RM. If your e1RM goes up, you are getting stronger."
            case .systemicLoad:
                return "Use this to balance your training. If yesterday's load was very high, consider a lighter session today to manage fatigue."
            case .sleepDebt:
                return "If debt > 5 hours, your recovery is compromised. Prioritize sleep or reduce training intensity until the debt is cleared."
            case .rpe:
                return "Be honest. Use it to track internal load over time. A high RPE with low external load (weight) can indicate fatigue or illness."
            }
        }
        
        var formula: String {
            switch self {
            case .readiness: return "(HRV_Z × 0.4) + (Sleep_Z × 0.4) - (RHR_Z × 0.2)"
            case .acwr: return "Acute Load (7-day EWMA) / Chronic Load (28-day EWMA)"
            case .e1rm: return "Brzycki (<10 reps) or Epley (≥10 reps)"
            case .systemicLoad: return "Cardio Load + (Duration × RPE)"
            case .sleepDebt: return "Σ (Sleep Need - Actual Sleep) over 14 days"
            case .rpe: return "User Input (1-10)"
            }
        }
        
        var icon: String {
            switch self {
            case .readiness: return "bolt.heart.fill"
            case .acwr: return "shield.fill"
            case .e1rm: return "dumbbell.fill"
            case .systemicLoad: return "chart.bar.fill"
            case .sleepDebt: return "bed.double.fill"
            case .rpe: return "gauge.with.needle.fill"
            }
        }
        
        var color: Color {
            switch self {
            case .readiness: return .blue
            case .acwr: return .green
            case .e1rm: return .orange
            case .systemicLoad: return .purple
            case .sleepDebt: return .indigo
            case .rpe: return .yellow
            }
        }
        
        var gradient: LinearGradient {
            LinearGradient(
                colors: [color.opacity(0.8), color],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }
    
    var body: some View {
        ZStack {
            Color(UIColor.systemBackground).ignoresSafeArea()
            
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
                            // Icon
                            ZStack {
                                Circle()
                                    .fill(metric.gradient)
                                    .frame(width: 88, height: 88)
                                    .shadow(color: metric.color.opacity(0.3), radius: 15, x: 0, y: 8)
                                
                                Image(systemName: metric.icon)
                                    .font(.system(size: 40))
                                    .foregroundColor(.white)
                            }
                            
                            // Titles
                            VStack(spacing: 6) {
                                Text(metric.title)
                                    .font(.system(size: 24, weight: .bold, design: .rounded))
                                    .multilineTextAlignment(.center)
                                    .foregroundColor(.primary)
                                
                                Text(metric.subtitle)
                                    .font(.system(size: 16, weight: .medium, design: .rounded))
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(.top, 10)
                        
                        // Content Sections
                        VStack(spacing: 24) {
                            InfoSection(
                                title: "What is it?",
                                content: metric.description,
                                icon: "info.circle.fill",
                                color: .blue
                            )
                            
                            InfoSection(
                                title: "How to use it?",
                                content: metric.howToUse,
                                icon: "lightbulb.fill",
                                color: .yellow
                            )
                            
                            InfoSection(
                                title: "The Math",
                                content: metric.formula,
                                icon: "function",
                                color: .purple,
                                isMonospaced: true
                            )
                        }
                        .padding(.horizontal, 20)
                    }
                    .padding(.bottom, 100) // Space for button
                }
            }
            
            // Floating Bottom Button
            VStack {
                Spacer()
                Button {
                    dismiss()
                } label: {
                    Text("Got it")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(metric.gradient)
                        .cornerRadius(28)
                        .shadow(color: metric.color.opacity(0.3), radius: 10, x: 0, y: 5)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 30)
            }
        }
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
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(16)
    }
}

#Preview {
    MetricExplanationSheet(metric: .readiness)
}

