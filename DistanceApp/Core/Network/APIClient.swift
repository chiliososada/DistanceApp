//
//  APIClient.swift
//  DistanceApp
//
//  Created by toyousoft on 2025/03/03.
//

import Foundation
import Combine

// MARK: - Protocol
protocol APIClientProtocol {
    func request<T: Codable>(_ endpoint: APIEndpoint) async throws -> T
    func request(_ endpoint: APIEndpoint) async throws
    func loginWithFirebaseToken(_ idToken: String) async throws -> UserProfile
    func checkSession() async throws -> Bool
    func refreshUserProfile() async throws -> UserProfile
    func updateUserStatus(isActive: Bool) async throws
    func updatePassword(currentPassword: String, newPassword: String) async throws
    func deleteAccount(password: String) async throws
}

// MARK: - Implementation
final class APIClient: APIClientProtocol {
    // MARK: - Properties
    private let baseURL: String
    private let sessionManager: SessionManagerProtocol
    private let timeoutInterval: TimeInterval = 30
    private let maxRetries = 2
    
    // MARK: - Response Models
    struct ApiResponse<T: Codable>: Codable {
        let code: Int
        let message: String
        let data: T
    }

    struct AuthData: Codable {
        let csrfToken: String
        let chatToken: String
        let uid: String
        let displayName: String
        let photoUrl: String?
        let email: String
        let gender: String?
        let bio: String?
        let chatID: [String]
        let chatUrl: String
        
        enum CodingKeys: String, CodingKey {
            case csrfToken = "csrf_token"
            case chatToken = "chat_token"
            case uid = "uid"
            case displayName = "display_name"
            case photoUrl = "photo_url"
            case email = "email"
            case gender = "gender"
            case bio = "bio"
            case chatID = "chat_id"
            case chatUrl = "chat_url"
        }
    }
    
    // 处理空响应
    private struct EmptyResponse: Codable {}
    
    // MARK: - Initialization
    init(
        sessionManager: SessionManagerProtocol,
        baseURL: String = AppConfig.apiBaseURL
    ) {
        self.sessionManager = sessionManager
        self.baseURL = baseURL
    }
    
    // MARK: - Public Methods
    func request<T: Codable>(_ endpoint: APIEndpoint) async throws -> T {
        try await performRequest(endpoint, retryCount: 0)
    }
    
    func request(_ endpoint: APIEndpoint) async throws {
        _ = try await request(endpoint) as EmptyResponse
    }
    
    // MARK: - Specialized API Methods
    func loginWithFirebaseToken(_ idToken: String) async throws -> UserProfile {
        let endpoint = APIEndpoint.loginWithFirebaseToken(idToken: idToken)
        return try await parseAuthResponse(from: endpoint)
    }
    
    func checkSession() async throws -> Bool {
        do {
            let response: SessionStatus = try await request(.checkSession)
            return response.isValid
        } catch APIError.unauthorized {
            return false
        } catch {
            Logger.error("Session check error: \(error.localizedDescription)")
            return false
        }
    }
    
    func refreshUserProfile() async throws -> UserProfile {
        return try await request(.refreshUserProfile)
    }
    
    func updateUserStatus(isActive: Bool) async throws {
        try await request(.updateUserStatus(isActive: isActive))
    }
    
    func updatePassword(currentPassword: String, newPassword: String) async throws {
        try await request(.updatePassword(currentPassword: currentPassword, newPassword: newPassword))
    }
    
    func deleteAccount(password: String) async throws {
        try await request(.deleteAccount(password: password))
    }
    
    // MARK: - Private Methods
    private func performRequest<T: Codable>(_ endpoint: APIEndpoint, retryCount: Int) async throws -> T {
        let request = try prepareRequest(for: endpoint)
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            // 调试日志
            logResponse(data: data, response: response)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw APIError.invalidResponse
            }
            
