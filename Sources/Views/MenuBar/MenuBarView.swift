/// MenuBarView - Main menu bar dropdown interface
///
/// Displays the list of active ports in a compact menu bar dropdown.
/// Supports both list and tree view modes for port organization.
///
/// - Note: This view is shown when clicking the menu bar icon.
/// - Important: Uses `@Bindable var state: AppState` for state management.

import SwiftUI
import Defaults

struct MenuBarView: View {
    @Environment(\.openWindow) private var openWindow
    @Bindable var state: AppState
    @State private var searchText = ""
    @State private var confirmingKillAll = false
    @State private var confirmingKillPort: UUID?
    @State private var hoveredPort: UUID?
    @State private var expandedProcesses: Set<Int> = []
    @State private var useTreeView = UserDefaults.standard.bool(forKey: "useTreeView")
    @State private var cachedGroups: [ProcessGroup] = []

    private var groupedByProcess: [ProcessGroup] { cachedGroups }

    /// Updates cached process groups from filtered ports
    private func updateGroupedByProcess() {
        let grouped = Dictionary(grouping: filteredPorts) { $0.pid }
        cachedGroups = grouped.map { pid, ports in
            ProcessGroup(
                id: pid,
                processName: ports.first?.processName ?? "Unknown",
                ports: ports.sorted(by: state.sortByRecentAppearance)
            )
        }.sorted { a, b in
            let aPort = a.ports.first
            let bPort = b.ports.first
            if let aPort = aPort, let bPort = bPort {
                if state.sortByRecentAppearance(aPort, bPort) {
                    return true
                }
            }
            
            let aHasFavorite = a.ports.contains(where: { state.isFavorite($0.port) })
            let aHasWatched = a.ports.contains(where: { state.isWatching($0.port) })
            let bHasFavorite = b.ports.contains(where: { state.isFavorite($0.port) })
            let bHasWatched = b.ports.contains(where: { state.isWatching($0.port) })

            let aPriority = aHasFavorite ? 2 : (aHasWatched ? 1 : 0)
            let bPriority = bHasFavorite ? 2 : (bHasWatched ? 1 : 0)

            if aPriority != bPriority {
                return aPriority > bPriority
            } else {
                return a.processName.localizedCaseInsensitiveCompare(b.processName) == .orderedAscending
            }
        }
    }

    /// Filters ports based on search text and sorts by recent
    private var filteredPorts: [PortInfo] {
        var filtered = state.ports
        
        if state.hideFamiliarProcesses {
            filtered = filtered.filter { port in
                if state.favorites.contains(port.port) || state.watchedPorts.contains(where: { $0.port == port.port }) {
                    return true
                }
                return !state.isFamiliar(port)
            }
        }
        
        if !searchText.isEmpty {
            filtered = filtered.filter {
                String($0.port).contains(searchText) || $0.processName.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        return filtered.sorted(by: state.sortByRecentAppearance)
    }

    /// Filters port-forward connections based on search text
    private var filteredPortForwardConnections: [PortForwardConnectionState] {
        let connections = state.portForwardManager.connections
        if searchText.isEmpty { return connections }
        return connections.filter {
            String($0.effectivePort).contains(searchText) ||
            $0.config.name.localizedCaseInsensitiveContains(searchText) ||
            $0.config.namespace.localizedCaseInsensitiveContains(searchText) ||
            $0.config.service.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            MenuBarHeader(searchText: $searchText, portCount: filteredPorts.count + filteredPortForwardConnections.count)

            Divider()

            MenuBarPortList(
                filteredPorts: filteredPorts,
                filteredPortForwardConnections: filteredPortForwardConnections,
                groupedByProcess: groupedByProcess,
                useTreeView: useTreeView,
                expandedProcesses: $expandedProcesses,
                confirmingKillPort: $confirmingKillPort,
                state: state
            )

            Divider()

            MenuBarActions(
                confirmingKillAll: $confirmingKillAll,
                useTreeView: $useTreeView,
                state: state,
                openWindow: openWindow
            )
        }
        .frame(width: 340)
        .onAppear { updateGroupedByProcess() }
        .onChange(of: state.ports) { _, _ in updateGroupedByProcess() }
        .onChange(of: searchText) { _, _ in updateGroupedByProcess() }
        .onChange(of: state.hideFamiliarProcesses) { _, _ in updateGroupedByProcess() }
    }
}
