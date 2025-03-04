//
//  LoadingView.swift
//  DistanceApp
//
//  Created by toyousoft on 2025/03/04.
//


import SwiftUI

struct LoadingView: View {
    let message: String
    
    var body: some View {
        VStack(spacing: 20) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle())
                .scaleEffect(1.5)
            
            Text(message)
                .font(.headline)
                .foregroundColor(.secondary)
        }
        .padding(30)
        .background(Color.secondary.opacity(0.1))
        .cornerRadius(10)
    }
}

#if DEBUG
struct LoadingView_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Color.white.edgesIgnoringSafeArea(.all)
            LoadingView(message: "正在加载...")
        }
    }
}
#endif
