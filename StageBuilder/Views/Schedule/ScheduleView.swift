import SwiftUI

// MARK: - Schedule View
struct ScheduleView: View {
    @EnvironmentObject var dataStore: DataStore
    @EnvironmentObject var appState: AppState
    @State private var selectedTab: ScheduleTab = .list
    @State private var showAddEvent = false
    @State private var searchText = ""
    @Environment(\.colorScheme) var scheme

    enum ScheduleTab: String, CaseIterable {
        case list = "List"
        case calendar = "Calendar"
    }

    var filteredEvents: [SBScheduleEvent] {
        let sorted = dataStore.scheduleEvents.sorted { $0.date < $1.date }
        if searchText.isEmpty { return sorted }
        return sorted.filter {
            $0.title.localizedCaseInsensitiveContains(searchText) ||
            $0.notes.localizedCaseInsensitiveContains(searchText)
        }
    }

    var upcomingEvents: [SBScheduleEvent] {
        filteredEvents.filter { $0.date >= Calendar.current.startOfDay(for: Date()) }
    }

    var pastEvents: [SBScheduleEvent] {
        filteredEvents.filter { $0.date < Calendar.current.startOfDay(for: Date()) }
    }

    var body: some View {
        NavigationView {
            ZStack {
                (scheme == .dark ? Color.sbDarkBG : Color(.systemGroupedBackground))
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    Picker("", selection: $selectedTab) {
                        ForEach(ScheduleTab.allCases, id: \.self) { tab in
                            Text(tab.rawValue).tag(tab)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)

                    if selectedTab == .list {
                        listView
                    } else {
                        CalendarView()
                            .environmentObject(dataStore)
                    }
                }
            }
            .navigationTitle("Schedule")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button { showAddEvent = true } label: {
                        Image(systemName: "plus")
                            .foregroundColor(.sbPrimary)
                            .fontWeight(.semibold)
                    }
                }
            }
            .sheet(isPresented: $showAddEvent) {
                AddEventView()
                    .environmentObject(dataStore)
                    .environmentObject(appState)
            }
        }
    }

    var listView: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                HStack {
                    Image(systemName: "magnifyingglass").foregroundColor(.secondary)
                    TextField("Search events...", text: $searchText)
                }
                .padding(10)
                .background(scheme == .dark ? Color.sbDarkSurface : .white)
                .cornerRadius(10)
                .padding(.horizontal, 16)
                .padding(.bottom, 16)

                if upcomingEvents.isEmpty && pastEvents.isEmpty {
                    SBEmptyState(
                        icon: "calendar",
                        title: "No Events",
                        subtitle: "Schedule your first work event by tapping the + button."
                    )
                    .padding(.top, 60)
                } else {
                    if !upcomingEvents.isEmpty {
                        sectionHeader("Upcoming")
                        ForEach(upcomingEvents) { event in
                            EventRow(event: event)
                                .padding(.horizontal, 16)
                                .padding(.bottom, 8)
                        }
                    }
                    if !pastEvents.isEmpty {
                        sectionHeader("Past")
                        ForEach(pastEvents) { event in
                            EventRow(event: event, isPast: true)
                                .padding(.horizontal, 16)
                                .padding(.bottom, 8)
                        }
                    }
                }
                Spacer().frame(height: 80)
            }
        }
    }

    func sectionHeader(_ title: String) -> some View {
        HStack {
            Text(title)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.secondary)
                .textCase(.uppercase)
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 6)
        .padding(.top, 4)
    }
}

// MARK: - Event Row
struct EventRow: View {
    @EnvironmentObject var dataStore: DataStore
    let event: SBScheduleEvent
    var isPast: Bool = false
    @State private var showDelete = false
    @Environment(\.colorScheme) var scheme

