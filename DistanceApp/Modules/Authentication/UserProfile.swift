//
//  Untitled.swift
//  DistanceApp
//
//  Created by toyousoft on 2025/03/03.
//

//
//  UserProfile.swift
//  DistanceApp
//
//  Created by toyousoft on 2025/03/03.
//

//
//  UserProfile.swift
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
    
    // MARK: - Initialization
    init(
        id: String,
        displayName: String,
        email: String,
        photoURL: URL? = nil,
        createdAt: Date = Date(),
        lastSeen: Date? = nil,
        authToken: String,
        csrfToken: String
    ) {
        self.id = id
        self.displayName = displayName
        self.email = email
        self.photoURL = photoURL
        self.createdAt = createdAt
        self.lastSeen = lastSeen
        self.authToken = authToken
        self.csrfToken = csrfToken
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
}
