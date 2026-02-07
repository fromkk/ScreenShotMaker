import SwiftUI

struct ContentView: View {
    @State private var projectState = ProjectState()

    var body: some View {
        HStack(spacing: 0) {
            SidebarView(state: projectState)
                .frame(width: 240)

            CanvasView(state: projectState)

            PropertiesPanelView(state: projectState)
                .frame(width: 300)
        }
        .toolbar {
            ToolbarItemGroup(placement: .automatic) {
                DevicePicker(state: projectState)
                LanguagePicker(state: projectState)
                Spacer()
                ExportButton(state: projectState)
            }
        }
    }
}

private struct DevicePicker: View {
    @Bindable var state: ProjectState

    var body: some View {
        Picker("Device", selection: $state.selectedDeviceIndex) {
            ForEach(Array(state.project.selectedDevices.enumerated()), id: \.offset) { index, device in
                Label(device.name, systemImage: device.category.iconName)
                    .tag(index)
            }
        }
        .frame(maxWidth: 200)
    }
}

private struct LanguagePicker: View {
    @Bindable var state: ProjectState

    var body: some View {
        Picker("Language", selection: $state.selectedLanguageIndex) {
            ForEach(Array(state.project.languages.enumerated()), id: \.offset) { index, language in
                Text(language.displayName)
                    .tag(index)
            }
        }
        .frame(maxWidth: 150)
    }
}

private struct ExportButton: View {
    let state: ProjectState

    var body: some View {
        Button {
            // TODO: Export
        } label: {
            Label("Export", systemImage: "square.and.arrow.up")
        }
        .buttonStyle(.borderedProminent)
    }
}

#Preview {
    ContentView()
        .frame(width: 1200, height: 800)
}
