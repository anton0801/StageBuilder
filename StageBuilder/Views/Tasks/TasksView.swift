import SwiftUI

struct TasksView: View {
    @EnvironmentObject var dataStore: DataStore
    @Environment(\.colorScheme) var scheme
    @State private var showAdd = false
    @State private var filterStatus: TaskStatus? = nil
    @State private var searchText = ""

    var filtered: [SBTask] {
        dataStore.tasks.filter { t in
            let matchSearch = searchText.isEmpty || t.title.localizedCaseInsensitiveContains(searchText)
            let matchStatus = filterStatus == nil || t.status == filterStatus
            return matchSearch && matchStatus
        }
        .sorted { $0.deadline < $1.deadline }
    }

    var body: some View {
        NavigationView {
            ZStack {
                (scheme == .dark ? Color.sbDarkBg : Color.sbBackground).ignoresSafeArea()
                VStack(spacing: 0) {
                    // Status filter
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            CategoryChip(label: "All", isSelected: filterStatus == nil) {
                                withAnimation { filterStatus = nil }
                            }
                            ForEach(TaskStatus.allCases, id: \.self) { status in
                                Button(action: {
                                    withAnimation { filterStatus = filterStatus == status ? nil : status }
                                }) {
                                    HStack(spacing: 5) {
                                        Image(systemName: status.icon).font(.system(size: 10))
                                        Text(status.rawValue).font(SBFont.caption(12))
                                    }
                                    .foregroundColor(filterStatus == status ? .white : .sbTextSecondary)
                                    .padding(.horizontal, 12).padding(.vertical, 7)
                                    .background(filterStatus == status ? status.color : Color.sbSurface2)
                                    .clipShape(Capsule())
                                }
                            }
                        }
                        .padding(.horizontal, 16).padding(.vertical, 10)
                    }

                    if filtered.isEmpty {
                        SBEmptyState(icon: "checkmark.square", title: "No Tasks", subtitle: "All clear! Add tasks to track work progress.")
                    } else {
                        ScrollView {
                            LazyVStack(spacing: 10) {
                                ForEach(filtered) { task in
                                    NavigationLink(destination: TaskDetailView(task: task)) {
                                        TaskCard(task: task)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                    .contextMenu {
                                        ForEach(TaskStatus.allCases, id: \.self) { status in
                                            Button(action: {
                                                var t = task; t.status = status
                                                if status == .completed { t.completedAt = Date() }
                                                dataStore.updateTask(t)
                                            }) {
                                                Label("Mark \(status.rawValue)", systemImage: status.icon)
                                            }
                                        }
                                        Divider()
                                        Button(role: .destructive, action: { dataStore.deleteTask(task) }) {
                                            Label("Delete Task", systemImage: "trash")
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
            .navigationTitle("Tasks")
            .searchable(text: $searchText, prompt: "Search tasks")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showAdd = true }) {
                        Image(systemName: "plus.circle.fill").font(.system(size: 20)).foregroundColor(.sbPrimary)
                    }
                }
            }
            .sheet(isPresented: $showAdd) { AddTaskView() }
        }
        .navigationViewStyle(.stack)
    }
}

struct TaskCard: View {
    let task: SBTask
    @Environment(\.colorScheme) var scheme

    var isOverdue: Bool { task.deadline < Date() && task.status != .completed }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                Image(systemName: task.status.icon)
                    .font(.system(size: 18))
                    .foregroundColor(task.status.color)
                    .frame(width: 24)

                VStack(alignment: .leading, spacing: 3) {
                    Text(task.title)
                        .font(SBFont.subheading())
                        .strikethrough(task.status == .completed)
                        .foregroundColor(task.status == .completed ? .sbTextTertiary : .primary)
                        .lineLimit(2)
                    if !task.description.isEmpty {
                        Text(task.description)
                            .font(SBFont.caption(12))
                            .foregroundColor(.sbTextSecondary)
                            .lineLimit(1)
                    }
                }
                Spacer()
                SBBadge(text: task.priority.rawValue, color: task.priority.color)
            }

            HStack(spacing: 12) {
                HStack(spacing: 4) {
                    Image(systemName: isOverdue ? "exclamationmark.circle.fill" : "calendar")
                        .font(.system(size: 11))
                        .foregroundColor(isOverdue ? .sbAccentRed : .sbTextTertiary)
                    Text(task.deadline.formatted(date: .abbreviated, time: .omitted))
                        .font(SBFont.caption(11))
                        .foregroundColor(isOverdue ? .sbAccentRed : .sbTextSecondary)
                }

                if !task.assignedTo.isEmpty {
                    HStack(spacing: 4) {
                        Image(systemName: "person.fill").font(.system(size: 11)).foregroundColor(.sbTextTertiary)
                        Text(task.assignedTo).font(SBFont.caption(11)).foregroundColor(.sbTextSecondary).lineLimit(1)
                    }
                }

                Spacer()
                SBBadge(text: task.status.rawValue, color: task.status.color)
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(scheme == .dark ? Color.sbDarkSurface : .white)
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(isOverdue ? Color.sbAccentRed.opacity(0.3) : Color.clear, lineWidth: 1.5)
                )
                .shadow(color: .black.opacity(0.05), radius: 6, y: 2)
        )
    }
}

