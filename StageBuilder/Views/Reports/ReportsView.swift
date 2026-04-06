import SwiftUI

// MARK: - Reports View
struct ReportsView: View {
    @EnvironmentObject var dataStore: DataStore
    @State private var selectedSection: ReportSection = .overview
    @Environment(\.colorScheme) var scheme

    enum ReportSection: String, CaseIterable {
        case overview = "Overview"
        case tools = "Tools"
        case materials = "Materials"
        case tasks = "Tasks"
    }

    var body: some View {
        NavigationView {
            ZStack {
                (scheme == .dark ? Color.sbDarkBG : Color(.systemGroupedBackground))
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        // Section picker
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 10) {
                                ForEach(ReportSection.allCases, id: \.self) { section in
                                    Button {
                                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                            selectedSection = section
                                        }
                                    } label: {
                                        Text(section.rawValue)
                                            .font(.system(size: 14, weight: .semibold))
                                            .padding(.horizontal, 16)
                                            .padding(.vertical, 8)
                                            .background(selectedSection == section ? Color.sbPrimary : (scheme == .dark ? Color.sbDarkSurface : .white))
                                            .foregroundColor(selectedSection == section ? .white : .primary)
                                            .cornerRadius(20)
                                    }
                                }
                            }
                            .padding(.horizontal, 16)
                        }
                        .padding(.top, 4)

                        switch selectedSection {
                        case .overview: overviewSection
                        case .tools: toolsSection
                        case .materials: materialsSection
                        case .tasks: tasksSection
                        }

