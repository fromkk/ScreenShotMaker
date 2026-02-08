import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {
    @Bindable var projectState: ProjectState
    @Environment(\.undoManager) private var undoManager
    @State private var showInspector = true

    var body: some View {
        NavigationSplitView {
            SidebarView(state: projectState)
                .navigationSplitViewColumnWidth(min: 200, ideal: 240, max: 320)
        } detail: {
            CanvasView(state: projectState)
                .inspector(isPresented: $showInspector) {
                    PropertiesPanelView(state: projectState)
                        .inspectorColumnWidth(min: 250, ideal: 300, max: 400)
                }
        }
        .toolbar {
            ToolbarItemGroup(placement: .automatic) {
                DevicePicker(state: projectState)
                DeviceManagerButton(state: projectState)
                LanguagePicker(state: projectState)
                LanguageManagerButton(state: projectState)
                Spacer()
                ExportButton(state: projectState)
                BatchExportButton(state: projectState)

                Button {
                    withAnimation {
                        showInspector.toggle()
                    }
                } label: {
                    Image(systemName: "sidebar.trailing")
                }
                .help("Toggle Inspector")
            }
        }
        .onAppear {
            projectState.undoManager = undoManager
        }
        .onChange(of: undoManager) { _, newValue in
            projectState.undoManager = newValue
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

private struct DeviceManagerButton: View {
    @Bindable var state: ProjectState
    @State private var showPopover = false

    var body: some View {
        Button {
            showPopover = true
        } label: {
            Image(systemName: "plus.circle")
        }
        .popover(isPresented: $showPopover) {
            deviceManagerPopover
        }
    }

    private var deviceManagerPopover: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                Text("Select Devices")
                    .font(.system(size: 13, weight: .semibold))

                ForEach(DeviceCategory.allCases) { category in
                    let devices = DeviceSize.sizes(for: category)
                    if !devices.isEmpty {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(category.displayName)
                                .font(.system(size: 11, weight: .medium))
                                .foregroundStyle(.secondary)

                            ForEach(devices) { device in
                                let isSelected = state.project.selectedDevices.contains(device)
                                Button {
                                    toggleDevice(device)
                                } label: {
                                    HStack {
                                        Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                                            .foregroundStyle(isSelected ? .blue : .secondary)
                                        Text(device.name)
                                            .font(.system(size: 12))
                                        Spacer()
                                        Text(device.sizeDescription)
                                            .font(.system(size: 10, design: .monospaced))
                                            .foregroundStyle(.tertiary)
                                    }
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
            }
            .padding(12)
        }
        .frame(width: 300)
        .frame(maxHeight: 400)
    }

    private func toggleDevice(_ device: DeviceSize) {
        if let index = state.project.selectedDevices.firstIndex(of: device) {
            guard state.project.selectedDevices.count > 1 else { return }
            state.project.selectedDevices.remove(at: index)
            if state.selectedDeviceIndex >= state.project.selectedDevices.count {
                state.selectedDeviceIndex = 0
            }
        } else {
            state.project.selectedDevices.append(device)
        }
        state.hasUnsavedChanges = true
    }
}

private struct LanguageManagerButton: View {
    @Bindable var state: ProjectState
    @State private var showPopover = false

    var body: some View {
        Button {
            showPopover = true
        } label: {
            Image(systemName: "plus.circle")
        }
        .popover(isPresented: $showPopover) {
            languageManagerPopover
        }
    }

    private var languageManagerPopover: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Select Languages")
                .font(.system(size: 13, weight: .semibold))

            ForEach(Language.supportedLanguages) { language in
                let isSelected = state.project.languages.contains(where: { $0.code == language.code })
                Button {
                    toggleLanguage(language)
                } label: {
                    HStack {
                        Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                            .foregroundStyle(isSelected ? .blue : .secondary)
                        Text(language.displayName)
                            .font(.system(size: 12))
                        Spacer()
                        Text(language.code)
                            .font(.system(size: 10, design: .monospaced))
                            .foregroundStyle(.tertiary)
                    }
                }
                .buttonStyle(.plain)
            }
        }
        .padding(12)
        .frame(width: 240)
    }

    private func toggleLanguage(_ language: Language) {
        if let index = state.project.languages.firstIndex(where: { $0.code == language.code }) {
            guard state.project.languages.count > 1 else { return }
            state.project.languages.remove(at: index)
            if state.selectedLanguageIndex >= state.project.languages.count {
                state.selectedLanguageIndex = 0
            }
        } else {
            state.project.languages.append(language)
            // Copy current language text to the new language for all screens
            let sourceCode = state.selectedLanguage?.code ?? "en"
            for i in state.project.screens.indices {
                let sourceText = state.project.screens[i].text(for: sourceCode)
                state.project.screens[i].setText(sourceText, for: language.code)
            }
        }
        state.hasUnsavedChanges = true
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
