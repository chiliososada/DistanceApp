//
//  FileStorageManager.swift
//  DistanceApp
//
//  Created by toyousoft on 2025/03/03.
//

import Foundation
import UIKit

// MARK: - Protocol
protocol FileStorageManagerProtocol {
    func saveImage(_ image: UIImage, withName name: String?, toDirectory directory: String?) -> String?
    func loadImage(withName name: String, fromDirectory directory: String?) -> UIImage?
    func deleteImage(withName name: String, fromDirectory directory: String?) -> Bool
    func saveData(_ data: Data, withName name: String, toDirectory directory: String?) -> Bool
    func loadData(withName name: String, fromDirectory directory: String?) -> Data?
    func deleteData(withName name: String, fromDirectory directory: String?) -> Bool
    func getDocumentsDirectory() -> URL
    func getCachesDirectory() -> URL
    func getTemporaryDirectory() -> URL
    func createDirectoryIfNeeded(at path: URL) -> Bool
    func fileExists(at path: URL) -> Bool
    func clearDirectory(_ directory: URL) -> Bool
}

// MARK: - Implementation
final class FileStorageManager: FileStorageManagerProtocol {
    // MARK: - Properties
    private let fileManager = FileManager.default
    
    // MARK: - Directories
    func getDocumentsDirectory() -> URL {
        return fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
    
    func getCachesDirectory() -> URL {
        return fileManager.urls(for: .cachesDirectory, in: .userDomainMask)[0]
    }
    
    func getTemporaryDirectory() -> URL {
        return fileManager.temporaryDirectory
    }
    
    // MARK: - Directory Management
    func createDirectoryIfNeeded(at path: URL) -> Bool {
        do {
            try fileManager.createDirectory(at: path, withIntermediateDirectories: true, attributes: nil)
            return true
        } catch {
            Logger.error("创建目录失败: \(error.localizedDescription)")
            return false
        }
    }
    
    func fileExists(at path: URL) -> Bool {
        return fileManager.fileExists(atPath: path.path)
    }
    
    func clearDirectory(_ directory: URL) -> Bool {
        do {
            let contents = try fileManager.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil)
            for fileURL in contents {
                try fileManager.removeItem(at: fileURL)
            }
            return true
        } catch {
            Logger.error("清理目录失败: \(error.localizedDescription)")
            return false
        }
    }
    
    // MARK: - Image Operations
    func saveImage(_ image: UIImage, withName name: String? = nil, toDirectory directory: String? = nil) -> String? {
        let imageName = name ?? UUID().uuidString
        let fileExtension = "jpg"
        let fileName = "\(imageName).\(fileExtension)"
        
        let directoryURL = getDirectoryURL(directory)
        createDirectoryIfNeeded(at: directoryURL)
        
        let fileURL = directoryURL.appendingPathComponent(fileName)
        
        guard let imageData = image.jpegData(compressionQuality: 0.7) else {
            Logger.error("无法将图像转换为JPEG数据")
            return nil
        }
        
        do {
            try imageData.write(to: fileURL)
            return imageName
        } catch {
            Logger.error("保存图像失败: \(error.localizedDescription)")
            return nil
        }
    }
    
    func loadImage(withName name: String, fromDirectory directory: String? = nil) -> UIImage? {
        let fileExtension = "jpg"
        let fileName = "\(name).\(fileExtension)"
        
        let directoryURL = getDirectoryURL(directory)
        let fileURL = directoryURL.appendingPathComponent(fileName)
        
        guard fileExists(at: fileURL) else {
            Logger.warning("图像文件不存在: \(fileURL.path)")
            return nil
        }
        
        do {
            let imageData = try Data(contentsOf: fileURL)
            return UIImage(data: imageData)
        } catch {
            Logger.error("加载图像失败: \(error.localizedDescription)")
            return nil
        }
    }
    
    func deleteImage(withName name: String, fromDirectory directory: String? = nil) -> Bool {
        let fileExtension = "jpg"
        let fileName = "\(name).\(fileExtension)"
        
        let directoryURL = getDirectoryURL(directory)
        let fileURL = directoryURL.appendingPathComponent(fileName)
        
        guard fileExists(at: fileURL) else {
            return true // 文件不存在，视为删除成功
        }
        
        do {
            try fileManager.removeItem(at: fileURL)
            return true
        } catch {
            Logger.error("删除图像失败: \(error.localizedDescription)")
            return false
        }
    }
    
    // MARK: - Data Operations
    func saveData(_ data: Data, withName name: String, toDirectory directory: String? = nil) -> Bool {
        let directoryURL = getDirectoryURL(directory)
        createDirectoryIfNeeded(at: directoryURL)
        
        let fileURL = directoryURL.appendingPathComponent(name)
        
        do {
            try data.write(to: fileURL)
            return true
        } catch {
            Logger.error("保存数据失败: \(error.localizedDescription)")
            return false
        }
    }
    
    func loadData(withName name: String, fromDirectory directory: String? = nil) -> Data? {
        let directoryURL = getDirectoryURL(directory)
        let fileURL = directoryURL.appendingPathComponent(name)
        
        guard fileExists(at: fileURL) else {
            Logger.warning("数据文件不存在: \(fileURL.path)")
            return nil
        }
        
        do {
            return try Data(contentsOf: fileURL)
        } catch {
            Logger.error("加载数据失败: \(error.localizedDescription)")
            return nil
        }
    }
    
    func deleteData(withName name: String, fromDirectory directory: String? = nil) -> Bool {
        let directoryURL = getDirectoryURL(directory)
        let fileURL = directoryURL.appendingPathComponent(name)
        
        guard fileExists(at: fileURL) else {
            return true // 文件不存在，视为删除成功
        }
        
        do {
            try fileManager.removeItem(at: fileURL)
            return true
        } catch {
            Logger.error("删除数据失败: \(error.localizedDescription)")
            return false
        }
    }
    
    // MARK: - Helper Methods
    private func getDirectoryURL(_ directory: String?) -> URL {
        if let directory = directory {
            return getDocumentsDirectory().appendingPathComponent(directory, isDirectory: true)
        }
        return getDocumentsDirectory()
    }
}
