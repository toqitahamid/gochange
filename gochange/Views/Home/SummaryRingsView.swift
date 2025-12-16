import SwiftUI

struct SummaryRingsView: View {
    let strain: Int
    let recovery: Int
    let sleep: Int
    
    @State private var showingStrainDetailView = false
    @State private var showingRecoveryDetailSheet = false
    @State private var showingSleepView = false
    @StateObject private var dashboardViewModel = HomeViewModel()
    
    var body: some View {
        HStack(spacing: 16) {
            // Strain Ring (Tappable)
            Button {
                showingStrainDetailView = true
            } label: {
                RingItem(
                    title: "Strain",
                    score: strain,
                    color: Color(hex: "#FF9500"), // Orange
                    gradient: LinearGradient(
                        colors: [Color(hex: "#FF9500"), Color(hex: "#FF5E3A")],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            }
            .buttonStyle(.plain)
            .sheet(isPresented: $showingStrainDetailView) {
                NavigationStack {
                    StrainDetailView()
                }
            }
            
            Divider()
                .frame(height: 60)
                .overlay(Color.gray.opacity(0.2))
            
            // Recovery Ring (Tappable)
            Button {
                showingRecoveryDetailSheet = true
            } label: {
                RingItem(
                    title: "Recovery",
                    score: recovery,
                    color: Color(hex: "#4CD964"), // Green
                    gradient: LinearGradient(
                        colors: [Color(hex: "#4CD964"), Color(hex: "#34AADC")],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            }
            .buttonStyle(.plain)
            .sheet(isPresented: $showingRecoveryDetailSheet) {
                NavigationStack {
                    RecoveryDetailSheet()
                }
                .environmentObject(dashboardViewModel)
            }
            
            Divider()
                .frame(height: 60)
                .overlay(Color.gray.opacity(0.2))
            
            // Sleep Ring (Tappable)
            Button {
                showingSleepView = true
            } label: {
                RingItem(
                    title: "Sleep",
                    score: sleep,
                    color: Color(hex: "#5AC8FA"), // Blue
                    gradient: LinearGradient(
                        colors: [Color(hex: "#5AC8FA"), Color(hex: "#007AFF")],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            }
            .buttonStyle(.plain)
            .sheet(isPresented: $showingSleepView) {
                NavigationStack {
                    SleepView()
                }
                .environmentObject(dashboardViewModel)
            }
        }
        .padding(.vertical, 24)
        .padding(.horizontal, 16)
        .background {
            RoundedRectangle(cornerRadius: 24)
                .fill(Color.white) // Solid white for better contrast
                .shadow(color: Color.black.opacity(0.08), radius: 15, x: 0, y: 5) // Slightly stronger shadow
                .overlay(
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(Color.gray.opacity(0.15), lineWidth: 1) // Slightly stronger border
                )
        }
    }
}

struct RingItem: View {
    let title: String
    let score: Int
    let color: Color
    let gradient: LinearGradient
    
    var body: some View {
        VStack(spacing: 12) {
            ZStack {
                // Background Track
                Circle()
                    .stroke(Color.gray.opacity(0.1), lineWidth: 8)
                    .frame(width: 80, height: 80)
                
                // Progress Ring
                CircularProgressView(
                    progress: Double(score) / 100.0,
                    lineWidth: 8,
                    gradient: gradient,
                    trackColor: .clear
                )
                .frame(width: 80, height: 80)
                
                // Score Text
                Text("\(score)%")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
            }
            
            Text(title)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    ZStack {
        Color(hex: "#F2F2F7").ignoresSafeArea()
        SummaryRingsView(strain: 34, recovery: 82, sleep: 75)
            .padding()
    }
}
