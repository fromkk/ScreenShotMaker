import Foundation
import Observation
import SwiftUI

struct ScreenShotProject: Codable {
  var name: String
  var screens: [Screen]
  var selectedDevices: [DeviceSize]
  var languages: [Language]
  var customDevices: [DeviceSize] = []

  init(
    name: String = "Untitled Project",
    screens: [Screen] = [
      Screen(name: "Screen 1", title: "Your App Title", subtitle: "A brief description")
    ],
    selectedDevices: [DeviceSize] = [
      DeviceSize.iPhoneSizes[0], DeviceSize.iPhoneSizes[2], DeviceSize.iPadSizes[0],
    ],
    languages: [Language] = [Language(code: "en", displayName: "English")],
    customDevices: [DeviceSize] = []
  ) {
    self.name = name
    self.screens = screens
    self.selectedDevices = selectedDevices
    self.languages = languages
    self.customDevices = customDevices
  }
  
  // Custom decoder for backward compatibility
  init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    name = try container.decode(String.self, forKey: .name)
    screens = try container.decode([Screen].self, forKey: .screens)
    selectedDevices = try container.decode([DeviceSize].self, forKey: .selectedDevices)
    languages = try container.decode([Language].self, forKey: .languages)
    // Default to empty array if customDevices is not present (backward compatibility)
    customDevices = try container.decodeIfPresent([DeviceSize].self, forKey: .customDevices) ?? []
  }
  
  private enum CodingKeys: String, CodingKey {
    case name, screens, selectedDevices, languages, customDevices
  }
}

struct Language: Codable, Identifiable, Hashable {
  var id: String { code }
  let code: String
  let displayName: LocalizedStringResource

  static func == (lhs: Language, rhs: Language) -> Bool {
    lhs.code == rhs.code
  }

  func hash(into hasher: inout Hasher) {
    hasher.combine(code)
  }
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
  var currentFileURL: URL? {
    didSet {
      if let url = currentFileURL {
        saveBookmark(for: url)
      } else {
        UserDefaults.standard.removeObject(forKey: Self.bookmarkKey)
      }
    }
  }
  var hasUnsavedChanges: Bool = false
  var undoManager: UndoManager?
  var zoomScale: Double = 1.0
  var copiedScreen: Screen?

  private static let bookmarkKey = "lastProjectBookmark"

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
      guard let newValue, let index = project.screens.firstIndex(where: { $0.id == newValue.id })
      else { return }
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
    let previousScreen = selectedScreen ?? project.screens.last
    var screen: Screen
    if let prev = previousScreen {
      screen = Screen(
        name: "Screen \(count)",
        layoutPreset: prev.layoutPreset,
        background: prev.background,
        showDeviceFrame: prev.showDeviceFrame,
        isLandscape: prev.isLandscape,
        fontFamily: prev.fontFamily,
        textColorHex: prev.textColorHex,
        titleStyle: prev.titleStyle,
        subtitleStyle: prev.subtitleStyle,
        deviceFrameConfig: prev.deviceFrameConfig,
        screenshotContentMode: prev.screenshotContentMode
      )
      screen.fontSizes = prev.fontSizes
    } else {
      screen = Screen(name: "Screen \(count)")
    }
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

  func duplicateScreen(_ screen: Screen) {
    guard let index = project.screens.firstIndex(where: { $0.id == screen.id }) else { return }
    var newScreen = screen
    newScreen.id = UUID()
    newScreen.name = screen.name + " Copy"
    project.screens.insert(newScreen, at: index + 1)
    selectedScreenID = newScreen.id
    hasUnsavedChanges = true

    undoManager?.registerUndo(withTarget: self) { state in
      state.project.screens.removeAll { $0.id == newScreen.id }
      if state.selectedScreenID == newScreen.id {
        state.selectedScreenID = screen.id
      }
      state.hasUnsavedChanges = true
    }
    undoManager?.setActionName("Duplicate Screen")
  }

  func copyScreen(_ screen: Screen) {
    copiedScreen = screen
  }

  func pasteScreen() {
    guard let source = copiedScreen else { return }
    var newScreen = source
    newScreen.id = UUID()
    newScreen.name = source.name + " Copy"
    project.screens.append(newScreen)
    selectedScreenID = newScreen.id
    hasUnsavedChanges = true

    undoManager?.registerUndo(withTarget: self) { state in
      state.project.screens.removeAll { $0.id == newScreen.id }
      if state.selectedScreenID == newScreen.id {
        state.selectedScreenID = state.project.screens.first?.id
      }
      state.hasUnsavedChanges = true
    }
    undoManager?.setActionName("Paste Screen")
  }

  // MARK: - Security-Scoped Bookmark Persistence

  private func saveBookmark(for url: URL) {
    do {
      #if os(macOS)
        let options: URL.BookmarkCreationOptions = [.withSecurityScope]
      #else
        let options: URL.BookmarkCreationOptions = []
      #endif
      let bookmarkData = try url.bookmarkData(
        options: options,
        includingResourceValuesForKeys: nil,
        relativeTo: nil
      )
      UserDefaults.standard.set(bookmarkData, forKey: Self.bookmarkKey)
    } catch {
      // Silently fail — bookmark saving is best-effort
      print("Failed to save bookmark: \(error)")
    }
  }

  func addCustomDevice(name: String, width: Int, height: Int) {
    let customDevice = DeviceSize.custom(name: name, width: width, height: height)
    project.customDevices.append(customDevice)
    project.selectedDevices.append(customDevice)
    hasUnsavedChanges = true
    
    undoManager?.registerUndo(withTarget: self) { state in
      state.project.customDevices.removeAll { $0.id == customDevice.id }
      state.project.selectedDevices.removeAll { $0.id == customDevice.id }
      state.hasUnsavedChanges = true
    }
    undoManager?.setActionName("Add Custom Device")
  }
  
  func removeCustomDevice(_ device: DeviceSize) {
    let customDeviceIndex = project.customDevices.firstIndex(where: { $0.id == device.id })
    let wasSelected = project.selectedDevices.contains(where: { $0.id == device.id })
    
    project.customDevices.removeAll { $0.id == device.id }
    project.selectedDevices.removeAll { $0.id == device.id }
    hasUnsavedChanges = true
    
    undoManager?.registerUndo(withTarget: self) { state in
      if let idx = customDeviceIndex {
        state.project.customDevices.insert(device, at: idx)
      } else {
        state.project.customDevices.append(device)
      }
      if wasSelected {
        state.project.selectedDevices.append(device)
      }
      state.hasUnsavedChanges = true
    }
    undoManager?.setActionName("Remove Custom Device")
  }

  func restoreBookmarkedURL() -> URL? {
    guard let bookmarkData = UserDefaults.standard.data(forKey: Self.bookmarkKey) else {
      return nil
    }
    do {
      var isStale = false
      #if os(macOS)
        let url = try URL(
          resolvingBookmarkData: bookmarkData,
          options: [.withSecurityScope],
          relativeTo: nil,
          bookmarkDataIsStale: &isStale
        )
      #else
        let url = try URL(
          resolvingBookmarkData: bookmarkData,
          relativeTo: nil,
          bookmarkDataIsStale: &isStale
        )
      #endif
      if isStale {
        saveBookmark(for: url)
      }
      return url
    } catch {
      print("Failed to restore bookmark: \(error)")
      UserDefaults.standard.removeObject(forKey: Self.bookmarkKey)
      return nil
    }
  }
}
