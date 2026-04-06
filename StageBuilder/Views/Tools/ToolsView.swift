import SwiftUI

// MARK: - Tools List
struct ToolsView: View {
    @EnvironmentObject var dataStore: DataStore
    @Environment(\.colorScheme) var scheme
    @State private var showAdd = false
    @State private var searchText = ""
    @State private var filterCategory: ToolCategory? = nil

    var filtered: [SBTool] {
        dataStore.tools.filter { tool in
            let matchSearch = searchText.isEmpty || tool.name.localizedCaseInsensitiveContains(searchText)
            let matchCat = filterCategory == nil || tool.category == filterCategory
            return matchSearch && matchCat
        }
    }

    var body: some View {
        NavigationView {
            ZStack {
                (scheme == .dark ? Color.sbDarkBg : Color.sbBackground).ignoresSafeArea()
                VStack(spacing: 0) {
                    // Category filter
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            CategoryChip(label: "All", isSelected: filterCategory == nil) {
                                withAnimation { filterCategory = nil }
                            }
                            ForEach(ToolCategory.allCases, id: \.self) { cat in
                                CategoryChip(label: cat.rawValue, isSelected: filterCategory == cat) {
                                    withAnimation { filterCategory = filterCategory == cat ? nil : cat }
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                    }

                    if filtered.isEmpty {
                        SBEmptyState(icon: "hammer", title: "No Tools Found", subtitle: "Add tools or adjust your search.")
                    } else {
                        ScrollView {
                            LazyVStack(spacing: 10) {
                                ForEach(filtered) { tool in
                                    NavigationLink(destination: ToolDetailView(tool: tool)) {
                                        ToolRow(tool: tool)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                    .contextMenu {
                                        Button(action: {
                                            var t = tool; t.isInUse.toggle(); dataStore.updateTool(t)
                                        }) {
                                            Label(tool.isInUse ? "Mark Available" : "Mark In Use",
                                                  systemImage: tool.isInUse ? "checkmark.circle" : "clock.fill")
                                        }
                                        Button(role: .destructive, action: { dataStore.deleteTool(tool) }) {
                                            Label("Delete Tool", systemImage: "trash")
                                        }
                                    }
                                }
                            }
                            .padding(16)
                            .padding(.bottom, 80)
                        }
                    }
                }
            }
            .navigationTitle("Tools")
            .searchable(text: $searchText, prompt: "Search tools")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showAdd = true }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 20))
                            .foregroundColor(.sbPrimary)
                    }
                }
            }
            .sheet(isPresented: $showAdd) { AddToolView() }
        }
        .navigationViewStyle(.stack)
    }
}

struct CategoryChip: View {
    let label: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(SBFont.caption(12))
                .foregroundColor(isSelected ? .white : .sbTextSecondary)
                .padding(.horizontal, 14)
                .padding(.vertical, 7)
                .background(isSelected ? Color.sbPrimary : Color.sbSurface2)
                .clipShape(Capsule())
        }
    }
}

struct ToolRow: View {
    let tool: SBTool
    @Environment(\.colorScheme) var scheme

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(tool.condition.color.opacity(0.12))
                    .frame(width: 48, height: 48)
                Image(systemName: tool.category.icon)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(tool.condition.color)
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(tool.name)
                        .font(SBFont.subheading())
                        .lineLimit(1)
                    if tool.isInUse {
                        SBBadge(text: "In Use", color: .sbPrimary)
                    }
                }
                HStack(spacing: 8) {
                    Text(tool.category.rawValue)
                        .font(SBFont.caption(11))
                        .foregroundColor(.sbTextSecondary)
                    Text("•").foregroundColor(.sbTextTertiary).font(.system(size: 10))
                    Label(tool.location, systemImage: "location.fill")
                        .font(SBFont.caption(11))
                        .foregroundColor(.sbTextSecondary)
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                SBStatusDot(status: tool.condition)
                Text(tool.condition.rawValue)
                    .font(.system(size: 10, design: .rounded))
                    .foregroundColor(.sbTextTertiary)
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(scheme == .dark ? Color.sbDarkSurface : .white)
                .shadow(color: .black.opacity(0.05), radius: 6, y: 2)
        )
    }
}

