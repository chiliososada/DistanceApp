//
//  Untitled.swift
//  DistanceApp
//
//  Created by toyousoft on 2025/03/03.
//
import Foundation

// MARK: - User Profile
struct UserProfile: Codable, Equatable, Identifiable {
    // MARK: - Properties
    var id: String
    var displayName: String
    var email: String
    var photoURL: URL?
    var createdAt: Date
    var lastSeen: Date?
    
    // MARK: - Tokens
    let authToken: String
    let csrfToken: String
    
    // MARK: - 附加字段
    let gender: String?
    let bio: String?
    let chatID: [String]?
    let chatUrl: String?
    
    // MARK: - Initialization
    init(
        id: String,
        displayName: String,
        email: String,
        photoURL: URL? = nil,
        createdAt: Date = Date(),
        lastSeen: Date? = nil,
        authToken: String,
        csrfToken: String,
        gender: String? = nil,
        bio: String? = nil,
        chatID: [String]? = nil,
        chatUrl: String? = nil
    ) {
        self.id = id
        self.displayName = displayName
        self.email = email
        self.photoURL = photoURL
        self.createdAt = createdAt
        self.lastSeen = lastSeen
        self.authToken = authToken
        self.csrfToken = csrfToken
        self.gender = gender
        self.bio = bio
        self.chatID = chatID
        self.chatUrl = chatUrl
    }
    
    // MARK: - Backend Model Conversion
    init(backendProfile: BackendUserProfile) {
        self.id = backendProfile.uid
        self.displayName = backendProfile.displayName
        self.email = backendProfile.email
        
        if let photoUrlString = backendProfile.photoUrl {
            self.photoURL = URL(string: photoUrlString)
        } else {
            self.photoURL = nil
        }
        
        self.createdAt = Date()
        self.lastSeen = Date()
        self.authToken = backendProfile.authToken
        self.csrfToken = backendProfile.csrfToken
        self.gender = backendProfile.gender
        self.bio = backendProfile.bio
        self.chatID = backendProfile.chatID
        self.chatUrl = backendProfile.chatUrl
    }
}

// MARK: - Backend Profile Model
struct BackendUserProfile: Codable {
    let csrfToken: String
    let authToken: String
    let uid: String
    let displayName: String
    let photoUrl: String?
    let email: String
    let gender: String?
    let bio: String?
    let session: String?
    let chatID: [String]?
    let chatUrl: String?
    
    enum CodingKeys: String, CodingKey {
        case csrfToken = "csrf_token"
        case authToken = "chat_token"
        case uid = "uid"
        case displayName = "display_name"
        case photoUrl = "photo_url"
        case email = "email"
        case gender = "gender"
        case bio = "bio"
        case session = "session"
        case chatID = "chat_id"
        case chatUrl = "chat_url"
    }
}
