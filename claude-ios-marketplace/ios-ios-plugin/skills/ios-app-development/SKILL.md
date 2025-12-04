---
name: ios-app-development
description: Expert iOS app architecture and SwiftUI implementation, including navigation, state management, Liquid Glass, and production-quality patterns.
allowed-tools: [Read, Write, Grep, Glob, Terminal]
---

# iOS App Development Skill

Create distinctive, production-grade iOS applications that balance Apple's platform conventions with unique creative expression. Implement real working SwiftUI code with exceptional attention to aesthetic details, Liquid Glass design, and fluid user experiences.

## When to Use

Apply this skill when the user asks to:
- Build complete iOS applications
- Create SwiftUI screens, views, or components
- Design iOS interfaces with modern glass effects
- Implement navigation, tab bars, or toolbars
- Create custom controls and interactive elements
- Design app icons for multiple appearance modes
- Build for iPhone, iPad, or Apple Watch

---

# PART 1: DESIGN THINKING

## Design Process

Before coding, understand the context and commit to a clear aesthetic direction:

### 1. Analyze Context
- **Purpose**: What problem does this app solve? Who uses it?
- **Platform**: iPhone, iPad, Watch, or universal?
- **Constraints**: iOS version target, performance requirements, accessibility needs
- **Differentiation**: What makes this app feel premium and memorable?

### 2. Choose Aesthetic Direction

While respecting iOS conventions, commit to a distinctive tone:

| Aesthetic | Expression in iOS |
|-----------|-------------------|
| Clean/Minimal | Apple-like restraint, SF Pro, subtle glass, generous whitespace |
| Bold/Expressive | Vibrant tints, playful animations, colorful glass effects |
| Editorial | Content-focused layouts, custom serif typography, magazine feel |
| Premium/Luxury | Refined materials, subtle depth, sophisticated color palette |
| Friendly/Approachable | Rounded shapes, warm colors, SF Pro Rounded, gentle animations |
| Technical/Professional | Data-dense, utilitarian, monospace accents, precise grid |
| Organic/Natural | Soft gradients, fluid shapes, earthy tones, slow animations |

**CRITICAL**: iOS apps must feel native while standing out. Balance platform conventions with unique personality. Bold maximalism and refined minimalism both work—the key is intentionality.

---

# PART 2: iOS DESIGN SYSTEM

## Typography

### System Fonts (Recommended for Body)
```swift
// Semantic styles - automatically support Dynamic Type
.font(.largeTitle)      // 34pt bold
.font(.title)           // 28pt bold
.font(.title2)          // 22pt bold
.font(.title3)          // 20pt semibold
.font(.headline)        // 17pt semibold
.font(.body)            // 17pt regular
.font(.callout)         // 16pt regular
.font(.subheadline)     // 15pt regular
.font(.footnote)        // 13pt regular
.font(.caption)         // 12pt regular
.font(.caption2)        // 11pt regular
```

### Custom Fonts (For Brand/Display)
```swift
// Custom display font with Dynamic Type support
Text("Welcome")
    .font(.custom("Playfair Display", size: 34, relativeTo: .largeTitle))

// Rounded system font for friendly feel
Text("Hello")
    .font(.system(.title, design: .rounded, weight: .bold))

// Monospaced for data/code
Text("$1,234.56")
    .font(.system(.title2, design: .monospaced, weight: .medium))
```

### Typography Best Practices
- Use SF Pro (system) for body text—it's optimized for iOS
- Reserve custom fonts for headlines and brand moments
- Always support Dynamic Type for accessibility
- Use semantic styles over fixed sizes

**AVOID**: Overriding Dynamic Type, using tiny fixed font sizes, mixing too many typefaces

## Color System

### Adaptive System Colors
```swift
// These automatically adapt to light/dark mode
Color(.systemBackground)           // Primary background
Color(.secondarySystemBackground)  // Elevated surfaces
Color(.tertiarySystemBackground)   // Tertiary surfaces
Color(.label)                      // Primary text
Color(.secondaryLabel)             // Secondary text
Color(.tertiaryLabel)              // Tertiary text
Color(.separator)                  // Dividers
Color(.systemFill)                 // Fills
```

### Semantic Colors
```swift
// System semantic colors
Color.accentColor      // App tint color
Color.primary          // Primary content
Color.secondary        // Secondary content

// Semantic UI colors
Color(.systemRed)
Color(.systemGreen)
Color(.systemBlue)
Color(.systemOrange)
Color(.systemYellow)
Color(.systemPink)
Color(.systemPurple)
Color(.systemTeal)
Color(.systemIndigo)
```