// MARK: - Tool Detail
struct ToolDetailView: View {
    @EnvironmentObject var dataStore: DataStore
    @Environment(\.colorScheme) var scheme
    @State var tool: SBTool
    @State private var showEdit = false
    @State private var showUsage = false
    @State private var showDeleteAlert = false
    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        ZStack {
            (scheme == .dark ? Color.sbDarkBg : Color.sbBackground).ignoresSafeArea()
            ScrollView {
                VStack(spacing: 16) {
                    // Header card
                    ZStack {
                        RoundedRectangle(cornerRadius: 20)
                            .fill(LinearGradient(colors: [tool.condition.color.opacity(0.8), tool.condition.color], startPoint: .topLeading, endPoint: .bottomTrailing))
                            .frame(height: 140)

                        HStack(spacing: 20) {
                            Image(systemName: tool.category.icon)
                                .font(.system(size: 42, weight: .bold))
                                .foregroundColor(.white.opacity(0.9))

                            VStack(alignment: .leading, spacing: 6) {
                                Text(tool.name)
                                    .font(SBFont.title(22))
                                    .foregroundColor(.white)
                                Text(tool.category.rawValue)
                                    .font(SBFont.body())
                                    .foregroundColor(.white.opacity(0.7))
                                SBBadge(text: tool.condition.rawValue, color: .white.opacity(0.25))
                            }
                            Spacer()
                        }
                        .padding(20)
                    }

                    // Info grid
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                        InfoTile(icon: "location.fill", label: "Location", value: tool.location, color: .sbAccent)
                        InfoTile(icon: "person.fill", label: "Assigned To", value: tool.assignedTo.isEmpty ? "Unassigned" : tool.assignedTo, color: Color(hex: "#9B59B6"))
                        InfoTile(icon: "clock.fill", label: "Status", value: tool.isInUse ? "In Use" : "Available", color: tool.isInUse ? .sbPrimary : .sbAccentGreen)
                        InfoTile(icon: "calendar", label: "Last Used", value: tool.lastUsed?.formatted(date: .abbreviated, time: .omitted) ?? "Never", color: .sbTextSecondary)
                    }

                    // Toggle in use
                    Button(action: {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            tool.isInUse.toggle()
                            tool.lastUsed = Date()
                            dataStore.updateTool(tool)
                        }
                    }) {
                        HStack {
                            Image(systemName: tool.isInUse ? "checkmark.circle.fill" : "clock.fill")
                            Text(tool.isInUse ? "Mark as Available" : "Mark as In Use")
                                .font(SBFont.subheading())
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(tool.isInUse ? Color.sbAccentGreen : Color.sbPrimary)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                    }

                    // Notes
                    if !tool.notes.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Notes").font(SBFont.heading(15))
                            Text(tool.notes).font(SBFont.body()).foregroundColor(.sbTextSecondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .modifier(SBCardModifier())
                    }

                    // Usage history
                    NavigationLink(destination: ToolUsageView(tool: tool)) {
                        HStack {
                            Label("Usage History", systemImage: "clock.arrow.circlepath")
                                .font(SBFont.subheading(15))
                            Spacer()
                            Image(systemName: "chevron.right").foregroundColor(.sbTextTertiary)
                        }
                        .padding(16)
                        .background(scheme == .dark ? Color.sbDarkSurface : .white)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        .shadow(color: .black.opacity(0.05), radius: 6, y: 2)
                    }
                    .buttonStyle(PlainButtonStyle())

                    // Actions
                    HStack(spacing: 12) {
                        Button(action: { showEdit = true }) {
                            Label("Edit", systemImage: "pencil")
                                .font(SBFont.subheading(14))
                                .foregroundColor(.sbPrimary)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(Color.sbPrimary.opacity(0.1))
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        Button(action: { showDeleteAlert = true }) {
                            Label("Delete", systemImage: "trash")
                                .font(SBFont.subheading(14))
                                .foregroundColor(.sbAccentRed)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(Color.sbAccentRed.opacity(0.1))
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                    }
                    .padding(.bottom, 80)
                }
                .padding(16)
            }
        }
        .navigationTitle(tool.name)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showEdit) { EditToolView(tool: $tool) }
        .alert("Delete Tool", isPresented: $showDeleteAlert) {
            Button("Delete", role: .destructive) {
                dataStore.deleteTool(tool)
                presentationMode.wrappedValue.dismiss()
            }
            Button("Cancel", role: .cancel) {}
        }
    }
}

