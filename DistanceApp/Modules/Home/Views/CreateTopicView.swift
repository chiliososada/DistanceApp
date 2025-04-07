import SwiftUI
import PhotosUI

struct CreateTopicView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = CreateTopicViewModel()
    @FocusState private var focusedField: Field?
    
    // 用于管理焦点
    enum Field: Hashable {
        case title, content
    }
    
    // 主题颜色
    private let accentColor = Color.blue
    private let errorColor = Color.red
    private let backgroundColor = Color(UIColor.systemGroupedBackground)
    private let cardColor = Color.white
    private let subtleTextColor = Color.gray.opacity(0.8)
    
    var body: some View {
        NavigationStack {
            ZStack {
                // 背景色 - 添加点击手势收起键盘
                backgroundColor
                    .edgesIgnoringSafeArea(.all)
                    .onTapGesture {
                        hideKeyboard()
                    }
                
                // 滚动内容
                ScrollView {
                    VStack(spacing: 16) {
                        // 标题卡片 - 带键盘收起功能
                        inputCard(content: titleSection, iconName: "text.quote", title: "标题")
                        
                        // 内容卡片 - 带键盘收起功能
                        inputCard(content: contentSection, iconName: "doc.text", title: "内容")
                        
                        // 图片卡片 - 普通卡片布局
                        standardCard(content: imageSelectionSection, iconName: "photo.on.rectangle", title: "图片")
                        
                        // 标签卡片 - 普通卡片布局
                        standardCard(content: tagSelectionSection, iconName: "tag", title: "标签")
                        
                        // 过期时间卡片 - 普通卡片布局
                        standardCard(content: expirationSection, iconName: "calendar", title: "过期时间")
                        
                        // 位置卡片 - 普通卡片布局
                        standardCard(content: locationSection, iconName: "location", title: "位置")
                        
                        // 发布按钮
                        publishButton
                            .padding(.top, 10)
                            .padding(.bottom, 30)
                    }
                    .padding(.horizontal)
                    .padding(.top, 10)
                }
            }
            .navigationTitle("发布新话题")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        hideKeyboard()
                        dismiss()
                    }) {
                        Text("取消")
                            .foregroundColor(accentColor)
                    }
                }
                
                // 添加键盘收起按钮
                ToolbarItem(placement: .keyboard) {
                    Button(action: hideKeyboard) {
                        Image(systemName: "keyboard.chevron.compact.down")
                            .foregroundColor(accentColor)
                    }
                }
            }
            .alert("提示", isPresented: $viewModel.showAlert) {
                Button("确定", role: .cancel) { }
            } message: {
                Text(viewModel.alertMessage)
            }
            .overlay {
                if viewModel.isLoading {
                    LoadingView(message: "正在发布...")
                }
            }
        }
    }
    
    // 隐藏键盘方法
    private func hideKeyboard() {
        focusedField = nil
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
    
    // 输入区域专用的卡片布局 - 带键盘收起功能
    private func inputCard<Content: View>(content: Content, iconName: String, title: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            // 标题行
            HStack(spacing: 8) {
                Image(systemName: iconName)
                    .foregroundColor(accentColor)
                    .font(.system(size: 18))
                
                Text(title)
                    .font(.headline)
                    .foregroundColor(.primary)
            }
            .padding(.bottom, 4)
            .onTapGesture {
                hideKeyboard()
            }
            
            // 内容
            content
        }
        .padding(16)
        .background(cardColor)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
        // 点击卡片非输入区时收起键盘
        .onTapGesture {
            hideKeyboard()
        }
    }
    
    // 标准卡片布局 - 不带键盘收起功能
    private func standardCard<Content: View>(content: Content, iconName: String, title: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            // 标题行
            HStack(spacing: 8) {
                Image(systemName: iconName)
                    .foregroundColor(accentColor)
                    .font(.system(size: 18))
                
                Text(title)
                    .font(.headline)
                    .foregroundColor(.primary)
            }
            .padding(.bottom, 4)
            
            // 内容
            content
        }
        .padding(16)
        .background(cardColor)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
    
    // 标题部分
    private var titleSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            ZStack(alignment: .topLeading) {
                TextField("请输入标题（必填）", text: $viewModel.title)
                    .font(.body)
                    .padding()
                    .background(Color(UIColor.secondarySystemBackground))
                    .cornerRadius(8)
                    .focused($focusedField, equals: .title)
                    .submitLabel(.next)
                    .onSubmit {
                        focusedField = .content
                    }
                
                // 在输入标题时显示的提示文本 - 移除动画
                if viewModel.title.isEmpty && focusedField == .title {
                    HStack(spacing: 4) {
                        Image(systemName: "pencil")
                            .font(.caption)
                        Text("一个吸引人的标题能获得更多关注")
                            .font(.caption)
                    }
                    .foregroundColor(subtleTextColor)
                    .padding(.horizontal, 12)
                    .padding(.top, 8)
                    .allowsHitTesting(false)
                }
            }
            
            // 字数统计
            HStack {
                Spacer()
                Text("\(viewModel.title.count)/255")
                    .font(.caption)
                    .foregroundColor(viewModel.title.count > 255 ? errorColor : subtleTextColor)
                    .padding(.trailing, 4)
            }
        }
        // 处理标题输入区的点击事件，避免与卡片点击冲突
        .contentShape(Rectangle())
        .onTapGesture {
            focusedField = .title
        }
    }
    
    // 内容部分
    private var contentSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            TextEditor(text: $viewModel.content)
                .placeholder(when: viewModel.content.isEmpty) {
                    Text("分享你的想法...")
                        .foregroundColor(subtleTextColor)
                        .padding(.top, 8)
                        .padding(.leading, 4)
                }
                .font(.body)
                .padding(4)
                .frame(minHeight: 150)
                .background(Color(UIColor.secondarySystemBackground))
                .cornerRadius(8)
                .focused($focusedField, equals: .content)
            
            // 字数统计
            HStack {
                Spacer()
                Text("\(viewModel.content.count)/4096")
                    .font(.caption)
                    .foregroundColor(viewModel.content.count > 4096 ? errorColor : subtleTextColor)
                    .padding(.trailing, 4)
            }
        }
        // 处理内容输入区的点击事件，避免与卡片点击冲突
        .contentShape(Rectangle())
        .onTapGesture {
            focusedField = .content
        }
    }
    
    // 图片选择部分 - 恢复直接使用PhotosPicker
    private var imageSelectionSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Spacer()
                Text("\(viewModel.selectedImages.count)/9")
                    .font(.caption)
                    .foregroundColor(subtleTextColor)
            }
            
            // 直接使用PhotosPicker
            PhotosPicker(selection: $viewModel.selectedItems, maxSelectionCount: 9, matching: .images) {
                // 在点击前隐藏键盘
                if viewModel.selectedImages.isEmpty {
                    // 空状态显示
                    emptyImagePlaceholder
                } else {
                    // 已选择图片显示
                    selectedImagesGrid
                }
            }
            .onChange(of: viewModel.selectedItems) { _ in
                // 选择图片后确保键盘隐藏
                hideKeyboard()
            }
        }
    }
    
    // 空图片占位符
    private var emptyImagePlaceholder: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(UIColor.secondarySystemBackground))
                .frame(height: 120)
            
            VStack(spacing: 12) {
                Image(systemName: "photo.on.rectangle.angled")
                    .font(.system(size: 32))
                    .foregroundColor(subtleTextColor)
                
                Text("点击添加图片")
                    .font(.callout)
                    .foregroundColor(subtleTextColor)
            }
        }
    }
    
    // 已选择图片网格
    private var selectedImagesGrid: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 100), spacing: 12)], spacing: 12) {
            ForEach(viewModel.selectedImages.indices, id: \.self) { index in
                ZStack(alignment: .topTrailing) {
                    if let image = viewModel.selectedImages[index] {
                        Image(uiImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 100, height: 100)
                            .cornerRadius(10)
                            .clipped()
                    }
                    
                    Button(action: {
                        viewModel.removeImage(at: index)
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 20))
                            .foregroundColor(.white)
                            .shadow(color: .black.opacity(0.6), radius: 2, x: 0, y: 0)
                            .padding(4)
                    }
                }
            }
            
            // 添加更多图片按钮（在网格内）
            if viewModel.selectedImages.count < 9 {
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color(UIColor.secondarySystemBackground))
                        .frame(width: 100, height: 100)
                    
                    Image(systemName: "plus")
                        .font(.system(size: 32))
                        .foregroundColor(subtleTextColor)
                }
            }
        }
    }
    
    // 标签选择部分
    private var tagSelectionSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                if viewModel.tags.isEmpty {
                    Text("添加标签以便其他用户更容易找到你的话题")
                        .font(.caption)
                        .foregroundColor(subtleTextColor)
                        .padding(.vertical, 4)
                } else {
                    tagsFlowLayout
                }
                
                Spacer()
                
                Button(action: {
                    hideKeyboard()
                    viewModel.isTagInputActive = true
                }) {
                    Image(systemName: "plus.circle.fill")
                        .foregroundColor(accentColor)
                        .font(.system(size: 22))
                }
            }
            
            // 标签添加区域 - 移除动画
            if viewModel.isTagInputActive {
                HStack {
                    TextField("输入标签，回车添加", text: $viewModel.currentTagInput)
                        .padding(10)
                        .background(Color(UIColor.secondarySystemBackground))
                        .cornerRadius(8)
                        .onSubmit {
                            viewModel.addTag()
                            // 添加标签后可以隐藏键盘
                            if viewModel.currentTagInput.isEmpty {
                                hideKeyboard()
                            }
                        }
                    
                    Button("添加") {
                        viewModel.addTag()
                        // 添加标签后隐藏键盘
                        hideKeyboard()
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(accentColor)
                    .cornerRadius(8)
                }
            }
        }
    }
    
    // 标签流式布局
    private var tagsFlowLayout: some View {
        FlowLayout(spacing: 8) {
            ForEach(viewModel.tags, id: \.self) { tag in
                HStack(spacing: 4) {
                    Text(tag)
                        .font(.subheadline)
                        .lineLimit(1)
                    
                    Button(action: {
                        viewModel.removeTag(tag)
                        hideKeyboard()
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 12))
                            .foregroundColor(.white.opacity(0.8))
                    }
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(accentColor)
                .foregroundColor(.white)
                .cornerRadius(15)
            }
        }
    }
    
    // 过期时间部分
    private var expirationSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Button(action: {
                hideKeyboard()
                viewModel.showDatePicker.toggle()
            }) {
                HStack {
                    Text(viewModel.formattedExpirationDate)
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    Image(systemName: "calendar")
                        .foregroundColor(accentColor)
                }
                .padding()
                .background(Color(UIColor.secondarySystemBackground))
                .cornerRadius(8)
            }
            
            Text("设置话题的有效期限，到期后不再显示")
                .font(.caption)
                .foregroundColor(subtleTextColor)
                .padding(.horizontal, 4)
        }
        .sheet(isPresented: $viewModel.showDatePicker) {
            DatePickerView(selectedDate: $viewModel.expirationDate, isPresented: $viewModel.showDatePicker)
        }
    }
    
    // 位置信息部分
    private var locationSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Toggle("使用当前位置", isOn: $viewModel.useCurrentLocation)
                    .toggleStyle(SwitchToggleStyle(tint: accentColor))
                    .onChange(of: viewModel.useCurrentLocation) { _ in
                        // 切换位置开关时收起键盘
                        hideKeyboard()
                    }
            }
            .padding(.vertical, 4)
            
            if viewModel.useCurrentLocation {
                HStack {
                    Image(systemName: "location.fill")
                        .foregroundColor(accentColor)
                    Text(viewModel.locationDescription)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 6)
                .padding(.horizontal, 4)
            }
            
            Text("位置信息帮助附近的用户发现你的话题")
                .font(.caption)
                .foregroundColor(subtleTextColor)
                .padding(.horizontal, 4)
        }
    }
    
    // 发布按钮 - 移除动画
    private var publishButton: some View {
        Button(action: publishTopic) {
            HStack {
                Image(systemName: "paperplane.fill")
                Text("发布话题")
                    .fontWeight(.semibold)
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                isFormValid ?
                LinearGradient(
                    gradient: Gradient(colors: [accentColor, accentColor.opacity(0.8)]),
                    startPoint: .leading,
                    endPoint: .trailing
                ) :
                LinearGradient(
                    gradient: Gradient(colors: [Color.gray, Color.gray.opacity(0.8)]),
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(12)
            .shadow(color: isFormValid ? accentColor.opacity(0.3) : Color.clear, radius: 8, x: 0, y: 4)
        }
        .disabled(!isFormValid)
    }
    
    // 发布话题
    private func publishTopic() {
        // 发布前收起键盘
        hideKeyboard()
        
        Task {
            do {
                try await viewModel.publishTopic()
                dismiss()
            } catch {
                // 错误处理已在ViewModel中完成
            }
        }
    }
    
    // 表单验证
    private var isFormValid: Bool {
        !viewModel.title.isEmpty && viewModel.title.count <= 255 &&
        viewModel.content.count <= 4096 &&
        !viewModel.tags.isEmpty
    }
}

// 日期选择器视图
struct DatePickerView: View {
    @Binding var selectedDate: Date
    @Binding var isPresented: Bool
    
    var body: some View {
        NavigationStack {
            VStack {
                DatePicker(
                    "选择过期时间",
                    selection: $selectedDate,
                    in: Date()...,
                    displayedComponents: [.date, .hourAndMinute]
                )
                .datePickerStyle(.wheel)
                .labelsHidden()
                .padding()
                
                // 说明文本
                Text("设置合适的过期时间，过期后话题将不再显示")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                    .padding(.bottom)
            }
            .navigationTitle("选择过期时间")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        isPresented = false
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("确定") {
                        isPresented = false
                    }
                    .fontWeight(.semibold)
                    .foregroundColor(.blue)
                }
            }
        }
        .presentationDetents([.medium])
    }
}

