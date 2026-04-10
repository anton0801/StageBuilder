import SwiftUI

struct OnboardingFlow: View {
    @EnvironmentObject var appState: ApplicationMainState
    @State private var currentPage = 0

    let pages: [OnboardingPage] = [
        OnboardingPage(
            title: "Manage construction tools",
            subtitle: "Track every drill, hammer, and saw. Know where each tool is, who's using it, and its current condition.",
            icon: "hammer.fill",
            accentIcon: "bolt.fill",
            gradient: [Color(hex: "#E8821A"), Color(hex: "#C06010")]
        ),
        OnboardingPage(
            title: "Track equipment and materials",
            subtitle: "Monitor cranes, mixers, and machinery. Keep your material inventory accurate with real-time stock levels.",
            icon: "gearshape.2.fill",
            accentIcon: "shippingbox.fill",
            gradient: [Color(hex: "#1A6AE8"), Color(hex: "#0C4DB8")]
        ),
        OnboardingPage(
            title: "Control tasks on site",
            subtitle: "Assign tasks, set deadlines, and track progress. Keep your entire crew aligned and productive.",
            icon: "checkmark.square.fill",
            accentIcon: "person.2.fill",
            gradient: [Color(hex: "#27AE60"), Color(hex: "#1A7A42")]
        )
    ]

    var body: some View {
        ZStack {
            Color.sbDarkBg.ignoresSafeArea()

            VStack(spacing: 0) {
                // Skip button
                HStack {
                    Spacer()
                    Button("Skip") {
                        withAnimation {
                            appState.hasCompletedOnboarding = true
                        }
                    }
                    .font(SBFont.subheading())
                    .foregroundColor(.white.opacity(0.5))
                    .padding(.top, 16)
                    .padding(.trailing, 24)
                }

                TabView(selection: $currentPage) {
                    ForEach(Array(pages.enumerated()), id: \.offset) { index, page in
                        OnboardingPageView(page: page)
                            .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))

                // Dots + button
                VStack(spacing: 32) {
                    HStack(spacing: 8) {
                        ForEach(0..<pages.count, id: \.self) { i in
                            Capsule()
                                .fill(i == currentPage ? Color.sbPrimary : Color.white.opacity(0.25))
                                .frame(width: i == currentPage ? 24 : 8, height: 8)
                                .animation(.spring(response: 0.4, dampingFraction: 0.7), value: currentPage)
                        }
                    }

                    if currentPage < pages.count - 1 {
                        Button(action: {
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                                currentPage += 1
                            }
                        }) {
                            HStack(spacing: 10) {
                                Text("Next")
                                    .font(SBFont.subheading())
                                Image(systemName: "arrow.right")
                                    .font(.system(size: 15, weight: .semibold))
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(LinearGradient.sbPrimaryGradient)
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        }
                        .padding(.horizontal, 24)
                    } else {
                        Button(action: {
                            withAnimation {
                                appState.hasCompletedOnboarding = true
                            }
                        }) {
                            HStack(spacing: 10) {
                                Text("Get Started")
                                    .font(SBFont.subheading())
                                Image(systemName: "arrow.right")
                                    .font(.system(size: 15, weight: .semibold))
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(LinearGradient.sbPrimaryGradient)
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        }
                        .padding(.horizontal, 24)
                    }
                }
                .padding(.bottom, 40)
            }
        }
    }
}

struct OnboardingPage {
    let title: String
    let subtitle: String
    let icon: String
    let accentIcon: String
    let gradient: [Color]
}

struct OnboardingPageView: View {
    let page: OnboardingPage
    @State private var appeared = false
    @State private var iconFloat: CGFloat = 0
    @State private var tapCount = 0

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            // Illustration area
            ZStack {
                // Background rings
                ForEach(0..<3, id: \.self) { i in
                    Circle()
                        .stroke(page.gradient[0].opacity(0.08 - Double(i) * 0.02), lineWidth: 1)
                        .frame(width: CGFloat(200 + i * 60), height: CGFloat(200 + i * 60))
                        .scaleEffect(appeared ? 1 : 0.8)
                        .animation(
                            .spring(response: 0.8, dampingFraction: 0.6).delay(Double(i) * 0.1),
                            value: appeared
                        )
                }

                // Main circle
                Circle()
                    .fill(
                        LinearGradient(
                            colors: page.gradient,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 180, height: 180)
                    .shadow(color: page.gradient[0].opacity(0.4), radius: 30, y: 12)
                    .scaleEffect(appeared ? 1 : 0.6)
                    .scaleEffect(tapCount % 2 == 1 ? 1.08 : 1.0)
                    .animation(.spring(response: 0.5, dampingFraction: 0.6).delay(0.1), value: appeared)
                    .animation(.spring(response: 0.3, dampingFraction: 0.5), value: tapCount)
                    .offset(y: iconFloat)
                    .onTapGesture { tapCount += 1 }

                // Primary icon
                Image(systemName: page.icon)
                    .font(.system(size: 54, weight: .bold))
                    .foregroundColor(.white)
                    .offset(y: iconFloat)
                    .animation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true), value: iconFloat)
                    .onTapGesture { tapCount += 1 }

                // Accent icon
                Circle()
                    .fill(.white)
                    .frame(width: 44, height: 44)
                    .shadow(color: .black.opacity(0.2), radius: 8, y: 4)
                    .overlay(
                        Image(systemName: page.accentIcon)
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(page.gradient[0])
                    )
                    .offset(x: 70, y: -60)
                    .scaleEffect(appeared ? 1 : 0)
                    .animation(.spring(response: 0.6, dampingFraction: 0.6).delay(0.4), value: appeared)

                // Hint label
                if tapCount == 0 {
                    Text("Tap to interact")
                        .font(SBFont.caption(11))
                        .foregroundColor(.white.opacity(0.4))
                        .offset(y: 110)
                }
            }
            .frame(height: 280)
            .onAppear {
                appeared = true
                withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
                    iconFloat = -8
                }
            }

            Spacer().frame(height: 48)

            // Text content
            VStack(spacing: 16) {
                Text(page.title)
                    .font(.system(size: 26, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .offset(y: appeared ? 0 : 30)
                    .opacity(appeared ? 1 : 0)
                    .animation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.3), value: appeared)

                Text(page.subtitle)
                    .font(SBFont.body())
                    .foregroundColor(.white.opacity(0.55))
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .padding(.horizontal, 32)
                    .offset(y: appeared ? 0 : 30)
                    .opacity(appeared ? 1 : 0)
                    .animation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.45), value: appeared)
            }

            Spacer()
        }
    }
}
