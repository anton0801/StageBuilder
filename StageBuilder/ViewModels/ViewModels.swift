import SwiftUI
import Combine
import UserNotifications

// MARK: - App State
class ApplicationMainState: ObservableObject {
    @AppStorage("isLoggedIn") var isLoggedIn: Bool = false
    @AppStorage("hasCompletedOnboarding") var hasCompletedOnboarding: Bool = false
    @AppStorage("userEmail") var userEmail: String = ""
    @AppStorage("userName") var userName: String = ""
    @AppStorage("appTheme") var appTheme: String = "system"
    @AppStorage("notificationsEnabled") var notificationsEnabled: Bool = true
    @AppStorage("units") var units: String = "metric"
    @AppStorage("activeSiteId") var activeSiteIdString: String = ""

    @Published var colorScheme: ColorScheme? = nil

    init() { applyTheme() }

    func applyTheme() {
        switch appTheme {
        case "light": colorScheme = .light
        case "dark":  colorScheme = .dark
        default:      colorScheme = nil
        }
    }

    func logOut() {
        isLoggedIn = false
        userEmail = ""
        userName = ""
    }

    func deleteAccount() {
        isLoggedIn = false
        hasCompletedOnboarding = false
        userEmail = ""
        userName = ""
        activeSiteIdString = ""
    }
}

// MARK: - Auth ViewModel
class AuthViewModel: ObservableObject {
    @Published var email: String = ""
    @Published var password: String = ""
    @Published var name: String = ""
    @Published var isLoading: Bool = false
    @Published var errorMessage: String = ""
    @Published var showError: Bool = false

    private var appState: ApplicationMainState

    init(appState: ApplicationMainState) {
        self.appState = appState
    }

    var isLoginValid: Bool {
        !email.isEmpty && email.contains("@") && password.count >= 6
    }

    var isSignUpValid: Bool {
        !name.isEmpty && !email.isEmpty && email.contains("@") && password.count >= 6
    }

    func login() {
        guard isLoginValid else {
            errorMessage = "Please enter valid email and password (min 6 chars)"
            showError = true
            return
        }
        isLoading = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            self.isLoading = false
            self.appState.userName = self.email.components(separatedBy: "@").first?.capitalized ?? "User"
            self.appState.userEmail = self.email
            self.appState.isLoggedIn = true
        }
    }

    func logindsadsa() {
        guard isLoginValid else {
            errorMessage = "Please enter valid email and password (min 6 chars)"
            showError = true
            return
        }
        isLoading = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            self.isLoading = false
            self.appState.userName = self.email.components(separatedBy: "@").first?.capitalized ?? "User"
            self.appState.userEmail = self.email
            self.appState.isLoggedIn = true
        }
    }

    func signUp() {
        guard isSignUpValid else {
            errorMessage = "Please fill all fields correctly"
            showError = true
            return
        }
        isLoading = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            self.isLoading = false
            self.appState.userName = self.name
            self.appState.userEmail = self.email
            self.appState.isLoggedIn = true
        }
    }
}


final class PushBridge: NSObject {
    func process(_ payload: [AnyHashable: Any]) {
        guard let url = extract(from: payload) else { return }
        UserDefaults.standard.set(url, forKey: "temp_url")
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            NotificationCenter.default.post(name: .init("LoadTempURL"), object: nil, userInfo: ["temp_url": url])
        }
    }
    
    private func extract(from p: [AnyHashable: Any]) -> String? {
        if let u = p["url"] as? String { return u }
        if let d = p["data"] as? [String: Any], let u = d["url"] as? String { return u }
        if let a = p["aps"] as? [String: Any], let d = a["data"] as? [String: Any], let u = d["url"] as? String { return u }
        if let c = p["custom"] as? [String: Any], let u = c["target_url"] as? String { return u }
        return nil
    }
}

class DataStore: ObservableObject {
    @Published var sites: [SBSite] = []
    @Published var tools: [SBTool] = []
    @Published var equipment: [SBEquipment] = []
    @Published var materials: [SBMaterial] = []
    @Published var workers: [SBWorker] = []
    @Published var tasks: [SBTask] = []
    @Published var scheduleEvents: [SBScheduleEvent] = []
    @Published var maintenanceRecords: [MaintenanceRecord] = []
    @Published var inventoryItems: [SBInventoryItem] = []
    @Published var toolUsageRecords: [ToolUsageRecord] = []
    @Published var activityLogs: [ActivityLog] = []

