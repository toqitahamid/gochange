# Fresh UI Redesign (Layered Glass) — Implementation Plan

> **For agentic workers:** REQUIRED: Use superpowers:subagent-driven-development (if subagents available) or superpowers:executing-plans to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Restyle all GoChange views from white-card-on-gray to a layered glassmorphism aesthetic with warm cream background, muted tangerine accent, ambient color blobs, and Sora typography.

**Architecture:** View-layer-only changes. Rewrite Theme.swift and ViewModifiers.swift as the foundation, then restyle each screen top-down (MainTabView → Home → Workout → Active Workout → Analytics → Detail views → Settings → remaining screens). HomeViewModel gets a small addition for Energy Bank computation + insight logic.

**Tech Stack:** SwiftUI, SwiftUI Charts, Sora font (OFL), existing SwiftData models and services unchanged.

**Spec:** `docs/superpowers/specs/2026-03-16-fresh-ui-redesign-design.md`

**Build command:**
```bash
xcodebuild -project gochange.xcodeproj -target gochange -sdk iphonesimulator -configuration Debug build CODE_SIGNING_ALLOWED=NO 2>&1 | grep "error:" | grep -v "Watch" | grep -v "Asset"
```

---

## Chunk 1: Foundation (Design System + Font)

### Task 1: Download and bundle Sora font files

**Files:**
- Create: `gochange/Resources/Fonts/Sora-Light.ttf`
- Create: `gochange/Resources/Fonts/Sora-Regular.ttf`
- Create: `gochange/Resources/Fonts/Sora-Medium.ttf`
- Create: `gochange/Resources/Fonts/Sora-SemiBold.ttf`
- Create: `gochange/Resources/Fonts/Sora-Bold.ttf`
- Create: `gochange/Resources/Fonts/Sora-ExtraBold.ttf`
- Create: `gochange/Resources/Fonts/OFL.txt`
- Modify: `gochange/Info.plist` (add UIAppFonts array)

- [ ] **Step 1: Download Sora font files**

```bash
mkdir -p gochange/Resources/Fonts
# Download each static weight from Google Fonts GitHub
curl -L "https://github.com/nicolo-ribaudo/sora/raw/main/fonts/ttf/Sora-Light.ttf" -o gochange/Resources/Fonts/Sora-Light.ttf
curl -L "https://github.com/nicolo-ribaudo/sora/raw/main/fonts/ttf/Sora-Regular.ttf" -o gochange/Resources/Fonts/Sora-Regular.ttf
curl -L "https://github.com/nicolo-ribaudo/sora/raw/main/fonts/ttf/Sora-Medium.ttf" -o gochange/Resources/Fonts/Sora-Medium.ttf
curl -L "https://github.com/nicolo-ribaudo/sora/raw/main/fonts/ttf/Sora-SemiBold.ttf" -o gochange/Resources/Fonts/Sora-SemiBold.ttf
curl -L "https://github.com/nicolo-ribaudo/sora/raw/main/fonts/ttf/Sora-Bold.ttf" -o gochange/Resources/Fonts/Sora-Bold.ttf
curl -L "https://github.com/nicolo-ribaudo/sora/raw/main/fonts/ttf/Sora-ExtraBold.ttf" -o gochange/Resources/Fonts/Sora-ExtraBold.ttf
```

If the above URLs don't work, download from https://fonts.google.com/specimen/Sora (click Download family) and extract the individual TTF files.

- [ ] **Step 2: Add OFL license file**

Create `gochange/Resources/Fonts/OFL.txt` with the SIL Open Font License text from the Sora download.

- [ ] **Step 3: Register fonts in Info.plist**

Add to `gochange/Info.plist` (within the top-level `<dict>`):
```xml
<key>UIAppFonts</key>
<array>
    <string>Sora-Light.ttf</string>
    <string>Sora-Regular.ttf</string>
    <string>Sora-Medium.ttf</string>
    <string>Sora-SemiBold.ttf</string>
    <string>Sora-Bold.ttf</string>
    <string>Sora-ExtraBold.ttf</string>
</array>
```

- [ ] **Step 4: Add font files to Xcode target**

Add all `.ttf` files and `OFL.txt` to the `gochange` target in `project.pbxproj`. Ensure they appear in the "Copy Bundle Resources" build phase. This can be done via Xcode UI or by editing the pbxproj manually.

- [ ] **Step 5: Build and verify**

Run build command. Expected: no new errors. Verify fonts load at runtime by temporarily printing available font names in `GoChangeApp.swift`:
```swift
// Temporary — remove after verification
for family in UIFont.familyNames.sorted() where family.contains("Sora") {
    print(family, UIFont.fontNames(forFamilyName: family))
}
```

- [ ] **Step 6: Commit**

```bash
git add gochange/Resources/Fonts/ gochange/Info.plist gochange.xcodeproj/project.pbxproj
git commit -m "chore: bundle Sora font files with OFL license"
```

---

### Task 2: Rewrite Theme.swift

**Files:**
- Modify: `gochange/Utilities/Theme.swift` (full rewrite, 138 → ~220 lines)

- [ ] **Step 1: Rewrite AppColors**

Replace the existing `AppColors` struct with new glass-themed tokens. Keep `RIRLabels` and `MuscleGroups` unchanged at the bottom of the file.

