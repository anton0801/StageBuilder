import SwiftUI

@main
struct StageBuilderApp: App {
    @StateObject private var appState = AppState()
    @StateObject private var dataStore = DataStore()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(appState)
                .environmentObject(dataStore)
                .preferredColorScheme(appState.colorScheme)
        }
    }
}

struct RootView: View {
    @EnvironmentObject var appState: AppState
    @State private var showSplash = true

    var body: some View {
        Group {
            if showSplash {
                SplashView()
                    .transition(.opacity)
            } else if !appState.hasCompletedOnboarding {
                OnboardingFlow()
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing),
                        removal: .move(edge: .leading)
                    ))
            } else if !appState.isLoggedIn {
                WelcomeView()
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing),
                        removal: .move(edge: .leading)
                    ))
            } else {
                MainTabView()
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing),
                        removal: .move(edge: .leading)
                    ))
            }
        }
        .animation(.spring(response: 0.5, dampingFraction: 0.8), value: showSplash)
        .animation(.spring(response: 0.5, dampingFraction: 0.8), value: appState.isLoggedIn)
        .animation(.spring(response: 0.5, dampingFraction: 0.8), value: appState.hasCompletedOnboarding)
        .onAppear {
            NotificationsManager.shared.checkAuthorization()
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.8) {
                withAnimation { showSplash = false }
            }
        }
    }
}
