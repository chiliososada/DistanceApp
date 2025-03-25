import SwiftUI
import Combine

// MARK: - HomeView
struct HomeView: View {
    // 环境对象
    @EnvironmentObject private var navigationManager: AppNavigationManager
    @EnvironmentObject private var authManager: AuthManager
    
    // ViewModel
    @StateObject private var viewModel = HomeViewModel()
    
    // 状态变量
    @State private var searchText = ""
    @State private var isNavBarVisible = true
    @State private var debouncedSearch = ""
    @State private var searchWorkItem: DispatchWorkItem?
    
    // 常量
    private let navBarHeight: CGFloat = 44
    private let searchBarHeight: CGFloat = 40
    private let totalHeaderHeight: CGFloat = 92
    
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
        }
        .background(Color.white)
        .navigationBarHidden(true)
        .onAppear {
            viewModel.loadInitialData()
        }
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
            }
        ) {
            LazyVStack(spacing: 16) {
                // 添加固定高度的占位空间
                Color.clear
                    .frame(height: totalHeaderHeight)
                
            
                
                // 热门话题
                trendingTopicsSection
                
                // 话题分类
                topicCategoriesSection
                
                // 最新话题列表
                recentTopicsSection
                    .padding(.bottom, 20)
            }
            .padding(.horizontal)
            .padding(.top, 8)
        }
        .pullToRefresh(isShowing: $viewModel.isRefreshing, onRefresh: {
            viewModel.refresh()
        })
    }
    
    // 热门话题区域
    private var trendingTopicsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("热门话题")
                .font(.headline)
                .fontWeight(.bold)
            
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
            Text("最新发布")
                .font(.headline)
                .fontWeight(.bold)
            
            // 过滤话题
            let filteredTopics = debouncedSearch.isEmpty ?
                viewModel.recentTopics :
                viewModel.filterTopics(searchText: debouncedSearch)
            
            if filteredTopics.isEmpty {
                Text("未找到匹配的话题")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 30)
            } else {
                ForEach(filteredTopics) { topic in
                    TopicCard(topic: topic)
                        .padding(.bottom, 8)
                        .id(topic.id)
                        .onAppear {
                            // 如果显示了最后一个项目，并且没有在搜索，加载更多
                            if topic.id == filteredTopics.last?.id && debouncedSearch.isEmpty {
                                viewModel.loadMoreTopics()
                            }
                        }
                }
            }
            
            // 加载更多指示器
            if viewModel.isLoadingMore && debouncedSearch.isEmpty {
                ProgressView()
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            }
        }
        .padding(.vertical)
    }
    
    // 热门话题卡片
    private func trendingTopicCard(topic: Topic) -> some View {
        VStack(alignment: .leading) {
            ZStack(alignment: .bottomLeading) {
                // 图片背景
                if !topic.images.isEmpty {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.blue.opacity(0.3))
                        .frame(width: 200, height: 120)
                        .overlay(
                            Image(systemName: "photo")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 40)
                                .foregroundColor(.white)
                        )
                } else {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.blue.opacity(0.3))
                        .frame(width: 200, height: 120)
                }
                
                // 图片上的渐变遮罩
                LinearGradient(
                    gradient: Gradient(colors: [Color.clear, Color.black.opacity(0.5)]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .cornerRadius(12)
                
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
    var content: () -> Content
    
    // 状态
    @State private var isVisible: Bool = true
    @State private var lastOffset: CGFloat = 0
    @State private var initialOffset: CGFloat? = nil
    @State private var lastUpdateTime: Date = Date()
    
    // 滚动相关常量
    private let scrollThreshold: CGFloat = 10
    private let topThreshold: CGFloat = 5
    private let updateThreshold: TimeInterval = 0.08 // 80毫秒节流
    
    init(
        showsIndicator: Bool = true,
        onStateChange: @escaping (Bool) -> Void,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.showsIndicator = showsIndicator
        self.onStateChange = onStateChange
        self.content = content
    }
    
    var body: some View {
        ScrollView(showsIndicators: showsIndicator) {
            content()
                .overlay(
                    GeometryReader { proxy in
                        Color.clear
                            .preference(key: OffsetPreferenceKey.self, value: proxy.frame(in: .global).minY)
                            .onAppear {
                                initialOffset = proxy.frame(in: .global).minY
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

// MARK: - TopicCard和其子组件
struct TopicCard: View {
    let topic: Topic
    @State private var isLiked: Bool
    
    init(topic: Topic) {
        self.topic = topic
        self._isLiked = State(initialValue: topic.isLiked)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 头部
            TopicCardHeader(
                authorName: topic.authorName,
                location: topic.location,
                isLiked: $isLiked
            )
            
            // 标题和内容
            TopicCardContent(
                title: topic.title,
                content: topic.content,
                images: topic.images
            )
            
            // 标签
            if !topic.tags.isEmpty {
                TopicCardTags(tags: topic.tags)
            }
            
            // 底部信息
            TopicCardFooter(
                participantsCount: topic.participantsCount,
                postedTime: topic.postedTime,
                distance: topic.distance
            )
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}

struct TopicCardHeader: View {
    let authorName: String
    let location: String
    @Binding var isLiked: Bool
    
    var body: some View {
        HStack(alignment: .center) {
            // 头像和作者信息
            HStack(spacing: 8) {
                Image(systemName: "person.circle.fill")
                    .resizable()
                    .frame(width: 40, height: 40)
                    .foregroundColor(.gray)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(authorName)
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    HStack {
                        Image(systemName: "location.circle.fill")
                            .foregroundColor(.gray)
                            .font(.caption2)
                        Text(location)
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
            }
            
            Spacer()
            
            // 点赞按钮
            Button(action: {
                withAnimation(.spring()) {
                    isLiked.toggle()
                }
            }) {
                Image(systemName: isLiked ? "heart.fill" : "heart")
                    .foregroundColor(isLiked ? .red : .gray)
            }
        }
    }
}

struct TopicCardContent: View {
    let title: String
    let content: String
    let images: [String]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
                .fontWeight(.bold)
            
            Text(content)
                .font(.subheadline)
                .foregroundColor(.black)
                .lineLimit(3)
            
            // 图片（如果有）
            if !images.isEmpty {
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 180)
                    
                    Image(systemName: "photo")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(height: 40)
                        .foregroundColor(.blue)
                }
                .frame(maxWidth: .infinity)
            }
        }
    }
}

struct TopicCardTags: View {
    let tags: [String]
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            LazyHStack {
                ForEach(tags, id: \.self) { tag in
                    Text(tag)
                        .font(.caption)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Color.blue.opacity(0.1))
                        .foregroundColor(.blue)
                        .cornerRadius(15)
                }
            }
        }
    }
}

struct TopicCardFooter: View {
    let participantsCount: Int
    let postedTime: String
    let distance: Double
    
    var body: some View {
        HStack {
            // 参与人数
            HStack(spacing: 4) {
                Image(systemName: "person.2")
                    .font(.caption)
                Text("\(participantsCount)人参与")
                    .font(.caption)
            }
            .foregroundColor(.gray)
            
            Spacer()
            
            // 发布时间
            HStack(spacing: 4) {
                Image(systemName: "clock")
                    .font(.caption)
                Text(postedTime)
                    .font(.caption)
            }
            .foregroundColor(.gray)
            
            Spacer()
            
            // 距离
            HStack(spacing: 4) {
                Image(systemName: "location")
                    .font(.caption)
                Text("\(distance)km")
                    .font(.caption)
            }
            .foregroundColor(.gray)
        }
    }
}

// MARK: - 优化的搜索和筛选组件
struct SearchAndFilterView: View {
    @Binding var search: String
    @State private var isShowingFilter = false
    
    var body: some View {
        HStack(spacing: 8) {
            // 搜索框
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.gray)
                    .frame(width: 20)
                
                TextField("搜索话题、标签或用户", text: $search)
                    .padding(.vertical, 2)
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(.black)
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
            }
            .padding(8)
            .background {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(UIColor.white))
            }
            .overlay {
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.gray, lineWidth: 1)
            }
            
            // 筛选按钮
            Button(action: { isShowingFilter.toggle() }) {
                Image(systemName: "slider.horizontal.3")
                    .foregroundColor(.black)
                    .frame(width: 20, height: 20)
                    .padding(8)
                    .background {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color(UIColor.white))
                    }
                    .overlay {
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.gray, lineWidth: 1)
                    }
            }
        }
        .padding(.horizontal)
        .sheet(isPresented: $isShowingFilter) {
            // 这里应该是筛选视图，但现在用一个占位符
            Text("筛选选项")
                .padding()
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

// MARK: - 下拉刷新修饰器
struct PullToRefresh: ViewModifier {
    @Binding var isShowing: Bool
    let onRefresh: () -> Void
    @State private var offset: CGFloat = 0
    
    private let threshold: CGFloat = 80
    
    func body(content: Content) -> some View {
        ZStack(alignment: .top) {
            // 添加明确的刷新指示器
            if isShowing {
                ProgressView("下拉刷新中...")
                    .frame(maxWidth: .infinity)
                    .padding(.top, 10)
                    .zIndex(1) // 确保显示在最上层
            }
            
            GeometryReader { geometry in
                content
                    .offset(y: isShowing ? threshold : 0)
                    .onChange(of: offset) { newValue in
                        if newValue > threshold && !isShowing {
                            isShowing = true
                            onRefresh()
                        }
                    }
                    .preference(key: OffsetPreferenceKey.self, value: geometry.frame(in: .global).minY)
            }
            .onPreferenceChange(OffsetPreferenceKey.self) { value in
                if value > 0 {
                    offset = value
                }
            }
        }
    }
}

extension View {
    func pullToRefresh(isShowing: Binding<Bool>, onRefresh: @escaping () -> Void) -> some View {
        self.modifier(PullToRefresh(isShowing: isShowing, onRefresh: onRefresh))
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