// MARK: - Task Detail
struct TaskDetailView: View {
    @EnvironmentObject var dataStore: DataStore
    @Environment(\.colorScheme) var scheme
    @State var task: SBTask
    @State private var showDeleteAlert = false
    @State private var showEdit = false
    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        ZStack {
            (scheme == .dark ? Color.sbDarkBg : Color.sbBackground).ignoresSafeArea()
            ScrollView {
                VStack(spacing: 16) {
                    // Header
                    ZStack {
                        RoundedRectangle(cornerRadius: 20)
                            .fill(LinearGradient(colors: [task.status.color, task.status.color.opacity(0.7)], startPoint: .topLeading, endPoint: .bottomTrailing))
                            .frame(height: 120)
                        HStack {
                            VStack(alignment: .leading, spacing: 6) {
                                Text(task.title).font(SBFont.title(20)).foregroundColor(.white).lineLimit(2)
                                HStack(spacing: 8) {
                                    SBBadge(text: task.priority.rawValue, color: .white.opacity(0.25))
                                    SBBadge(text: task.status.rawValue, color: .white.opacity(0.25))
                                }
                            }
                            Spacer()
                            Image(systemName: task.status.icon).font(.system(size: 36)).foregroundColor(.white.opacity(0.4))
                        }
                        .padding(20)
                    }

                    // Info tiles
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                        InfoTile(icon: "calendar", label: "Deadline", value: task.deadline.formatted(date: .abbreviated, time: .omitted), color: task.deadline < Date() && task.status != .completed ? .sbAccentRed : .sbAccent)
                        InfoTile(icon: "person.fill", label: "Assigned To", value: task.assignedTo.isEmpty ? "Unassigned" : task.assignedTo, color: Color(hex: "#9B59B6"))
                        InfoTile(icon: "flag.fill", label: "Priority", value: task.priority.rawValue, color: task.priority.color)
                        InfoTile(icon: "clock.fill", label: "Created", value: task.createdAt.formatted(date: .abbreviated, time: .omitted), color: .sbTextSecondary)
                    }

                    if !task.description.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Description").font(SBFont.heading(15))
                            Text(task.description).font(SBFont.body()).foregroundColor(.sbTextSecondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .modifier(SBCardModifier())
                    }

                    // Status changer
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Update Status").font(SBFont.heading(15))
                        HStack(spacing: 8) {
                            ForEach(TaskStatus.allCases, id: \.self) { status in
                                Button(action: {
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                        task.status = status
                                        if status == .completed { task.completedAt = Date() }
                                        dataStore.updateTask(task)
                                    }
                                }) {
                                    VStack(spacing: 4) {
                                        Image(systemName: status.icon).font(.system(size: 14))
                                        Text(status.rawValue).font(.system(size: 9, design: .rounded))
                                    }
                                    .foregroundColor(task.status == status ? .white : status.color)
                                    .padding(10)
                                    .frame(maxWidth: .infinity)
                                    .background(task.status == status ? status.color : status.color.opacity(0.1))
                                    .clipShape(RoundedRectangle(cornerRadius: 10))
                                }
                            }
                        }
                    }
                    .modifier(SBCardModifier())

                    HStack(spacing: 12) {
                        Button(action: { showEdit = true }) {
                            Label("Edit Task", systemImage: "pencil")
                                .font(SBFont.subheading(14)).foregroundColor(.sbPrimary)
                                .frame(maxWidth: .infinity).padding(.vertical, 12)
                                .background(Color.sbPrimary.opacity(0.1))
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        Button(action: { showDeleteAlert = true }) {
                            Label("Delete", systemImage: "trash")
                                .font(SBFont.subheading(14)).foregroundColor(.sbAccentRed)
                                .frame(maxWidth: .infinity).padding(.vertical, 12)
                                .background(Color.sbAccentRed.opacity(0.1))
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                    }
                    .padding(.bottom, 80)
                }
                .padding(16)
            }
        }
        .navigationTitle("Task Detail")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showEdit) { EditTaskView(task: $task) }
        .alert("Delete Task", isPresented: $showDeleteAlert) {
            Button("Delete", role: .destructive) {
                dataStore.deleteTask(task)
                presentationMode.wrappedValue.dismiss()
            }
            Button("Cancel", role: .cancel) {}
        }
    }
}