### Custom Brand Colors
```swift
// Define in Asset Catalog for light/dark variants
extension Color {
    static let brandPrimary = Color("BrandPrimary")
    static let brandSecondary = Color("BrandSecondary")
    static let brandAccent = Color("BrandAccent")
}

// Or define programmatically with adaptations
extension Color {
    static let customBackground = Color(
        light: Color(hex: "#FFFFFF"),
        dark: Color(hex: "#1C1C1E")
    )
}
```

### Color Best Practices
- Use semantic system colors for automatic dark mode support
- Define custom colors in Asset Catalog with light/dark variants
- Maintain 4.5:1 contrast ratio for text
- Use color meaningfully (green for success, red for errors)

## Spacing & Layout

### Standard Spacing Scale
```swift
// Apple's spacing increments
// 4, 8, 12, 16, 20, 24, 32, 40, 48, 64

.padding(4)   // Tight
.padding(8)   // Compact
.padding(12)  // Small
.padding(16)  // Standard (default)
.padding(20)  // Medium
.padding(24)  // Large
.padding(32)  // Extra large
```

### Safe Areas
```swift
// Always respect safe areas
.safeAreaInset(edge: .bottom) {
    ActionBar()
}

// Extend background to edges, content stays safe
ZStack {
    Color.blue.ignoresSafeArea()
    ContentView()  // Automatically in safe area
}
```

### Adaptive Layouts
```swift
struct AdaptiveView: View {
    @Environment(\.horizontalSizeClass) var sizeClass
    
    var body: some View {
        if sizeClass == .compact {
            // iPhone portrait
            VStack { content }
        } else {
            // iPad or iPhone landscape
            HStack { content }
        }
    }
}
```

---

# PART 3: LIQUID GLASS DESIGN

## Understanding Liquid Glass

Liquid Glass is Apple's **digital meta-material** (iOS 26+) that creates dynamic, light-bending interfaces:

### Core Properties
- **Lensing**: Dynamically bends and concentrates light for definition
- **Materiality**: Three-layered design adapting tint, shadows, and dynamic range
- **Fluidity**: Smooth, responsive motion that feels like liquid
- **Layered Architecture**: Glass controls float ABOVE content as distinct functional layer

### When to Use Glass

✅ **Use Glass For:**
- Tab bars and toolbars
- Floating action buttons
- Navigation controls and sidebars
- Menus, popovers, and sheets
- Interactive overlays

❌ **Never Use Glass For:**
- List rows or table cells
- Main content areas
- Card backgrounds within content
- Stacking glass on glass without containers

**CRITICAL PRINCIPLE**: Liquid Glass is for the **navigation layer**, not main content. Content sits at the bottom; glass controls float on top.

## Concentricity

All shapes should nest perfectly within each other, sharing a common center:
```swift
// Three shape types for concentricity:

// 1. Fixed shapes: constant corner radius
.clipShape(RoundedRectangle(cornerRadius: 12))

// 2. Capsules: radius = half the height (perfect for buttons)
.clipShape(Capsule())
.buttonBorderShape(.capsule)

// 3. Concentric shapes: radius calculated from parent
.clipShape(.rect(cornerRadius: .concentric(fallback: 12)))
```

**Design Rule**: Controls nest into rounded corners of windows/screens. If something feels off, its shape probably needs to be concentric.

## Glass Effect API

### Basic Glass Effects
```swift
// Default glass (capsule shape, blur, reflection)
.glassEffect()

// Regular glass
.glassEffect(.regular)

// Clear glass (minimal blur, subtle transparency)
.glassEffect(.clear)
```

### Tinted Glass
```swift
// Solid tint
.glassEffect(.regular.tint(.purple))

// Semi-transparent tint
.glassEffect(.regular.tint(.blue.opacity(0.7)))

// Brand color tint
.glassEffect(.regular.tint(Color.brandPrimary.opacity(0.6)))
```

### Interactive Glass
```swift
// Responds to touch with shimmer and scale
.glassEffect(.regular.interactive())

// Combined: tinted + interactive
.glassEffect(.regular.tint(.purple.opacity(0.8)).interactive())
```

### Glass Button Styles
```swift
// Standard glass button (secondary actions)
Button("Settings") { }
    .buttonStyle(.glass)

// Prominent glass button (primary actions)  
Button("Continue") { }
    .buttonStyle(.glassProminent)
    .tint(.blue)

// Glass button with custom shape
Button("Add") { }
    .buttonStyle(.glass)
    .buttonBorderShape(.circle)

// Bordered prominent (alternative primary style)
Button("Submit") { }
    .buttonStyle(.borderedProminent)
```

