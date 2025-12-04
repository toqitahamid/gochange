---
name: ios-app-design
description: Deep expertise in iOS 26+ Liquid Glass design. Use for SwiftUI layout, visual hierarchy, and premium Apple-quality UI styling decisions.
allowed-tools: [Read, Write, Grep, Glob]
---

# iOS Liquid Glass Design Skill

You are an expert iOS developer building production-grade SwiftUI interfaces using Apple's Liquid Glass design language for iOS 26+.

## Core Philosophy

Liquid Glass is a digital meta-material that dynamically bends and sculpts light. Key principles:

1. **Layer Separation**: Glass controls float ABOVE content as navigation layer
2. **Concentricity**: Shapes nest perfectly within each other, sharing common center
3. **Fluid Motion**: Smooth, responsive animations under 400ms using `.bouncy`
4. **System Effects**: Let system handle shadows, reflections, masking

## When to Use Glass

✅ Use for: Tab bars, toolbars, sidebars, floating action buttons, navigation controls, menus, popovers
❌ Never for: List rows, main content areas, card backgrounds, stacking glass on glass

## SwiftUI Glass APIs

### Basic Effects
```swift
.glassEffect()                              // Default capsule
.glassEffect(.regular.tint(.purple))        // Tinted
.glassEffect(.regular.interactive())        // Touch responsive
.glassEffect(.clear)                        // Minimal blur
```

### Button Styles
```swift
Button("Action") { }
    .buttonStyle(.glass)           // Secondary
    .buttonStyle(.glassProminent)  // Primary
    .buttonBorderShape(.circle)    // Shape control
```

### Grouping & Morphing
```swift
@Namespace private var namespace

GlassEffectContainer(spacing: 16) {
    Button("A") { }.glassEffect().glassEffectID("a", in: namespace)
    Button("B") { }.glassEffect().glassEffectID("b", in: namespace)
}

withAnimation(.bouncy) { isExpanded.toggle() }
```

### Tab Bar
```swift
TabView(selection: $selectedTab) {
    Tab("Home", systemImage: "house", value: 0) { HomeView() }
    Tab("Search", systemImage: "magnifyingglass", value: 1, role: .search) { SearchView() }
}
.tabBarMinimizeBehavior(.onScrollDown)
```

## Concentricity
```swift
.clipShape(.rect(cornerRadius: .concentric(fallback: 12)))
.buttonBorderShape(.capsule)
```

## Required Accessibility
```swift
.accessibilityLabel("Description")
.dynamicTypeSize(.large ... .accessibility5)
@Environment(\.accessibilityReduceTransparency) var reduceTransparency
@Environment(\.accessibilityReduceMotion) var reduceMotion
.sensoryFeedback(.impact, trigger: isPressed)
```

## Animation Patterns
```swift
withAnimation(.bouncy) { }                    // Glass morphing
withAnimation(.bouncy(duration: 0.4)) { }     // Controlled duration
.contentTransition(.symbolEffect(.replace))   // Symbol transitions
```

## Anti-Patterns — NEVER DO
- Apply `.glassEffect()` to list rows or content views
- Stack glass on glass without `GlassEffectContainer`
- Add custom shadows/reflections manually
- Use rectangular shapes where concentricity expected
- Override scroll edge effects with custom backgrounds
- Ignore Dark/Clear/Tinted appearance modes

## Backward Compatibility
```swift
@ViewBuilder
func adaptiveGlassEffect() -> some View {
    if #available(iOS 26.0, *) {
        self.glassEffect(.regular.interactive())
    } else {
        self.background(.ultraThinMaterial, in: Capsule())
    }
}
```
