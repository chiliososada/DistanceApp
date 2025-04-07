import SwiftUI
import Combine

// MARK: - HomeViewModel
class HomeViewModel: ObservableObject {
    
    static let shared = HomeViewModel(postService: AppEnvironment.shared.postService)
    // 调试选项
    private let isDebug = true
    private func log(_ message: String) {
        if isDebug {
            Logger.debug("【HomeViewModel】\(message)")
        }
    }
    
    // MARK: - 发布属性
    @Published var trendingTopics: [Topic] = []
    @Published var recentTopics: [Topic] = []
    @Published var isLoadingMore = false
    @Published var isRefreshing = false
    @Published var errorMessage: String?
    @Published var isLoading = false
    @Published var hasError = false
    @Published var debugInfo: String = "" // 调试信息
    
    // MARK: - 私有属性
    private let postService: PostServiceProtocol
    private var cancellables = Set<AnyCancellable>()
    private let pageSize = 10 // 每页加载数量
    private var currentScore: Int? = nil // 当前最后一条数据的游标值
    @Published var hasMoreData: Bool = true
    
    // MARK: - 初始化
    init(postService: PostServiceProtocol) {
        self.postService = postService
    }
    
    // MARK: - 公共方法
    
    // 加载初始数据
    func loadInitialData() {
        // 如果已经有数据且不是刷新状态，避免重复加载
        if !self.recentTopics.isEmpty && !self.isRefreshing {
            log("已有数据(\(self.recentTopics.count)条)，跳过初始加载")
            return
        }
        
        log("开始加载初始数据")
        isLoading = true
        hasError = false
        debugInfo = "正在加载初始数据..."
        
        // 只有在真正需要重新加载时才重置分页状态
        if self.recentTopics.isEmpty {
            currentScore = nil // 重置游标
            hasMoreData = true // 重置是否有更多数据标志
        }
        
        Task {
            do {
                // 并行加载热门话题和最新话题
                async let trendingResult = loadTrendingTopics()
                async let recentResult = loadRecentTopics()
                
                // 等待两个任务完成
                _ = try await (trendingResult, recentResult)
                
                await MainActor.run {
                    self.isLoading = false
                    self.hasError = false
                    self.debugInfo = "初始数据加载完成，热门话题: \(self.trendingTopics.count)，最新话题: \(self.recentTopics.count)"
                    log("初始数据加载完成")
                }
            } catch {
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
    
    // 刷新数据
    func refresh() {
        guard !isRefreshing else {
            log("已在刷新中，跳过")
            return
        }
        
        log("开始刷新数据")
        isRefreshing = true
        currentScore = nil // 重置游标
        hasMoreData = true // 重置是否有更多数据标志
        hasError = false
        debugInfo = "正在刷新数据..."
        
        Task {
            do {
                // 并行加载热门话题和最新话题
                async let trendingResult = loadTrendingTopics()
                async let recentResult = loadRecentTopics()
                
                // 等待两个任务完成
                _ = try await (trendingResult, recentResult)
                
                await MainActor.run {
                    self.isRefreshing = false
                    self.hasError = false
                    self.debugInfo = "数据刷新完成，共\(self.recentTopics.count)条数据"
                    log("刷新完成")
                }
            } catch {
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
    
    // 加载更多话题
    func loadMoreTopics() {
        // 检查是否已经在加载中
        guard !isLoadingMore && !isRefreshing && !isLoading else {
            log("已在加载中，跳过加载更多: isLoadingMore=\(isLoadingMore), isRefreshing=\(isRefreshing), isLoading=\(isLoading)")
            debugInfo = "已在加载中，跳过"
            return
        }
        
        // 检查是否还有更多数据
        guard hasMoreData else {
            log("没有更多数据了")
            debugInfo = "没有更多数据了"
            return
        }
        
        log("开始加载更多数据，当前score: \(String(describing: currentScore))")
        debugInfo = "正在加载更多数据..."
        isLoadingMore = true
        
        Task {
            do {
                log("执行加载更多请求，使用score: \(String(describing: currentScore))")
                let result = try await loadMoreRecentTopics()
                
                await MainActor.run {
                    isLoadingMore = false
                    // 确保hasMoreData按实际情况设置，不要随便重置
                    if result.isEmpty {
                        hasMoreData = false
                        log("没有收到更多数据，设置hasMoreData=false")
                    } else {
                        hasMoreData = result.count >= pageSize
                        log("收到\(result.count)条新数据，hasMoreData=\(hasMoreData)")
                    }
                    debugInfo = "加载更多完成，共\(recentTopics.count)条数据"
                    log("加载更多完成，新增\(result.count)条，总计\(recentTopics.count)条")
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    isLoadingMore = false
                    // 出错时不要重置hasMoreData
                    hasError = true
                    debugInfo = "加载更多失败: \(error.localizedDescription)"
                    log("加载更多失败: \(error.localizedDescription)")
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
            
            // 调用实际API获取热门话题
            let topics = try await postService.getTrendingTopics(max: 10)
            
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
    
    // 加载最新话题（初始加载）
    @discardableResult
    private func loadRecentTopics() async throws -> [Topic] {
        do {
            log("加载最新话题，初始加载")
            
            // 调用实际API获取最新话题
            let (topics, score) = try await getTopics(recency: 0)
            
            await MainActor.run {
                self.recentTopics = topics
                self.currentScore = score
                self.hasMoreData = topics.count >= self.pageSize
                log("最新话题加载完成: \(topics.count)条，score: \(String(describing: score))")
            }
            
            return topics
        } catch {
            log("加载最新话题失败: \(error)")
            throw error
        }
    }
    
    // 修改loadMoreRecentTopics方法，返回实际加载的结果数组
    @discardableResult
    private func loadMoreRecentTopics() async throws -> [Topic] {
        do {
            log("加载更多最新话题，当前score: \(String(describing: currentScore))")
            
            // 使用当前游标加载更多话题
            let recency = currentScore ?? 0
            let (topics, score) = try await getTopics(recency: recency)
            
            await MainActor.run {
                // 如果返回数据为空，设置hasMoreData为false
                if topics.isEmpty {
                    log("返回的话题数组为空，设置hasMoreData=false")
                    hasMoreData = false
                } else {
                    // 将新加载的话题追加到现有列表
                    recentTopics.append(contentsOf: topics)
                    
                    // 保存新的游标，但不要在出错时丢失原有游标
                    if let newScore = score {
                        currentScore = newScore
                        log("更新游标为: \(newScore)")
                    } else {
                        // 如果API没有返回新游标但有数据，使用一个估计值
                        if let lastTopic = topics.last, let lastId = Int(lastTopic.id) {
                            currentScore = lastId
                            log("API未返回游标，使用估计值: \(lastId)")
                        }
                    }
                    
                    hasMoreData = topics.count >= pageSize
                    log("加载更多完成: 新增\(topics.count)条，总计\(recentTopics.count)条，新score: \(String(describing: score)), hasMoreData=\(hasMoreData)")
                }
            }
            
            return topics
        } catch {
            log("加载更多话题失败: \(error)")
            // 错误时不要重置hasMoreData，让用户有机会重试
            throw error
        }
    }
    
    // 获取话题的通用方法，返回话题数组和游标值
    private func getTopics(recency: Int) async throws -> ([Topic], Int?) {
        do {
            // 调用postService获取话题数据，使用适当的参数
            let topics = try await postService.getTopics(findby: "recent", max: pageSize, recency: recency)
            
            // 直接从postService获取最后一次响应的score值
            let score = postService.getLastResponseScore()
            
            log("获取话题成功: 条数=\(topics.count), score=\(String(describing: score))")
            
            return (topics, score)
        } catch let error as NSError where error.domain == NSURLErrorDomain && error.code == NSURLErrorCancelled {
            // 处理请求取消的情况
            log("请求已被取消，可能是由于视图消失或刷新")
            throw PostError.networkError(error)
        } catch {
            // 记录并重新抛出其他错误
            log("获取话题失败: \(error.localizedDescription)")
            throw error
        }
    }
}

