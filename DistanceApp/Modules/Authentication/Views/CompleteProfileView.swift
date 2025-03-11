//
//  CompleteProfileView.swift
//  DistanceApp
//
//  Created on 2025/03/10.
//

import SwiftUI

struct CompleteProfileView: View {
    // 环境对象
    @EnvironmentObject private var navigationManager: AppNavigationManager
    @EnvironmentObject private var authManager: AuthManager
    @EnvironmentObject private var environment: AppEnvironment
    
    // 状态变量
    @State private var displayName: String = ""
    @State private var gender: String = "未设置"
    @State private var bio: String = ""
    @State private var selectedImage: UIImage?
    @State private var showImagePicker = false
    @State private var isLoading = false
    @State private var errorMessage = ""
    @State private var showError = false
    
    // 性别选项
    private let genderOptions = ["男", "女", "其他", "未设置"]
    
    var body: some View {
        ScrollView {
            VStack(spacing: 25) {
                // 头像选择
                profileImageSection
                
                // 个人信息表单
                formSection
                
                // 提交按钮
                submitButton
                
                Spacer()
            }
            .padding()
        }
        .navigationTitle("完善个人信息")
        .navigationBarBackButtonHidden(true)
        .sheet(isPresented: $showImagePicker) {
            ImagePicker(selectedImage: $selectedImage)
        }
        .alert("错误", isPresented: $showError) {
            Button("确定", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
        .overlay {
            if isLoading {
                LoadingView(message: "正在保存...")
            }
        }
        .onAppear {
            loadUserProfile()
        }
    }
    
    // 头像选择部分
    private var profileImageSection: some View {
        VStack {
            ZStack {
                if let image = selectedImage {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 120, height: 120)
                        .clipShape(Circle())
                } else if let photoURL = authManager.userProfile?.photoURL {
                    // photoURL已经是URL类型，不需要再次解包
                    AsyncImage(url: photoURL) { image in
                        image
                            .resizable()
                            .scaledToFill()
                    } placeholder: {
                        Color.gray.opacity(0.3)
                    }
                    .frame(width: 120, height: 120)
                    .clipShape(Circle())
                } else {
                    Image(systemName: "person.circle.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 120, height: 120)
                        .foregroundColor(.gray)
                }
                
                Button(action: {
                    showImagePicker = true
                }) {
                    Image(systemName: "camera.fill")
                        .foregroundColor(.white)
                        .padding(8)
                        .background(Color.blue)
                        .clipShape(Circle())
                }
                .offset(x: 40, y: 40)
            }
            .padding(.top, 20)
            
            Text("点击更换头像")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
    
    // 表单部分
    private var formSection: some View {
        VStack(spacing: 20) {
            VStack(alignment: .leading) {
                Text("昵称")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                TextField("请输入您的昵称", text: $displayName)
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)
            }
            
            VStack(alignment: .leading) {
                Text("性别")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Picker("选择性别", selection: $gender) {
                    ForEach(genderOptions, id: \.self) { option in
                        Text(option).tag(option)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
            }
            
            VStack(alignment: .leading) {
                Text("个人简介")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                TextEditor(text: $bio)
                    .frame(height: 120)
                    .padding(4)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                    )
            }
        }
    }
    
    // 提交按钮
    private var submitButton: some View {
        Button(action: saveProfile) {
            Text("保存并继续")
                .fontWeight(.bold)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(displayName.isEmpty ? Color.gray : Color.blue)
                .cornerRadius(8)
        }
        .disabled(displayName.isEmpty || isLoading)
        .padding(.top, 20)
    }
    
    // 加载用户信息
    private func loadUserProfile() {
        guard let profile = authManager.userProfile else { return }
        
        displayName = profile.displayName
        
        if let genderValue = profile.gender {
            if genderOptions.contains(genderValue) {
                gender = genderValue
            }
        }
        
        if let bioValue = profile.bio {
            bio = bioValue
        }
    }
    
    // 保存个人信息
    private func saveProfile() {
        guard !displayName.isEmpty else {
            errorMessage = "请输入昵称"
            showError = true
            return
        }
        
        isLoading = true
        
        Task {
                do {
                    try await authManager.updateProfile(
                        displayName: displayName,
                        gender: gender == "未设置" ? nil : gender,
                        bio: bio.isEmpty ? nil : bio,
                        profileImage: selectedImage
                    )
                    
                    // 更新成功，导航到主页
                    await MainActor.run {
                        isLoading = false
                        // 不再使用 navigationManager.popToRoot()
                        
                        // 更新环境状态
                        environment.isAuthenticated = true
                        environment.isProfileIncomplete = false // 明确标记资料已完善
                    }
                }  catch {
                await MainActor.run {
                    isLoading = false
                    errorMessage = error.localizedDescription
                    showError = true
                }
            }
        }
    }
}

// 图片选择器
struct ImagePicker: UIViewControllerRepresentable {
    @Binding var selectedImage: UIImage?
    @Environment(\.presentationMode) var presentationMode
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.allowsEditing = true
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: ImagePicker
        
        init(_ parent: ImagePicker) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let editedImage = info[.editedImage] as? UIImage {
                parent.selectedImage = editedImage
            } else if let originalImage = info[.originalImage] as? UIImage {
                parent.selectedImage = originalImage
            }
            
            parent.presentationMode.wrappedValue.dismiss()
        }
    }
}

#if DEBUG
struct CompleteProfileView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            CompleteProfileView()
                .environmentObject(AppNavigationManager.preview)
                .environmentObject(AuthManager(
                    authService: MockAuthService(),
                    sessionManager: MockSessionManager(),
                    keychainManager: MockKeychainManager()
                ))
                .environmentObject(AppEnvironment.preview)
        }
    }
    
    // 假的服务用于预览
    private class MockAuthService: AuthServiceProtocol {
        func loginWithFirebaseToken(_ idToken: String) async throws -> UserProfile {
            fatalError("未实现")
        }
        
        func checkSession() async throws -> Bool {
            return false
        }
        
        func updatePassword(currentPassword: String, newPassword: String) async throws {
            fatalError("未实现")
        }
        
        func deleteAccount(password: String) async throws {
            fatalError("未实现")
        }
    }
    
    private class MockSessionManager: SessionManagerProtocol {
        func updateSessionWithToken(idToken: String, profile: UserProfile) async {}
        func updateSession(user: UserProfile?) async {}
        func getSavedProfile() -> UserProfile? { return nil }
        func clearSession() async {}
        func getAuthToken() -> String? { return nil }
        func savePushToken(_ token: String) {}
        func getPushToken() -> String? { return nil }
        func isSessionValid() -> Bool { return false }
        func shouldRefreshProfile() -> Bool { return false }
    }
    
    private class MockKeychainManager: KeychainManagerProtocol {
        func saveSecureString(_ value: String, forKey key: String) throws {}
        func getSecureString(forKey key: String) throws -> String? { return nil }
        func saveSecureData(_ data: Data, forKey key: String) throws {}
        func getSecureData(forKey key: String) throws -> Data? { return nil }
        func deleteSecureData(forKey key: String) throws {}
        func clearAll() throws {}
        func hasKey(_ key: String) -> Bool { return false }
        func saveSecureObject<T: Encodable>(_ object: T, forKey key: String) throws {}
        func getSecureObject<T: Decodable>(_ type: T.Type, forKey key: String) throws -> T? { return nil }
    }
}
#endif
