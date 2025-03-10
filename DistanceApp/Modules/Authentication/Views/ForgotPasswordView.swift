//
//  ForgotPasswordView.swift
//  DistanceApp
//
//  Created by toyousoft on 2025/03/10.
//
import SwiftUI

struct ForgotPasswordView: View {
    @State private var email = ""
    @State private var message: String?
    @State private var showAlert = false
    
    var body: some View {
        VStack(spacing: 20) {
            Text("重置密码")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text("请输入您的账号邮箱，我们会向您发送重置密码的链接")
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
            
            TextField("邮箱", text: $email)
                .keyboardType(.emailAddress)
                .autocapitalization(.none)
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(8)
            
            Button(action: resetPassword) {
                Text("发送重置链接")
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(8)
            }
            .disabled(email.isEmpty)
            
            Spacer()
        }
        .padding()
        .alert(isPresented: $showAlert) {
            Alert(
                title: Text(message?.contains("成功") ?? false ? "成功" : "错误"),
                message: Text(message ?? "未知错误"),
                dismissButton: .default(Text("确定"))
            )
        }
        .navigationTitle("找回密码")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    // 重置密码方法
    private func resetPassword() {
        // 这里应该调用Firebase Auth的重置密码方法
        // 示例代码：暂未实现实际功能
        showAlert = true
        message = "重置密码链接已发送到您的邮箱，请查收"
    }
}
