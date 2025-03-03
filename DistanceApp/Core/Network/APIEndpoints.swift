//
//  APIEndpoints.swift
//  DistanceApp
//
//  Created by toyousoft on 2025/03/03.
//

import Foundation
import MapKit

// MARK: - HTTP Method Enum
enum HTTPMethod: String {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case delete = "DELETE"
}

// MARK: - API Endpoint
enum APIEndpoint {
    // Auth Endpoints
    case loginWithFirebaseToken(idToken: String)
    case login(email: String, password: String)
    case register(email: String, name: String, password: String)
    case updatePassword(currentPassword: String, newPassword: String)
    case deleteAccount(password: String)
    case checkSession
    case refreshUserProfile
    
    // User Endpoints
    case updateUserStatus(isActive: Bool)
    case updateUserProfile(UserProfile)
    
    // Content Endpoints
    case postLocation(LocationPost.Draft)
    case fetchPosts(region: MKCoordinateRegion)
    case getPost(id: String)
    case savePost(id: String)
    case unsavePost(id: String)
    
    // Chat Endpoints
    case getConversations
    case getMessages(conversationId: String, page: Int, pageSize: Int)
    case sendMessage(conversationId: String, content: String)
    
    // MARK: - HTTP Headers
    var headers: [String: String] {
        var headers = ["Content-Type": "application/json"]
        return headers
    }
    
    // MARK: - HTTP Method
    var method: HTTPMethod {
        switch self {
        case .checkSession, .refreshUserProfile, .getPost, .fetchPosts, .getConversations, .getMessages:
            return .get
        case .register, .login, .loginWithFirebaseToken, .postLocation, .sendMessage:
            return .post
        case .updatePassword, .updateUserStatus, .updateUserProfile, .savePost:
            return .put
        case .deleteAccount, .unsavePost:
            return .delete
        }
    }
    
    // MARK: - API Path
    var path: String {
        switch self {
        // Auth Paths
        case .loginWithFirebaseToken:
            return "/api/v1/auth/firebase"
        case .login:
            return "/api/v1/auth/login"
        case .register:
            return "/api/v1/auth/register"
        case .updatePassword:
            return "/api/v1/auth/password"
        case .deleteAccount:
            return "/api/v1/auth/account"
        case .checkSession:
            return "/api/v1/auth/session"
        case .refreshUserProfile:
            return "/api/v1/auth/profile"
            
        // User Paths
        case .updateUserStatus:
            return "/api/v1/users/status"
        case .updateUserProfile:
            return "/api/v1/users/profile"
            
        // Content Paths
        case .postLocation:
            return "/api/v1/posts"
        case .fetchPosts:
            return "/api/v1/posts/nearby"
        case .getPost(let id):
            return "/api/v1/posts/\(id)"
        case .savePost(let id):
            return "/api/v1/posts/\(id)/save"
        case .unsavePost(let id):
            return "/api/v1/posts/\(id)/save"
            
        // Chat Paths
        case .getConversations:
            return "/api/v1/chats"
        case .getMessages(let conversationId, _, _):
            return "/api/v1/chats/\(conversationId)/messages"
        case .sendMessage(let conversationId, _):
            return "/api/v1/chats/\(conversationId)/messages"
        }
    }
    
    // MARK: - HTTP Body
    var body: Encodable? {
        switch self {
        case .loginWithFirebaseToken(let idToken):
            return ["id_token": idToken]
            
        case .login(let email, let password):
            return ["email": email, "password": password]
            
        case .register(let email, let name, let password):
            return ["email": email, "name": name, "password": password]
            
        case .updatePassword(let currentPassword, let newPassword):
            return ["current_password": currentPassword, "new_password": newPassword]
            
        case .deleteAccount(let password):
            return ["password": password]
            
        case .updateUserStatus(let isActive):
            return ["is_active": isActive]
            
        case .updateUserProfile(let profile):
            return profile
            
        case .postLocation(let draft):
            return draft
            
        case .fetchPosts(let region):
            return [
                "latitude": region.center.latitude,
                "longitude": region.center.longitude,
                "latitude_delta": region.span.latitudeDelta,
                "longitude_delta": region.span.longitudeDelta
            ]
            
        case .sendMessage(_, let content):
            return ["content": content]
            
        case .getMessages(_, let page, let pageSize):
            return ["page": page, "page_size": pageSize]
            
        case .checkSession, .refreshUserProfile, .getPost, .getConversations, .savePost, .unsavePost:
            return nil
        }
    }
    
    // MARK: - Query Parameters
    var queryParameters: [String: String]? {
        switch self {
        case .getMessages(_, let page, let pageSize):
            return ["page": "\(page)", "page_size": "\(pageSize)"]
        default:
            return nil
        }
    }
}