```swift
import SwiftUI

// MARK: - Colors

struct AppColors {
    // Brand
    static let primary = Color(hex: "#D97B4A")       // Muted Tangerine
    static let primaryDark = Color(hex: "#C46A3A")    // Gradient end

    // Backgrounds
    static let background = Color(hex: "#EDE5D8")     // Warm parchment
    static let surface = Color.white.opacity(0.5)     // Standard glass
    static let surfaceStrong = Color.white.opacity(0.65) // Hero glass
    static let surfaceSubtle = Color.white.opacity(0.32) // Secondary glass

    // Text
    static let textPrimary = Color(hex: "#2C2418")
    static let textSecondary = Color(hex: "#6B5D4F")

    // Metrics
    static let strain = Color(hex: "#E8453C")
    static let recovery = Color(hex: "#00B482")
    static let sleep = Color(hex: "#6E5AD2")

    // Borders & Dividers
    static let border = Color.white.opacity(0.55)
    static let borderSubtle = Color.white.opacity(0.4)
    static let divider = Color(red: 140/255, green: 126/255, blue: 110/255).opacity(0.12)

    // Semantic
    static let completedTint = Color(red: 0, green: 180/255, blue: 130/255).opacity(0.06)
    static let success = Color(hex: "#00B482")
    static let warning = Color(hex: "#F59E0B")
    static let error = Color(hex: "#E8453C")
}
```

- [ ] **Step 2: Rewrite AppFonts**

```swift
// MARK: - Fonts

struct AppFonts {
    static func sora(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        let name: String
        switch weight {
        case .light: name = "Sora-Light"
        case .regular: name = "Sora-Regular"
        case .medium: name = "Sora-Medium"
        case .semibold: name = "Sora-SemiBold"
        case .bold: name = "Sora-Bold"
        case .heavy, .black: name = "Sora-ExtraBold"
        default: name = "Sora-Regular"
        }
        return .custom(name, size: size)
    }

    // Named styles
    static let heroValue = sora(54, weight: .heavy)
    static let screenTitle = sora(28, weight: .heavy)
    static let cardValue = sora(26, weight: .heavy)
    static let cardValueSmall = sora(22, weight: .heavy)
    static let body = sora(15, weight: .medium)
    static let bodySmall = sora(13, weight: .medium)
    static let label = sora(10, weight: .bold)
    static let caption = sora(11, weight: .regular)
    static let captionSmall = sora(9, weight: .regular)
}
```

- [ ] **Step 3: Rewrite AppLayout**

```swift
// MARK: - Layout

struct AppLayout {
    static let horizontalPadding: CGFloat = 16
    static let cardPadding: CGFloat = 16
    static let cardPaddingStrong: CGFloat = 20
    static let cardPaddingSubtle: CGFloat = 14
    static let cardSpacing: CGFloat = 10
    static let sectionSpacing: CGFloat = 16
    static let cornerRadiusLarge: CGFloat = 22
    static let cornerRadiusMedium: CGFloat = 20
    static let cornerRadiusSmall: CGFloat = 16
    static let cornerRadiusTiny: CGFloat = 12
    static let tabBarHeight: CGFloat = 56
    static let tabBarBottomPadding: CGFloat = 34
    static let scrollBottomPadding: CGFloat = 100

    // Legacy aliases for compatibility during migration
    static let margin: CGFloat = 16
    static let spacing: CGFloat = 10
    static let cornerRadius: CGFloat = 20
    static let miniRadius: CGFloat = 16
    static let smallRadius: CGFloat = 12
}
```

- [ ] **Step 4: Replace AppShadow and AppBorder**

```swift
// MARK: - Shadows

struct AppShadow {
    // Glass card shadows
    static let cardColor = Color.black.opacity(0.05)
    static let cardRadius: CGFloat = 10
    static let cardY: CGFloat = 4

    static let strongColor = Color.black.opacity(0.08)
    static let strongRadius: CGFloat = 16
    static let strongY: CGFloat = 8

    // Legacy aliases
    static let cardOpacity: Double = 0.05
    static let subCardRadius: CGFloat = 10
    static let subCardOpacity: Double = 0.04
    static let subCardY: CGFloat = 4
}

struct AppBorder {
    static let color = Color.white.opacity(0.55)
    static let width: CGFloat = 1.0
}
```

- [ ] **Step 5: Keep RIRLabels and MuscleGroups unchanged**

Do not modify the existing `RIRLabels` and `MuscleGroups` structs — they are data logic, not visual styling. Ensure they remain at the bottom of Theme.swift.

- [ ] **Step 6: Build and verify**

Run build command. Fix any compilation errors from color/layout token renames in other files. Expected: some errors from views referencing old color names — these will be fixed as each view is restyled. For now, add temporary compatibility aliases if needed to keep the build green:

```swift
// MARK: - Temporary compatibility (remove as views are migrated)
extension AppColors {
    static let secondary = textPrimary
}
```

- [ ] **Step 7: Commit**

```bash
git add gochange/Utilities/Theme.swift
git commit -m "refactor: rewrite Theme.swift for Layered Glass design system"
```

---

### Task 3: Rewrite ViewModifiers.swift

