import SwiftUI
import PhotosUI
import CoreLocation
import FirebaseStorage // 添加这一行


// 修改：让 CreateTopicViewModel 继承自 NSObject 以支持 CLLocationManagerDelegate
class CreateTopicViewModel: NSObject, ObservableObject {
    // 表单字段
    @Published var title: String = ""
    @Published var content: String = ""
    @Published var selectedItems: [PhotosPickerItem] = []
    @Published var selectedImages: [UIImage?] = []
    @Published var tags: [String] = []
    @Published var expirationDate: Date = Date().addingTimeInterval(7 * 24 * 60 * 60) // 默认7天后过期
    @Published var useCurrentLocation: Bool = true
    
    // UI状态
    @Published var currentTagInput: String = ""
    @Published var isTagInputActive: Bool = false
    @Published var showDatePicker: Bool = false
    @Published var isLoading: Bool = false
    @Published var showAlert: Bool = false
    @Published var alertMessage: String = ""
    
    // 位置信息
    private var locationManager: CLLocationManager?
    private var currentLatitude: Double?
    private var currentLongitude: Double?
    
    // 格式化的过期时间
    var formattedExpirationDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: expirationDate)
    }
    
    // 位置描述
    var locationDescription: String {
        if let lat = currentLatitude, let lon = currentLongitude {
            return "当前位置: \(String(format: "%.6f", lat)), \(String(format: "%.6f", lon))"
        } else {
            return "获取位置中..."
        }
    }
    
    // 服务依赖 - 使用PostService
    private let postService = AppEnvironment.shared.postService
    
    // 初始化 - 需要调用 super.init() 因为现在继承自 NSObject
    override init() {
        super.init()
        setupLocationManager()
        setupImageSelection()
    }
    
    // 设置位置管理器
    private func setupLocationManager() {
        locationManager = CLLocationManager()
        locationManager?.delegate = self
        locationManager?.requestWhenInUseAuthorization()
        locationManager?.startUpdatingLocation()
        
        // 设置默认值（东京新宿附近）
        currentLatitude = 35.689487
        currentLongitude = 139.691711
    }
    
    // 监听图片选择
    private func setupImageSelection() {
        Task {
            for await value in $selectedItems.values {
                await loadImages(from: value)
            }
        }
    }
    
    // 加载选择的图片
    @MainActor
    private func loadImages(from items: [PhotosPickerItem]) async {
        selectedImages = []
        
        for item in items {
            if let data = try? await item.loadTransferable(type: Data.self),
               let uiImage = UIImage(data: data) {
                selectedImages.append(uiImage)
            } else {
                selectedImages.append(nil)
            }
        }
    }
    
    // 删除选中的图片
    func removeImage(at index: Int) {
        guard index < selectedItems.count && index < selectedImages.count else { return }
        
        selectedItems.remove(at: index)
        selectedImages.remove(at: index)
    }
    
    // 添加标签
    func addTag() {
        let tag = currentTagInput.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if !tag.isEmpty && !tags.contains(tag) && tag.count <= 50 && tags.count < 10 {
            tags.append(tag)
            currentTagInput = ""
        } else if tag.count > 50 {
            alertMessage = "标签最多50个字符"
            showAlert = true
        } else if tags.count >= 10 {
            alertMessage = "最多添加10个标签"
            showAlert = true
        }
        
        isTagInputActive = false
    }
    
    // 删除标签
    func removeTag(_ tag: String) {
        tags.removeAll { $0 == tag }
    }
    
    // 发布话题
    @MainActor
    func publishTopic() async throws {
        // 表单验证
        guard !title.isEmpty && title.count <= 255 else {
            alertMessage = "标题不能为空且最多255个字符"
            showAlert = true
            throw PostError.invalidInput("标题不能为空")
        }
        
        guard content.count <= 4096 else {
            alertMessage = "内容最多4096个字符"
            showAlert = true
            throw PostError.invalidInput("内容过长")
        }
        
        guard !tags.isEmpty else {
            alertMessage = "请至少添加一个标签"
            showAlert = true
            throw PostError.invalidInput("缺少标签")
        }
        
        // 开始加载
        isLoading = true
        
        do {
            // 生成唯一ID
            let uid = UUID().uuidString.lowercased()
            
            // 准备图片数据
            var imageIds: [String] = []
            
            // 这里应该先上传图片，获取图片ID
            if !selectedImages.isEmpty {
                // 实际项目中，这里应该调用上传图片的API
                imageIds = try await uploadImages(topicUid: uid)
            }
            
            // 准备位置数据
            var latitude: Double? = nil
            var longitude: Double? = nil
            
            if useCurrentLocation {
                latitude = currentLatitude
                longitude = currentLongitude
            }
            
            // 创建话题请求，传入新增的uid参数
            let request = CreateTopicRequest(
                uid: uid,
                title: title,
                content: content,
                images: imageIds,
                tags: tags,
                latitude: latitude,
                longitude: longitude,
                expiresAt: expirationDate
            )
            
            // 发送请求 - 使用PostService
            try await postService.createTopic(request)
            
            // 发布成功
            isLoading = false
            
            // 重置表单
            resetForm()
            
        } catch {
            isLoading = false
            alertMessage = "发布失败: \(error.localizedDescription)"
            showAlert = true
            throw error
        }
    }
    
    // 上传图片 压缩处理under 500kb
    private func uploadImages(topicUid: String) async throws -> [String] {
        let storage = Storage.storage()
        var imagePaths: [String] = []
        
        for index in 0..<selectedImages.count {
            guard let image = selectedImages[index] else { continue }
            
            // 压缩图片到500KB以下
            guard let compressedImageData = compressImage(image, maxSizeKB: 500) else {
                Logger.error("图片压缩失败")
                throw PostError.imageUploadFailed
            }
            
            let metadata = StorageMetadata()
            metadata.contentType = "image/jpeg"
            
            // 创建图片路径
            let imagePath = "topics/\(topicUid)/image-\(index)"
            let storageRef = storage.reference().child(imagePath)
            
            // 上传图片
            do {
                _ = try await storageRef.putDataAsync(compressedImageData, metadata: metadata)
                
                // 使用路径
                imagePaths.append(imagePath)
                
                Logger.debug("成功上传图片: \(imagePath), 大小: \(compressedImageData.count / 1024)KB")
            } catch {
                Logger.error("图片上传失败: \(error.localizedDescription)")
                throw PostError.imageUploadFailed
            }
        }
        
        return imagePaths
    }

    // 图片压缩方法
    private func compressImage(_ originalImage: UIImage, maxSizeKB: Int) -> Data? {
        // 尝试不同的压缩质量
        var compression: CGFloat = 0.9
        let maxBytes = maxSizeKB * 1024
        
        // 第一次尝试的压缩
        guard var imageData = originalImage.jpegData(compressionQuality: compression) else {
            return nil
        }
        
        // 如果已经小于最大大小，直接返回
        if imageData.count <= maxBytes {
            return imageData
        }
        
        // 尝试逐步降低质量
        while imageData.count > maxBytes && compression > 0.1 {
            compression -= 0.1
            if let compressedData = originalImage.jpegData(compressionQuality: compression) {
                imageData = compressedData
                Logger.debug("压缩质量: \(compression), 大小: \(imageData.count / 1024)KB")
                
                if imageData.count <= maxBytes {
                    return imageData
                }
            }
        }
        
        // 如果质量压缩不够，则尝试调整尺寸
        if imageData.count > maxBytes {
            var scaleFactor: CGFloat = 0.9
            var scaledImage = originalImage
            
            while imageData.count > maxBytes && scaleFactor > 0.1 {
                let newWidth = originalImage.size.width * scaleFactor
                let newHeight = originalImage.size.height * scaleFactor
                let newSize = CGSize(width: newWidth, height: newHeight)
                
                UIGraphicsBeginImageContextWithOptions(newSize, false, originalImage.scale)
                originalImage.draw(in: CGRect(origin: .zero, size: newSize))
                if let resizedImage = UIGraphicsGetImageFromCurrentImageContext() {
                    UIGraphicsEndImageContext()
                    
                    scaledImage = resizedImage
                    if let resizedData = resizedImage.jpegData(compressionQuality: compression) {
                        imageData = resizedData
                        Logger.debug("压缩尺寸: \(scaleFactor), 大小: \(imageData.count / 1024)KB")
                        
                        if imageData.count <= maxBytes {
                            return imageData
                        }
                    }
                } else {
                    UIGraphicsEndImageContext()
                }
                
                scaleFactor -= 0.1
            }
        }
        
        // 如果所有压缩尝试都失败，返回最后的压缩结果
        Logger.warning("未能将图片压缩到\(maxSizeKB)KB以下，最终大小: \(imageData.count / 1024)KB")
        return imageData
    }
    
    // 重置表单
    private func resetForm() {
        title = ""
        content = ""
        selectedItems = []
        selectedImages = []
        tags = []
        expirationDate = Date().addingTimeInterval(7 * 24 * 60 * 60)
        currentTagInput = ""
        isTagInputActive = false
    }
}

// MARK: - CLLocationManagerDelegate
extension CreateTopicViewModel: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        
        currentLatitude = location.coordinate.latitude
        currentLongitude = location.coordinate.longitude
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("定位失败: \(error.localizedDescription)")
    }
}