    var duration: String? {
        guard let end = event.endDate else { return nil }
        let secs = end.timeIntervalSince(event.date)
        let hours = Int(secs / 3600)
        let mins = Int((secs.truncatingRemainder(dividingBy: 3600)) / 60)
        if hours > 0 && mins > 0 { return "\(hours)h \(mins)m" }
        if hours > 0 { return "\(hours)h" }
        return "\(mins)m"
    }

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(event.type.color.opacity(0.15))
                    .frame(width: 44, height: 44)
                Image(systemName: event.type.icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(event.type.color)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(event.title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(isPast ? .secondary : (scheme == .dark ? .white : .sbDarkBG))
                    .lineLimit(1)

                if !event.notes.isEmpty {
                    Text(event.notes)
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }

                HStack(spacing: 6) {
                    Image(systemName: "clock")
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                    Text(event.date.formatted(date: .abbreviated, time: .shortened))
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                    if let site = dataStore.sites.first(where: { $0.id == event.siteId }) {
                        Text("·").foregroundColor(.secondary)
                        Text(site.name)
                            .font(.system(size: 12))
                            .foregroundColor(.sbPrimary)
                            .lineLimit(1)
                    }
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                SBBadge(text: event.type.rawValue, color: event.type.color)
                if let dur = duration {
                    Text(dur)
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(14)
        .background(scheme == .dark ? Color.sbDarkSurface : .white)
        .cornerRadius(12)
        .opacity(isPast ? 0.7 : 1.0)
        .alert("Delete Event", isPresented: $showDelete) {
            Button("Delete", role: .destructive) {
                withAnimation { dataStore.deleteEvent(event) }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Remove \"\(event.title)\" from schedule?")
        }
        .contextMenu {
            Button(role: .destructive) { showDelete = true } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }
}

// MARK: - Calendar View
struct CalendarView: View {
    @EnvironmentObject var dataStore: DataStore
    @State private var currentMonth = Date()
    @State private var selectedDate: Date? = nil
    @Environment(\.colorScheme) var scheme

    var eventsForSelectedDate: [SBScheduleEvent] {
        guard let selected = selectedDate else { return [] }
        return dataStore.scheduleEvents.filter {
            Calendar.current.isDate($0.date, inSameDayAs: selected)
        }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                HStack {
                    Button {
                        currentMonth = Calendar.current.date(byAdding: .month, value: -1, to: currentMonth) ?? currentMonth
                    } label: {
                        Image(systemName: "chevron.left").foregroundColor(.sbPrimary).fontWeight(.semibold).padding(8)
                    }
                    Spacer()
                    Text(currentMonth.formatted(.dateTime.year().month(.wide)))
                        .font(.system(size: 18, weight: .bold))
                    Spacer()
                    Button {
                        currentMonth = Calendar.current.date(byAdding: .month, value: 1, to: currentMonth) ?? currentMonth
                    } label: {
                        Image(systemName: "chevron.right").foregroundColor(.sbPrimary).fontWeight(.semibold).padding(8)
                    }
                }
                .padding(.horizontal, 16)

                HStack(spacing: 0) {
                    ForEach(["Sun","Mon","Tue","Wed","Thu","Fri","Sat"], id: \.self) { d in
                        Text(d).font(.system(size: 12, weight: .medium)).foregroundColor(.secondary).frame(maxWidth: .infinity)
                    }
                }
                .padding(.horizontal, 8)

                let days = generateDays()
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 0), count: 7), spacing: 4) {
                    ForEach(days, id: \.self) { date in
                        DayCell(
                            date: date,
                            currentMonth: currentMonth,
                            isSelected: selectedDate.map { Calendar.current.isDate($0, inSameDayAs: date) } ?? false,
                            hasEvents: dataStore.scheduleEvents.contains { Calendar.current.isDate($0.date, inSameDayAs: date) }
                        )
                        .onTapGesture {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                if let sel = selectedDate, Calendar.current.isDate(sel, inSameDayAs: date) {
                                    selectedDate = nil
                                } else {
                                    selectedDate = date
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal, 8)

                if let selected = selectedDate {
                    VStack(alignment: .leading, spacing: 10) {
                        Text(selected.formatted(.dateTime.weekday(.wide).month().day()))
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 16)

                        if eventsForSelectedDate.isEmpty {
                            Text("No events on this day")
                                .font(.system(size: 14))
                                .foregroundColor(.secondary)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                        } else {
                            ForEach(eventsForSelectedDate) { event in
                                EventRow(event: event)
                                    .padding(.horizontal, 16)
                                    .environmentObject(dataStore)
                            }
                        }
                    }
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }

                Spacer().frame(height: 80)
            }
        }
    }

    func generateDays() -> [Date] {
        var calendar = Calendar.current
        calendar.firstWeekday = 1
        let components = calendar.dateComponents([.year, .month], from: currentMonth)
        guard let firstDay = calendar.date(from: components) else { return [] }
        let weekday = calendar.component(.weekday, from: firstDay)
        let offset = weekday - 1
        var days: [Date] = []
        for i in stride(from: -offset, to: 42 - offset, by: 1) {
            if let date = calendar.date(byAdding: .day, value: i, to: firstDay) {
                days.append(date)
            }
        }
        return days
    }
}

// MARK: - Day Cell
struct DayCell: View {
    let date: Date
    let currentMonth: Date
    let isSelected: Bool
    let hasEvents: Bool
    @Environment(\.colorScheme) var scheme

