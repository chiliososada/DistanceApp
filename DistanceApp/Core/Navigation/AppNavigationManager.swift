//
//  AppNavigationManager.swift
//  DistanceApp
//
//  Created by toyousoft on 2025/03/03.
//

import SwiftUI
import Combine

// MARK: - Route Definitions
enum AppRoute: Hashable {
    // Auth Flow
    case login(showBackButton: Bool)
    case register
    case loginPassword(email: String)
    case createAccount(email: String)
    case passwordChanged
    case forgetPassword
    
    // Main Flow
    case chatDetail(chatRoom: ChatRoom)
    case profileEditor
    case settings
    case privacyPolicy
    case about
    case passwordChange
    case postDetail(post: LocationPost)
    case home
    
    // Sheet Presentations
    case postInput
    case searchFilter
    case imageGallery([UIImage])
    case locationPicker
    case verification(email: String? = nil)
}

// MARK: - Tab Routes
enum TabRoute: Int {
    case home = 0
    case nearby
    case post
    case chat
    case profile
}

// MARK: - Protocol
protocol NavigationManagerProtocol {
    var navigationPath: NavigationPath { get }
    var selectedTab: TabRoute { get }
    var presentedSheet: AppRoute? { get }
    var isPresentingSheet: Bool { get }
    
    func navigate(to route: AppRoute)
    func present(_ route: AppRoute)
    func dismiss()
    func popToRoot()
    func goBack()
    func navigateToHome()
    func navigateToTab(_ tab: TabRoute)
    func switchTab(to tab: TabRoute)
    func resetNavigation()
    func toggleMenu()
    func closeMenu()
}

// MARK: - Implementation
final class AppNavigationManager: ObservableObject, NavigationManagerProtocol {
    // MARK: - Published Properties
    @Published var navigationPath = NavigationPath()
    @Published var selectedTab: TabRoute = .home
    @Published var presentedSheet: AppRoute?
    @Published var isPresentingSheet = false
    @Published var isShowingMenu = false
    
    // MARK: - Navigation Source Tracking
    enum ChatNavigationSource: Equatable {
        case normal
        case fromRecipe(RecipeInfo)
        
        struct RecipeInfo: Equatable {
            let title: String
            let imageUrl: String
            let participantsCount: Int
        }
    }
    
    @Published var chatNavigationSource: ChatNavigationSource = .normal
    @Published var pendingChatRoom: ChatRoom?
    
    // MARK: - Singleton Instance
    static let shared = AppNavigationManager()
    
    // MARK: - Initialization
    init() {
        setupLogging()
    }
    
    private func setupLogging() {
        // 设置属性改变日志记录
        Publishers.MergeMany(
            $navigationPath.map { _ in "Navigation path changed" },
            $selectedTab.map { "Selected tab changed to: \($0)" },
            $presentedSheet.map { "Presented sheet changed to: \(String(describing: $0))" },
            $isPresentingSheet.map { "isPresentingSheet changed to: \($0)" },
            $chatNavigationSource.map { _ in "Chat navigation source changed" },
            $pendingChatRoom.map { "Pending chat room \($0 != nil ? "set" : "cleared")" },
            $isShowingMenu.map { "Menu visibility changed to: \($0)" }
        )
        .sink { message in
            Logger.debug("Navigation: \(message)")
        }
        .store(in: &cancellables)
    }
    
    // MARK: - Private Properties
    private var cancellables = Set<AnyCancellable>()
    
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
    
    func navigateToHome() {
        // 如果已经在主页且tab是home，直接返回
        if selectedTab == .home && navigationPath.count <= 1 {
            return
        }
        
        // 否则执行导航
        navigationPath = NavigationPath()
        selectedTab = .home
        Logger.info("Navigated to home")
    }
    
    func navigateToTab(_ tab: TabRoute) {
        Logger.info("Navigating to tab: \(tab)")
        selectedTab = tab
    }
    
    func switchTab(to tab: TabRoute) {
        Logger.info("Switching to tab: \(tab)")
        selectedTab = tab
    }
    
    func resetNavigation() {
        Logger.info("Resetting navigation state")
        navigationPath = NavigationPath()
        chatNavigationSource = .normal
        selectedTab = .home
        pendingChatRoom = nil
        isPresentingSheet = false
        presentedSheet = nil
        isShowingMenu = false
    }
    
    func toggleMenu() {
        withAnimation(.spring()) {
            isShowingMenu.toggle()
        }
        Logger.info("Menu toggled: \(isShowingMenu)")
    }
    
    func closeMenu() {
        withAnimation(.spring()) {
            isShowingMenu = false
        }
        Logger.info("Menu closed")
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
