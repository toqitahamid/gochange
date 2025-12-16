import SwiftUI

// MARK: - Protocol Definition
protocol MetricDefinition {
    var title: String { get }
    var subtitle: String { get }
    var description: String { get }
    var howToUse: [MetricPoint] { get } // Changed from String
    var math: String { get } // Renamed from 'formula' for broader context
    var unit: String { get }
    var icon: String { get }
    var color: Color { get }
    var ranges: [MetricRange] { get }
    
    // Helper for gradient
    var gradient: LinearGradient { get }
}

extension MetricDefinition {
    var gradient: LinearGradient {
        LinearGradient(
            colors: [color.opacity(0.8), color],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

struct MetricRange: Identifiable {
    let id = UUID()
    let label: String
    let min: Double
    let max: Double
    let color: Color
    
    var isUnboundedMax: Bool { max > 1000 }
}

struct MetricPoint: Identifiable {
    let id = UUID()
    let title: String
    let body: String
}

// MARK: - Concrete Implementations

struct ReadinessMetric: MetricDefinition {
    let title = "Daily Readiness"
    let subtitle = "Recovery Status"
    let unit = "%"
    let icon = "bolt.heart.fill"
    let color = Color.blue
    
    let description = """
    Your Daily Readiness Score is a comprehensive measure of your body's capacity to take on strain today. It is calculated by analyzing your Heart Rate Variability (HRV), Resting Heart Rate (RHR), and Sleep Quality relative to your own 30-day baseline.
    
    A high score indicates your autonomic nervous system is balanced and you are primed for high-intensity training. A low score suggests your body is fighting stress, illness, or fatigue, and you should prioritize recovery.
    """
    
    let howToUse: [MetricPoint] = [
        MetricPoint(title: "80-100% (Prime)", body: "Your body is fully recovered. This is the best time to attempt a PR or a high-intensity workout."),
        MetricPoint(title: "40-80% (Ready)", body: "You are in a normal training state. Stick to your planned workout volume and intensity."),
        MetricPoint(title: "<40% (Low)", body: "Your Central Nervous System (CNS) is fatigued. Consider reducing your training volume by 15-30%, doing an active recovery session, or taking a complete rest day.")
    ]
    
    let math = """
    (HRV_Z × 0.4) + (Sleep_Z × 0.4) - (RHR_Z × 0.2)
    
    We use Z-scores (standard deviations from your mean) to normalize your data. This ensures the score is personalized to *your* physiology, not a generic average.
    """
    
    let ranges: [MetricRange] = [
        MetricRange(label: "Low", min: 0, max: 40, color: Color(hex: "#FF6B6B")),
        MetricRange(label: "Steady", min: 40, max: 70, color: Color(hex: "#FFD60A")),
        MetricRange(label: "Ready", min: 70, max: 85, color: Color(hex: "#34C759")),
        MetricRange(label: "Prime", min: 85, max: 100, color: Color(hex: "#007AFF"))
    ]
}

struct ACWRMetric: MetricDefinition {
    let title = "ACWR"
    let subtitle = "Acute:Chronic Workload Ratio"
    let unit = ""
    let icon = "shield.fill"
    let color = Color.green
    
    let description = """
    The Acute:Chronic Workload Ratio (ACWR) is the gold standard for injury prevention in sports science. It compares your short-term fatigue (Acute Load, last 7 days) to your long-term fitness (Chronic Load, last 28 days).
    
    It answers the question: "Am I doing too much, too soon?" keeping you in the sweet spot where you gain fitness without breaking down.
    """
    
    let howToUse: [MetricPoint] = [
        MetricPoint(title: "0.8 – 1.3 (Optimal)", body: "The \"Sweet Spot\". Your training load is increasing at a safe, sustainable rate. This is where fitness gains happen with minimal injury risk."),
        MetricPoint(title: "> 1.5 (Danger Zone)", body: "You have spiked your volume too quickly. Injury risk increases significantly (up to 2-4x). Deload immediately."),
        MetricPoint(title: "< 0.8 (Undertraining)", body: "You are doing significantly less than you are used to. You may be losing fitness (detraining).")
    ]
    
    let math = """
    Acute Load (7-day EWMA) / Chronic Load (28-day EWMA)
    
    We use Exponentially Weighted Moving Averages (EWMA) rather than simple rolling averages. This gives more weight to recent sessions, making the metric more responsive to sudden changes in your training.
    """
    
    let ranges: [MetricRange] = [
        MetricRange(label: "Low", min: 0, max: 0.8, color: Color(hex: "#64D2FF")),
        MetricRange(label: "Optimal", min: 0.8, max: 1.3, color: Color(hex: "#34C759")),
        MetricRange(label: "High", min: 1.3, max: 1.5, color: Color(hex: "#FFD60A")),
        MetricRange(label: "Danger", min: 1.5, max: 3.0, color: Color(hex: "#FF6B6B"))
    ]
}

struct SleepDebtMetric: MetricDefinition {
    let title = "Sleep Debt"
    let subtitle = "Sleep Balance"
    let unit = "h"
    let icon = "bed.double.fill"
    let color = Color.indigo
    
    let description = """
    Sleep Debt tracks the cumulative difference between your biological sleep need (defaulting to 8 hours) and the actual sleep you've gotten over the last 14 days.
    
    Sleep is the most potent recovery tool you have. Accumulating debt impairs cognitive function, reaction time, insulin sensitivity, and testosterone production.
    """
    
    let howToUse: [MetricPoint] = [
        MetricPoint(title: "0-2h (Well Rested)", body: "You are meeting your sleep needs. Recovery is optimal."),
        MetricPoint(title: "2-5h (Minor Debt)", body: "You missed a few hours. Try to go to bed 30 mins earlier for a few nights to clear it."),
        MetricPoint(title: "> 5h (High Debt)", body: "Your recovery is significantly compromised. Prioritize sleep over high-intensity training until this number comes down.")
    ]
    
    let math = """
    ∑ (Sleep Need - Actual Sleep) over 14 days
    
    We look at a 14-day rolling window because the effects of sleep deprivation are cumulative. One good night's sleep does not erase a week of deprivation.
    """
    
    let ranges: [MetricRange] = [
        MetricRange(label: "Good", min: 0, max: 2, color: Color(hex: "#34C759")),
        MetricRange(label: "Fair", min: 2, max: 5, color: Color(hex: "#FFD60A")),
        MetricRange(label: "Poor", min: 5, max: 12, color: Color(hex: "#FF6B6B"))
    ]
}

struct RPEMetric: MetricDefinition {
    let title = "RPE"
    let subtitle = "Rate of Perceived Exertion"
    let unit = "/10"
    let icon = "gauge.with.needle.fill"
    let color = Color.yellow
    
    let description = """
    RPE (Rate of Perceived Exertion) is a subjective measure of how hard a workout felt, on a scale of 1 to 10. It captures the internal load—the physiological and psychological stress your body experienced.
    
    Two workouts can have the same weight and reps (external load), but if you are tired or stressed, one will feel harder (higher RPE). This makes RPE a crucial context for your training data.
    """
    
    let howToUse: [MetricPoint] = [
        MetricPoint(title: "Be Honest", body: "Don't let your ego dictate the score. If a warm-up weight felt heavy, log it."),
        MetricPoint(title: "Track Trends", body: "A rising RPE for the same workout indicates fatigue or overtraining. A falling RPE indicates you are getting stronger and fitter."),
        MetricPoint(title: "Auto-Regulation", body: "Use RPE to adjust your weights. If the plan says \"Heavy\" but RPE 8 feels like RPE 10, drop the weight.")
    ]
    
    let math = """
    User Input (1-10) based on the Modified Borg Scale.
    
    We use this value to calculate Systemic Load:
    Load = Duration (min) × RPE
    """
    
    let ranges: [MetricRange] = [
        MetricRange(label: "Easy", min: 1, max: 3, color: Color(hex: "#64D2FF")),
        MetricRange(label: "Moderate", min: 4, max: 6, color: Color(hex: "#34C759")),
        MetricRange(label: "Hard", min: 7, max: 8, color: Color(hex: "#FFD60A")),
        MetricRange(label: "Max", min: 9, max: 10, color: Color(hex: "#FF6B6B"))
    ]
}

struct SystemicLoadMetric: MetricDefinition {
    let title = "Systemic Load"
    let subtitle = "Total Training Stress"
    let unit = "au"
    let icon = "chart.bar.fill"
    let color = Color.purple
    
    let description = """
    Systemic Load quantifies the total physiological toll a workout takes on your body. It combines Cardiovascular Load (from heart rate) and Muscular Load (from weight training volume and RPE).
    
    Not all stress is created equal. A heavy squat session taxes your CNS differently than a long run taxes your metabolic system. Systemic Load unifies these into a single number to track your total capacity.
    """
    
    let howToUse: [MetricPoint] = [
        MetricPoint(title: "Balance", body: "Use this to ensure you aren't overloading yourself. If yesterday's load was very high, consider a lighter session today."),
        MetricPoint(title: "Periodization", body: "Your load should wave up and down over the week. High days should be followed by lower days to allow for supercompensation.")
    ]
    
    let math = """
    Cardio Load (TRIMP) + Muscular Load
    
    Muscular Load = Volume × (RPE ÷ 10)
    TRIMP = Duration × (HR_reserve) × e^(b × HR_reserve)
    """
    
    let ranges: [MetricRange] = [] // No fixed ranges for raw load as it varies wildly by person
}

struct E1RMMetric: MetricDefinition {
    let title = "Estimated 1RM"
    let subtitle = "Strength Potential"
    let unit = "lbs"
    let icon = "dumbbell.fill"
    let color = Color.orange
    
    let description = """
    Estimated 1RM (One Rep Max) is a theoretical calculation of the maximum weight you could lift for a single repetition, based on your performance in submaximal sets (e.g., lifting 200lbs for 5 reps).
    
    This allows you to track your strength gains safely without the injury risk and CNS fatigue associated with testing a true 1RM regularly.
    """
    
    let howToUse: [MetricPoint] = [
        MetricPoint(title: "Progress Tracking", body: "If your e1RM is trending up, your program is working."),
        MetricPoint(title: "Programming", body: "Use your e1RM to calculate percentages for your working sets (e.g., \"Do 3 sets at 70% of 1RM\").")
    ]
    
    let math = """
    We use two different formulas depending on the rep range for better accuracy:
    
    • < 10 reps (Brzycki): Weight × (36 ÷ (37 - Reps))
    • ≥ 10 reps (Epley): Weight × (1 + (0.0333 × Reps))
    """
    
    let ranges: [MetricRange] = [] // No fixed ranges for strength
}

struct VolumeIntensityMetric: MetricDefinition {
    let title = "Volume vs. Intensity"
    let subtitle = "Training Density"
    let unit = ""
    let icon = "chart.xyaxis.line"
    let color = Color(hex: "#00D4AA")
    
    let description = """
    This scatter plot visualizes the relationship between your total workout volume (Total Weight Moved) and your average intensity (Average Weight per Rep).
    
    It helps you categorize your sessions:
    • High Volume, High Intensity: Peak performance days.
    • Low Volume, Low Intensity: Recovery or deload sessions.
    • High Volume, Low Intensity: Hypertrophy/Endurance focus.
    • Low Volume, High Intensity: Strength/Power focus.
    """
    
    let howToUse: [MetricPoint] = [
        MetricPoint(title: "Identify Trends", body: "Are you consistently training in one quadrant? Try to vary your stimulus."),
        MetricPoint(title: "Monitor Recovery", body: "If you can't hit high intensity on high volume days, you might need more rest.")
    ]
    
    let math = """
    • Volume: ∑ (Weight × Reps) for all sets.
    • Intensity: Volume ÷ Total Reps.
    """
    
    let ranges: [MetricRange] = []
}

struct MuscleSplitMetric: MetricDefinition {
    let title = "Muscle Group Split"
    let subtitle = "Volume Distribution"
    let unit = "%"
    let icon = "figure.mixed.cardio"
    let color = Color.pink
    
    let description = """
    This chart breaks down your total training volume by muscle group (Chest, Back, Legs, Shoulders, Arms, Core).
    
    A balanced physique requires balanced training. Neglecting certain groups can lead to posture issues, strength imbalances, and increased injury risk.
    """
    
    let howToUse: [MetricPoint] = [
        MetricPoint(title: "Spot Imbalances", body: "Is 50% of your volume Chest? Time to do some Pull-ups."),
        MetricPoint(title: "Specialization", body: "If you are prioritizing a body part (e.g., Legs), expect its slice to be larger, but don't let others disappear.")
    ]
    
    let math = """
    (Volume for Muscle Group ÷ Total Volume) × 100
    """
    
    let ranges: [MetricRange] = []
}

// MARK: - Factory
enum MetricFactory {
    static func make(for type: MetricExplanationSheet.MetricType) -> MetricDefinition {
        switch type {
        case .readiness: return ReadinessMetric()
        case .acwr: return ACWRMetric()
        case .sleepDebt: return SleepDebtMetric()
        case .rpe: return RPEMetric()
        case .systemicLoad: return SystemicLoadMetric()
        case .e1rm: return E1RMMetric()
        case .volumeIntensity: return VolumeIntensityMetric()
        case .muscleSplit: return MuscleSplitMetric()
        }
    }
}
