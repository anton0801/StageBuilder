import SwiftUI

struct DashboardView: View {
    @EnvironmentObject var appState: ApplicationMainState
    @EnvironmentObject var dataStore: DataStore
    @Environment(\.colorScheme) var scheme
    @State private var appeared = false

    var activeSite: SBSite? { dataStore.sites.first(where: { $0.isActive }) }

    var body: some View {
        NavigationView {
            ZStack {
                (scheme == .dark ? Color.sbDarkBg : Color.sbBackground).ignoresSafeArea()
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        heroCard
                        statsGrid
                        activeSiteCard
                        recentTasksCard
                        recentActivityCard
                        Spacer().frame(height: 80)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                }
            }
            .navigationTitle("Dashboard")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    NavigationLink(destination: NotificationsView()) {
                        ZStack(alignment: .topTrailing) {
                            Image(systemName: "bell.fill")
                                .font(.system(size: 17, weight: .semibold))
                                .foregroundColor(.sbPrimary)
                            Circle().fill(Color.sbAccentRed).frame(width: 8, height: 8).offset(x: 3, y: -3)
                        }
                    }
                }
            }
        }
        .navigationViewStyle(.stack)
        .onAppear { withAnimation(.easeOut(duration: 0.5).delay(0.1)) { appeared = true } }
    }

    // MARK: Hero Card
    var heroCard: some View {
        ZStack {
            LinearGradient(
                colors: [Color(hex: "#E8821A"), Color(hex: "#8B3A05")],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))

            // Pattern overlay
            GeometryReader { geo in
                Canvas { ctx, size in
                    for i in stride(from: 0, through: size.width, by: 30) {
                        for j in stride(from: 0, through: size.height, by: 30) {
                            let rect = CGRect(x: i, y: j, width: 2, height: 2)
                            ctx.fill(Path(ellipseIn: rect), with: .color(.white.opacity(0.06)))
                        }
                    }
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))

            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Good \(greeting), \(appState.userName)!")
                            .font(.system(size: 13, weight: .medium, design: .rounded))
                            .foregroundColor(.white.opacity(0.75))
                        Text("Here's your site overview")
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                    }
                    Spacer()
                    Image(systemName: "building.2.fill")
                        .font(.system(size: 36, weight: .light))
                        .foregroundColor(.white.opacity(0.25))
                }
                .padding(.top, 4)

                Divider().background(.white.opacity(0.2)).padding(.vertical, 4)

                HStack(spacing: 20) {
                    heroStat(value: "\(dataStore.sites.count)", label: "Sites")
                    heroStat(value: "\(dataStore.toolsInUseCount)", label: "Tools in Use")
                    heroStat(value: "\(dataStore.todayTasksCount)", label: "Today's Tasks")
                }
            }
            .padding(20)
        }
        .frame(height: 160)
        .offset(y: appeared ? 0 : 20)
        .opacity(appeared ? 1 : 0)
    }

    func heroStat(value: String, label: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(value)
                .font(.system(size: 24, weight: .black, design: .rounded))
                .foregroundColor(.white)
            Text(label)
                .font(.system(size: 11, weight: .medium, design: .rounded))
                .foregroundColor(.white.opacity(0.6))
        }
    }

    var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 0..<12: return "morning"
        case 12..<17: return "afternoon"
        default: return "evening"
        }
    }

    // MARK: Stats Grid
    var statsGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            StatCard(
                icon: "hammer.fill",
                iconColor: .sbPrimary,
                value: "\(dataStore.tools.count)",
                label: "Total Tools",
                sub: "\(dataStore.toolsInUseCount) in use"
            )
            StatCard(
                icon: "gearshape.2.fill",
                iconColor: .sbAccent,
                value: "\(dataStore.equipment.count)",
                label: "Equipment",
                sub: "\(dataStore.activeEquipmentCount) active"
            )
            StatCard(
                icon: "shippingbox.fill",
                iconColor: .sbAccentGreen,
                value: "\(dataStore.materials.count)",
                label: "Materials",
                sub: dataStore.lowStockMaterialsCount > 0 ? "\(dataStore.lowStockMaterialsCount) low stock" : "All stocked"
            )
            StatCard(
                icon: "person.2.fill",
                iconColor: Color(hex: "#9B59B6"),
                value: "\(dataStore.workers.filter { $0.isActive }.count)",
                label: "Workers",
                sub: "Active workers"
            )
        }
        .offset(y: appeared ? 0 : 20)
        .opacity(appeared ? 1 : 0)
        .animation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.15), value: appeared)
    }

    // MARK: Active Site Card
    var activeSiteCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Label("Active Site", systemImage: "location.fill")
                    .font(SBFont.heading(16))
                Spacer()
                NavigationLink(destination: SitesView()) {
                    Text("View all")
                        .font(SBFont.caption())
                        .foregroundColor(.sbPrimary)
                }
            }

            if let site = activeSite {
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        VStack(alignment: .leading, spacing: 3) {
                            Text(site.name)
                                .font(SBFont.heading())
                            Text(site.address)
                                .font(SBFont.caption())
                                .foregroundColor(.sbTextSecondary)
                        }
                        Spacer()
                        SBBadge(text: "Active", color: .sbAccentGreen)
                    }

                    // Progress bar
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text("Progress")
                                .font(SBFont.caption())
                                .foregroundColor(.sbTextSecondary)
                            Spacer()
                            Text("\(Int(site.progress * 100))%")
                                .font(SBFont.caption())
                                .foregroundColor(.sbPrimary)
                        }
                        GeometryReader { g in
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 4).fill(Color.sbBorder).frame(height: 6)
                                RoundedRectangle(cornerRadius: 4).fill(LinearGradient.sbPrimaryGradient)
                                    .frame(width: g.size.width * site.progress, height: 6)
                            }
                        }
                        .frame(height: 6)
                    }

                    HStack(spacing: 16) {
                        Label("\(site.workerCount) workers", systemImage: "person.2.fill")
                            .font(SBFont.caption())
                            .foregroundColor(.sbTextSecondary)
                    }
                }
            } else {
                Text("No active site. Create one in Sites.")
                    .font(SBFont.body())
                    .foregroundColor(.sbTextSecondary)
            }
        }
        .modifier(SBCardModifier())
        .offset(y: appeared ? 0 : 20)
        .opacity(appeared ? 1 : 0)
        .animation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.2), value: appeared)
    }

    // MARK: Recent Tasks
    var recentTasksCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Label("Tasks Today", systemImage: "checkmark.square.fill")
                    .font(SBFont.heading(16))
                Spacer()
                NavigationLink(destination: TasksView()) {
                    Text("See all")
                        .font(SBFont.caption())
                        .foregroundColor(.sbPrimary)
                }
            }

            let todayTasks = dataStore.tasks.filter {
                $0.status != .completed
            }.prefix(3)

            if todayTasks.isEmpty {
                Text("No pending tasks. Great work!")
                    .font(SBFont.body())
                    .foregroundColor(.sbTextSecondary)
            } else {
                ForEach(Array(todayTasks)) { task in
                    DashTaskRow(task: task)
                }
            }
        }
        .modifier(SBCardModifier())
        .offset(y: appeared ? 0 : 20)
        .opacity(appeared ? 1 : 0)
        .animation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.25), value: appeared)
    }

    // MARK: Recent Activity
    var recentActivityCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Label("Recent Activity", systemImage: "clock.fill")
                    .font(SBFont.heading(16))
                Spacer()
                NavigationLink(destination: ActivityHistoryView()) {
                    Text("All")
                        .font(SBFont.caption())
                        .foregroundColor(.sbPrimary)
                }
            }

            if dataStore.activityLogs.isEmpty {
                Text("No activity yet. Start adding items.")
                    .font(SBFont.body())
                    .foregroundColor(.sbTextSecondary)
            } else {
                ForEach(dataStore.activityLogs.prefix(4)) { log in
                    HStack(spacing: 12) {
                        Image(systemName: log.icon)
                            .font(.system(size: 14))
                            .foregroundColor(.sbPrimary)
                            .frame(width: 32, height: 32)
                            .background(Color.sbPrimary.opacity(0.1))
                            .clipShape(Circle())
                        VStack(alignment: .leading, spacing: 2) {
                            Text(log.action)
                                .font(SBFont.caption())
                                .foregroundColor(.sbTextPrimary)
                            Text(log.entityName)
                                .font(.system(size: 11, design: .rounded))
                                .foregroundColor(.sbTextSecondary)
                        }
                        Spacer()
                        Text(log.date.timeAgo)
                            .font(.system(size: 10, design: .rounded))
                            .foregroundColor(.sbTextTertiary)
                    }
                }
            }
        }
        .modifier(SBCardModifier())
    }
}

