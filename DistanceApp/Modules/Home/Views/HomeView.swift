import SwiftUI
import Combine

// MARK: - HomeView
struct HomeView: View {
    // 环境对象
    @EnvironmentObject private var navigationManager: AppNavigationManager
    @EnvironmentObject private var authManager: AuthManager
    
    // ViewModel
    @StateObject private var viewModel: HomeViewModel
    
    // 状态变量
    @State private var searchText = ""
    @State private var isNavBarVisible = true
    @State private var debouncedSearch = ""
    @State private var searchWorkItem: DispatchWorkItem?
    
    // 常量
    private let navBarHeight: CGFloat = 44
    private let searchBarHeight: CGFloat = 40
    private let totalHeaderHeight: CGFloat = 92
    private let topContentPadding: CGFloat = 100 // 增加额外顶部间距避免遮挡
    
    // 添加初始化方法
    init() {
        // 使用环境中注册的PostService
        let postService = AppEnvironment.shared.postService
        _viewModel = StateObject(wrappedValue: HomeViewModel(postService: postService))
    }
    
    var body: some View {
        ZStack(alignment: .top) {
            // 主内容区
            mainContent
            
            // 导航栏和搜索栏
            VStack(spacing: 1) {
                customNavigationBar
                
                SearchAndFilterView(search: $searchText)
                    .padding(.vertical, 2)
                    .padding(.bottom, 8)
                    .onChange(of: searchText) { newValue in
                        debounceSearchText(newValue)
                    }
            }
            .frame(height: totalHeaderHeight)
            .background(Color.white)
            .offset(y: isNavBarVisible ? 0 : -totalHeaderHeight)
            .opacity(isNavBarVisible ? 1 : 0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isNavBarVisible)
            .zIndex(10) // 确保在最上层
        }
        .background(Color.white)
        .navigationBarHidden(true)
        .onAppear {
            viewModel.loadInitialData()
        }
        // 在这里添加浮动操作按钮作为overlay
           .overlay(alignment: .bottomTrailing) {
               createTopicButton
           }
           // 添加sheet呈现CreateTopicView
           .sheet(isPresented: $showCreateTopicView) {
               CreateTopicView()
                   .interactiveDismissDisabled(true)
           }
        
    }
    // 添加这些属性到HomeView结构体中
    @State private var showCreateTopicView = false

    // 添加这个计算属性到HomeView结构体中
    private var createTopicButton: some View {
        Button(action: {
            showCreateTopicView = true
        }) {
            Image(systemName: "plus")
                .font(.system(size: 22))
                .foregroundColor(.white)
                .frame(width: 60, height: 60)
                .background(Circle().fill(Color.blue))
                .shadow(color: Color.black.opacity(0.3), radius: 5, x: 0, y: 2)
        }
        .padding([.bottom, .trailing], 20)
    }
    // 自定义导航栏
    private var customNavigationBar: some View {
        HStack {
            // 左侧菜单按钮
            Button(action: {
                // 触发侧边菜单
            }) {
                Image(systemName: "line.horizontal.3")
                    .resizable()
                    .frame(width: 20, height: 15)
                    .foregroundColor(.black)
            }
            
            Spacer()
            
            // 中间标题和位置
            VStack(spacing: 2) {
                Text("附近话题")
                    .font(.headline)
                    .fontWeight(.bold)
                
                HStack(spacing: 4) {
                    Image(systemName: "location.fill")
                        .font(.caption2)
                    Text("东京都 新宿区")
                        .font(.caption)
                }
                .foregroundColor(.gray)
            }
            
            Spacer()
            
            // 右侧通知按钮
            Button(action: {
                // 通知操作
            }) {
                Image(systemName: "bell")
                    .foregroundColor(.black)
            }
        }
        .padding(.horizontal)
        .frame(height: navBarHeight)
        .background(Color.white)
    }
    
