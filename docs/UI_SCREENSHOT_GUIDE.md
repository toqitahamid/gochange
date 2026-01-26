# UI Screenshot & Mockup Guide

**Purpose:** Guide for generating screenshots and visual mockups of GoChange app

---

## Generating Screenshots

### Using Xcode Simulator

1. **Build and Run:**
   ```bash
   xcodebuild -scheme gochange -configuration Debug \
     -destination 'platform=iOS Simulator,name=iPhone 15 Pro' \
     build
   ```

2. **Take Screenshots:**
   - Open Simulator
   - Navigate to desired screen
   - Cmd+S to save screenshot
   - Or use Device → Screenshot menu

3. **Recommended Devices:**
   - iPhone 15 Pro (393×852pt) - Primary
   - iPhone 15 Pro Max (430×932pt) - Large screen
   - iPhone SE (375×667pt) - Compact

### Using Fastlane Screenshots

If Fastlane is configured:

```bash
fastlane screenshots
```

### Manual Screenshot Checklist

**Home Tab (JournalView):**
- [ ] Default state (no workouts)
- [ ] With recovery data (high score)
- [ ] With recovery data (low score)
- [ ] With activity timeline
- [ ] Pull-to-refresh state

**Workout Tab:**
- [ ] Empty state (no workouts)
- [ ] With 4 workout days
- [ ] Weekly progress at 0%
- [ ] Weekly progress at 50%
- [ ] Weekly progress at 100%
- [ ] Workout card (completed)
- [ ] Workout card (not completed)

**Workout Preview:**
- [ ] Push workout preview
- [ ] Pull workout preview
- [ ] Legs workout preview
- [ ] Fullbody workout preview
- [ ] With many exercises (scrollable)

**Active Workout:**
- [ ] First exercise (expanded)
- [ ] Middle exercise
- [ ] Last exercise
- [ ] With completed sets
- [ ] With rest timer active
- [ ] Minimized state (miniplayer)

**Fitness Tab:**
- [ ] Default view (Week range)
- [ ] Month range view
- [ ] Year range view
- [ ] With all metrics populated
- [ ] Empty state (no data)
- [ ] Loading states

**Components:**
- [ ] Recovery ring card (various scores)
- [ ] Energy bank card (various levels)
- [ ] Strain progress card
- [ ] Sleep score card
- [ ] Workout day card (all states)
- [ ] Set input row
- [ ] Progress indicators

---

## Creating Mockups

### Design Tools

**Recommended:**
- **Figma** - Best for collaborative design
- **Sketch** - macOS native
- **Adobe XD** - Cross-platform

### Design Tokens

Import these values into your design tool:

**Colors:**
```
Background: #F5F5F7
Card: #FFFFFF
Primary: #5B7FFF
Success: #00C896
Warning: #F59E0B
Error: #EF4444
Text Primary: #111827
Text Secondary: #6B7280
```

**Typography:**
```
Display: SF Pro Rounded, 48pt, Bold
Title: SF Pro Rounded, 34pt, Bold
Headline: SF Pro Rounded, 24pt, Semibold
Body: SF Pro Rounded, 16pt, Medium
Caption: SF Pro Rounded, 12pt, Medium
```

**Spacing:**
```
Screen Padding: 20pt
Card Padding: 16-24pt
Card Spacing: 20pt
Component Spacing: 8-12pt
```

**Shadows:**
```
Card Shadow:
  Color: Black @ 5% opacity
  Blur: 10pt
  Offset: (0, 4pt)

Button Shadow:
  Color: Accent @ 35% opacity
  Blur: 20pt
  Offset: (0, 8pt)
```

**Corner Radius:**
```
Cards: 24pt
Buttons: 16pt
Small Elements: 8-12pt
```

### Mockup Templates

**iPhone 15 Pro Frame:**
- Width: 393pt
- Height: 852pt
- Safe Area: Top 47pt, Bottom 34pt
- Tab Bar: 49pt height

