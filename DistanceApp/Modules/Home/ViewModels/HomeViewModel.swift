//
//  HomeViewModel.swift
//  DistanceApp
//
//  Created by toyousoft on 2025/03/03.
//  Updated on 2025/03/25.
//

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
    @Published var currentPage = 1
    @Published var errorMessage: String?
    @Published var isLoading = false
    @Published var hasError = false
    @Published var debugInfo: String = "" // 调试信息
    
    // MARK: - 私有属性
    private let postService: PostServiceProtocol
    private var cancellables = Set<AnyCancellable>()
    private let pageSize = 5 // 修改：每页数据量改为5，方便测试
    
    // MARK: - 初始化
    init(postService: PostServiceProtocol) {
        self.postService = postService
        // 首次加载使用模拟数据，确保UI能立即显示
        setupMockData()
    }
    
    // MARK: - 公共方法
    
    // 加载初始数据
    func loadInitialData() {
        log("开始加载初始数据")
        isLoading = true
        hasError = false
        debugInfo = "正在加载初始数据..."
        
        Task {
            do {
                // 并行加载热门话题和最新话题
                async let trendingResult = loadTrendingTopics()
                async let recentResult = loadRecentTopics(page: 1)
                
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
        currentPage = 1
        hasError = false
        debugInfo = "正在刷新数据..."
        
        Task {
            do {
                // 延迟1秒，便于观察
                try await Task.sleep(nanoseconds: 1_000_000_000)
                
                // 并行加载热门话题和最新话题
                async let trendingResult = loadTrendingTopics()
                async let recentResult = loadRecentTopics(page: 1)
                
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
        guard !isLoadingMore && !isRefreshing && !isLoading else {
            log("已在加载中，跳过加载更多")
            debugInfo = "已在加载中，跳过"
            return
        }
        
        log("开始加载更多数据，当前页: \(currentPage)，下一页: \(currentPage + 1)")
        debugInfo = "开始加载第\(currentPage + 1)页..."
        isLoadingMore = true
        currentPage += 1
        
        // 使用直接测试方法而不是异步
        let newTopics = generateMoreMockData(page: currentPage)
        log("已生成\(newTopics.count)条测试数据")
        
        // 直接添加到当前话题列表
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.recentTopics.append(contentsOf: newTopics)
            self.isLoadingMore = false
            self.debugInfo = "已加载第\(self.currentPage)页，共\(self.recentTopics.count)条数据"
            self.log("更新完成，现在共有\(self.recentTopics.count)条数据")
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
            // 使用模拟数据
            // 在实际应用中，这里会调用postService.getTrendingTopics
            try await Task.sleep(nanoseconds: 500_000_000) // 0.5秒延迟
            
            await MainActor.run {
                // trendingTopics已在setupMockData中初始化，不需要更改
                log("热门话题加载完成: \(self.trendingTopics.count)条")
            }
            
            return trendingTopics
        } catch {
            log("加载热门话题失败: \(error)")
            throw error
        }
    }
    
    // 加载最新话题
    @discardableResult
    private func loadRecentTopics(page: Int, append: Bool = false) async throws -> [Topic] {
        do {
            log("加载最新话题，页码: \(page), 追加模式: \(append)")
            // 使用模拟数据来简化测试
            
            try await Task.sleep(nanoseconds: 500_000_000) // 0.5秒延迟
            
            if page == 1 {
                // 第一页使用初始模拟数据
                let topics = setupMockRecentTopics()
                
                await MainActor.run {
                    self.recentTopics = topics
                    self.log("第1页最新话题加载完成: \(topics.count)条")
                }
                
                return topics
            } else {
                // 这个条件永远不会执行，因为loadMoreTopics直接使用generateMoreMockData
                log("使用loadRecentTopics加载更多页的情况，不应该发生")
                return []
            }
        } catch {
            log("加载最新话题失败: \(error)")
            throw error
        }
    }
    
    // 设置模拟数据 - 首次加载时使用，确保UI能立即显示
    private func setupMockData() {
        log("设置初始模拟数据")
        // 趋势话题
        trendingTopics = [
            Topic(
                id: "1",
                title: "新宿御苑赏樱花",
                content: "有人明天一起去新宿御苑赏樱花吗？预计花期正好，想找几个人一起去。",
                authorName: "樱花爱好者",
                location: "新宿区",
                tags: ["赏樱", "周末活动"],
                participantsCount: 15,
                postedTime: "2小时前",
                distance: 0.5,
                isLiked: false,
                images: ["cherry1"]
            ),
            Topic(
                id: "2",
                title: "歌舞伎町酒吧推荐",
                content: "刚到东京，有人能推荐歌舞伎町有哪些适合外国人的酒吧吗？",
                authorName: "旅行者小明",
                location: "歌舞伎町",
                tags: ["夜生活", "酒吧"],
                participantsCount: 23,
                postedTime: "5小时前",
                distance: 1.2,
                isLiked: true,
                images: []
            ),
            Topic(
                id: "3",
                title: "求购Switch游戏",
                content: "有人知道新宿哪里可以买到便宜的二手Switch游戏吗？特别想找塞尔达传说。",
                authorName: "游戏迷",
                location: "新宿站",
                tags: ["游戏", "二手交易"],
                participantsCount: 8,
                postedTime: "昨天",
                distance: 0.8,
                isLiked: false,
                images: ["switch1"]
            ),
            Topic(
                id: "4",
                title: "今晚演唱会",
                content: "今晚在新宿Loft有个地下乐队演出，有人一起去吗？",
                authorName: "音乐发烧友",
                location: "新宿Loft",
                tags: ["音乐", "演唱会"],
                participantsCount: 32,
                postedTime: "3小时前",
                distance: 1.5,
                isLiked: false,
                images: ["concert1"]
            )
        ]
        
        // 最新话题在初始化时不加载，确保loadInitialData能正常工作
        recentTopics = []
    }
    
    // 生成模拟的最新话题数据
    private func setupMockRecentTopics() -> [Topic] {
        return [
            Topic(
                id: "5",
                title: "【第1页】求推荐拉面店",
                content: "刚搬到新宿，有什么好吃的拉面店推荐吗？最好是本地人喜欢去的那种。【第1页内容】",
                authorName: "吃货小王",
                location: "新宿站西口",
                tags: ["美食", "拉面", "第1页"],
                participantsCount: 7,
                postedTime: "30分钟前",
                distance: 0.3,
                isLiked: false,
                images: []
            ),
            Topic(
                id: "6",
                title: "【第1页】新宿中央公园晨练",
                content: "每天早上6点在新宿中央公园有晨练小组，欢迎附近的朋友加入！【第1页内容】",
                authorName: "健身达人",
                location: "新宿中央公园",
                tags: ["运动", "晨练", "第1页"],
                participantsCount: 12,
                postedTime: "1小时前",
                distance: 1.0,
                isLiked: true,
                images: ["park1"]
            ),
            Topic(
                id: "7",
                title: "【第1页】寻找共享办公室",
                content: "有人知道新宿附近有什么价格合理的共享办公空间吗？最好有月租选项。【第1页内容】",
                authorName: "自由职业者",
                location: "新宿区",
                tags: ["工作", "共享空间", "第1页"],
                participantsCount: 4,
                postedTime: "2小时前",
                distance: 0.7,
                isLiked: false,
                images: []
            ),
            Topic(
                id: "8",
                title: "【第1页】卖二手自行车",
                content: "搬家需要出售一辆9成新的通勤自行车，有需要的可以联系我。【第1页内容】",
                authorName: "搬家达人",
                location: "高田马场",
                tags: ["二手", "自行车", "第1页"],
                participantsCount: 2,
                postedTime: "45分钟前",
                distance: 2.5,
                isLiked: false,
                images: ["bike1"]
            ),
            Topic(
                id: "9",
                title: "【第1页】初始页面最后一条",
                content: "这是初始页的最后一条内容，用于触发加载更多。滚动到这里应该开始加载第2页。【第1页内容】",
                authorName: "测试用户",
                location: "测试位置",
                tags: ["测试", "初始页", "第1页"],
                participantsCount: 1,
                postedTime: "刚刚",
                distance: 0.1,
                isLiked: false,
                images: []
            )
        ]
    }
    
    // 生成更多模拟数据
    func generateMoreMockData(page: Int) -> [Topic] {
        // 根据页码生成不同的数据
        let startId = 100 + (page - 1) * pageSize
        return (0..<pageSize).map { i in
            let id = "\(startId + i)"
            return Topic(
                id: id,
                title: "【第\(page)页】新测试话题\(i+1)",
                content: "这是【第\(page)页】的第\(i+1)个新测试话题。这是通过下拉加载更多生成的测试内容。该内容明显区别于第一页。",
                authorName: "新用户\(page)-\(i)",
                location: "新位置\(page)-\(i)",
                tags: ["第\(page)页", "测试\(i)", "加载更多"],
                participantsCount: page * 10 + i,
                postedTime: "\(page)小时前",
                distance: Double(page) + Double(i)/10.0,
                isLiked: (page + i) % 2 == 0,
                images: []
            )
        }
    }
}
