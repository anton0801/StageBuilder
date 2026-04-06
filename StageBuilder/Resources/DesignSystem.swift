import SwiftUI

// MARK: - Color Palette
extension Color {
    // Primary palette — industrial amber/steel
    static let sbPrimary       = Color(hex: "#E8821A")   // Construction amber
    static let sbPrimaryDark   = Color(hex: "#C06010")
    static let sbPrimaryLight  = Color(hex: "#F4A94E")
    static let sbAccent        = Color(hex: "#1A6AE8")   // Blueprint blue
    static let sbAccentGreen   = Color(hex: "#27AE60")   // Ready/active
    static let sbAccentRed     = Color(hex: "#E82B1A")   // Alert/error
    static let sbAccentYellow  = Color(hex: "#F4D050")   // Warning

    // Surface palette
    static let sbBackground    = Color(hex: "#F5F2EE")   // Off-white concrete
    static let sbSurface       = Color(hex: "#FFFFFF")
    static let sbSurface2      = Color(hex: "#EDE9E3")
    static let sbBorder        = Color(hex: "#D4CEC6")

    // Dark mode
    static let sbDarkBg        = Color(hex: "#141210")
    static let sbDarkSurface   = Color(hex: "#1E1C18")
    static let sbDarkSurface2  = Color(hex: "#2A2720")
    static let sbDarkBorder    = Color(hex: "#3A3630")

    // Text
    static let sbTextPrimary   = Color(hex: "#1A1714")
    static let sbTextSecondary = Color(hex: "#6B6560")
    static let sbTextTertiary  = Color(hex: "#9E9890")

    // Convenience aliases
    static let sbGreen  = Color(hex: "#27AE60")
    static let sbRed    = Color(hex: "#E82B1A")
    static let sbDarkBG = Color(hex: "#141210")

    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(.sRGB,
                  red: Double(r) / 255,
                  green: Double(g) / 255,
                  blue: Double(b) / 255,
                  opacity: Double(a) / 255)
    }
}

// MARK: - Gradients
extension LinearGradient {
    static let sbPrimaryGradient = LinearGradient(
        colors: [.sbPrimary, .sbPrimaryDark],
        startPoint: .topLeading, endPoint: .bottomTrailing
    )
    static let sbCardGradient = LinearGradient(
        colors: [Color.white.opacity(0.12), Color.white.opacity(0.04)],
        startPoint: .topLeading, endPoint: .bottomTrailing
    )
    static let sbHeroGradient = LinearGradient(
        colors: [Color(hex: "#E8821A"), Color(hex: "#C06010"), Color(hex: "#8B3A05")],
        startPoint: .top, endPoint: .bottom
    )
}

// MARK: - Typography
struct SBFont {
    static func title(_ size: CGFloat = 28) -> Font {
        .system(size: size, weight: .bold, design: .rounded)
    }
    static func heading(_ size: CGFloat = 20) -> Font {
        .system(size: size, weight: .semibold, design: .rounded)
    }
    static func subheading(_ size: CGFloat = 16) -> Font {
        .system(size: size, weight: .medium, design: .rounded)
    }
    static func body(_ size: CGFloat = 15) -> Font {
        .system(size: size, weight: .regular, design: .rounded)
    }
    static func caption(_ size: CGFloat = 12) -> Font {
        .system(size: size, weight: .medium, design: .rounded)
    }
    static func mono(_ size: CGFloat = 13) -> Font {
        .system(size: size, weight: .medium, design: .monospaced)
    }
}

// MARK: - Shared Components

struct SBCard<Content: View>: View {
    let content: Content
    var padding: CGFloat = 16
    @Environment(\.colorScheme) var scheme

    init(padding: CGFloat = 16, @ViewBuilder content: () -> Content) {
        self.padding = padding
        self.content = content()
    }

    var body: some View {
        content
            .padding(padding)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(scheme == .dark ? Color.sbDarkSurface : Color.sbSurface)
                    .shadow(color: Color.black.opacity(scheme == .dark ? 0.3 : 0.07), radius: 10, x: 0, y: 4)
            )
    }
}

