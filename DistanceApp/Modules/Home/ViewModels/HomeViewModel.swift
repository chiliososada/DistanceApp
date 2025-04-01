import SwiftUI
import Combine

// MARK: - HomeViewModel
class HomeViewModel: ObservableObject {
    // 用于调试
    private let isDebug = true
    private func log(_ message: String) {
        if isDebug {
            print("【HomeViewModel】\(message)")
        }
    }
    
    // MARK: - 发布属性
    @Published var trendingTopics: [Topic] = []
    @Published var recentTopics: [Topic] = []
    @Published var isLoadingMore = false
    @Published var isRefreshing = false
    @Published var currentPage = 0 // 使用时间戳或ID作为分页标记
    @Published var errorMessage: String?
    @Published var isLoading = false
    @Published var hasError = false
    @Published var debugInfo: String = "" // 调试信息
    @Published var hasReachedEnd = false  // 标记是否已到达数据末尾
    
    // MARK: - 私有属性
    private let postService: PostServiceProtocol
    private var cancellables = Set<AnyCancellable>()
    private let pageSize = 5 // 每页数据量
    private var loadingTask: Task<Void, Error>? // 存储当前加载任务
    private var loadingSemaphore = false // 防止重复加载的信号量
    
    // 最后一项的时间戳或ID，用于分页
    private var lastItemRecency: Int {
        // 如果没有数据，返回0表示最新数据
        guard let lastTopic = recentTopics.last, let lastId = Int(lastTopic.id) else {
            return 0
        }
        return lastId
    }
    
    // MARK: - 初始化
    init(postService: PostServiceProtocol) {
        self.postService = postService
        log("HomeViewModel初始化，使用真实API")
    }
    
    deinit {
        // 取消正在进行的任务
        loadingTask?.cancel()
    }
    
    // MARK: - 公共方法
    
    // 加载初始数据
    func loadInitialData() {
        guard !isLoading else {
            log("已在加载中，跳过初始化")
            return
        }
        
        log("开始加载初始数据")
        isLoading = true
        hasError = false
        currentPage = 0 // 重置为0，表示最新数据
        hasReachedEnd = false // 重置标志
        debugInfo = "正在加载初始数据..."
        
        // 取消之前的任务
        loadingTask?.cancel()
        
        loadingTask = Task {
            do {
                // 并行加载热门话题和最新话题
                async let trendingResult = loadTrendingTopics()
                async let recentResult = loadRecentTopics(recency: 0, isRefresh: true)
                
                // 等待两个任务完成
                _ = try await (trendingResult, recentResult)
                
                if Task.isCancelled { return }
                
                await MainActor.run {
                    self.isLoading = false
                    self.hasError = false
                    self.debugInfo = "初始数据加载完成，热门话题: \(self.trendingTopics.count)，最新话题: \(self.recentTopics.count)"
                    log("初始数据加载完成")
                }
            } catch {
                if !Task.isCancelled {
                    await MainActor.run {
                        self.errorMessage = error.localizedDescription
                        self.isLoading = false
                        self.hasError = true
                        self.debugInfo = "加载数据失败: \(error.localizedDescription)"
                        log("加载数据失败: \(error.localizedDescription)")
                    }
                }
            }
        }
    }
    
    // 刷新数据
    func refresh() {
        guard !isRefreshing && !isLoadingMore else {
            log("已在刷新或加载更多中，跳过")
            return
        }
        
        log("开始刷新数据")
        isRefreshing = true
        currentPage = 0 // 重置为0，表示最新数据
        hasReachedEnd = false // 重置到达末尾标志
        hasError = false
        debugInfo = "正在刷新数据..."
        
        // 取消之前的任务
        loadingTask?.cancel()
        
        loadingTask = Task {
            do {
                // 并行加载热门话题和最新话题
                async let trendingResult = loadTrendingTopics()
                async let recentResult = loadRecentTopics(recency: 0, isRefresh: true)
                
                // 等待两个任务完成
                _ = try await (trendingResult, recentResult)
                
                if Task.isCancelled { return }
                
                await MainActor.run {
                    self.isRefreshing = false
                    self.hasError = false
                    self.debugInfo = "数据刷新完成，共\(self.recentTopics.count)条数据"
                    log("刷新完成")
                }
            } catch {
                if !Task.isCancelled {
                    await MainActor.run {
                        self.errorMessage = error.localizedDescription
                        self.isRefreshing = false
                        self.hasError = true
                        self.debugInfo = "刷新数据失败: \(error.localizedDescription)"
                        log("刷新失败: \(error.localizedDescription)")
                    }
                }
            }
        }
    }
    
