//
//  AuthenticationFlowView.swift
//  DistanceApp
//
//  Created by toyousoft on 2025/03/04.
//

//
//  AuthenticationFlowView.swift
//  DistanceApp
//

import SwiftUI

struct AuthenticationFlowView: View {
    // 环境对象
    @EnvironmentObject private var navigationManager: AppNavigationManager
    @EnvironmentObject private var authManager: AuthManager  // 添加这一行
    
    var body: some View {
        NavigationStack(path: $navigationManager.navigationPath) {
            // 登录视图作为认证流程的起点
            LoginView()
                .environmentObject(authManager)  // 添加这一行，确保传递authManager
                .navigationDestination(for: AppRoute.self) { route in
                    // 处理认证流程导航
                    switch route {
                    case .register:
                        RegisterView()
                    case .forgotPassword:
                        ForgotPasswordView()
                    case .verifyEmail:
                        VerifyEmailView()
                    case .completeProfile:
                        CompleteProfileView()
                    default:
                        Text("未实现的页面：\(route.title)")
                    }
                }
        }
    }
}





#if DEBUG
struct AuthenticationFlowView_Previews: PreviewProvider {
    static var previews: some View {
        AuthenticationFlowView()
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

