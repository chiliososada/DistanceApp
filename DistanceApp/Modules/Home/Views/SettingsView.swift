//
//  SettingsView.swift
//  DistanceApp
//
//  Created on 2025/03/11.
//

import SwiftUI

struct SettingsView: View {
    // 环境对象
    @EnvironmentObject private var navigationManager: AppNavigationManager
    @EnvironmentObject private var authManager: AuthManager
    @EnvironmentObject private var environment: AppEnvironment
    
    // 添加初始化器以确保环境对象正确传递
    init() {
        // 确保视图正确初始化
        print("SettingsView初始化")
    }
    
    // 状态变量
    @State private var showLogoutConfirmation = false
    @State private var isLoggingOut = false
    
    var body: some View {
        List {
            // 个人信息区域
            Section {
                if let profile = authManager.userProfile {
                    HStack(spacing: 12) {
                        // 头像
                        if let photoURL = profile.photoURL {
                            AsyncImage(url: photoURL) { image in
                                image
                                    .resizable()
                                    .scaledToFill()
                            } placeholder: {
                                Color.gray.opacity(0.3)
                            }
                            .frame(width: 60, height: 60)
                            .clipShape(Circle())
                        } else {
                            Image(systemName: "person.circle.fill")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 60, height: 60)
                                .foregroundColor(.gray)
                        }
                        
                        // 用户信息
                        VStack(alignment: .leading, spacing: 4) {
                            Text(profile.displayName)
                                .font(.headline)
                            
                            Text(profile.email)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        // 编辑按钮
                        Image(systemName: "chevron.right")
                            .foregroundColor(.gray)
                    }
                    .padding(.vertical, 8)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        navigationManager.navigate(to: .profile)
                    }
                }
            }
            
            // 账号区域
            Section("账号") {
                // 个人资料设置
                NavigationLink(value: AppRoute.profile) {
                    HStack {
                        Image(systemName: "person.circle")
                            .foregroundColor(.blue)
                        Text("个人资料")
                    }
                }
                
                // 密码修改
                NavigationLink(value: AppRoute.changePassword) {
                    HStack {
                        Image(systemName: "lock")
                            .foregroundColor(.blue)
                        Text("修改密码")
                    }
                }
                
                // 账号设置
                NavigationLink(value: AppRoute.accountSettings) {
                    HStack {
                        Image(systemName: "person.text.rectangle")
                            .foregroundColor(.blue)
                        Text("账号设置")
                    }
                }
            }
            
            // 应用设置区域
            Section("应用设置") {
                // 通知设置
                Button {
                    // 通知设置逻辑
                } label: {
                    HStack {
                        Image(systemName: "bell")
                            .foregroundColor(.blue)
                        Text("通知设置")
                        Spacer()
                        Image(systemName: "chevron.right")
                            .foregroundColor(.gray)
                    }
                }
                .buttonStyle(PlainButtonStyle())
                
                // 隐私设置
                Button {
                    // 隐私设置逻辑
                } label: {
                    HStack {
                        Image(systemName: "hand.raised")
                            .foregroundColor(.blue)
                        Text("隐私设置")
                        Spacer()
                        Image(systemName: "chevron.right")
                            .foregroundColor(.gray)
                    }
                }
                .buttonStyle(PlainButtonStyle())
                
                // 深色模式开关
                Toggle(isOn: Binding(
                    get: { environment.systemTheme == .dark },
                    set: { newValue in
                        environment.systemTheme = newValue ? .dark : .light
                    }
                )) {
                    HStack {
                        Image(systemName: "moon")
                            .foregroundColor(.blue)
                        Text("深色模式")
                    }
                }
            }
            
            // 关于区域
            Section("关于") {
                // 帮助与反馈
                Button {
                    // 帮助与反馈逻辑
                } label: {
                    HStack {
                        Image(systemName: "questionmark.circle")
                            .foregroundColor(.blue)
                        Text("帮助与反馈")
                        Spacer()
                        Image(systemName: "chevron.right")
                            .foregroundColor(.gray)
                    }
                }
                .buttonStyle(PlainButtonStyle())
                
                // 隐私政策
                Button {
                    // 隐私政策逻辑
                } label: {
                    HStack {
                        Image(systemName: "doc.text")
                            .foregroundColor(.blue)
                        Text("隐私政策")
                        Spacer()
                        Image(systemName: "chevron.right")
                            .foregroundColor(.gray)
                    }
                }
                .buttonStyle(PlainButtonStyle())
                
                // 关于我们
                Button {
                    // 关于我们逻辑
                } label: {
                    HStack {
                        Image(systemName: "info.circle")
                            .foregroundColor(.blue)
                        Text("关于我们")
                        Spacer()
                        Image(systemName: "chevron.right")
                            .foregroundColor(.gray)
                    }
                }
                .buttonStyle(PlainButtonStyle())
                
                // 版本信息
                HStack {
                    Image(systemName: "apps.iphone")
                        .foregroundColor(.blue)
                    Text("版本")
                    Spacer()
                    Text("\(AppConfig.appVersion) (\(AppConfig.buildNumber))")
                        .foregroundColor(.gray)
                }
            }
            
            // 登出按钮
            Section {
                Button(action: {
                    showLogoutConfirmation = true
                }) {
                    HStack {
                        Spacer()
                        if isLoggingOut {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle())
                        } else {
                            Text("退出登录")
                                .foregroundColor(.red)
                        }
                        Spacer()
                    }
                }
                .disabled(isLoggingOut)
            }
        }
        .navigationTitle("设置")
        .alert("确认退出", isPresented: $showLogoutConfirmation) {
            Button("取消", role: .cancel) { }
            Button("退出", role: .destructive) {
                logout()
            }
        } message: {
            Text("确定要退出登录吗？")
        }
    }
    
    // 登出方法
    private func logout() {
        isLoggingOut = true
        
        Task {
            // 不需要do-catch，因为reset()内部已处理错误
            await environment.reset()
            
            // 切换到主线程更新UI状态
            await MainActor.run {
                isLoggingOut = false
            }
        }
    }
}

#if DEBUG
struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            SettingsView()
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
}
#endif