// FlowLayout：实现标签的流式布局
struct FlowLayout: Layout {
    var spacing: CGFloat = 10
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let width = proposal.width ?? 0
        var height: CGFloat = 0
        var x: CGFloat = 0
        var y: CGFloat = 0
        var maxHeight: CGFloat = 0
        
        for view in subviews {
            let viewSize = view.sizeThatFits(.unspecified)
            
            if x + viewSize.width > width {
                y += maxHeight + spacing
                x = 0
                maxHeight = 0
            }
            
            maxHeight = max(maxHeight, viewSize.height)
            x += viewSize.width + spacing
        }
        
        height = y + maxHeight
        
        return CGSize(width: width, height: height)
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let width = bounds.width
        var x = bounds.minX
        var y = bounds.minY
        var maxHeight: CGFloat = 0
        
        for view in subviews {
            let viewSize = view.sizeThatFits(.unspecified)
            
            if x + viewSize.width > bounds.maxX {
                y += maxHeight + spacing
                x = bounds.minX
                maxHeight = 0
            }
            
            view.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(viewSize))
            
            maxHeight = max(maxHeight, viewSize.height)
            x += viewSize.width + spacing
        }
    }
}

// TextEditor Placeholder
extension View {
    func placeholder<Content: View>(
        when shouldShow: Bool,
        alignment: Alignment = .leading,
        @ViewBuilder placeholder: () -> Content) -> some View {
        
        ZStack(alignment: alignment) {
            placeholder().opacity(shouldShow ? 1 : 0)
            self
        }
    }
}
