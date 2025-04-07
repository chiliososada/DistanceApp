//
//  TopicDetailFromIdView.swift
//  DistanceApp
//

import SwiftUI

// 简化的中转视图，只从HomeViewModel中获取数据
struct TopicDetailFromIdView: View {
    let topicId: String
    @State private var topic: Topic?
    @State private var isLoading = true
    @State private var errorMessage: String?
    
    // 使用HomeViewModel的共享实例
    @ObservedObject private var viewModel = HomeViewModel.shared
    
    var body: some View {
        Group {
            if isLoading {
                LoadingView(message: "加载中...")
            } else if let topic = topic {
                TopicDetailView(topic: topic)
            } else {
                VStack(spacing: 16) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.largeTitle)
                        .foregroundColor(.orange)
                    
                    Text(errorMessage ?? "找不到该话题")
                        .font(.headline)
                }
                .padding()
            }
        }
        .onAppear {
            findTopicInViewModel()
        }
    }
    
    // 从ViewModel中查找话题
    private func findTopicInViewModel() {
           Logger.debug("正在查找话题ID: \(topicId)")
           
           // 先查找recentTopics
           if let topic = viewModel.recentTopics.first(where: { $0.id == topicId }) {
               Logger.debug("在recentTopics中找到话题")
               self.topic = topic
               self.isLoading = false
               return
           }
           
           // 再查找trendingTopics
           if let topic = viewModel.trendingTopics.first(where: { $0.id == topicId }) {
               Logger.debug("在trendingTopics中找到话题")
               self.topic = topic
               self.isLoading = false
               return
           }
           
           // 如果没找到，显示错误
           Logger.error("未找到话题ID: \(topicId)")
           self.errorMessage = "找不到ID为 \(topicId) 的话题"
           self.isLoading = false
       }
}
