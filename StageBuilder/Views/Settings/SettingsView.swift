import SwiftUI
import UserNotifications

// MARK: - Notifications View
struct NotificationsView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var dataStore: DataStore
    @State private var pendingNotifications: [UNNotificationRequest] = []
    @State private var authStatus: UNAuthorizationStatus = .notDetermined
    @Environment(\.colorScheme) var scheme

    var body: some View {
        NavigationView {
            ZStack {
                (scheme == .dark ? Color.sbDarkBG : Color(.systemGroupedBackground))
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        // Status card
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                ZStack {
                                    Circle()
                                        .fill(authStatus == .authorized ? Color.sbGreen.opacity(0.15) : Color.orange.opacity(0.15))
                                        .frame(width: 44, height: 44)
                                    Image(systemName: authStatus == .authorized ? "bell.fill" : "bell.slash.fill")
                                        .foregroundColor(authStatus == .authorized ? .sbGreen : .orange)
                                        .font(.system(size: 20))
                                }

                                VStack(alignment: .leading, spacing: 3) {
                                    Text(authStatus == .authorized ? "Notifications Enabled" : "Notifications Disabled")
                                        .font(.system(size: 16, weight: .semibold))
                                    Text(authStatus == .authorized
                                         ? "You'll receive task and maintenance reminders"
                                         : "Enable in Settings to get reminders")
                                        .font(.system(size: 12))
                                        .foregroundColor(.secondary)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                            }

                            if authStatus != .authorized {
                                Button {
                                    if authStatus == .denied {
                                        if let url = URL(string: UIApplication.openSettingsURLString) {
                                            UIApplication.shared.open(url)
                                        }
                                    } else {
                                        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
                                            DispatchQueue.main.async {
                                                loadAuthStatus()
                                            }
                                        }
                                    }
                                } label: {
                                    Text(authStatus == .denied ? "Open Settings" : "Enable Notifications")
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundColor(.white)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 10)
                                        .background(Color.sbPrimary)
                                        .cornerRadius(10)
                                }
                            }
                        }
                        .padding(16)
                        .background(scheme == .dark ? Color.sbDarkSurface : .white)
                        .cornerRadius(14)
                        .padding(.horizontal, 16)

                        // Preferences
                        VStack(alignment: .leading, spacing: 0) {
                            Text("Preferences")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(.secondary)
                                .textCase(.uppercase)
                                .padding(.horizontal, 16)
                                .padding(.bottom, 8)

                            VStack(spacing: 0) {
                                NotifToggleRow(
                                    icon: "checkmark.circle.fill",
                                    color: .sbGreen,
                                    title: "Task Reminders",
                                    subtitle: "Get reminded before task deadlines",
                                    isOn: $appState.notificationsEnabled
                                )
                                Divider().padding(.leading, 60)
                                NotifToggleRow(
                                    icon: "wrench.and.screwdriver.fill",
                                    color: .sbPrimary,
                                    title: "Maintenance Alerts",
                                    subtitle: "Equipment service due notifications",
                                    isOn: $appState.notificationsEnabled
                                )
                                Divider().padding(.leading, 60)
                                NotifToggleRow(
                                    icon: "shippingbox.fill",
                                    color: .sbAccent,
                                    title: "Low Stock Alerts",
                                    subtitle: "When materials fall below minimum",
                                    isOn: $appState.notificationsEnabled
                                )
                            }
                            .background(scheme == .dark ? Color.sbDarkSurface : .white)
                            .cornerRadius(14)
                            .padding(.horizontal, 16)
                        }

                        // Scheduled notifications list
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Scheduled")
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundColor(.secondary)
                                    .textCase(.uppercase)

                                Spacer()

                                if !pendingNotifications.isEmpty {
                                    Button {
                                        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
                                        pendingNotifications = []
                                    } label: {
                                        Text("Clear All")
                                            .font(.system(size: 13, weight: .semibold))
                                            .foregroundColor(.sbRed)
                                    }
                                }
                            }
                            .padding(.horizontal, 16)

                            if pendingNotifications.isEmpty {
                                HStack {
                                    Spacer()
                                    VStack(spacing: 8) {
                                        Image(systemName: "bell.slash")
                                            .font(.system(size: 30))
                                            .foregroundColor(.secondary.opacity(0.5))
                                        Text("No scheduled notifications")
                                            .font(.system(size: 14))
                                            .foregroundColor(.secondary)
                                    }
                                    .padding(.vertical, 30)
                                    Spacer()
                                }
                                .background(scheme == .dark ? Color.sbDarkSurface : .white)
                                .cornerRadius(14)
                                .padding(.horizontal, 16)
                            } else {
                                VStack(spacing: 0) {
                                    ForEach(Array(pendingNotifications.enumerated()), id: \.offset) { idx, req in
                                        ScheduledNotifRow(request: req)
                                        if idx < pendingNotifications.count - 1 {
                                            Divider().padding(.leading, 54)
                                        }
                                    }
                                }
                                .background(scheme == .dark ? Color.sbDarkSurface : .white)
                                .cornerRadius(14)
                                .padding(.horizontal, 16)
                            }
                        }

                        Spacer().frame(height: 80)
                    }
                    .padding(.top, 16)
                }
            }
            .navigationTitle("Notifications")
            .navigationBarTitleDisplayMode(.large)
            .onAppear { loadAuthStatus(); loadPendingNotifications() }
        }
    }

    func loadAuthStatus() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                authStatus = settings.authorizationStatus
            }
        }
    }

    func loadPendingNotifications() {
        UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
            DispatchQueue.main.async {
                pendingNotifications = requests
            }
        }
    }
}

