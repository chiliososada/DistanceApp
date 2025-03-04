//
//  ContentView.swift
//  DistanceApp
//
//  Created by toyousoft on 2025/03/04.
//

//
//  ContentView.swift
//  DistanceApp
//

import SwiftUI

struct ContentView: View {
    // 环境对象
    @EnvironmentObject private var environment: AppEnvironment
    
    var body: some View {
        ZStack {
            if !environment.isInitialized {
                // 初始加载视图
                LoadingView(message: "正在加载...")
                    .task {
                        await environment.initialize()
                    }
            } else if environment.isAuthenticated {
                // 已认证：主应用界面
                authenticatedView
            } else {
                // 未认证：认证流程
                AuthenticationFlowView()
            }
        }
        .preferredColorScheme(environment.systemTheme)
    }
    
    // 已认证状态视图
    private var authenticatedView: some View {
        TabView {
            // 首页标签
            HomeView()
                .tabItem {
                    Label("首页", systemImage: "house.fill")
                }
            
            // 个人资料标签
            Text("个人资料") // 替换为实际的ProfileView
                .tabItem {
                    Label("我的", systemImage: "person.fill")
                }
            
            // 设置标签
            Text("设置") // 替换为实际的SettingsView
                .tabItem {
                    Label("设置", systemImage: "gear")
                }
        }
        .environmentObject(environment.navigationManager as! AppNavigationManager)
        .environmentObject(environment.authManager as! AuthManager)
    }
}

#if DEBUG
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environmentObject(AppEnvironment.preview)
    }
}
#endif
