import SwiftUI

struct SplashView: View {
    @State private var logoScale: CGFloat = 0.4
    @State private var logoOpacity: Double = 0
    @State private var textOpacity: Double = 0
    @State private var ringScale: CGFloat = 0.6
    @State private var ringOpacity: Double = 0
    @State private var particlesVisible = false
    @State private var subtitleOffset: CGFloat = 20
    @Environment(\.colorScheme) var scheme

    var body: some View {
        ZStack {
            // Background
            LinearGradient(
                colors: [Color(hex: "#1A1410"), Color(hex: "#2C1F10"), Color(hex: "#0E0A06")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            // Particle grid background
            ParticleGrid()
                .opacity(particlesVisible ? 0.3 : 0)
                .animation(.easeIn(duration: 1.2).delay(0.5), value: particlesVisible)

            // Ambient glow
            Circle()
                .fill(Color.sbPrimary.opacity(0.15))
                .frame(width: 400, height: 400)
                .blur(radius: 80)
                .offset(y: -50)

            VStack(spacing: 0) {
                Spacer()

                // Logo container
                ZStack {
                    // Pulsing ring
                    Circle()
                        .stroke(Color.sbPrimary.opacity(0.25), lineWidth: 1)
                        .frame(width: 130, height: 130)
                        .scaleEffect(ringScale)
                        .opacity(ringOpacity)

                    Circle()
                        .stroke(Color.sbPrimary.opacity(0.12), lineWidth: 1)
                        .frame(width: 160, height: 160)
                        .scaleEffect(ringScale * 0.95)
                        .opacity(ringOpacity * 0.7)

                    // Logo background
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color(hex: "#E8821A"), Color(hex: "#8B3A05")],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 100, height: 100)
                        .shadow(color: Color.sbPrimary.opacity(0.5), radius: 20, y: 8)

                    // Icon composition
                    ZStack {
                        Image(systemName: "building.2.fill")
                            .font(.system(size: 22, weight: .bold))
                            .foregroundColor(.white.opacity(0.9))
                            .offset(x: -8, y: 5)

                        Image(systemName: "hammer.fill")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.white)
                            .offset(x: 10, y: -8)
                            .rotationEffect(.degrees(-30))
                    }
                }
                .scaleEffect(logoScale)
                .opacity(logoOpacity)

                Spacer().frame(height: 32)

                // App name
                VStack(spacing: 6) {
                    HStack(spacing: 0) {
                        Text("Stage")
                            .font(.system(size: 38, weight: .black, design: .rounded))
                            .foregroundColor(.white)
                        Text("Builder")
                            .font(.system(size: 38, weight: .black, design: .rounded))
                            .foregroundColor(.sbPrimary)
                    }

                    Text("Control your construction site.")
                        .font(.system(size: 15, weight: .medium, design: .rounded))
                        .foregroundColor(.white.opacity(0.5))
                        .offset(y: subtitleOffset)
                }
                .opacity(textOpacity)

                Spacer()

                // Loading indicator
                HStack(spacing: 6) {
                    ForEach(0..<3, id: \.self) { i in
                        LoadingDot(delay: Double(i) * 0.2)
                    }
                }
                .opacity(textOpacity)
                .padding(.bottom, 60)
            }
        }
        .onAppear { animate() }
    }

    func animate() {
        withAnimation(.spring(response: 0.7, dampingFraction: 0.6).delay(0.2)) {
            logoScale = 1.0
            logoOpacity = 1.0
        }
        withAnimation(.easeOut(duration: 0.8).delay(0.3)) {
            ringScale = 1.0
            ringOpacity = 1.0
        }
        withAnimation(.easeOut(duration: 0.6).delay(0.6)) {
            textOpacity = 1.0
            subtitleOffset = 0
        }
        particlesVisible = true

        // Ring pulse
        withAnimation(.easeInOut(duration: 1.8).repeatForever(autoreverses: true).delay(1.0)) {
            ringScale = 1.05
        }
    }
}

struct LoadingDot: View {
    let delay: Double
    @State private var scale: CGFloat = 0.5
    @State private var opacity: Double = 0.3

    var body: some View {
        Circle()
            .fill(Color.sbPrimary)
            .frame(width: 7, height: 7)
            .scaleEffect(scale)
            .opacity(opacity)
            .onAppear {
                withAnimation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true).delay(delay + 1.0)) {
                    scale = 1.0
                    opacity = 1.0
                }
            }
    }
}

struct ParticleGrid: View {
    var body: some View {
        Canvas { context, size in
            let spacing: CGFloat = 40
            let cols = Int(size.width / spacing) + 1
            let rows = Int(size.height / spacing) + 1
            for col in 0...cols {
                for row in 0...rows {
                    let x = CGFloat(col) * spacing
                    let y = CGFloat(row) * spacing
                    let rect = CGRect(x: x - 1, y: y - 1, width: 2, height: 2)
                    context.fill(Path(ellipseIn: rect), with: .color(.white.opacity(0.4)))
                }
            }
        }
        .ignoresSafeArea()
    }
}