**Card Template:**
- Background: White (#FFFFFF)
- Corner Radius: 24pt
- Padding: 16-24pt
- Shadow: See above
- Border: 1pt, Gray @ 10% opacity

### Component Library

Create reusable components in your design tool:

1. **Score Cards**
   - Recovery Ring
   - Energy Bank
   - Strain Progress
   - Sleep Score

2. **Workout Cards**
   - Workout Day Card
   - Exercise Preview Row
   - Add Workout Card

3. **Inputs**
   - Text Field
   - RIR Picker
   - Set Completion Checkbox

4. **Charts**
   - Circular Progress
   - Linear Progress Bar
   - Radar Chart
   - Time Series Chart

5. **Buttons**
   - Primary Button
   - Secondary Button
   - Icon Button

---

## Screenshot Organization

### Folder Structure

```
screenshots/
├── home/
│   ├── default.png
│   ├── with-data.png
│   └── empty-state.png
├── workout/
│   ├── selection-view.png
│   ├── preview-push.png
│   ├── preview-pull.png
│   └── active-workout.png
├── fitness/
│   ├── dashboard-week.png
│   ├── dashboard-month.png
│   └── charts.png
└── components/
    ├── score-cards.png
    ├── workout-cards.png
    └── inputs.png
```

### Naming Convention

Format: `{screen}-{state}-{device}.png`

Examples:
- `home-default-iphone15pro.png`
- `workout-preview-push-iphone15pro.png`
- `fitness-dashboard-week-iphone15pro.png`

---

## App Store Screenshots

### Required Sizes

**iPhone 6.7" Display (iPhone 15 Pro Max):**
- 1290×2796 pixels

**iPhone 6.5" Display (iPhone 11 Pro Max):**
- 1242×2688 pixels

**iPhone 5.5" Display (iPhone 8 Plus):**
- 1242×2208 pixels

### Screenshot Content

**Screen 1: Home Dashboard**
- Show recovery, sleep, strain cards
- Include activity timeline
- Highlight key metrics

**Screen 2: Workout Planning**
- Weekly progress header
- Workout day cards
- Show completion status

**Screen 3: Active Workout**
- Exercise card with sets
- Show logging interface
- Highlight ease of use

**Screen 4: Fitness Analytics**
- Charts and graphs
- Show data visualization
- Highlight insights

**Screen 5: Apple Watch**
- Watch app interface
- Show workout on wrist
- Highlight convenience

---

## Testing Screenshots

### Before Taking Screenshots

1. **Clean State:**
   - Reset simulator data
   - Use fresh install
   - Or use test data

2. **Data Setup:**
   - Create sample workouts
   - Log sample sessions
   - Add recovery data

3. **UI State:**
   - Ensure no loading states
   - Hide debug overlays
   - Check for errors

### Quality Checklist

- [ ] No placeholder text
- [ ] All data populated
- [ ] No loading indicators
- [ ] Consistent styling
- [ ] Proper spacing
- [ ] Readable text
- [ ] Good contrast
- [ ] No UI glitches

---

## Automation

### Script for Batch Screenshots

Create a script to automate screenshot capture:

```bash
#!/bin/bash

# Screenshot automation script
DEVICE="iPhone 15 Pro"
SCHEME="gochange"

# Build
xcodebuild -scheme $SCHEME -destination "platform=iOS Simulator,name=$DEVICE" build

# Launch app
xcrun simctl boot "iPhone 15 Pro"
open -a Simulator

# Wait for app to launch
sleep 5

# Navigate and capture screenshots
# (Add navigation commands here)

echo "Screenshots captured!"
```

### Using UI Testing

Create UI tests that navigate and capture screenshots:

```swift
func testScreenshotHome() {
    let app = XCUIApplication()
    app.launch()
    
    // Navigate to home
    app.tabBars.buttons["Home"].tap()
    
    // Wait for content
    sleep(2)
    
    // Capture screenshot
    let screenshot = app.screenshot()
    let attachment = XCTAttachment(screenshot: screenshot)
    attachment.name = "Home Screen"
    add(attachment)
}
```

---

## Resources

### Design Assets

- SF Symbols: Use system icons
- SF Pro Rounded: System font
- Color palette: See UI_DOCUMENTATION.md

### Tools

- **Simulator**: Built into Xcode
- **Fastlane**: Screenshot automation
- **Figma**: Design mockups
- **Sketch**: Alternative design tool

### Documentation

- See `UI_DOCUMENTATION.md` for detailed specs
- See `PRD.md` for feature requirements
- See `CLAUDE.md` for architecture details

---

**Last Updated:** January 26, 2026
