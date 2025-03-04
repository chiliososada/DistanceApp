//
//  APIClient.swift
//  DistanceApp
//

import Foundation
import Combine

// MARK: - Protocol
protocol APIClientProtocol {
    // 只提供通用的网络请求方法
    func request<T: Codable>(_ endpoint: APIEndpoint) async throws -> T
    func request(_ endpoint: APIEndpoint) async throws
}

// MARK: - Implementation
final class APIClient: APIClientProtocol {
    // MARK: - Properties
    private let baseURL: String
    private let sessionManager: SessionManagerProtocol
    private let timeoutInterval: TimeInterval = 30
    private let maxRetries = 2
    
    // MARK: - 空响应
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
