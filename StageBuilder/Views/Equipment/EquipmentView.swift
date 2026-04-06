import SwiftUI

struct EquipmentView: View {
    @EnvironmentObject var dataStore: DataStore
    @Environment(\.colorScheme) var scheme
    @State private var showAdd = false
    @State private var searchText = ""

    var filtered: [SBEquipment] {
        searchText.isEmpty ? dataStore.equipment :
            dataStore.equipment.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }

    var body: some View {
        ZStack {
            (scheme == .dark ? Color.sbDarkBg : Color.sbBackground).ignoresSafeArea()
            if filtered.isEmpty {
                SBEmptyState(icon: "gearshape.2", title: "No Equipment", subtitle: "Add construction equipment to track.")
            } else {
                ScrollView {
                    LazyVStack(spacing: 10) {
                        ForEach(filtered) { eq in
                            NavigationLink(destination: EquipmentDetailView(equipment: eq)) {
                                EquipmentRow(equipment: eq)
                            }
                            .buttonStyle(PlainButtonStyle())
                            .contextMenu {
                                Button(action: {
                                    var e = eq; e.isInUse.toggle(); dataStore.updateEquipment(e)
                                }) {
                                    Label(eq.isInUse ? "Mark Available" : "Mark Active",
                                          systemImage: eq.isInUse ? "checkmark.circle" : "bolt.fill")
                                }
                                Button(role: .destructive, action: { dataStore.deleteEquipment(eq) }) {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                        }
                    }
                    .padding(16)
                    .padding(.bottom, 80)
                }
            }
        }
        .navigationTitle("Equipment")
        .searchable(text: $searchText, prompt: "Search equipment")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { showAdd = true }) {
                    Image(systemName: "plus.circle.fill").font(.system(size: 20)).foregroundColor(.sbPrimary)
                }
            }
        }
        .sheet(isPresented: $showAdd) { AddEquipmentView() }
    }
}

