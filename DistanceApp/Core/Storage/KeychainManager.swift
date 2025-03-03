//
//  KeychainManager.swift
//  DistanceApp
//
//  Created by toyousoft on 2025/03/03.
//

import Foundation

// MARK: - Protocol
protocol KeychainManagerProtocol {
    func saveSecureString(_ value: String, forKey key: String) throws
    func getSecureString(forKey key: String) throws -> String?
    func saveSecureData(_ data: Data, forKey key: String) throws
    func getSecureData(forKey key: String) throws -> Data?
    func deleteSecureData(forKey key: String) throws
    func clearAll() throws
    func hasKey(_ key: String) -> Bool
    func saveSecureObject<T: Encodable>(_ object: T, forKey key: String) throws
    func getSecureObject<T: Decodable>(_ type: T.Type, forKey key: String) throws -> T?
}

// MARK: - Implementation
final class KeychainManager: KeychainManagerProtocol {
    // MARK: - Properties
    private let keychain: KeychainWrapperProtocol
    
    // MARK: - Initialization
    init(keychain: KeychainWrapperProtocol = KeychainWrapper.standard) {
        self.keychain = keychain
    }
    
    // MARK: - String Operations
    func saveSecureString(_ value: String, forKey key: String) throws {
        try keychain.set(value, forKey: key)
    }
    
    func getSecureString(forKey key: String) throws -> String? {
        try keychain.string(forKey: key)
    }
    
    // MARK: - Data Operations
    func saveSecureData(_ data: Data, forKey key: String) throws {
        try keychain.set(data, forKey: key)
    }
    
    func getSecureData(forKey key: String) throws -> Data? {
        try keychain.data(forKey: key)
    }
    
    func deleteSecureData(forKey key: String) throws {
        try keychain.remove(key)
    }
    
    func clearAll() throws {
        keychain.removeAllKeys()
    }
    
    func hasKey(_ key: String) -> Bool {
        keychain.containsKey(key)
    }
    
    // MARK: - Object Operations
    func saveSecureObject<T: Encodable>(_ object: T, forKey key: String) throws {
        try keychain.setObject(object, forKey: key)
    }
    
    func getSecureObject<T: Decodable>(_ type: T.Type, forKey key: String) throws -> T? {
        try keychain.object(type, forKey: key)
    }
}
