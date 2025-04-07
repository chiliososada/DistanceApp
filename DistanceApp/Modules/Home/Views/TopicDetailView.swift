//
//  TopicDetailView.swift
//  DistanceApp
//

import SwiftUI

struct TopicDetailView: View {
    // 话题数据
    let topic: Topic
    
    // 状态变量
    @State private var isLiked: Bool
    @State private var selectedImageIndex: Int = 0
    @State private var imageURLs: [URL] = []
    @State private var isLoadingImages: Bool = true
    
    // 环境变量
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    
    // 颜色和风格
    private let accentColor = Color.blue
    private let backgroundColor = Color(.systemBackground)
    private let cardBackgroundColor = Color(.secondarySystemBackground).opacity(0.5)
    
    // 初始化
    init(topic: Topic) {
        self.topic = topic
        self._isLiked = State(initialValue: topic.isLiked)
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // 顶部作者信息卡片
                authorInfoCard
                
                // 内容区域
                VStack(alignment: .leading, spacing: 16) {
                    // 标题
                    Text(topic.title)
                        .font(.title2)
                        .fontWeight(.bold)
                        .fixedSize(horizontal: false, vertical: true)
                    
                    // 图片部分
                    if !topic.images.isEmpty {
                        imageGallerySection
                    }
                    
                    // 内容部分
                    contentSection
                    
                    // 标签部分
                    if !topic.tags.isEmpty {
                        tagsSection
                    }
                    
                    // 底部信息部分
                    footerInfoSection
                }
                .padding(.horizontal)
                
                // 操作按钮
                actionButtonsBar
            }
            .padding(.top)
            .padding(.bottom, 80)
        }
        .background(backgroundColor.ignoresSafeArea())
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("话题详情")
                    .font(.headline)
                    .fontWeight(.medium)
            }
            
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    // 分享功能
                }) {
                    Image(systemName: "square.and.arrow.up")
                        .foregroundColor(accentColor)
                }
            }
        }
        .onAppear {
            loadImages()
        }
    }
    
    // MARK: - UI组件
    
    // 作者信息卡片
    private var authorInfoCard: some View {
        VStack {
            HStack(spacing: 14) {
                // 头像
                Circle()
                    .fill(Color.gray.opacity(0.2))
                    .frame(width: 50, height: 50)
                    .overlay(
                        Image(systemName: "person.fill")
                            .resizable()
                            .scaledToFit()
                            .padding(12)
                            .foregroundColor(.gray)
                    )
                    .overlay(
                        Circle()
                            .stroke(Color.white, lineWidth: 2)
                    )
                    .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
                
                // 作者信息
                VStack(alignment: .leading, spacing: 4) {
                    Text(topic.authorName)
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    HStack(spacing: 8) {
                        // 位置信息
                        HStack(spacing: 3) {
                            Image(systemName: "location.fill")
                                .font(.caption2)
                                .foregroundColor(.gray)
                            Text(topic.location)
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                        
                        // 分隔符
                        Text("•")
                            .foregroundColor(.gray)
                            .font(.caption)
                        
                        // 发布时间
                        Text(topic.postedTime)
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
                
                Spacer()
            }
            .padding(.horizontal)
            .padding(.vertical, 12)
        }
        .background(cardBackgroundColor)
    }
    
    // 图片轮播部分 - 修复重复指示器问题
    private var imageGallerySection: some View {
        VStack(spacing: 8) {
            // 主图片显示区域
            ZStack {
                if isLoadingImages {
                    // 加载中状态
                    Rectangle()
                        .fill(Color.gray.opacity(0.1))
                        .frame(height: 300)
                        .cornerRadius(12)
                        .overlay(
                            ProgressView()
                                .scaleEffect(1.2)
                        )
                } else if imageURLs.isEmpty {
                    // 无图片状态
                    Rectangle()
                        .fill(Color.gray.opacity(0.1))
                        .frame(height: 300)
                        .cornerRadius(12)
                        .overlay(
                            VStack(spacing: 8) {
                                Image(systemName: "photo")
                                    .font(.largeTitle)
                                    .foregroundColor(.gray)
                                
                                Text("无法加载图片")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                        )
                } else {
                    // 显示当前选中的图片
                    TabView(selection: $selectedImageIndex) {
                        ForEach(0..<imageURLs.count, id: \.self) { index in
                            GeometryReader { proxy in
                                AsyncImage(url: imageURLs[index]) { phase in
                                    switch phase {
                                    case .empty:
                                        ProgressView()
                                            .frame(width: proxy.size.width, height: proxy.size.height)
                                    case .success(let image):
                                        image
                                            .resizable()
                                            .aspectRatio(contentMode: .fill)
                                            .frame(width: proxy.size.width, height: proxy.size.height)
                                            .clipped()
                                    case .failure:
                                        Image(systemName: "exclamationmark.triangle")
                                            .font(.largeTitle)
                                            .foregroundColor(.gray)
                                            .frame(width: proxy.size.width, height: proxy.size.height)
                                    @unknown default:
                                        EmptyView()
                                    }
                                }
                                .cornerRadius(12)
                            }
                            .tag(index)
                        }
                    }
                    .frame(height: 300)
                    .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never)) // 不显示内置指示器
                    
                    // 自定义指示器
                    if imageURLs.count > 1 {
                        HStack(spacing: 8) {
                            ForEach(0..<imageURLs.count, id: \.self) { index in
                                Circle()
                                    .fill(index == selectedImageIndex ? accentColor : Color.gray.opacity(0.5))
                                    .frame(width: 8, height: 8)
                                    .animation(.easeInOut, value: selectedImageIndex)
                                    .transition(.scale)
                            }
                        }
                        .padding(.vertical, 8)
                        .padding(.horizontal, 12)
                        .background(Color.black.opacity(0.4))
                        .cornerRadius(20)
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(Color.white.opacity(0.2), lineWidth: 1)
                        )
                        .offset(y: 125) // 放在图片底部
                    }
                }
            }
        }
        .padding(.vertical, 8)
    }
    
    // 内容部分
    private var contentSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(topic.content)
                .font(.body)
                .lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.bottom, 8)
            
            Divider()
                .background(Color.gray.opacity(0.3))
        }
        .padding(.vertical, 4)
    }
    
    // 标签部分
    private var tagsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("标签")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.secondary)
            
            FlowLayout(spacing: 8) {
                ForEach(topic.tags, id: \.self) { tag in
                    Text(tag)
                        .font(.subheadline)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 7)
                        .background(accentColor.opacity(0.1))
                        .foregroundColor(accentColor)
                        .cornerRadius(20)
                }
            }
        }
        .padding(.vertical, 4)
    }
    
    // 底部信息部分
    private var footerInfoSection: some View {
        HStack(spacing: 20) {
            // 参与人数
            HStack(spacing: 6) {
                Image(systemName: "person.2.fill")
                    .foregroundColor(.gray)
                Text("\(topic.participantsCount)人参与")
                    .foregroundColor(.gray)
            }
            .font(.subheadline)
            
            Spacer()
            
            // 距离
            HStack(spacing: 6) {
                Image(systemName: "location.fill")
                    .foregroundColor(.gray)
                Text("\(String(format: "%.1f", topic.distance))km")
                    .foregroundColor(.gray)
            }
            .font(.subheadline)
        }
        .padding(.vertical, 12)
    }
    
    // 操作按钮栏
    private var actionButtonsBar: some View {
            VStack {
                HStack(spacing: 16) {
                    // 喜欢按钮 - 变小并移到左侧
                    Button(action: {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                            isLiked.toggle()
                        }
                    }) {
                        Label {
                            Text("喜欢")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        } icon: {
                            Image(systemName: isLiked ? "heart.fill" : "heart")
                                .foregroundColor(isLiked ? .red : .gray)
                                .font(.body)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(20)
                    }
                    
                    Spacer()
                    
                    // 进入聊天室按钮 - 大按钮，主要操作
                    Button(action: {
                        // 进入聊天室操作
                    }) {
                        HStack(spacing: 10) {
                            Image(systemName: "bubble.left.and.bubble.right.fill")
                                .font(.headline)
                            
                            Text("进入聊天室")
                                .font(.headline)
                                .fontWeight(.semibold)
                        }
                        .padding(.horizontal, 24)
                        .padding(.vertical, 14)
                        .foregroundColor(.white)
                        .background(accentColor)
                        .cornerRadius(25)
                        .shadow(color: accentColor.opacity(0.4), radius: 4, x: 0, y: 2)
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 16)
                .background(backgroundColor)
                .overlay(
                    Rectangle()
                        .frame(height: 1)
                        .foregroundColor(Color.gray.opacity(0.2)),
                    alignment: .top
                )
            }
            .background(
                backgroundColor
                    .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: -2)
            )
            .frame(maxWidth: .infinity)
        }
    // MARK: - 辅助方法
    
    // 加载图片
    private func loadImages() {
        guard !topic.images.isEmpty else {
            isLoadingImages = false
            return
        }
        
        isLoadingImages = true
        
        Task {
            // 加载图片URL
            let urls = await loadImageURLs(for: topic.images)
            
            await MainActor.run {
                imageURLs = urls
                isLoadingImages = false
            }
        }
    }
    
    // 从Firebase Storage加载图片URL
    private func loadImageURLs(for paths: [String]) async -> [URL] {
        var urls: [URL] = []
        
        for path in paths {
            do {
                let url = try await FirebaseStorageService.shared.getImageURL(for: path)
                urls.append(url)
            } catch {
                Logger.warning("加载图片URL失败: \(path)")
            }
        }
        
        return urls
    }
}



#if DEBUG
struct TopicDetailView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            TopicDetailView(topic: Topic(
                id: "1",
                title: "这是一个测试话题标题",
                content: "这里是话题的详细内容，可能包含很多文字。这是一个测试内容，用于预览TopicDetailView的显示效果。内容可能会很长，需要进行适当的换行和布局调整。",
                authorName: "测试用户",
                location: "东京都 新宿区",
                tags: ["标签1", "标签2", "长一点的标签3"],
                participantsCount: 42,
                postedTime: "3小时前",
                distance: 2.5,
                isLiked: false,
                images: [],
                firebaseImagePaths: []
            ))
        }
    }
}
#endif
