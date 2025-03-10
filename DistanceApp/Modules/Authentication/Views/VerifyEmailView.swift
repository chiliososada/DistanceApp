//
//  Untitled.swift
//  DistanceApp
//
//  Created by toyousoft on 2025/03/10.
//
import SwiftUI

struct VerifyEmailView: View {
    @EnvironmentObject private var navigationManager: AppNavigationManager
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "envelope.circle.fill")
                .resizable()
                .scaledToFit()
                .frame(width: 100, height: 100)
                .foregroundColor(.blue)
            
            Text("请验证您的邮箱")
                .font(.title)
                .fontWeight(.bold)
            
            Text("我们已向您的邮箱发送了一封验证邮件，请查收并点击邮件中的链接完成验证")
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
            
            Button(action: {
                // 返回登录页面
                navigationManager.popToRoot()
            }) {
                Text("返回登录")
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(8)
            }
            .padding(.top, 20)
            
            Spacer()
        }
        .padding()
        .navigationTitle("验证邮箱")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
    }
}

// 警告项模型
struct AlertItem: Identifiable {
    let id: String
    let message: String
}