struct InfoTile: View {
    let icon: String
    let label: String
    let value: String
    let color: Color
    @Environment(\.colorScheme) var scheme

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: icon).font(.system(size: 12)).foregroundColor(color)
                Text(label).font(SBFont.caption(11)).foregroundColor(.sbTextTertiary)
            }
            Text(value).font(SBFont.subheading(14)).lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(scheme == .dark ? Color.sbDarkSurface : .white)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.04), radius: 5, y: 2)
    }
}

// MARK: - Add Tool
struct AddToolView: View {
    @EnvironmentObject var dataStore: DataStore
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.colorScheme) var scheme
    @State private var name = ""
    @State private var category: ToolCategory = .hand
    @State private var condition: ToolCondition = .good
    @State private var location = ""
    @State private var assignedTo = ""
    @State private var notes = ""
    @State private var showError = false

    var body: some View {
        NavigationView {
            ZStack {
                (scheme == .dark ? Color.sbDarkBg : Color.sbBackground).ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 14) {
                        SBTextField(placeholder: "Tool name", text: $name, icon: "hammer.fill")

                        // Category picker
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Category").font(SBFont.caption()).foregroundColor(.sbTextSecondary).padding(.horizontal, 4)
                            Picker("Category", selection: $category) {
                                ForEach(ToolCategory.allCases, id: \.self) { Text($0.rawValue).tag($0) }
                            }
                            .pickerStyle(.wheel)
                            .frame(height: 100)
                            .clipped()
                            .background(scheme == .dark ? Color.sbDarkSurface2 : Color.sbSurface2)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }

                        // Condition
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Condition").font(SBFont.caption()).foregroundColor(.sbTextSecondary).padding(.horizontal, 4)
                            HStack(spacing: 8) {
                                ForEach(ToolCondition.allCases, id: \.self) { cond in
                                    Button(action: { condition = cond }) {
                                        VStack(spacing: 4) {
                                            Circle().fill(cond.color).frame(width: 10, height: 10)
                                            Text(cond.rawValue).font(.system(size: 9, design: .rounded))
                                        }
                                        .padding(8)
                                        .background(condition == cond ? cond.color.opacity(0.15) : Color.clear)
                                        .clipShape(RoundedRectangle(cornerRadius: 8))
                                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(condition == cond ? cond.color : Color.sbBorder, lineWidth: 1))
                                    }
                                    .foregroundColor(condition == cond ? cond.color : .sbTextSecondary)
                                }
                            }
                        }

                        SBTextField(placeholder: "Location (e.g. Tool Room A)", text: $location, icon: "location.fill")
                        SBTextField(placeholder: "Assigned to (optional)", text: $assignedTo, icon: "person.fill")

                        if showError {
                            Text("Please fill tool name and location.")
                                .font(SBFont.caption()).foregroundColor(.sbAccentRed)
                        }

                        SBPrimaryButton("Add Tool", icon: "plus.circle.fill") {
                            guard !name.isEmpty, !location.isEmpty else { showError = true; return }
                            let tool = SBTool(name: name, category: category, condition: condition, location: location, assignedTo: assignedTo, notes: notes)
                            dataStore.addTool(tool)
                            presentationMode.wrappedValue.dismiss()
                        }
                    }
                    .padding(16)
                }
            }
            .navigationTitle("Add Tool")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { presentationMode.wrappedValue.dismiss() }.foregroundColor(.sbPrimary)
                }
            }
        }
    }
}

