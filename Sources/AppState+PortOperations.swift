import Foundation
import Defaults

extension AppState {
    /// Refreshes the port list by scanning for active ports.
    func refresh() async {
        guard !isScanning else { return }
        isScanning = true
        defer { isScanning = false }

        let scanned = await scanner.scanPorts()
        updatePorts(scanned)
        checkWatchedPorts()
    }

    /// Updates the internal port list only if there are changes.
    func updatePorts(_ newPorts: [PortInfo]) {
        let newSet = Set(newPorts.map { "\($0.port)-\($0.pid)" })
        let oldSet = Set(ports.map { "\($0.port)-\($0.pid)" })
        guard newSet != oldSet else { return }

        updateProcessFamiliarityStats(newPorts: newPorts)
        
        ports = newPorts.sorted { a, b in
            let aFav = favorites.contains(a.port)
            let bFav = favorites.contains(b.port)
            if aFav != bFav { return aFav }
            return a.port < b.port
        }
    }
    
    private func updateProcessFamiliarityStats(newPorts: [PortInfo]) {
        let now = Date()
        let deltaSeconds: TimeInterval
        
        if let lastTime = lastRefreshTime {
            deltaSeconds = now.timeIntervalSince(lastTime)
        } else {
            deltaSeconds = Double(Defaults[.refreshInterval])
        }
        
        lastRefreshTime = now
        
        let currentProcessKeys = Set(newPorts.map { $0.processKey })
        let newlyAppearedProcessKeys = currentProcessKeys.subtracting(lastVisibleProcessKeys)
        lastVisibleProcessKeys = currentProcessKeys
        
        for key in currentProcessKeys {
            var stat = processFamiliarityData.stats[key] ?? ProcessSeenStat(
                firstSeenAt: now,
                lastSeenAt: now,
                seenSeconds: 0
            )
            
            if stat.firstSeenAt > now {
                stat.firstSeenAt = now
            }
            
            if newlyAppearedProcessKeys.contains(key) {
                stat.lastSeenAt = now
            }
            stat.seenSeconds += deltaSeconds
            
            processFamiliarityData.stats[key] = stat
        }
        
        processFamiliarityData.cleanup(keepDays: 90)
    }

    /// Kills the process using the specified port.
    func killPort(_ port: PortInfo) async {
        if await scanner.killProcessGracefully(pid: port.pid) {
            ports.removeAll { $0.id == port.id }
            await refresh()
        }
    }

    /// Kills all processes currently using ports.
    func killAll() async {
        for port in ports {
            _ = await scanner.killProcessGracefully(pid: port.pid)
        }
        ports.removeAll()
        await refresh()
    }
}
