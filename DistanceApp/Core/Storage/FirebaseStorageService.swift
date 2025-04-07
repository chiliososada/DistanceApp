//
//  FirebaseStorageService.swift
//  DistanceApp
//
//  Created by toyousoft on 2025/04/07.
//

import Foundation
import FirebaseStorage

class FirebaseStorageService {
    // 单例模式
    static let shared = FirebaseStorageService()
    
    private let storage = Storage.storage()
    private var urlCache = NSCache<NSString, NSURL>()
    
    private init() {}
    
    /// 根据相对路径获取Firebase Storage下载URL
    /// - Parameter path: 相对路径，如 "topics/9dcced12-55c2-4940-9ccc-1990fcc084e5/image-1"
    /// - Returns: 可用于下载的URL
    func getImageURL(for path: String) async throws -> URL {
        // 检查缓存
        if let cachedURL = urlCache.object(forKey: path as NSString) {
            return cachedURL as URL
        }
        
        // 获取引用
        let storageRef = storage.reference().child(path)
        
        do {
            // 获取下载URL
            let downloadURL = try await storageRef.downloadURL()
            
            // 缓存URL
            urlCache.setObject(downloadURL as NSURL, forKey: path as NSString)
            
            return downloadURL
        } catch {
            Logger.error("获取图片URL失败: \(path), 错误: \(error.localizedDescription)")
            throw error
        }
    }
    
    /// 获取话题所有图片的URL
    /// - Parameter topicId: 话题ID
    /// - Returns: 图片URL数组
    func getTopicImagesURLs(topicId: String, imageCount: Int) async -> [URL] {
        var urls: [URL] = []
        
        for i in 0..<imageCount {
            let path = "topics/\(topicId)/image-\(i)"
            do {
                let url = try await getImageURL(for: path)
                urls.append(url)
            } catch {
                Logger.warning("获取图片失败: \(path)")
                continue
            }
        }
        
        return urls
    }
}
