//
//  DistanceAppApp.swift
//  DistanceApp
//
//  Created by toyousoft on 2025/03/03.
//

import SwiftUI

@main
struct DistanceApp: App {
    // 使用环境对象管理全局状态和依赖
    @StateObject private var environment = AppEnvironment.shared
    
    var body: some Scene {
        WindowGroup {
            ZStack {
                if !environment.isInitialized {
                    // 初始加载视图
                    LoadingView(message: "正在加载...")
                        .task {
                            await environment.initialize()
                        }
                } else if environment.isAuthenticated {
                    // 已认证：主应用界面
                    MainContentView()
                        .environmentObject(environment)
                        .environmentObject(environment.navigationManager as! AppNavigationManager)
                        .environmentObject(environment.authManager as! AuthManager)
                } else {
                    // 未认证：认证流程
                    AuthenticationFlowView()
                        .environmentObject(environment)
                        .environmentObject(environment.navigationManager as! AppNavigationManager)
                        .environmentObject(environment.authManager as! AuthManager)
                }
            }
            .preferredColorScheme(environment.systemTheme)
        }
    }
}

// 视图代码暂不提供完整实现
struct MainContentView: View {
    var body: some View {
        Text("主内容区域")
    }
}

struct AuthenticationFlowView: View {
    var body: some View {
        Text("认证流程")
    }
}
