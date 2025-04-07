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
        
        // 获取图片路径数组
        let imagePaths = topicImages ?? []
        
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
            images: topicImages ?? [],
            firebaseImagePaths: imagePaths  // 新增字段，保存原始路径
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

// 创建话题响应
// 在PostService.swift中替换CreateTopicResponse结构体

struct CreateTopicResponse: Codable {
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
    let expiresAt: String
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
}

// 空响应模型
struct EmptyResponse: Codable {}

// 话题创建请求模型
struct CreateTopicRequest: Encodable {
    let uid: String  // 添加前台生成的唯一ID
    let title: String
    let content: String
    let images: [String]
    let tags: [String]
    let latitude: Double?
    let longitude: Double?
    let expiresAt: Date
    
    // 自定义编码
    enum CodingKeys: String, CodingKey {
        case uid
        case title
        case content
        case images
        case tags
        case latitude
        case longitude
        case expiresAt = "expires_at"
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(uid, forKey: .uid)  // 编码新增的uid字段
        try container.encode(title, forKey: .title)
        try container.encode(content, forKey: .content)
        try container.encode(images, forKey: .images)
        try container.encode(tags, forKey: .tags)
        
        // 编码可选字段
        if let latitude = latitude {
            try container.encode(latitude, forKey: .latitude)
        }
        
        if let longitude = longitude {
            try container.encode(longitude, forKey: .longitude)
        }
        
        // 格式化日期
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        let dateString = formatter.string(from: expiresAt)
        try container.encode(dateString, forKey: .expiresAt)
    }
}
// MARK: - PostService 协议
protocol PostServiceProtocol {
    func getTopics(findby: String, max: Int, recency: Int) async throws -> [Topic]
    func getTrendingTopics(max: Int) async throws -> [Topic]
    func getLastResponseScore() -> Int?
    
    // 新增发布话题方法
    func createTopic(_ request: CreateTopicRequest) async throws
    
    // 点赞相关方法
    func likeTopic(id: String) async throws
    func unlikeTopic(id: String) async throws
}


// MARK: - PostService 实现
final class PostService: PostServiceProtocol {
    // MARK: - 依赖
    private let apiClient: APIClientProtocol
    
    // 存储最后一次响应中的score值
    private var lastResponseScore: Int?
    
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
        do {
            // 调用API获取话题列表
            let endpoint = APIEndpoint.getTopics(findby: findby, max: max, recency: recency)
            let response: TopicsResponse = try await apiClient.request(endpoint)
            
            // 确保响应状态码正确
            guard response.code == 0 else {
                Logger.error("API返回错误码: \(response.code), 消息: \(response.message)")
                throw PostError.apiError(response.message)
            }
            
            // 存储score值以便后续使用
            self.lastResponseScore = response.data.score
            Logger.debug("获取到score值: \(String(describing: response.data.score))")
            
            // 转换为视图模型数据
            let topics = response.data.topics.map { $0.toTopic() }
            Logger.debug("成功解析话题数据，共\(topics.count)条")
            
            return topics
        } catch let decodingError as DecodingError {
            // 详细记录解码错误信息
            Logger.error("话题数据解码失败: \(decodingError)")
            throw PostError.decodingError(decodingError)
        } catch {
            Logger.error("获取话题失败: \(error.localizedDescription)")
            throw PostError.networkError(error)
        }
    }
    
    /// 获取热门话题
    /// - Parameter max: 获取数量
    /// - Returns: 转换后的Topic数组
    func getTrendingTopics(max: Int = 10) async throws -> [Topic] {
        // 获取热门话题，使用与recent相同的接口，但查询参数可能不同
        // 这里使用"recent"而不是"trending"，确保与后端API一致
        return try await getTopics(findby: "recent", max: max, recency: 0)
    }
    
    /// 获取最后一次响应中的score值
    /// - Returns: score值，如果没有则返回nil
    func getLastResponseScore() -> Int? {
        return lastResponseScore
    }
    
    // MARK: - 新增方法：创建话题
    
    /// 创建新话题
    /// - Parameter request: 创建话题请求
    func createTopic(_ request: CreateTopicRequest) async throws {
        // 构造API端点
        let endpoint = APIEndpoint.createTopic(request: request)
        
        do {
            // 发送创建话题请求
            let response: APIResponse<CreateTopicResponse> = try await apiClient.request(endpoint)
            
            // 验证响应
            guard response.code == 0 else {
                Logger.error("创建话题API返回错误: \(response.code), 消息: \(response.message)")
                throw PostError.apiError(response.message)
            }
            
            // 记录成功
            Logger.info("话题创建成功，ID: \(response.data.uid)")
            
        } catch let apiError as APIError {
            Logger.error("创建话题失败 (API错误): \(apiError.localizedDescription)")
            throw PostError.networkError(apiError)
        } catch {
            Logger.error("创建话题失败 (未知错误): \(error.localizedDescription)")
            throw PostError.networkError(error)
        }
    }
    
    // MARK: - 新增方法：点赞相关
    
    /// 点赞话题
    /// - Parameter id: 话题ID
    func likeTopic(id: String) async throws {
        do {
            // 构造API端点
            let endpoint = APIEndpoint.likeTopic(id: id)
            
            // 发送请求
            let response: APIResponse<EmptyResponse> = try await apiClient.request(endpoint)
            
            // 验证响应
            guard response.code == 0 else {
                Logger.error("点赞话题API返回错误: \(response.code), 消息: \(response.message)")
                throw PostError.apiError(response.message)
            }
            
            Logger.debug("话题点赞成功，ID: \(id)")
            
        } catch {
            Logger.error("话题点赞失败: \(error.localizedDescription)")
            throw PostError.networkError(error)
        }
    }
    
    /// 取消点赞话题
    /// - Parameter id: 话题ID
    func unlikeTopic(id: String) async throws {
        do {
            // 构造API端点
            let endpoint = APIEndpoint.unlikeTopic(id: id)
            
            // 发送请求
            let response: APIResponse<EmptyResponse> = try await apiClient.request(endpoint)
            
            // 验证响应
            guard response.code == 0 else {
                Logger.error("取消点赞话题API返回错误: \(response.code), 消息: \(response.message)")
                throw PostError.apiError(response.message)
            }
            
            Logger.debug("取消话题点赞成功，ID: \(id)")
            
        } catch {
            Logger.error("取消话题点赞失败: \(error.localizedDescription)")
            throw PostError.networkError(error)
        }
    }
}

// MARK: - 错误类型
enum PostError: LocalizedError {
    case apiError(String)
    case invalidResponse
    case networkError(Error)
    case decodingError(Error)
    case invalidInput(String)
    case imageUploadFailed
    
    var errorDescription: String? {
        switch self {
        case .apiError(let message):
            return "API错误: \(message)"
        case .invalidResponse:
            return "无效的响应数据"
        case .networkError(let error):
            return "网络错误: \(error.localizedDescription)"
        case .decodingError(let error):
            return "数据解析错误: \(error.localizedDescription)"
        case .invalidInput(let message):
            return "输入错误: \(message)"
        case .imageUploadFailed:
            return "图片上传失败"
        }
    }
}
