import Foundation
import Defaults

struct ProcessSeenStat: Codable, Equatable {
    var firstSeenAt: Date
    var lastSeenAt: Date
    var seenSeconds: TimeInterval
}

struct ProcessFamiliarityData: Codable, Defaults.Serializable {
    var stats: [String: ProcessSeenStat] = [:]
    var knownProcessKeys: Set<String> = []
    var alwaysShowProcessKeys: Set<String> = []
    
    mutating func cleanup(keepDays: Int = 90) {
        let cutoff = Date().addingTimeInterval(-Double(keepDays * 24 * 60 * 60))
        stats = stats.filter { $0.value.lastSeenAt > cutoff }
    }
}

extension PortInfo {
    var processKey: String {
        let commandParts = command.split(separator: " ", maxSplits: 1, omittingEmptySubsequences: true)
        if let firstPart = commandParts.first {
            let executable = String(firstPart)
            if executable.hasPrefix("/") {
                return "\(executable)|\(processName)"
            }
        }
        return processName
    }
}

