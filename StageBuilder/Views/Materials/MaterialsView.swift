import SwiftUI

// MARK: - Materials View
struct MaterialsView: View {
    @EnvironmentObject var dataStore: DataStore
    @Environment(\.colorScheme) var scheme
    @State private var showAdd = false
    @State private var searchText = ""

    var filtered: [SBMaterial] {
        searchText.isEmpty ? dataStore.materials :
            dataStore.materials.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }

    var body: some View {
        ZStack {
            (scheme == .dark ? Color.sbDarkBg : Color.sbBackground).ignoresSafeArea()

            VStack(spacing: 0) {
                // Low stock banner
                if dataStore.lowStockMaterialsCount > 0 {
                    HStack(spacing: 8) {
                        Image(systemName: "exclamationmark.triangle.fill").foregroundColor(.sbAccentYellow)
                        Text("\(dataStore.lowStockMaterialsCount) material(s) low on stock")
                            .font(SBFont.caption())
                        Spacer()
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(Color.sbAccentYellow.opacity(0.12))
                }

                if filtered.isEmpty {
                    SBEmptyState(icon: "shippingbox", title: "No Materials", subtitle: "Add construction materials to track inventory.")
                } else {
                    ScrollView {
                        LazyVStack(spacing: 10) {
                            ForEach(filtered) { mat in
                                NavigationLink(destination: MaterialDetailView(material: mat)) {
                                    MaterialRow(material: mat)
                                }
                                .buttonStyle(PlainButtonStyle())
                                .contextMenu {
                                    Button(role: .destructive, action: { dataStore.deleteMaterial(mat) }) {
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
        }
        .navigationTitle("Materials")
        .searchable(text: $searchText, prompt: "Search materials")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { showAdd = true }) {
                    Image(systemName: "plus.circle.fill").font(.system(size: 20)).foregroundColor(.sbPrimary)
                }
            }
        }
        .sheet(isPresented: $showAdd) { AddMaterialView() }
    }
}

struct MaterialRow: View {
    let material: SBMaterial
    @Environment(\.colorScheme) var scheme

    var fillRatio: Double {
        guard material.minQuantity > 0 else { return 1.0 }
        return min(material.quantity / (material.minQuantity * 4), 1.0)
    }

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill((material.isLowStock ? Color.sbAccentRed : Color.sbAccentGreen).opacity(0.12))
                    .frame(width: 48, height: 48)
                Image(systemName: "shippingbox.fill")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(material.isLowStock ? .sbAccentRed : .sbAccentGreen)
            }

            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(material.name).font(SBFont.subheading()).lineLimit(1)
                    if material.isLowStock {
                        SBBadge(text: "Low Stock", color: .sbAccentYellow)
                    }
                }

                GeometryReader { g in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 3).fill(Color.sbBorder).frame(height: 5)
                        RoundedRectangle(cornerRadius: 3)
                            .fill(material.isLowStock ? Color.sbAccentRed : Color.sbAccentGreen)
                            .frame(width: g.size.width * fillRatio, height: 5)
                    }
                }
                .frame(height: 5)
            }

