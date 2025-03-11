//
//  AppNavigationManager.swift
//  DistanceApp
//

import SwiftUI
import Combine

// 标签页枚举
enum Tab: String, Identifiable, CaseIterable {
    case home, profile, settings
    
    var id: String { self.rawValue }
    
    var icon: String {
        switch self {
        case .home: return "house.fill"
        case .profile: return "person.fill"
        case .settings: return "gear"
        }
    }
    
    var title: String {
        switch self {
        case .home: return "首页"
        case .profile: return "我的"
        case .settings: return "设置"
        }
    }
}

// MARK: - Protocol
protocol NavigationManagerProtocol {
    var navigationPath: NavigationPath { get }
    var isPresentingSheet: Bool { get }
    var selectedTab: Tab { get set }
    
    func navigate(to route: AppRoute)
    func switchTab(to tab: Tab)
    func navigateWithTab(tab: Tab, route: AppRoute)
    func present(_ route: AppRoute)
    func dismiss()
    func popToRoot()
    func goBack()
    func resetNavigation()
}

// MARK: - Implementation
final class AppNavigationManager: ObservableObject, NavigationManagerProtocol {
    // MARK: - Published Properties
    @Published var navigationPath = NavigationPath() // 保留旧路径用于认证流程
    @Published var homeTabPath = NavigationPath() // 首页标签导航路径
    @Published var profileTabPath = NavigationPath() // 个人资料标签导航路径
    @Published var settingsTabPath = NavigationPath() // 设置标签导航路径
    @Published var selectedTab: Tab = .home
    @Published var presentedSheet: AppRoute?
    @Published var isPresentingSheet = false
    @Published var isAuthenticated = false // 添加认证状态跟踪
    
    // MARK: - 当前活动标签的导航路径
    var currentTabPath: NavigationPath {
        get {
            switch selectedTab {
            case .home: return homeTabPath
            case .profile: return profileTabPath
            case .settings: return settingsTabPath
            }
        }
        set {
            switch selectedTab {
            case .home: homeTabPath = newValue
            case .profile: profileTabPath = newValue
            case .settings: settingsTabPath = newValue
            }
        }
    }
    
    // MARK: - Private Properties
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Singleton Instance
    static let shared = AppNavigationManager()
    
    // MARK: - Initialization
    init() {
        setupLogging()
    }
    
    private func setupLogging() {
        // 监听导航路径变化
        $navigationPath
            .dropFirst()
            .sink { _ in Logger.debug("Navigation: Navigation path changed") }
            .store(in: &cancellables)
        
        // 监听标签页选择变化
        $selectedTab
            .dropFirst()
            .sink { Logger.debug("Navigation: Tab selection changed to: \($0)") }
            .store(in: &cancellables)
        
        // 监听弹出表单变化
        $presentedSheet
            .dropFirst()
            .sink { Logger.debug("Navigation: Presented sheet changed to: \(String(describing: $0))") }
            .store(in: &cancellables)
        
        // 监听是否正在显示表单
        $isPresentingSheet
            .dropFirst()
            .sink { Logger.debug("Navigation: isPresentingSheet changed to: \($0)") }
            .store(in: &cancellables)
        
        // 监听各标签页导航路径变化
        $homeTabPath
            .dropFirst()
            .sink { _ in Logger.debug("Navigation: Home tab path changed") }
            .store(in: &cancellables)
        
        $profileTabPath
            .dropFirst()
            .sink { _ in Logger.debug("Navigation: Profile tab path changed") }
            .store(in: &cancellables)
        
        $settingsTabPath
            .dropFirst()
            .sink { _ in Logger.debug("Navigation: Settings tab path changed") }
            .store(in: &cancellables)
    }
    
    // MARK: - Navigation Methods
    func navigate(to route: AppRoute) {
        Logger.info("Navigating to route: \(route)")
        // 确保在主线程执行
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            // 区分认证/未认证状态的导航
            if self.isAuthenticated {
                // 已认证状态：使用标签页导航
                switch self.selectedTab {
                case .home:
                    self.homeTabPath.append(route)
                case .profile:
                    self.profileTabPath.append(route)
                case .settings:
                    self.settingsTabPath.append(route)
                }
            } else {
                // 未认证状态：使用全局导航路径
                self.navigationPath.append(route)
            }
        }
    }
    
    // 切换标签页
    func switchTab(to tab: Tab) {
        Logger.info("Switching to tab: \(tab)")
        selectedTab = tab
    }
    
    // 导航到特定标签页并显示路由
    func navigateWithTab(tab: Tab, route: AppRoute) {
        Logger.info("Navigating to tab: \(tab) with route: \(route)")
        selectedTab = tab
        navigate(to: route)
    }
    
    func present(_ route: AppRoute) {
        Logger.info("Presenting sheet: \(route)")
        presentedSheet = route
        isPresentingSheet = true
    }
    
    func dismiss() {
        Logger.info("Dismissing sheet")
        presentedSheet = nil
        isPresentingSheet = false
    }
    
    func popToRoot() {
        Logger.info("Popping to root")
        if isAuthenticated {
            // 清除当前标签页的导航路径
            switch selectedTab {
            case .home:
                homeTabPath = NavigationPath()
            case .profile:
                profileTabPath = NavigationPath()
            case .settings:
                settingsTabPath = NavigationPath()
            }
        } else {
            // 未认证状态清除全局导航路径
            navigationPath = NavigationPath()
        }
    }
    
    func goBack() {
        Logger.info("Going back")
        if isAuthenticated {
            // 从当前标签页的导航路径中移除最后一项
            switch selectedTab {
            case .home:
                if !homeTabPath.isEmpty {
                    homeTabPath.removeLast()
                }
            case .profile:
                if !profileTabPath.isEmpty {
                    profileTabPath.removeLast()
                }
            case .settings:
                if !settingsTabPath.isEmpty {
                    settingsTabPath.removeLast()
                }
            }
        } else {
            // 未认证状态，从全局导航路径中移除
            if !navigationPath.isEmpty {
                navigationPath.removeLast()
            }
        }
    }
    
    @MainActor
    func resetNavigation() {
        Logger.info("Resetting navigation state")
        homeTabPath = NavigationPath()
        profileTabPath = NavigationPath()
        settingsTabPath = NavigationPath()
        navigationPath = NavigationPath()
        selectedTab = .home
        isPresentingSheet = false
        presentedSheet = nil
    }
    
    // 更新认证状态
    func updateAuthenticationState(isAuthenticated: Bool) {
        self.isAuthenticated = isAuthenticated
    }
}

// MARK: - Preview Helper
#if DEBUG
extension AppNavigationManager {
    static var preview: AppNavigationManager {
        return AppNavigationManager.shared
    }
}
#endif
