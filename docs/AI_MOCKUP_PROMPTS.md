# AI Mockup Generation Prompts for GoChange

**Purpose:** Detailed prompts for generating UI mockups using AI image generation tools (DALL-E, Midjourney, Stable Diffusion, etc.)

---

## Prompt Guidelines

- Use aspect ratio: **9:16** (portrait, iPhone screen)
- Style: **Photorealistic iOS app mockup**
- Include: **iPhone frame, realistic shadows, clean UI**
- Colors: Match the design system exactly

---

## Screen 1: Home Dashboard (JournalView)

### Prompt:
```
A photorealistic iPhone 15 Pro mockup showing a fitness app home screen. The screen has a light gray background (#F5F5F7). At the top is a header with "January 26, 2026" in small gray text and "Good Morning" in large bold text, with a circular profile button on the right showing "TT" initials. Below is a blue pill-shaped card saying "Next: Push Workout". 

The main content shows a 2x2 grid of score cards:
- Top left: A circular progress ring card showing "85%" in the center with "Recovery" label below and "Prime" status in green
- Top right: A battery icon card showing "65%" energy level with "Energy" label and "Good" status
- Bottom left: A full-width card showing "12.5 / 21" strain score with a progress bar and "Optimal" status in green
- Bottom right: A full-width card showing "7h 30m" sleep duration with a purple bar showing sleep stages and "78%" score

Below is a row of 5 small metric cards showing: HRV 45ms, RHR 58 bpm, RR 14, SpO2 98%, VO2 Max 42. Then a white card with a sparkles icon and "Daily Insight" text saying "You are well recovered. Ready to train hard!"

At the bottom is an activity timeline showing recent workouts. The entire design uses clean white cards with subtle shadows, rounded corners (24pt), and modern iOS typography. Ultra-realistic, professional app mockup, soft lighting, iPhone frame visible.
```

---

## Screen 2: Workout Planning (WorkoutDaySelectionView)

### Prompt:
```
A photorealistic iPhone 15 Pro mockup showing a workout planning screen. Light gray background (#F5F5F7). Top header shows "Workout" in large bold text and "Your Training Plan" subtitle, with a chart icon button on the right.

Below is a large white card with rounded corners showing weekly progress:
- Left side: "WEEKLY GOAL" label, large "3 / 4" text, "Almost there!" message in blue
- Right side: A circular progress ring (88pt diameter) showing 75% completion in blue gradient, with "75%" in the center
- Below: Four day indicators (D1, D2, D3, D4) connected by a line, with checkmarks on D1, D2, D3

Below are workout day cards, each white with rounded corners:
- Card 1: Left side has a teal gradient icon (64x64pt) with checkmark, center shows "DAY 1" label, "DONE" green badge, "Push" workout name, "5 Exercises" label, right side has chevron
- Card 2: Similar but purple icon, "DAY 2", "Pull", completed
- Card 3: Similar but light blue icon, "DAY 3", "Legs", not completed
- Card 4: Similar but sky blue icon, "DAY 4", "Fullbody", not completed

At the bottom is a glassmorphic "Add Workout" card with a plus icon. All cards have subtle shadows and 1pt gray borders. Ultra-realistic iOS app design, clean typography, professional spacing.
```

---

## Screen 3: Workout Preview

### Prompt:
```
A photorealistic iPhone 15 Pro mockup showing a workout preview screen. Light gray background (#F5F5F7). Navigation bar shows back arrow, "Pull" title, and edit icon.

Main content shows a white card with rounded corners (24pt radius):
- Top section: Left side has a purple gradient icon (64x64pt) with rowing figure icon, center shows "DAY 2" label and "Pull" in large bold text
- Divider line
- Bottom section: Three stat badges showing "5 Exercises | 15 Sets | 30 min"

Below is an "EXERCISES" section header with "5" badge. Then a white card listing exercises:
- Row 1: Number badge "1" in purple, "Lat Pulldown" name, "Back • 3 × 12" details, chevron
- Row 2: Number badge "2", "Dumbbell Rows", "Back • 3 × 12", chevron
- Row 3: Number badge "3", "Rear Delt Flyes", "Shoulders • 3 × 15", chevron
- (More rows visible)

At the bottom is a sticky gradient button (purple to darker purple) saying "Start Workout" with play icon, white text, rounded corners, shadow. The button has a gradient fade effect above it. Ultra-realistic iOS design, clean cards, professional spacing.
```

---

## Screen 4: Active Workout View

### Prompt:
```
A photorealistic iPhone 15 Pro mockup showing an active workout screen. Light gray background (#F5F5F7). Top bar shows elapsed time "12:34" in gray pill, "PUSH" workout name centered in uppercase, and X close button.

Below is a controls row with "Pause" button (gray) and "Finish Workout" button (green capsule).

Main content shows an exercise card (white, rounded corners):
- Header: "Bench Press" in bold, "Chest • 3 × 8" subtitle, "2/3" completion indicator, chevron down
- Expanded section shows table headers: "SET | TARGET | WEIGHT | REPS | RIR | ✓"
- Set rows:
  - Set 1: "1" | "8" | "135 lbs" | "8" | "2" | green checkmark (completed)
  - Set 2: "2" | "8" | "135 lbs" | "8" | "2" | green checkmark (completed)
  - Set 3: "3" | "8" | "140 lbs" | "8" | "2" | empty circle (not completed)
- Bottom row: "+ Add Set" button (blue) and "Notes" button

The card has subtle shadow and border. Page indicator dots at bottom show "1 of 5". Ultra-realistic iOS workout app, clean interface, professional design.
```

