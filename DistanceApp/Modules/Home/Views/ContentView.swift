//
//  ContentView.swift
//  DistanceApp
//
//  Created by toyousoft on 2025/03/04.
//

import SwiftUI

struct ContentView: View {
    // 环境对象
    @EnvironmentObject private var environment: AppEnvironment
    @EnvironmentObject private var navigationManager: AppNavigationManager
    @EnvironmentObject private var authManager: AuthManager
    
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
                //updateprofile
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
        .environmentObject(navigationManager)
        .environmentObject(authManager)
    }
}

#if DEBUG
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environmentObject(AppEnvironment.preview)
            .environmentObject(AppNavigationManager.preview)
            .environmentObject(AuthManager(
                authService: MockAuthService(),
                sessionManager: MockSessionManager(),
                keychainManager: MockKeychainManager()
            ))
    }
}

// 预览辅助类
private class MockAuthService: AuthServiceProtocol {
    func loginWithFirebaseToken(_ idToken: String) async throws -> UserProfile {
        fatalError("仅预览使用")
    }
    func checkSession() async throws -> Bool { return true }
    func updatePassword(currentPassword: String, newPassword: String) async throws {}
    func deleteAccount(password: String) async throws {}
}

private class MockSessionManager: SessionManagerProtocol {
    func updateSessionWithToken(idToken: String, profile: UserProfile) async {}
    func updateSession(user: UserProfile?) async {}
    func getSavedProfile() -> UserProfile? { return nil }
    func clearSession() async {}
    func getAuthToken() -> String? { return nil }
    func savePushToken(_ token: String) {}
    func getPushToken() -> String? { return nil }
    func isSessionValid() -> Bool { return true }
    func shouldRefreshProfile() -> Bool { return false }
}

private class MockKeychainManager: KeychainManagerProtocol {
    func saveSecureString(_ value: String, forKey key: String) throws {}
    func getSecureString(forKey key: String) throws -> String? { return nil }
    func saveSecureData(_ data: Data, forKey key: String) throws {}
    func getSecureData(forKey key: String) throws -> Data? { return nil }
    func deleteSecureData(forKey key: String) throws {}
    func clearAll() throws {}
    func hasKey(_ key: String) -> Bool { return false }
    func saveSecureObject<T: Encodable>(_ object: T, forKey key: String) throws {}
    func getSecureObject<T: Decodable>(_ type: T.Type, forKey key: String) throws -> T? { return nil }
}
#endif
