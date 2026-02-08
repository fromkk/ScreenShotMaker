import Foundation
import SwiftUI
import Observation

struct ScreenShotProject: Codable {
    var name: String
    var screens: [Screen]
    var selectedDevices: [DeviceSize]
    var languages: [Language]

    init(
        name: String = "Untitled Project",
        screens: [Screen] = [Screen(name: "Screen 1", title: "Your App Title", subtitle: "A brief description")],
        selectedDevices: [DeviceSize] = [DeviceSize.iPhoneSizes[0], DeviceSize.iPhoneSizes[2], DeviceSize.iPadSizes[0]],
        languages: [Language] = [Language(code: "en", displayName: "English")]
    ) {
        self.name = name
        self.screens = screens
        self.selectedDevices = selectedDevices
        self.languages = languages
    }
}

struct Language: Codable, Identifiable, Hashable {
    var id: String { code }
    let code: String
    let displayName: String
}

extension Language {
    static let supportedLanguages: [Language] = [
        Language(code: "en", displayName: "English"),
        Language(code: "ja", displayName: "Japanese"),
        Language(code: "zh-Hans", displayName: "Chinese (Simplified)"),
        Language(code: "zh-Hant", displayName: "Chinese (Traditional)"),
        Language(code: "ko", displayName: "Korean"),
        Language(code: "fr", displayName: "French"),
        Language(code: "de", displayName: "German"),
        Language(code: "es", displayName: "Spanish"),
        Language(code: "pt-BR", displayName: "Portuguese (Brazil)"),
        Language(code: "it", displayName: "Italian"),
        Language(code: "nl", displayName: "Dutch"),
        Language(code: "ru", displayName: "Russian"),
        Language(code: "ar", displayName: "Arabic"),
        Language(code: "th", displayName: "Thai"),
        Language(code: "vi", displayName: "Vietnamese"),
    ]
}

@MainActor @Observable
final class ProjectState {
    var project: ScreenShotProject
    var selectedScreenID: UUID?
    var selectedDeviceIndex: Int = 0
    var selectedLanguageIndex: Int = 0
    var currentFileURL: URL?
    var hasUnsavedChanges: Bool = false
    var undoManager: UndoManager?
    var zoomScale: Double = 0.5

    func zoomIn() {
        withAnimation(.easeInOut(duration: 0.15)) {
            zoomScale = min(3.0, zoomScale + 0.1)
        }
    }

    func zoomOut() {
        withAnimation(.easeInOut(duration: 0.15)) {
            zoomScale = max(0.1, zoomScale - 0.1)
        }
    }

    func zoomReset() {
        withAnimation(.easeInOut(duration: 0.2)) {
            zoomScale = 1.0
        }
    }

    var selectedScreen: Screen? {
        get {
            guard let id = selectedScreenID else { return project.screens.first }
            return project.screens.first { $0.id == id }
        }
        set {
            guard let newValue, let index = project.screens.firstIndex(where: { $0.id == newValue.id }) else { return }
            project.screens[index] = newValue
        }
    }

    var selectedDevice: DeviceSize? {
        guard selectedDeviceIndex < project.selectedDevices.count else { return nil }
        return project.selectedDevices[selectedDeviceIndex]
    }

    var selectedLanguage: Language? {
        guard selectedLanguageIndex < project.languages.count else { return nil }
        return project.languages[selectedLanguageIndex]
    }

    init(project: ScreenShotProject = ScreenShotProject()) {
        self.project = project
        self.selectedScreenID = project.screens.first?.id
    }

    func addScreen() {
        let count = project.screens.count + 1
        let screen = Screen(name: "Screen \(count)", title: "Title", subtitle: "Subtitle")
        project.screens.append(screen)
        selectedScreenID = screen.id
        hasUnsavedChanges = true

        undoManager?.registerUndo(withTarget: self) { state in
            state.project.screens.removeAll { $0.id == screen.id }
            if state.selectedScreenID == screen.id {
                state.selectedScreenID = state.project.screens.first?.id
            }
            state.hasUnsavedChanges = true
        }
        undoManager?.setActionName("Add Screen")
    }

    func deleteScreen(_ screen: Screen) {
        guard let index = project.screens.firstIndex(where: { $0.id == screen.id }) else { return }
        let oldScreen = project.screens[index]
        let oldIndex = index
        let oldSelectedID = selectedScreenID

        project.screens.remove(at: index)
        if selectedScreenID == screen.id {
            selectedScreenID = project.screens.first?.id
        }
        hasUnsavedChanges = true

        undoManager?.registerUndo(withTarget: self) { state in
            let insertAt = min(oldIndex, state.project.screens.count)
            state.project.screens.insert(oldScreen, at: insertAt)
            state.selectedScreenID = oldSelectedID
            state.hasUnsavedChanges = true
        }
        undoManager?.setActionName("Delete Screen")
    }

    func moveScreen(from source: IndexSet, to destination: Int) {
        let oldScreens = project.screens
        project.screens.move(fromOffsets: source, toOffset: destination)
        hasUnsavedChanges = true

        undoManager?.registerUndo(withTarget: self) { state in
            state.project.screens = oldScreens
            state.hasUnsavedChanges = true
        }
        undoManager?.setActionName("Move Screen")
    }

    func updateScreen(_ screen: Screen, actionName: String = "Edit Screen") {
        guard let index = project.screens.firstIndex(where: { $0.id == screen.id }) else { return }
        let oldScreen = project.screens[index]
        project.screens[index] = screen
        hasUnsavedChanges = true

        undoManager?.registerUndo(withTarget: self) { state in
            if let idx = state.project.screens.firstIndex(where: { $0.id == oldScreen.id }) {
                state.project.screens[idx] = oldScreen
                state.hasUnsavedChanges = true
            }
        }
        undoManager?.setActionName(actionName)
    }
}
