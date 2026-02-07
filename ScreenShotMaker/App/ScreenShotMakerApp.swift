import SwiftUI
import UniformTypeIdentifiers

@main
struct ScreenShotMakerApp: App {
    @State private var projectState = ProjectState()

    var body: some Scene {
        WindowGroup {
            ContentView(projectState: projectState)
                .frame(minWidth: 960, minHeight: 600)
        }
        .windowStyle(.titleBar)
        .defaultSize(width: 1280, height: 800)
        .commands {
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
