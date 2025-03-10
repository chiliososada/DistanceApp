//
//  RegisterView.swift
//  DistanceApp
//
//  Created by toyousoft on 2025/03/10.
//

import SwiftUI

struct RegisterView: View {
    @EnvironmentObject private var authManager: AuthManager
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var showSuccess = false
    
    var body: some View {
        VStack(spacing: 20) {
            Text("创建新账户")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            VStack(spacing: 15) {
                // 删除姓名输入框
                
                TextField("邮箱", text: $email)
                    .keyboardType(.emailAddress)
                    .autocapitalization(.none)
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)
                
                SecureField("密码", text: $password)
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)
                
                SecureField("确认密码", text: $confirmPassword)
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)
            }
            
            Button(action: registerUser) {
                Text("注册")
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(8)
            }
            .disabled(!isFormValid || authManager.isLoading)
            
            if authManager.isLoading {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle())
            }
            
            Spacer()
        }
        .padding()
        .alert(isPresented: $showSuccess) {
            Alert(
                title: Text("注册成功"),
                message: Text("请查看您的邮箱并验证账户"),
                dismissButton: .default(Text("确定"))
            )
        }
        .alert(item: alertItem) { item in
            Alert(
                title: Text("错误"),
                message: Text(item.message),
                dismissButton: .default(Text("确定"))
            )
        }
        .navigationTitle("注册")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    // 修改表单验证，移除姓名检查
    private var isFormValid: Bool {
        !email.isEmpty && !password.isEmpty && password == confirmPassword && password.count >= 6
    }
    
    // 警告项
    private var alertItem: Binding<AlertItem?> {
        Binding<AlertItem?>(
            get: {
                guard let error = authManager.error else { return nil }
                return AlertItem(id: UUID().uuidString, message: error.errorDescription ?? "未知错误")
            },
            set: { _ in }
        )
    }
    
    // 注册方法
    private func registerUser() {
        Task {
            do {
                try await authManager.signUp(with: RegistrationData(
                    email: email,
                    password: password,
                    name: "" // 使用空字符串作为name，保持结构体兼容性
                ))
                showSuccess = true
                // 重置表单
                email = ""
                password = ""
                confirmPassword = ""
            } catch {
                // 错误已在AuthManager中处理
            }
        }
    }
}