                        // Activity History link
                        NavigationLink(destination: ActivityHistoryView().environmentObject(dataStore)) {
                            HStack {
                                Image(systemName: "clock.arrow.circlepath")
                                    .foregroundColor(.sbPrimary)
                                Text("Full Activity History")
                                    .font(.system(size: 15, weight: .medium))
                                    .foregroundColor(.primary)
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 13))
                                    .foregroundColor(.secondary)
                            }
                            .padding(16)
                            .background(scheme == .dark ? Color.sbDarkSurface : .white)
                            .cornerRadius(12)
                            .padding(.horizontal, 16)
                        }

                        Spacer().frame(height: 80)
                    }
                    .padding(.top, 8)
                }
            }
            .navigationTitle("Reports")
            .navigationBarTitleDisplayMode(.large)
        }
    }

    // MARK: Overview
    var overviewSection: some View {
        VStack(spacing: 16) {
            // Summary cards
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ReportStatCard(title: "Total Tools", value: "\(dataStore.tools.count)", icon: "wrench.fill", color: .sbPrimary)
                ReportStatCard(title: "In Use", value: "\(dataStore.tools.filter { $0.isInUse }.count)", icon: "hammer.fill", color: .sbAccent)
                ReportStatCard(title: "Equipment", value: "\(dataStore.equipment.count)", icon: "gearshift.layout.sixspeed", color: Color.orange)
                ReportStatCard(title: "Active Tasks", value: "\(dataStore.tasks.filter { $0.status != .completed }.count)", icon: "checkmark.circle.fill", color: .sbGreen)
            }
            .padding(.horizontal, 16)

            // Sites summary
            sectionCard(title: "Sites Overview") {
                if dataStore.sites.isEmpty {
                    emptyRow(text: "No sites added yet")
                } else {
                    ForEach(dataStore.sites) { site in
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(site.name)
                                    .font(.system(size: 14, weight: .semibold))
                                Text(site.address)
                                    .font(.system(size: 12))
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            VStack(alignment: .trailing, spacing: 2) {
                                Text("\(Int(site.progress * 100))%")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(.sbPrimary)
                                Text("complete")
                                    .font(.system(size: 11))
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
            }

            // Workers summary
            sectionCard(title: "Workers") {
                let roles = Dictionary(grouping: dataStore.workers, by: { $0.role.rawValue })
                if roles.isEmpty {
                    emptyRow(text: "No workers added yet")
                } else {
                    ForEach(Array(roles.keys.sorted()), id: \.self) { role in
                        HStack {
                            Text(role)
                                .font(.system(size: 14))
                            Spacer()
                            Text("\(roles[role]?.count ?? 0)")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.sbPrimary)
                        }
                        .padding(.vertical, 2)
                    }
                }
            }
        }
    }

    // MARK: Tools
    var toolsSection: some View {
        VStack(spacing: 16) {
            // Condition distribution
            sectionCard(title: "Tool Condition") {
                let conditions = Dictionary(grouping: dataStore.tools, by: { $0.condition.rawValue })
                if conditions.isEmpty {
                    emptyRow(text: "No tools added yet")
                } else {
                    ForEach(ToolCondition.allCases, id: \.self) { condition in
                        let count = conditions[condition.rawValue]?.count ?? 0
                        let total = dataStore.tools.count
                        let ratio = total > 0 ? Double(count) / Double(total) : 0

                        HStack {
                            HStack(spacing: 8) {
                                Circle()
                                    .fill(conditionColor(condition))
                                    .frame(width: 8, height: 8)
                                Text(condition.rawValue)
                                    .font(.system(size: 14))
                            }
                            Spacer()
                            GeometryReader { geo in
                                ZStack(alignment: .leading) {
                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(Color(.systemGray5))
                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(conditionColor(condition))
                                        .frame(width: geo.size.width * ratio)
                                }
                            }
                            .frame(width: 80, height: 8)
                            Text("\(count)")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(conditionColor(condition))
                                .frame(width: 24, alignment: .trailing)
                        }
                        .padding(.vertical, 3)
                    }
                }
            }

            // Category breakdown
            sectionCard(title: "By Category") {
                let cats = Dictionary(grouping: dataStore.tools, by: { $0.category.rawValue })
                if cats.isEmpty {
                    emptyRow(text: "No tools added yet")
                } else {
                    ForEach(Array(cats.keys.sorted()), id: \.self) { cat in
                        HStack {
                            Text(cat)
                                .font(.system(size: 14))
                            Spacer()
                            Text("\(cats[cat]?.count ?? 0) tools")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(.sbPrimary)
                        }
                        .padding(.vertical, 3)
                    }
                }
            }

            // Usage records
            sectionCard(title: "Recent Tool Usage") {
                let recent = dataStore.toolUsageRecords.sorted { $0.startDate > $1.startDate }.prefix(5)
                if recent.isEmpty {
                    emptyRow(text: "No usage recorded yet")
                } else {
                    ForEach(Array(recent)) { record in
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                if let tool = dataStore.tools.first(where: { $0.id == record.toolId }) {
                                    Text(tool.name)
                                        .font(.system(size: 14, weight: .semibold))
                                }
                                Text(record.usedBy)
                                    .font(.system(size: 12))
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            Text(record.startDate.timeAgo)
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 3)
                    }
                }
            }
        }
    }

    // MARK: Materials
    var materialsSection: some View {
        VStack(spacing: 16) {
            // Stock overview
            sectionCard(title: "Stock Levels") {
                if dataStore.materials.isEmpty {
                    emptyRow(text: "No materials added yet")
                } else {
                    ForEach(dataStore.materials.sorted { $0.quantity / max($0.minQuantity, 1) < $1.quantity / max($1.minQuantity, 1) }) { mat in
                        let ratio = mat.minQuantity > 0 ? min(Double(mat.quantity) / Double(mat.minQuantity), 2.0) : 1.0
                        let isLow = mat.quantity <= mat.minQuantity

                        HStack(spacing: 10) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(mat.name)
                                    .font(.system(size: 14, weight: .semibold))
                                Text("\(mat.quantity) \(mat.unit)")
                                    .font(.system(size: 12))
                                    .foregroundColor(isLow ? .sbRed : .secondary)
                            }
                            Spacer()
                            if isLow {
                                SBBadge(text: "Low", color: .sbRed)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
            }

            // Inventory movements
            sectionCard(title: "Recent Movements") {
                let movements = dataStore.inventoryMovements.sorted { $0.date > $1.date }.prefix(6)
                if movements.isEmpty {
                    emptyRow(text: "No movements recorded yet")
                } else {
                    ForEach(Array(movements)) { mov in
                        HStack {
                            let isIn = mov.quantityIn > 0
                            Image(systemName: isIn ? "arrow.down.circle.fill" : "arrow.up.circle.fill")
                                .foregroundColor(isIn ? .sbGreen : .sbRed)
                                .font(.system(size: 16))

                            if let mat = dataStore.materials.first(where: { $0.id == mov.materialId }) {
                                Text(mat.name)
                                    .font(.system(size: 14))
                            }
                            Spacer()
                            let qty = mov.quantityIn > 0 ? mov.quantityIn : mov.quantityOut
                            Text((mov.quantityIn > 0 ? "+" : "-") + String(format: "%.0f", qty))
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(mov.quantityIn > 0 ? .sbGreen : .sbRed)
                        }
                        .padding(.vertical, 3)
                    }
                }
            }
        }
    }

    // MARK: Tasks
    var tasksSection: some View {
        VStack(spacing: 16) {
            // Status breakdown
            sectionCard(title: "Task Status") {
                let statuses = Dictionary(grouping: dataStore.tasks, by: { $0.status })
                if statuses.isEmpty {
                    emptyRow(text: "No tasks added yet")
                } else {
                    ForEach(TaskStatus.allCases, id: \.self) { status in
                        let count = statuses[status]?.count ?? 0
                        let total = dataStore.tasks.count
                        let ratio = total > 0 ? Double(count) / Double(total) : 0

                        HStack {
                            HStack(spacing: 8) {
                                Circle()
                                    .fill(taskStatusColor(status))
                                    .frame(width: 8, height: 8)
                                Text(status.rawValue)
                                    .font(.system(size: 14))
                            }
                            Spacer()
                            GeometryReader { geo in
                                ZStack(alignment: .leading) {
                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(Color(.systemGray5))
                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(taskStatusColor(status))
                                        .frame(width: geo.size.width * ratio)
                                }
                            }
                            .frame(width: 80, height: 8)
                            Text("\(count)")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(taskStatusColor(status))
                                .frame(width: 24, alignment: .trailing)
                        }
                        .padding(.vertical, 3)
                    }
                }
            }

            // Priority breakdown
            sectionCard(title: "By Priority") {
                let priorities = Dictionary(grouping: dataStore.tasks, by: { $0.priority })
                if priorities.isEmpty {
                    emptyRow(text: "No tasks added yet")
                } else {
                    ForEach(TaskPriority.allCases, id: \.self) { priority in
                        HStack {
                            Text(priority.rawValue)
                                .font(.system(size: 14))
                            Spacer()
                            Text("\(priorities[priority]?.count ?? 0) tasks")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(taskPriorityColor(priority))
                        }
                        .padding(.vertical, 3)
                    }
                }
            }

            // Overdue tasks
            let overdue = dataStore.tasks.filter { $0.deadline < Date() && $0.status != .completed }
            if !overdue.isEmpty {
                sectionCard(title: "⚠️ Overdue Tasks") {
                    ForEach(overdue) { task in
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(task.title)
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(.sbRed)
                                Text("Due: \(task.deadline.formatted(date: .abbreviated, time: .omitted))")
                                    .font(.system(size: 12))
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            SBBadge(text: task.priority.rawValue, color: taskPriorityColor(task.priority))
                        }
                        .padding(.vertical, 3)
                    }
                }
            }
        }
    }

    // MARK: Helpers
    func sectionCard<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.secondary)
                .textCase(.uppercase)
                .padding(.horizontal, 16)

            VStack(alignment: .leading, spacing: 4) {
                content()
            }
            .padding(16)
            .background(scheme == .dark ? Color.sbDarkSurface : .white)
            .cornerRadius(14)
            .padding(.horizontal, 16)
        }
    }

    func emptyRow(text: String) -> some View {
        Text(text)
            .font(.system(size: 14))
            .foregroundColor(.secondary)
            .padding(.vertical, 4)
    }

    func conditionColor(_ c: ToolCondition) -> Color {
        switch c {
        case .excellent: return .sbGreen
        case .good: return Color(hex: "#52C41A")
        case .fair: return Color.orange
        case .needsRepair: return .sbPrimary
        case .outOfService: return .sbRed
        }
    }

    func taskStatusColor(_ s: TaskStatus) -> Color {
        switch s {
        case .pending: return .secondary
        case .inProgress: return .sbPrimary
        case .completed: return .sbGreen
        case .blocked: return .sbRed
        }
    }

    func taskPriorityColor(_ p: TaskPriority) -> Color {
        switch p {
        case .low: return .sbGreen
        case .medium: return .sbPrimary
        case .high: return Color.orange
        case .critical: return .sbRed
        }
    }
}

