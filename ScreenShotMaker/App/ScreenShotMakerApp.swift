import SwiftUI
import UniformTypeIdentifiers

@main
struct ScreenShotMakerApp: App {
  @State private var projectState = ProjectState()
  @State private var showTemplateGallery = false
  @AppStorage("showTemplateOnLaunch") private var showTemplateOnLaunch = true

  // File dialog states
  @State private var showOpenProject = false
  @State private var showSaveProject = false
  @State private var projectDocument: ProjectFileDocument?

  // Unsaved changes confirmation
  @State private var showUnsavedChangesDialog = false
  @State private var pendingAction: (() -> Void)?

  // Error alert
  @State private var showError = false
  @State private var errorTitle = ""
  @State private var errorMessage = ""

  // onOpenURL state
  @State private var pendingOpenURL: URL?
  @State private var showOpenURLConfirmation = false

  var body: some Scene {
    WindowGroup {
      ContentView(
        projectState: projectState,
        onNewProject: { newProject() },
        onOpenProject: { openProject() },
        onSaveProject: { saveProject() },
        onSaveProjectAs: { saveProjectAs() }
      )
      #if os(macOS)
        .frame(minWidth: 960, minHeight: 600)
      #endif
      .sheet(isPresented: $showTemplateGallery) {
        TemplateGalleryView(state: projectState)
      }
      .onAppear {
        if let url = projectState.restoreBookmarkedURL() {
          let accessing = url.startAccessingSecurityScopedResource()
          defer { if accessing { url.stopAccessingSecurityScopedResource() } }
          do {
            let project = try ProjectFileService.loadPackageFromURL(url)
            projectState.project = project
            projectState.selectedScreenID = project.screens.first?.id
            projectState.selectedDeviceIndex = 0
            projectState.selectedLanguageIndex = 0
            projectState.currentFileURL = url
            projectState.hasUnsavedChanges = false
          } catch {
            // Bookmark is invalid, show template gallery
            UserDefaults.standard.removeObject(forKey: "lastProjectBookmark")
            if showTemplateOnLaunch {
              showTemplateGallery = true
            }
          }
        } else if showTemplateOnLaunch {
          showTemplateGallery = true
        }
      }
      .fileImporter(
        isPresented: $showOpenProject,
        allowedContentTypes: [.shotcraftProject],
        allowsMultipleSelection: false
      ) { result in
        switch result {
        case .success(let urls):
          if let url = urls.first {
            loadProject(from: url)
          }
        case .failure(let error):
          presentError(title: "Failed to Open Project", message: error.localizedDescription)
        }
      }
      .fileExporter(
        isPresented: $showSaveProject,
        document: projectDocument,
        contentType: .shotcraftProject,
        defaultFilename: projectState.project.name + ".shotcraft"
      ) { result in
        switch result {
        case .success(let url):
          projectState.currentFileURL = url
          projectState.hasUnsavedChanges = false
          #if os(macOS)
            NSDocumentController.shared.noteNewRecentDocumentURL(url)
          #endif
        case .failure(let error):
          presentError(title: "Failed to Save Project", message: error.localizedDescription)
        }
      }
      .confirmationDialog(
        "Do you want to save the current project?",
        isPresented: $showUnsavedChangesDialog,
        titleVisibility: .visible
      ) {
        Button("Save") {
          saveProject()
          pendingAction?()
          pendingAction = nil
        }
        Button("Don't Save", role: .destructive) {
          pendingAction?()
          pendingAction = nil
        }
        Button("Cancel", role: .cancel) {
          pendingAction = nil
        }
      } message: {
        Text("Your changes will be lost if you don't save them.")
      }
      .alert(errorTitle, isPresented: $showError) {
        Button("OK", role: .cancel) {}
      } message: {
        Text(errorMessage)
      }
      .onOpenURL { url in
        handleOpenURL(url)
      }
      .confirmationDialog(
        "Do you want to save the current project before opening another?",
        isPresented: $showOpenURLConfirmation,
        titleVisibility: .visible
      ) {
        Button("Save") {
          saveProject()
          if let url = pendingOpenURL {
            loadProject(from: url)
          }
          pendingOpenURL = nil
        }
        Button("Don't Save", role: .destructive) {
          if let url = pendingOpenURL {
            loadProject(from: url)
          }
          pendingOpenURL = nil
        }
        Button("Cancel", role: .cancel) {
          pendingOpenURL = nil
        }
      } message: {
        Text("Your changes will be lost if you don't save them.")
      }
    }
    #if os(macOS)
      .windowStyle(.titleBar)
      .defaultSize(width: 1280, height: 800)
    #endif
    .commands {
      CommandGroup(after: .newItem) {
        Button("New from Template...") {
          showTemplateGallery = true
        }
        .keyboardShortcut("n", modifiers: [.command, .shift])

        Divider()

        Button("Open...") {
          openProject()
        }
        .keyboardShortcut("o", modifiers: .command)
      }
      CommandGroup(after: .toolbar) {
        Button("Zoom In") {
          projectState.zoomIn()
        }
        .keyboardShortcut("+", modifiers: .command)

        Button("Zoom Out") {
          projectState.zoomOut()
        }
        .keyboardShortcut("-", modifiers: .command)

        Button("Actual Size") {
          projectState.zoomReset()
        }
        .keyboardShortcut("0", modifiers: .command)
      }
      CommandGroup(replacing: .saveItem) {
        Button("Save") {
          saveProject()
        }
        .keyboardShortcut("s", modifiers: .command)

        Button("Save As...") {
          saveProjectAs()
        }
        .keyboardShortcut("s", modifiers: [.command, .shift])
      }
    }
  }

