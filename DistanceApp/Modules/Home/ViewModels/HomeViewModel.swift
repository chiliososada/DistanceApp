//
//  HomeViewModel.swift
//  DistanceApp
//
//  Created by toyousoft on 2025/03/03.
//

import SwiftUI
import Combine

// MARK: - HomeViewModel
class HomeViewModel: ObservableObject {
    @Published var trendingTopics: [Topic] = []
    @Published var recentTopics: [Topic] = []
    @Published var isLoadingMore = false
    @Published var isRefreshing = false
    @Published var currentPage = 1
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        setupMockData()
    }
    
    // 加载初始数据
    func loadInitialData() {
        loadTrendingTopics()
        loadRecentTopics(page: 1)
    }
    
    // 刷新数据
    func refresh() {
        guard !isRefreshing else { return }
        
        isRefreshing = true
        currentPage = 1
        
        // 模拟网络请求延迟
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [weak self] in
            guard let self = self else { return }
            self.loadInitialData()
            self.isRefreshing = false
        }
    }
    
    // 加载更多话题
    func loadMoreTopics() {
        guard !isLoadingMore && !isRefreshing else { return }
        
        isLoadingMore = true
        currentPage += 1
        
        // 模拟网络请求延迟
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) { [weak self] in
            guard let self = self else { return }
            
            // 这里应该是从API加载更多数据
            // 暂时使用示例数据
            self.loadRecentTopics(page: self.currentPage)
            self.isLoadingMore = false
        }
    }
    
    // 设置模拟数据 - 实际应用中会从API获取
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
        let initialRecentTopics = [
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
        
        recentTopics = initialRecentTopics
    }
    
    private func loadTrendingTopics() {
        // 实际项目中，这里会有网络请求
        // 示例代码已在setupMockData中初始化
    }
    
    private func loadRecentTopics(page: Int) {
        // 实际项目中，这里会有网络请求
        // 现在使用模拟数据
        
        if page > 1 {
            // 加载更多页的数据，模拟分页加载
            let moreTopics = [
                Topic(
                    id: "9-\(UUID().uuidString)",
                    title: "招聘兼职翻译",
                    content: "需要一名中日翻译，每周工作约10小时，可远程。",
                    authorName: "日企HR",
                    location: "池袋",
                    tags: ["兼职", "翻译"],
                    participantsCount: 3,
                    postedTime: "1小时前",
                    distance: 3.2,
                    isLiked: false,
                    images: []
                ),
                Topic(
                    id: "10-\(UUID().uuidString)",
                    title: "组织周末远足",
                    content: "计划这周末去高尾山远足，有兴趣的朋友可以加入。",
                    authorName: "户外爱好者",
                    location: "新宿",
                    tags: ["远足", "周末"],
                    participantsCount: 8,
                    postedTime: "3小时前",
                    distance: 0.5,
                    isLiked: false,
                    images: ["hiking1"]
                )
            ]
            
            recentTopics.append(contentsOf: moreTopics)
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
}
