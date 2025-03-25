import SwiftUI

// MARK: - HomeView
struct HomeView: View {
    // 环境对象
    @EnvironmentObject private var navigationManager: AppNavigationManager
    @EnvironmentObject private var authManager: AuthManager
    
    // 状态变量
    @State private var searchText = ""
    @State private var isRefreshing = false
    @State private var isNavBarVisible = true
    
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
            }
            .frame(height: 92)
            .background(Color.white)
            .offset(y: isNavBarVisible ? 0 : -92)
            .opacity(isNavBarVisible ? 1 : 0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isNavBarVisible)
        }
        .background(Color.white)
        .navigationBarHidden(true)
    }
    
    // 自定义导航栏
    private var customNavigationBar: some View {
        HStack {
            // 左侧菜单按钮
            Button(action: {
                // 触发侧边菜单
               // navigationManager.toggleMenu()
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
        .frame(height: 44)
        .background(Color.white)
    }
    
    // 主内容区
    private var mainContent: some View {
        TabStateScrollView(
            axis: .vertical,
            showsIndicator: true,
            onStateChange: { isVisible in
                isNavBarVisible = isVisible
            }
        ) {
            LazyVStack(spacing: 16) {
                // 添加固定高度的占位空间
                Color.clear
                    .frame(height: 92)
                
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
    }
    
    // 热门话题区域
    private var trendingTopicsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("热门话题")
                .font(.headline)
                .fontWeight(.bold)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(trendingTopics) { topic in
                        trendingTopicCard(topic: topic)
                    }
                }
            }
        }
        .padding(.vertical)
    }
    
    // 话题分类区域
    private var topicCategoriesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("话题分类")
                .font(.headline)
                .fontWeight(.bold)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(topicCategories, id: \.name) { category in
                        categoryItem(category: category)
                    }
                }
            }
        }
        .padding(.vertical)
    }
    
    // 最新话题区域
    private var recentTopicsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("最新发布")
                .font(.headline)
                .fontWeight(.bold)
            
            ForEach(recentTopics) { topic in
                TopicCard(topic: topic)
                    .padding(.bottom, 8)
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
    
    // 测试数据
    private let topicCategories = [
        TopicCategory(name: "美食", icon: "fork.knife", color: .orange),
        TopicCategory(name: "购物", icon: "cart", color: .blue),
        TopicCategory(name: "活动", icon: "ticket", color: .pink),
        TopicCategory(name: "交友", icon: "person.2", color: .purple),
        TopicCategory(name: "旅行", icon: "airplane", color: .green),
        TopicCategory(name: "求助", icon: "questionmark.circle", color: .red)
    ]
    
    private var trendingTopics: [Topic] = [
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
    
    private var recentTopics: [Topic] = [
        Topic(
            id: "5",
            title: "求推荐拉面店",
            content: "刚搬到新宿，有什么好吃的拉面店推荐吗？最好是本地人喜欢去的那种。刚搬到新宿，有什么好吃的拉面店推荐吗？最好是本地人喜欢去的那种。刚搬到新宿，有什么好吃的拉面店推荐吗？最好是本地人喜欢去的那种。刚搬到新宿，有什么好吃的拉面店推荐吗？最好是本地人喜欢去的那种。刚搬到新宿，有什么好吃的拉面店推荐吗？最好是本地人喜欢去的那种。刚搬到新宿，有什么好吃的拉面店推荐吗？最好是本地人喜欢去的那种。刚搬到新宿，有什么好吃的拉面店推荐吗？最好是本地人喜欢去的那种。",
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

// MARK: - TopicCard
struct TopicCard: View {
    let topic: Topic
    @State private var isLiked: Bool
    
    init(topic: Topic) {
        self.topic = topic
        self._isLiked = State(initialValue: topic.isLiked)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 作者信息和点赞按钮
            HStack(alignment: .center) {
                // 头像和作者信息
                HStack(spacing: 8) {
                    Image(systemName: "person.circle.fill")
                        .resizable()
                        .frame(width: 40, height: 40)
                        .foregroundColor(.gray)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(topic.authorName)
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        HStack {
                            Image(systemName: "location.circle.fill")
                                .foregroundColor(.gray)
                                .font(.caption2)
                            Text(topic.location)
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                    }
                }
                
                Spacer()
                
                // 点赞按钮
                Button(action: {
                    isLiked.toggle()
                }) {
                    Image(systemName: isLiked ? "heart.fill" : "heart")
                        .foregroundColor(isLiked ? .red : .gray)
                }
            }
            
            // 标题和内容
            Text(topic.title)
                .font(.headline)
                .fontWeight(.bold)
            
            Text(topic.content)
                .font(.subheadline)
                .foregroundColor(.black)
                .lineLimit(3)
            
            // 图片（如果有）
            if !topic.images.isEmpty {
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
            
            // 标签
            if !topic.tags.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack {
                        ForEach(topic.tags, id: \.self) { tag in
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
            
            // 底部信息
            HStack {
                // 参与人数
                HStack(spacing: 4) {
                    Image(systemName: "person.2")
                        .font(.caption)
                    Text("\(topic.participantsCount)人参与")
                        .font(.caption)
                }
                .foregroundColor(.gray)
                
                Spacer()
                
                // 发布时间
                HStack(spacing: 4) {
                    Image(systemName: "clock")
                        .font(.caption)
                    Text(topic.postedTime)
                        .font(.caption)
                }
                .foregroundColor(.gray)
                
                Spacer()
                
                // 距离
                HStack(spacing: 4) {
                    Image(systemName: "location")
                        .font(.caption)
                    Text("\(topic.distance)km")
                        .font(.caption)
                }
                .foregroundColor(.gray)
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}

// MARK: - SearchAndFilterView
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
                    .accentColor(.gray)
                    .textInputAutocapitalization(.none)
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

// MARK: - TabStateScrollView
struct TabStateScrollView<Content: View>: View {
    // MARK: - Properties
    var axis: Axis.Set
    var showsIndicator: Bool
    var onStateChange: (Bool) -> Void
    var content: Content
    
    // MARK: - State
    @State private var isVisible: Bool = true
    @State private var lastOffset: CGFloat = 0
    @State private var initialOffset: CGFloat? = nil
    
    // 滑动和顶部判断的阈值
    private let scrollThreshold: CGFloat = 10
    private let topThreshold: CGFloat = 5
    
    // MARK: - Initialization
    init(
        axis: Axis.Set,
        showsIndicator: Bool,
        onStateChange: @escaping (Bool) -> Void,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.axis = axis
        self.showsIndicator = showsIndicator
        self.onStateChange = onStateChange
        self.content = content()
    }
    
    var body: some View {
        ScrollView(axis, showsIndicators: showsIndicator) {
            content
                .overlay(
                    GeometryReader { proxy in
                        Color.clear
                            .preference(key: OffsetPreferenceKey.self, value: proxy.frame(in: .global).minY)
                            .onAppear {
                                // 记录初始偏移量，用于判断顶部位置
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
                } else if direction > 0 && !isVisible {
                    // 向上滑动，显示导航栏
                    isVisible = true
                    onStateChange(true)
                }
            }
            
            // 在顶部区域时强制显示导航栏
            if isAtOrNearTop && !isVisible {
                isVisible = true
                onStateChange(true)
            }
            
            // 更新上次偏移量
            lastOffset = offset
        }
    }
}

// 保持原有的 OffsetPreferenceKey 定义
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
            .environmentObject(AppNavigationManager.preview)
            .environmentObject(AuthManager(
                authService: AppEnvironment.shared.authService,
                sessionManager: AppEnvironment.shared.sessionManager,
                keychainManager: AppEnvironment.shared.keychainManager
            ))
    }
}
#endif
