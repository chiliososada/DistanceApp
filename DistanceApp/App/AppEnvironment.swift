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
    
    // 添加防抖相关属性
    private var lastSessionCheckTime: Date = .distantPast
    private let sessionCheckInterval: TimeInterval = 30.0 // 30秒内不重复检查
    private var isInitializingSession = false
    
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
        isInitializingSession = true
        defer { isInitializingSession = false }
        
        do {
            if shouldCheckSession() {
                // 更新最后检查时间
                lastSessionCheckTime = Date()
                Logger.info("环境初始化: 执行会话检查")
                let isSessionValid = try await authManager.validateCurrentSession()
                await MainActor.run {
                    self.isAuthenticated = isSessionValid
                    self.isInitialized = true
                }
            } else {
                Logger.info("环境初始化: 跳过会话检查(已在短时间内执行过)")
                await MainActor.run {
                    self.isInitialized = true
                }
            }
        } catch {
            Logger.error("环境初始化失败: \(error.localizedDescription)")
            await MainActor.run {
                self.isAuthenticated = false
                self.isInitialized = true
            }
        }
    }
    
    /// 检查会话有效性并防抖动
    func checkSessionIfNeeded() async -> Bool {
        // 如果正在执行初始化，等待它完成
        if isInitializingSession {
            Logger.info("等待初始化完成...")
            // 简单延迟，给初始化一点时间完成
            try? await Task.sleep(nanoseconds: 500_000_000) // 0.5秒
        }
        
        if !shouldCheckSession() {
            Logger.info("会话检查已在短时间内执行过，跳过")
            // 确保返回最新的状态
            return isInitialized ? isAuthenticated : false
        }
        
        // 更新最后检查时间
        lastSessionCheckTime = Date()
        Logger.info("执行会话检查")
        
        do {
            let isValid = try await authManager.validateCurrentSession()
            await MainActor.run {
                self.isAuthenticated = isValid
            }
            return isValid
        } catch {
            Logger.error("会话检查失败: \(error.localizedDescription)")
            await MainActor.run {
                self.isAuthenticated = false
            }
            return false
        }
    }
    
    /// 判断是否应该检查会话（防抖动逻辑）
    private func shouldCheckSession() -> Bool {
        let now = Date()
        return now.timeIntervalSince(lastSessionCheckTime) > sessionCheckInterval
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