**Files:**
- Modify: `gochange/Utilities/ViewModifiers.swift` (full rewrite, 43 → ~120 lines)

- [ ] **Step 1: Write glass card modifiers**

```swift
import SwiftUI

// MARK: - Glass Card Modifiers

struct GlassCardModifier: ViewModifier {
    enum Style {
        case standard, strong, subtle
    }

    let style: Style

    private var backgroundColor: Color {
        switch style {
        case .standard: return .white.opacity(0.5)
        case .strong: return .white.opacity(0.65)
        case .subtle: return .white.opacity(0.32)
        }
    }

    private var cornerRadius: CGFloat {
        switch style {
        case .standard: return AppLayout.cornerRadiusMedium
        case .strong: return AppLayout.cornerRadiusLarge
        case .subtle: return AppLayout.cornerRadiusSmall
        }
    }

    private var borderColor: Color {
        switch style {
        case .standard: return .white.opacity(0.55)
        case .strong: return .white.opacity(0.7)
        case .subtle: return .white.opacity(0.4)
        }
    }

    private var shadowColor: Color {
        switch style {
        case .strong: return .black.opacity(0.08)
        default: return .black.opacity(0.05)
        }
    }

    private var shadowRadius: CGFloat {
        switch style {
        case .strong: return 16
        default: return 10
        }
    }

    private var shadowY: CGFloat {
        switch style {
        case .strong: return 8
        default: return 4
        }
    }

    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(backgroundColor)
                    .background(
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .fill(.ultraThinMaterial)
                    )
            )
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(borderColor, lineWidth: 1)
            )
            .shadow(color: shadowColor, radius: shadowRadius, x: 0, y: shadowY)
    }
}

// MARK: - Ambient Background

struct AmbientBackgroundModifier: ViewModifier {
    var scrollOffset: CGFloat = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func body(content: Content) -> some View {
        ZStack {
            AppColors.background.ignoresSafeArea()

            Group {
                Circle()
                    .fill(AppColors.primary)
                    .frame(width: 160, height: 160)
                    .blur(radius: 50)
                    .opacity(0.35)
                    .offset(x: 80, y: reduceMotion ? -40 : -40 + scrollOffset * 0.3)
                Circle()
                    .fill(AppColors.sleep)
                    .frame(width: 130, height: 130)
                    .blur(radius: 50)
                    .opacity(0.20)
                    .offset(x: -60, y: reduceMotion ? 300 : 300 + scrollOffset * 0.3)
                Circle()
                    .fill(AppColors.recovery)
                    .frame(width: 150, height: 150)
                    .blur(radius: 50)
                    .opacity(0.18)
                    .offset(x: 70, y: reduceMotion ? 500 : 500 + scrollOffset * 0.3)
            }
            .drawingGroup()

            content
        }
    }
}

// MARK: - Primary Button Style

struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(AppFonts.sora(14, weight: .bold))
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(
                LinearGradient(
                    colors: [AppColors.primary, AppColors.primaryDark],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .shadow(color: AppColors.primary.opacity(0.3), radius: 12, y: 6)
            .scaleEffect(configuration.isPressed ? 0.96 : 1)
            .animation(.easeOut(duration: 0.1), value: configuration.isPressed)
    }
}

// MARK: - View Extensions

extension View {
    func glassCard() -> some View {
        modifier(GlassCardModifier(style: .standard))
    }

    func glassCardStrong() -> some View {
        modifier(GlassCardModifier(style: .strong))
    }

    func glassCardSubtle() -> some View {
        modifier(GlassCardModifier(style: .subtle))
    }

    func ambientBackground(scrollOffset: CGFloat = 0) -> some View {
        modifier(AmbientBackgroundModifier(scrollOffset: scrollOffset))
    }

    // Legacy compatibility — remove after full migration
    func cardStyle() -> some View {
        glassCard()
    }

    func subCardStyle() -> some View {
        glassCardSubtle()
    }
}
```

- [ ] **Step 2: Build and verify**

Run build command. Expected: clean build (legacy aliases maintain compatibility).

- [ ] **Step 3: Commit**

```bash
git add gochange/Utilities/ViewModifiers.swift
git commit -m "refactor: rewrite ViewModifiers with glass card + ambient background"
```

---

### Task 4: Update Constants.swift and Extensions.swift

**Files:**
- Modify: `gochange/Utilities/Constants.swift`
- Modify: `gochange/Utilities/Extensions.swift` (verify Color(hex:) exists)

- [ ] **Step 1: Update Constants.swift**

Ensure `AppConstants.Defaults.restTimerDuration` and RIR/muscleGroup delegates still work. No structural changes needed — just verify it still compiles with the new Theme.swift.

- [ ] **Step 2: Verify Color(hex:) extension exists in Extensions.swift**

The new color tokens use `Color(hex:)`. Verify this initializer exists in `Extensions.swift`. It should already be there from the existing codebase.

- [ ] **Step 3: Build and verify**

Run build command. Expected: clean build.

- [ ] **Step 4: Commit** (if any changes were needed)

```bash
git add gochange/Utilities/
git commit -m "chore: verify utilities compatibility with new design system"
```

---

## Chunk 2: Navigation + Home Dashboard

### Task 5: Add Energy Bank + Insight logic to HomeViewModel

