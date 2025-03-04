//
//  AppConfig.swift
//  DistanceApp
//
//  Created by toyousoft on 2025/03/03.
//


import Foundation

/// 应用程序全局配置
struct AppConfig {
    // MARK: - API Configuration
    static let apiBaseURL = "https://api.distance.example.com"
    static let apiVersion = "v1"
    
    // MARK: - App Settings
    static let appName = "Distance"
    static let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    static let buildNumber = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    
    // MARK: - Feature Flags
    static let enablePushNotifications = true
    static let enableLocationSharing = true
    static let enableOfflineMode = false
    
    // MARK: - UI Configuration
    static let animationDuration: Double = 0.3
    static let defaultCornerRadius: CGFloat = 12.0
    
    // MARK: - Cache Configuration
    static let maxImageCacheSize: Int = 50 * 1024 * 1024 // 50MB
    static let defaultCacheTimeout: TimeInterval = 60 * 60 * 24 // 24 hours
    
    // MARK: - Timeouts
    static let apiRequestTimeout: TimeInterval = 30.0
    static let locationTimeout: TimeInterval = 15.0
}
