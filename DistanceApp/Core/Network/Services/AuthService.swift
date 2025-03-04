//
//  AuthService.swift
//  DistanceApp
//
//  Created by toyousoft on 2025/03/03.
//

//
//  AuthService.swift
//  DistanceApp
//

import Foundation

// MARK: - Auth Service Protocol
protocol AuthServiceProtocol {
    func loginWithFirebaseToken(_ idToken: String) async throws -> UserProfile
    func checkSession() async throws -> Bool
    func updatePassword(currentPassword: String, newPassword: String) async throws
    func deleteAccount(password: String) async throws
}

// MARK: - Auth Service Implementation
final class AuthService: AuthServiceProtocol {
    // MARK: - Dependencies
    private let apiClient: APIClientProtocol
    
    // MARK: - Initialization
    init(apiClient: APIClientProtocol) {
        self.apiClient = apiClient
    }
    
    // MARK: - Auth Methods
    func loginWithFirebaseToken(_ idToken: String) async throws -> UserProfile {
        let endpoint = APIEndpoint.loginWithFirebaseToken(idToken: idToken)
        let authData: AuthData = try await apiClient.request(endpoint)
        
        // 创建用户配置文件 - 业务逻辑移到这里
        return UserProfile(
            id: authData.uid,
            displayName: authData.displayName,
            email: authData.email,
            photoURL: authData.photoUrl != nil ? URL(string: authData.photoUrl!) : nil,
            createdAt: Date(),
            lastSeen: Date(),
            authToken: authData.chatToken,
            csrfToken: authData.csrfToken
        )
    }
    
    func checkSession() async throws -> Bool {
        do {
            let response: SessionStatus = try await apiClient.request(.checkSession)
            return response.isValid
        } catch APIError.unauthorized {
            return false
        } catch {
            Logger.error("会话检查错误: \(error.localizedDescription)")
            return false
        }
    }
    
    func updatePassword(currentPassword: String, newPassword: String) async throws {
        try await apiClient.request(.updatePassword(currentPassword: currentPassword, newPassword: newPassword))
    }
    
    func deleteAccount(password: String) async throws {
        try await apiClient.request(.deleteAccount(password: password))
    }
}

// MARK: - Auth Data Models
struct AuthData: Codable {
    let csrfToken: String
    let chatToken: String
    let uid: String
    let displayName: String
    let photoUrl: String?
    let email: String
    
    enum CodingKeys: String, CodingKey {
        case csrfToken = "csrf_token"
        case chatToken = "chat_token"
        case uid = "uid"
        case displayName = "display_name"
        case photoUrl = "photo_url"
        case email = "email"
    }
}

struct SessionStatus: Codable {
    let isValid: Bool
    let message: String?
}