**Files:**
- Modify: `gochange/ViewModels/HomeViewModel.swift`

- [ ] **Step 1: Add Energy Bank computed properties**

Add after the existing properties in `HomeViewModel`:

```swift
// MARK: - Energy Bank

var energyBankScore: Int {
    let recoveryComponent = 0.40 * Double(recoveryScore)
    let sleepComponent = 0.35 * Double(sleepData?.qualityPercentage ?? 0)
    let inverseStrain = max(0.0, 100.0 - Double(strainScore))
    let strainComponent = 0.25 * inverseStrain
    return Int(recoveryComponent + sleepComponent + strainComponent)
}

var energyBankStatus: String {
    switch energyBankScore {
    case 80...100: return "Your body is ready to push"
    case 60..<80: return "Pace your training today"
    case 40..<60: return "Consider lighter work"
    default: return "Rest recommended"
    }
}

var energyBankLabel: String {
    switch energyBankScore {
    case 80...100: return "Fully Charged"
    case 60..<80: return "Moderate"
    case 40..<60: return "Depleted"
    default: return "Critical"
    }
}
```

- [ ] **Step 2: Add insight badge logic**

Add to `HomeViewModel`:

```swift
var insightBadge: (text: String, color: Color)? {
    if let sleep = sleepData, sleep.qualityPercentage > 85 {
        let boost = max(0, recoveryScore - 70)
        return ("Great sleep boosted recovery +\(boost)%", AppColors.sleep)
    }
    if strainScore > 75 {
        return ("High strain yesterday — allow extra recovery", AppColors.strain)
    }
    if recoveryScore >= 80 {
        return ("Recovery is strong — ready to train", AppColors.recovery)
    }
    return nil
}
```

- [ ] **Step 3: Build and verify**

Run build command. Expected: clean build.

- [ ] **Step 4: Commit**

```bash
git add gochange/ViewModels/HomeViewModel.swift
git commit -m "feat: add Energy Bank score + insight badge to HomeViewModel"
```

---

### Task 6: Rewrite MainTabView with glass tab bar

**Files:**
- Modify: `gochange/Views/MainTabView.swift` (full rewrite)

- [ ] **Step 1: Rewrite MainTabView**

Rewrite the entire file. Keep the same 3-tab structure and WorkoutManager overlay logic. Replace the custom tab bar with a floating glass tab bar. Add ambient background at the root level.

Key changes:
- Replace `CustomTabBar` with a glass-styled floating tab bar using `.glassCardStrong()` modifier
- Use `ZStack` with ambient background behind all tab content
- Keep `WorkoutMiniplayer` and `ActiveWorkoutView` sheet logic unchanged
- Tab icons: `house.fill`, `dumbbell.fill`, `chart.xyaxis.line`
- Tab labels: "Home", "Workout", "Analytics"
- Active state uses `AppColors.primary`, inactive uses `AppColors.textSecondary`
- Tab bar positioned with `.padding(.bottom, AppLayout.tabBarBottomPadding)`
- Tab bar corner radius: 24pt
- Read the existing file first — preserve all `WorkoutManager` state management, minimize/resume logic, and sheet presentation

- [ ] **Step 2: Build and verify**

Run build command. Expected: clean build.

- [ ] **Step 3: Commit**

```bash
git add gochange/Views/MainTabView.swift
git commit -m "refactor: rewrite MainTabView with floating glass tab bar"
```

---

### Task 7: Create reusable glass components

**Files:**
- Create: `gochange/Views/Components/SparklineChart.swift`
- Create: `gochange/Views/Components/GlassProgressRing.swift`
- Create: `gochange/Views/Components/ScoreCard.swift`
- Create: `gochange/Views/Components/EnergyBankCard.swift`
- Create: `gochange/Views/Components/VitalCard.swift`

- [ ] **Step 1: Create SparklineChart**

7-bar mini chart component. Takes an array of up to 7 Double values and a color. Bars are 3pt wide, 2pt gap, rounded caps. Progressive opacity from 15% (oldest) to 100% (newest).

```swift
struct SparklineChart: View {
    let values: [Double]
    let color: Color

    var body: some View {
        HStack(alignment: .bottom, spacing: 2) {
            ForEach(Array(values.suffix(7).enumerated()), id: \.offset) { index, value in
                let normalizedHeight = normalizeHeight(value)
                let opacity = 0.15 + (Double(index) / Double(max(values.count - 1, 1))) * 0.85
                RoundedRectangle(cornerRadius: 1.5)
                    .fill(color.opacity(opacity))
                    .frame(width: 3, height: max(2, normalizedHeight))
            }
        }
        .frame(height: 20)
    }

    private func normalizeHeight(_ value: Double) -> CGFloat {
        guard let maxVal = values.max(), maxVal > 0 else { return 2 }
        return CGFloat(value / maxVal) * 20
    }
}
```

- [ ] **Step 2: Create GlassProgressRing**

Reusable circular progress ring with glass styling.

