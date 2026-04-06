import SwiftUI
import Combine

// MARK: - Enums

enum ToolCondition: String, CaseIterable, Codable {
    case excellent = "Excellent"
    case good = "Good"
    case fair = "Fair"
    case needsRepair = "Needs Repair"
    case outOfService = "Out of Service"

    var color: Color {
        switch self {
        case .excellent: return .sbAccentGreen
        case .good: return Color(hex: "#52C41A")
        case .fair: return .sbAccentYellow
        case .needsRepair: return .sbPrimary
        case .outOfService: return .sbAccentRed
        }
    }

    var icon: String {
        switch self {
        case .excellent: return "checkmark.seal.fill"
        case .good: return "checkmark.circle.fill"
        case .fair: return "exclamationmark.circle.fill"
        case .needsRepair: return "wrench.fill"
        case .outOfService: return "xmark.circle.fill"
        }
    }
}

enum ToolCategory: String, CaseIterable, Codable {
    case power = "Power Tools"
    case hand = "Hand Tools"
    case measuring = "Measuring"
    case safety = "Safety"
    case cutting = "Cutting"
    case lifting = "Lifting"
    case electrical = "Electrical"
    case other = "Other"

    var icon: String {
        switch self {
        case .power: return "bolt.fill"
        case .hand: return "hammer.fill"
        case .measuring: return "ruler.fill"
        case .safety: return "shield.fill"
        case .cutting: return "scissors"
        case .lifting: return "arrow.up.arrow.down"
        case .electrical: return "bolt.circle.fill"
        case .other: return "wrench.and.screwdriver.fill"
        }
    }
}

enum TaskStatus: String, CaseIterable, Codable {
    case pending = "Pending"
    case inProgress = "In Progress"
    case completed = "Completed"
    case blocked = "Blocked"

    var color: Color {
        switch self {
        case .pending: return .sbTextSecondary
        case .inProgress: return .sbAccent
        case .completed: return .sbAccentGreen
        case .blocked: return .sbAccentRed
        }
    }

    var icon: String {
        switch self {
        case .pending: return "clock"
        case .inProgress: return "arrow.triangle.2.circlepath"
        case .completed: return "checkmark.circle.fill"
        case .blocked: return "exclamationmark.octagon.fill"
        }
    }
}

enum TaskPriority: String, CaseIterable, Codable {
    case low = "Low"
    case medium = "Medium"
    case high = "High"
    case critical = "Critical"

    var color: Color {
        switch self {
        case .low: return .sbTextSecondary
        case .medium: return .sbAccentYellow
        case .high: return .sbPrimary
        case .critical: return .sbAccentRed
        }
    }
}

enum WorkerRole: String, CaseIterable, Codable {
    case foreman = "Foreman"
    case carpenter = "Carpenter"
    case electrician = "Electrician"
    case plumber = "Plumber"
    case mason = "Mason"
    case crane = "Crane Operator"
    case laborer = "General Laborer"
    case safety = "Safety Officer"
    case engineer = "Site Engineer"
    case other = "Other"

    var icon: String {
        switch self {
        case .foreman: return "person.badge.key.fill"
        case .carpenter: return "hammer.fill"
        case .electrician: return "bolt.fill"
        case .plumber: return "drop.fill"
        case .mason: return "square.grid.2x2.fill"
        case .crane: return "arrow.up.backward.and.arrow.down.forward"
        case .laborer: return "person.fill"
        case .safety: return "shield.fill"
        case .engineer: return "gearshape.fill"
        case .other: return "person.crop.circle"
        }
    }
}

// MARK: - Models

struct SBSite: Identifiable, Codable {
    var id: UUID = UUID()
    var name: String
    var address: String
    var workerCount: Int
    var isActive: Bool = true
    var createdAt: Date = Date()
    var notes: String = ""
    var progress: Double = 0.0