    // 主内容区
    private var mainContent: some View {
        OptimizedScrollView(
            showsIndicator: true,
            onStateChange: { isVisible in
                isNavBarVisible = isVisible
            },
            onBottomReached: {
                // 滚动到底部时触发加载更多
                if !viewModel.isLoadingMore && !viewModel.isRefreshing && debouncedSearch.isEmpty && viewModel.hasMoreData {
                    Logger.debug("滚动到底部，触发加载更多")
                    viewModel.loadMoreTopics()
                }
            }
        ) {
            LazyVStack(spacing: 16) {
                // 顶部安全区域间距，避免被导航栏遮挡
                Color.clear
                    .frame(height: topContentPadding)
                
                // 热门话题
                trendingTopicsSection
                
                // 话题分类
                topicCategoriesSection
                
                // 最新话题列表
                recentTopicsSection
                
                // 加载更多区域
                loadMoreSection
                    .padding(.bottom, 20)
            }
            .padding(.horizontal)
            .background(
                // 在滚动到顶部时触发下拉刷新
                GeometryReader { geo in
                    if geo.frame(in: .global).minY > 80 && !viewModel.isRefreshing {
                        Color.clear.onAppear {
                            viewModel.refresh()
                        }
                    } else {
                        Color.clear
                    }
                }
            )
        }
        .onAppear {
            // 首次加载
            if viewModel.recentTopics.isEmpty && !viewModel.isLoading {
                viewModel.loadInitialData()
            }
        }
    }
    
    // 热门话题区域
    private var trendingTopicsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("热门话题")
                .font(.headline)
                .fontWeight(.bold)
            