            VStack(alignment: .trailing, spacing: 2) {
                Text("\(Int(material.quantity))")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                Text(material.unit)
                    .font(.system(size: 11, design: .rounded))
                    .foregroundColor(.sbTextSecondary)
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

// MARK: - Material Detail
struct MaterialDetailView: View {
    @EnvironmentObject var dataStore: DataStore
    @Environment(\.colorScheme) var scheme
    @State var material: SBMaterial
    @State private var adjustQty = ""
    @State private var showDeleteAlert = false
    @State private var showConfirm = false
    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        ZStack {
            (scheme == .dark ? Color.sbDarkBg : Color.sbBackground).ignoresSafeArea()
            ScrollView {
                VStack(spacing: 16) {
                    // Header
                    ZStack {
                        RoundedRectangle(cornerRadius: 20)
                            .fill(LinearGradient(colors: [.sbAccentGreen, Color(hex: "#1A7A42")], startPoint: .topLeading, endPoint: .bottomTrailing))
                            .frame(height: 130)
                        HStack(spacing: 20) {
                            Image(systemName: "shippingbox.fill")
                                .font(.system(size: 40)).foregroundColor(.white.opacity(0.9))
                            VStack(alignment: .leading, spacing: 6) {
                                Text(material.name).font(SBFont.title(22)).foregroundColor(.white)
                                Text("\(Int(material.quantity)) \(material.unit) available")
                                    .font(SBFont.body()).foregroundColor(.white.opacity(0.75))
                            }
                            Spacer()
                        }
                        .padding(20)
                    }

                    // Info
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                        InfoTile(icon: "shippingbox.fill", label: "In Stock", value: "\(Int(material.quantity)) \(material.unit)", color: .sbAccentGreen)
                        InfoTile(icon: "exclamationmark.triangle.fill", label: "Min Threshold", value: "\(Int(material.minQuantity)) \(material.unit)", color: .sbAccentYellow)
                        InfoTile(icon: "location.fill", label: "Location", value: material.location, color: .sbAccent)
                        InfoTile(icon: "chart.bar.fill", label: "Status", value: material.isLowStock ? "Low Stock" : "OK", color: material.isLowStock ? .sbAccentRed : .sbAccentGreen)
                    }

                    // Adjust quantity
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Adjust Quantity").font(SBFont.heading(16))

                        HStack(spacing: 12) {
                            Button(action: {
                                let delta = Double(adjustQty) ?? 0
                                if material.quantity - delta >= 0 {
                                    material.quantity -= delta
                                    dataStore.updateMaterial(material)
                                    let item = SBInventoryItem(materialId: material.id, materialName: material.name, quantityIn: 0, quantityOut: delta, date: Date())
                                    dataStore.addInventoryMovement(item)
                                    adjustQty = ""
                                    showConfirm = true
                                }
                            }) {
                                Label("Use", systemImage: "minus.circle.fill")
                                    .font(SBFont.subheading(14))
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 12)
                                    .background(Color.sbAccentRed)
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                            }

                            SBTextField(placeholder: "Amount", text: $adjustQty, icon: "number", keyboardType: .decimalPad)

                            Button(action: {
                                let delta = Double(adjustQty) ?? 0
                                material.quantity += delta
                                dataStore.updateMaterial(material)
                                let item = SBInventoryItem(materialId: material.id, materialName: material.name, quantityIn: delta, quantityOut: 0, date: Date())
                                dataStore.addInventoryMovement(item)
                                adjustQty = ""
                                showConfirm = true
                            }) {
                                Label("Add", systemImage: "plus.circle.fill")
                                    .font(SBFont.subheading(14))
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 12)
                                    .background(Color.sbAccentGreen)
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                            }
                        }

                        if showConfirm {
                            HStack(spacing: 6) {
                                Image(systemName: "checkmark.circle.fill").foregroundColor(.sbAccentGreen)
                                Text("Quantity updated successfully").font(SBFont.caption()).foregroundColor(.sbAccentGreen)
                            }
                            .transition(.move(edge: .top).combined(with: .opacity))
                        }
                    }
                    .modifier(SBCardModifier())
                    .animation(.spring(response: 0.3, dampingFraction: 0.7), value: showConfirm)

                    Button(action: { showDeleteAlert = true }) {
                        Label("Delete Material", systemImage: "trash")
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
        .navigationTitle(material.name)
        .navigationBarTitleDisplayMode(.inline)
        .alert("Delete Material", isPresented: $showDeleteAlert) {
            Button("Delete", role: .destructive) {
                dataStore.deleteMaterial(material)
                presentationMode.wrappedValue.dismiss()
            }
            Button("Cancel", role: .cancel) {}
        }
    }
}

// MARK: - Add Material
struct AddMaterialView: View {
    @EnvironmentObject var dataStore: DataStore
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.colorScheme) var scheme
    @State private var name = ""
    @State private var unit = "bags"
    @State private var quantity = ""
    @State private var minQuantity = ""
    @State private var location = "Warehouse"
    @State private var showError = false

    let units = ["bags", "pcs", "boards", "rods", "sheets", "kg", "tons", "liters", "m³", "m²"]

    var body: some View {
        NavigationView {
            ZStack {
                (scheme == .dark ? Color.sbDarkBg : Color.sbBackground).ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 14) {
                        SBTextField(placeholder: "Material name", text: $name, icon: "shippingbox.fill")

                        VStack(alignment: .leading, spacing: 6) {
                            Text("Unit").font(SBFont.caption()).foregroundColor(.sbTextSecondary)
                            Picker("Unit", selection: $unit) {
                                ForEach(units, id: \.self) { Text($0).tag($0) }
                            }
                            .pickerStyle(.wheel)
                            .frame(height: 100)
                            .clipped()
                            .background(scheme == .dark ? Color.sbDarkSurface2 : Color.sbSurface2)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }

                        SBTextField(placeholder: "Current quantity", text: $quantity, icon: "number", keyboardType: .decimalPad)
                        SBTextField(placeholder: "Minimum stock level", text: $minQuantity, icon: "exclamationmark.triangle.fill", keyboardType: .decimalPad)
                        SBTextField(placeholder: "Storage location", text: $location, icon: "location.fill")

                        if showError {
                            Text("Please fill in the material name and quantity.").font(SBFont.caption()).foregroundColor(.sbAccentRed)
                        }

                        SBPrimaryButton("Add Material", icon: "plus.circle.fill") {
                            guard !name.isEmpty, !quantity.isEmpty else { showError = true; return }
                            let mat = SBMaterial(name: name, unit: unit, quantity: Double(quantity) ?? 0, minQuantity: Double(minQuantity) ?? 0, location: location)
                            dataStore.addMaterial(mat)
                            presentationMode.wrappedValue.dismiss()
                        }
                    }
                    .padding(16)
                }
            }
            .navigationTitle("Add Material")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { presentationMode.wrappedValue.dismiss() }.foregroundColor(.sbPrimary)
                }
            }
        }
    }
}

