//
//  HomeViewParts.swift
//  DistanceApp
//
//  Created by toyousoft on 2025/04/01.
//
import SwiftUI
import Combine
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
    @State private var loadedImageURLs: [URL] = []
    @State private var isLoadingImages = false
    
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
                if isLoadingImages {
                    // 加载中状态
                    ZStack {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.gray.opacity(0.2))
                            .frame(height: 180)
                        
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle())
                    }
                    .frame(maxWidth: .infinity)
                } else if !loadedImageURLs.isEmpty {
                    // 显示第一张图片
                    AsyncImage(url: loadedImageURLs[0]) { phase in
                        switch phase {
                        case .empty:
                            Rectangle()
                                .fill(Color.gray.opacity(0.2))
                                .frame(height: 180)
                                .cornerRadius(8)
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(height: 180)
                                .cornerRadius(8)
                                .clipped()
                        case .failure:
                            ZStack {
                                Rectangle()
                                    .fill(Color.gray.opacity(0.2))
                                    .frame(height: 180)
                                    .cornerRadius(8)
                                
                                Image(systemName: "exclamationmark.triangle")
                                    .foregroundColor(.gray)
                            }
                        @unknown default:
                            EmptyView()
                        }
                    }
                    .frame(maxWidth: .infinity)
                    
                    // 显示图片数量指示器
                    if loadedImageURLs.count > 1 {
                        Text("+\(loadedImageURLs.count - 1) 张图片")
                            .font(.caption)
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.black.opacity(0.5))
                            .cornerRadius(4)
                            .offset(x: 0, y: -30)
                            .frame(maxWidth: .infinity, alignment: .trailing)
                            .padding(.trailing, 8)
                    }
                } else {
                    // 默认占位符
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
        .onAppear {
            loadImagesIfNeeded()
        }
    }
    
    private func loadImagesIfNeeded() {
        // 避免重复加载
        guard !isLoadingImages && loadedImageURLs.isEmpty && !images.isEmpty else {
            return
        }
        
        isLoadingImages = true
        
        Task {
            // 加载图片URL
            let urls = await loadImageURLs(for: images)
            
            await MainActor.run {
                loadedImageURLs = urls
                isLoadingImages = false
            }
        }
    }
    
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
