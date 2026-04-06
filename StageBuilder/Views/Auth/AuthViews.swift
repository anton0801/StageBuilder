import SwiftUI

// MARK: - Welcome View
struct WelcomeView: View {
    @EnvironmentObject var appState: AppState
    @State private var showLogin = false
    @State private var showSignUp = false
    @State private var appeared = false

    var body: some View {
        NavigationView {
            ZStack {
                // Dark background
                Color(hex: "#0E0A06").ignoresSafeArea()

                // Ambient glow
                Circle()
                    .fill(Color.sbPrimary.opacity(0.12))
                    .frame(width: 500)
                    .blur(radius: 100)
                    .offset(y: -100)
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    Spacer()

                    // Logo
                    VStack(spacing: 20) {
                        ZStack {
                            Circle()
                                .fill(LinearGradient.sbPrimaryGradient)
                                .frame(width: 90, height: 90)
                                .shadow(color: Color.sbPrimary.opacity(0.5), radius: 20)

                            ZStack {
                                Image(systemName: "building.2.fill")
                                    .font(.system(size: 20, weight: .bold))
                                    .foregroundColor(.white.opacity(0.8))
                                    .offset(x: -7, y: 5)
                                Image(systemName: "hammer.fill")
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(.white)
                                    .offset(x: 9, y: -7)
                                    .rotationEffect(.degrees(-30))
                            }
                        }
                        .scaleEffect(appeared ? 1 : 0.5)
                        .opacity(appeared ? 1 : 0)
                        .animation(.spring(response: 0.7, dampingFraction: 0.6).delay(0.1), value: appeared)

                        VStack(spacing: 8) {
                            HStack(spacing: 0) {
                                Text("Stage").font(.system(size: 34, weight: .black, design: .rounded)).foregroundColor(.white)
                                Text("Builder").font(.system(size: 34, weight: .black, design: .rounded)).foregroundColor(.sbPrimary)
                            }
                            Text("Construction site management")
                                .font(SBFont.body())
                                .foregroundColor(.white.opacity(0.45))
                        }
                        .offset(y: appeared ? 0 : 20)
                        .opacity(appeared ? 1 : 0)
                        .animation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.25), value: appeared)
                    }

                    Spacer().frame(height: 60)

                    // Feature chips
                    HStack(spacing: 10) {
                        FeatureChip(icon: "hammer.fill", text: "Tools")
                        FeatureChip(icon: "gearshape.fill", text: "Equipment")
                        FeatureChip(icon: "checkmark.square.fill", text: "Tasks")
                    }
                    .offset(y: appeared ? 0 : 20)
                    .opacity(appeared ? 1 : 0)
                    .animation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.4), value: appeared)

                    Spacer()

                    // Buttons
                    VStack(spacing: 12) {
                        NavigationLink(destination: SignUpView(), isActive: $showSignUp) { EmptyView() }
                        NavigationLink(destination: LoginView(), isActive: $showLogin) { EmptyView() }

                        SBPrimaryButton("Create Account", icon: "person.badge.plus") {
                            showSignUp = true
                        }

                        SBSecondaryButton(title: "Log In") {
                            showLogin = true
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 48)
                    .offset(y: appeared ? 0 : 40)
                    .opacity(appeared ? 1 : 0)
                    .animation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.5), value: appeared)
                }
            }
            .navigationBarHidden(true)
        }
        .navigationViewStyle(.stack)
        .onAppear { appeared = true }
    }
}

struct FeatureChip: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(.sbPrimary)
            Text(text)
                .font(SBFont.caption())
                .foregroundColor(.white.opacity(0.7))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 7)
        .background(Color.white.opacity(0.07))
        .clipShape(Capsule())
        .overlay(Capsule().stroke(Color.white.opacity(0.1), lineWidth: 1))
    }
}

// MARK: - Login View
struct LoginView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var vm: AuthViewModel
    @Environment(\.presentationMode) var presentationMode
    @State private var appeared = false

    init() {
        _vm = StateObject(wrappedValue: AuthViewModel(appState: AppState()))
    }

    var body: some View {
        ZStack {
            backgroundGradient

            ScrollView {
                VStack(spacing: 32) {
                    // Header
                    VStack(spacing: 8) {
                        Image(systemName: "lock.shield.fill")
                            .font(.system(size: 40, weight: .bold))
                            .foregroundColor(.sbPrimary)
                            .scaleEffect(appeared ? 1 : 0.6)
                            .animation(.spring(response: 0.6, dampingFraction: 0.6).delay(0.1), value: appeared)

                        Text("Welcome back")
                            .font(SBFont.title())
                            .foregroundColor(primaryText)

                        Text("Sign in to your account")
                            .font(SBFont.body())
                            .foregroundColor(.sbTextSecondary)
                    }
                    .padding(.top, 32)

                    // Form
                    VStack(spacing: 14) {
                        SBTextField(placeholder: "Email address", text: $vm.email, icon: "envelope.fill", keyboardType: .emailAddress)
                        SBTextField(placeholder: "Password", text: $vm.password, icon: "lock.fill", isSecure: true)
                    }
                    .padding(.horizontal, 24)

                    // Error
                    if vm.showError {
                        HStack(spacing: 8) {
                            Image(systemName: "exclamationmark.circle.fill")
                                .foregroundColor(.sbAccentRed)
                            Text(vm.errorMessage)
                                .font(SBFont.caption())
                                .foregroundColor(.sbAccentRed)
                        }
                        .padding(.horizontal, 24)
                        .transition(.move(edge: .top).combined(with: .opacity))
                    }

                    // Login button
                    SBPrimaryButton("Log In", icon: "arrow.right", isLoading: vm.isLoading) {
                        withAnimation { vm.showError = false }
                        vm.login()
                    }
                    .padding(.horizontal, 24)
                }
            }
        }
        .navigationTitle("Log In")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { appeared = true }
    }

    @Environment(\.colorScheme) var scheme
    var backgroundGradient: some View {
        (scheme == .dark ? Color.sbDarkBg : Color.sbBackground).ignoresSafeArea()
    }
    var primaryText: Color { scheme == .dark ? .white : .sbTextPrimary }
}

