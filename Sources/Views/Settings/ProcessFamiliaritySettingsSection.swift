import SwiftUI
import Defaults

struct ProcessFamiliaritySettingsSection: View {
    @Bindable var appState: AppState
    @State private var showResetConfirmation = false
    
    var body: some View {
        SettingsGroup("Process Filtering", icon: "eye.slash.fill") {
            VStack(spacing: 0) {
                SettingsRowContainer {
                    SettingsToggleRow(
                        title: "Hide familiar processes",
                        subtitle: "Automatically hide processes that are frequently seen",
                        isOn: Binding(
                            get: { appState.hideFamiliarProcesses },
                            set: { appState.hideFamiliarProcesses = $0 }
                        )
                    )
                }
                
                SettingsDivider()
                
                SettingsRowContainer {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Reset Learned Data")
                                .fontWeight(.medium)
                            Text("Clear all familiarity statistics and manual marks")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        
                        Spacer()
                        
                        Button("Reset") {
                            showResetConfirmation = true
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                    }
                }
            }
        }
        .confirmationDialog(
            "Reset Learned Familiarity",
            isPresented: $showResetConfirmation
        ) {
            Button("Reset", role: .destructive) {
                appState.resetLearnedFamiliarity()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will clear all learned familiarity statistics and manual marks. This action cannot be undone.")
        }
    }
}