```swift
struct GlassProgressRing: View {
    let progress: Double // 0.0 to 1.0
    let color: Color
    let size: CGFloat
    let lineWidth: CGFloat

    init(progress: Double, color: Color, size: CGFloat = 64, lineWidth: CGFloat = 6) {
        self.progress = progress
        self.color = color
        self.size = size
        self.lineWidth = lineWidth
    }

    var body: some View {
        ZStack {
            Circle()
                .stroke(color.opacity(0.12), lineWidth: lineWidth)
            Circle()
                .trim(from: 0, to: min(progress, 1.0))
                .stroke(color, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .shadow(color: color.opacity(0.25), radius: 4, y: 2)
        }
        .frame(width: size, height: size)
    }
}
```

- [ ] **Step 3: Create ScoreCard**

Score trio card (Strain/Recovery/Sleep) with sparkline.

```swift
struct ScoreCard: View {
    let title: String
    let value: String
    let subtitle: String
    let color: Color
    let sparklineData: [Double]

    var body: some View {
        VStack(spacing: 4) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)

            Text(title)
                .font(AppFonts.label)
                .tracking(1.2)
                .foregroundColor(color)
                .textCase(.uppercase)

            Text(value)
                .font(AppFonts.cardValue)
                .foregroundColor(AppColors.textPrimary)

            Text(subtitle)
                .font(AppFonts.captionSmall)
                .foregroundColor(AppColors.textSecondary)

            SparklineChart(values: sparklineData, color: color)
                .padding(.top, 4)
        }
        .padding(14)
        .frame(maxWidth: .infinity)
        .glassCardSubtle()
    }
}
```

- [ ] **Step 4: Create EnergyBankCard**

Hero Energy Bank card.

```swift
struct EnergyBankCard: View {
    let score: Int
    let statusText: String
    let insightBadge: (text: String, color: Color)?

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("ENERGY BANK")
                    .font(AppFonts.label)
                    .tracking(1.5)
                    .foregroundColor(AppColors.primary)

                HStack(alignment: .firstTextBaseline, spacing: 2) {
                    Text("\(score)")
                        .font(AppFonts.heroValue)
                        .foregroundColor(AppColors.textPrimary)
                    Text("%")
                        .font(AppFonts.cardValueSmall)
                        .foregroundColor(AppColors.textSecondary)
                }

                Text(statusText)
                    .font(AppFonts.bodySmall)
                    .foregroundColor(AppColors.textSecondary)

                if let badge = insightBadge {
                    HStack(spacing: 5) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 10))
                        Text(badge.text)
                            .font(AppFonts.captionSmall)
                    }
                    .foregroundColor(badge.color)
                    .padding(.horizontal, 11)
                    .padding(.vertical, 6)
                    .glassCardSubtle()
                    .padding(.top, 4)
                }
            }

            Spacer()

            GlassProgressRing(
                progress: Double(score) / 100.0,
                color: AppColors.primary,
                size: 64
            )
        }
        .padding(20)
        .glassCardStrong()
    }
}
```

- [ ] **Step 5: Create VitalCard**

```swift
struct VitalCard: View {
    let icon: String
    let iconColor: Color
    let title: String
    let value: String
    let unit: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 12))
                    .foregroundColor(iconColor)
                Text(title)
                    .font(AppFonts.label)
                    .tracking(1)
                    .foregroundColor(AppColors.textSecondary)
                    .textCase(.uppercase)
            }

            Text(value)
                .font(AppFonts.cardValue)
                .foregroundColor(AppColors.textPrimary)

            Text(unit)
                .font(AppFonts.caption)
                .foregroundColor(AppColors.textSecondary)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassCardSubtle()
    }
}
```

- [ ] **Step 6: Build and verify**

Run build command. Expected: clean build.

- [ ] **Step 7: Commit**

```bash
git add gochange/Views/Components/SparklineChart.swift gochange/Views/Components/GlassProgressRing.swift gochange/Views/Components/ScoreCard.swift gochange/Views/Components/EnergyBankCard.swift gochange/Views/Components/VitalCard.swift
git commit -m "feat: add reusable glass components (sparkline, ring, score, energy, vital)"
```

---

### Task 8: Rewrite JournalView (Home Dashboard)

**Files:**
- Modify: `gochange/Views/Fitness/JournalView.swift` (full rewrite)
- Modify: `gochange/Views/Fitness/Components/JournalScoreCards.swift` (delete or gut — replaced by ScoreCard)

- [ ] **Step 1: Rewrite JournalView**

Rewrite to the new Home Dashboard layout. Read the existing file first to preserve:
- `@StateObject var viewModel = HomeViewModel()`
- `@EnvironmentObject var workoutManager: WorkoutManager`
- `@Environment(\.modelContext) var modelContext`
- `.task { await viewModel.loadData(context: modelContext) }`
- `.refreshable { await viewModel.loadData(context: modelContext) }`
- Navigation to settings and metric detail views

New layout order:
1. Header with greeting + settings gear
2. EnergyBankCard
3. Score trio (3 × ScoreCard in HStack)
4. Next workout card (query WorkoutDay from modelContext, use SchedulingService)
5. Vitals grid (2×2 VitalCard)
6. Recent activity list (glass card with workout sessions)
7. 100pt bottom padding

Use `ScrollView` with `ambientBackground()` modifier. Track scroll offset with `GeometryReader` in a preference key for parallax.

Handle `LoadState`: show ProgressView when `.loading`, error card when `.error`, content when `.loaded`.

- [ ] **Step 2: Build and verify**

