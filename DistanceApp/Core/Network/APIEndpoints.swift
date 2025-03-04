//
//  APIEndpoints.swift
//  DistanceApp
//

import Foundation

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
    //case login(email: String, password: String)
    case register(email: String, name: String, password: String)
    case updatePassword(currentPassword: String, newPassword: String)
    case deleteAccount(password: String)
    case checkSession
    
    // MARK: - HTTP Headers
    var headers: [String: String] {
        var headers = ["Content-Type": "application/json"]
        return headers
    }
    
    // MARK: - HTTP Method
    var method: HTTPMethod {
        switch self {
        case .checkSession:
            return .get
        case .register, .loginWithFirebaseToken:
            return .post
        case .updatePassword:
            return .put
        case .deleteAccount:
            return .delete
        }
    }
    
    // MARK: - API Path
    var path: String {
        switch self {
        // Auth Paths
        case .loginWithFirebaseToken:
            return "/api/v1/login"
       // case .login:
        //    return "/api/v1/login"
        case .register:
            return "/api/v1/auth/register"
        case .updatePassword:
            return "/api/v1/auth/password"
        case .deleteAccount:
            return "/api/v1/auth/account"
        case .checkSession:
            return "/api/v1/auth/checksession"
        }
    }
    
    // MARK: - HTTP Body
    var body: Encodable? {
        switch self {
        case .loginWithFirebaseToken(let idToken):
            return ["id_token": idToken]
            
    //    case .login(let email, let password):
        //    return ["email": email, "password": password]
            
        case .register(let email, let name, let password):
            return ["email": email, "name": name, "password": password]
            
        case .updatePassword(let currentPassword, let newPassword):
            return ["current_password": currentPassword, "new_password": newPassword]
            
        case .deleteAccount(let password):
            return ["password": password]
            
        case .checkSession:
            return nil
        }
    }
}
