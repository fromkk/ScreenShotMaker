import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {
  @Bindable var projectState: ProjectState
  @Environment(\.undoManager) private var undoManager
  @State private var showInspector = true
  @State private var columnVisibility: NavigationSplitViewVisibility =
    .doubleColumn

  // File operation callbacks (connected from App level)
  var onNewProject: (() -> Void)?
  var onOpenProject: (() -> Void)?
  var onSaveProject: (() -> Void)?
  var onSaveProjectAs: (() -> Void)?

  var body: some View {
    NavigationSplitView(columnVisibility: $columnVisibility) {
      SidebarView(
        state: projectState,
        onNewProject: onNewProject,
        onOpenProject: onOpenProject,
        onSaveProject: onSaveProject,
        onSaveProjectAs: onSaveProjectAs
      )
      .navigationSplitViewColumnWidth(min: 200, ideal: 240, max: 320)
    } detail: {
      CanvasView(state: projectState)
        .inspector(isPresented: $showInspector) {
          PropertiesPanelView(state: projectState)
            .inspectorColumnWidth(min: 250, ideal: 300, max: 400)
        }
        #if os(iOS)
          .navigationBarTitleDisplayMode(.inline)
        #endif
        .toolbar {
          #if os(iOS)
            if columnVisibility == .detailOnly {
              ToolbarItem(placement: .topBarLeading) {
                Button {
                  withAnimation {
                    columnVisibility = .doubleColumn
                  }
                } label: {
                  Image(systemName: "sidebar.leading")
                }
              }
            }

            ToolbarItemGroup(placement: .primaryAction) {
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
          #else
            ToolbarItemGroup(placement: .primaryAction) {
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
          #endif
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

struct DevicePicker: View {
  @Bindable var state: ProjectState

  var body: some View {
    Picker("Device", selection: $state.selectedDeviceIndex) {
      ForEach(Array(state.project.selectedDevices.enumerated()), id: \.offset) {
        index,
        device in
        Label(device.name, systemImage: device.category.iconName)
          .tag(index)
      }
    }
    .pickerStyle(.menu)
  }
}

struct LanguagePicker: View {
  @Bindable var state: ProjectState

  var body: some View {
    Picker("Language", selection: $state.selectedLanguageIndex) {
      ForEach(Array(state.project.languages.enumerated()), id: \.offset) {
        index,
        language in
        Text(language.displayName)
          .tag(index)
      }
    }
    .pickerStyle(.menu)
  }
}

struct DeviceManagerButton: View {
  @Bindable var state: ProjectState
  @State private var showPopover = false
  @State private var showCustomDeviceDialog = false

  var body: some View {
    Button {
      showPopover = true
    } label: {
      Image(systemName: "plus.circle")
    }
    .popover(isPresented: $showPopover) {
      deviceManagerPopover
    }
    .sheet(isPresented: $showCustomDeviceDialog) {
      CustomDeviceSizeDialog(projectState: state)
    }
  }

  private var deviceManagerPopover: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 12) {
        Text("Select Devices")
          .font(.system(size: 13, weight: .semibold))

        ForEach(DeviceCategory.allCases.filter { $0 != .custom }) { category in
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
                    Image(
                      systemName: isSelected
                        ? "checkmark.circle.fill" : "circle"
                    )
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
        
        // Custom devices section
        if !state.project.customDevices.isEmpty {
          VStack(alignment: .leading, spacing: 4) {
            Text("Custom Sizes")
              .font(.system(size: 11, weight: .medium))
              .foregroundStyle(.secondary)
            
            ForEach(state.project.customDevices) { device in
              let isSelected = state.project.selectedDevices.contains(device)
              HStack(spacing: 4) {
                Button {
                  toggleDevice(device)
                } label: {
                  HStack {
                    Image(
                      systemName: isSelected
                        ? "checkmark.circle.fill" : "circle"
                    )
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
                
                Button {
                  state.removeCustomDevice(device)
                } label: {
                  Image(systemName: "trash")
                    .font(.system(size: 10))
                    .foregroundStyle(.red)
                }
                .buttonStyle(.plain)
              }
            }
          }
        }
        
        // Add custom size button
        Divider()
          .padding(.vertical, 4)
        
        Button {
          showCustomDeviceDialog = true
        } label: {
          Label("Add Custom Size", systemImage: "plus.circle")
            .font(.system(size: 12))
            .foregroundStyle(.blue)
        }
        .buttonStyle(.plain)
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

struct LanguageManagerButton: View {
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
        let isSelected = state.project.languages.contains(where: {
          $0.code == language.code
        })
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
    if let index = state.project.languages.firstIndex(where: {
      $0.code == language.code
    }) {
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

        // Copy screenshot images for all selected devices
        for device in state.project.selectedDevices {
          if let imageData = state.project.screens[i].screenshotImageData(
            for: sourceCode,
            category: device.category
          ) {
            state.project.screens[i].setScreenshotImageData(
              imageData,
              for: language.code,
              category: device.category
            )
          }
        }
      }
    }
    state.hasUnsavedChanges = true
  }
}

private struct ExportButton: View {
  let state: ProjectState
  @State private var showExportError = false
  @State private var exportError: String?
  @State private var showExportFile = false
  @State private var exportDocument: ExportedImageDocument?
  @State private var exportFilename: String = "screen.png"
  @State private var exportContentType: UTType = .png
  @State private var showVideoFolderPicker = false
  @State private var showVideoProgress = false
  @State private var videoProgressState = ExportProgressState()
  #if os(iOS)
    @State private var showSaveSuccess = false
  #endif

  var body: some View {
    #if os(iOS)
      Menu {
        Button {
          exportToPhotos()
        } label: {
          Label("Save to Photos", systemImage: "photo.on.rectangle")
        }
        Button {
          exportToFile()
        } label: {
          Label("Save to Files", systemImage: "folder")
        }
      } label: {
        Label("Export", systemImage: "square.and.arrow.up")
      }
      .disabled(state.selectedScreen == nil || state.selectedDevice == nil)
      .alert("Export Error", isPresented: $showExportError) {
        Button("OK") {}
      } message: {
        Text(exportError ?? "Unknown error")
      }
      .alert("Saved", isPresented: $showSaveSuccess) {
        Button("OK") {}
      } message: {
        Text("Screenshot saved to Photos.")
      }
      .fileExporter(
        isPresented: $showExportFile,
        document: exportDocument,
        contentType: exportContentType,
        defaultFilename: exportFilename
      ) { result in
        if case .failure(let error) = result {
          exportError = error.localizedDescription
          showExportError = true
        }
      }
      .fileImporter(
        isPresented: $showVideoFolderPicker,
        allowedContentTypes: [.folder],
        allowsMultipleSelection: false
      ) { result in
        switch result {
        case .success(let urls):
          if let url = urls.first { exportVideoToFolder(url) }
        case .failure(let error):
          exportError = error.localizedDescription
          showExportError = true
        }
      }
      .sheet(isPresented: $showVideoProgress) {
        ExportProgressView(
          progressState: videoProgressState,
          outputDirectory: nil
        ) {
          showVideoProgress = false
          videoProgressState.reset()
        }
      }
    #else
      Button {
        exportToFile()
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
      .fileExporter(
        isPresented: $showExportFile,
        document: exportDocument,
        contentType: exportContentType,
        defaultFilename: exportFilename
      ) { result in
        if case .failure(let error) = result {
          exportError = error.localizedDescription
          showExportError = true
        }
      }
      .fileImporter(
        isPresented: $showVideoFolderPicker,
        allowedContentTypes: [.folder],
        allowsMultipleSelection: false
      ) { result in
        switch result {
        case .success(let urls):
          if let url = urls.first { exportVideoToFolder(url) }
        case .failure(let error):
          exportError = error.localizedDescription
          showExportError = true
        }
      }
      .sheet(isPresented: $showVideoProgress) {
        ExportProgressView(
          progressState: videoProgressState,
          outputDirectory: nil
        ) {
          showVideoProgress = false
          videoProgressState.reset()
        }
      }
    #endif
  }

  #if os(iOS)
    private func exportToPhotos() {
      guard let screen = state.selectedScreen,
        let device = state.selectedDevice
      else { return }
      let languageCode = state.selectedLanguage?.code ?? "en"

      if screen.hasVideo(for: languageCode, category: device.category) {
        // Export video to temp file, then save to Photos
        let tempURL = FileManager.default.temporaryDirectory
          .appendingPathComponent(screen.name + ".mp4")
        videoProgressState.reset()
        videoProgressState.total = 1
        videoProgressState.isExporting = true
        videoProgressState.currentItem = screen.name
        showVideoProgress = true
      Task {
          do {
            try await VideoExportService.exportVideoScreen(
              screen, device: device, languageCode: languageCode, outputURL: tempURL,
              onFrameProgress: { done, total in
                DispatchQueue.main.async {
                  videoProgressState.currentFrameCompleted = done
                  videoProgressState.currentFrameTotal = total
                }
              })
            videoProgressState.completed = 1
            try await PhotoLibraryService.requestAuthorization()
            try await PhotoLibraryService.saveVideo(at: tempURL)
            // Also save poster frame to Photos
            if let posterData = await VideoExportService.exportPosterFrame(
              screen: screen, device: device, languageCode: languageCode)
            {
              try? await PhotoLibraryService.saveImage(posterData)
            }
            videoProgressState.isExporting = false
            showVideoProgress = false
            showSaveSuccess = true
          } catch {
            videoProgressState.isExporting = false
            showVideoProgress = false
            exportError = error.localizedDescription
            showExportError = true
          }
        }
      } else {
        guard let data = renderCurrentScreen() else { return }
        Task {
          do {
            try await PhotoLibraryService.requestAuthorization()
            try await PhotoLibraryService.saveImage(data)
            showSaveSuccess = true
          } catch {
            exportError = error.localizedDescription
            showExportError = true
          }
        }
      }
    }
  #endif

  private func exportToFile() {
    guard let screen = state.selectedScreen,
      let device = state.selectedDevice
    else { return }
    let languageCode = state.selectedLanguage?.code ?? "en"

    if screen.hasVideo(for: languageCode, category: device.category) {
      showVideoFolderPicker = true
    } else {
      guard let data = renderCurrentScreen() else { return }
      exportDocument = ExportedImageDocument(data: data)
      exportFilename = screen.name + ".png"
      exportContentType = .png
      showExportFile = true
    }
  }

  private func exportVideoToFolder(_ folderURL: URL) {
    guard let screen = state.selectedScreen,
      let device = state.selectedDevice
    else { return }
    let languageCode = state.selectedLanguage?.code ?? "en"
    let accessing = folderURL.startAccessingSecurityScopedResource()
    videoProgressState.reset()
    videoProgressState.total = 1
    videoProgressState.isExporting = true
    videoProgressState.currentItem = screen.name
    showVideoProgress = true
    Task {
      defer { if accessing { folderURL.stopAccessingSecurityScopedResource() } }
      do {
        let videoOutURL = folderURL.appendingPathComponent("\(screen.name).mp4")
        try await VideoExportService.exportVideoScreen(
          screen, device: device, languageCode: languageCode, outputURL: videoOutURL,
          onFrameProgress: { done, total in
            DispatchQueue.main.async {
              videoProgressState.currentFrameCompleted = done
              videoProgressState.currentFrameTotal = total
            }
          })
        videoProgressState.resetFrameProgress()
        if let posterData = await VideoExportService.exportPosterFrame(
          screen: screen, device: device, languageCode: languageCode)
        {
          let posterURL = folderURL.appendingPathComponent("\(screen.name)_poster.png")
          try posterData.write(to: posterURL, options: .atomic)
        }
        videoProgressState.completed = 1
        videoProgressState.isExporting = false
        showVideoProgress = false
      } catch {
        videoProgressState.isExporting = false
        showVideoProgress = false
        exportError = error.localizedDescription
        showExportError = true
      }
    }
  }

  private func renderCurrentScreen() -> Data? {
    guard let screen = state.selectedScreen,
      let device = state.selectedDevice
    else { return nil }

    let format: ExportFormat = .png
    let languageCode = state.selectedLanguage?.code ?? "en"
    guard
      let data = ExportService.exportScreen(
        screen,
        device: device,
        format: format,
        languageCode: languageCode
      )
    else {
      exportError = "Failed to render the screen."
      showExportError = true
      return nil
    }
    return data
  }
}

/// FileDocument wrapper for exported images
struct ExportedImageDocument: FileDocument {
  static var readableContentTypes: [UTType] { [.png, .jpeg, .mpeg4Movie, .quickTimeMovie] }

  var data: Data

  init(data: Data) {
    self.data = data
  }

  init(configuration: ReadConfiguration) throws {
    data = configuration.file.regularFileContents ?? Data()
  }

  func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
    FileWrapper(regularFileWithContents: data)
  }
}

private struct BatchExportButton: View {
  let state: ProjectState
  @State private var showBatchExport = false
  @State private var progressState = ExportProgressState()
  @State private var outputDirectory: URL?
  @State private var exportTask: Task<Void, Never>?
  @State private var showFolderPicker = false
  #if os(iOS)
    @State private var showExportError = false
    @State private var exportError: String?
  #endif

  var body: some View {
    #if os(iOS)
      Menu {
        Button {
          showFolderPicker = true
        } label: {
          Label("Save to Files", systemImage: "folder")
        }
      } label: {
        Label("Export All", systemImage: "square.and.arrow.up.on.square")
      }
      .disabled(state.project.screens.isEmpty)
      .alert("Export Error", isPresented: $showExportError) {
        Button("OK") {}
      } message: {
        Text(exportError ?? "Unknown error")
      }
      .fileImporter(
        isPresented: $showFolderPicker,
        allowedContentTypes: [.folder],
        allowsMultipleSelection: false
      ) { result in
        switch result {
        case .success(let urls):
          if let url = urls.first {
            startBatchExport(to: url)
          }
        case .failure:
          break
        }
      }
      .sheet(isPresented: $showBatchExport) {
        ExportProgressView(
          progressState: progressState,
          outputDirectory: outputDirectory
        ) {
          showBatchExport = false
          progressState.reset()
        }
      }
    #else
      Button {
        showFolderPicker = true
      } label: {
        Label("Export All", systemImage: "square.and.arrow.up.on.square")
      }
      .disabled(state.project.screens.isEmpty)
      .fileImporter(
        isPresented: $showFolderPicker,
        allowedContentTypes: [.folder],
        allowsMultipleSelection: false
      ) { result in
        switch result {
        case .success(let urls):
          if let url = urls.first {
            startBatchExport(to: url)
          }
        case .failure:
          break
        }
      }
      .sheet(isPresented: $showBatchExport) {
        ExportProgressView(
          progressState: progressState,
          outputDirectory: outputDirectory
        ) {
          showBatchExport = false
          progressState.reset()
        }
      }
    #endif
  }

  private func startBatchExport(to url: URL) {
    let accessing = url.startAccessingSecurityScopedResource()
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
      if accessing {
        url.stopAccessingSecurityScopedResource()
      }
    }
  }
}

#Preview {
  ContentView(projectState: ProjectState())
    .frame(width: 1200, height: 800)
}
