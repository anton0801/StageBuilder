import SwiftUI

struct MainTabView: View {
    @State private var selectedTab = 0
    @Environment(\.colorScheme) var scheme

    var body: some View {
        ZStack(alignment: .bottom) {
            TabView(selection: $selectedTab) {
                DashboardView()
                    .tag(0)
                SitesView()
                    .tag(1)
                ToolsView()
                    .tag(2)
                TasksView()
                    .tag(3)
                MoreView(selectedTab: $selectedTab)
                    .tag(4)
            }

            CustomTabBar(selectedTab: $selectedTab)
        }
        // .ignoresSafeArea(edges: .bottom)
    }
}

struct TabItem {
    let tag: Int
    let icon: String
    let activeIcon: String
    let label: String
}

struct CustomTabBar: View {
    @Binding var selectedTab: Int
    @Environment(\.colorScheme) var scheme

    let tabs: [TabItem] = [
        TabItem(tag: 0, icon: "square.grid.2x2", activeIcon: "square.grid.2x2.fill", label: "Dashboard"),
        TabItem(tag: 1, icon: "building.2", activeIcon: "building.2.fill", label: "Sites"),
        TabItem(tag: 2, icon: "hammer", activeIcon: "hammer.fill", label: "Tools"),
        TabItem(tag: 3, icon: "checkmark.square", activeIcon: "checkmark.square.fill", label: "Tasks"),
        TabItem(tag: 4, icon: "ellipsis.circle", activeIcon: "ellipsis.circle.fill", label: "More")
    ]

    var body: some View {
        HStack(spacing: 0) {
            ForEach(tabs, id: \.tag) { tab in
                Button(action: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        selectedTab = tab.tag
                    }
                }) {
                    VStack(spacing: 4) {
                        Image(systemName: selectedTab == tab.tag ? tab.activeIcon : tab.icon)
                            .font(.system(size: 20, weight: selectedTab == tab.tag ? .semibold : .regular))
                            .foregroundColor(selectedTab == tab.tag ? .sbPrimary : .sbTextTertiary)
                            .scaleEffect(selectedTab == tab.tag ? 1.1 : 1.0)
                            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: selectedTab)

                        Text(tab.label)
                            .font(.system(size: 10, weight: selectedTab == tab.tag ? .semibold : .regular, design: .rounded))
                            .foregroundColor(selectedTab == tab.tag ? .sbPrimary : .sbTextTertiary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 12)
                    .padding(.bottom, 8)
                }
            }
        }
        .background(
            Rectangle()
                .fill(scheme == .dark ? Color.sbDarkSurface : Color.sbSurface)
                .shadow(color: .black.opacity(0.1), radius: 16, y: -4)
                .ignoresSafeArea(edges: .bottom)
        )
    }
}

// MARK: - More Menu
struct MoreView: View {
    @Binding var selectedTab: Int
    @Environment(\.colorScheme) var scheme

    struct MoreItem: Identifiable {
        let id = UUID()
        let icon: String
        let label: String
        let color: Color
        let tag: Int
    }

    let items: [MoreItem] = [
        MoreItem(icon: "gearshape.2.fill", label: "Equipment", color: Color(hex: "#1A6AE8"), tag: 10),
        MoreItem(icon: "shippingbox.fill", label: "Materials", color: Color(hex: "#27AE60"), tag: 11),
        MoreItem(icon: "archivebox.fill", label: "Inventory", color: Color(hex: "#9B59B6"), tag: 12),
        MoreItem(icon: "person.2.fill", label: "Workers", color: Color(hex: "#E82B1A"), tag: 13),
        MoreItem(icon: "calendar", label: "Schedule", color: Color(hex: "#E8821A"), tag: 14),
        MoreItem(icon: "chart.bar.fill", label: "Reports", color: Color(hex: "#16A085"), tag: 15),
        MoreItem(icon: "bell.fill", label: "Notifications", color: Color(hex: "#F39C12"), tag: 16),
        MoreItem(icon: "person.circle.fill", label: "Profile", color: Color(hex: "#8E44AD"), tag: 17),
        MoreItem(icon: "gearshape.fill", label: "Settings", color: Color(hex: "#2C3E50"), tag: 18)
    ]

    var body: some View {
        NavigationView {
            ZStack {
                (scheme == .dark ? Color.sbDarkBg : Color.sbBackground).ignoresSafeArea()
                ScrollView {
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                        ForEach(items) { item in
                            MoreItemCell(item: item)
                        }
                    }
                    .padding(16)
                    .padding(.bottom, 80)
                }
            }
            .navigationTitle("More")
        }
        .navigationViewStyle(.stack)
    }
}

struct MoreItemCell: View {
    let item: MoreView.MoreItem
    @Environment(\.colorScheme) var scheme
    @State private var isPressed = false

    @ViewBuilder
    var destination: some View {
        switch item.tag {
        case 10: EquipmentView()
        case 11: MaterialsView()
        case 12: InventoryView()
        case 13: WorkersView()
        case 14: ScheduleView()
        case 15: ReportsView()
        case 16: NotificationsView()
        case 17: ProfileView()
        case 18: SettingsView()
        default: EmptyView()
        }
    }

    var body: some View {
        NavigationLink(destination: destination) {
            VStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(item.color.opacity(0.12))
                        .frame(width: 50, height: 50)
                    Image(systemName: item.icon)
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundColor(item.color)
                }
                Text(item.label)
                    .font(SBFont.caption(12))
                    .foregroundColor(scheme == .dark ? .white.opacity(0.85) : .sbTextPrimary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(scheme == .dark ? Color.sbDarkSurface : Color.sbSurface)
                    .shadow(color: .black.opacity(0.05), radius: 6, y: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}
