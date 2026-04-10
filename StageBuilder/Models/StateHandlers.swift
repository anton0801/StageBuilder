import Foundation
import AppsFlyerLib

final class StateHandlers {
    private let storage: StorageService
    private let validation: ValidationService
    let network: NetworkService
    private let notification: NotificationService
    
    init(
        storage: StorageService,
        validation: ValidationService,
        network: NetworkService,
        notification: NotificationService
    ) {
        self.storage = storage
        self.validation = validation
        self.network = network
        self.notification = notification
    }
    
    func handleInitial(context: inout StateContext) async -> AppState {
        let stored = storage.loadState()
        context.tracking = stored.tracking
        context.navigation = stored.navigation
        context.mode = stored.mode
        context.isFirstLaunch = stored.isFirstLaunch
        context.permission = StateContext.PermissionData(
            isGranted: stored.permission.isGranted,
            isDenied: stored.permission.isDenied,
            lastAsked: stored.permission.lastAsked
        )
        
        return .loadingTracking
    }
    
    func handleLoadingTracking(context: StateContext) -> AppState {
        // Ждём tracking от AppsFlyer
        return .loadingTracking
    }
    
    func handleTracking(data: [String: Any], context: inout StateContext) -> AppState {
        let converted = data.mapValues { "\($0)" }
        context.tracking = converted
        storage.saveTracking(converted)
        
        return .validating
    }
    
    func handleNavigation(data: [String: Any], context: inout StateContext) {
        let converted = data.mapValues { "\($0)" }
        context.navigation = converted
        storage.saveNavigation(converted)
    }
    
    func handleValidating(context: StateContext) async -> AppState {
        guard context.hasTracking() else {
            return .validationFailed
        }
        
        do {
            let isValid = try await validation.validate()
            if isValid {
                return .fetchingEndpoint
            } else {
                return .validationFailed
            }
        } catch {
            print("🎭 [StageBuilder] Validation error: \(error)")
            return .validationFailed
        }
    }
    
    func handleValidationFailed() -> AppState {
        return .main
    }
    
    func handleFetchingAttribution(context: inout StateContext) async -> AppState {
        guard context.isOrganic() && context.isFirstLaunch else {
            return .fetchingEndpoint
        }
        
        try? await Task.sleep(nanoseconds: 5_000_000_000)
        
        let deviceID = AppsFlyerLib.shared().getAppsFlyerUID()
        
        do {
            var fetched = try await network.fetchAttribution(deviceID: deviceID)
            
            for (key, value) in context.navigation {
                if fetched[key] == nil {
                    fetched[key] = value
                }
            }
            
            let converted = fetched.mapValues { "\($0)" }
            context.tracking = converted
            storage.saveTracking(converted)
            
            return .fetchingEndpoint
        } catch {
            print("🎭 [StageBuilder] Attribution error: \(error)")
            return .main
        }
    }
    
    func handleFetchingEndpoint(context: StateContext) async -> AppState {
        // Проверяем temp_url
        if let temp = UserDefaults.standard.string(forKey: "temp_url"), !temp.isEmpty {
            return .endpoint
        }
        
        let trackingDict = context.tracking.mapValues { $0 as Any }
        
        do {
            let url = try await network.fetchEndpoint(tracking: trackingDict)
            return .endpoint
        } catch {
            print("🎭 [StageBuilder] Endpoint error: \(error)")
            return .main
        }
    }
    
    func handleEndpoint(url: String, context: inout StateContext) -> AppState {
        context.endpoint = url
        context.mode = "Active"
        context.isFirstLaunch = false
        context.isLocked = true
        
        storage.saveEndpoint(url)
        storage.saveMode("Active")
        storage.markLaunched()
        
        if context.permission.canAsk {
            return .showingPermission
        } else {
            return .web
        }
    }
    
//    func handlePermissionRequest(context: inout StateContext) async -> AppState {
//        var localPermission = context.permission
//        
//        return await withCheckedContinuation { continuation in
//            notification.requestPermission { granted in
//                if granted {
//                    localPermission.isGranted = true
//                    localPermission.isDenied = false
//                    localPermission.lastAsked = Date()
//                    self.notification.registerForPush()
//                } else {
//                    localPermission.isGranted = false
//                    localPermission.isDenied = true
//                    localPermission.lastAsked = Date()
//                }
//
//                self.storage.savePermissions(localPermission)
//                continuation.resume(returning: .web)
//            }
//        }
//    }
    
    func handlePermissionRequest(context: inout StateContext) async -> AppState {
        var localPermission = context.permission
        
        let updatedPermission = await withCheckedContinuation {
            (continuation: CheckedContinuation<StateContext.PermissionData, Never>) in
            
            notification.requestPermission { granted in
                var permission = localPermission  // ✅ Читаем из context
                
                if granted {
                    permission.isGranted = true
                    permission.isDenied = false
                    permission.lastAsked = Date()
                    self.notification.registerForPush()
                } else {
                    permission.isGranted = false
                    permission.isDenied = true
                    permission.lastAsked = Date()
                }
                
                self.storage.savePermissions(permission)
                continuation.resume(returning: permission)  // ✅ Возвращаем ДАННЫЕ
            }
        }
        
        // ✅ Применяем обновление к context
        context.permission = updatedPermission
        
        // ✅ Возвращаем state БЕЗ continuation
        return .web
    }
    
    func handlePermissionDefer(context: inout StateContext) -> AppState {
        context.permission.lastAsked = Date()
        storage.savePermissions(context.permission)
        return .web
    }
}
