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
    func signOut() async throws
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
        // 使用包装类型接收响应
        let response: APIResponse<AuthData> = try await apiClient.request(endpoint)
        let authData = response.data
        
        // 创建用户配置文件
        return UserProfile(
            id: authData.uid,
            displayName: authData.displayName,
            email: authData.email,
            photoURL: authData.photoUrl != nil ? URL(string: authData.photoUrl!) : nil,
            createdAt: Date(),
            lastSeen: Date(),
            authToken: authData.chatToken,
            csrfToken: authData.csrfToken,
            gender: authData.gender,
            bio: authData.bio,
            chatID: authData.chatID,
            chatUrl: authData.chatUrl
        )
    }
    
    func checkSession() async throws -> Bool {
        do {
            let response: APIResponse<SessionStatus> = try await apiClient.request(.checkSession)
            
            // 如果成功解析并且uid不为空，则认为会话有效
            return response.code == 0 && !response.data.uid.isEmpty
        } catch APIError.unauthorized {
            return false
        } catch {
            Logger.error("会话检查错误: \(error.localizedDescription)")
            return false
        }
    }
    
    
    func signOut() async throws {
        let _: APIResponse<EmptyResponse> = try await apiClient.request(.signout)
    }
    func updatePassword(currentPassword: String, newPassword: String) async throws {
        // 对于不需要返回数据的请求，使用包装一个空响应
        let _: APIResponse<EmptyResponse> = try await apiClient.request(.updatePassword(currentPassword: currentPassword, newPassword: newPassword))
    }
    
    func deleteAccount(password: String) async throws {
        let _: APIResponse<EmptyResponse> = try await apiClient.request(.deleteAccount(password: password))
    }
    
    // MARK: - 空响应模型
    private struct EmptyResponse: Codable {}
}

// MARK: - Auth Data Models
struct AuthData: Codable {
    let csrfToken: String
    let chatToken: String
    let uid: String
    let displayName: String
    let photoUrl: String?
    let email: String
    let gender: String?
    let bio: String?
    let session: String?
    let chatID: [String]?
    let chatUrl: String?
    
    enum CodingKeys: String, CodingKey {
        case csrfToken = "csrf_token"
        case chatToken = "chat_token"
        case uid = "uid"
        case displayName = "display_name"
        case photoUrl = "photo_url"
        case email = "email"
        case gender = "gender"
        case bio = "bio"
        case session = "session"
        case chatID = "chat_id"
        case chatUrl = "chat_url"
    }
}

struct SessionStatus: Codable {
    // 使用与API响应匹配的字段
    let csrfToken: String
    let chatToken: String
    let uid: String
    let displayName: String
    let photoUrl: String?
    let email: String
    let gender: String?
    let bio: String?
    let chatID: [String]?
    let chatUrl: String?
    
    enum CodingKeys: String, CodingKey {
        case csrfToken = "csrf_token"
        case chatToken = "chat_token"
        case uid
        case displayName = "display_name"
        case photoUrl = "photo_url"
        case email
        case gender
        case bio
        case chatID = "chat_id"
        case chatUrl = "chat_url"
    }
}
