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
    case updateProfile(params: [String: Any])
    case signout
    
    // Topics Endpoints
    case getTopics(findby: String, max: Int, recency: Int)
    case createTopic(request: CreateTopicRequest)
    case likeTopic(id: String)
    case unlikeTopic(id: String)
    
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
        case .register, .loginWithFirebaseToken, .getTopics, .createTopic, .likeTopic, .unlikeTopic:
            return .post
        case .signout:
            return .post
        case .updatePassword, .updateProfile:
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
        case .signout:
            return "/api/v1/auth/users/signout"
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
        case .updateProfile:
            return "/api/v1/auth/users/updateprofile"
            
        // Topics Paths
        case .getTopics:
            return "/api/v1/auth/topics/findby"
        case .createTopic:
            return "/api/v1/auth/topics"
        case .likeTopic(let id):
            return "/api/v1/auth/topics/\(id)/like"
        case .unlikeTopic(let id):
            return "/api/v1/auth/topics/\(id)/unlike"
        }
    }
    
    // MARK: - HTTP Body
    var body: Encodable? {
        switch self {
        case .loginWithFirebaseToken(let idToken):
            return ["id_token": idToken]
        case .getTopics(let findby, let max, let recency):
            return DynamicParameters([
                "findby": findby,
                "max": max,
                "recency": recency
            ])
        case .updateProfile(let params):
            return DynamicParameters(params)
        case .signout:
            return nil
        case .register(let email, let name, let password):
            return ["email": email, "name": name, "password": password]
            
        case .updatePassword(let currentPassword, let newPassword):
            return ["current_password": currentPassword, "new_password": newPassword]
            
        case .deleteAccount(let password):
            return ["password": password]
            
        case .checkSession:
            return nil
            
        case .createTopic(let request):
            return request
            
        case .likeTopic, .unlikeTopic:
            return nil
        }
    }
}

struct DynamicParameters: Encodable {
    private let parameters: [String: Any]
    
    init(_ parameters: [String: Any]) {
        self.parameters = parameters
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: DynamicCodingKey.self)
        
        for (key, value) in parameters {
            let codingKey = DynamicCodingKey(key: key)
            
            if let boolValue = value as? Bool {
                try container.encode(boolValue, forKey: codingKey)
            } else if let stringValue = value as? String {
                try container.encode(stringValue, forKey: codingKey)
            } else if let intValue = value as? Int {
                try container.encode(intValue, forKey: codingKey)
            } else if let doubleValue = value as? Double {
                try container.encode(doubleValue, forKey: codingKey)
            } else if let arrayValue = value as? [String] {
                try container.encode(arrayValue, forKey: codingKey)
            } else if let dictValue = value as? [String: String] {
                try container.encode(dictValue, forKey: codingKey)
            } else {
                // 对于不支持的类型，尝试使用JSON序列化
                let jsonData = try JSONSerialization.data(withJSONObject: value, options: [])
                if let jsonString = String(data: jsonData, encoding: .utf8) {
                    try container.encode(jsonString, forKey: codingKey)
                }
            }
        }
    }
}

struct DynamicCodingKey: CodingKey {
    var stringValue: String
    var intValue: Int?
    
    init(key: String) {
        self.stringValue = key
        self.intValue = nil
    }
    
    init?(stringValue: String) {
        self.stringValue = stringValue
        self.intValue = nil
    }
    
    init?(intValue: Int) {
        self.stringValue = String(intValue)
        self.intValue = intValue
    }
}
