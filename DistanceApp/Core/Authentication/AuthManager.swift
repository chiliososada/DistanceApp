//
//  AuthManager.swift
//  DistanceApp
//
//  Created by toyousoft on 2025/03/03.
//

import Foundation
import Combine
import FirebaseAuth

// MARK: - Protocol
protocol AuthManagerProtocol {
    // 认证状态
    var authStatePublisher: AnyPublisher<Bool, Never> { get }
    var currentUser: User? { get }
    var userProfile: UserProfile? { get }
    var isLoading: Bool { get }
    
    // 会话验证
    func validateCurrentSession() async throws -> Bool
    
    // 登录相关
    func signIn(with credentials: AuthCredentials) async throws
    func signInWithGoogle() async throws
    func signInWithApple() async throws
    
    // 注册相关
    func signUp(with data: RegistrationData) async throws
    
    // 退出和账户管理
    func signOut() async throws
    func updatePassword(currentPassword: String, newPassword: String) async throws
    func deleteAccount(password: String) async throws
    
    // 用户状态
    func updateUserActiveStatus(_ isActive: Bool) async throws
}

// MARK: - Implementation
final class AuthManager: ObservableObject, AuthManagerProtocol {
    // MARK: - Published Properties
    @Published private(set) var currentUser: User?
    @Published private(set) var userProfile: UserProfile?
    @Published private(set) var isLoading = false
    @Published private(set) var error: AuthError?
    @Published private(set) var isInitialized = false
    
    private let auth = Auth.auth()
    private let apiClient: APIClientProtocol
    private let sessionManager: SessionManagerProtocol
    private let keychainManager: KeychainManagerProtocol
    private var stateListener: AuthStateDidChangeListenerHandle?
    
    private let authStateSubject = PassthroughSubject<Bool, Never>()
    var authStatePublisher: AnyPublisher<Bool, Never> {
        authStateSubject.eraseToAnyPublisher()
    }
    
    // MARK: - Initialization
    init(
        apiClient: APIClientProtocol,
        sessionManager: SessionManagerProtocol,
        keychainManager: KeychainManagerProtocol
    ) {
        self.apiClient = apiClient
        self.sessionManager = sessionManager
        self.keychainManager = keychainManager
        setupAuthStateListener()
    }
    
    deinit {
        if let listener = stateListener {
            auth.removeStateDidChangeListener(listener)
        }
    }
    
    // MARK: - Private Methods
    private func setupAuthStateListener() {
        stateListener = auth.addStateDidChangeListener { [weak self] _, user in
            Task { @MainActor in
                guard let self = self else { return }
                
                self.currentUser = user
                
                if !self.isInitialized {
                    // 从会话管理器加载用户配置文件
                    self.userProfile = self.sessionManager.getSavedProfile()
                    self.isInitialized = true
                    
                    // 发布认证状态更新
                    self.authStateSubject.send(self.userProfile != nil)
                }
            }
        }
    }
    
    private func updateUserProfile(_ user: User, name: String) async throws {
        let changeRequest = user.createProfileChangeRequest()
        changeRequest.displayName = name
        try await changeRequest.commitChanges()
    }
    
    // MARK: - Public Methods
    @MainActor
    func validateCurrentSession() async throws -> Bool {
        // 检查会话是否有效
        guard sessionManager.isSessionValid() else {
            return false
        }
        
        do {
            // 通过API验证会话有效性
            let isValid = try await apiClient.checkSession()
            
            if isValid {
                // 如果会话有效，确保加载用户配置文件
                if let profile = sessionManager.getSavedProfile() {
                    self.userProfile = profile
                    self.authStateSubject.send(true)
                    return true
                } else if sessionManager.shouldRefreshProfile() {
                    // 如果需要刷新用户配置文件
                    let profile = try await apiClient.refreshUserProfile()
                    await sessionManager.updateSession(user: profile)
                    self.userProfile = profile
                    self.authStateSubject.send(true)
                    return true
                }
                
                return true
            }
            
            // 会话无效，清理本地状态
            await sessionManager.clearSession()
            self.userProfile = nil
            self.authStateSubject.send(false)
            return false
        } catch {
            // 出现错误时，保守处理为会话无效
            await sessionManager.clearSession()
            self.userProfile = nil
            self.authStateSubject.send(false)
            throw error
        }
    }
    
    @MainActor
    func signIn(with credentials: AuthCredentials) async throws {
        isLoading = true
        error = nil
        
        defer { isLoading = false }
        
        do {
            // 1. Firebase 认证
            let result = try await auth.signIn(withEmail: credentials.email, password: credentials.password)
            
            // 2. 检查邮箱验证
            if !result.user.isEmailVerified {
                // 如果未验证，发送验证邮件
                try await result.user.sendEmailVerification()
                throw AuthError.emailNotVerified
            }
            
            // 3. 获取 idToken
            let idToken = try await result.user.getIDToken()
            
            // 4. 调用后端API进行真正的登录
            let userProfile = try await apiClient.loginWithFirebaseToken(idToken)
            
            // 5. 存储session信息
            self.userProfile = userProfile
            await sessionManager.updateSessionWithToken(idToken: idToken, profile: userProfile)
            
            // 6. 发布认证状态更新
            self.authStateSubject.send(true)
            
        } catch {
            self.error = AuthError.fromFirebaseError(error)
            throw self.error!
        }
    }
    