    static let samples: [SBSite] = [
        SBSite(name: "Downtown Complex", address: "123 Main St, NYC", workerCount: 24, progress: 0.65),
        SBSite(name: "Harbor Bridge", address: "Ocean Ave, Boston", workerCount: 12, progress: 0.32),
        SBSite(name: "Riverside Apt", address: "45 River Rd, Chicago", workerCount: 8, progress: 0.89)
    ]
}

struct SBTool: Identifiable, Codable {
    var id: UUID = UUID()
    var name: String
    var category: ToolCategory
    var condition: ToolCondition
    var location: String
    var assignedTo: String = ""
    var siteId: UUID?
    var lastUsed: Date?
    var notes: String = ""
    var isInUse: Bool = false
    var createdAt: Date = Date()

    static let samples: [SBTool] = [
        SBTool(name: "DeWalt Drill", category: .power, condition: .excellent, location: "Tool Room A", isInUse: true),
        SBTool(name: "Claw Hammer", category: .hand, condition: .good, location: "Site B", isInUse: false),
        SBTool(name: "Circular Saw", category: .cutting, condition: .fair, location: "Warehouse", isInUse: false),
        SBTool(name: "Laser Level", category: .measuring, condition: .excellent, location: "Office", isInUse: true),
        SBTool(name: "Safety Harness", category: .safety, condition: .good, location: "Site A", isInUse: false)
    ]
}

struct ToolUsageRecord: Identifiable, Codable {
    var id: UUID = UUID()
    var toolId: UUID
    var toolName: String
    var usedBy: String
    var startDate: Date
    var endDate: Date?
    var notes: String = ""
}

struct SBEquipment: Identifiable, Codable {
    var id: UUID = UUID()
    var name: String
    var condition: ToolCondition
    var location: String
    var isInUse: Bool = false
    var lastMaintenance: Date?
    var nextMaintenance: Date?
    var siteId: UUID?
    var notes: String = ""
    var createdAt: Date = Date()

    static let samples: [SBEquipment] = [
        SBEquipment(name: "Tower Crane #1", condition: .good, location: "Site A", isInUse: true),
        SBEquipment(name: "Concrete Mixer", condition: .excellent, location: "Site B", isInUse: false),
        SBEquipment(name: "Excavator CAT 320", condition: .fair, location: "Yard", isInUse: true),
        SBEquipment(name: "Forklift Toyota", condition: .good, location: "Warehouse", isInUse: false)
    ]
}

struct MaintenanceRecord: Identifiable, Codable {
    var id: UUID = UUID()
    var equipmentId: UUID
    var equipmentName: String
    var serviceDate: Date
    var description: String
    var performedBy: String
    var cost: Double
    var nextServiceDate: Date?
}

struct SBMaterial: Identifiable, Codable {
    var id: UUID = UUID()
    var name: String
    var unit: String
    var quantity: Double
    var minQuantity: Double
    var location: String = "Warehouse"
    var notes: String = ""
    var createdAt: Date = Date()

    var isLowStock: Bool { quantity <= minQuantity }

    static let samples: [SBMaterial] = [
        SBMaterial(name: "Concrete Mix", unit: "bags", quantity: 240, minQuantity: 50),
        SBMaterial(name: "Red Brick", unit: "pcs", quantity: 5000, minQuantity: 500),
        SBMaterial(name: "Lumber 2x4", unit: "boards", quantity: 180, minQuantity: 30),
        SBMaterial(name: "Steel Rebar", unit: "rods", quantity: 12, minQuantity: 20),
        SBMaterial(name: "Plywood Sheet", unit: "sheets", quantity: 85, minQuantity: 20)
    ]
}

struct SBInventoryItem: Identifiable, Codable {
    var id: UUID = UUID()
    var materialId: UUID
    var materialName: String
    var quantityIn: Double
    var quantityOut: Double
    var date: Date
    var siteId: UUID?
    var notes: String = ""
}

