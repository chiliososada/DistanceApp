//
//  KeychainWrapper.swift
//  DistanceApp
//
//  Created by toyousoft on 2025/03/03.
//

import Foundation
import KeychainAccess

// MARK: - Protocol
protocol KeychainWrapperProtocol {
    func set(_ value: String, forKey key: String) throws
    func string(forKey key: String) throws -> String?
    func set(_ data: Data, forKey key: String) throws
    func data(forKey key: String) throws -> Data?
    func remove(_ key: String) throws
    func removeAllKeys()
    func containsKey(_ key: String) -> Bool
    func setObject<T: Encodable>(_ object: T, forKey key: String) throws
    func object<T: Decodable>(_ type: T.Type, forKey key: String) throws -> T?
}

// MARK: - Implementation
final class KeychainWrapper: KeychainWrapperProtocol {
    static let standard = KeychainWrapper()
    private let keychain: Keychain
    
    // MARK: - Error Type
    enum KeychainError: LocalizedError {
        case saveError(String)
        case readError(String)
        case deleteError(String)
        
        var errorDescription: String? {
            switch self {
            case .saveError(let message):
                return "保存数据失败: \(message)"
            case .readError(let message):
                return "读取数据失败: \(message)"
            case .deleteError(let message):
                return "删除数据失败: \(message)"
            }
        }
    }
    
    // MARK: - Initialization
    init(service: String = "com.distance.app.keychain", accessGroup: String? = nil) {
        var keychain = Keychain(service: service)
            .accessibility(.afterFirstUnlock)
        
        if let accessGroup = accessGroup {
            keychain = keychain.accessGroup(accessGroup)
        }
        
        self.keychain = keychain
    }
    
    // MARK: - String Methods
    func set(_ value: String, forKey key: String) throws {
        do {
            try keychain.set(value, key: key)
        } catch {
            throw KeychainError.saveError(error.localizedDescription)
        }
    }
    
    func string(forKey key: String) throws -> String? {
        do {
            return try keychain.get(key)
        } catch {
            throw KeychainError.readError(error.localizedDescription)
        }
    }
    
    // MARK: - Data Methods
    func set(_ data: Data, forKey key: String) throws {
        do {
            try keychain.set(data, key: key)
        } catch {
            throw KeychainError.saveError(error.localizedDescription)
        }
    }
    
    func data(forKey key: String) throws -> Data? {
        do {
            return try keychain.getData(key)
        } catch {
            throw KeychainError.readError(error.localizedDescription)
        }
    }
    
    // MARK: - Removal Methods
    func remove(_ key: String) throws {
        do {
            try keychain.remove(key)
        } catch {
            throw KeychainError.deleteError(error.localizedDescription)
        }
    }
    
    func removeAllKeys() {
        try? keychain.removeAll()
    }
    
    // MARK: - Utility Methods
    func containsKey(_ key: String) -> Bool {
        (try? string(forKey: key)) != nil || (try? data(forKey: key)) != nil
    }
    
    // MARK: - Generic Methods
    func setObject<T: Encodable>(_ object: T, forKey key: String) throws {
        let data = try JSONEncoder().encode(object)
        try set(data, forKey: key)
    }
    
    func object<T: Decodable>(_ type: T.Type, forKey key: String) throws -> T? {
        guard let data = try data(forKey: key) else { return nil }
        return try JSONDecoder().decode(type, from: data)
    }
}