struct NotifToggleRow: View {
    let icon: String
    let color: Color
    let title: String
    let subtitle: String
    @Binding var isOn: Bool

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(color.opacity(0.15))
                    .frame(width: 36, height: 36)
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundColor(color)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 15, weight: .medium))
                Text(subtitle)
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }
            Spacer()
            Toggle("", isOn: $isOn)
                .labelsHidden()
                .tint(.sbPrimary)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
    }
}

struct ScheduledNotifRow: View {
    let request: UNNotificationRequest

    var triggerDate: Date? {
        if let calTrigger = request.trigger as? UNCalendarNotificationTrigger {
            return Calendar.current.date(from: calTrigger.dateComponents)
        }
        return nil
    }

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color.sbPrimary.opacity(0.15))
                    .frame(width: 38, height: 38)
                Image(systemName: "bell.fill")
                    .font(.system(size: 15))
                    .foregroundColor(.sbPrimary)
            }
            VStack(alignment: .leading, spacing: 3) {
                Text(request.content.title)
                    .font(.system(size: 14, weight: .medium))
                    .lineLimit(1)
                if let date = triggerDate {
                    Text(date.formatted(date: .abbreviated, time: .shortened))
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
            }
            Spacer()
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
    }
}

// MARK: - Profile View
struct ProfileView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var dataStore: DataStore
    @State private var isEditing = false
    @State private var editName = ""
    @State private var editEmail = ""
    @State private var showSaveConfirmation = false
    @Environment(\.colorScheme) var scheme

    var initials: String {
        let parts = appState.userName.split(separator: " ")
        let chars = parts.prefix(2).compactMap { $0.first?.uppercased() }
        return chars.joined()
    }

    var body: some View {
        NavigationView {
            ZStack {
                (scheme == .dark ? Color.sbDarkBG : Color(.systemGroupedBackground))
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        // Avatar
                        VStack(spacing: 16) {
                            ZStack {
                                Circle()
                                    .fill(LinearGradient(
                                        colors: [Color.sbPrimary, Color.sbPrimary.opacity(0.7)],
                                        startPoint: .topLeading, endPoint: .bottomTrailing))
                                    .frame(width: 90, height: 90)
                                Text(initials.isEmpty ? "?" : initials)
                                    .font(.system(size: 32, weight: .bold))
                                    .foregroundColor(.white)
                            }
                            .shadow(color: Color.sbPrimary.opacity(0.3), radius: 10, y: 4)

                            VStack(spacing: 4) {
                                Text(appState.userName.isEmpty ? "Your Name" : appState.userName)
                                    .font(.system(size: 20, weight: .bold))
                                Text(appState.userEmail.isEmpty ? "your@email.com" : appState.userEmail)
                                    .font(.system(size: 14))
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(.top, 24)

                        // Stats
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                            ProfileStat(value: "\(dataStore.sites.count)", label: "Sites")
                            ProfileStat(value: "\(dataStore.tools.count)", label: "Tools")
                            ProfileStat(value: "\(dataStore.tasks.filter { $0.status == .completed }.count)", label: "Done")
                        }
                        .padding(.horizontal, 16)

                        // Edit form
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Personal Info")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(.secondary)
                                .textCase(.uppercase)
                                .padding(.horizontal, 16)

                            if isEditing {
                                VStack(spacing: 12) {
                                    SBTextField(placeholder: "Full Name", text: $editName, icon: "person")
                                    SBTextField(placeholder: "Email", text: $editEmail, icon: "envelope")
                                }
                                .padding(.horizontal, 16)
                            } else {
                                VStack(spacing: 0) {
                                    InfoDisplayRow(label: "Name", value: appState.userName.isEmpty ? "Not set" : appState.userName, icon: "person.fill")
                                    Divider().padding(.leading, 56)
                                    InfoDisplayRow(label: "Email", value: appState.userEmail.isEmpty ? "Not set" : appState.userEmail, icon: "envelope.fill")
                                }
                                .background(scheme == .dark ? Color.sbDarkSurface : .white)
                                .cornerRadius(14)
                                .padding(.horizontal, 16)
                            }
                        }

                        if showSaveConfirmation {
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.sbGreen)
                                Text("Profile updated successfully")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.sbGreen)
                            }
                            .padding(.horizontal, 16)
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                        }

                        if isEditing {
                            HStack(spacing: 12) {
                                SBSecondaryButton(title: "Cancel") {
                                    withAnimation { isEditing = false }
                                }
                                SBPrimaryButton("Save Changes", icon: "checkmark") {
                                    let n = editName.trimmingCharacters(in: .whitespaces)
                                    let e = editEmail.trimmingCharacters(in: .whitespaces)
                                    if !n.isEmpty { appState.userName = n }
                                    if !e.isEmpty { appState.userEmail = e }
                                    withAnimation { isEditing = false; showSaveConfirmation = true }
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                                        withAnimation { showSaveConfirmation = false }
                                    }
                                }
                            }
                            .padding(.horizontal, 16)
                        } else {
                            SBSecondaryButton(title: "Edit Profile") {
                                editName = appState.userName
                                editEmail = appState.userEmail
                                withAnimation { isEditing = true }
                            }
                            .padding(.horizontal, 16)
                        }

                        Spacer().frame(height: 80)
                    }
                }
            }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