## GlassEffectContainer

Group glass elements for shared rendering, blending, and morphing:
```swift
struct FloatingToolbar: View {
    var body: some View {
        GlassEffectContainer(spacing: 16) {
            HStack(spacing: 16) {
                Button("Undo", systemImage: "arrow.uturn.backward") { }
                    .glassEffect()
                
                Button("Redo", systemImage: "arrow.uturn.forward") { }
                    .glassEffect()
                
                Divider().frame(height: 24)
                
                Button("Share", systemImage: "square.and.arrow.up") { }
                    .glassEffect()
            }
            .labelStyle(.iconOnly)
            .padding(.horizontal, 8)
        }
    }
}
```

**Why Use Containers:**
- Efficient rendering of multiple glass elements
- Elements blend when close together
- Required for morphing transitions
- Prevents visual artifacts

## Morphing Transitions

Create fluid morph animations using `glassEffectID`:
```swift
struct MorphingActionMenu: View {
    @State private var isExpanded = false
    @Namespace private var namespace
    
    var body: some View {
        GlassEffectContainer(spacing: 20) {
            VStack(spacing: 16) {
                // Always visible toggle button
                Button {
                    withAnimation(.bouncy) {
                        isExpanded.toggle()
                    }
                } label: {
                    Image(systemName: isExpanded ? "xmark" : "plus")
                        .font(.title2.bold())
                        .frame(width: 56, height: 56)
                        .contentTransition(.symbolEffect(.replace))
                }
                .buttonStyle(.glassProminent)
                .buttonBorderShape(.circle)
                .tint(.blue)
                .glassEffectID("toggle", in: namespace)
                
                // Morphing action buttons
                if isExpanded {
                    actionButton("camera", color: .orange)
                        .glassEffectID("camera", in: namespace)
                    
                    actionButton("photo", color: .green)
                        .glassEffectID("photo", in: namespace)
                    
                    actionButton("doc", color: .blue)
                        .glassEffectID("doc", in: namespace)
                }
            }
        }
    }
    
    func actionButton(_ icon: String, color: Color) -> some View {
        Button { } label: {
            Image(systemName: icon)
                .font(.title3)
                .frame(width: 48, height: 48)
        }
        .buttonStyle(.glass)
        .buttonBorderShape(.circle)
        .tint(color)
    }
}
```

### Morphing Requirements
1. Wrap all glass elements in `GlassEffectContainer`
2. Declare `@Namespace` property
3. Apply `glassEffectID(_:in:)` to each element
4. Use unique identifier per element
5. Animate with `withAnimation(.bouncy)`

## Glass Effect Union

Group specific elements to blend while others stay separate:
```swift
GlassEffectContainer {
    HStack(spacing: 8) {
        // These three blend together
        ForEach(0..<3) { index in
            Button("\(index)") { }
                .glassEffect()
                .glassEffectUnion(id: "group1", namespace: namespace)
        }
        
        Spacer()
        
        // This one floats separately
        Button("More") { }
            .glassEffect()
            .glassEffectUnion(id: "group2", namespace: namespace)
    }
}
```

## Glass Effect Transitions
```swift
// Transition types
.glassEffectTransition(.identity)        // No transition
.glassEffectTransition(.matchedGeometry) // Default matched geometry
.glassEffectTransition(.materialize)     // Material fade in/out

// Example
Button("Action") { }
    .glassEffect()
    .glassEffectID("button", in: namespace)
    .glassEffectTransition(.materialize)
```

---

# PART 4: APP ARCHITECTURE

## App Entry Point
```swift
import SwiftUI

@main
struct MyApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
```

## Navigation Patterns

### Tab-Based Navigation (Most Common)
```swift
struct ContentView: View {
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            Tab("Home", systemImage: "house", value: 0) {
                HomeView()
            }
            
            Tab("Search", systemImage: "magnifyingglass", value: 1) {
                SearchView()
            }
            
            Tab("Library", systemImage: "books.vertical", value: 2) {
                LibraryView()
            }
            
            Tab("Profile", systemImage: "person", value: 3) {
                ProfileView()
            }
        }
        .tint(.primary)
    }
}
```

### Tab Bar Behaviors
```swift
TabView {
    // tabs...
}
// Shrink tab bar when scrolling down
.tabBarMinimizeBehavior(.onScrollDown)

// Search tab with floating button
Tab("Search", systemImage: "magnifyingglass", value: 1, role: .search) {
    SearchView()
}
```

