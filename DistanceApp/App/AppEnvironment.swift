//
//  AppEnvironment.swift
//  DistanceApp
//
//  Created by toyousoft on 2025/03/03.
//
/// 应用程序全局环境，管理依赖注入和全局状态
//
//  AppEnvironment.swift
//  DistanceApp
//
//  Created by toyousoft on 2025/03/03.
//

import SwiftUI
import Combine

/// 应用程序全局环境，管理依赖注入和全局状态
final class AppEnvironment: ObservableObject {
    // MARK: - Shared Instance
    static let shared = AppEnvironment()
    
    // MARK: - Services
    let authService: AuthServiceProtocol
    let authManager: AuthManagerProtocol
    let sessionManager: SessionManagerProtocol
    let navigationManager: NavigationManagerProtocol
    let apiClient: APIClientProtocol
    let storageManager: StorageManagerProtocol
    let keychainManager: KeychainManagerProtocol
    
    // MARK: - Published Properties
    @Published var isAuthenticated: Bool = false
    @Published var isInitialized: Bool = false
    @Published var systemTheme: ColorScheme = .light
    
    // MARK: - Private
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    private init() {
        // 创建各服务实例
        let keychain = KeychainWrapper()
        self.keychainManager = KeychainManager(keychain: keychain)
        
        let userDefaults = UserDefaults.standard
        self.storageManager = StorageManager(userDefaults: userDefaults)
        
        self.sessionManager = SessionManager(
            keychainManager: keychainManager,
            storageManager: storageManager
        )
        
        self.apiClient = APIClient(
            sessionManager: sessionManager,
            baseURL: AppConfig.apiBaseURL
        )
        
        self.authService = AuthService(apiClient: apiClient)
        self.navigationManager = AppNavigationManager()
        
        self.authManager = AuthManager(
            authService: authService,
            sessionManager: sessionManager,
            keychainManager: keychainManager
        )
        
        setupBindings()
    }
    
    private func setupBindings() {
        // 监听认证状态变化
        authManager.authStatePublisher
            .receive(on: RunLoop.main)
            .sink { [weak self] isAuthenticated in
                self?.isAuthenticated = isAuthenticated
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Public Methods
    
    /// 初始化应用程序环境
    func initialize() async {
        do {
            // 检查是否有有效会话
            let isSessionValid = try await authManager.validateCurrentSession()
            
            await MainActor.run {
                self.isAuthenticated = isSessionValid
                self.isInitialized = true
            }
        } catch {
            Logger.error("环境初始化失败: \(error.localizedDescription)")
            await MainActor.run {
                self.isAuthenticated = false
                self.isInitialized = true
            }
        }
    }
    
    /// 重置环境状态
    func reset() async {
        do {
            try await authManager.signOut()
            navigationManager.resetNavigation()
            
            await MainActor.run {
                self.isAuthenticated = false
            }
        } catch {
            Logger.error("环境重置失败: \(error.localizedDescription)")
        }
    }
}

// 为了简化测试，提供预览环境
#if DEBUG
extension AppEnvironment {
    static var preview: AppEnvironment {
        let environment = AppEnvironment.shared
        return environment
    }
}
#endif


