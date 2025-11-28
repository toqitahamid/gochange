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
        
        var title: String {
            switch self {
            case .readiness: return "Daily Readiness Score"
            case .acwr: return "Acute:Chronic Workload Ratio"
            case .e1rm: return "Estimated 1RM"
            case .systemicLoad: return "Total Systemic Load"
            case .sleepDebt: return "Sleep Debt"
            }
        }
        
        var subtitle: String {
            switch self {
            case .readiness: return "The Governor"
            case .acwr: return "The Shield"
            case .e1rm: return "The Progress"
            case .systemicLoad: return "The Context"
            case .sleepDebt: return "Reality Check"
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
            }
        }
        
        var formula: String {
            switch self {
            case .readiness: return "(HRV_Z × 0.4) + (Sleep_Z × 0.4) - (RHR_Z × 0.2)"
            case .acwr: return "Acute Load (7-day EWMA) / Chronic Load (28-day EWMA)"
            case .e1rm: return "Brzycki (<10 reps) or Epley (>10 reps)"
            case .systemicLoad: return "Cardio Load + (Duration × RPE)"
            case .sleepDebt: return "Σ (Sleep Need - Actual Sleep) over 14 days"
            }
        }
        
        var icon: String {
            switch self {
            case .readiness: return "bolt.heart.fill"
            case .acwr: return "shield.fill"
            case .e1rm: return "dumbbell.fill"
            case .systemicLoad: return "chart.bar.fill"
            case .sleepDebt: return "bed.double.fill"
            }
        }
        
        var color: Color {
            switch self {
            case .readiness: return .blue
            case .acwr: return .green
            case .e1rm: return .orange
            case .systemicLoad: return .purple
            case .sleepDebt: return .indigo
            }
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Spacer()
                Capsule()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 40, height: 4)
                Spacer()
            }
            .padding(.top, 12)
            .padding(.bottom, 20)
            
            ScrollView {
                VStack(spacing: 24) {
                    // Icon & Title
                    VStack(spacing: 12) {
                        Image(systemName: metric.icon)
                            .font(.system(size: 48))
                            .foregroundColor(metric.color)
                            .padding()
                            .background(metric.color.opacity(0.1))
                            .clipShape(Circle())
                        
                        VStack(spacing: 4) {
                            Text(metric.title)
                                .font(.title2)
                                .fontWeight(.bold)
                                .multilineTextAlignment(.center)
                            
                            Text(metric.subtitle)
                                .font(.headline)
                                .foregroundColor(.secondary)
                                .fontWeight(.medium)
                        }
                    }
                    
                    Divider()
                    
                    // Sections
                    VStack(alignment: .leading, spacing: 24) {
                        InfoSection(title: "What is it?", content: metric.description)
                        InfoSection(title: "How to use it?", content: metric.howToUse)
                        InfoSection(title: "The Math", content: metric.formula, isMonospaced: true)
                    }
                    .padding(.horizontal)
                }
                .padding(.bottom, 30)
            }
            
            // Close Button
            Button {
                dismiss()
            } label: {
                Text("Got it")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(metric.color)
                    .cornerRadius(16)
            }
            .padding(20)
        }
        .background(Color.white)
    }
}

struct InfoSection: View {
    let title: String
    let content: String
    var isMonospaced: Bool = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
            Text(content)
                .font(isMonospaced ? .system(.body, design: .monospaced) : .body)
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}