// MARK: - Report Stat Card
struct ReportStatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    @Environment(\.colorScheme) var scheme

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(color.opacity(0.15))
                        .frame(width: 34, height: 34)
                    Image(systemName: icon)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(color)
                }
                Spacer()
            }
            Text(value)
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(color)
            Text(title)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.secondary)
        }
        .padding(14)
        .background(scheme == .dark ? Color.sbDarkSurface : .white)
        .cornerRadius(14)
    }
}

// MARK: - Activity History View
struct ActivityHistoryView: View {
    @EnvironmentObject var dataStore: DataStore
    @State private var searchText = ""
    @Environment(\.colorScheme) var scheme

    var filtered: [ActivityLog] {
        if searchText.isEmpty { return dataStore.activityLogs }
        return dataStore.activityLogs.filter {
            $0.action.localizedCaseInsensitiveContains(searchText) ||
            $0.entityType.localizedCaseInsensitiveContains(searchText) ||
            $0.entityName.localizedCaseInsensitiveContains(searchText)
        }
    }

    var groupedLogs: [String: [ActivityLog]] {
        Dictionary(grouping: filtered) { log in
            if Calendar.current.isDateInToday(log.date) { return "Today" }
            if Calendar.current.isDateInYesterday(log.date) { return "Yesterday" }
            return log.date.formatted(.dateTime.month(.wide).day().year())
        }
    }

