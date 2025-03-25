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
    // MARK: - 发布属性
    @Published var trendingTopics: [Topic] = []
    @Published var recentTopics: [Topic] = []
    @Published var isLoadingMore = false
    @Published var isRefreshing = false
    @Published var currentPage = 1
    @Published var errorMessage: String?
    @Published var isLoading = false
    @Published var hasError = false
    
    // MARK: - 私有属性
    private let postService: PostServiceProtocol
    private var cancellables = Set<AnyCancellable>()
    private let pageSize = 30 // 每页数据量
    
    // MARK: - 初始化
    init(postService: PostServiceProtocol) {
        self.postService = postService
        // 首次加载使用模拟数据，确保UI能立即显示
        setupMockData()
    }
    
    // MARK: - 公共方法
    
    // 加载初始数据
    func loadInitialData() {
        isLoading = true
        hasError = false
        
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
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                    self.isLoading = false
                    self.hasError = true
                    Logger.error("加载数据失败: \(error.localizedDescription)")
                }
            }
        }
    }
    
    // 刷新数据
    func refresh() {
        guard !isRefreshing else { return }
        
        isRefreshing = true
        currentPage = 1
        hasError = false
        
        Task {
            do {
                // 并行加载热门话题和最新话题
                async let trendingResult = loadTrendingTopics()
                async let recentResult = loadRecentTopics(page: 1)
                
                // 等待两个任务完成
                _ = try await (trendingResult, recentResult)
                
                await MainActor.run {
                    self.isRefreshing = false
                    self.hasError = false
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                    self.isRefreshing = false
                    self.hasError = true
                    Logger.error("刷新数据失败: \(error.localizedDescription)")
                }
            }
        }
    }
    
    // 加载更多话题
    func loadMoreTopics() {
        guard !isLoadingMore && !isRefreshing && !isLoading else { return }
        
        isLoadingMore = true
        currentPage += 1
        
        Task {
            do {
                // 加载下一页话题
                try await loadRecentTopics(page: currentPage, append: true)
                
                await MainActor.run {
                    self.isLoadingMore = false
                    self.hasError = false
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                    self.isLoadingMore = false
                    self.hasError = true
                    self.currentPage -= 1 // 失败时回退页码
                    Logger.error("加载更多话题失败: \(error.localizedDescription)")
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
            let topics = try await postService.getTrendingTopics(max: 10)
            
            await MainActor.run {
                self.trendingTopics = topics
            }
            
            return topics
        } catch {
            Logger.error("加载热门话题失败: \(error)")
            throw error
        }
    }

    
    // 加载最新话题
    @discardableResult
    private func loadRecentTopics(page: Int, append: Bool = false) async throws -> [Topic] {
        do {
            // 使用页码计算recency参数
            // 假设recency为0表示最新数据，每页数据以pageSize递增
            let recency = (page - 1) * pageSize
            
            let topics = try await postService.getTopics(findby: "recent", max: pageSize, recency: recency)
            
            await MainActor.run {
                if append {
                    // 追加数据
                    self.recentTopics.append(contentsOf: topics)
                } else {
                    // 替换数据
                    self.recentTopics = topics
                }
            }
            
            return topics
        } catch {
            Logger.error("加载最新话题失败: \(error)")
            throw error
        }
    }
    
    // 设置模拟数据 - 首次加载时使用，确保UI能立即显示
    private func setupMockData() {
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
        
        // 最新话题
        recentTopics = [
            Topic(
                id: "5",
                title: "求推荐拉面店",
                content: "刚搬到新宿，有什么好吃的拉面店推荐吗？最好是本地人喜欢去的那种。",
                authorName: "吃货小王",
                location: "新宿站西口",
                tags: ["美食", "拉面"],
                participantsCount: 7,
                postedTime: "30分钟前",
                distance: 0.3,
                isLiked: false,
                images: []
            ),
            Topic(
                id: "6",
                title: "新宿中央公园晨练",
                content: "每天早上6点在新宿中央公园有晨练小组，欢迎附近的朋友加入！",
                authorName: "健身达人",
                location: "新宿中央公园",
                tags: ["运动", "晨练"],
                participantsCount: 12,
                postedTime: "1小时前",
                distance: 1.0,
                isLiked: true,
                images: ["park1"]
            ),
            Topic(
                id: "7",
                title: "寻找共享办公室",
                content: "有人知道新宿附近有什么价格合理的共享办公空间吗？最好有月租选项。",
                authorName: "自由职业者",
                location: "新宿区",
                tags: ["工作", "共享空间"],
                participantsCount: 4,
                postedTime: "2小时前",
                distance: 0.7,
                isLiked: false,
                images: []
            ),
            Topic(
                id: "8",
                title: "卖二手自行车",
                content: "搬家需要出售一辆9成新的通勤自行车，有需要的可以联系我。",
                authorName: "搬家达人",
                location: "高田马场",
                tags: ["二手", "自行车"],
                participantsCount: 2,
                postedTime: "45分钟前",
                distance: 2.5,
                isLiked: false,
                images: ["bike1"]
            )
        ]
    }
}
