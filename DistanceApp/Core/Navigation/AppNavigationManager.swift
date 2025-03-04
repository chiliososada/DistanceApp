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

// MARK: - Protocol
protocol NavigationManagerProtocol {
    var navigationPath: NavigationPath { get }
    var isPresentingSheet: Bool { get }
    
    func navigate(to route: AppRoute)
    func dismiss()
    func popToRoot()
    func goBack()
    func resetNavigation()
}

// MARK: - Implementation
final class AppNavigationManager: ObservableObject, NavigationManagerProtocol {
    // MARK: - Published Properties
    @Published var navigationPath = NavigationPath()
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