            if viewModel.trendingTopics.isEmpty && viewModel.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, minHeight: 120)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    LazyHStack(spacing: 16) {
                        ForEach(viewModel.trendingTopics) { topic in
                            trendingTopicCard(topic: topic)
                                .id(topic.id)
                        }
                    }
                    .padding(.horizontal)
                }
            }
        }
        .padding(.vertical)
    }
    
    // 话题分类区域 - 使用常量缓存
    private var topicCategoriesSection: some View {
        let cachedCategories = topicCategories
        
        return VStack(alignment: .leading, spacing: 12) {
            Text("话题分类")
                .font(.headline)
                .fontWeight(.bold)
            
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: 16) {
                    ForEach(cachedCategories, id: \.name) { category in
                        categoryItem(category: category)
                    }
                }
                .padding(.horizontal)
            }
        }
        .padding(.vertical)
    }
    
    // 最新话题区域 - 支持分页加载
    private var recentTopicsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("最新发布")
                    .font(.headline)
                    .fontWeight(.bold)
                
                Spacer()
                
                // 显示条数信息
                Text("共\(viewModel.recentTopics.count)条")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            // 过滤话题
            let filteredTopics = debouncedSearch.isEmpty ?
                viewModel.recentTopics :
                viewModel.filterTopics(searchText: debouncedSearch)
            
            if filteredTopics.isEmpty {
                VStack {
                    if viewModel.isLoading {
                        ProgressView("加载中...")
                    } else {
                        Text(debouncedSearch.isEmpty ? "暂无话题" : "未找到匹配的话题")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.vertical, 30)
            } else {
                VStack(spacing: 12) {
                    // 显示下拉刷新中状态
                    if viewModel.isRefreshing {
                        ProgressView("下拉刷新中...")
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(.vertical, 10)
                    }
                    
                    // 话题列表
                    ForEach(filteredTopics) { topic in
                        TopicCard(topic: topic)
                            .padding(.bottom, 4)
                            .id(topic.id)
                            .onAppear {
                                // 显示到最后N条数据时预加载
                                if debouncedSearch.isEmpty &&
                                   topic.id == filteredTopics[max(0, filteredTopics.count - 3)].id &&
                                   !viewModel.isLoadingMore {
                                    Logger.debug("接近最后几条数据，预加载更多")
                                    viewModel.loadMoreTopics()
                                }
                            }
                    }
                }
            }
        }
        .padding(.vertical)
    }
    
    // 加载更多区域
    private var loadMoreSection: some View {
        Group {
            if debouncedSearch.isEmpty {
                if viewModel.isLoadingMore {
                    // 加载更多指示器
                    ProgressView("加载更多中...")
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.vertical, 10)
                } else if viewModel.hasMoreData {
                    // 上拉加载更多提示
                    Button(action: {
                        viewModel.loadMoreTopics()
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: "arrow.down.circle")
                            Text("点击加载更多")
                        }
                        .font(.subheadline)
                        .foregroundColor(.blue)
                        .frame(maxWidth: .infinity)
                        .padding(12)
                    }
                    .padding(.vertical, 10)
                    .contentShape(Rectangle())
                } else {
                    // 没有更多数据提示
                    Text("— 已经到底了 —")
                        .font(.caption)
                        .foregroundColor(.gray)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.vertical, 20)
                }
                
                // 调试信息
                if !viewModel.debugInfo.isEmpty {
                    Text(viewModel.debugInfo)
                        .font(.caption)
                        .foregroundColor(.gray)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.top, 8)
                }
            }
        }
    }
    
    // 热门话题卡片
    private func trendingTopicCard(topic: Topic) -> some View {
        VStack(alignment: .leading) {
            ZStack(alignment: .bottomLeading) {
                // 图片背景
                if !topic.images.isEmpty {
                             FirebaseImageView(imagePath: topic.images[0])
                                 .frame(width: 200, height: 120)
                                 .clipShape(RoundedRectangle(cornerRadius: 12))
                                 .overlay(
                                     LinearGradient(
                                         gradient: Gradient(colors: [Color.clear, Color.black.opacity(0.5)]),
                                         startPoint: .top,
                                         endPoint: .bottom
                                     )
                                     .cornerRadius(12)
                                 )
                         } else {
                             RoundedRectangle(cornerRadius: 12)
                                 .fill(Color.blue.opacity(0.3))
                                 .frame(width: 200, height: 120)
                         }
                
                // 图片上的渐变遮罩
//                LinearGradient(
//                    gradient: Gradient(colors: [Color.clear, Color.black.opacity(0.5)]),
//                    startPoint: .top,
//                    endPoint: .bottom
//                )
//                .cornerRadius(12)
                
                // 底部信息
                        VStack(alignment: .leading, spacing: 2) {
                            Text(topic.title)
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                            
                            HStack {
                                Image(systemName: "person.2.fill")
                                    .font(.caption2)
                                Text("\(topic.participantsCount)人参与")
                                    .font(.caption2)
                                
                                Spacer()
                                
                                Image(systemName: "mappin.circle.fill")
                                    .font(.caption2)
                                Text("\(topic.distance)km")
                                    .font(.caption2)
                            }
                            .foregroundColor(.white.opacity(0.9))
                        }
                        .padding(8)
                    }
            
            // 作者信息
            HStack {
                Image(systemName: "person.circle.fill")
                    .resizable()
                    .frame(width: 20, height: 20)
                    .clipShape(Circle())
                Text(topic.authorName)
                    .font(.caption)
                    .fontWeight(.medium)
            }
            .padding(.top, 4)
            
            // 标签
            if !topic.tags.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack {
                        ForEach(topic.tags, id: \.self) { tag in
                            Text(tag)
                                .font(.system(size: 10))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.blue.opacity(0.1))
                                .foregroundColor(.blue)
                                .cornerRadius(4)
                        }
                    }
                }
            }
        }
        .frame(width: 200)
    }
    
    // 分类项目
    private func categoryItem(category: TopicCategory) -> some View {
        VStack {
            Circle()
                .fill(category.color)
                .frame(width: 60, height: 60)
                .overlay(
                    Image(systemName: category.icon)
                        .imageScale(.large)
                        .foregroundColor(.white)
                )
                .shadow(color: category.color.opacity(0.3), radius: 4, x: 0, y: 2)
            
            Text(category.name)
                .font(.caption)
                .fontWeight(.medium)
                .lineLimit(1)
        }
        .frame(width: 80)
    }
    
    // 搜索防抖实现
    private func debounceSearchText(_ text: String) {
        // 取消之前的任务
        searchWorkItem?.cancel()
        
        // 创建新任务
        let workItem = DispatchWorkItem {
            DispatchQueue.main.async {
                self.debouncedSearch = text
            }
        }
        
        // 存储任务引用
        searchWorkItem = workItem
        
        // 延迟执行
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: workItem)
    }
    
    // 缓存的话题分类数据
    private let topicCategories = [
        TopicCategory(name: "美食", icon: "fork.knife", color: .orange),
        TopicCategory(name: "购物", icon: "cart", color: .blue),
        TopicCategory(name: "活动", icon: "ticket", color: .pink),
        TopicCategory(name: "交友", icon: "person.2", color: .purple),
        TopicCategory(name: "旅行", icon: "airplane", color: .green),
        TopicCategory(name: "求助", icon: "questionmark.circle", color: .red)
    ]
}

// MARK: - 优化的滚动视图组件
struct OptimizedScrollView<Content: View>: View {
    // 配置
    var showsIndicator: Bool
    var onStateChange: (Bool) -> Void
    var onBottomReached: () -> Void  // 新增：滚动到底部的回调
    var content: () -> Content
    
    // 状态
    @State private var isVisible: Bool = true
    @State private var lastOffset: CGFloat = 0
    @State private var initialOffset: CGFloat? = nil
    @State private var lastUpdateTime: Date = Date()
    @State private var lastBottomReachTime: Date = Date.distantPast
    