// MARK: - Stat Card
struct StatCard: View {
    let icon: String
    let iconColor: Color
    let value: String
    let label: String
    let sub: String
    @Environment(\.colorScheme) var scheme

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(iconColor.opacity(0.12))
                    .frame(width: 38, height: 38)
                Image(systemName: icon)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(iconColor)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(.system(size: 26, weight: .black, design: .rounded))
                Text(label)
                    .font(SBFont.caption(12))
                    .foregroundColor(.sbTextSecondary)
                Text(sub)
                    .font(.system(size: 10, design: .rounded))
                    .foregroundColor(.sbTextTertiary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(scheme == .dark ? Color.sbDarkSurface : .white)
                .shadow(color: .black.opacity(0.05), radius: 8, y: 3)
        )
    }
}

struct DashTaskRow: View {
    let task: SBTask

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: task.status.icon)
                .font(.system(size: 15))
                .foregroundColor(task.status.color)
                .frame(width: 24)
            VStack(alignment: .leading, spacing: 2) {
                Text(task.title)
                    .font(SBFont.caption())
                    .lineLimit(1)
                Text(task.deadline.formatted(date: .abbreviated, time: .omitted))
                    .font(.system(size: 10, design: .rounded))
                    .foregroundColor(.sbTextTertiary)
            }
            Spacer()
            SBBadge(text: task.priority.rawValue, color: task.priority.color)
        }
    }
}

struct SBCardModifier: ViewModifier {
    @Environment(\.colorScheme) var scheme
    func body(content: Content) -> some View {
        content
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(scheme == .dark ? Color.sbDarkSurface : Color.sbSurface)
                    .shadow(color: .black.opacity(scheme == .dark ? 0.3 : 0.06), radius: 10, y: 4)
            )
    }
}

extension Date {
    var timeAgo: String {
        let seconds = -timeIntervalSinceNow
        if seconds < 60 { return "now" }
        if seconds < 3600 { return "\(Int(seconds/60))m ago" }
        if seconds < 86400 { return "\(Int(seconds/3600))h ago" }
        return "\(Int(seconds/86400))d ago"
    }
}
