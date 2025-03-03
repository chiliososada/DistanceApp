//
//  UserDefaultsManager.swift
//  DistanceApp
//
//  Created by toyousoft on 2025/03/03.
//

import Foundation
import Combine

// MARK: - Protocol
protocol StorageManagerProtocol {
    func saveObject<T: Encodable>(_ object: T, forKey key: String)
    func getObject<T: Decodable>(_ type: T.Type, forKey key: String) -> T?
    func saveString(_ value: String, forKey key: String)
    func getString(forKey key: String) -> String?
    func saveInt(_ value: Int, forKey key: String)
    func getInt(forKey key: String) -> Int?
    func saveDouble(_ value: Double, forKey key: String)
    func getDouble(forKey key: String) -> Double?
    func saveBool(_ value: Bool, forKey key: String)
    func getBool(forKey key: String) -> Bool?
    func saveDate(_ value: Date, forKey key: String)
    func getDate(forKey key: String) -> Date?
    func removeObject(forKey key: String)
    func removeAllObjects()
    func contains(key: String) -> Bool
}

// MARK: - Implementation
final class StorageManager: StorageManagerProtocol {
    // MARK: - Properties
    private let userDefaults: UserDefaults
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    
    // MARK: - Initialization
    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }
    
    // MARK: - Object Operations
    func saveObject<T: Encodable>(_ object: T, forKey key: String) {
        do {
            let data = try encoder.encode(object)
            userDefaults.set(data, forKey: key)
        } catch {
            Logger.error("保存对象失败: \(error.localizedDescription)")
        }
    }
    
    func getObject<T: Decodable>(_ type: T.Type, forKey key: String) -> T? {
        guard let data = userDefaults.data(forKey: key) else {
            return nil
        }
        
        do {
            return try decoder.decode(type, from: data)
        } catch {
            Logger.error("读取对象失败: \(error.localizedDescription)")
            return nil
        }
    }
    
    // MARK: - Primitive Type Operations
    func saveString(_ value: String, forKey key: String) {
        userDefaults.set(value, forKey: key)
    }
    
    func getString(forKey key: String) -> String? {
        return userDefaults.string(forKey: key)
    }
    
    func saveInt(_ value: Int, forKey key: String) {
        userDefaults.set(value, forKey: key)
    }
    
    func getInt(forKey key: String) -> Int? {
        return userDefaults.object(forKey: key) as? Int
    }
    
    func saveDouble(_ value: Double, forKey key: String) {
        userDefaults.set(value, forKey: key)
    }
    
    func getDouble(forKey key: String) -> Double? {
        return userDefaults.object(forKey: key) as? Double
    }
    
    func saveBool(_ value: Bool, forKey key: String) {
        userDefaults.set(value, forKey: key)
    }
    
    func getBool(forKey key: String) -> Bool? {
        return userDefaults.object(forKey: key) as? Bool
    }
    
    func saveDate(_ value: Date, forKey key: String) {
        userDefaults.set(value, forKey: key)
    }
    
    func getDate(forKey key: String) -> Date? {
        return userDefaults.object(forKey: key) as? Date
    }
    
    // MARK: - Management Operations
    func removeObject(forKey key: String) {
        userDefaults.removeObject(forKey: key)
    }
    
    func removeAllObjects() {
        let dictionary = userDefaults.dictionaryRepresentation()
        dictionary.keys.forEach { key in
            userDefaults.removeObject(forKey: key)
        }
    }
    
    func contains(key: String) -> Bool {
        return userDefaults.object(forKey: key) != nil
    }
}