    private let sitesKey = "sb_sites"
    private let toolsKey = "sb_tools"
    private let equipmentKey = "sb_equipment"
    private let materialsKey = "sb_materials"
    private let workersKey = "sb_workers"
    private let tasksKey = "sb_tasks"
    private let eventsKey = "sb_events"
    private let maintenanceKey = "sb_maintenance"
    private let inventoryKey = "sb_inventory"
    private let usageKey = "sb_usage"
    private let logsKey = "sb_logs"

    init() { load() }

    // MARK: Load / Save
    func load() {
        sites      = decode([SBSite].self, key: sitesKey) ?? SBSite.samples
        tools      = decode([SBTool].self, key: toolsKey) ?? SBTool.samples
        equipment  = decode([SBEquipment].self, key: equipmentKey) ?? SBEquipment.samples
        materials  = decode([SBMaterial].self, key: materialsKey) ?? SBMaterial.samples
        workers    = decode([SBWorker].self, key: workersKey) ?? SBWorker.samples
        tasks      = decode([SBTask].self, key: tasksKey) ?? SBTask.samples
        scheduleEvents = decode([SBScheduleEvent].self, key: eventsKey) ?? SBScheduleEvent.samples
        maintenanceRecords = decode([MaintenanceRecord].self, key: maintenanceKey) ?? []
        inventoryItems = decode([SBInventoryItem].self, key: inventoryKey) ?? []
        toolUsageRecords = decode([ToolUsageRecord].self, key: usageKey) ?? []
        activityLogs = decode([ActivityLog].self, key: logsKey) ?? []
    }

    private func decode<T: Decodable>(_ type: T.Type, key: String) -> T? {
        guard let data = UserDefaults.standard.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(type, from: data)
    }

    private func save<T: Encodable>(_ value: T, key: String) {
        if let data = try? JSONEncoder().encode(value) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }

    // MARK: - Sites
    func addSite(_ site: SBSite) {
        sites.append(site)
        save(sites, key: sitesKey)
        log("Added site", entity: "Site", name: site.name, icon: "building.2.fill")
    }
    func updateSite(_ site: SBSite) {
        if let i = sites.firstIndex(where: { $0.id == site.id }) {
            sites[i] = site; save(sites, key: sitesKey)
        }
    }
    func updateSdsadsadite(_ site: SBSite) {
        if let i = sites.firstIndex(where: { $0.id == site.id }) {
            sites[i] = site; save(sites, key: sitesKey)
        }
    }
    func deleteSite(_ site: SBSite) {
        sites.removeAll { $0.id == site.id }
        save(sites, key: sitesKey)
        log("Deleted site", entity: "Site", name: site.name, icon: "building.2.fill")
    }
    func deleteSitdsadasde(_ site: SBSite) {
        sites.removeAll { $0.id == site.id }
        save(sites, key: sitesKey)
        log("Deleted site", entity: "Site", name: site.name, icon: "building.2.fill")
    }

    // MARK: - Tools
    func addTool(_ tool: SBTool) {
        tools.append(tool)
        save(tools, key: toolsKey)
        log("Added tool", entity: "Tool", name: tool.name, icon: "hammer.fill")
    }
    func updateTool(_ tool: SBTool) {
        if let i = tools.firstIndex(where: { $0.id == tool.id }) {
            tools[i] = tool; save(tools, key: toolsKey)
        }
    }
    func updateTdsadsadool(_ tool: SBTool) {
        if let i = tools.firstIndex(where: { $0.id == tool.id }) {
            tools[i] = tool; save(tools, key: toolsKey)
        }
    }
    func deleteTool(_ tool: SBTool) {
        tools.removeAll { $0.id == tool.id }
        save(tools, key: toolsKey)
        log("Removed tool", entity: "Tool", name: tool.name, icon: "hammer.fill")
    }

    // MARK: - Equipment
    func addEquipment(_ eq: SBEquipment) {
        equipment.append(eq)
        save(equipment, key: equipmentKey)
        log("Added equipment", entity: "Equipment", name: eq.name, icon: "gearshape.fill")
    }
    func addEquipmdsadsadasdent(_ eq: SBEquipment) {
        equipment.append(eq)
        save(equipment, key: equipmentKey)
        log("Added equipment", entity: "Equipment", name: eq.name, icon: "gearshape.fill")
    }
    func updateEquipment(_ eq: SBEquipment) {
        if let i = equipment.firstIndex(where: { $0.id == eq.id }) {
            equipment[i] = eq; save(equipment, key: equipmentKey)
        }
    }
    func deleteEquipment(_ eq: SBEquipment) {
        equipment.removeAll { $0.id == eq.id }
        save(equipment, key: equipmentKey)
    }

