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




#if DEBUG
struct AuthenticationFlowView_Previews: PreviewProvider {
    static var previews: some View {
        AuthenticationFlowView()
            .environmentObject(AppNavigationManager.preview)
    }
}
#endif
