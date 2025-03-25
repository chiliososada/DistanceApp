//
//  PostService.swift
//  DistanceApp
//
//  Created on 2025/03/25.
//

import Foundation
import Combine

// MARK: - 话题相关数据模型
// 话题用户信息模型
struct TopicUserResponse: Codable {
    let nickname: String
    let avatarUrl: String?
    let gender: String?
    let locationLatitude: Double?
    let locationLongitude: Double?
    
    enum CodingKeys: String, CodingKey {
        case nickname
        case avatarUrl = "avatar_url"
        case gender
        case locationLatitude = "location_latitude"
        case locationLongitude = "location_longitude"
    }
}

// 话题响应数据模型
struct TopicResponse: Codable {
    let uid: String
    let createdAt: String
    let updatedAt: String
    let userUid: String
    let title: String
    let content: String
    let locationLatitude: Double?
    let locationLongitude: Double?
    let likesCount: Int
    let participantsCount: Int
    let viewsCount: Int
    let sharesCount: Int
    let expiresAt: String?
    let status: String
    let user: TopicUserResponse
    let topicImages: [String]?
    let tags: [String]?
    let chatId: String?
    
    enum CodingKeys: String, CodingKey {
        case uid
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case userUid = "user_uid"
        case title
        case content
        case locationLatitude = "location_latitude"
        case locationLongitude = "location_longitude"
        case likesCount = "likes_count"
        case participantsCount = "participants_count"
        case viewsCount = "views_count"
        case sharesCount = "shares_count"
        case expiresAt = "expires_at"
        case status
        case user
        case topicImages = "topic_images"
        case tags
        case chatId = "chat_id"
    }
    
    // 转换为视图层使用的Topic模型
    func toTopic() -> Topic {
        // 计算相对时间
        let postedTime = formatRelativeTime(from: createdAt)
        
        // 计算距离（实际应用中应该基于用户位置计算）
        let distance = calculateDistance()
        
        // 推导位置描述
        let location = deriveLocationName()
        
        return Topic(
            id: uid,
            title: title,
            content: content,
            authorName: user.nickname,
            location: location,
            tags: tags ?? [],
            participantsCount: participantsCount,
            postedTime: postedTime,
            distance: distance,
            isLiked: likesCount > 0, // 这里简单处理，实际可能需要单独API判断
            images: topicImages ?? []
        )
    }
    
    // 格式化相对时间
    private func formatRelativeTime(from dateString: String) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        
        guard let date = formatter.date(from: dateString) else {
            return "未知时间"
        }
        
        let now = Date()
        let components = Calendar.current.dateComponents([.minute, .hour, .day], from: date, to: now)
        
        if let day = components.day, day > 0 {
            return day == 1 ? "昨天" : "\(day)天前"
        } else if let hour = components.hour, hour > 0 {
            return "\(hour)小时前"
        } else if let minute = components.minute, minute > 0 {
            return "\(minute)分钟前"
        } else {
            return "刚刚"
        }
    }
    
    // 计算距离（示例实现）
    private func calculateDistance() -> Double {
        guard let lat = locationLatitude, let lng = locationLongitude else {
            return 0.0
        }
        
        // 这里可以实现实际的距离计算，目前返回一个模拟值
        // 实际应用中应该使用用户当前位置和话题位置计算
        return Double(Int.random(in: 1...50)) / 10.0
    }
    
    // 推导位置名称（示例实现）
    private func deriveLocationName() -> String {
        // 实际应用中应该使用反向地理编码获取地址
        if locationLatitude != nil && locationLongitude != nil {
            return "东京都 新宿区"
        } else {
            return "未知位置"
        }
    }
}

// 话题列表响应
struct TopicsListResponse: Codable {
    let topics: [TopicResponse]
    let score: Int?
}

// 完整API响应包装
struct TopicsResponse: Codable {
    let code: Int
    let message: String
    let data: TopicsListResponse
}

// MARK: - PostService 协议
protocol PostServiceProtocol {
    func getTopics(findby: String, max: Int, recency: Int) async throws -> [Topic]
    func getTrendingTopics(max: Int) async throws -> [Topic]
}

// MARK: - PostService 实现
final class PostService: PostServiceProtocol {
    // MARK: - 依赖
    private let apiClient: APIClientProtocol
    
    // MARK: - 初始化
    init(apiClient: APIClientProtocol) {
        self.apiClient = apiClient
    }
    
    // MARK: - 话题相关方法
    
    /// 获取话题列表
    /// - Parameters:
    ///   - findby: 查找方式，如"recent"、"trending"等
    ///   - max: 最大返回数量
    ///   - recency: 时间标记，用于分页
    /// - Returns: 转换后的Topic数组
    func getTopics(findby: String, max: Int, recency: Int) async throws -> [Topic] {
        // 调用API获取话题列表
        let endpoint = APIEndpoint.getTopics(findby: findby, max: max, recency: recency)
        let response: TopicsResponse = try await apiClient.request(endpoint)
        
        // 确保响应状态码正确
        guard response.code == 0 else {
            throw PostError.apiError(response.message)
        }
        
        // 转换为视图模型数据
        return response.data.topics.map { $0.toTopic() }
    }
    
    /// 获取热门话题
    /// - Parameter max: 获取数量
    /// - Returns: 转换后的Topic数组
    func getTrendingTopics(max: Int = 10) async throws -> [Topic] {
        // 获取热门话题，使用trending查找方式
        return try await getTopics(findby: "recent", max: max, recency: 0)
    }
}

// MARK: - 错误类型
enum PostError: LocalizedError {
    case apiError(String)
    case invalidResponse
    case networkError(Error)
    
    var errorDescription: String? {
        switch self {
        case .apiError(let message):
            return "API错误: \(message)"
        case .invalidResponse:
            return "无效的响应数据"
        case .networkError(let error):
            return "网络错误: \(error.localizedDescription)"
        }
    }
}