### Stack-Based Navigation
```swift
struct HomeView: View {
    var body: some View {
        NavigationStack {
            List(items) { item in
                NavigationLink(value: item) {
                    ItemRow(item: item)
                }
            }
            .navigationTitle("Home")
            .navigationDestination(for: Item.self) { item in
                ItemDetailView(item: item)
            }
        }
    }
}
```

### Split View (iPad)
```swift
struct ContentView: View {
    @State private var selectedItem: Item?
    
    var body: some View {
        NavigationSplitView {
            // Sidebar
            List(items, selection: $selectedItem) { item in
                Text(item.name)
            }
            .navigationTitle("Items")
        } detail: {
            // Detail view
            if let item = selectedItem {
                ItemDetailView(item: item)
            } else {
                ContentUnavailableView("Select an Item", 
                    systemImage: "doc")
            }
        }
    }
}
```

### Modal Presentation
```swift
struct ParentView: View {
    @State private var showSheet = false
    @State private var showFullScreen = false
    
    var body: some View {
        VStack {
            Button("Show Sheet") { showSheet = true }
            Button("Show Full Screen") { showFullScreen = true }
        }
        .sheet(isPresented: $showSheet) {
            SheetView()
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
        .fullScreenCover(isPresented: $showFullScreen) {
            FullScreenView()
        }
    }
}
```

## Toolbars
```swift
struct ContentView: View {
    var body: some View {
        NavigationStack {
            ContentList()
                .navigationTitle("Items")
                .toolbar {
                    // Leading items
                    ToolbarItem(placement: .topBarLeading) {
                        Button("Edit") { }
                    }
                    
                    // Trailing items
                    ToolbarItemGroup(placement: .topBarTrailing) {
                        Button("Filter", systemImage: "line.3.horizontal.decrease") { }
                        Button("Add", systemImage: "plus") { }
                    }
                    
                    // Bottom bar
                    ToolbarItemGroup(placement: .bottomBar) {
                        Button("Delete", systemImage: "trash") { }
                        Spacer()
                        Button("Share", systemImage: "square.and.arrow.up") { }
                    }
                }
        }
    }
}
```

### Toolbar with Flexible Grouping
```swift
.toolbar {
    ToolbarItemGroup(placement: .bottomBar) {
        Button("Left") { }
        ToolbarSpacer(.flexible)  // Flexible space
        Button("Center") { }
        ToolbarSpacer(.flexible)
        Button("Right") { }
    }
}
```

---

# PART 5: COMMON UI COMPONENTS

## Lists
```swift
struct ItemListView: View {
    @State private var items: [Item] = []
    
    var body: some View {
        List {
            // Sections with headers
            Section("Recent") {
                ForEach(items.prefix(5)) { item in
                    ItemRow(item: item)
                }
            }
            
            Section("All Items") {
                ForEach(items) { item in
                    ItemRow(item: item)
                        .swipeActions(edge: .trailing) {
                            Button("Delete", role: .destructive) {
                                delete(item)
                            }
                        }
                        .swipeActions(edge: .leading) {
                            Button("Pin", systemImage: "pin") {
                                pin(item)
                            }
                            .tint(.orange)
                        }
                }
            }
        }
        .listStyle(.insetGrouped)
        .searchable(text: $searchText)
        .refreshable {
            await refresh()
        }
    }
}
```

## Forms & Settings
```swift
struct SettingsView: View {
    @AppStorage("notifications") private var notifications = true
    @AppStorage("username") private var username = ""
    @State private var volume = 0.5
    
    var body: some View {
        Form {
            Section("Account") {
                TextField("Username", text: $username)
                
                NavigationLink("Privacy") {
                    PrivacySettingsView()
                }
            }
            
            Section("Preferences") {
                Toggle("Notifications", isOn: $notifications)
                
                Slider(value: $volume) {
                    Text("Volume")
                }
                
                Picker("Theme", selection: $theme) {
                    Text("System").tag(Theme.system)
                    Text("Light").tag(Theme.light)
                    Text("Dark").tag(Theme.dark)
                }
            }
            
            Section {
                Button("Sign Out", role: .destructive) {
                    signOut()
                }
            }
        }
        .navigationTitle("Settings")
    }
}
```