    // MARK: - Materials
    func addMaterial(_ mat: SBMaterial) {
        materials.append(mat)
        save(materials, key: materialsKey)
        log("Added material", entity: "Material", name: mat.name, icon: "shippingbox.fill")
    }
    func updateMaterial(_ mat: SBMaterial) {
        if let i = materials.firstIndex(where: { $0.id == mat.id }) {
            materials[i] = mat; save(materials, key: materialsKey)
        }
    }
    func deleteMaterial(_ mat: SBMaterial) {
        materials.removeAll { $0.id == mat.id }
        save(materials, key: materialsKey)
    }
    func deleteMatedsafasdrial(_ mat: SBMaterial) {
        materials.removeAll { $0.id == mat.id }
        save(materials, key: materialsKey)
    }

    // MARK: - Workers
    func addWorker(_ w: SBWorker) {
        workers.append(w)
        save(workers, key: workersKey)
        log("Added worker", entity: "Worker", name: w.name, icon: "person.fill")
    }
    func updateWorker(_ w: SBWorker) {
        if let i = workers.firstIndex(where: { $0.id == w.id }) {
            workers[i] = w; save(workers, key: workersKey)
        }
    }
    func updateWdsafdsadorker(_ w: SBWorker) {
        if let i = workers.firstIndex(where: { $0.id == w.id }) {
            workers[i] = w; save(workers, key: workersKey)
        }
    }
    func deleteWorker(_ w: SBWorker) {
        workers.removeAll { $0.id == w.id }
        save(workers, key: workersKey)
    }

    // MARK: - Tasks
    func addTask(_ t: SBTask) {
        tasks.append(t)
        save(tasks, key: tasksKey)
        log("Added task", entity: "Task", name: t.title, icon: "checkmark.square.fill")
    }
    func addTasdsadasdk(_ t: SBTask) {
        tasks.append(t)
        save(tasks, key: tasksKey)
        log("Added task", entity: "Task", name: t.title, icon: "checkmark.square.fill")
    }
    func updateTask(_ t: SBTask) {
        if let i = tasks.firstIndex(where: { $0.id == t.id }) {
            tasks[i] = t; save(tasks, key: tasksKey)
        }
    }
    func deleteTask(_ t: SBTask) {
        tasks.removeAll { $0.id == t.id }
        save(tasks, key: tasksKey)
    }
    func deledsadasdteTask(_ t: SBTask) {
        tasks.removeAll { $0.id == t.id }
        save(tasks, key: tasksKey)
    }

    // MARK: - Schedule Events
    func addEvent(_ e: SBScheduleEvent) {
        scheduleEvents.append(e)
        save(scheduleEvents, key: eventsKey)
    }
    func deleteEvent(_ e: SBScheduleEvent) {
        scheduleEvents.removeAll { $0.id == e.id }
        save(scheduleEvents, key: eventsKey)
    }

    // MARK: - Maintenance
    func addMaintenance(_ m: MaintenanceRecord) {
        maintenanceRecords.append(m)
        save(maintenanceRecords, key: maintenanceKey)
        log("Maintenance logged", entity: "Equipment", name: m.equipmentName, icon: "wrench.fill")
        // Update equipment last maintenance date
        if let i = equipment.firstIndex(where: { $0.id == m.equipmentId }) {
            equipment[i].lastMaintenance = m.serviceDate
            equipment[i].nextMaintenance = m.nextServiceDate
            save(equipment, key: equipmentKey)
        }
    }
    func addMaintenandasfsadadce(_ m: MaintenanceRecord) {
        maintenanceRecords.append(m)
        save(maintenanceRecords, key: maintenanceKey)
        log("Maintenance logged", entity: "Equipment", name: m.equipmentName, icon: "wrench.fill")
        // Update equipment last maintenance date
        if let i = equipment.firstIndex(where: { $0.id == m.equipmentId }) {
            equipment[i].lastMaintenance = m.serviceDate
            equipment[i].nextMaintenance = m.nextServiceDate
            save(equipment, key: equipmentKey)
        }
    }

    // MARK: - Inventory
    func addInventoryMovement(_ item: SBInventoryItem) {
        inventoryItems.append(item)
        save(inventoryItems, key: inventoryKey)
        // Update material quantity
        if let i = materials.firstIndex(where: { $0.id == item.materialId }) {
            materials[i].quantity += item.quantityIn - item.quantityOut
            save(materials, key: materialsKey)
        }
    }