    // 滚动相关常量
    private let scrollThreshold: CGFloat = 10
    private let topThreshold: CGFloat = 5
    private let updateThreshold: TimeInterval = 0.08 // 80毫秒节流
    private let bottomThreshold: CGFloat = 100 // 距离底部多少时触发
    private let bottomReachThrottle: TimeInterval = 1.0 // 底部触发节流时间
    
    init(
        showsIndicator: Bool = true,
        onStateChange: @escaping (Bool) -> Void,
        onBottomReached: @escaping () -> Void = {},
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.showsIndicator = showsIndicator
        self.onStateChange = onStateChange
        self.onBottomReached = onBottomReached
        self.content = content
    }
    
    var body: some View {
        GeometryReader { outerGeometry in
            ScrollView(showsIndicators: showsIndicator) {
                content()
                    .overlay(
                        GeometryReader { proxy in
                            Color.clear
                                .preference(key: OffsetPreferenceKey.self, value: proxy.frame(in: .global).minY)
                                .onAppear {
                                    initialOffset = proxy.frame(in: .global).minY
                                }
                                .onChange(of: proxy.frame(in: .global).minY) { newOffset in
                                    checkBottomReached(
                                        contentHeight: proxy.size.height,
                                        outerHeight: outerGeometry.size.height,
                                        offset: newOffset
                                    )
                                }
                        }
                    )
            }
            .onPreferenceChange(OffsetPreferenceKey.self) { offset in
                // 确保初始偏移量已设置
                guard let initialOffset = initialOffset else {
                    self.initialOffset = offset
                    return
                }
                
                // 添加节流逻辑
                let now = Date()
                guard now.timeIntervalSince(lastUpdateTime) >= updateThreshold else { return }
                
                // 计算滑动方向
                let direction = offset - lastOffset
                
                // 判断是否在顶部区域
                let isAtOrNearTop = offset >= initialOffset - topThreshold
                
                // 更新导航栏显示状态
                if abs(direction) > scrollThreshold {
                    if direction < 0 && isVisible && !isAtOrNearTop {
                        // 向下滑动且不在顶部区域，隐藏导航栏
                        isVisible = false
                        onStateChange(false)
                        lastUpdateTime = now
                    } else if direction > 0 && !isVisible {
                        // 向上滑动，显示导航栏
                        isVisible = true
                        onStateChange(true)
                        lastUpdateTime = now
                    }
                }
                
                // 在顶部区域时强制显示导航栏
                if isAtOrNearTop && !isVisible {
                    isVisible = true
                    onStateChange(true)
                    lastUpdateTime = now
                }
                
                // 更新上次偏移量
                lastOffset = offset
            }
        }
    }
    
    // 检查是否滚动到底部
    private func checkBottomReached(contentHeight: CGFloat, outerHeight: CGFloat, offset: CGFloat) {
        let now = Date()
        
        // 计算实际偏移量，处理负值问题
        let initialValue = initialOffset ?? 0
        let adjustedOffset = initialValue - offset
        
        // 计算底部触发阈值
        let triggerThreshold = contentHeight - outerHeight - bottomThreshold
        
        // 当滚动超过阈值且未在节流期内时触发回调
        if adjustedOffset > triggerThreshold && adjustedOffset > 0 {
            if now.timeIntervalSince(lastBottomReachTime) >= bottomReachThrottle {
                lastBottomReachTime = now
                Logger.debug("触发onBottomReached，内容高度: \(contentHeight), 视图高度: \(outerHeight), 调整后偏移: \(adjustedOffset), 阈值: \(triggerThreshold)")
                onBottomReached()
            }
        }
    }
}

// MARK: - 偏移量PreferenceKey
struct OffsetPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}
// MARK: - 数据模型
struct Topic: Identifiable {
    let id: String
    let title: String
    let content: String
    let authorName: String
    let location: String
    let tags: [String]
    let participantsCount: Int
    let postedTime: String
    let distance: Double
    var isLiked: Bool
    let images: [String]
    let firebaseImagePaths: [String]  // 新增字段，保存原始路径
    var imageURLs: [URL] = []  // 新增字段，保存加载后的URL
}

struct TopicCategory {
    let name: String
    let icon: String
    let color: Color
}

// MARK: - 预览
#if DEBUG
struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView()
            .environmentObject(AppNavigationManager.shared)
            .environmentObject(AuthManager(
                authService: AppEnvironment.shared.authService,
                sessionManager: AppEnvironment.shared.sessionManager,
                keychainManager: AppEnvironment.shared.keychainManager
            ))
    }
}
#endif