## Cards
```swift
struct ContentCard: View {
    let item: Item
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Image
            AsyncImage(url: item.imageURL) { image in
                image
                    .resizable()
                    .aspectRatio(16/9, contentMode: .fill)
            } placeholder: {
                Rectangle()
                    .fill(Color(.systemFill))
            }
            .frame(height: 180)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            
            // Content
            VStack(alignment: .leading, spacing: 4) {
                Text(item.title)
                    .font(.headline)
                
                Text(item.subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 4)
        }
        .padding(12)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}
```

## Custom Controls

### Segmented Picker with Glass
```swift
struct GlassSegmentedPicker: View {
    @Binding var selection: Int
    let options: [String]
    @Namespace private var namespace
    
    var body: some View {
        GlassEffectContainer(spacing: 4) {
            HStack(spacing: 4) {
                ForEach(options.indices, id: \.self) { index in
                    Button {
                        withAnimation(.bouncy) {
                            selection = index
                        }
                    } label: {
                        Text(options[index])
                            .font(.subheadline.weight(.medium))
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                    }
                    .glassEffect(
                        selection == index 
                            ? .regular.tint(.blue.opacity(0.3)) 
                            : .clear
                    )
                    .glassEffectID(options[index], in: namespace)
                }
            }
            .padding(4)
        }
    }
}
```

### Floating Action Button
```swift
struct FloatingActionButton: View {
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Image(systemName: "plus")
                .font(.title2.bold())
                .frame(width: 56, height: 56)
        }
        .buttonStyle(.glassProminent)
        .buttonBorderShape(.circle)
        .tint(.blue)
        .shadow(color: .black.opacity(0.15), radius: 8, y: 4)
    }
}

// Usage in a view
ZStack(alignment: .bottomTrailing) {
    ContentView()
    
    FloatingActionButton {
        // action
    }
    .padding(24)
}
```

---

# PART 6: ANIMATION & MOTION

## Animation Principles

- Glass elements **materialize** (fade while modulating light)
- Motion should feel **liquid**: smooth, responsive, effortless
- Keep animations under 400ms for responsiveness
- Use `.bouncy` for glass morphing

## Animation Types

### Spring Animations
```swift
// Bouncy (best for glass morphing)
withAnimation(.bouncy) { }
withAnimation(.bouncy(duration: 0.4)) { }
withAnimation(.bouncy(duration: 0.5, extraBounce: 0.1)) { }

// Natural spring
withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) { }

// Snappy
withAnimation(.snappy) { }
withAnimation(.snappy(duration: 0.3)) { }
```

### Standard Animations
```swift
// Ease in out
withAnimation(.easeInOut(duration: 0.3)) { }

// Linear
withAnimation(.linear(duration: 0.2)) { }

// Default
withAnimation { }
```

### View Transitions
```swift
// Built-in transitions
.transition(.opacity)
.transition(.scale)
.transition(.slide)
.transition(.move(edge: .bottom))

// Combined
.transition(.opacity.combined(with: .scale))

// Asymmetric
.transition(.asymmetric(
    insertion: .scale.combined(with: .opacity),
    removal: .opacity
))
```

### Symbol Effects
```swift
// Replace symbol with animation
Image(systemName: isPlaying ? "pause.fill" : "play.fill")
    .contentTransition(.symbolEffect(.replace))

// Bounce effect
Image(systemName: "heart.fill")
    .symbolEffect(.bounce, value: isFavorite)

// Pulse effect
Image(systemName: "bell.fill")
    .symbolEffect(.pulse)
```

### Phase Animations
```swift
struct PulsingView: View {
    @State private var isAnimating = false
    
    var body: some View {
        Circle()
            .fill(.blue)
            .frame(width: 100, height: 100)
            .phaseAnimator([false, true]) { content, phase in
                content
                    .scaleEffect(phase ? 1.1 : 1.0)
                    .opacity(phase ? 0.8 : 1.0)
            } animation: { _ in
                .easeInOut(duration: 1.0)
            }
    }
}
```

### Matched Geometry
```swift
struct HeroAnimation: View {
    @State private var isExpanded = false
    @Namespace private var namespace
    
    var body: some View {
        if isExpanded {
            ExpandedView()
                .matchedGeometryEffect(id: "card", in: namespace)
                .onTapGesture {
                    withAnimation(.spring(response: 0.4)) {
                        isExpanded = false
                    }
                }
        } else {
            CompactView()
                .matchedGeometryEffect(id: "card", in: namespace)
                .onTapGesture {
                    withAnimation(.spring(response: 0.4)) {
                        isExpanded = true
                    }
                }
        }
    }
}
```

---

