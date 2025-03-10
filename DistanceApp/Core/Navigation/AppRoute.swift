//
//  AppRoute.swift
//  DistanceApp
//

import Foundation

/// 应用程序导航路由
enum AppRoute: Hashable {
    // 认证相关路由
    case login
    case register
    case forgotPassword
    case verifyEmail
    
    // 主要功能路由 - 可以根据需要扩展
    case home
    case profile
    case settings
    
    // 设置相关路由
    case changePassword
    case accountSettings
    case deleteAccount
    // 在AppRoute枚举中添加
    case completeProfile  // 添加这一行
}

// 路由标题扩展
extension AppRoute {
    var title: String {
        switch self {
        case .login:
            return "登录"
        case .register:
            return "注册"
        case .forgotPassword:
            return "找回密码"
        case .verifyEmail:
            return "验证邮箱"
            // 在title计算属性中添加
        case .completeProfile:
           return "完善个人信息"
        case .home:
            return "首页"
        case .profile:
            return "个人资料"
        case .settings:
            return "设置"
        case .changePassword:
            return "修改密码"
        case .accountSettings:
            return "账户设置"
        case .deleteAccount:
            return "删除账户"
        }
    }
}