struct SBWorker: Identifiable, Codable {
    var id: UUID = UUID()
    var name: String
    var role: WorkerRole
    var phone: String = ""
    var email: String = ""
    var siteId: UUID?
    var isActive: Bool = true
    var createdAt: Date = Date()
    var avatarInitials: String { String(name.prefix(2)).uppercased() }

    static let samples: [SBWorker] = [
        SBWorker(name: "James Carter", role: .foreman, phone: "+1 555-0101"),
        SBWorker(name: "Maria Gonzalez", role: .engineer, phone: "+1 555-0102"),
        SBWorker(name: "David Kim", role: .electrician, phone: "+1 555-0103"),
        SBWorker(name: "Sarah Johnson", role: .safety, phone: "+1 555-0104"),
        SBWorker(name: "Mike Brown", role: .carpenter, phone: "+1 555-0105")
    ]
}

struct SBTask: Identifiable, Codable {
    var id: UUID = UUID()
    var title: String
    var description: String = ""
    var status: TaskStatus
    var priority: TaskPriority
    var deadline: Date
    var assignedTo: String = ""
    var siteId: UUID?
    var createdAt: Date = Date()
    var completedAt: Date?

    static let samples: [SBTask] = [
        SBTask(title: "Install windows — Block C", description: "Install all 24 windows on floor 3", status: .inProgress, priority: .high, deadline: Date().addingTimeInterval(86400 * 2)),
        SBTask(title: "Pour concrete — Foundation E", description: "Pour concrete for east foundation", status: .pending, priority: .critical, deadline: Date().addingTimeInterval(86400)),
        SBTask(title: "Electrical wiring — Floor 2", description: "Complete electrical rough-in", status: .completed, priority: .medium, deadline: Date().addingTimeInterval(-86400)),
        SBTask(title: "Safety inspection", description: "Monthly safety compliance check", status: .pending, priority: .high, deadline: Date().addingTimeInterval(86400 * 3)),
        SBTask(title: "Material delivery check", description: "Verify steel rebar delivery", status: .blocked, priority: .medium, deadline: Date().addingTimeInterval(86400 * 5))
    ]
}

struct SBScheduleEvent: Identifiable, Codable {
    var id: UUID = UUID()
    var title: String
    var date: Date
    var endDate: Date?
    var type: EventType
    var siteId: UUID?
    var notes: String = ""

    enum EventType: String, CaseIterable, Codable {
        case task = "Task"
        case maintenance = "Maintenance"
        case delivery = "Delivery"
        case inspection = "Inspection"
        case meeting = "Meeting"

        var color: Color {
            switch self {
            case .task: return .sbAccent
            case .maintenance: return .sbPrimary
            case .delivery: return .sbAccentGreen
            case .inspection: return .sbAccentYellow
            case .meeting: return Color(hex: "#9B59B6")
            }
        }

        var icon: String {
            switch self {
            case .task: return "checkmark.square.fill"
            case .maintenance: return "wrench.fill"
            case .delivery: return "shippingbox.fill"
            case .inspection: return "magnifyingglass"
            case .meeting: return "person.2.fill"
            }
        }
    }

    static let samples: [SBScheduleEvent] = [
        SBScheduleEvent(title: "Foundation Inspection", date: Date().addingTimeInterval(86400), type: .inspection),
        SBScheduleEvent(title: "Steel Rebar Delivery", date: Date().addingTimeInterval(86400 * 2), type: .delivery),
        SBScheduleEvent(title: "Site Meeting", date: Date().addingTimeInterval(86400 * 3), type: .meeting),
        SBScheduleEvent(title: "Crane Maintenance", date: Date().addingTimeInterval(86400 * 4), type: .maintenance)
    ]
}

struct ActivityLog: Identifiable, Codable {
    var id: UUID = UUID()
    var action: String
    var entityType: String
    var entityName: String
    var date: Date = Date()
    var icon: String
}
