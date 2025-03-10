//
//  AuthenticationFlowView.swift
//  DistanceApp
//
//  Created by toyousoft on 2025/03/04.
//

//
//  AuthenticationFlowView.swift
//  DistanceApp
//

import SwiftUI

struct AuthenticationFlowView: View {
    // 环境对象
    @EnvironmentObject private var navigationManager: AppNavigationManager
    @EnvironmentObject private var authManager: AuthManager  // 添加这一行
    
    var body: some View {
        NavigationStack(path: $navigationManager.navigationPath) {
            // 登录视图作为认证流程的起点
            LoginView()
                .environmentObject(authManager)  // 添加这一行，确保传递authManager
                .navigationDestination(for: AppRoute.self) { route in
                    // 处理认证流程导航
                    switch route {
                    case .register:
                        RegisterView()
                    case .forgotPassword:
                        ForgotPasswordView()
                    case .verifyEmail:
                        VerifyEmailView()
                    case .completeProfile:
                        CompleteProfileView()
                    default:
                        Text("未实现的页面：\(route.title)")
                    }
                }
        }
    }
}

// 注册视图
struct RegisterView: View {
    @EnvironmentObject private var authManager: AuthManager
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var name = ""
    @State private var showSuccess = false
    
    var body: some View {
        VStack(spacing: 20) {
            Text("创建新账户")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            VStack(spacing: 15) {
                TextField("姓名", text: $name)
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)
                
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
    
    // 表单验证
    private var isFormValid: Bool {
        !name.isEmpty && !email.isEmpty && !password.isEmpty && password == confirmPassword && password.count >= 6
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
                    name: name
                ))
                showSuccess = true
                // 重置表单
                email = ""
                password = ""
                confirmPassword = ""
                name = ""
            } catch {
                // 错误已在AuthManager中处理
            }
        }
    }
}

// 忘记密码视图
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

// 验证邮箱视图
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

#if DEBUG
struct AuthenticationFlowView_Previews: PreviewProvider {
    static var previews: some View {
        AuthenticationFlowView()
            .environmentObject(AppNavigationManager.preview)
    }
}
#endif
