import SwiftUI

struct WorkersView: View {
    @EnvironmentObject var dataStore: DataStore
    @Environment(\.colorScheme) var scheme
    @State private var showAdd = false
    @State private var searchText = ""
    @State private var filterRole: WorkerRole? = nil

    var filtered: [SBWorker] {
        dataStore.workers.filter { w in
            let matchSearch = searchText.isEmpty || w.name.localizedCaseInsensitiveContains(searchText)
            let matchRole = filterRole == nil || w.role == filterRole
            return matchSearch && matchRole
        }
    }

    var body: some View {
        ZStack {
            (scheme == .dark ? Color.sbDarkBg : Color.sbBackground).ignoresSafeArea()
            VStack(spacing: 0) {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        CategoryChip(label: "All", isSelected: filterRole == nil) {
                            withAnimation { filterRole = nil }
                        }
                        ForEach(WorkerRole.allCases, id: \.self) { role in
                            CategoryChip(label: role.rawValue, isSelected: filterRole == role) {
                                withAnimation { filterRole = filterRole == role ? nil : role }
                            }
                        }
                    }
                    .padding(.horizontal, 16).padding(.vertical, 10)
                }

                if filtered.isEmpty {
                    SBEmptyState(icon: "person.2", title: "No Workers Found", subtitle: "Add team members to track their assignments.")
                } else {
                    ScrollView {
                        LazyVStack(spacing: 10) {
                            ForEach(filtered) { worker in
                                NavigationLink(destination: WorkerDetailView(worker: worker)) {
                                    WorkerRow(worker: worker)
                                }
                                .buttonStyle(PlainButtonStyle())
                                .contextMenu {
                                    Button(role: .destructive, action: { dataStore.deleteWorker(worker) }) {
                                        Label("Remove Worker", systemImage: "trash")
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
        .navigationTitle("Workers")
        .searchable(text: $searchText, prompt: "Search workers")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { showAdd = true }) {
                    Image(systemName: "person.badge.plus.fill").font(.system(size: 18)).foregroundColor(.sbPrimary)
                }
            }
        }
        .sheet(isPresented: $showAdd) { AddWorkerView() }
    }
}

struct WorkerRow: View {
    let worker: SBWorker
    @Environment(\.colorScheme) var scheme

    let avatarColors: [Color] = [.sbPrimary, .sbAccent, .sbAccentGreen, Color(hex: "#9B59B6"), Color(hex: "#E82B1A")]

    var avatarColor: Color {
        let index = abs(worker.name.hashValue) % avatarColors.count
        return avatarColors[index]
    }

    var body: some View {
        HStack(spacing: 14) {
            // Avatar
            ZStack {
                Circle()
                    .fill(avatarColor)
                    .frame(width: 46, height: 46)
                Text(worker.avatarInitials)
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(worker.name).font(SBFont.subheading())
                HStack(spacing: 6) {
                    Image(systemName: worker.role.icon).font(.system(size: 11)).foregroundColor(.sbPrimary)
                    Text(worker.role.rawValue).font(SBFont.caption(12)).foregroundColor(.sbTextSecondary)
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                SBBadge(text: worker.isActive ? "Active" : "Inactive",
                        color: worker.isActive ? .sbAccentGreen : .sbTextTertiary)
                if !worker.phone.isEmpty {
                    Text(worker.phone)
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundColor(.sbTextTertiary)
                }
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

// MARK: - Worker Detail
struct WorkerDetailView: View {
    @EnvironmentObject var dataStore: DataStore
    @Environment(\.colorScheme) var scheme
    @State var worker: SBWorker
    @State private var showEdit = false
    @State private var showDeleteAlert = false
    @Environment(\.presentationMode) var presentationMode

    let avatarColors: [Color] = [.sbPrimary, .sbAccent, .sbAccentGreen, Color(hex: "#9B59B6"), Color(hex: "#E82B1A")]
    var avatarColor: Color {
        let index = abs(worker.name.hashValue) % avatarColors.count
        return avatarColors[index]
    }

    var body: some View {
        ZStack {
            (scheme == .dark ? Color.sbDarkBg : Color.sbBackground).ignoresSafeArea()
            ScrollView {
                VStack(spacing: 16) {
                    // Profile header
                    VStack(spacing: 16) {
                        ZStack {
                            Circle()
                                .fill(LinearGradient(colors: [avatarColor, avatarColor.opacity(0.7)], startPoint: .topLeading, endPoint: .bottomTrailing))
                                .frame(width: 90, height: 90)
                                .shadow(color: avatarColor.opacity(0.4), radius: 15)
                            Text(worker.avatarInitials)
                                .font(.system(size: 32, weight: .black, design: .rounded))
                                .foregroundColor(.white)
                        }
                        VStack(spacing: 6) {
                            Text(worker.name).font(SBFont.title(24))
                            HStack(spacing: 8) {
                                Image(systemName: worker.role.icon).foregroundColor(.sbPrimary)
                                Text(worker.role.rawValue).font(SBFont.body()).foregroundColor(.sbTextSecondary)
                            }
                        }
                    }
                    .padding(.top, 8)

                    // Contact info
                    VStack(spacing: 0) {
                        if !worker.phone.isEmpty {
                            ContactRow(icon: "phone.fill", label: "Phone", value: worker.phone, color: .sbAccentGreen)
                            Divider().padding(.leading, 52)
                        }
                        if !worker.email.isEmpty {
                            ContactRow(icon: "envelope.fill", label: "Email", value: worker.email, color: .sbAccent)
                        }
                    }
                    .background(scheme == .dark ? Color.sbDarkSurface : .white)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .shadow(color: .black.opacity(0.05), radius: 6, y: 2)

                    // Status toggle
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Active Status").font(SBFont.subheading(15))
                            Text(worker.isActive ? "Worker is currently active" : "Worker is inactive")
                                .font(SBFont.caption()).foregroundColor(.sbTextSecondary)
                        }
                        Spacer()
                        Toggle("", isOn: Binding(
                            get: { worker.isActive },
                            set: { worker.isActive = $0; dataStore.updateWorker(worker) }
                        ))
                        .tint(.sbAccentGreen)
                    }
                    .modifier(SBCardModifier())

                    // Actions
                    HStack(spacing: 12) {
                        Button(action: { showEdit = true }) {
                            Label("Edit", systemImage: "pencil")
                                .font(SBFont.subheading(14))
                                .foregroundColor(.sbPrimary)
                                .frame(maxWidth: .infinity).padding(.vertical, 12)
                                .background(Color.sbPrimary.opacity(0.1))
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        Button(action: { showDeleteAlert = true }) {
                            Label("Remove", systemImage: "trash")
                                .font(SBFont.subheading(14))
                                .foregroundColor(.sbAccentRed)
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
        .navigationTitle(worker.name)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showEdit) { EditWorkerView(worker: $worker) }
        .alert("Remove Worker", isPresented: $showDeleteAlert) {
            Button("Remove", role: .destructive) {
                dataStore.deleteWorker(worker)
                presentationMode.wrappedValue.dismiss()
            }
            Button("Cancel", role: .cancel) {}
        }
    }
}

struct ContactRow: View {
    let icon: String
    let label: String
    let value: String
    let color: Color

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(color)
                .frame(width: 34, height: 34)
                .background(color.opacity(0.12))
                .clipShape(Circle())
            VStack(alignment: .leading, spacing: 2) {
                Text(label).font(SBFont.caption(11)).foregroundColor(.sbTextTertiary)
                Text(value).font(SBFont.body(14))
            }
            Spacer()
        }
        .padding(14)
    }
}

// MARK: - Add Worker
struct AddWorkerView: View {
    @EnvironmentObject var dataStore: DataStore
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.colorScheme) var scheme
    @State private var name = ""
    @State private var role: WorkerRole = .laborer
    @State private var phone = ""
    @State private var email = ""
    @State private var showError = false

    var body: some View {
        NavigationView {
            ZStack {
                (scheme == .dark ? Color.sbDarkBg : Color.sbBackground).ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 14) {
                        SBTextField(placeholder: "Full name", text: $name, icon: "person.fill")

                        VStack(alignment: .leading, spacing: 6) {
                            Text("Role").font(SBFont.caption()).foregroundColor(.sbTextSecondary)
                            Picker("Role", selection: $role) {
                                ForEach(WorkerRole.allCases, id: \.self) { r in
                                    Label(r.rawValue, systemImage: r.icon).tag(r)
                                }
                            }
                            .pickerStyle(.wheel)
                            .frame(height: 120)
                            .clipped()
                            .background(scheme == .dark ? Color.sbDarkSurface2 : Color.sbSurface2)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }

                        SBTextField(placeholder: "Phone number", text: $phone, icon: "phone.fill", keyboardType: .phonePad)
                        SBTextField(placeholder: "Email (optional)", text: $email, icon: "envelope.fill", keyboardType: .emailAddress)

                        if showError {
                            Text("Please enter worker's name.").font(SBFont.caption()).foregroundColor(.sbAccentRed)
                        }

                        SBPrimaryButton("Add Worker", icon: "person.badge.plus.fill") {
                            guard !name.isEmpty else { showError = true; return }
                            let w = SBWorker(name: name, role: role, phone: phone, email: email)
                            dataStore.addWorker(w)
                            presentationMode.wrappedValue.dismiss()
                        }
                    }
                    .padding(16)
                }
            }
            .navigationTitle("Add Worker")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { presentationMode.wrappedValue.dismiss() }.foregroundColor(.sbPrimary)
                }
            }
        }
    }
}

// MARK: - Edit Worker
struct EditWorkerView: View {
    @EnvironmentObject var dataStore: DataStore
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.colorScheme) var scheme
    @Binding var worker: SBWorker
    @State private var name = ""
    @State private var phone = ""
    @State private var email = ""
    @State private var role: WorkerRole = .laborer

    var body: some View {
        NavigationView {
            ZStack {
                (scheme == .dark ? Color.sbDarkBg : Color.sbBackground).ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 14) {
                        SBTextField(placeholder: "Full name", text: $name, icon: "person.fill")
                        Picker("Role", selection: $role) {
                            ForEach(WorkerRole.allCases, id: \.self) { r in Text(r.rawValue).tag(r) }
                        }
                        .pickerStyle(.menu)
                        .padding(14)
                        .background(scheme == .dark ? Color.sbDarkSurface2 : Color.sbSurface2)
                        .clipShape(RoundedRectangle(cornerRadius: 12))

                        SBTextField(placeholder: "Phone", text: $phone, icon: "phone.fill", keyboardType: .phonePad)
                        SBTextField(placeholder: "Email", text: $email, icon: "envelope.fill", keyboardType: .emailAddress)

                        SBPrimaryButton("Save Changes", icon: "checkmark.circle.fill") {
                            worker.name = name; worker.phone = phone; worker.email = email; worker.role = role
                            dataStore.updateWorker(worker)
                            presentationMode.wrappedValue.dismiss()
                        }
                    }
                    .padding(16)
                }
            }
            .navigationTitle("Edit Worker")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { presentationMode.wrappedValue.dismiss() }.foregroundColor(.sbPrimary)
                }
            }
            .onAppear {
                name = worker.name; phone = worker.phone; email = worker.email; role = worker.role
            }
        }
    }
}