Run build command. Expected: clean build. May need to fix imports or remove references to deleted score card components.

- [ ] **Step 3: Commit**

```bash
git add gochange/Views/Fitness/JournalView.swift gochange/Views/Fitness/Components/
git commit -m "refactor: rewrite JournalView as Home Dashboard with glass design"
```

---

## Chunk 3: Workout Tab + Preview

### Task 9: Restyle WorkoutDaySelectionView

**Files:**
- Modify: `gochange/Views/Workout/WorkoutDaySelectionView.swift`

- [ ] **Step 1: Read the existing file and identify what to change**

Read the full file. Note all data bindings, @Query, NavigationLink destinations, context menu actions — these must be preserved. Only change visual styling.

- [ ] **Step 2: Apply glass styling**

Key changes:
- Background: `ambientBackground()` instead of `AppColors.background`
- Header: Sora fonts, textPrimary/textSecondary colors
- Weekly Progress Card: `.glassCardStrong()`, primary gradient ring, 4-dot indicators
- WorkoutDayCard rows: `.glassCard()`, gradient icon badge using workout's colorHex, Sora fonts
- Add Workout card: `.glassCardSubtle()` with dashed border overlay
- Exercise Library row: `.glassCard()`
- Bottom padding: 100pt

- [ ] **Step 3: Build and verify**

Run build command.

- [ ] **Step 4: Commit**

```bash
git add gochange/Views/Workout/WorkoutDaySelectionView.swift
git commit -m "style: restyle WorkoutDaySelectionView with glass cards"
```

---

### Task 10: Restyle WorkoutPreviewView

**Files:**
- Modify: `gochange/Views/Workout/WorkoutPreviewView.swift`

- [ ] **Step 1: Read and restyle**

Key changes:
- Header card: `.glassCardStrong()`, gradient icon, Sora fonts
- Exercise list: `.glassCard()`, numbered gradient badges, glass dividers
- Sticky start button: primary gradient button with glass gradient fade
- Background: `AppColors.background`

Preserve all NavigationLink destinations and data bindings.

- [ ] **Step 2: Build and verify**

Run build command.

- [ ] **Step 3: Commit**

```bash
git add gochange/Views/Workout/WorkoutPreviewView.swift
git commit -m "style: restyle WorkoutPreviewView with glass cards"
```

---

## Chunk 4: Active Workout + Miniplayer

### Task 11: Restyle ActiveWorkoutView

**Files:**
- Modify: `gochange/Views/Workout/ActiveWorkoutView.swift`
- Modify: `gochange/Views/Workout/ExerciseWorkoutCard.swift`
- Modify: `gochange/Views/Workout/SetInputCard.swift`

- [ ] **Step 1: Read all three files**

Understand the full active workout flow. Note all WorkoutManager interactions, timer logic, set completion, exercise navigation.

- [ ] **Step 2: Restyle ActiveWorkoutView**

Key changes:
- Sheet header: `.glassCardStrong()`, elapsed time in glass pill, Sora fonts
- Control buttons: glass styling, recovery green for Finish
- Background: `AppColors.background`

- [ ] **Step 3: Restyle ExerciseWorkoutCard**

Key changes:
- Exercise name: Sora screenTitle
- Badge row: glass pills for muscle group, progress, notes
- Mini chart: `.glassCardSubtle()` container
- Progressive overload banner: glass pill with primary color

- [ ] **Step 4: Restyle SetInputCard**

Key changes:
- `.glassCardSubtle()` for each set row
- Glass text fields for weight/reps inputs
- RIR menu: keep existing color coding from `RIRLabels`
- Completion toggle: stroke circle → filled primary circle with checkmark
- Completed sets: add `.completedTint` background

- [ ] **Step 5: Build and verify**

Run build command.

- [ ] **Step 6: Commit**

```bash
git add gochange/Views/Workout/ActiveWorkoutView.swift gochange/Views/Workout/ExerciseWorkoutCard.swift gochange/Views/Workout/SetInputCard.swift
git commit -m "style: restyle active workout views with glass design"
```

---

### Task 12: Restyle WorkoutMiniplayer

**Files:**
- Modify: `gochange/Views/Workout/WorkoutMiniplayer.swift`

- [ ] **Step 1: Read and restyle**

Key changes:
- `.glassCardStrong()` styling
- Top corner radius 20pt, 0 bottom
- Workout badge: primary bg capsule, white text
- Sora fonts throughout
- Pause/Resume: primary glass circle, 40pt
- Preserve all WorkoutManager bindings and tap-to-expand gesture

- [ ] **Step 2: Build and verify**

Run build command.

- [ ] **Step 3: Commit**

```bash
git add gochange/Views/Workout/WorkoutMiniplayer.swift
git commit -m "style: restyle WorkoutMiniplayer with glass design"
```

---

## Chunk 5: Analytics + Detail Views

### Task 13: Restyle PerformanceAnalyticsView (Analytics Tab)

**Files:**
- Modify: `gochange/Views/Analytics/PerformanceAnalyticsView.swift`

- [ ] **Step 1: Read and restyle**

