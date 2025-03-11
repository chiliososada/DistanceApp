//
//  AppNavigationManager.swift
//  DistanceApp
//
//  Created by toyousoft on 2025/03/03.
//

//
//  AppNavigationManager.swift
//  DistanceApp
//
//  Created by toyousoft on 2025/03/03.
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
// MARK: - Implementation
final class AppNavigationManager: ObservableObject, NavigationManagerProtocol {
    // MARK: - Published Properties
    @Published var navigationPath = NavigationPath()
    @Published var selectedTab: Tab = .home
    @Published var presentedSheet: AppRoute?
    @Published var isPresentingSheet = false
    
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
    }
    
    // MARK: - Navigation Methods
    func navigate(to route: AppRoute) {
        Logger.info("Navigating to route: \(route)")
        // 确保在主线程执行
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.navigationPath.append(route)
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
        navigationPath = NavigationPath()
    }
    
    func goBack() {
        Logger.info("Going back")
        if !navigationPath.isEmpty {
            navigationPath.removeLast()
        }
    }
    
    func resetNavigation() {
        Logger.info("Resetting navigation state")
        navigationPath = NavigationPath()
        selectedTab = .home
        isPresentingSheet = false
        presentedSheet = nil
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