struct EquipmentRow: View {
    let equipment: SBEquipment
    @Environment(\.colorScheme) var scheme

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.sbAccent.opacity(0.12))
                    .frame(width: 48, height: 48)
                Image(systemName: "gearshape.2.fill")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.sbAccent)
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(equipment.name)
                        .font(SBFont.subheading())
                        .lineLimit(1)
                    if equipment.isInUse {
                        SBBadge(text: "Active", color: .sbPrimary)
                    }
                }
                HStack(spacing: 8) {
                    Label(equipment.location, systemImage: "location.fill")
                        .font(SBFont.caption(11))
                        .foregroundColor(.sbTextSecondary)
                    if let maint = equipment.nextMaintenance {
                        Text("•").foregroundColor(.sbTextTertiary).font(.system(size: 10))
                        Label(maint.formatted(date: .abbreviated, time: .omitted), systemImage: "wrench")
                            .font(SBFont.caption(11))
                            .foregroundColor(maint < Date() ? .sbAccentRed : .sbTextSecondary)
                    }
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                SBStatusDot(status: equipment.condition)
                Text(equipment.condition.rawValue)
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

// MARK: - Equipment Detail
struct EquipmentDetailView: View {
    @EnvironmentObject var dataStore: DataStore
    @Environment(\.colorScheme) var scheme
    @State var equipment: SBEquipment
    @State private var showMaintenance = false
    @State private var showDeleteAlert = false
    @Environment(\.presentationMode) var presentationMode

    var maintenanceHistory: [MaintenanceRecord] {
        dataStore.maintenanceRecords.filter { $0.equipmentId == equipment.id }
    }

    var body: some View {
        ZStack {
            (scheme == .dark ? Color.sbDarkBg : Color.sbBackground).ignoresSafeArea()
            ScrollView {
                VStack(spacing: 16) {
                    // Header
                    ZStack {
                        RoundedRectangle(cornerRadius: 20)
                            .fill(LinearGradient(colors: [.sbAccent, Color(hex: "#0C4DB8")], startPoint: .topLeading, endPoint: .bottomTrailing))
                            .frame(height: 130)
                        HStack(spacing: 20) {
                            Image(systemName: "gearshape.2.fill")
                                .font(.system(size: 40, weight: .bold))
                                .foregroundColor(.white.opacity(0.9))
                            VStack(alignment: .leading, spacing: 6) {
                                Text(equipment.name).font(SBFont.title(22)).foregroundColor(.white)
                                SBBadge(text: equipment.condition.rawValue, color: .white.opacity(0.25))
                            }
                            Spacer()
                        }
                        .padding(20)
                    }

                    // Info grid
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                        InfoTile(icon: "location.fill", label: "Location", value: equipment.location, color: .sbAccent)
                        InfoTile(icon: "bolt.fill", label: "Status", value: equipment.isInUse ? "In Use" : "Available", color: equipment.isInUse ? .sbPrimary : .sbAccentGreen)
                        InfoTile(icon: "wrench.fill", label: "Last Service", value: equipment.lastMaintenance?.formatted(date: .abbreviated, time: .omitted) ?? "None", color: .sbAccentYellow)
                        InfoTile(icon: "calendar.badge.clock", label: "Next Service", value: equipment.nextMaintenance?.formatted(date: .abbreviated, time: .omitted) ?? "Not set", color: equipment.nextMaintenance.map { $0 < Date() ? .sbAccentRed : .sbAccentGreen } ?? .sbTextSecondary)
                    }

                    // Toggle active
                    Button(action: {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            equipment.isInUse.toggle()
                            dataStore.updateEquipment(equipment)
                        }
                    }) {
                        HStack {
                            Image(systemName: equipment.isInUse ? "checkmark.circle.fill" : "bolt.fill")
                            Text(equipment.isInUse ? "Mark as Available" : "Mark as Active")
                                .font(SBFont.subheading())
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(equipment.isInUse ? Color.sbAccentGreen : Color.sbAccent)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                    }

                    // Maintenance log button
                    Button(action: { showMaintenance = true }) {
                        HStack {
                            Label("Log Maintenance", systemImage: "wrench.and.screwdriver.fill")
                                .font(SBFont.subheading(15))
                            Spacer()
                            Image(systemName: "plus.circle.fill").foregroundColor(.sbPrimary)
                        }
                        .padding(16)
                        .background(scheme == .dark ? Color.sbDarkSurface : .white)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        .shadow(color: .black.opacity(0.05), radius: 6, y: 2)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .foregroundColor(.primary)

                    // Maintenance history
                    if !maintenanceHistory.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Maintenance History").font(SBFont.heading(16))
                            ForEach(maintenanceHistory) { record in
                                MaintenanceRow(record: record)
                            }
                        }
                        .modifier(SBCardModifier())
                    }

                    Button(action: { showDeleteAlert = true }) {
                        Label("Delete Equipment", systemImage: "trash")
                            .font(SBFont.subheading(14))
                            .foregroundColor(.sbAccentRed)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Color.sbAccentRed.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .padding(.bottom, 80)
                }
                .padding(16)
            }
        }
        .navigationTitle(equipment.name)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showMaintenance) { AddMaintenanceView(equipment: equipment) }
        .alert("Delete Equipment", isPresented: $showDeleteAlert) {
            Button("Delete", role: .destructive) {
                dataStore.deleteEquipment(equipment)
                presentationMode.wrappedValue.dismiss()
            }
            Button("Cancel", role: .cancel) {}
        }
    }
}

struct MaintenanceRow: View {
    let record: MaintenanceRecord
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "wrench.fill")
                .font(.system(size: 14))
                .foregroundColor(.sbPrimary)
                .frame(width: 30, height: 30)
                .background(Color.sbPrimary.opacity(0.1))
                .clipShape(Circle())
            VStack(alignment: .leading, spacing: 2) {
                Text(record.description).font(SBFont.caption()).lineLimit(1)
                Text(record.serviceDate.formatted(date: .abbreviated, time: .omitted))
                    .font(.system(size: 10, design: .rounded))
                    .foregroundColor(.sbTextSecondary)
            }
            Spacer()
            Text("$\(Int(record.cost))").font(SBFont.mono(12)).foregroundColor(.sbPrimary)
        }
    }
}