// MARK: - Add Task
struct AddTaskView: View {
    @EnvironmentObject var dataStore: DataStore
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.colorScheme) var scheme
    @State private var title = ""
    @State private var description = ""
    @State private var status: TaskStatus = .pending
    @State private var priority: TaskPriority = .medium
    @State private var deadline = Date().addingTimeInterval(86400)
    @State private var assignedTo = ""
    @State private var showError = false

    var body: some View {
        NavigationView {
            ZStack {
                (scheme == .dark ? Color.sbDarkBg : Color.sbBackground).ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 14) {
                        SBTextField(placeholder: "Task title", text: $title, icon: "checkmark.square.fill")
                        SBTextField(placeholder: "Description (optional)", text: $description, icon: "text.alignleft")
                        SBTextField(placeholder: "Assigned to", text: $assignedTo, icon: "person.fill")

                        // Priority
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Priority").font(SBFont.caption()).foregroundColor(.sbTextSecondary)
                            HStack(spacing: 8) {
                                ForEach(TaskPriority.allCases, id: \.self) { p in
                                    Button(action: { priority = p }) {
                                        Text(p.rawValue)
                                            .font(SBFont.caption(12))
                                            .foregroundColor(priority == p ? .white : p.color)
                                            .padding(.horizontal, 12).padding(.vertical, 7)
                                            .background(priority == p ? p.color : p.color.opacity(0.12))
                                            .clipShape(Capsule())
                                    }
                                }
                            }
                        }

                        // Deadline
                        DatePicker("Deadline", selection: $deadline, displayedComponents: .date)
                            .font(SBFont.body())
                            .padding(14)
                            .background(scheme == .dark ? Color.sbDarkSurface2 : Color.sbSurface2)
                            .clipShape(RoundedRectangle(cornerRadius: 12))

                        if showError {
                            Text("Please enter a task title.").font(SBFont.caption()).foregroundColor(.sbAccentRed)
                        }

                        SBPrimaryButton("Add Task", icon: "plus.circle.fill") {
                            guard !title.isEmpty else { showError = true; return }
                            let task = SBTask(title: title, description: description, status: status, priority: priority, deadline: deadline, assignedTo: assignedTo)
                            dataStore.addTask(task)
                            if dataStore.activityLogs.isEmpty == false {
                                NotificationsManager.shared.scheduleTaskReminder(task: task)
                            }
                            presentationMode.wrappedValue.dismiss()
                        }
                    }
                    .padding(16)
                }
            }
            .navigationTitle("New Task")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { presentationMode.wrappedValue.dismiss() }.foregroundColor(.sbPrimary)
                }
            }
        }
    }
}

// MARK: - Edit Task
struct EditTaskView: View {
    @EnvironmentObject var dataStore: DataStore
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.colorScheme) var scheme
    @Binding var task: SBTask
    @State private var title = ""
    @State private var description = ""
    @State private var assignedTo = ""
    @State private var priority: TaskPriority = .medium
    @State private var deadline = Date()

    var body: some View {
        NavigationView {
            ZStack {
                (scheme == .dark ? Color.sbDarkBg : Color.sbBackground).ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 14) {
                        SBTextField(placeholder: "Task title", text: $title, icon: "checkmark.square.fill")
                        SBTextField(placeholder: "Description", text: $description, icon: "text.alignleft")
                        SBTextField(placeholder: "Assigned to", text: $assignedTo, icon: "person.fill")
                        HStack(spacing: 8) {
                            ForEach(TaskPriority.allCases, id: \.self) { p in
                                Button(action: { priority = p }) {
                                    Text(p.rawValue).font(SBFont.caption(12))
                                        .foregroundColor(priority == p ? .white : p.color)
                                        .padding(.horizontal, 12).padding(.vertical, 7)
                                        .background(priority == p ? p.color : p.color.opacity(0.12))
                                        .clipShape(Capsule())
                                }
                            }
                        }
                        DatePicker("Deadline", selection: $deadline, displayedComponents: .date)
                            .font(SBFont.body()).padding(14)
                            .background(scheme == .dark ? Color.sbDarkSurface2 : Color.sbSurface2)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        SBPrimaryButton("Save Changes", icon: "checkmark.circle.fill") {
                            task.title = title; task.description = description
                            task.assignedTo = assignedTo; task.priority = priority; task.deadline = deadline
                            dataStore.updateTask(task)
                            presentationMode.wrappedValue.dismiss()
                        }
                    }
                    .padding(16)
                }
            }
            .navigationTitle("Edit Task")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { presentationMode.wrappedValue.dismiss() }.foregroundColor(.sbPrimary)
                }
            }
            .onAppear {
                title = task.title; description = task.description
                assignedTo = task.assignedTo; priority = task.priority; deadline = task.deadline
            }
        }
    }
}
