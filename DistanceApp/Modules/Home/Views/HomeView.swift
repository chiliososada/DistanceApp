import SwiftUI

struct HomeView: View {
    // 环境对象
    @EnvironmentObject private var navigationManager: AppNavigationManager
    @EnvironmentObject private var authManager: AuthManager
    
    // 状态变量
    @State private var searchText = ""
    @State private var isRefreshing = false
    
    var body: some View {
        VStack {
            // 搜索栏
            searchBar
            
            // 内容区域
            ScrollView {
                // 顶部卡片
                featuredContentCard
                
                // 分类列表
                categoriesList
                
                // 推荐列表
                recommendationsList
            }
            .refreshable {
                // 模拟刷新操作
                isRefreshing = true
                try? await Task.sleep(nanoseconds: 1_000_000_000)
                isRefreshing = false
            }
        }
        .navigationTitle("探索")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    // 通知按钮操作
                }) {
                    Image(systemName: "bell")
                }
            }
        }
    }
    
    // 搜索栏
    private var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.gray)
            
            TextField("搜索地点、用户或活动", text: $searchText)
                .foregroundColor(.primary)
            
            if !searchText.isEmpty {
                Button(action: {
                    searchText = ""
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.gray)
                }
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(Color(.systemGray6))
        .cornerRadius(10)
        .padding(.horizontal)
    }
    
    // 顶部卡片
    private var featuredContentCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("附近热门")
                .font(.headline)
                .fontWeight(.bold)
                .padding(.horizontal)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(0..<5) { index in
                        featuredItem(index: index)
                    }
                }
                .padding(.horizontal)
            }
        }
        .padding(.vertical)
    }
    
    // 分类列表
    private var categoriesList: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("分类浏览")
                .font(.headline)
                .fontWeight(.bold)
                .padding(.horizontal)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(categories, id: \.name) { category in
                        categoryItem(category: category)
                    }
                }
                .padding(.horizontal)
            }
        }
        .padding(.vertical)
    }
    
    // 推荐列表
    private var recommendationsList: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("为你推荐")
                .font(.headline)
                .fontWeight(.bold)
                .padding(.horizontal)
            
            ForEach(recommendations, id: \.id) { item in
                recommendationItem(item: item)
            }
        }
        .padding(.vertical)
    }
    
    // 特色项目
    private func featuredItem(index: Int) -> some View {
        VStack(alignment: .leading) {
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
            
            Text("热门地点 \(index + 1)")
                .font(.subheadline)
                .fontWeight(.semibold)
            
            Text("距离: \(Int.random(in: 1...10))km")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(width: 200)
    }
    
    // 分类项目
    private func categoryItem(category: Category) -> some View {
        VStack {
            Circle()
                .fill(category.color)
                .frame(width: 60, height: 60)
                .overlay(
                    Image(systemName: category.icon)
                        .imageScale(.large)
                        .foregroundColor(.white)
                )
            
            Text(category.name)
                .font(.caption)
                .lineLimit(1)
        }
        .frame(width: 80)
    }
    
    // 推荐项目
    private func recommendationItem(item: Recommendation) -> some View {
        HStack(spacing: 16) {
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.gray.opacity(0.2))
                .frame(width: 80, height: 80)
                .overlay(
                    Image(systemName: "mappin.and.ellipse")
                        .imageScale(.large)
                        .foregroundColor(.blue)
                )
            
            VStack(alignment: .leading, spacing: 4) {
                Text(item.title)
                    .font(.headline)
                
                Text(item.description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                
                HStack {
                    Image(systemName: "location")
                        .imageScale(.small)
                    Text("\(item.distance)km")
                    
                    Spacer()
                    
                    Image(systemName: "star.fill")
                        .imageScale(.small)
                        .foregroundColor(.yellow)
                    Text(String(format: "%.1f", item.rating))
                }
                .font(.caption)
                .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
    }
    
    // 测试数据
    private let categories = [
        Category(name: "餐饮", icon: "fork.knife", color: .orange),
        Category(name: "购物", icon: "cart", color: .blue),
        Category(name: "景点", icon: "mountain.2", color: .green),
        Category(name: "活动", icon: "figure.walk", color: .purple),
        Category(name: "酒店", icon: "bed.double", color: .red),
        Category(name: "交通", icon: "car", color: .teal)
    ]
    
    private let recommendations = [
        Recommendation(id: 1, title: "中央公园", description: "市中心的休闲绿地，提供各种户外活动和自然风光。", distance: 2.5, rating: 4.7),
        Recommendation(id: 2, title: "海滨广场", description: "临海广场，有各种餐厅和商店，周末有露天市场。", distance: 4.1, rating: 4.3),
        Recommendation(id: 3, title: "历史博物馆", description: "展示本地丰富历史和文化的综合博物馆，适合全家参观。", distance: 3.7, rating: 4.5),
        Recommendation(id: 4, title: "山顶观景台", description: "城市最高点，提供360度全景视野，日落时分尤为壮观。", distance: 7.2, rating: 4.8)
    ]
}

// 辅助数据结构
struct Category {
    let name: String
    let icon: String
    let color: Color
}

struct Recommendation: Identifiable {
    let id: Int
    let title: String
    let description: String
    let distance: Double
    let rating: Double
}

#if DEBUG
struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            HomeView()
                .environmentObject(AppNavigationManager.preview)
                .environmentObject(AuthManager(
                    authService: AppEnvironment.shared.authService,
                    sessionManager: AppEnvironment.shared.sessionManager,
                    keychainManager: AppEnvironment.shared.keychainManager
                ))
        }
    }
}
#endif