// MARK: - Inventory View
struct InventoryView: View {
    @EnvironmentObject var dataStore: DataStore
    @Environment(\.colorScheme) var scheme

    var body: some View {
        ZStack {
            (scheme == .dark ? Color.sbDarkBg : Color.sbBackground).ignoresSafeArea()
            ScrollView {
                VStack(spacing: 16) {
                    // Summary card
                    VStack(spacing: 12) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Warehouse Overview").font(SBFont.heading())
                                Text("\(dataStore.materials.count) material types").font(SBFont.caption()).foregroundColor(.sbTextSecondary)
                            }
                            Spacer()
                            Image(systemName: "archivebox.fill").font(.system(size: 28)).foregroundColor(.sbPrimary)
                        }
                        Divider()
                        HStack(spacing: 0) {
                            InventorySummaryItem(value: "\(dataStore.materials.filter { !$0.isLowStock }.count)", label: "Well Stocked", color: .sbAccentGreen)
                            InventorySummaryItem(value: "\(dataStore.lowStockMaterialsCount)", label: "Low Stock", color: .sbAccentYellow)
                            InventorySummaryItem(value: "\(dataStore.materials.filter { $0.quantity == 0 }.count)", label: "Out of Stock", color: .sbAccentRed)
                        }
                    }
                    .modifier(SBCardModifier())

                    // Materials grid
                    Text("Available Materials").font(SBFont.heading(16)).frame(maxWidth: .infinity, alignment: .leading)

                    ForEach(dataStore.materials) { mat in
                        NavigationLink(destination: MaterialDetailView(material: mat)) {
                            InventoryItemRow(material: mat)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }

                    // Recent movements
                    if !dataStore.inventoryItems.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Recent Movements").font(SBFont.heading(16))
                            ForEach(dataStore.inventoryItems.prefix(8)) { item in
                                HStack(spacing: 12) {
                                    Image(systemName: item.quantityIn > 0 ? "arrow.down.circle.fill" : "arrow.up.circle.fill")
                                        .foregroundColor(item.quantityIn > 0 ? .sbAccentGreen : .sbAccentRed)
                                        .font(.system(size: 18))
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(item.materialName).font(SBFont.caption())
                                        Text(item.date.formatted(date: .abbreviated, time: .shortened))
                                            .font(.system(size: 10, design: .rounded))
                                            .foregroundColor(.sbTextSecondary)
                                    }
                                    Spacer()
                                    Text(item.quantityIn > 0 ? "+\(Int(item.quantityIn))" : "-\(Int(item.quantityOut))")
                                        .font(SBFont.mono(13))
                                        .foregroundColor(item.quantityIn > 0 ? .sbAccentGreen : .sbAccentRed)
                                }
                            }
                        }
                        .modifier(SBCardModifier())
                    }
                    Spacer().frame(height: 80)
                }
                .padding(16)
            }
        }
        .navigationTitle("Inventory")
    }
}

struct InventorySummaryItem: View {
    let value: String
    let label: String
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            Text(value).font(.system(size: 22, weight: .black, design: .rounded)).foregroundColor(color)
            Text(label).font(.system(size: 10, design: .rounded)).foregroundColor(.sbTextSecondary)
        }
        .frame(maxWidth: .infinity)
    }
}

struct InventoryItemRow: View {
    let material: SBMaterial
    @Environment(\.colorScheme) var scheme

    var fillRatio: Double {
        guard material.minQuantity > 0 else { return 0.8 }
        return min(material.quantity / (material.minQuantity * 4), 1.0)
    }

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: "shippingbox.fill")
                .font(.system(size: 18))
                .foregroundColor(material.isLowStock ? .sbAccentRed : .sbAccentGreen)
                .frame(width: 36, height: 36)
                .background((material.isLowStock ? Color.sbAccentRed : Color.sbAccentGreen).opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 8))

            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(material.name).font(SBFont.caption(13))
                    if material.isLowStock {
                        SBBadge(text: "Low", color: .sbAccentYellow)
                    }
                }
                GeometryReader { g in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 3).fill(Color.sbBorder).frame(height: 4)
                        RoundedRectangle(cornerRadius: 3)
                            .fill(material.isLowStock ? Color.sbAccentRed : Color.sbAccentGreen)
                            .frame(width: g.size.width * fillRatio, height: 4)
                    }
                }
                .frame(height: 4)
            }

            Text("\(Int(material.quantity)) \(material.unit)")
                .font(SBFont.mono(12))
                .foregroundColor(.sbTextSecondary)
                .frame(width: 70, alignment: .trailing)
        }
        .padding(12)
        .background(scheme == .dark ? Color.sbDarkSurface : .white)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.04), radius: 5, y: 2)
    }
}
