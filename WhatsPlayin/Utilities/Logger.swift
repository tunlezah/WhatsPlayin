import Foundation
import Combine
import os

enum LogCategory: String {
    case audio = "Audio"
    case fingerprint = "Fingerprint"
    case recognition = "Recognition"
    case metadata = "Metadata"
    case coverArt = "CoverArt"
    case ui = "UI"
    case network = "Network"
    case general = "General"
}

final class AppLogger {
    static let shared = AppLogger()

    private let subsystem = Bundle.main.bundleIdentifier ?? "com.whatsplayin.app"
    private var loggers: [LogCategory: os.Logger] = [:]

    /// Debug log entries for the debug panel
    @Published private(set) var debugEntries: [DebugLogEntry] = []
    private let maxDebugEntries = 200
    private let lock = NSLock()

    private init() {
        for category in [LogCategory.audio, .fingerprint, .recognition, .metadata, .coverArt, .ui, .network, .general] {
            loggers[category] = os.Logger(subsystem: subsystem, category: category.rawValue)
        }
    }

    func log(_ message: String, category: LogCategory = .general, level: OSLogType = .info) {
        loggers[category]?.log(level: level, "\(message, privacy: .public)")
        addDebugEntry(message: message, category: category, level: level)
    }

    func debug(_ message: String, category: LogCategory = .general) {
        log(message, category: category, level: .debug)
    }

    func error(_ message: String, category: LogCategory = .general) {
        log(message, category: category, level: .error)
    }

    func info(_ message: String, category: LogCategory = .general) {
        log(message, category: category, level: .info)
    }

    private func addDebugEntry(message: String, category: LogCategory, level: OSLogType) {
        let entry = DebugLogEntry(
            timestamp: Date(),
            category: category,
            level: level,
            message: message
        )
        lock.lock()
        debugEntries.append(entry)
        if debugEntries.count > maxDebugEntries {
            debugEntries.removeFirst(debugEntries.count - maxDebugEntries)
        }
        lock.unlock()
    }

    func clearDebugEntries() {
        lock.lock()
        debugEntries.removeAll()
        lock.unlock()
    }
}

struct DebugLogEntry: Identifiable {
    let id = UUID()
    let timestamp: Date
    let category: LogCategory
    let level: OSLogType
    let message: String

    var levelString: String {
        switch level {
        case .debug: return "DEBUG"
        case .info: return "INFO"
        case .error: return "ERROR"
        case .fault: return "FAULT"
        default: return "LOG"
        }
    }
}