    var sortedKeys: [String] {
        groupedLogs.keys.sorted { a, b in
            let order = ["Today", "Yesterday"]
            if let ai = order.firstIndex(of: a), let bi = order.firstIndex(of: b) { return ai < bi }
            if order.contains(a) { return true }
            if order.contains(b) { return false }
            return a > b
        }
    }

    var body: some View {
        ZStack {
            (scheme == .dark ? Color.sbDarkBG : Color(.systemGroupedBackground))
                .ignoresSafeArea()

            if filtered.isEmpty {
                SBEmptyState(icon: "clock.arrow.circlepath", title: "No Activity", subtitle: "Actions you take in the app will be logged here.")
            } else {
                ScrollView {
                    LazyVStack(spacing: 0, pinnedViews: .sectionHeaders) {
                        // Search
                        HStack {
                            Image(systemName: "magnifyingglass").foregroundColor(.secondary)
                            TextField("Search activity...", text: $searchText)
                        }
                        .padding(10)
                        .background(scheme == .dark ? Color.sbDarkSurface : .white)
                        .cornerRadius(10)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)

                        ForEach(sortedKeys, id: \.self) { key in
                            Section {
                                ForEach(groupedLogs[key]?.sorted { $0.date > $1.date } ?? []) { log in
                                    ActivityLogRow(log: log)
                                        .padding(.horizontal, 16)
                                        .padding(.bottom, 8)
                                }
                            } header: {
                                HStack {
                                    Text(key)
                                        .font(.system(size: 13, weight: .semibold))
                                        .foregroundColor(.secondary)
                                        .textCase(.uppercase)
                                    Spacer()
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(scheme == .dark ? Color.sbDarkBG : Color(.systemGroupedBackground))
                            }
                        }

                        Spacer().frame(height: 40)
                    }
                }
            }
        }
        .navigationTitle("Activity History")
        .navigationBarTitleDisplayMode(.large)
    }
}

struct ActivityLogRow: View {
    let log: ActivityLog
    @Environment(\.colorScheme) var scheme

    var entityColor: Color {
        switch log.entityType.lowercased() {
        case "tool": return .sbPrimary
        case "equipment": return Color.orange
        case "material": return .sbAccent
        case "task": return .sbGreen
        case "site": return Color.purple
        case "worker": return Color.pink
        default: return .secondary
        }
    }

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(entityColor.opacity(0.15))
                    .frame(width: 38, height: 38)
                Image(systemName: log.icon)
                    .font(.system(size: 16))
                    .foregroundColor(entityColor)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text("\(log.action) \(log.entityName)")
                    .font(.system(size: 14, weight: .medium))
                    .lineLimit(2)
                HStack(spacing: 4) {
                    SBBadge(text: log.entityType, color: entityColor)
                    Text(log.date.formatted(.dateTime.hour().minute()))
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(12)
        .background(scheme == .dark ? Color.sbDarkSurface : .white)
        .cornerRadius(12)
    }
}
