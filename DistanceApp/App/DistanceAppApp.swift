import SwiftUI
import Firebase

@main
struct DistanceApp: App {
    // 初始化 Firebase
    init() {
        FirebaseApp.configure()
    }
    
    // 使用环境对象管理全局状态和依赖
    @StateObject private var environment = AppEnvironment.shared
    
    // 观察应用程序生命周期
    @Environment(\.scenePhase) private var scenePhase
    
    // 防抖动变量
    @State private var lastSessionCheckTime: Date = .distantPast
    private let sessionCheckInterval: TimeInterval = 30.0 // 30秒内不重复检查
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(environment)
                .environmentObject(environment.authManager as! AuthManager)
                .environmentObject(environment.navigationManager as! AppNavigationManager)
        }
        .onChange(of: scenePhase) { oldPhase, newPhase in
            switch newPhase {
            case .active:
                // 应用变为活跃状态时检查会话
                checkSessionWithDebounce()
                
                // 更新用户活跃状态
                updateUserActiveStatus(true)
                
            case .inactive:
                // 应用变为非活跃状态
                updateUserActiveStatus(false)
                
            case .background:
                // 应用进入后台
                Logger.info("应用进入后台")
                
            @unknown default:
                break
            }
        }
    }
    
    // 带防抖功能的会话检查
    private func checkSessionWithDebounce() {
        let uniqueId = UUID().uuidString.prefix(8)
            let now = Date()
            
            if now.timeIntervalSince(lastSessionCheckTime) > sessionCheckInterval {
                lastSessionCheckTime = now
                print("[\(uniqueId)] 应用激活：执行会话检查")
            Task {
                do {
                    let isValid = try await environment.authManager.validateCurrentSession()
                    Logger.info("会话状态: \(isValid ? "有效" : "无效")")
                   
                } catch {
                    Logger.error("会话检查失败: \(error.localizedDescription)")
                }
            }
        } else {
            Logger.info("会话检查已在短时间内执行过，跳过")
        }
    }
    
    // 更新用户活跃状态
    private func updateUserActiveStatus(_ isActive: Bool) {
        Task {
            do {
                try await environment.authManager.updateUserActiveStatus(isActive)
            } catch {
                Logger.error("更新用户活跃状态失败: \(error.localizedDescription)")
            }
        }
    }
}