            return try parseResponse(data: data, httpResponse: httpResponse)
            
        } catch let networkError as URLError where shouldRetry(networkError) && retryCount < maxRetries {
            // 网络错误重试
            Logger.warning("网络请求失败，正在重试... (\(retryCount + 1)/\(maxRetries))")
            try await Task.sleep(nanoseconds: UInt64(pow(2.0, Double(retryCount)) * 1_000_000_000))
            return try await performRequest(endpoint, retryCount: retryCount + 1)
        } catch let error as APIError {
            throw error
        } catch {
            throw APIError.networkError(error)
        }
    }
    
    private func prepareRequest(for endpoint: APIEndpoint) throws -> URLRequest {
        guard let url = URL(string: baseURL + endpoint.path) else {
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = endpoint.method.rawValue
        request.allHTTPHeaderFields = endpoint.headers
        request.timeoutInterval = timeoutInterval
        
        // 添加认证令牌
        if let token = sessionManager.getAuthToken() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        // 序列化请求体
        if let body = endpoint.body {
            let encoder = JSONEncoder()
            let data = try encoder.encode(body)
            request.httpBody = data
            
            // 调试日志
            if let bodyString = String(data: data, encoding: .utf8) {
                Logger.debug("Request body: \(bodyString)")
            }
        }
        
        return request
    }
    
    private func parseResponse<T: Codable>(data: Data, httpResponse: HTTPURLResponse) throws -> T {
        // 首先尝试解析为标准API响应
        if let apiResponse = try? JSONDecoder().decode(ApiResponse<T>.self, from: data) {
            if apiResponse.code != 0 {
                throw APIError.serverError(apiResponse.code)
            }
            return apiResponse.data
        }
        
        // 不是标准API响应，根据HTTP状态码处理
        switch httpResponse.statusCode {
        case 200...299:
            do {
                let decoder = JSONDecoder()
                return try decoder.decode(T.self, from: data)
            } catch let decodingError as DecodingError {
                logDecodingError(decodingError)
                throw APIError.decodingError(decodingError)
            }
        case 401:
            throw APIError.unauthorized
        default:
            throw APIError.serverError(httpResponse.statusCode)
        }
    }
    
    private func parseAuthResponse(from endpoint: APIEndpoint) async throws -> UserProfile {
        let request = try prepareRequest(for: endpoint)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        // 调试日志
        logResponse(data: data, response: response)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            throw APIError.serverError(httpResponse.statusCode)
        }
        
        // 尝试使用JSONSerialization先解析，以便更灵活处理
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw APIError.decodingError(NSError(domain: "APIClient", code: 1001, userInfo: [NSLocalizedDescriptionKey: "Failed to parse JSON"]))
        }
        
        // 检查API响应结构
        guard let code = json["code"] as? Int else {
            throw APIError.invalidResponse
        }
        
        // 检查错误
        if code != 0 {
            let message = json["message"] as? String ?? "Unknown error"
            throw APIError.serverError(code)
        }
        
        // 提取data对象
        guard let dataDict = json["data"] as? [String: Any] else {
            throw APIError.invalidResponse
        }
        
        // 提取必要字段
        guard let csrfToken = dataDict["csrf_token"] as? String,
              let uid = dataDict["uid"] as? String,
              let displayName = dataDict["display_name"] as? String,
              let email = dataDict["email"] as? String,
              let chatToken = dataDict["chat_token"] as? String else {
            throw APIError.invalidResponse
        }
        
        // 提取可选字段
        let photoUrl = dataDict["photo_url"] as? String
        let gender = dataDict["gender"] as? String
        let bio = dataDict["bio"] as? String
        let chatID = dataDict["chat_id"] as? [String] ?? []
        let chatUrl = dataDict["chat_url"] as? String ?? ""
        
        // 创建后端配置文件
        let backendProfile = BackendUserProfile(
            csrfToken: csrfToken,
            uid: uid,
            displayName: displayName,
            photoUrl: photoUrl,
            email: email,
            gender: gender,
            bio: bio,
            chatToken: chatToken,
            chatID: chatID,
            chatUrl: chatUrl
        )
        
        // 创建用户配置文件
        return UserProfile(backendProfile: backendProfile)
    }
    
    private func shouldRetry(_ error: URLError) -> Bool {
        switch error.code {
        case .timedOut, .networkConnectionLost, .notConnectedToInternet:
            return true
        default:
            return false
        }
    }
    
    // MARK: - Logging Helpers
    private func logResponse(data: Data, response: URLResponse) {
        #if DEBUG
        if let responseString = String(data: data, encoding: .utf8) {
            Logger.debug("Raw response: \(responseString)")
        }
        
        if let httpResponse = response as? HTTPURLResponse {
            Logger.debug("HTTP Status Code: \(httpResponse.statusCode)")
        }
        #endif
    }
    
    private func logDecodingError(_ error: DecodingError) {
        switch error {
        case .keyNotFound(let key, let context):
            Logger.error("Decoding error: Key not found '\(key.stringValue)', path: \(context.codingPath.map { $0.stringValue })")
        case .valueNotFound(let type, let context):
            Logger.error("Decoding error: Value not found for type \(type), path: \(context.codingPath.map { $0.stringValue })")
        case .typeMismatch(let type, let context):
            Logger.error("Decoding error: Type mismatch, expected \(type), path: \(context.codingPath.map { $0.stringValue })")
        case .dataCorrupted(let context):
            Logger.error("Decoding error: Data corrupted, \(context)")
        @unknown default:
            Logger.error("Unknown decoding error: \(error)")
        }
    }
}

// MARK: - Support Model
struct SessionStatus: Codable {
    let isValid: Bool
    let message: String?
}
