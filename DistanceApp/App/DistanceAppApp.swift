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
        Task {
            // 使用环境中统一的防抖机制
            let isValid = await environment.checkSessionIfNeeded()
            Logger.info("会话状态检查结果: \(isValid ? "有效" : "无效")")
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