    @MainActor
    func signInWithGoogle() async throws {
        // 实现Google登录逻辑
        isLoading = true
        defer { isLoading = false }
        
        // TODO: 实现Google登录流程
        throw AuthError.notImplemented
    }
    
    @MainActor
    func signInWithApple() async throws {
        // 实现Apple登录逻辑
        isLoading = true
        defer { isLoading = false }
        
        // TODO: 实现Apple登录流程
        throw AuthError.notImplemented
    }
    
    @MainActor
    func signUp(with data: RegistrationData) async throws {
        isLoading = true
        error = nil
        
        defer { isLoading = false }
        
        do {
            // 1. 创建用户
            let result = try await auth.createUser(withEmail: data.email, password: data.password)
            
            // 2. 更新用户资料
            try await updateUserProfile(result.user, name: data.name)
            
            // 3. 发送验证邮件
            try await result.user.sendEmailVerification()
            
            // 4. 注册完成后退出Firebase
            try auth.signOut()
            
        } catch {
            self.error = AuthError.fromFirebaseError(error)
            throw self.error!
        }
    }
    
    @MainActor
    func signOut() async throws {
        isLoading = true
        error = nil
        
        defer { isLoading = false }
        
        do {
            // 1. 清除session
            await sessionManager.clearSession()
            
            // 2. 清除本地状态
            self.userProfile = nil
            
            // 3. Firebase 登出
            if auth.currentUser != nil {
                try auth.signOut()
            }
            
            // 4. 发布认证状态更新
            self.authStateSubject.send(false)
            
        } catch {
            self.error = AuthError.fromFirebaseError(error)
            throw self.error!
        }
    }
    
    @MainActor
    func updatePassword(currentPassword: String, newPassword: String) async throws {
        isLoading = true
        error = nil
        
        defer { isLoading = false }
        
        do {
            // 调用后端API
            try await apiClient.updatePassword(currentPassword: currentPassword, newPassword: newPassword)
            
            // 成功后清除session，强制用户重新登录
            await sessionManager.clearSession()
            self.userProfile = nil
            self.authStateSubject.send(false)
            
        } catch {
            self.error = error as? AuthError ?? AuthError.unknown(error.localizedDescription)
            throw self.error!
        }
    }
    
    @MainActor
    func deleteAccount(password: String) async throws {
        isLoading = true
        error = nil
        
        defer { isLoading = false }
        
        do {
            // 调用后端API删除账户
            try await apiClient.deleteAccount(password: password)
            
            // 清除session
            await sessionManager.clearSession()
            self.userProfile = nil
            self.authStateSubject.send(false)
            
        } catch {
            self.error = error as? AuthError ?? AuthError.unknown(error.localizedDescription)
            throw self.error!
        }
    }
    
    @MainActor
    func updateUserActiveStatus(_ isActive: Bool) async throws {
        guard userProfile != nil else { return }
        
        do {
            try await apiClient.updateUserStatus(isActive: isActive)
        } catch {
            // 非关键错误，只记录日志
            print("更新用户状态失败: \(error.localizedDescription)")
        }
    }
}

// MARK: - Error Type
enum AuthError: LocalizedError, Equatable {
    case invalidEmail
    case invalidPassword
    case invalidCredentials
    case weakPassword
    case emailAlreadyInUse
    case userNotFound
    case requiresRecentLogin
    case networkError
    case emailNotVerified
    case tooManyRequests
    case notImplemented
    case unknown(String)
    
    var errorDescription: String? {
        switch self {
        case .invalidEmail:
            return "邮箱格式无效"
        case .invalidPassword:
            return "密码错误"
        case .invalidCredentials:
            return "账号或密码错误"
        case .weakPassword:
            return "密码强度不够，至少需要6个字符"
        case .emailAlreadyInUse:
            return "该邮箱已被注册"
        case .userNotFound:
            return "用户不存在"
        case .requiresRecentLogin:
            return "此操作需要重新登录"
        case .networkError:
            return "网络连接错误，请检查网络后重试"
        case .emailNotVerified:
            return "邮箱尚未验证"
        case .tooManyRequests:
            return "请求过于频繁，请稍后再试"
        case .notImplemented:
            return "功能尚未实现"
        case .unknown(let message):
            return "错误：\(message)"
        }
    }
    
    // Firebase错误映射
    static func fromFirebaseError(_ error: Error) -> AuthError {
        // 实现从Firebase错误到AuthError的映射
        // [实现代码同原始项目]
        return .unknown(error.localizedDescription)
    }
    
    // Equatable
    static func == (lhs: AuthError, rhs: AuthError) -> Bool {
        switch (lhs, rhs) {
        case (.invalidEmail, .invalidEmail),
             (.invalidPassword, .invalidPassword),
             (.invalidCredentials, .invalidCredentials),
             (.weakPassword, .weakPassword),
             (.emailAlreadyInUse, .emailAlreadyInUse),
             (.userNotFound, .userNotFound),
             (.requiresRecentLogin, .requiresRecentLogin),
             (.networkError, .networkError),
             (.emailNotVerified, .emailNotVerified),
             (.tooManyRequests, .tooManyRequests),
             (.notImplemented, .notImplemented):
            return true
        case (.unknown(let lhsMessage), .unknown(let rhsMessage)):
            return lhsMessage == rhsMessage
        default:
            return false
        }
    }
}

// MARK: - Support Types
struct AuthCredentials {
    let email: String
    let password: String
}

struct RegistrationData {
    let email: String
    let password: String
    let name: String
}
