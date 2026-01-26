# GoChange - Product Requirements Document

**Version:** 1.0  
**Last Updated:** November 27, 2025  
**Status:** Implementation Complete

---

## Table of Contents

1. [Executive Summary](#executive-summary)
2. [Product Vision](#product-vision)
3. [Feature Requirements](#feature-requirements)
   - [iOS Application](#ios-application)
   - [Apple Watch Application](#apple-watch-application)
4. [Design System](#design-system)
5. [Technical Architecture](#technical-architecture)
6. [Data Requirements](#data-requirements)
7. [Success Metrics](#success-metrics)

---

## Executive Summary

GoChange is a comprehensive fitness and wellness application that combines workout tracking, recovery monitoring, and health data visualization into a unified, premium user experience. The application leverages Apple's HealthKit ecosystem to provide users with actionable insights about their fitness journey, supporting both iPhone and Apple Watch platforms.

### Core Value Propositions

- **Holistic Health Monitoring**: Tracks recovery, sleep, strain, and workout performance in one place
- **Real-time Workout Tracking**: Live heart rate monitoring during workouts via Apple Watch
- **Data-Driven Insights**: Advanced analytics including muscle group distribution, cardio focus, and strain vs. recovery analysis
- **Premium Design**: Modern "Liquid Glass" aesthetic with glassmorphism effects and fluid animations

---

## Product Vision

### Mission Statement

Empower users to optimize their fitness and recovery by providing comprehensive health insights in an intuitive, visually stunning interface that makes complex data simple to understand and act upon.

### Target Audience

- **Fitness Enthusiasts**: Regular gym-goers tracking strength training progress
- **Data-Driven Athletes**: Users who want detailed analytics about their performance
- **Health-Conscious Individuals**: People monitoring recovery, sleep, and overall wellness
- **Apple Watch Users**: Active users who want seamless iPhone-Watch integration

---

## Feature Requirements

### iOS Application

#### 1. Dashboard (Home View)

**Purpose**: Provide at-a-glance view of user's current health status

**Features**:
- **Three Primary Metric Cards**:
  - **Recovery Score**: HRV, Resting HR, and recovery insights
  - **Sleep Score**: Time in bed, sleep stages breakdown, sleep quality
  - **Strain Score**: Duration, active energy, workout intensity
  
- **Summary Rings**: Activity rings showing daily progress
  
- **Daily Insight Card**: Personalized recovery feedback based on recent data
  
- **Health Metrics Panel**: Real-time display of:
  - Respiratory Rate (RR)
  - SpO2 (Oxygen Saturation)
  - Body Temperature
  - Daily Steps
  - VO2 Max
  
- **Activity Timeline**: Interactive list of completed workouts with:
  - Workout-specific icons (Push, Pull, Legs, etc.)
  - Set count badges
  - Tap-to-view session details
  
**Design Specifications**:
- Light background: `#F5F5F7`
- White cards with glassmorphism
- Shadow: `radius: 15, x: 0, y: 5, opacity: 0.08`
- Border: `Color.gray.opacity(0.15), lineWidth: 1`
- Corner radius: 24pt
- Horizontal padding: 20pt from screen edges

---

#### 2. Workout Management

##### 2.1 Workout Planning View

**Purpose**: Weekly workout schedule and routine management

**Features**:
- **Weekly Progress Header**:
  - Large circular progress indicator
  - Workout count vs. weekly goal
  - Day indicators with connected timeline
  - Motivational messages (e.g., "Goal crushed! 🔥")
  
- **Workout Cards**:
  - One card per scheduled workout day
  - Dynamic SF Symbol icons based on workout type
  - Status badges ("DONE" in green)
  - Tap to view workout details
  
- **Add Workout Card**: Dashed border with blue plus icon

**Supported Workout Types**:
- Push (Upper body pressing)
- Pull (Upper body pulling)
- Legs
- Full Body
- Cardio/Running
- Arms
- Shoulders
- Core/Abs

##### 2.2 Workout Preview View

**Purpose**: Display exercise list before starting a workout

**Features**:
- **Header Card**:
  - Large workout-specific icon with gradient background
  - Workout name (28pt bold)
  - Exercise count
  
- **Exercise List**:
  - Scrollable list of exercises
  - Exercise name and muscle group
  - Dividers between items
  
- **Edit Button**: Navigate to workout customization

##### 2.3 Active Workout View

**Purpose**: Track sets, reps, and weight in real-time during workouts

**Features**:
- **Workout Timer Card**: Displays elapsed time and current heart rate (from Apple Watch)
- **Exercise Display**: Current exercise with muscle group
- **Set Input**: Weight and reps entry
- **Progress Indicator**: Set count (e.g., "Set 2/4")
- **Complete Set Button**: Log set and advance to next
- **Previous Sets History**: View recent performance for reference
- **Minimize Function**: Global workout state allowing navigation without losing progress

**Heart Rate Integration**:
- Live heart rate display from Apple Watch
- Updates in real-time during workout
- Falls back to "---" when unavailable

##### 2.4 Exercise Library

**Purpose**: Browse and manage available exercises

**Features**:
- **Filter Chips**: Filter by muscle group (Chest, Back, Legs, etc.)
- **Search**: Find exercises by name
- **Exercise Cards**: White cards with exercise name and muscle group
- **Tap to View Details**: Navigate to exercise detail view

##### 2.5 Exercise Detail View

**Purpose**: View exercise information and performance history

**Features**:
- **Header Section**:
  - Exercise name
  - Muscle group badge
  - Default sets/reps recommendation
  
- **Media Section**: Form reference (video/image)
  
- **Stats Section**: Personal records
  - Max weight
  - Max reps
  - Max volume
  
- **History Section**: Recent performance log with dates and sets
  
- **Notes Section**: User notes for form cues or tips

---

#### 3. Fitness Analytics

**Purpose**: Comprehensive fitness data visualization and analysis

**Features**:

##### 3.1 Activity Heatmap
- **GitHub-style contribution grid**: 2-month view showing intensity
- **Real Data Source**: All HealthKit workouts (including third-party apps)
- **Flexible Grid Layout**: Responsive columns filling card width
- **Color Intensity**: Visual representation of activity levels

##### 3.2 Daily Activity Summary
- **Steps**: Total daily step count
- **Distance**: Walking + Running distance (km)
- **Calories**: Active Energy Burned (kcal)
- **Exercise**: Apple Exercise Time (minutes)
- **Data Source**: Real-time HealthKit data

##### 3.3 Strength Analytics

**Strength Radar Chart**:
- **Muscle Group Distribution**: 6 muscle groups (Chest, Back, Legs, Shoulders, Core, Arms)
- **Three Metric Views**:
  - **Total Volume**: Raw weight (lbs/kg)
  - **Workout Frequency**: Number of sets per muscle group
  - **Muscular Load**: Percentage distribution across groups
- **Filter Menu**: Switch between metrics
- **Clean Design**: White grid with percentage labels

**Strength Progression Card**:
- Updates based on selected metric
- Dynamic title and empty state messages
- Historical trend visualization

##### 3.4 Cardio Analytics

**Cardio Focus Card**:
- Gauge visualization
- Clean white/teal design

**HRR (Heart Rate Reserve) Card**:
- Real Resting Heart Rate from HealthKit
- Good/Excellent rating label
- Slider visualization

##### 3.5 Strain Performance
- Chart visualizing strain vs. recovery correlation
- Helps users understand workout intensity impact

**Design Specifications**:
- Matches Home tab card design exactly
- Internal padding: 24pt vertical, 16pt horizontal
- Same shadow, border, and corner radius as Home cards
- 20pt horizontal padding for main container

---

#### 4. Recovery Monitoring

**Purpose**: Track and visualize recovery metrics

**Features**:
- **Recovery Score**: Composite score from HRV and RHR
- **HRV Tracking**: Heart Rate Variability trends
- **Resting Heart Rate**: Daily RHR monitoring
- **Insights**: Recovery recommendations
- **Theme**: Green gradient background
- **Metric Cards**: Glassmorphic design with key stats

---

#### 5. Sleep Analysis

**Purpose**: Monitor sleep quality and patterns

**Features**:
- **Sleep Score**: Overall sleep quality rating
- **Time in Bed**: Total sleep duration
- **Sleep Stages**: Breakdown of REM, Deep, Core, Awake
- **Insights**: Sleep quality recommendations
- **Theme**: Blue gradient background
- **Data Source**: HealthKit sleep analysis

---

#### 6. Strain Tracking

**Purpose**: Monitor workout intensity and energy expenditure

**Features**:
- **Strain Score**: Workout intensity rating
- **Duration**: Total workout time
- **Active Energy**: Calories burned
- **Insights**: Intensity recommendations
- **Theme**: Orange gradient background

---

### Apple Watch Application

#### 1. Workout List View

**Purpose**: Browse available workouts on watch

**Features**:
- **Liquid Glass Cards**: Glassmorphic workout cards
- **Gradient Overlays**: Color-coded by workout type
- **Empty State**: Pulsing iPhone icon with sync prompt
- **Smooth Scrolling**: Optimized for Digital Crown

**Design**:
- Translucent materials (`.ultraThinMaterial`)
- Spring animations for taps
- Edge-to-edge layouts
- Content-first design

#### 2. Active Workout View (Paginated)

**Page 1: Set Input**
- **Full-screen gradient**: Vibrant background matching workout color
- **Large Exercise Name**: Bold, 24pt SF Pro Rounded
- **Progress Ring**: Circular indicator showing set progress
- **Digital Crown Input**: Adjust weight/reps
- **Focus Indicators**: Gradient borders on active field
- **Haptic Feedback**: Tactile confirmation for changes

**Page 2: Overview**
- **Glassmorphic Stat Cards**:
  - Sets completed
  - Exercise count
  - Elapsed time
- **Animated Heart Rate**: Real-time BPM with pulsing icon
- **Translucent backgrounds**: Ultra-thin material

**Page 3: Controls**
- **Pause/Resume Button**: Secondary button style
- **End Workout**: Confirmation dialog
- **Simplified Layout**: Large, tappable controls

#### 3. Set Input View

**Purpose**: Input weight and reps during workout

**Features**:
- **Digital Crown Support**: Scroll to adjust values
- **Haptic Feedback**: Confirms input changes
- **Focus Management**: Tap to switch between weight/reps
- **Large Typography**: Easy to read while moving
- **Default Values**: Smart defaults from routine (e.g., "8-12" → 8 reps)

**Bug Fixes**:
- Fixed reps parsing for range values (extracts first number)

#### 4. WatchOS Capabilities

**Implementation Requirements**:
- **HealthKit**: Read/write workout data and heart rate
- **Background Modes**: Workout processing
- **WatchConnectivity**: Sync with iPhone
- **Info.plist**: Health permissions descriptions

**Font Optimization**:
- Optimized for Apple Watch Series 10 46mm display
- SF Pro Rounded for modern appearance

---

## Design System

### Color Palette

#### Primary Colors
- **Background**: `#F5F5F7` (Light gray)
- **Card Background**: `#FFFFFF` (White)
- **Accent Blue**: `Color.blue` (Modern iOS blue)

#### Theme Colors
- **Recovery**: Emerald green gradient
- **Sleep**: Midnight blue gradient
- **Strain**: Burnt orange gradient

#### Text Colors
- **Primary**: `.primary` (Black in light mode)
- **Secondary**: `.secondary` (Gray)

#### UI Elements
- **Shadow**: `Color.black.opacity(0.08)`
- **Border**: `Color.gray.opacity(0.15)`
- **Divider**: `Color.gray.opacity(0.1)`

### Typography

#### Hierarchy
- **Large Title**: 34pt Bold Rounded
- **Section Header**: 28pt Bold
- **Body**: 16pt Semibold
- **Caption**: 12pt Regular
- **Metadata**: 15pt Rounded

### Spacing

- **Screen Horizontal Padding**: 20pt
- **Card Vertical Padding**: 24pt
- **Card Horizontal Padding**: 16pt
- **Section Spacing**: 12-20pt

### Effects

#### Glassmorphism "Liquid Glass" Usage
- **Navigation Only**: Use frosted glass ONLY for floating tab bars, toolbars, and contextual menus.
- **Content Cards**: MUST be OPAQUE WHITE (#FFFFFF). Do NOT use glass for data cards.
- **Vibrancy**: While cards are white, the data visualizations inside (rings, charts) should be glowing, vibrant, and gradient-rich to maintain the premium "wow" factor.
- **Translucency**: Semi-transparent overlays allowed for modal backgrounds only.

#### Shadows
- **Main Cards**: `radius: 15, x: 0, y: 5, opacity: 0.08` (Soft, diffuse)
- **Sub-cards**: `radius: 10, x: 0, y: 4, opacity: 0.05`
- **Small Elements**: `radius: 8, x: 0, y: 2, opacity: 0.05`

#### Corner Radius
- **Main Cards**: 24pt
- **List Containers**: 20pt
- **Sub-components**: 12-16pt

#### Animations
- **Spring**: Fluid, natural motion
- **Haptics**: Tactile feedback on Watch
- **Transitions**: Smooth navigation

---

## Technical Architecture

### Data Layer

#### SwiftData Models
- **WorkoutSession**: Completed workouts
- **ExerciseLog**: Individual exercise performance
- **Exercise**: Exercise library
- **WorkoutDay**: Scheduled routines

#### HealthKit Integration

**Read Permissions**:
- Workouts and Routes
- Active Energy, Exercise Time, Steps
- Cycling/Swimming/Running Distances & Metrics
- Heart Rate, HRV, Resting HR
- VO2 Max, Respiratory Rate, SpO2
- Sleep Analysis
- Body Temperature

**Write Permissions**:
- Workouts
- Heart Rate (from Watch)

### Services

#### HealthKitService
- Fetches health metrics from HealthKit
- Aggregates daily activity stats
- Manages permissions

#### WorkoutManager
- Global workout state management
- Set/exercise progression logic
- Heart rate subscription from Watch

#### WatchConnectivityManager
- Syncs workout data to Watch
- Receives heart rate updates from Watch
- Manages connection state

### ViewModels

#### DashboardViewModel
- Aggregates Recovery, Sleep, Strain data
- Real-time updates from HealthKit

#### FitnessViewModel
- Fetches completed workouts from SwiftData
- Aggregates strength metrics by muscle group
- Calculates Total Volume, Frequency, and Load

### Watch Services

#### WatchWorkoutManager
- Manages active workout on Watch
- Streams heart rate to iPhone
- Handles set completion

#### WatchHealthKitService
- Authorizes HealthKit on Watch
- Provides heart rate updates

---

## Data Requirements

### HealthKit Data Flow

#### iPhone → HealthKit
- Completed workouts
- Exercise logs
- Set performance

#### HealthKit → iPhone
- HRV, Resting HR, VO2 Max
- Sleep stages and duration
- Daily steps, distance, calories
- Active energy, exercise time

#### Watch → iPhone (via WatchConnectivity)
- Real-time heart rate during workouts

#### iPhone → Watch (via WatchConnectivity)
- Workout routines
- Exercise library
- Scheduled workout days

### Local Storage (SwiftData)

- Workout history
- Exercise library
- Personal records
- User notes

---

## Success Metrics

### User Engagement
- **Daily Active Users**: Track daily app opens
- **Workout Completion Rate**: % of started workouts completed
- **Watch Adoption**: % of users with active Watch app

### Feature Adoption
- **Fitness Tab Usage**: Time spent viewing analytics
- **Heart Rate Tracking**: % of workouts with HR data
- **Filter Interactions**: Metric filter usage on Strength Radar

### Data Quality
- **HealthKit Permissions**: % of users granting full access
- **Sync Success Rate**: iPhone-Watch sync reliability
- **Data Completeness**: % of workouts with complete data

### User Satisfaction
- **Visual Appeal**: User feedback on design
- **Performance**: App launch time, view load times
- **Reliability**: Crash-free session rate

---

## Implementation Status

### ✅ Completed Features

#### iOS Application
- ✅ Dashboard with Recovery, Sleep, Strain cards
- ✅ Workout planning and scheduling
- ✅ Active workout tracking with minimize function
- ✅ Exercise library and detail views
- ✅ Fitness analytics tab with heatmap
- ✅ Strength Radar with 3 metric views
- ✅ Real-time heart rate from Watch
- ✅ Session detail view
- ✅ HealthKit integration (comprehensive permissions)
- ✅ Modern light theme design system
- ✅ Glassmorphism effects
- ✅ Premium background gradients

#### Apple Watch Application
- ✅ Workout list with Liquid Glass design
- ✅ Active workout view (3-page layout)
- ✅ Set input with Digital Crown
- ✅ Heart rate streaming to iPhone
- ✅ WatchConnectivity sync
- ✅ Workout controls (pause, resume, end)
- ✅ Optimized fonts for Series 10
- ✅ Haptic feedback

### Design System
- ✅ Consistent card styling across all views
- ✅ Light theme (#F5F5F7 background)
- ✅ Modern blue accent color
- ✅ Workout-specific SF Symbol icons
- ✅ Premium shadows and borders
- ✅ Typography hierarchy
- ✅ Progressive Overload Suggestions
- ✅ Rest Timer with Live Activity
- ✅ Form Reference (Photo/Video)
- ✅ Home Screen & Lock Screen Widgets

---

## Future Enhancements

### Potential Features
- **Social Integration**: Share workouts with friends
- **Nutrition Logging**: Meal tracking and macros
- **Training Programs**: Pre-built workout plans
- **Plate Calculator**: Calculate barbell loading
- **Advanced Analytics**: ML-powered insights

### Platform Expansion
- **iPad App**: Optimized tablet experience
- **Shortcuts Integration**: Siri workout start
- **Focus Mode**: Workout-specific Focus mode integration

---

## Appendix

### Technology Stack
- **Language**: Swift
- **UI Framework**: SwiftUI
- **Data Persistence**: SwiftData
- **Health Integration**: HealthKit
- **Watch Communication**: WatchConnectivity
- **Minimum iOS Version**: iOS 17.0+
- **Minimum watchOS Version**: watchOS 10.0+

### Key Dependencies
- Foundation
- SwiftUI
- SwiftData
- HealthKit
- WatchConnectivity
- Combine
- ActivityKit (for Live Activities)

### Design References
- **watchOS 26 "Liquid Glass"**: Watch app aesthetic inspiration
- **iOS Design Guidelines**: Apple Human Interface Guidelines
- **Glassmorphism**: Modern UI trend with translucent materials

---

**Document Owner**: Product Team  
**Technical Lead**: Development Team  
**Last Review**: November 27, 2025
