import SwiftUI

@main
struct PortKillerApp: App {
    @State private var manager = PortManager()

    init() {
        // Hide from Dock
        NSApplication.shared.setActivationPolicy(.accessory)
    }

    var body: some Scene {
        MenuBarExtra {
            MenuBarView(manager: manager)
        } label: {
            Image(nsImage: menuBarIcon())
        }
        .menuBarExtraStyle(.window)
    }

    private func menuBarIcon() -> NSImage {
        if let image = loadIcon(named: "ToolbarIcon") {
            image.size = NSSize(width: 18, height: 18)
            return image
        }
        return NSImage(systemSymbolName: "network.slash", accessibilityDescription: nil) ?? NSImage()
    }

    private func loadIcon(named name: String) -> NSImage? {
        // Search in multiple locations for compatibility with dev and release builds
        let bundlePaths = [
            Bundle.main.resourceURL?.appendingPathComponent("PortKiller_PortKiller.bundle"),
            Bundle.main.bundleURL.appendingPathComponent("PortKiller_PortKiller.bundle"),
            Bundle.main.resourceURL,
            Bundle.main.bundleURL
        ]

        for bundlePath in bundlePaths {
            if let path = bundlePath?.appendingPathComponent("\(name).png"),
               FileManager.default.fileExists(atPath: path.path),
               let image = NSImage(contentsOf: path) {
                return image
            }
        }

        // Fallback: try Bundle.module for development
        if let url = Bundle.module.url(forResource: name, withExtension: "png"),
           let image = NSImage(contentsOf: url) {
            return image
        }

        return nil
    }
}