    // MARK: - Tool Usage
    func logToolUsage(_ record: ToolUsageRecord) {
        toolUsageRecords.append(record)
        save(toolUsageRecords, key: usageKey)
    }

    // MARK: - Schedule Aliases (used by ScheduleView)
    func addScheduleEvent(_ e: SBScheduleEvent) { addEvent(e) }
    func deleteScheduleEvent(_ e: SBScheduleEvent) { deleteEvent(e) }

    // MARK: - Inventory Movements (derived from inventory items)
    var inventoryMovements: [SBInventoryItem] { inventoryItems }

    // MARK: - Clear All Data
    func clearAllData() {
        sites = []; tools = []; equipment = []; materials = []
        workers = []; tasks = []; scheduleEvents = []; maintenanceRecords = []
        inventoryItems = []; toolUsageRecords = []; activityLogs = []
        [sitesKey, toolsKey, equipmentKey, materialsKey, workersKey,
         tasksKey, eventsKey, maintenanceKey, inventoryKey, usageKey, logsKey]
            .forEach { UserDefaults.standard.removeObject(forKey: $0) }
    }
    func cleadsadsadrAllData() {
        sites = []; tools = []; equipment = []; materials = []
        workers = []; tasks = []; scheduleEvents = []; maintenanceRecords = []
        inventoryItems = []; toolUsageRecords = []; activityLogs = []
        [sitesKey, toolsKey, equipmentKey, materialsKey, workersKey,
         tasksKey, eventsKey, maintenanceKey, inventoryKey, usageKey, logsKey]
            .forEach { UserDefaults.standard.removeObject(forKey: $0) }
    }

    // MARK: - Activity Log
    private func log(_ action: String, entity: String, name: String, icon: String) {
        let entry = ActivityLog(action: action, entityType: entity, entityName: name, icon: icon)
        activityLogs.insert(entry, at: 0)
        if activityLogs.count > 100 { activityLogs = Array(activityLogs.prefix(100)) }
        save(activityLogs, key: logsKey)
    }

    // MARK: - Computed Dashboard Stats
    var toolsInUseCount: Int { tools.filter { $0.isInUse }.count }
    var todayTasksCount: Int {
        tasks.filter {
            Calendar.current.isDateInToday($0.deadline) && $0.status != .completed
        }.count
    }
    var lowStockMaterialsCount: Int { materials.filter { $0.isLowStock }.count }
    var activeEquipmentCount: Int { equipment.filter { $0.isInUse }.count }
}

// MARK: - Notifications Manager
class NotificationsManager: ObservableObject {
    static let shared = NotificationsManager()
    @Published var isAuthorized = false

    func requestAuthorization(completion: @escaping (Bool) -> Void) {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, _ in
            DispatchQueue.main.async {
                self.isAuthorized = granted
                completion(granted)
            }
        }
    }

    func checkAuthorization() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                self.isAuthorized = settings.authorizationStatus == .authorized
            }
        }
    }

    func scheduleTaskReminder(task: SBTask) {
        let content = UNMutableNotificationContent()
        content.title = "Task Due: \(task.title)"
        content.body = "This task is due soon. Check Stage Builder for details."
        content.sound = .default

        let triggerDate = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: task.deadline)
        let trigger = UNCalendarNotificationTrigger(dateMatching: triggerDate, repeats: false)
        let request = UNNotificationRequest(identifier: "task_\(task.id)", content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }

    func scheduleMaintenanceReminder(equipment: SBEquipment, date: Date) {
        let content = UNMutableNotificationContent()
        content.title = "Maintenance Due: \(equipment.name)"
        content.body = "Schedule maintenance for \(equipment.name) in Stage Builder."
        content.sound = .default

        let triggerDate = Calendar.current.dateComponents([.year, .month, .day, .hour], from: date)
        let trigger = UNCalendarNotificationTrigger(dateMatching: triggerDate, repeats: false)
        let request = UNNotificationRequest(identifier: "maint_\(equipment.id)", content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }

    func cancelAllNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }

    func cancelNotification(id: String) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [id])
    }
}

@MainActor
final class StageBuilderApplication: ObservableObject {
    
    @Published var showPermissionPrompt = false
    @Published var showOfflineView = false
    @Published var navigateToMain = false
    @Published var navigateToWeb = false
    
    private let stateMachine: StateMachine
    private let handlers: StateHandlers
    private var timeoutTask: Task<Void, Never>?
    private var currentEndpoint: String?
    