// MARK: - Add Equipment
struct AddEquipmentView: View {
    @EnvironmentObject var dataStore: DataStore
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.colorScheme) var scheme
    @State private var name = ""
    @State private var condition: ToolCondition = .good
    @State private var location = ""
    @State private var notes = ""
    @State private var showError = false

    var body: some View {
        NavigationView {
            ZStack {
                (scheme == .dark ? Color.sbDarkBg : Color.sbBackground).ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 14) {
                        SBTextField(placeholder: "Equipment name", text: $name, icon: "gearshape.2.fill")

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

                        if showError {
                            Text("Please enter name and location.").font(SBFont.caption()).foregroundColor(.sbAccentRed)
                        }

                        SBPrimaryButton("Add Equipment", icon: "plus.circle.fill") {
                            guard !name.isEmpty, !location.isEmpty else { showError = true; return }
                            let eq = SBEquipment(name: name, condition: condition, location: location, notes: notes)
                            dataStore.addEquipment(eq)
                            presentationMode.wrappedValue.dismiss()
                        }
                    }
                    .padding(16)
                }
            }
            .navigationTitle("Add Equipment")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { presentationMode.wrappedValue.dismiss() }.foregroundColor(.sbPrimary)
                }
            }
        }
    }
}

// MARK: - Add Maintenance
struct AddMaintenanceView: View {
    @EnvironmentObject var dataStore: DataStore
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.colorScheme) var scheme
    let equipment: SBEquipment
    @State private var description = ""
    @State private var performedBy = ""
    @State private var costText = ""
    @State private var serviceDate = Date()
    @State private var nextServiceDate = Date().addingTimeInterval(86400 * 90)
    @State private var hasNextDate = false
    @State private var showError = false

    var body: some View {
        NavigationView {
            ZStack {
                (scheme == .dark ? Color.sbDarkBg : Color.sbBackground).ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 14) {
                        Text("Equipment: \(equipment.name)")
                            .font(SBFont.body())
                            .foregroundColor(.sbTextSecondary)
                            .frame(maxWidth: .infinity, alignment: .leading)

                        SBTextField(placeholder: "Service description", text: $description, icon: "wrench.fill")
                        SBTextField(placeholder: "Performed by", text: $performedBy, icon: "person.fill")
                        SBTextField(placeholder: "Cost ($)", text: $costText, icon: "dollarsign.circle.fill", keyboardType: .decimalPad)

                        DatePicker("Service Date", selection: $serviceDate, displayedComponents: .date)
                            .font(SBFont.body())
                            .padding(14)
                            .background(scheme == .dark ? Color.sbDarkSurface2 : Color.sbSurface2)
                            .clipShape(RoundedRectangle(cornerRadius: 12))

                        Toggle("Set next service date", isOn: $hasNextDate)
                            .tint(.sbPrimary)
                            .font(SBFont.body())
                            .padding(.horizontal, 16).padding(.vertical, 10)
                            .background(scheme == .dark ? Color.sbDarkSurface2 : Color.sbSurface2)
                            .clipShape(RoundedRectangle(cornerRadius: 12))

                        if hasNextDate {
                            DatePicker("Next Service", selection: $nextServiceDate, displayedComponents: .date)
                                .font(SBFont.body())
                                .padding(14)
                                .background(scheme == .dark ? Color.sbDarkSurface2 : Color.sbSurface2)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        }

                        if showError {
                            Text("Please enter a description.").font(SBFont.caption()).foregroundColor(.sbAccentRed)
                        }

                        SBPrimaryButton("Log Maintenance", icon: "checkmark.circle.fill") {
                            guard !description.isEmpty else { showError = true; return }
                            let record = MaintenanceRecord(
                                equipmentId: equipment.id,
                                equipmentName: equipment.name,
                                serviceDate: serviceDate,
                                description: description,
                                performedBy: performedBy,
                                cost: Double(costText) ?? 0,
                                nextServiceDate: hasNextDate ? nextServiceDate : nil
                            )
                            dataStore.addMaintenance(record)
                            presentationMode.wrappedValue.dismiss()
                        }
                    }
                    .padding(16)
                }
            }
            .navigationTitle("Log Maintenance")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { presentationMode.wrappedValue.dismiss() }.foregroundColor(.sbPrimary)
                }
            }
        }
    }
}