Key changes:
- Rename header from "Performance" to "Analytics"
- Glass segmented controls for period + section selection
- Hero stats row: 3 × `.glassCardSubtle()` pills
- Chart cards: each wrapped in `.glassCard()`
- Chart styling: area fills at 15% opacity, line strokes in metric color
- Background: `AppColors.background`
- Sora fonts throughout

Preserve all ViewModel bindings and chart data.

- [ ] **Step 2: Restyle supporting analytics views**

Apply glass card styling to all files in `gochange/Views/Analytics/`:
- `VolumeTrendsChart.swift` — glass card container, updated colors
- `RepsTrendsChart.swift` — same pattern
- `MuscleGroupBalanceView.swift` — same pattern
- `WorkoutFrequencyHeatmap.swift` — same pattern
- `PerformanceCharts.swift` / `PerformanceCharts2.swift` — updated colors
- Other analytics views — `.glassCard()` containers

- [ ] **Step 3: Build and verify**

Run build command.

- [ ] **Step 4: Commit**

```bash
git add gochange/Views/Analytics/
git commit -m "style: restyle Analytics tab with glass cards and updated chart colors"
```

---

### Task 14: Create MetricDetailView (unified)

**Files:**
- Create: `gochange/Views/Home/MetricDetailView.swift`
- Modify: `gochange/Views/Recovery/RecoveryDashboardView.swift` (restyle)
- Modify: `gochange/Views/Home/StrainDetailView.swift` (restyle)
- Modify: `gochange/Views/Sleep/SleepView.swift` (restyle)

- [ ] **Step 1: Create MetricDetailView**

A parameterized view that works for Strain, Recovery, or Sleep. Takes a `MetricType` enum (strain/recovery/sleep) and displays:
1. Large progress ring (160pt, glassCardStrong)
2. Key metrics grid (2×2, glassCardSubtle)
3. 7-day trend chart (glassCard, SwiftUI Charts AreaMark+LineMark)
4. Insights list (glassCard)

Use existing ViewModels (HomeViewModel, FitnessViewModel) for data.

- [ ] **Step 2: Update existing detail views to redirect or restyle**

Option A (preferred): Keep existing files but restyle them with glass. This avoids breaking navigation links throughout the app.
Option B: Replace with MetricDetailView and update all NavigationLink destinations.

Choose Option A for safety — restyle `RecoveryDashboardView`, `StrainDetailView`, and `SleepView` with glass cards, Sora fonts, and the warm cream background.

- [ ] **Step 3: Build and verify**

Run build command.

- [ ] **Step 4: Commit**

```bash
git add gochange/Views/Home/ gochange/Views/Recovery/ gochange/Views/Sleep/
git commit -m "style: restyle metric detail views with glass design"
```

---

### Task 15: Restyle SessionDetailView

**Files:**
- Modify: `gochange/Views/History/SessionDetailView.swift`
- Modify: `gochange/Views/History/SessionHealthSummaryCard.swift`

- [ ] **Step 1: Read and restyle both files**

Key changes:
- Header: `.glassCardStrong()`, Sora screenTitle
- Glass pill badges for duration/volume/sets
- Health summary: `.glassCard()` with 2×2 vital grid
- Exercise log cards: `.glassCard()` per exercise, `.glassCardSubtle()` per set row
- Background: `AppColors.background`

- [ ] **Step 2: Build and verify**

Run build command.

- [ ] **Step 3: Commit**

```bash
git add gochange/Views/History/
git commit -m "style: restyle SessionDetailView with glass design"
```

---

## Chunk 6: Settings + Remaining Views

### Task 16: Restyle Settings views

**Files:**
- Modify: `gochange/Views/Settings/SettingsView.swift`
- Modify: `gochange/Views/Settings/AccountSettingsView.swift`
- Modify: `gochange/Views/Settings/CustomizationSettingsView.swift`
- Modify: `gochange/Views/Settings/NotificationSettingsView.swift`
- Modify: `gochange/Views/Settings/ReminderSettingsView.swift`
- Modify: `gochange/Views/Settings/DataSourcesView.swift`
- Modify: `gochange/Views/Settings/DataManagementView.swift`

- [ ] **Step 1: Restyle SettingsView (root)**

Key changes:
- Section groups: `.glassCard()` containing navigation rows
- SF Symbol icons with colored circle bg at 15% opacity
- Sora fonts, textPrimary/textSecondary colors
- Glass dividers between rows
- Background: `AppColors.background` with ambient blobs

- [ ] **Step 2: Restyle all sub-settings views**

Apply the same glass pattern to each sub-settings view:
- Form fields: `.glassCardSubtle()` containers
- Toggle switches: primary tint when on
- Navigation rows: same pattern as root settings
- Backgrounds: `AppColors.background`

- [ ] **Step 3: Build and verify**

Run build command.

- [ ] **Step 4: Commit**

```bash
git add gochange/Views/Settings/
git commit -m "style: restyle all Settings views with glass design"
```

---

### Task 17: Restyle remaining views (batch)