struct SBPrimaryButton: View {
    let title: String
    let icon: String?
    let action: () -> Void
    var isLoading: Bool = false
    var isFullWidth: Bool = true

    init(_ title: String, icon: String? = nil, isLoading: Bool = false, isFullWidth: Bool = true, action: @escaping () -> Void) {
        self.title = title
        self.icon = icon
        self.isLoading = isLoading
        self.isFullWidth = isFullWidth
        self.action = action
    }

    @State private var isPressed = false

    var body: some View {
        Button(action: {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) { isPressed = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) { isPressed = false }
            }
            action()
        }) {
            HStack(spacing: 8) {
                if isLoading {
                    ProgressView().tint(.white).scaleEffect(0.8)
                } else {
                    if let icon = icon {
                        Image(systemName: icon).font(.system(size: 16, weight: .semibold))
                    }
                    Text(title).font(SBFont.subheading())
                }
            }
            .foregroundColor(.white)
            .frame(maxWidth: isFullWidth ? .infinity : nil)
            .padding(.vertical, 16)
            .padding(.horizontal, isFullWidth ? 24 : 28)
            .background(LinearGradient.sbPrimaryGradient)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .scaleEffect(isPressed ? 0.97 : 1.0)
            .shadow(color: Color.sbPrimary.opacity(0.4), radius: isPressed ? 4 : 10, y: isPressed ? 2 : 6)
        }
    }
}

struct SBSecondaryButton: View {
    let title: String
    let action: () -> Void
    @Environment(\.colorScheme) var scheme

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(SBFont.subheading())
                .foregroundColor(.sbPrimary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(Color.sbPrimary, lineWidth: 1.5)
                        .background(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(Color.sbPrimary.opacity(0.05))
                        )
                )
        }
    }
}

struct SBTextField: View {
    let placeholder: String
    @Binding var text: String
    var icon: String? = nil
    var keyboardType: UIKeyboardType = .default
    var isSecure: Bool = false
    @Environment(\.colorScheme) var scheme
    @FocusState private var focused: Bool

    var body: some View {
        HStack(spacing: 12) {
            if let icon = icon {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(focused ? .sbPrimary : .sbTextSecondary)
                    .frame(width: 20)
                    .animation(.easeInOut(duration: 0.2), value: focused)
            }
            if isSecure {
                SecureField(placeholder, text: $text)
                    .font(SBFont.body())
                    .keyboardType(keyboardType)
                    .focused($focused)
            } else {
                TextField(placeholder, text: $text)
                    .font(SBFont.body())
                    .keyboardType(keyboardType)
                    .focused($focused)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(scheme == .dark ? Color.sbDarkSurface2 : Color.sbSurface2)
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(focused ? Color.sbPrimary : Color.clear, lineWidth: 1.5)
                )
        )
        .animation(.easeInOut(duration: 0.2), value: focused)
    }
}

struct SBBadge: View {
    let text: String
    let color: Color

    var body: some View {
        Text(text)
            .font(SBFont.caption(11))
            .foregroundColor(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(color)
            .clipShape(Capsule())
    }
}

struct SBStatusDot: View {
    let status: ToolCondition

    var body: some View {
        Circle()
            .fill(status.color)
            .frame(width: 8, height: 8)
            .overlay(
                Circle().stroke(status.color.opacity(0.3), lineWidth: 3)
            )
    }
}

struct SBEmptyState: View {
    let icon: String
    let title: String
    let subtitle: String

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 48, weight: .light))
                .foregroundColor(.sbTextTertiary)
            Text(title)
                .font(SBFont.heading())
                .foregroundColor(.sbTextSecondary)
            Text(subtitle)
                .font(SBFont.body())
                .foregroundColor(.sbTextTertiary)
                .multilineTextAlignment(.center)
        }
        .padding(40)
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Navigation Bar Style
struct SBNavigationModifier: ViewModifier {
    let title: String
    @Environment(\.colorScheme) var scheme

    func body(content: Content) -> some View {
        content
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.large)
    }
}

extension View {
    func sbNavStyle(_ title: String) -> some View {
        modifier(SBNavigationModifier(title: title))
    }
}
