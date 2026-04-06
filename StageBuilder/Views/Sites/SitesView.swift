import SwiftUI

// MARK: - Sites List
struct SitesView: View {
    @EnvironmentObject var dataStore: DataStore
    @Environment(\.colorScheme) var scheme
    @State private var showAdd = false
    @State private var searchText = ""

    var filtered: [SBSite] {
        searchText.isEmpty ? dataStore.sites :
            dataStore.sites.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }

    var body: some View {
        NavigationView {
            ZStack {
                (scheme == .dark ? Color.sbDarkBg : Color.sbBackground).ignoresSafeArea()
                if dataStore.sites.isEmpty {
                    SBEmptyState(icon: "building.2", title: "No Sites Yet", subtitle: "Add your first construction site to get started.")
                } else {
                    ScrollView {
                        VStack(spacing: 12) {
                            ForEach(filtered) { site in
                                NavigationLink(destination: SiteDetailView(site: site)) {
                                    SiteCard(site: site)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                        .padding(16)
                        .padding(.bottom, 80)
                    }
                }
            }
            .navigationTitle("Sites")
            .searchable(text: $searchText, prompt: "Search sites")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showAdd = true }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 20))
                            .foregroundColor(.sbPrimary)
                    }
                }
            }
            .sheet(isPresented: $showAdd) {
                AddSiteView()
            }
        }
        .navigationViewStyle(.stack)
    }
}

struct SiteCard: View {
    let site: SBSite
    @Environment(\.colorScheme) var scheme

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.sbPrimary.opacity(0.12))
                        .frame(width: 42, height: 42)
                    Image(systemName: "building.2.fill")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.sbPrimary)
                }
                VStack(alignment: .leading, spacing: 3) {
                    Text(site.name)
                        .font(SBFont.heading(16))
                    Text(site.address)
                        .font(SBFont.caption())
                        .foregroundColor(.sbTextSecondary)
                        .lineLimit(1)
                }
                Spacer()
                SBBadge(text: site.isActive ? "Active" : "Inactive",
                        color: site.isActive ? .sbAccentGreen : .sbTextTertiary)
            }

            HStack(spacing: 16) {
                Label("\(site.workerCount) workers", systemImage: "person.2.fill")
                    .font(SBFont.caption(11))
                    .foregroundColor(.sbTextSecondary)
                Spacer()
                Text("\(Int(site.progress * 100))%")
                    .font(SBFont.caption(11))
                    .foregroundColor(.sbPrimary)
            }

            GeometryReader { g in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3).fill(Color.sbBorder).frame(height: 5)
                    RoundedRectangle(cornerRadius: 3).fill(LinearGradient.sbPrimaryGradient)
                        .frame(width: g.size.width * site.progress, height: 5)
                }
            }
            .frame(height: 5)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(scheme == .dark ? Color.sbDarkSurface : .white)
                .shadow(color: .black.opacity(0.06), radius: 8, y: 3)
        )
    }
}

// MARK: - Site Detail
struct SiteDetailView: View {
    @EnvironmentObject var dataStore: DataStore
    @Environment(\.colorScheme) var scheme
    @State var site: SBSite
    @State private var showEdit = false
    @State private var showDeleteAlert = false
    @Environment(\.presentationMode) var presentationMode

    var siteTools: [SBTool] { dataStore.tools.filter { $0.siteId == site.id } }
    var siteWorkers: [SBWorker] { dataStore.workers.filter { $0.siteId == site.id } }

    var body: some View {
        ZStack {
            (scheme == .dark ? Color.sbDarkBg : Color.sbBackground).ignoresSafeArea()
            ScrollView {
                VStack(spacing: 16) {
                    // Hero
                    ZStack(alignment: .bottomLeading) {
                        LinearGradient(colors: [Color.sbPrimary, Color(hex: "#8B3A05")], startPoint: .topLeading, endPoint: .bottomTrailing)
                            .frame(height: 160)
                            .clipShape(RoundedRectangle(cornerRadius: 20))
                        VStack(alignment: .leading, spacing: 4) {
                            Text(site.name)
                                .font(SBFont.title(24))
                                .foregroundColor(.white)
                            Label(site.address, systemImage: "location.fill")
                                .font(SBFont.caption())
                                .foregroundColor(.white.opacity(0.7))
                        }
                        .padding(20)
                    }

                    // Stats row
                    HStack(spacing: 12) {
                        SiteStatPill(value: "\(site.workerCount)", label: "Workers", icon: "person.2.fill")
                        SiteStatPill(value: "\(Int(site.progress * 100))%", label: "Progress", icon: "chart.bar.fill")
                        SiteStatPill(value: site.isActive ? "Active" : "Inactive", label: "Status", icon: "dot.radiowaves.up.forward")
                    }

                    // Progress section
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Text("Project Progress")
                                .font(SBFont.heading(16))
                            Spacer()
                            Text("\(Int(site.progress * 100))%")
                                .font(SBFont.mono())
                                .foregroundColor(.sbPrimary)
                        }
                        GeometryReader { g in
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 5).fill(Color.sbBorder).frame(height: 10)
                                RoundedRectangle(cornerRadius: 5).fill(LinearGradient.sbPrimaryGradient)
                                    .frame(width: g.size.width * site.progress, height: 10)
                            }
                        }
                        .frame(height: 10)

                        // Progress editor
                        HStack {
                            Text("Adjust:")
                                .font(SBFont.caption())
                                .foregroundColor(.sbTextSecondary)
                            Slider(value: Binding(
                                get: { site.progress },
                                set: { site.progress = $0; dataStore.updateSite(site) }
                            ), in: 0...1)
                            .accentColor(.sbPrimary)
                        }
                    }
                    .modifier(SBCardModifier())

