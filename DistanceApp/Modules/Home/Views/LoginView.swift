//
//  LoginView.swift
//  DistanceApp
//
//  Created by toyousoft on 2025/03/04.
//

//
//  LoginView.swift
//  DistanceApp
//

import SwiftUI

struct LoginView: View {
    // 环境对象
    @EnvironmentObject private var authManager: AuthManager
    @EnvironmentObject private var navigationManager: AppNavigationManager
    @State private var errorMessage: String = ""
    // 状态变量
    @State private var email = ""
    @State private var password = ""
    @State private var isSecured = true
    
    var body: some View {
        VStack(spacing: 20) {
            // 标题和Logo
            VStack(spacing: 10) {
                Image(systemName: "location.circle.fill") // 替换为您的实际Logo
                    .resizable()
                    .scaledToFit()
                    .frame(width: 80, height: 80)
                    .foregroundColor(.blue)
                
                Text("Distance")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("探索周围的世界")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .padding(.bottom, 40)
            
            // 登录表单
            VStack(spacing: 15) {
                // 邮箱输入框
                TextField("邮箱", text: $email)
                    .keyboardType(.emailAddress)
                    .autocapitalization(.none)
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)
                
                // 密码输入框
                HStack {
                    if isSecured {
                        SecureField("密码", text: $password)
                    } else {
                        TextField("密码", text: $password)
                    }
                    
                    Button(action: { isSecured.toggle() }) {
                        Image(systemName: isSecured ? "eye.slash" : "eye")
                            .foregroundColor(.gray)
                    }
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(8)
                
                // 忘记密码链接
                HStack {
                    Spacer()
                    Button(action: { navigateTo(.forgotPassword) }) {
                        Text("忘记密码?")
                            .foregroundColor(.blue)
                    }
                }
                .padding(.top, 5)
            }
            
            // 登录按钮
            Button {
                print("登录按钮点击")
                login()
            } label: {
                Text("登录")
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.blue)
            .cornerRadius(8)
            .disabled(!isFormValid || authManager.isLoading)
            .opacity(!isFormValid ? 0.7 : 1)
            .padding(.top, 10)
            
            // 分隔线
            HStack {
                VStack { Divider() }
                Text("或")
                    .foregroundColor(.secondary)
                    .font(.footnote)
                VStack { Divider() }
            }
            .padding(.vertical)
            
            // 社交登录按钮
            HStack(spacing: 15) {
                Button(action: loginWithGoogle) {
                    HStack {
                        Image(systemName: "g.circle.fill") // 替换为Google图标
                            .foregroundColor(.red)
                        Text("Google登录")
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)
                }
                
                Button(action: loginWithApple) {
                    HStack {
                        Image(systemName: "apple.logo") // 替换为Apple图标
                            .foregroundColor(.black)
                        Text("Apple登录")
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)
                }
            }
            
            Spacer()
            
            // 注册链接
            HStack {
                Text("还没有账号?")
                    .foregroundColor(.secondary)
                Button(action: { navigateTo(.register) }) {
                    Text("立即注册")
                        .fontWeight(.semibold)
                        .foregroundColor(.blue)
                }
            }
            .padding(.bottom)
        }
        .padding()
        .alert(item: alertItem) { item in
            Alert(
                title: Text("错误"),
                message: Text(item.message),
                dismissButton: .default(Text("确定"))
            )
        }
    }
    
    // MARK: - 表单验证
    private var isFormValid: Bool {
        !email.isEmpty && !password.isEmpty
    }
    
    // MARK: - 警告项
    private var alertItem: Binding<AlertItem?> {
        Binding<AlertItem?>(
            get: {
                guard let error = authManager.error else { return nil }
                return AlertItem(id: UUID().uuidString, message: error.errorDescription ?? "未知错误")
            },
            set: { _ in }
        )
    }
    
    // MARK: - 导航方法
    private func navigateTo(_ route: AppRoute) {
        navigationManager.navigate(to: route)
    }
    // MARK: - 登录方法
    private func login() {
        Logger.debug("登录按钮被点击")
        errorMessage = ""
        
        // 检查表单是否有效
        guard isFormValid else {
            errorMessage = "请输入邮箱和密码"
            return
        }
        
        Task {
            do {
                Logger.debug("开始登录流程 - 邮箱: \(email)")
                try await authManager.signIn(with: AuthCredentials(
                    email: email,
                    password: password
                ))
                Logger.debug("登录成功")
                
            } catch let error as AuthError {
                // 检查是否需要完善个人资料
                if case .profileIncomplete = error {
                    // 导航到完善个人资料页面
                    await MainActor.run {
                        navigationManager.navigate(to: .completeProfile)
                    }
                    return
                }
                
                // 处理其他认证错误
                await MainActor.run {
                    errorMessage = error.errorDescription ?? "登录失败"
                    Logger.error("登录失败: \(errorMessage)")
                }
            } catch {
                await MainActor.run {
                    errorMessage = "登录失败: \(error.localizedDescription)"
                    Logger.error("未知错误: \(error.localizedDescription)")
                }
            }
        }
    }
    
    private func loginWithGoogle() {
        Task {
            do {
                try await authManager.signInWithGoogle()
            } catch {
                // 错误已在AuthManager中处理
            }
        }
    }
    
    private func loginWithApple() {
        Task {
            do {
                try await authManager.signInWithApple()
            } catch {
                // 错误已在AuthManager中处理
            }
        }
    }
}

#if DEBUG
struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        LoginView()
            .environmentObject(AuthManager.init(
                authService: MockAuthService(),
                sessionManager: MockSessionManager(),
                keychainManager: MockKeychainManager()
            ) as AuthManager)
            .environmentObject(AppNavigationManager.preview)
    }
}

// 假的服务用于预览
private class MockAuthService: AuthServiceProtocol {
    func loginWithFirebaseToken(_ idToken: String) async throws -> UserProfile {
        fatalError("未实现")
    }
    func signOut()async throws {
        fatalError("未实现")
    }
    func checkSession() async throws -> Bool {
        return false
    }
    
    func updatePassword(currentPassword: String, newPassword: String) async throws {
        fatalError("未实现")
    }
    
    func deleteAccount(password: String) async throws {
        fatalError("未实现")
    }
}

private class MockSessionManager: SessionManagerProtocol {
    func updateSessionWithToken(idToken: String, profile: UserProfile) async {}
    func updateSession(user: UserProfile?) async {}
    func getSavedProfile() -> UserProfile? { return nil }
    func clearSession() async {}
    func getAuthToken() -> String? { return nil }
    func savePushToken(_ token: String) {}
    func getPushToken() -> String? { return nil }
    func isSessionValid() -> Bool { return false }
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
