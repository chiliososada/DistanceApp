//
//  NetworkError.swift
//  DistanceApp
//
//  Created by toyousoft on 2025/03/03.
//

import Foundation

// MARK: - API Error
enum APIError: LocalizedError {
    case invalidURL
    case invalidResponse
    case networkError(Error)
    case decodingError(Error)
    case serverError(Int)
    case unauthorized
    case noData
    case notFound
    case rateLimited
    case forbidden
    case badRequest(String)
    
    // MARK: - Error Description
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "无效的URL"
        case .invalidResponse:
            return "无效的响应"
        case .networkError(let error):
            return "网络错误: \(error.localizedDescription)"
        case .decodingError(let error):
            return "数据解析错误: \(error.localizedDescription)"
        case .serverError(let code):
            return "服务器错误: \(code)"
        case .unauthorized:
            return "未授权访问，请重新登录"
        case .noData:
            return "没有数据"
        case .notFound:
            return "请求的资源不存在"
        case .rateLimited:
            return "请求频率过高，请稍后再试"
        case .forbidden:
            return "没有权限访问该资源"
        case .badRequest(let message):
            return "请求错误: \(message)"
        }
    }
    
    // MARK: - Recovery Suggestion
    var recoverySuggestion: String? {
        switch self {
        case .networkError:
            return "请检查您的网络连接并重试。"
        case .unauthorized:
            return "您的登录已过期，请重新登录。"
        case .serverError:
            return "请稍后重试，或联系客服支持。"
        case .rateLimited:
            return "请等待一段时间后再尝试。"
        default:
            return nil
        }
    }
    
    // MARK: - From HTTP Status Code
    static func fromStatusCode(_ statusCode: Int, message: String? = nil) -> APIError {
        switch statusCode {
        case 400:
            return .badRequest(message ?? "Bad Request")
        case 401:
            return .unauthorized
        case 403:
            return .forbidden
        case 404:
            return .notFound
        case 429:
            return .rateLimited
        case 500...599:
            return .serverError(statusCode)
        default:
            return .serverError(statusCode)
        }
    }
}
