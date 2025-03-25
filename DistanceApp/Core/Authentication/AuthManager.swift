//
//  AuthManager.swift
//  DistanceApp
//

import Foundation
import Combine
import FirebaseAuth
import UIKit

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
    
    // 个人资料更新
    func updateProfile(displayName: String, gender: String?, bio: String?, profileImage: UIImage?) async throws
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
    private let authService: AuthServiceProtocol
    private let sessionManager: SessionManagerProtocol
    private let keychainManager: KeychainManagerProtocol
    private let profileService: ProfileServiceProtocol
    private var stateListener: AuthStateDidChangeListenerHandle?
    
    private let authStateSubject = PassthroughSubject<Bool, Never>()
    var authStatePublisher: AnyPublisher<Bool, Never> {
        authStateSubject.eraseToAnyPublisher()
    }
    
    // MARK: - Initialization
    init(
        authService: AuthServiceProtocol,
        sessionManager: SessionManagerProtocol,
        keychainManager: KeychainManagerProtocol,
        profileService: ProfileServiceProtocol
    ) {
        self.authService = authService
        self.sessionManager = sessionManager
        self.keychainManager = keychainManager
        self.profileService = profileService
        setupAuthStateListener()
    }
    
    // 为了兼容现有代码，添加不包含profileService的init方法
    convenience init(
        authService: AuthServiceProtocol,
        sessionManager: SessionManagerProtocol,
        keychainManager: KeychainManagerProtocol
    ) {
        // 创建一个文件存储管理器
        let fileStorageManager = FileStorageManager()
        
        // 创建一个ProfileService
        let apiClient = APIClient(sessionManager: sessionManager)
        let profileService = ProfileService(apiClient: apiClient, fileStorageManager: fileStorageManager)
        
        self.init(
            authService: authService,
            sessionManager: sessionManager,
            keychainManager: keychainManager,
            profileService: profileService
        )
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
            let isValid = try await authService.checkSession()
            
            if isValid {
                // 如果会话有效，确保加载用户配置文件
                if let profile = sessionManager.getSavedProfile() {
                    self.userProfile = profile
                    
                    // 检查用户资料是否完整
                    if profile.displayName.isEmpty {
                        // 用户资料不完整，但会话有效
                        // 不清除会话，让用户能够完善资料
                        throw AuthError.profileIncomplete
                    }
                    
                    self.authStateSubject.send(true)
                    return true
                    
                } else if sessionManager.shouldRefreshProfile() {
                    // 如果需要刷新用户配置文件
                    let profile = try await getCurrentUserProfile()
                    await sessionManager.updateSession(user: profile)
                    self.userProfile = profile
                    
                    // 检查用户资料是否完整
                    if profile.displayName.isEmpty {
                        throw AuthError.profileIncomplete
                    }
                    
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
            // 如果是profileIncomplete错误，我们不清除session
            if case AuthError.profileIncomplete = error {
                throw error
            }
            
            // 其他错误时，保守处理为会话无效
            await sessionManager.clearSession()
            self.userProfile = nil
            self.authStateSubject.send(false)
            throw error
        }
    }
    
    // 获取当前用户资料的辅助方法
    private func getCurrentUserProfile() async throws -> UserProfile {
        // 这里可以调用Firebase获取token再调用后端，或直接使用后端提供的刷新接口
        // 如果authService没有直接的刷新方法，可以考虑从sessionManager获取token，再调用登录接口
        guard let token = sessionManager.getAuthToken() else {
            throw AuthError.requiresRecentLogin
        }
        
        return try await authService.loginWithFirebaseToken(token)
    }
    
    @MainActor
    func signIn(with credentials: AuthCredentials) async throws {
        isLoading = true
        error = nil
        
        defer { isLoading = false }
        
        // 将 Firebase 认证放在单独的函数中，以便使用 defer 确保登出
        func authenticateWithFirebase() async throws -> (User, String) {
            let result = try await auth.signIn(withEmail: credentials.email, password: credentials.password)
            let user = result.user
            
            // 确保无论如何都从 Firebase 登出
            defer {
                do {
                    try auth.signOut()
                    Logger.info("已从Firebase登出，会话将由自己的后台管理")
                } catch {
                    Logger.error("从Firebase登出失败: \(error.localizedDescription)")
                }
            }
            
            // 检查邮箱验证
            if !user.isEmailVerified {
                try await user.sendEmailVerification()
                throw AuthError.emailNotVerified
            }
            
            // 获取 idToken
            let idToken = try await user.getIDToken()
            return (user, idToken)
        }
        
        do {
            // 1. Firebase 认证和获取令牌
            let (_, idToken) = try await authenticateWithFirebase()
           
            // 2. 调用后端API进行真正的登录
            let userProfile = try await authService.loginWithFirebaseToken(idToken)
            
            // 3. 存储session信息
            self.userProfile = userProfile
            await sessionManager.updateSessionWithToken(idToken: idToken, profile: userProfile)
            
            // 4. 检查displayName是否为空
            let shouldCompleteProfile = userProfile.displayName.isEmpty
            
            // 5. 根据个人资料完整性决定后续流程
            if shouldCompleteProfile {
                // 如果需要完善个人信息，抛出特定错误
                throw AuthError.profileIncomplete
            } else {
                // 资料完整时，发布认证成功状态
                self.authStateSubject.send(true)
            }
            
        } catch {
            // 捕获特定错误：如果是需要完善个人信息的错误，直接向上传递
            if case AuthError.profileIncomplete = error {
                throw error
            }
            
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
        
        defer {
            isLoading = false
            
            // 确保无论成功还是失败都尝试登出 Firebase
            if auth.currentUser != nil {
                do {
                    try auth.signOut()
                    Logger.info("注册流程结束，已从 Firebase 登出")
                } catch {
                    Logger.error("注册流程结束，从 Firebase 登出失败: \(error.localizedDescription)")
                }
            }
        }
        
        do {
            // 1. 创建用户
            let result = try await auth.createUser(withEmail: data.email, password: data.password)
            
            // 2. 发送验证邮件
            try await result.user.sendEmailVerification()
            
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
            // 1. 调用后端API登出
                  try await authService.signOut()
                  
                  // 2. 清除session
                  await sessionManager.clearSession()
                  
                  // 3. 清除本地状态
                  self.userProfile = nil
                  
                  // 4. 发布认证状态更新
                  self.authStateSubject.send(false)
            
           
//            if auth.currentUser != nil {
//                try auth.signOut()
//            }
            
       
            
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
            // 调用AuthService而不是APIClient
            try await authService.updatePassword(currentPassword: currentPassword, newPassword: newPassword)
            
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
            // 调用AuthService而不是APIClient
            try await authService.deleteAccount(password: password)
            
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
            // 这个方法需要在AuthService中添加
            // 或者改用APIClient的updateUserStatus方法
            // 这里假设已添加到AuthService
            try await updateActiveStatus(isActive)
        } catch {
            // 非关键错误，只记录日志
            Logger.error("更新用户状态失败: \(error.localizedDescription)")
        }
    }
    
    // 辅助方法 - 当AuthService不包含此功能时使用
    private func updateActiveStatus(_ isActive: Bool) async throws {
        // 这里可以使用注入的APIClient或创建一个UserService来处理
        // 简单起见，这个示例仅记录日志
        Logger.info("用户状态更新为: \(isActive ? "在线" : "离线")")
        // 实际实现应当调用API
    }
    
    // MARK: - 个人资料更新
    @MainActor
    func updateProfile(displayName: String, gender: String?, bio: String?, profileImage: UIImage?) async throws {
        isLoading = true
        error = nil
        
        defer { isLoading = false }
        
        do {
            // 获取当前用户的电子邮件
            guard let email = userProfile?.email else {
                throw AuthError.unknown("无法获取当前用户邮箱")
            }
            
            // 调用个人资料服务更新资料，传入电子邮件
            let updatedProfile = try await profileService.updateProfile(
                email: email,
                displayName: displayName,
                gender: gender,
                bio: bio,
                profileImage: profileImage
            )
            
            // 更新本地保存的用户资料
            self.userProfile = updatedProfile
            await sessionManager.updateSession(user: updatedProfile)
            
            // 发布认证状态更新
            self.authStateSubject.send(true)
            
        } catch {
            self.error = error as? AuthError ?? AuthError.unknown(error.localizedDescription)
            throw self.error!
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
    case profileIncomplete
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
            return "请求频率过高，请稍后再试"
        case .notImplemented:
            return "功能尚未实现"
        case .profileIncomplete:
            return "个人信息不完整，请完善个人资料"
        case .unknown(let message):
            return "错误：\(message)"
        }
    }
    
    // Firebase错误映射
    static func fromFirebaseError(_ error: Error) -> AuthError {
        // 根据错误类型和错误码进行映射
        let nsError = error as NSError
        let errorCode = nsError.code
        
        if let authError = error as? AuthErrorCode {
            switch authError.code {
            case .invalidEmail:
                return .invalidEmail
            case .wrongPassword:
                return .invalidPassword
            case .userNotFound:
                return .userNotFound
            case .emailAlreadyInUse:
                return .emailAlreadyInUse
            case .weakPassword:
                return .weakPassword
            case .requiresRecentLogin:
                return .requiresRecentLogin
            case .tooManyRequests:
                return .tooManyRequests
            default:
                break
            }
        }
        
        // 处理网络错误
        if errorCode == NSURLErrorNotConnectedToInternet {
            return .networkError
        }
        
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
             (.notImplemented, .notImplemented),
             (.profileIncomplete, .profileIncomplete):
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