# PART 7: DATA & STATE MANAGEMENT

## Property Wrappers
```swift
struct ContentView: View {
    // Simple state
    @State private var count = 0
    
    // Binding from parent
    @Binding var isPresented: Bool
    
    // Persistent storage
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false
    
    // Environment values
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    
    // Observable object
    @StateObject private var viewModel = ViewModel()
    
    // Observed object from parent
    @ObservedObject var store: DataStore
    
    // Environment object
    @EnvironmentObject var settings: AppSettings
}
```

## Observable Pattern (iOS 17+)
```swift
@Observable
class ItemStore {
    var items: [Item] = []
    var isLoading = false
    var errorMessage: String?
    
    func fetch() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            items = try await api.fetchItems()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

struct ItemListView: View {
    @State private var store = ItemStore()
    
    var body: some View {
        List(store.items) { item in
            ItemRow(item: item)
        }
        .overlay {
            if store.isLoading {
                ProgressView()
            }
        }
        .task {
            await store.fetch()
        }
    }
}
```

## Async/Await
```swift
struct AsyncContentView: View {
    @State private var data: [Item] = []
    @State private var isLoading = true
    
    var body: some View {
        List(data) { item in
            ItemRow(item: item)
        }
        .overlay {
            if isLoading {
                ProgressView()
            }
        }
        .task {
            // Runs when view appears, cancels on disappear
            await loadData()
        }
        .refreshable {
            // Pull to refresh
            await loadData()
        }
    }
    
    func loadData() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            data = try await fetchItems()
        } catch {
            // Handle error
        }
    }
}
```

---

# PART 8: APP ICONS

## Icon Appearance Modes

Icons must adapt to six modes:
- Default Light / Default Dark
- Clear Light / Clear Dark
- Tinted Light / Tinted Dark

## Design Guidelines

1. **Layered Design**: Separate foreground, middle, and background layers
2. **Simplified Forms**: Use solid, filled, or semi-transparent shapes
3. **System Effects**: Let system handle masking, blurring, reflections, shadows
4. **Rounded Corners**: Sharp corners scatter light unnaturally
5. **Bold Colors**: Colors should remain balanced across all modes
6. **Mono Layer**: Designate one layer as pure white for Clear/Tinted modes

## Icon Composer Workflow
```
1. Design in Figma/Sketch/Illustrator
   - Use 1024px grid (iPhone, iPad, Mac)
   - Structure as separate layers

2. Export layers as SVG or PNG

3. Import into Icon Composer (Xcode 26+)
   - Organize layers (foreground, middle, background)
   - Apply Liquid Glass properties:
     • Specular highlights
     • Blur/translucency
     • Shadows (neutral or chromatic)

4. Adjust for each appearance mode
   - Dark mode: boost contrast
   - Clear mode: set mono layer to white
   - Tinted mode: ensure grayscale works

5. Preview across platforms and wallpapers

6. Export as .icon file → Add to Xcode
```

---

# PART 9: ACCESSIBILITY

## Essential Accessibility
```swift
struct AccessibleButton: View {
    @State private var isFavorite = false
    
    var body: some View {
        Button {
            isFavorite.toggle()
        } label: {
            Image(systemName: isFavorite ? "heart.fill" : "heart")
        }
        .accessibilityLabel(isFavorite ? "Remove from favorites" : "Add to favorites")
        .accessibilityHint("Double tap to toggle favorite status")
        .sensoryFeedback(.impact, trigger: isFavorite)
    }
}
```

## Environment Adaptations
```swift
struct AdaptiveView: View {
    @Environment(\.accessibilityReduceMotion) var reduceMotion
    @Environment(\.accessibilityReduceTransparency) var reduceTransparency
    @Environment(\.dynamicTypeSize) var dynamicTypeSize
    
    var body: some View {
        ContentView()
            .animation(reduceMotion ? nil : .bouncy, value: state)
            .background(
                reduceTransparency 
                    ? Color(.systemBackground) 
                    : Color(.systemBackground).opacity(0.8)
            )
    }
}
```

## Dynamic Type Support
```swift
// Always use semantic font styles
Text("Title")
    .font(.headline)

// Or relative sizing for custom fonts
Text("Custom")
    .font(.custom("Playfair", size: 24, relativeTo: .title))

// Limit scaling if needed
Text("Fixed")
    .dynamicTypeSize(.large ... .accessibility2)
```

## Minimum Tap Targets
```swift
// Ensure 44x44pt minimum
Button("Small") { }
    .frame(minWidth: 44, minHeight: 44)
```

