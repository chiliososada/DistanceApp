//
//  ProfileService.swift
//  DistanceApp
//
//  Created on 2025/03/10.
//

//
//  ProfileService.swift
//  DistanceApp
//
//  Created on 2025/03/10.
//

import Foundation
import UIKit

// MARK: - Profile Service Protocol
protocol ProfileServiceProtocol {
    func updateProfile(displayName: String, gender: String?, bio: String?, profileImage: UIImage?) async throws -> UserProfile
}

// MARK: - Profile Service Implementation
final class ProfileService: ProfileServiceProtocol {
    // Constants
    private enum Constants {
        static let profileImageMaxSize: CGFloat = 1024 // 最大尺寸限制为1024px
        static let profileImageCompressionQuality: CGFloat = 0.7 // 图片压缩质量
    }
    // MARK: - Dependencies
    private let apiClient: APIClientProtocol
    private let fileStorageManager: FileStorageManagerProtocol
    
    // MARK: - Initialization
    init(
        apiClient: APIClientProtocol,
        fileStorageManager: FileStorageManagerProtocol
    ) {
        self.apiClient = apiClient
        self.fileStorageManager = fileStorageManager
    }
    
    // MARK: - Profile Methods
    func updateProfile(displayName: String, gender: String?, bio: String?, profileImage: UIImage?) async throws -> UserProfile {
        // 准备请求参数
        var params: [String: Any] = [
            "display_name": displayName
        ]
        
        // 添加可选参数
        if let gender = gender {
            params["gender"] = gender
        }
        
        if let bio = bio {
            params["bio"] = bio
        }
        
        // 如果有新头像，先上传图片
        if let profileImage = profileImage {
            let imageURL = try await uploadProfileImage(profileImage)
            params["photo_url"] = imageURL
        }
        
        // 构造API请求端点
        let endpoint = APIEndpoint.updateProfile(params: params)
        
        // 发送请求
        let response: APIResponse<ProfileUpdateResponse> = try await apiClient.request(endpoint)
        
        // 构造并返回更新后的用户资料
        return UserProfile(backendProfile: response.data.profile)
    }
    
    // 上传头像图片
    private func uploadProfileImage(_ image: UIImage) async throws -> String {
        // 处理图片尺寸
        let processedImage = resizeImageIfNeeded(image)
        
        // 构造上传请求
        // 实际项目中需要调用图片上传API
        
        // 临时：保存到本地并返回假URL
        if let imageName = fileStorageManager.saveImage(processedImage, withName: "profile_\(Date().timeIntervalSince1970)", toDirectory: "profiles") {
            // TODO: 实现真正的图片上传API调用，获取返回的URL
            return "profiles/\(imageName).jpg"
        } else {
            throw ProfileError.imageUploadFailed
        }
    }
    
    // 调整图片尺寸
    private func resizeImageIfNeeded(_ image: UIImage) -> UIImage {
        let maxSize = Constants.profileImageMaxSize
        
        // 检查图片尺寸是否需要调整
        let width = image.size.width
        let height = image.size.height
        
        if width <= maxSize && height <= maxSize {
            return image  // 尺寸已经合适，不需要调整
        }
        
        // 计算新尺寸，保持原始比例
        var newWidth: CGFloat
        var newHeight: CGFloat
        
        if width > height {
            newWidth = maxSize
            newHeight = height * maxSize / width
        } else {
            newHeight = maxSize
            newWidth = width * maxSize / height
        }
        
        // 创建新的图片尺寸
        let size = CGSize(width: newWidth, height: newHeight)
        
        // 使用UIGraphicsImageRenderer重新绘制图片
        let renderer = UIGraphicsImageRenderer(size: size)
        let resizedImage = renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: size))
        }
        
        return resizedImage
    }
}

// MARK: - Response Models
struct ProfileUpdateResponse: Codable {
    let profile: BackendUserProfile
}

// MARK: - Error Type
enum ProfileError: LocalizedError {
    case imageUploadFailed
    case invalidResponse
    case updateFailed(String)
    
    var errorDescription: String? {
        switch self {
        case .imageUploadFailed:
            return "头像上传失败"
        case .invalidResponse:
            return "服务器响应无效"
        case .updateFailed(let message):
            return "资料更新失败: \(message)"
        }
    }
}