---

## Screen 5: Fitness Analytics Dashboard

### Prompt:
```
A photorealistic iPhone 15 Pro mockup showing a fitness analytics screen. Light gray background (#F5F5F7). Top shows "Fitness" in large bold text and a time range picker showing "Week | Month | Year".

Main content scrolls showing multiple white cards:

1. Daily Readiness Card: Large "78%" score in green, "Prime Time. Go for PRs." message, progress bar below

2. Two side-by-side cards:
   - Sleep Debt: "2.3 hours" in green, "Well Rested" status
   - ACWR: "1.1" ratio in green, "Sweet Spot" status with range indicator

3. Activity Heatmap: Two month grids side by side showing GitHub-style contribution grid with colored squares (gray, light green, green, blue) representing workout frequency

4. Activity Summary Card: Four metrics in 2x2 grid - "8,234 Steps", "5.2 km Distance", "342 Kcal", "45 min Exercise"

5. Cardio Section header "Cardio" with:
   - Cardio Load card showing "425" value and mini line chart
   - Two side cards: Cardio Focus (65%) and HRR (58 bpm)

6. Strength Section header "Strength" with:
   - Radar chart card showing 6-axis chart (Chest, Back, Legs, Shoulders, Core, Arms) with menu selector
   - Strength Progression card

All cards use white background, 24pt corner radius, subtle shadows, clean typography. Ultra-realistic iOS app mockup, professional design.
```

---

## Screen 6: Component Showcase

### Prompt:
```
A photorealistic iPhone 15 Pro mockup showing various UI components from a fitness app. Light gray background (#F5F5F7). Multiple component examples arranged:

1. Score Cards (2x2 grid):
   - Recovery Ring: Circular progress (85%), green ring, "Prime" status
   - Energy Bank: Battery icon, 65% filled, "Good" status
   - Strain Progress: "12.5 / 21" with progress bar, "Optimal"
   - Sleep Score: "7h 30m", purple bar, "78%"

2. Workout Day Card: Teal icon, "DAY 1", "Push", "5 Exercises", chevron

3. Input Components:
   - Text field: Gray rounded input showing "135"
   - RIR Picker: Menu showing "2"
   - Checkbox: Green filled circle with checkmark

4. Progress Indicators:
   - Circular progress ring (75% blue)
   - Linear progress bar (green fill)

5. Buttons:
   - Primary: Blue gradient "Start Workout" button
   - Secondary: Gray "Pause" button
   - Icon: Circular button with chart icon

All components use white cards, 24pt corners, subtle shadows, clean iOS design. Ultra-realistic mockup, professional spacing.
```

---

## Screen 7: Apple Watch App

### Prompt:
```
A photorealistic Apple Watch Series 10 (46mm) mockup showing a workout app interface. Circular watch face with dark background. The screen shows:

Top: "Workouts" title in white text
Main content: Three workout cards in glassmorphic style:
- Card 1: Teal gradient background, "Push" text, checkmark icon (completed)
- Card 2: Purple gradient background, "Pull" text, play icon
- Card 3: Light blue gradient background, "Legs" text, play icon

Each card has rounded corners, subtle blur effect, white text, and is swipeable. The design uses liquid glass aesthetic with translucent backgrounds, soft shadows, and modern watchOS typography.

Bottom: Digital Crown visible on watch frame. Ultra-realistic Apple Watch mockup, professional design, soft lighting.
```

---

## Usage Instructions

### For Bing Image Creator / DALL-E:
1. Copy the prompt for the desired screen
2. Add: "Aspect ratio: 9:16, photorealistic, iPhone mockup, professional design"
3. Generate image
4. Download and save with naming: `mockup-{screen-name}.png`

### For Midjourney:
1. Use prompt format: `/imagine prompt: [copy prompt] --ar 9:16 --style raw`
2. Add: `--v 6` for latest version

### For Stable Diffusion:
1. Use prompt with negative: `(bad quality, blurry, distorted)`
2. Set aspect ratio to 9:16
3. Use realistic checkpoint models

### Post-Processing:
- Crop to exact iPhone dimensions if needed
- Adjust colors to match design system exactly
- Add iPhone frame overlay if desired
- Ensure text is readable (may need manual overlay)

---

## Design System Reference

**Colors:**
- Background: #F5F5F7
- Cards: #FFFFFF
- Primary: #5B7FFF
- Success: #00C896
- Warning: #F59E0B
- Error: #EF4444

**Typography:**
- Headers: Bold, 28-34pt
- Body: Semibold, 16-18pt
- Captions: Medium, 12-13pt

**Spacing:**
- Screen padding: 20pt
- Card padding: 16-24pt
- Card radius: 24pt

---

**Last Updated:** January 26, 2026