    var isToday: Bool { Calendar.current.isDateInToday(date) }
    var isCurrentMonth: Bool { Calendar.current.isDate(date, equalTo: currentMonth, toGranularity: .month) }

    var body: some View {
        VStack(spacing: 4) {
            ZStack {
                if isSelected {
                    Circle().fill(Color.sbPrimary).frame(width: 34, height: 34)
                } else if isToday {
                    Circle().stroke(Color.sbPrimary, lineWidth: 1.5).frame(width: 34, height: 34)
                }
                Text("\(Calendar.current.component(.day, from: date))")
                    .font(.system(size: 14, weight: isToday || isSelected ? .bold : .regular))
                    .foregroundColor(
                        isSelected ? .white :
                        isCurrentMonth ? (scheme == .dark ? .white : .sbDarkBG) :
                        .secondary.opacity(0.4)
                    )
            }
            .frame(width: 34, height: 34)

            Circle()
                .fill(hasEvents && isCurrentMonth ? (isSelected ? .white : Color.sbPrimary) : Color.clear)
                .frame(width: 5, height: 5)
        }
        .frame(height: 48)
    }
}

// MARK: - Add Event View
struct AddEventView: View {
    @EnvironmentObject var dataStore: DataStore
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var scheme

    @State private var title = ""
    @State private var notes = ""
    @State private var date = Date()
    @State private var hasEndDate = false
    @State private var endDate = Date().addingTimeInterval(3600)
    @State private var selectedType: SBScheduleEvent.EventType = .task
    @State private var selectedSiteId: UUID? = nil
    @State private var showValidation = false

    var body: some View {
        NavigationView {
            ZStack {
                (scheme == .dark ? Color.sbDarkBG : Color(.systemGroupedBackground))
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Event Details")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(.secondary)
                                .textCase(.uppercase)
                            SBTextField(placeholder: "Event title", text: $title, icon: "calendar")
                            SBTextField(placeholder: "Notes (optional)", text: $notes, icon: "text.alignleft")
                        }
                        .padding(.horizontal, 16)

                        VStack(alignment: .leading, spacing: 10) {
                            Text("Event Type")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(.secondary)
                                .textCase(.uppercase)
                                .padding(.horizontal, 16)

                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 10) {
                                    ForEach(SBScheduleEvent.EventType.allCases, id: \.self) { type in
                                        Button {
                                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                                selectedType = type
                                            }
                                        } label: {
                                            HStack(spacing: 6) {
                                                Image(systemName: type.icon).font(.system(size: 13))
                                                Text(type.rawValue).font(.system(size: 13, weight: .semibold))
                                            }
                                            .padding(.horizontal, 14)
                                            .padding(.vertical, 8)
                                            .background(selectedType == type ? type.color : (scheme == .dark ? Color.sbDarkSurface : Color.white))
                                            .foregroundColor(selectedType == type ? Color.white : Color.primary)
                                            .cornerRadius(20)
                                        }
                                    }
                                }
                                .padding(.horizontal, 16)
                            }
                        }

