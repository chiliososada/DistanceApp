//
//  DistanceApp.swift
//  DistanceApp
//

import SwiftUI

@main
struct DistanceApp: App {
    // 使用环境对象管理全局状态和依赖
    @StateObject private var environment = AppEnvironment.shared
    
    // 观察应用程序生命周期
    @Environment(\.scenePhase) private var scenePhase
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(environment)
        }
        .onChange(of: scenePhase) { newPhase in
            switch newPhase {
            case .active:
                // 应用变为活跃状态时检查会话
                checkSession()
                
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
    
    // 检查会话状态
    private func checkSession() {
        Logger.info("检查会话状态")
        Task {
            do {
                let isValid = try await environment.authManager.validateCurrentSession()
                Logger.info("会话状态: \(isValid ? "有效" : "无效")")
            } catch {
                Logger.error("会话检查失败: \(error.localizedDescription)")
            }
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
