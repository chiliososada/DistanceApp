import SwiftUI

struct ContentView: View {
    // 环境对象
    @EnvironmentObject private var environment: AppEnvironment
    @EnvironmentObject private var navigationManager: AppNavigationManager
    @EnvironmentObject private var authManager: AuthManager
    
    var body: some View {
           Group {
               if !environment.isInitialized {
                   // 初始加载视图
                   LoadingView(message: "正在加载...")
                       .task {
                           await environment.initialize()
                       }
               } else if environment.isAuthenticated {
                   if environment.isProfileIncomplete {
                       // 已认证但需要完善资料
                       NavigationStack {
                           CompleteProfileView()
                       }
                   } else {
                       // 已完全认证：主应用界面 - 使用TabView
                       mainTabView
                   }
               } else {
                   // 未认证：认证流程 - 保持原有导航路径
                   NavigationStack(path: $navigationManager.navigationPath) {
                       LoginView()
                           .navigationDestination(for: AppRoute.self) { route in
                               authDestinationView(for: route)
                           }
                   }
               }
           }
           .sheet(isPresented: $navigationManager.isPresentingSheet) {
               if let route = navigationManager.presentedSheet {
                   sheetView(for: route)
               }
           }
           .preferredColorScheme(environment.systemTheme)
       }
    
    // 主标签页视图 - 使用各标签页独立的导航路径
    private var mainTabView: some View {
            TabView(selection: $navigationManager.selectedTab) {
                // 首页标签
                NavigationStack(path: $navigationManager.homeTabPath) {
                    HomeView()
                        .navigationDestination(for: AppRoute.self) { route in
                            destinationView(for: route)
                        }
                }
                .tabItem {
                    Label("首页", systemImage: "house.fill")
                }
                .tag(Tab.home)
                
                // 个人资料标签
                NavigationStack(path: $navigationManager.profileTabPath) {
                    Text("个人资料") // 替换为实际的ProfileView
                        .navigationDestination(for: AppRoute.self) { route in
                            destinationView(for: route)
                        }
                }
                .tabItem {
                    Label("我的", systemImage: "person.fill")
                }
                .tag(Tab.profile)
                
                // 设置标签
                NavigationStack(path: $navigationManager.settingsTabPath) {
                    SettingsView()
                        .navigationDestination(for: AppRoute.self) { route in
                            destinationView(for: route)
                        }
                }
                .tabItem {
                    Label("设置", systemImage: "gear")
                }
                .tag(Tab.settings)
            }
        }
    
    // 目标视图构建器
    @ViewBuilder
    private func destinationView(for route: AppRoute) -> some View {
        switch route {
        case .login:
            LoginView()
        case .register:
            RegisterView()
        case .forgotPassword:
            ForgotPasswordView()
        case .verifyEmail:
            VerifyEmailView()
        case .completeProfile:
            CompleteProfileView()
        case .home:
            HomeView()
        case .profile:
            Text("用户资料页面")
        case .settings:
            SettingsView()
        case .changePassword:
            Text("修改密码页面")
        case .accountSettings:
            Text("账户设置页面")
        case .deleteAccount:
            Text("删除账户页面")
        case .topicDetail(let topicId):
              // 处理话题详情页导航，需要从HomeViewModel中查找话题数据
              TopicDetailFromIdView(topicId: topicId)
        }
    }
    
    // 认证流程视图构建器
    @ViewBuilder
    private func authDestinationView(for route: AppRoute) -> some View {
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
            Text("未实现的认证页面: \(route.title)")
        }
    }
    
    // 表单视图构建器
    @ViewBuilder
    private func sheetView(for route: AppRoute) -> some View {
        switch route {
        case .forgotPassword:
            ForgotPasswordView()
        default:
            Text("未实现的表单: \(route.title)")
        }
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
    func signOut()async throws {
        fatalError("未实现")
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