                        VStack(alignment: .leading, spacing: 12) {
                            Text("Timing")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(.secondary)
                                .textCase(.uppercase)

                            DatePicker("Start", selection: $date, displayedComponents: [.date, .hourAndMinute])
                                .padding(14)
                                .background(scheme == .dark ? Color.sbDarkSurface : Color.white)
                                .cornerRadius(12)

                            Toggle(isOn: $hasEndDate) {
                                Label("Add End Time", systemImage: "clock.badge.checkmark").font(.system(size: 15))
                            }
                            .tint(.sbPrimary)
                            .padding(14)
                            .background(scheme == .dark ? Color.sbDarkSurface : Color.white)
                            .cornerRadius(12)

                            if hasEndDate {
                                DatePicker("End", selection: $endDate, in: date..., displayedComponents: [.date, .hourAndMinute])
                                    .padding(14)
                                    .background(scheme == .dark ? Color.sbDarkSurface : Color.white)
                                    .cornerRadius(12)
                                    .transition(.opacity.combined(with: .move(edge: .top)))
                            }
                        }
                        .padding(.horizontal, 16)

                        if !dataStore.sites.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Site (Optional)")
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundColor(.secondary)
                                    .textCase(.uppercase)

                                VStack(spacing: 8) {
                                    siteOptionRow(name: "No specific site", subtitle: nil, id: nil)
                                    ForEach(dataStore.sites) { site in
                                        siteOptionRow(name: site.name, subtitle: site.address, id: site.id)
                                    }
                                }
                            }
                            .padding(.horizontal, 16)
                        }

                        if showValidation && title.trimmingCharacters(in: .whitespaces).isEmpty {
                            Text("Please enter an event title.")
                                .font(.system(size: 13))
                                .foregroundColor(.sbRed)
                                .padding(.horizontal, 16)
                        }

                        SBPrimaryButton("Schedule Event", icon: "calendar.badge.plus", action: {
                            let t = title.trimmingCharacters(in: .whitespaces)
                            guard !t.isEmpty else { showValidation = true; return }
                            let event = SBScheduleEvent(
                                title: t,
                                date: date,
                                endDate: hasEndDate ? endDate : nil,
                                type: selectedType,
                                siteId: selectedSiteId,
                                notes: notes.trimmingCharacters(in: .whitespaces)
                            )
                            dataStore.addEvent(event)
                            dismiss()
                        })
                        .padding(.horizontal, 16)

                        Spacer().frame(height: 40)
                    }
                    .padding(.top, 20)
                }
            }
            .navigationTitle("New Event")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }.foregroundColor(.sbPrimary)
                }
            }
        }
    }

    func siteOptionRow(name: String, subtitle: String?, id: UUID?) -> some View {
        Button {
            withAnimation { selectedSiteId = id }
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(name).font(.system(size: 15, weight: .medium)).foregroundColor(.primary)
                    if let sub = subtitle {
                        Text(sub).font(.system(size: 12)).foregroundColor(.secondary)
                    }
                }
                Spacer()
                if selectedSiteId == id {
                    Image(systemName: "checkmark").foregroundColor(.sbPrimary)
                }
            }
            .padding(14)
            .background(scheme == .dark ? Color.sbDarkSurface : .white)
            .cornerRadius(12)
        }
    }
}
