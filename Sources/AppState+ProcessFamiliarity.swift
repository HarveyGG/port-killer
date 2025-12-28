import Foundation

extension AppState {
    private enum FamiliarityThreshold {
        static let totalSeenHours: TimeInterval = 6
        static let ageInDays: TimeInterval = 7
        static let minimumSeenSeconds: TimeInterval = 1800
    }
    
    func isFamiliar(_ port: PortInfo) -> Bool {
        let key = port.processKey
        
        if processFamiliarityData.alwaysShowProcessKeys.contains(key) {
            return false
        }
        
        if processFamiliarityData.knownProcessKeys.contains(key) {
            return true
        }
        
        guard let stat = processFamiliarityData.stats[key] else {
            return false
        }
        
        let now = Date()
        let totalSeenHours = stat.seenSeconds / 3600
        let daysSinceFirstSeen = (now.timeIntervalSince1970 - stat.firstSeenAt.timeIntervalSince1970) / 86400
        
        if totalSeenHours >= FamiliarityThreshold.totalSeenHours {
            return true
        }
        
        if daysSinceFirstSeen >= FamiliarityThreshold.ageInDays && stat.seenSeconds >= FamiliarityThreshold.minimumSeenSeconds {
            return true
        }
        
        return false
    }
    
    func markAsFamiliar(_ port: PortInfo) {
        let key = port.processKey
        processFamiliarityData.knownProcessKeys.insert(key)
        processFamiliarityData.alwaysShowProcessKeys.remove(key)
    }
    
    func markAsAlwaysShow(_ port: PortInfo) {
        let key = port.processKey
        processFamiliarityData.alwaysShowProcessKeys.insert(key)
        processFamiliarityData.knownProcessKeys.remove(key)
    }
    
    func removeFamiliarityMark(_ port: PortInfo) {
        let key = port.processKey
        processFamiliarityData.knownProcessKeys.remove(key)
        processFamiliarityData.alwaysShowProcessKeys.remove(key)
    }
    
    func resetLearnedFamiliarity() {
        processFamiliarityData.stats.removeAll()
        processFamiliarityData.knownProcessKeys.removeAll()
        processFamiliarityData.alwaysShowProcessKeys.removeAll()
    }
    
    func getProcessSeenStat(_ port: PortInfo) -> ProcessSeenStat? {
        processFamiliarityData.stats[port.processKey]
    }
    
    func sortByRecentAppearance(_ a: PortInfo, _ b: PortInfo) -> Bool {
        let aStat = getProcessSeenStat(a)
        let bStat = getProcessSeenStat(b)
        let aTime = aStat?.lastSeenAt ?? Date()
        let bTime = bStat?.lastSeenAt ?? Date()
        
        if aTime != bTime {
            return aTime > bTime
        }
        return a.port < b.port
    }
}

