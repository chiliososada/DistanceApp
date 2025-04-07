//
//  FirebaseImageView.swift
//  DistanceApp
//
//  Created by toyousoft on 2025/04/07.
//

import SwiftUI
import FirebaseStorage

struct FirebaseImageView: View {
    let imagePath: String
    @State private var imageURL: URL? = nil
    @State private var isLoading = true
    @State private var loadError = false
    
    var body: some View {
        Group {
            if let url = imageURL {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .empty:
                        ProgressView()
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    case .failure:
                        Image(systemName: "exclamationmark.triangle")
                            .foregroundColor(.gray)
                    @unknown default:
                        EmptyView()
                    }
                }
            } else if isLoading {
                ProgressView()
            } else if loadError {
                Image(systemName: "exclamationmark.triangle")
                    .foregroundColor(.gray)
            } else {
                Color.gray.opacity(0.3)
            }
        }
        .onAppear {
            loadImage()
        }
    }
    
    private func loadImage() {
        guard imageURL == nil, !loadError else { return }
        
        isLoading = true
        
        Task {
            do {
                let url = try await FirebaseStorageService.shared.getImageURL(for: imagePath)
                
                await MainActor.run {
                    self.imageURL = url
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.loadError = true
                    self.isLoading = false
                }
            }
        }
    }
}