struct ProfileStat: View {
    let value: String
    let label: String
    @Environment(\.colorScheme) var scheme

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(.sbPrimary)
            Text(label)
                .font(.system(size: 12))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(scheme == .dark ? Color.sbDarkSurface : .white)
        .cornerRadius(12)
    }
}

struct InfoDisplayRow: View {
    let label: String
    let value: String
    let icon: String

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(.sbPrimary)
                .frame(width: 30)

            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
                Text(value)
                    .font(.system(size: 15, weight: .medium))
            }
            Spacer()
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 13)
    }
}

// MARK: - Settings View
struct SettingsView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var dataStore: DataStore
    @State private var showLogoutAlert = false
    @State private var showDeleteAlert = false
    @State private var showDeleteConfirmField = false
    @State private var deleteConfirmText = ""
    @Environment(\.colorScheme) var scheme

    var body: some View {
        NavigationView {
            ZStack {
                (scheme == .dark ? Color.sbDarkBG : Color(.systemGroupedBackground))
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        // Appearance
                        settingsSection(title: "Appearance") {
                            VStack(spacing: 0) {
                                HStack {
                                    Label {
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text("Theme")
                                                .font(.system(size: 15, weight: .medium))
                                            Text("Changes the entire app appearance")
                                                .font(.system(size: 12))
                                                .foregroundColor(.secondary)
                                        }
                                    } icon: {
                                        Image(systemName: "circle.lefthalf.filled")
                                            .foregroundColor(.sbPrimary)
                                            .frame(width: 28)
                                    }
                                    Spacer()
                                    Picker("", selection: $appState.appTheme) {
                                        Text("System").tag("system")
                                        Text("Light").tag("light")
                                        Text("Dark").tag("dark")
                                    }
                                    .pickerStyle(.menu)
                                    .accentColor(.sbPrimary)
                                    .onChange(of: appState.appTheme) { _ in
                                        appState.applyTheme()
                                    }
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 14)
                            }
                        }

                        // Units
                        settingsSection(title: "Measurement") {
                            VStack(spacing: 0) {
                                HStack {
                                    Label {
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text("Units")
                                                .font(.system(size: 15, weight: .medium))
                                            Text(appState.units == "metric" ? "Using metric system" : "Using imperial system")
                                                .font(.system(size: 12))
                                                .foregroundColor(.secondary)
                                        }
                                    } icon: {
                                        Image(systemName: "ruler")
                                            .foregroundColor(.sbAccent)
                                            .frame(width: 28)
                                    }
                                    Spacer()
                                    Picker("", selection: $appState.units) {
                                        Text("Metric").tag("metric")
                                        Text("Imperial").tag("imperial")
                                    }
                                    .pickerStyle(.segmented)
                                    .frame(width: 160)
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 14)
                            }
                        }

                        // Notifications
                        settingsSection(title: "Notifications") {
                            VStack(spacing: 0) {
                                HStack {
                                    Label {
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text("Push Notifications")
                                                .font(.system(size: 15, weight: .medium))
                                            Text("Task reminders and maintenance alerts")
                                                .font(.system(size: 12))
                                                .foregroundColor(.secondary)
                                        }
                                    } icon: {
                                        Image(systemName: "bell.fill")
                                            .foregroundColor(.sbGreen)
                                            .frame(width: 28)
                                    }
                                    Spacer()
                                    Toggle("", isOn: $appState.notificationsEnabled)
                                        .labelsHidden()
                                        .tint(.sbPrimary)
                                        .onChange(of: appState.notificationsEnabled) { enabled in
                                            if enabled {
                                                UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
                                                    if !granted {
                                                        DispatchQueue.main.async { appState.notificationsEnabled = false }
                                                    }
                                                }
                                            } else {
                                                UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
                                            }
                                        }
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 14)

                                Divider().padding(.leading, 60)

                                NavigationLink(destination: NotificationsView().environmentObject(appState).environmentObject(dataStore)) {
                                    HStack {
                                        Label {
                                            Text("Manage Notifications")
                                                .font(.system(size: 15, weight: .medium))
                                                .foregroundColor(.primary)
                                        } icon: {
                                            Image(systemName: "list.bullet.rectangle")
                                                .foregroundColor(.sbPrimary)
                                                .frame(width: 28)
                                        }
                                        Spacer()
                                        Image(systemName: "chevron.right")
                                            .font(.system(size: 13))
                                            .foregroundColor(.secondary)
                                    }
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 14)
                                }
                            }
                        }

                        // Data
                        settingsSection(title: "Data") {
                            VStack(spacing: 0) {
                                Button {
                                    withAnimation {
                                        dataStore.clearAllData()
                                    }
                                } label: {
                                    HStack {
                                        Label {
                                            VStack(alignment: .leading, spacing: 2) {
                                                Text("Clear App Data")
                                                    .font(.system(size: 15, weight: .medium))
                                                    .foregroundColor(.primary)
                                                Text("Remove all sites, tools, tasks, and materials")
                                                    .font(.system(size: 12))
                                                    .foregroundColor(.secondary)
                                            }
                                        } icon: {
                                            Image(systemName: "trash.fill")
                                                .foregroundColor(.orange)
                                                .frame(width: 28)
                                        }
                                        Spacer()
                                        Image(systemName: "chevron.right")
                                            .font(.system(size: 13))
                                            .foregroundColor(.secondary)
                                    }
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 14)
                                }
                            }
                        }

                        // Account
                        settingsSection(title: "Account") {
                            VStack(spacing: 0) {
                                Button {
                                    showLogoutAlert = true
                                } label: {
                                    HStack {
                                        Label {
                                            Text("Log Out")
                                                .font(.system(size: 15, weight: .semibold))
                                                .foregroundColor(.sbPrimary)
                                        } icon: {
                                            Image(systemName: "rectangle.portrait.and.arrow.right")
                                                .foregroundColor(.sbPrimary)
                                                .frame(width: 28)
                                        }
                                        Spacer()
                                    }
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 14)
                                }

                                Divider().padding(.leading, 60)

                                Button {
                                    showDeleteAlert = true
                                } label: {
                                    HStack {
                                        Label {
                                            VStack(alignment: .leading, spacing: 2) {
                                                Text("Delete Account")
                                                    .font(.system(size: 15, weight: .semibold))
                                                    .foregroundColor(.sbRed)
                                                Text("Permanently removes all your data")
                                                    .font(.system(size: 12))
                                                    .foregroundColor(.secondary)
                                            }
                                        } icon: {
                                            Image(systemName: "person.crop.circle.badge.minus")
                                                .foregroundColor(.sbRed)
                                                .frame(width: 28)
                                        }
                                        Spacer()
                                    }
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 14)
                                }
                            }
                        }

                        // Version info
                        Text("Stage Builder v1.0.0 · Built with ❤️")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                            .padding(.bottom, 80)
                    }
                    .padding(.top, 16)
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
            .alert("Log Out", isPresented: $showLogoutAlert) {
                Button("Log Out", role: .destructive) {
                    appState.logOut()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Are you sure you want to log out of Stage Builder?")
            }
            .alert("Delete Account", isPresented: $showDeleteAlert) {
                Button("Delete Permanently", role: .destructive) {
                    appState.deleteAccount()
                    dataStore.clearAllData()
                    UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This will permanently delete your account and all data. This action cannot be undone.")
            }
        }
    }

    func settingsSection<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.secondary)
                .textCase(.uppercase)
                .padding(.horizontal, 16)

            content()
                .background(scheme == .dark ? Color.sbDarkSurface : .white)
                .cornerRadius(14)
                .padding(.horizontal, 16)
        }
    }
}