  private func newProject() {
    if projectState.hasUnsavedChanges {
      pendingAction = { resetToNewProject() }
      showUnsavedChangesDialog = true
    } else {
      resetToNewProject()
    }
  }

  private func resetToNewProject() {
    projectState.project = ScreenShotProject()
    projectState.selectedScreenID = projectState.project.screens.first?.id
    projectState.selectedDeviceIndex = 0
    projectState.selectedLanguageIndex = 0
    projectState.currentFileURL = nil
    projectState.hasUnsavedChanges = false
  }

  private func openProject() {
    if projectState.hasUnsavedChanges {
      pendingAction = { showOpenProject = true }
      showUnsavedChangesDialog = true
    } else {
      showOpenProject = true
    }
  }

  private func loadProject(from url: URL) {
    let accessing = url.startAccessingSecurityScopedResource()
    defer { if accessing { url.stopAccessingSecurityScopedResource() } }
    do {
      let project = try ProjectFileService.loadPackageFromURL(url)
      projectState.project = project
      projectState.selectedScreenID = project.screens.first?.id
      projectState.selectedDeviceIndex = 0
      projectState.selectedLanguageIndex = 0
      projectState.currentFileURL = url
      projectState.hasUnsavedChanges = false
      #if os(macOS)
        NSDocumentController.shared.noteNewRecentDocumentURL(url)
      #endif
    } catch {
      presentError(title: "Failed to Open Project", message: error.localizedDescription)
    }
  }

  private func saveProject() {
    if let url = projectState.currentFileURL {
      let accessing = url.startAccessingSecurityScopedResource()
      defer { if accessing { url.stopAccessingSecurityScopedResource() } }
      do {
        try ProjectFileService.savePackageToURL(projectState.project, to: url)
        projectState.hasUnsavedChanges = false
      } catch {
        presentError(title: "Failed to Save Project", message: error.localizedDescription)
      }
    } else {
      saveProjectAs()
    }
  }

  private func saveProjectAs() {
    projectDocument = ProjectFileDocument(project: projectState.project)
    showSaveProject = true
  }

  private func presentError(title: String, message: String) {
    errorTitle = title
    errorMessage = message
    showError = true
  }

  private func handleOpenURL(_ url: URL) {
    if projectState.hasUnsavedChanges {
      pendingOpenURL = url
      showOpenURLConfirmation = true
    } else {
      loadProject(from: url)
    }
  }
}

// MARK: - FileDocument wrapper for project files

struct ProjectFileDocument: FileDocument {
  static var readableContentTypes: [UTType] {
    [.shotcraftProject]
  }

  var project: ScreenShotProject

  init(project: ScreenShotProject) {
    self.project = project
  }

  init(configuration: ReadConfiguration) throws {
    project = try ProjectFileService.loadPackage(from: configuration.file)
  }

  func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
    try ProjectFileService.savePackage(project)
  }
}