    // 加载更多话题 - 添加防抖和状态检查机制
    func loadMoreTopics() {
        // 检查多种状态，防止重复加载
        guard !isLoadingMore && !isRefreshing && !isLoading && !loadingSemaphore && !hasReachedEnd else {
            log("已在加载中或已到达末尾，跳过加载更多")
            return
        }
        
        // 设置信号量防止短时间内重复调用
        loadingSemaphore = true
        
        // 预先设置状态，确保UI立即反馈
        isLoadingMore = true
        debugInfo = "开始加载更多数据..."
        log("开始加载更多数据，recency: \(lastItemRecency)")
        
        // 取消之前的任务
        loadingTask?.cancel()
        
        // 创建新任务
        loadingTask = Task {
            do {
                // 获取下一页数据
                //let newTopics = try await loadRecentTopics(recency: lastItemRecency, isRefresh: false)
                let newTopics = try await loadRecentTopics(recency: 0, isRefresh: false)
                if Task.isCancelled { return }
                
                // 主线程更新UI和状态
                await MainActor.run {
                    // 检查是否获取到新数据
                    if newTopics.isEmpty {
                        self.hasReachedEnd = true
                        self.debugInfo = "已加载全部数据"
                        log("已到达数据末尾")
                    } else {
                        self.debugInfo = "已加载更多，共\(self.recentTopics.count)条数据"
                        log("更新完成，现在共有\(self.recentTopics.count)条数据")
                    }
                    
                    // 重置加载状态
                    self.isLoadingMore = false
                    
                    // 延迟重置信号量，防止快速连续触发
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                        self.loadingSemaphore = false
                    }
                }
            } catch {
                if !Task.isCancelled {
                    await MainActor.run {
                        self.isLoadingMore = false
                        self.debugInfo = "加载更多失败: \(error.localizedDescription)"
                        log("加载更多失败: \(error.localizedDescription)")
                        
                        // 即使出错，也要延迟重置信号量
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                            self.loadingSemaphore = false
                        }
                    }
                }
            }
        }
    }
    
    // 基于搜索文本过滤话题
    func filterTopics(searchText: String) -> [Topic] {
        guard !searchText.isEmpty else {
            return recentTopics // 如果搜索为空，返回全部话题
        }
        
        return recentTopics.filter { topic in
            topic.title.localizedCaseInsensitiveContains(searchText) ||
            topic.content.localizedCaseInsensitiveContains(searchText) ||
            topic.tags.contains { $0.localizedCaseInsensitiveContains(searchText) } ||
            topic.authorName.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    // MARK: - 私有方法
    
    // 加载热门话题
    @discardableResult
    private func loadTrendingTopics() async throws -> [Topic] {
        do {
            log("加载热门话题")
            // 使用实际API调用
            let topics = try await postService.getTrendingTopics(max: 5)
            
            if Task.isCancelled { throw CancellationError() }
            
            await MainActor.run {
                self.trendingTopics = topics
                log("热门话题加载完成: \(topics.count)条")
            }
            
            return topics
        } catch {
            log("加载热门话题失败: \(error)")
            throw error
        }
    }
    
    // 加载最新话题
    @discardableResult
    private func loadRecentTopics(recency: Int, isRefresh: Bool) async throws -> [Topic] {
        do {
            log("加载最新话题，参数: recency=\(recency), isRefresh=\(isRefresh)")
            
            // 使用实际API调用
            let topics = try await postService.getTopics(findby: "recent", max: pageSize, recency: recency)
            
            if Task.isCancelled { throw CancellationError() }
            
            await MainActor.run {
                if isRefresh {
                    // 刷新模式：替换数据
                    self.recentTopics = topics
                    log("刷新模式：替换为\(topics.count)条数据")
                } else {
                    // 加载更多模式：追加数据
                    self.recentTopics.append(contentsOf: topics)
                    log("追加模式：新增\(topics.count)条数据，总共\(self.recentTopics.count)条")
                }
                
                // 更新页码，用于标记和调试
                if topics.count > 0 {
                    self.currentPage += 1
                }
            }
            
            return topics
        } catch {
            log("加载最新话题失败: \(error)")
            throw error
        }
    }
}
