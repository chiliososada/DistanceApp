//
//  SessionManager.swift
//  DistanceApp
//
//  Created by toyousoft on 2025/03/03.
//

import Foundation
import Combine

// MARK: - Protocol
protocol SessionManagerProtocol {
    func updateSessionWithToken(idToken: String, profile: UserProfile) async
    func updateSession(user: UserProfile?) async
    func getSavedProfile() -> UserProfile?
    func clearSession() async
    func getAuthToken() -> String?
    func savePushToken(_ token: String)
    func getPushToken() -> String?
    func isSessionValid() -> Bool
    func shouldRefreshProfile() -> Bool
}

// MARK: - Implementation
final class SessionManager: SessionManagerProtocol {
    // MARK: - Dependencies
    private let keychainManager: KeychainManagerProtocol
    private let storageManager: StorageManagerProtocol
    
    // MARK: - Constants
    private enum Keys {
        static let authToken = "auth_token"
        static let userProfile = "user_profile"
        static let lastLoginDate = "last_login_date"
        static let pushToken = "push_notification_token"
    }
    
    // MARK: - Initialization
    init(
        keychainManager: KeychainManagerProtocol,
        storageManager: StorageManagerProtocol
    ) {
        self.keychainManager = keychainManager
        self.storageManager = storageManager
    }
    
    // MARK: - Session Management
    
    /// 使用idToken和用户配置文件更新会话
    func updateSessionWithToken(idToken: String, profile: UserProfile) async {
        // 保存token到keychain
        try? keychainManager.saveSecureString(idToken, forKey: Keys.authToken)
        
        // 保存用户配置文件
        await updateSession(user: profile)
    }
    
    /// 更新会话信息，主要保存用户配置文件
    func updateSession(user: UserProfile?) async {
        if let user = user {
            // 保存用户配置文件到存储管理器
            storageManager.saveObject(user, forKey: Keys.userProfile)
            
            // 记录最后登录时间
            storageManager.saveObject(Date(), forKey: Keys.lastLoginDate)
        }
    }
    
    /// 获取保存的用户配置文件
    func getSavedProfile() -> UserProfile? {
        return storageManager.getObject(UserProfile.self, forKey: Keys.userProfile)
    }
    
    /// 清除会话数据
    func clearSession() async {
        // 清除本地存储的用户数据
        storageManager.removeObject(forKey: Keys.userProfile)
        storageManager.removeObject(forKey: Keys.lastLoginDate)
        
        // 清除认证token
        try? keychainManager.deleteSecureData(forKey: Keys.authToken)
    }
    
    /// 获取认证token
    func getAuthToken() -> String? {
        return try? keychainManager.getSecureString(forKey: Keys.authToken)
    }
    
    /// 保存推送通知令牌
    func savePushToken(_ token: String) {
        storageManager.saveString(token, forKey: Keys.pushToken)
    }
    
    /// 获取推送通知令牌
    func getPushToken() -> String? {
        return storageManager.getString(forKey: Keys.pushToken)
    }
    
    /// 判断会话是否有效 (简化，仅做基本检查)
    func isSessionValid() -> Bool {
        return getAuthToken() != nil && getSavedProfile() != nil
    }
    
    /// 判断用户配置是否需要更新
    func shouldRefreshProfile() -> Bool {
        guard let lastLogin = storageManager.getObject(Date.self, forKey: Keys.lastLoginDate) else {
            return true
        }
        // 如果最后登录时间超过24小时，建议刷新配置
        return Date().timeIntervalSince(lastLogin) > 24 * 60 * 60
    }
}
