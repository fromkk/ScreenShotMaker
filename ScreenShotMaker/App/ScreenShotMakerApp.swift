import SwiftUI
import UniformTypeIdentifiers

@main
struct ScreenShotMakerApp: App {
    @State private var projectState = ProjectState()
    @State private var showTemplateGallery = false

    var body: some Scene {
        WindowGroup {
            ContentView(projectState: projectState)
                .frame(minWidth: 960, minHeight: 600)
                .sheet(isPresented: $showTemplateGallery) {
                    TemplateGalleryView(state: projectState)
                }
                .onAppear {
                    showTemplateGallery = true
                }
        }
        .windowStyle(.titleBar)
        .defaultSize(width: 1280, height: 800)
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
            CommandMenu("View") {
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

    private func openProject() {
        if projectState.hasUnsavedChanges {
            let alert = NSAlert()
            alert.messageText = "Do you want to save the current project?"
            alert.informativeText = "Your changes will be lost if you don't save them."
            alert.alertStyle = .warning
            alert.addButton(withTitle: "Save")
            alert.addButton(withTitle: "Don't Save")
            alert.addButton(withTitle: "Cancel")

            let response = alert.runModal()
            switch response {
            case .alertFirstButtonReturn:
                saveProject()
            case .alertThirdButtonReturn:
                return
            default:
                break
            }
        }

        let panel = NSOpenPanel()
        panel.allowedContentTypes = [UTType(filenameExtension: "ssmaker")!]
        panel.allowsMultipleSelection = false

        if panel.runModal() == .OK, let url = panel.url {
            loadProject(from: url)
        }
    }

    private func loadProject(from url: URL) {
        do {
            let project = try ProjectFileService.load(from: url)
            projectState.project = project
            projectState.selectedScreenID = project.screens.first?.id
            projectState.selectedDeviceIndex = 0
            projectState.selectedLanguageIndex = 0
            projectState.currentFileURL = url
            projectState.hasUnsavedChanges = false
            NSDocumentController.shared.noteNewRecentDocumentURL(url)
        } catch {
            let alert = NSAlert()
            alert.messageText = "Failed to Open Project"
            alert.informativeText = error.localizedDescription
            alert.alertStyle = .warning
            alert.addButton(withTitle: "OK")
            alert.runModal()
        }
    }

    private func saveProject() {
        if let url = projectState.currentFileURL {
            do {
                try ProjectFileService.save(projectState.project, to: url)
                projectState.hasUnsavedChanges = false
            } catch {
                presentSaveError(error)
            }
        } else {
            saveProjectAs()
        }
    }

    private func saveProjectAs() {
        let panel = NSSavePanel()
        panel.allowedContentTypes = [UTType(filenameExtension: "ssmaker")!]
        panel.nameFieldStringValue = projectState.project.name + ".ssmaker"
        panel.canCreateDirectories = true

        if panel.runModal() == .OK, let url = panel.url {
            do {
                try ProjectFileService.save(projectState.project, to: url)
                projectState.currentFileURL = url
                projectState.hasUnsavedChanges = false
                NSDocumentController.shared.noteNewRecentDocumentURL(url)
            } catch {
                presentSaveError(error)
            }
        }
    }

    private func presentSaveError(_ error: Error) {
        let alert = NSAlert()
        alert.messageText = "Failed to Save Project"
        alert.informativeText = error.localizedDescription
        alert.alertStyle = .warning
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }
}