// MARK: - Edit Tool
struct EditToolView: View {
    @EnvironmentObject var dataStore: DataStore
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.colorScheme) var scheme
    @Binding var tool: SBTool
    @State private var name = ""
    @State private var location = ""
    @State private var assignedTo = ""
    @State private var condition: ToolCondition = .good
    @State private var category: ToolCategory = .hand

    var body: some View {
        NavigationView {
            ZStack {
                (scheme == .dark ? Color.sbDarkBg : Color.sbBackground).ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 14) {
                        SBTextField(placeholder: "Tool name", text: $name, icon: "hammer.fill")
                        Picker("Category", selection: $category) {
                            ForEach(ToolCategory.allCases, id: \.self) { Text($0.rawValue).tag($0) }
                        }
                        .pickerStyle(.segmented)

                        VStack(alignment: .leading, spacing: 6) {
                            Text("Condition").font(SBFont.caption()).foregroundColor(.sbTextSecondary)
                            HStack(spacing: 8) {
                                ForEach(ToolCondition.allCases, id: \.self) { cond in
                                    Button(action: { condition = cond }) {
                                        VStack(spacing: 4) {
                                            Circle().fill(cond.color).frame(width: 10, height: 10)
                                            Text(cond.rawValue).font(.system(size: 9, design: .rounded))
                                        }
                                        .padding(8)
                                        .background(condition == cond ? cond.color.opacity(0.15) : Color.clear)
                                        .clipShape(RoundedRectangle(cornerRadius: 8))
                                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(condition == cond ? cond.color : Color.sbBorder, lineWidth: 1))
                                    }
                                    .foregroundColor(condition == cond ? cond.color : .sbTextSecondary)
                                }
                            }
                        }

                        SBTextField(placeholder: "Location", text: $location, icon: "location.fill")
                        SBTextField(placeholder: "Assigned to", text: $assignedTo, icon: "person.fill")

                        SBPrimaryButton("Save Changes", icon: "checkmark.circle.fill") {
                            tool.name = name; tool.location = location
                            tool.assignedTo = assignedTo; tool.condition = condition; tool.category = category
                            dataStore.updateTool(tool)
                            presentationMode.wrappedValue.dismiss()
                        }
                    }
                    .padding(16)
                }
            }
            .navigationTitle("Edit Tool")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { presentationMode.wrappedValue.dismiss() }.foregroundColor(.sbPrimary)
                }
            }
            .onAppear {
                name = tool.name; location = tool.location
                assignedTo = tool.assignedTo; condition = tool.condition; category = tool.category
            }
        }
    }
}

// MARK: - Tool Usage History
struct ToolUsageView: View {
    @EnvironmentObject var dataStore: DataStore
    @Environment(\.colorScheme) var scheme
    let tool: SBTool
    @State private var showAddUsage = false
    @State private var usedBy = ""
    @State private var notes = ""

    var usageRecords: [ToolUsageRecord] {
        dataStore.toolUsageRecords.filter { $0.toolId == tool.id }
    }

    var body: some View {
        ZStack {
            (scheme == .dark ? Color.sbDarkBg : Color.sbBackground).ignoresSafeArea()
            VStack {
                if usageRecords.isEmpty {
                    SBEmptyState(icon: "clock.arrow.circlepath", title: "No Usage Records", subtitle: "Log when this tool is checked out.")
                } else {
                    List {
                        ForEach(usageRecords) { record in
                            VStack(alignment: .leading, spacing: 6) {
                                Text(record.usedBy).font(SBFont.subheading(15))
                                HStack {
                                    Text(record.startDate.formatted(date: .abbreviated, time: .shortened))
                                    if let end = record.endDate {
                                        Text("→ \(end.formatted(date: .abbreviated, time: .shortened))")
                                    } else {
                                        Text("→ Ongoing").foregroundColor(.sbPrimary)
                                    }
                                }
                                .font(SBFont.caption(11))
                                .foregroundColor(.sbTextSecondary)
                                if !record.notes.isEmpty {
                                    Text(record.notes).font(SBFont.caption(11)).foregroundColor(.sbTextTertiary)
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    }
                    .listStyle(.insetGrouped)
                }
            }
        }
        .navigationTitle("Usage History")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { showAddUsage = true }) {
                    Image(systemName: "plus.circle.fill").foregroundColor(.sbPrimary)
                }
            }
        }
        .sheet(isPresented: $showAddUsage) {
            logUsageSheet
        }
    }

    var logUsageSheet: some View {
        NavigationView {
            VStack(spacing: 16) {
                SBTextField(placeholder: "Used by (name)", text: $usedBy, icon: "person.fill")
                SBTextField(placeholder: "Notes (optional)", text: $notes, icon: "note.text")
                SBPrimaryButton("Log Usage", icon: "plus.circle.fill") {
                    let record = ToolUsageRecord(toolId: tool.id, toolName: tool.name, usedBy: usedBy.isEmpty ? "Unknown" : usedBy, startDate: Date(), notes: notes)
                    dataStore.logToolUsage(record)
                    usedBy = ""; notes = ""
                    showAddUsage = false
                }
                Spacer()
            }
            .padding(16)
            .navigationTitle("Log Usage")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { showAddUsage = false }.foregroundColor(.sbPrimary)
                }
            }
        }
    }
}