**Files:**
- Modify: `gochange/Views/Workout/EditWorkoutDayView.swift`
- Modify: `gochange/Views/Workout/ExerciseSelectionSheet.swift`
- Modify: `gochange/Views/Workout/ReorderExercisesSheet.swift`
- Modify: `gochange/Views/Workout/WorkoutSummaryView.swift`
- Modify: `gochange/Views/Workout/WeightInputSheet.swift`
- Modify: `gochange/Views/Workout/RepsDurationInputSheet.swift`
- Modify: `gochange/Views/Workout/RPEInputSheet.swift`
- Modify: `gochange/Views/Workout/PreviousWorkoutHistorySheet.swift`
- Modify: `gochange/Views/Workout/ComparisonMetricsRow.swift`
- Modify: `gochange/Views/Workout/ProgressiveOverloadBanner.swift`
- Modify: `gochange/Views/Workout/ExerciseMiniChart.swift`
- Modify: `gochange/Views/Exercise/ExerciseLibraryView.swift`
- Modify: `gochange/Views/Exercise/ExerciseDetailView.swift`
- Modify: `gochange/Views/Fitness/FitnessDashboardView.swift`
- Modify: `gochange/Views/Fitness/MetricExplanationSheet.swift`
- Modify: `gochange/Views/Recovery/RestDayLoggingView.swift`
- Modify: `gochange/Views/Recovery/RestDayListView.swift`
- Modify: `gochange/Views/Recovery/RecoveryDetailSheet.swift`

- [ ] **Step 1: Apply glass styling to all workout sheets**

For each sheet view:
- Replace `.background(...)` with `AppColors.background`
- Replace `.cardStyle()` / white backgrounds with `.glassCard()` or `.glassCardSubtle()`
- Update text colors to `AppColors.textPrimary` / `AppColors.textSecondary`
- Update fonts to Sora equivalents
- Add `.presentationDetents([.medium, .large])` if not present

- [ ] **Step 2: Apply glass styling to exercise views**

- `ExerciseLibraryView`: search bar in `.glassCardSubtle()`, rows in `.glassCard()`
- `ExerciseDetailView`: `.glassCardStrong()` header, `.glassCard()` sections

- [ ] **Step 3: Apply glass styling to remaining fitness/recovery views**

- `FitnessDashboardView`: glass cards throughout
- `MetricExplanationSheet`: `.glassCard()` with icon + body text
- `RestDayLoggingView`: `.glassCard()` form
- `RestDayListView`: `.glassCard()` rows
- `RecoveryDetailSheet`: `.glassCard()` sections

- [ ] **Step 4: Build and verify**

Run build command. This is the most likely step to surface compilation errors from missed token renames. Fix all errors.

- [ ] **Step 5: Commit**

```bash
git add gochange/Views/
git commit -m "style: restyle all remaining views with glass design"
```

---

### Task 18: Clean up legacy compatibility + final polish

**Files:**
- Modify: `gochange/Utilities/Theme.swift` (remove legacy aliases)
- Modify: `gochange/Utilities/ViewModifiers.swift` (remove legacy aliases)
- Modify: `gochange/Views/Components/` (remove unused old components)
- Modify: `gochange/Views/Fitness/Components/` (remove or update old dashboard components)

- [ ] **Step 1: Search for any remaining old color/style references**

```bash
grep -r "AppColors.secondary\|AppColors.surface\b[^S]" gochange/ --include="*.swift" | grep -v "Theme.swift"
grep -r "\.cardStyle()\|\.subCardStyle()" gochange/ --include="*.swift" | grep -v "ViewModifiers.swift"
```

Fix any remaining references.

- [ ] **Step 2: Remove legacy aliases from Theme.swift and ViewModifiers.swift**

Remove the `// Legacy compatibility` sections added in Tasks 2 and 3.

- [ ] **Step 3: Remove or update old component files**

If these are no longer used after the JournalView rewrite:
- `gochange/Views/Fitness/Components/JournalScoreCards.swift` — replaced by `ScoreCard`
- `gochange/Views/Fitness/Components/VitalsGridView.swift` — replaced by `VitalCard` grid in JournalView
- `gochange/Views/Components/MetricCard.swift` — evaluate if still used
- `gochange/Views/Components/LightMetricCard.swift` — evaluate
- `gochange/Views/Components/InsightCard.swift` — evaluate
- `gochange/Views/Components/LightInsightCard.swift` — evaluate

Only delete files that are confirmed unused (no imports or references).

- [ ] **Step 4: Remove temporary font verification code**

Remove the `UIFont.familyNames` print statement from `GoChangeApp.swift` if it was added in Task 1.

- [ ] **Step 5: Full build and verify**

Run build command. Expected: zero errors.

- [ ] **Step 6: Commit**

```bash
git add gochange/
git commit -m "chore: remove legacy design system aliases and unused components"
```

---

## Summary

| Chunk | Tasks | Scope |
|---|---|---|
| 1: Foundation | 1–4 | Font, Theme.swift, ViewModifiers.swift, Constants |
| 2: Navigation + Home | 5–8 | Energy Bank, MainTabView, glass components, JournalView |
| 3: Workout | 9–10 | WorkoutDaySelectionView, WorkoutPreviewView |
| 4: Active Workout | 11–12 | ActiveWorkoutView, ExerciseWorkoutCard, SetInputCard, Miniplayer |
| 5: Analytics + Detail | 13–15 | PerformanceAnalyticsView, MetricDetailView, SessionDetailView |
| 6: Remaining | 16–18 | Settings, sheets, cleanup |

Total: 18 tasks across 6 chunks. Each task produces a working build and a commit.
