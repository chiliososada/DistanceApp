//
//  Logger.swift
//  DistanceApp
//
//  Created by toyousoft on 2025/03/03.
//

import Foundation
import OSLog

// MARK: - Log Level
enum LogLevel: Int, Comparable {
    case debug = 0
    case info = 1
    case warning = 2
    case error = 3
    case critical = 4
    
    static func < (lhs: LogLevel, rhs: LogLevel) -> Bool {
        return lhs.rawValue < rhs.rawValue
    }
}

// MARK: - Logger
final class Logger {
    // MARK: - Properties
    private static let subsystem = Bundle.main.bundleIdentifier ?? "com.distance.app"
    
    private static var minimumLogLevel: LogLevel = {
        #if DEBUG
        return .debug
        #else
        return .info
        #endif
    }()
    
    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
        return formatter
    }()
    
    private static let osLog = OSLog(subsystem: subsystem, category: "AppLogs")
    
    // MARK: - Configuration
    static func configure(minimumLevel: LogLevel) {
        self.minimumLogLevel = minimumLevel
    }
    
    // MARK: - Logging Methods
    static func debug(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        log(level: .debug, message: message, file: file, function: function, line: line)
    }
    
    static func info(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        log(level: .info, message: message, file: file, function: function, line: line)
    }
    
    static func warning(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        log(level: .warning, message: message, file: file, function: function, line: line)
    }
    
    static func error(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        log(level: .error, message: message, file: file, function: function, line: line)
    }
    
    static func critical(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        log(level: .critical, message: message, file: file, function: function, line: line)
    }
    
    // MARK: - Private Methods
    private static func log(level: LogLevel, message: String, file: String, function: String, line: Int) {
        // 检查日志级别
        guard level >= minimumLogLevel else { return }
        
        // 提取文件名
        let filename = URL(fileURLWithPath: file).lastPathComponent
        
        // 获取当前时间
        let timestamp = dateFormatter.string(from: Date())
        
        // 构建日志消息
        let logMessage = "[\(timestamp)] [\(levelString(for: level))] [\(filename):\(line)] \(function): \(message)"
        
        // 选择其中一种输出方式：
        
        #if DEBUG
        // 方式1: 只使用控制台输出
        print(logMessage)
        #else
        // 方式2: 只使用OSLog (生产环境)
        switch level {
        case .debug:
            os_log(.debug, log: osLog, "%{public}@", logMessage)
        case .info:
            os_log(.info, log: osLog, "%{public}@", logMessage)
        case .warning:
            os_log(.default, log: osLog, "%{public}@", logMessage)
        case .error:
            os_log(.error, log: osLog, "%{public}@", logMessage)
        case .critical:
            os_log(.fault, log: osLog, "%{public}@", logMessage)
        }
        #endif
    }
    
    private static func levelString(for level: LogLevel) -> String {
        switch level {
        case .debug:    return "DEBUG"
        case .info:     return "INFO"
        case .warning:  return "WARNING"
        case .error:    return "ERROR"
        case .critical: return "CRITICAL"
        }
    }
}