---

# PART 10: COMPLETE EXAMPLES

## Example 1: Meditation App
```swift
import SwiftUI

struct MeditationApp: App {
    var body: some Scene {
        WindowGroup {
            MeditationHomeView()
        }
    }
}

struct MeditationHomeView: View {
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            Tab("Today", systemImage: "sun.horizon", value: 0) {
                TodayView()
            }
            Tab("Meditate", systemImage: "leaf", value: 1) {
                MeditateView()
            }
            Tab("Sleep", systemImage: "moon.stars", value: 2) {
                SleepView()
            }
            Tab("Profile", systemImage: "person", value: 3) {
                ProfileView()
            }
        }
        .tint(.mint)
        .tabBarMinimizeBehavior(.onScrollDown)
    }
}

struct TodayView: View {
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Hero card
                    FeaturedSessionCard()
                    
                    // Quick actions with glass
                    QuickActionsSection()
                    
                    // Recent sessions
                    RecentSessionsSection()
                }
                .padding()
            }
            .background(
                LinearGradient(
                    colors: [Color.mint.opacity(0.1), Color.clear],
                    startPoint: .top,
                    endPoint: .center
                )
                .ignoresSafeArea()
            )
            .navigationTitle("Today")
        }
    }
}

struct QuickActionsSection: View {
    @Namespace private var namespace
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Quick Start")
                .font(.headline)
            
            GlassEffectContainer(spacing: 12) {
                HStack(spacing: 12) {
                    QuickActionButton(
                        icon: "timer",
                        title: "5 min",
                        color: .mint
                    )
                    .glassEffectID("5min", in: namespace)
                    
                    QuickActionButton(
                        icon: "timer",
                        title: "10 min",
                        color: .teal
                    )
                    .glassEffectID("10min", in: namespace)
                    
                    QuickActionButton(
                        icon: "timer",
                        title: "20 min",
                        color: .cyan
                    )
                    .glassEffectID("20min", in: namespace)
                }
            }
        }
    }
}

struct QuickActionButton: View {
    let icon: String
    let title: String
    let color: Color
    
    var body: some View {
        Button { } label: {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title2)
                Text(title)
                    .font(.caption.weight(.medium))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
        }
        .buttonStyle(.glass)
        .tint(color)
    }
}
```

## Example 2: Finance Dashboard
```swift
struct FinanceHomeView: View {
    @State private var selectedPeriod = 0
    @Namespace private var namespace
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Balance card
                    BalanceCard()
                    
                    // Period selector with glass
                    GlassEffectContainer(spacing: 4) {
                        HStack(spacing: 4) {
                            ForEach(["1D", "1W", "1M", "1Y"], id: \.self) { period in
                                PeriodButton(
                                    title: period,
                                    isSelected: periods[selectedPeriod] == period,
                                    namespace: namespace
                                ) {
                                    withAnimation(.bouncy) {
                                        selectedPeriod = periods.firstIndex(of: period) ?? 0
                                    }
                                }
                            }
                        }
                        .padding(4)
                    }
                    
                    // Chart
                    ChartView()
                    
                    // Transactions
                    TransactionsSection()
                }
                .padding()
            }
            .background(Color(.systemBackground))
            .navigationTitle("Portfolio")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Add", systemImage: "plus") { }
                        .buttonStyle(.glass)
                }
            }
        }
    }
}

struct BalanceCard: View {
    var body: some View {
        VStack(spacing: 8) {
            Text("Total Balance")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            
            Text("$24,532.00")
                .font(.system(size: 42, weight: .bold, design: .rounded))
            
            HStack(spacing: 4) {
                Image(systemName: "arrow.up.right")
                Text("+$1,234.56 (5.3%)")
            }
            .font(.subheadline.weight(.medium))
            .foregroundStyle(.green)
        }
        .frame(maxWidth: .infinity)
        .padding(24)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }
}

struct PeriodButton: View {
    let title: String
    let isSelected: Bool
    var namespace: Namespace.ID
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline.weight(.medium))
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
        }
        .glassEffect(isSelected ? .regular.tint(.blue.opacity(0.3)) : .clear)
        .glassEffectID(title, in: namespace)
    }
}
```

