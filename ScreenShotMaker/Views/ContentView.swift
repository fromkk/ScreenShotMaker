import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {
    @Bindable var projectState: ProjectState

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
                BatchExportButton(state: projectState)
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
    @State private var showExportError = false
    @State private var exportError: String?

    var body: some View {
        Button {
            exportCurrentScreen()
        } label: {
            Label("Export", systemImage: "square.and.arrow.up")
        }
        .buttonStyle(.borderedProminent)
        .disabled(state.selectedScreen == nil || state.selectedDevice == nil)
        .alert("Export Error", isPresented: $showExportError) {
            Button("OK") {}
        } message: {
            Text(exportError ?? "Unknown error")
        }
    }

    private func exportCurrentScreen() {
        guard let screen = state.selectedScreen,
              let device = state.selectedDevice else { return }

        let panel = NSSavePanel()
        panel.allowedContentTypes = [.png, .jpeg]
        panel.nameFieldStringValue = screen.name + ".png"
        panel.canCreateDirectories = true

        guard panel.runModal() == .OK, let url = panel.url else { return }

        let format: ExportFormat = url.pathExtension.lowercased() == "jpeg" || url.pathExtension.lowercased() == "jpg"
            ? .jpeg : .png

        let languageCode = state.selectedLanguage?.code ?? "en"
        guard let data = ExportService.exportScreen(screen, device: device, format: format, languageCode: languageCode) else {
            exportError = "Failed to render the screen."
            showExportError = true
            return
        }

        do {
            try data.write(to: url, options: .atomic)
        } catch {
            exportError = error.localizedDescription
            showExportError = true
        }
    }
}

private struct BatchExportButton: View {
    let state: ProjectState
    @State private var showBatchExport = false
    @State private var progressState = ExportProgressState()
    @State private var outputDirectory: URL?
    @State private var exportTask: Task<Void, Never>?

    var body: some View {
        Button {
            startBatchExport()
        } label: {
            Label("Export All", systemImage: "square.and.arrow.up.on.square")
        }
        .disabled(state.project.screens.isEmpty)
        .sheet(isPresented: $showBatchExport) {
            ExportProgressView(
                progressState: progressState,
                outputDirectory: outputDirectory
            ) {
                showBatchExport = false
                progressState.reset()
            }
        }
    }

    private func startBatchExport() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.canCreateDirectories = true
        panel.prompt = "Export"
        panel.message = "Choose an output folder for batch export"

        guard panel.runModal() == .OK, let url = panel.url else { return }
        outputDirectory = url
        progressState.reset()
        showBatchExport = true

        exportTask = Task {
            await ExportService.batchExport(
                project: state.project,
                devices: state.project.selectedDevices,
                languages: state.project.languages,
                format: .png,
                outputDirectory: url,
                progressState: progressState
            )
        }
    }
}

#Preview {
    ContentView(projectState: ProjectState())
        .frame(width: 1200, height: 800)
}
