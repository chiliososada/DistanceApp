//
//  SceneDelegate.swift
//  DistanceApp
//
//  Created by toyousoft on 2025/03/03.
//

import UIKit
import SwiftUI

// 用于处理应用程序场景生命周期，支持多窗口
class SceneDelegate: NSObject, UIWindowSceneDelegate {
    var window: UIWindow?
    
    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = scene as? UIWindowScene else { return }
        
        window = UIWindow(windowScene: windowScene)
        
        // 设置根视图控制器
        let appView = DistanceApp.ContentView()
            .environmentObject(AppEnvironment.shared)
        
        let hostingController = UIHostingController(rootView: appView)
        window?.rootViewController = hostingController
        window?.makeKeyAndVisible()
        
        // 处理通知点击等启动选项
        handleConnectionOptions(connectionOptions)
    }
    
    func sceneDidDisconnect(_ scene: UIScene) {
        // 场景断开连接时调用
        // 可以在这里执行资源清理，保存用户数据等
        Logger.info("场景断开连接")
    }
    
    func sceneDidBecomeActive(_ scene: UIScene) {
        // 场景变为活跃状态时调用
        Logger.info("场景变为活跃")
        
        // 用户活跃状态更新
        Task {
            do {
                try await AppEnvironment.shared.authManager.updateUserActiveStatus(true)
            } catch {
                Logger.error("更新用户活跃状态失败: \(error.localizedDescription)")
            }
        }
    }
    
    func sceneWillResignActive(_ scene: UIScene) {
        // 场景即将变为非活跃状态时调用
        Logger.info("场景即将变为非活跃")
        
        // 用户非活跃状态更新
        Task {
            do {
                try await AppEnvironment.shared.authManager.updateUserActiveStatus(false)
            } catch {
                Logger.error("更新用户非活跃状态失败: \(error.localizedDescription)")
            }
        }
    }
    
    func sceneWillEnterForeground(_ scene: UIScene) {
        // 场景将进入前台时调用
        Logger.info("场景将进入前台")
    }
    
    func sceneDidEnterBackground(_ scene: UIScene) {
        // 场景进入后台时调用
        Logger.info("场景进入后台")
    }
    
    // MARK: - Private Methods
    
    private func handleConnectionOptions(_ options: UIScene.ConnectionOptions) {
        // 处理各种启动选项
        
        // 处理推送通知
        if let notification = options.notificationResponse {
            handleNotification(notification)
        }
        
        // 处理URL打开
        if let url = options.urlContexts.first?.url {
            handleURL(url)
        }
    }
    
    private func handleNotification(_ response: UNNotificationResponse) {
        // 处理通知点击逻辑
        Logger.info("处理通知: \(response.notification.request.content.userInfo)")
    }
    
    private func handleURL(_ url: URL) {
        // 处理URL打开逻辑
        Logger.info("处理URL: \(url)")
    }
}

// 这里定义一个简单的Logger，后续会在Utils/Logger.swift中详细实现
struct Logger {
    static func info(_ message: String) {
        print("INFO: \(message)")
    }
    
    static func error(_ message: String) {
        print("ERROR: \(message)")
    }
}
