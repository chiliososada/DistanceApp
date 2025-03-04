//
//  APIResponseModels.swift
//  DistanceApp
//
//  Created by toyousoft on 2025/03/04.
//

import Foundation

/// API响应包装类
struct APIResponse<T: Codable>: Codable {
    let code: Int
    let message: String
    let data: T
}