## Example 3: Photo Editor with Floating Controls
```swift
struct PhotoEditorView: View {
    @State private var showTools = false
    @Namespace private var namespace
    
    var body: some View {
        ZStack {
            // Photo canvas
            Image("sample")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .ignoresSafeArea()
            
            // Floating toolbar
            VStack {
                Spacer()
                
                GlassEffectContainer(spacing: 16) {
                    VStack(spacing: 16) {
                        // Expandable tools
                        if showTools {
                            HStack(spacing: 20) {
                                toolButton("crop", label: "Crop")
                                    .glassEffectID("crop", in: namespace)
                                toolButton("wand.and.rays", label: "Auto")
                                    .glassEffectID("auto", in: namespace)
                                toolButton("slider.horizontal.3", label: "Adjust")
                                    .glassEffectID("adjust", in: namespace)
                                toolButton("paintbrush", label: "Filters")
                                    .glassEffectID("filters", in: namespace)
                            }
                        }
                        
                        // Main toolbar
                        HStack(spacing: 24) {
                            Button("Cancel") { }
                                .buttonStyle(.glass)
                            
                            Spacer()
                            
                            Button {
                                withAnimation(.bouncy) {
                                    showTools.toggle()
                                }
                            } label: {
                                Image(systemName: showTools ? "xmark" : "slider.horizontal.3")
                                    .frame(width: 44, height: 44)
                                    .contentTransition(.symbolEffect(.replace))
                            }
                            .buttonStyle(.glassProminent)
                            .buttonBorderShape(.circle)
                            .tint(.white)
                            .glassEffectID("toggle", in: namespace)
                            
                            Spacer()
                            
                            Button("Done") { }
                                .buttonStyle(.glassProminent)
                                .tint(.blue)
                        }
                    }
                    .padding(20)
                }
            }
            .padding()
        }
    }
    
    func toolButton(_ icon: String, label: String) -> some View {
        Button { } label: {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.title3)
                Text(label)
                    .font(.caption2)
            }
            .frame(width: 60, height: 50)
        }
        .buttonStyle(.glass)
    }
}
```

---

# PART 11: ANTI-PATTERNS

## Design Anti-Patterns

❌ **Never:**
- Apply `.glassEffect()` to list rows or main content
- Stack glass on glass without `GlassEffectContainer`
- Add custom shadows/reflections to glass elements
- Use rectangular shapes where concentricity expected
- Remove scroll edge effects with custom backgrounds
- Ignore Dark/Clear/Tinted appearance modes
- Use hamburger menus (use tab bar or sidebar)
- Create non-standard gestures that conflict with system

## Code Anti-Patterns

❌ **Never:**
- Force unwrap optionals in views
- Perform heavy computation in view body
- Use `@State` for shared data (use `@Observable`)
- Ignore `@MainActor` for UI updates
- Hard-code colors that break in dark mode
- Skip accessibility labels on interactive elements
- Use tiny tap targets (minimum 44x44pt)

## Visual Anti-Patterns

❌ **Never:**
- Same aesthetic across all apps (vary your approach)
- Generic system-default styling without personality
- Overuse of glass effects everywhere
- Ignoring platform conventions entirely
- Cluttered UI without visual hierarchy

---

# DECISION FRAMEWORK
```
User Request → Analyze Requirements

├── What type of view?
│   ├── Full App → Set up App struct, navigation, tabs
│   ├── Screen → NavigationStack + content
│   ├── Component → Reusable View struct
│   └── Control → Custom interactive element

├── Does it need glass effects?
│   ├── Navigation/Toolbar → Yes, use glass
│   ├── Floating actions → Yes, use glass
│   ├── Main content → No, avoid glass
│   └── Overlays/Sheets → Consider glass

├── What aesthetic direction?
│   ├── Identify purpose and audience
│   ├── Choose tone (minimal, bold, editorial, etc.)
│   ├── Select typography approach
│   └── Define color palette

└── Implementation
    ├── Structure data model
    ├── Build view hierarchy
    ├── Add navigation
    ├── Apply styling and glass effects
    ├── Add animations
    └── Ensure accessibility
```

---

## Remember

**Design Philosophy:**
- iOS apps must feel native while expressing unique personality
- Liquid Glass floats above content—never competes with it
- Concentricity creates harmony between shapes
- Motion should feel liquid: smooth, responsive, effortless

**Code Quality:**
- Use semantic system APIs (colors, fonts, spacing)
- Support Dynamic Type and accessibility
- Test in light mode, dark mode, and all appearance variants
- Keep views focused and composable

**Aesthetic Excellence:**
- Match implementation complexity to the vision
- Maximalist designs need elaborate animations and effects
- Minimalist designs need precision and restraint
- Every pixel matters—iOS users expect polish

Build interfaces that feel inevitable—like Apple could have made them, but with your distinctive purpose.