// Override to inject correct appState
struct LoginViewWrapper: View {
    @EnvironmentObject var appState: AppState
    @State private var email = ""
    @State private var password = ""
    @State private var isLoading = false
    @State private var errorMessage = ""
    @State private var showError = false
    @Environment(\.colorScheme) var scheme

    var body: some View {
        ZStack {
            (scheme == .dark ? Color.sbDarkBg : Color.sbBackground).ignoresSafeArea()

            ScrollView {
                VStack(spacing: 32) {
                    VStack(spacing: 8) {
                        Image(systemName: "lock.shield.fill")
                            .font(.system(size: 40, weight: .bold))
                            .foregroundColor(.sbPrimary)
                        Text("Welcome back")
                            .font(SBFont.title())
                        Text("Sign in to your account")
                            .font(SBFont.body())
                            .foregroundColor(.sbTextSecondary)
                    }
                    .padding(.top, 32)

                    VStack(spacing: 14) {
                        SBTextField(placeholder: "Email address", text: $email, icon: "envelope.fill", keyboardType: .emailAddress)
                        SBTextField(placeholder: "Password", text: $password, icon: "lock.fill", isSecure: true)
                    }
                    .padding(.horizontal, 24)

                    if showError {
                        HStack(spacing: 8) {
                            Image(systemName: "exclamationmark.circle.fill").foregroundColor(.sbAccentRed)
                            Text(errorMessage).font(SBFont.caption()).foregroundColor(.sbAccentRed)
                        }
                        .padding(.horizontal, 24)
                        .transition(.move(edge: .top).combined(with: .opacity))
                    }

                    SBPrimaryButton("Log In", icon: "arrow.right.circle.fill", isLoading: isLoading) {
                        loginAction()
                    }
                    .padding(.horizontal, 24)
                }
            }
        }
        .navigationTitle("Log In")
        .navigationBarTitleDisplayMode(.inline)
    }

    func loginAction() {
        guard !email.isEmpty && email.contains("@") && password.count >= 6 else {
            withAnimation { errorMessage = "Please enter valid email and password (min 6 chars)"; showError = true }
            return
        }
        isLoading = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            isLoading = false
            appState.userName = email.components(separatedBy: "@").first?.capitalized ?? "User"
            appState.userEmail = email
            appState.isLoggedIn = true
        }
    }
}

// MARK: - Sign Up View
struct SignUpView: View {
    @EnvironmentObject var appState: AppState
    @State private var name = ""
    @State private var email = ""
    @State private var password = ""
    @State private var isLoading = false
    @State private var errorMessage = ""
    @State private var showError = false
    @Environment(\.colorScheme) var scheme

    var body: some View {
        ZStack {
            (scheme == .dark ? Color.sbDarkBg : Color.sbBackground).ignoresSafeArea()

            ScrollView {
                VStack(spacing: 32) {
                    VStack(spacing: 8) {
                        Image(systemName: "person.badge.plus.fill")
                            .font(.system(size: 40, weight: .bold))
                            .foregroundColor(.sbPrimary)
                        Text("Create Account")
                            .font(SBFont.title())
                        Text("Start managing your construction site")
                            .font(SBFont.body())
                            .foregroundColor(.sbTextSecondary)
                    }
                    .padding(.top, 32)

                    VStack(spacing: 14) {
                        SBTextField(placeholder: "Full name", text: $name, icon: "person.fill")
                        SBTextField(placeholder: "Email address", text: $email, icon: "envelope.fill", keyboardType: .emailAddress)
                        SBTextField(placeholder: "Password (min 6 chars)", text: $password, icon: "lock.fill", isSecure: true)
                    }
                    .padding(.horizontal, 24)

                    if showError {
                        HStack(spacing: 8) {
                            Image(systemName: "exclamationmark.circle.fill").foregroundColor(.sbAccentRed)
                            Text(errorMessage).font(SBFont.caption()).foregroundColor(.sbAccentRed)
                        }
                        .padding(.horizontal, 24)
                        .transition(.move(edge: .top).combined(with: .opacity))
                    }

                    SBPrimaryButton("Create Account", icon: "checkmark.circle.fill", isLoading: isLoading) {
                        signUpAction()
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 40)
                }
            }
        }
        .navigationTitle("Sign Up")
        .navigationBarTitleDisplayMode(.inline)
    }

    func signUpAction() {
        guard !name.isEmpty, !email.isEmpty, email.contains("@"), password.count >= 6 else {
            withAnimation { errorMessage = "Please fill all fields correctly"; showError = true }
            return
        }
        isLoading = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            isLoading = false
            appState.userName = name
            appState.userEmail = email
            appState.isLoggedIn = true
        }
    }
}