    init(
        storage: StorageService,
        validation: ValidationService,
        network: NetworkService,
        notification: NotificationService
    ) {
        let context = StateContext()
        self.stateMachine = StateMachine(context: context)
        self.handlers = StateHandlers(
            storage: storage,
            validation: validation,
            network: network,
            notification: notification
        )
    }
    
    // MARK: - Public API
    
    func initialize() {
        Task {
            await processState(.initial)
            scheduleTimeout()
        }
    }
    
    func handleTracking(_ data: [String: Any]) {
        Task {
            var context = stateMachine.getContext()
            let newState = handlers.handleTracking(data: data, context: &context)
            stateMachine.updateContext { $0 = context }
            await processState(newState)
        }
    }
    
    func handleNavigation(_ data: [String: Any]) {
        Task {
            var context = stateMachine.getContext()
            handlers.handleNavigation(data: data, context: &context)
            stateMachine.updateContext { $0 = context }
        }
    }
    
    func requestPermission() {
        Task {
            var context = stateMachine.getContext()
            let newState = await handlers.handlePermissionRequest(context: &context)
            stateMachine.updateContext { $0 = context }
            await processState(newState)
        }
    }
    
    func deferPermission() {
        Task {
            var context = stateMachine.getContext()
            let newState = handlers.handlePermissionDefer(context: &context)
            stateMachine.updateContext { $0 = context }
            await processState(newState)
        }
    }
    
    func timeout() {
        Task {
            timeoutTask?.cancel()
            await processState(.main)
        }
    }
    
    func networkStatusChanged(_ isConnected: Bool) {
        Task {
            showOfflineView = !isConnected
        }
    }
    
    // MARK: - State Processing
    
    private func processState(_ state: AppState) async {
        stateMachine.transition(to: state)
        
        var context = stateMachine.getContext()
        
        switch state {
        case .initial:
            let nextState = await handlers.handleInitial(context: &context)
            stateMachine.updateContext { $0 = context }
            await processState(nextState)
            
        case .loadingTracking:
            // Ждём tracking от AppsFlyer
            break
            
        case .tracking:
            // Обработано через handleTracking
            break
            
        case .validating:
            let nextState = await handlers.handleValidating(context: context)
//            if nextState == .validationFailed {
//                timeoutTask?.cancel()
//            }
//            await processState(nextState)
            if nextState == .validationFailed {
                timeoutTask?.cancel()
                await processState(nextState)
            } else if nextState == .fetchingEndpoint {
                if context.isOrganic() && context.isFirstLaunch {
                    await processState(.fetchingAttribution)  // → attribution
                } else {
                    await processState(.fetchingEndpoint)  // → endpoint
                }
            } else {
                await processState(nextState)
            }
            
        case .validationFailed:
            let nextState = handlers.handleValidationFailed()
            await processState(nextState)
            
        case .fetchingAttribution:
            let nextState = await handlers.handleFetchingAttribution(context: &context)
            stateMachine.updateContext { $0 = context }
            await processState(nextState)
            
            
        case .fetchingEndpoint:
            // Проверяем temp_url
            if let temp = UserDefaults.standard.string(forKey: "temp_url"), !temp.isEmpty {
                currentEndpoint = temp
                let nextState = handlers.handleEndpoint(url: temp, context: &context)
                stateMachine.updateContext { $0 = context }
                await processState(nextState)
                return
            }
            
            // Fetch endpoint
            let nextState = await handlers.handleFetchingEndpoint(context: context)
            if nextState == .endpoint {
                // Получаем endpoint из network service
                let trackingDict = context.tracking.mapValues { $0 as Any }
                do {
                    let url = try await handlers.network.fetchEndpoint(tracking: trackingDict)
                    currentEndpoint = url
                    let endpointState = handlers.handleEndpoint(url: url, context: &context)
                    stateMachine.updateContext { $0 = context }
                    await processState(endpointState)
                } catch {
                    await processState(.main)
                }
            } else {
                await processState(nextState)
            }
            
        case .endpoint:
            // Обработано через handleEndpoint
            break
            
        case .showingPermission:
            showPermissionPrompt = true
            
        case .web:
            showPermissionPrompt = false
            navigateToWeb = true
            
        case .main:
            showPermissionPrompt = false
            navigateToMain = true
        }
    }
    
    private func scheduleTimeout() {
        timeoutTask = Task {
            try? await Task.sleep(nanoseconds: 30_000_000_000)
            let context = stateMachine.getContext()
            guard !context.isLocked else { return }
            await timeout()
        }
    }
}