                    // Notes
                    if !site.notes.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Notes").font(SBFont.heading(16))
                            Text(site.notes).font(SBFont.body()).foregroundColor(.sbTextSecondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .modifier(SBCardModifier())
                    }

                    // Actions
                    HStack(spacing: 12) {
                        Button(action: { showEdit = true }) {
                            Label("Edit Site", systemImage: "pencil")
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
        .navigationTitle(site.name)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showEdit) {
            EditSiteView(site: $site)
        }
        .alert("Delete Site", isPresented: $showDeleteAlert) {
            Button("Delete", role: .destructive) {
                dataStore.deleteSite(site)
                presentationMode.wrappedValue.dismiss()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Are you sure you want to delete \(site.name)?")
        }
    }
}

struct SiteStatPill: View {
    let value: String
    let label: String
    let icon: String
    @Environment(\.colorScheme) var scheme

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(.sbPrimary)
            Text(value)
                .font(.system(size: 15, weight: .bold, design: .rounded))
            Text(label)
                .font(.system(size: 10, design: .rounded))
                .foregroundColor(.sbTextSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(scheme == .dark ? Color.sbDarkSurface : .white)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .shadow(color: .black.opacity(0.05), radius: 5, y: 2)
    }
}

// MARK: - Add Site
struct AddSiteView: View {
    @EnvironmentObject var dataStore: DataStore
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.colorScheme) var scheme
    @State private var name = ""
    @State private var address = ""
    @State private var workerCount = ""
    @State private var isActive = true
    @State private var notes = ""
    @State private var showError = false

    var body: some View {
        NavigationView {
            ZStack {
                (scheme == .dark ? Color.sbDarkBg : Color.sbBackground).ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 16) {
                        VStack(spacing: 12) {
                            SBTextField(placeholder: "Site name", text: $name, icon: "building.2.fill")
                            SBTextField(placeholder: "Address", text: $address, icon: "location.fill")
                            SBTextField(placeholder: "Worker count", text: $workerCount, icon: "person.2.fill", keyboardType: .numberPad)
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Notes").font(SBFont.caption()).foregroundColor(.sbTextSecondary)
                                TextEditor(text: $notes)
                                    .font(SBFont.body())
                                    .frame(height: 80)
                                    .padding(10)
                                    .background(scheme == .dark ? Color.sbDarkSurface2 : Color.sbSurface2)
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                            }
                            Toggle(isOn: $isActive) {
                                Label("Active Site", systemImage: "dot.radiowaves.up.forward")
                                    .font(SBFont.body())
                            }
                            .tint(.sbPrimary)
                            .padding(.horizontal, 16).padding(.vertical, 10)
                            .background(scheme == .dark ? Color.sbDarkSurface2 : Color.sbSurface2)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        .padding(.horizontal, 16)

                        if showError {
                            Text("Please fill in the site name and address.")
                                .font(SBFont.caption()).foregroundColor(.sbAccentRed).padding(.horizontal, 16)
                        }

                        SBPrimaryButton("Add Site", icon: "plus.circle.fill") {
                            saveSite()
                        }
                        .padding(.horizontal, 16)
                    }
                    .padding(.top, 16)
                }
            }
            .navigationTitle("New Site")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { presentationMode.wrappedValue.dismiss() }
                        .foregroundColor(.sbPrimary)
                }
            }
        }
    }

    func saveSite() {
        guard !name.isEmpty, !address.isEmpty else { showError = true; return }
        let count = Int(workerCount) ?? 0
        let site = SBSite(name: name, address: address, workerCount: count, isActive: isActive, notes: notes)
        dataStore.addSite(site)
        presentationMode.wrappedValue.dismiss()
    }
}

// MARK: - Edit Site
struct EditSiteView: View {
    @EnvironmentObject var dataStore: DataStore
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.colorScheme) var scheme
    @Binding var site: SBSite
    @State private var name: String = ""
    @State private var address: String = ""
    @State private var workerCount: String = ""
    @State private var isActive: Bool = true
    @State private var notes: String = ""

    var body: some View {
        NavigationView {
            ZStack {
                (scheme == .dark ? Color.sbDarkBg : Color.sbBackground).ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 12) {
                        SBTextField(placeholder: "Site name", text: $name, icon: "building.2.fill")
                        SBTextField(placeholder: "Address", text: $address, icon: "location.fill")
                        SBTextField(placeholder: "Worker count", text: $workerCount, icon: "person.2.fill", keyboardType: .numberPad)
                        Toggle(isOn: $isActive) {
                            Label("Active Site", systemImage: "dot.radiowaves.up.forward").font(SBFont.body())
                        }
                        .tint(.sbPrimary)
                        .padding(.horizontal, 16).padding(.vertical, 10)
                        .background(scheme == .dark ? Color.sbDarkSurface2 : Color.sbSurface2)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .padding(16)

                    SBPrimaryButton("Save Changes", icon: "checkmark.circle.fill") {
                        site.name = name
                        site.address = address
                        site.workerCount = Int(workerCount) ?? site.workerCount
                        site.isActive = isActive
                        site.notes = notes
                        dataStore.updateSite(site)
                        presentationMode.wrappedValue.dismiss()
                    }
                    .padding(.horizontal, 16)
                }
            }
            .navigationTitle("Edit Site")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { presentationMode.wrappedValue.dismiss() }
                        .foregroundColor(.sbPrimary)
                }
            }
            .onAppear {
                name = site.name; address = site.address
                workerCount = "\(site.workerCount)"; isActive = site.isActive; notes = site.notes
            }
        }
    }
}
