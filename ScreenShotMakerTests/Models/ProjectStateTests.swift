import Foundation
import Testing

@testable import ScreenShotMaker

@Suite("ProjectState Tests")
@MainActor
struct ProjectStateTests {

  @Test("Initial state has one screen selected")
  func testInitialState() {
    let state = ProjectState()
    #expect(state.project.screens.count == 1)
    #expect(state.selectedScreenID == state.project.screens.first?.id)
  }

  @Test("addScreen increases count and selects new screen")
  func testAddScreen() {
    let state = ProjectState()
    let initialCount = state.project.screens.count

    state.addScreen()

    #expect(state.project.screens.count == initialCount + 1)
    #expect(state.selectedScreenID == state.project.screens.last?.id)
  }

  @Test("deleteScreen removes screen from project")
  func testDeleteScreen() {
    let state = ProjectState()
    state.addScreen()
    let screenToDelete = state.project.screens.last!
    let countBefore = state.project.screens.count

    state.deleteScreen(screenToDelete)

    #expect(state.project.screens.count == countBefore - 1)
    #expect(!state.project.screens.contains(where: { $0.id == screenToDelete.id }))
  }

  @Test("Deleting selected screen switches selection to first")
  func testDeleteSelectedScreen() {
    let state = ProjectState()
    state.addScreen()
    let selectedScreen = state.project.screens.last!
    state.selectedScreenID = selectedScreen.id

    state.deleteScreen(selectedScreen)

    #expect(state.selectedScreenID == state.project.screens.first?.id)
  }

  @Test("Deleting last screen sets selectedScreenID to nil")
  func testDeleteLastScreen() {
    let state = ProjectState()
    let onlyScreen = state.project.screens.first!

    state.deleteScreen(onlyScreen)

    #expect(state.project.screens.isEmpty)
    #expect(state.selectedScreenID == nil)
  }

  @Test("moveScreen reorders screens")
  func testMoveScreen() {
    let state = ProjectState()
    state.addScreen()
    state.addScreen()
    let firstID = state.project.screens[0].id
    let secondID = state.project.screens[1].id

    state.moveScreen(from: IndexSet(integer: 0), to: 2)

    #expect(state.project.screens[0].id == secondID)
    #expect(state.project.screens[1].id == firstID)
  }

  @Test("selectedScreen returns correct screen for ID")
  func testSelectedScreenComputed() {
    let state = ProjectState()
    state.addScreen()
    let targetScreen = state.project.screens.last!
    state.selectedScreenID = targetScreen.id

    #expect(state.selectedScreen?.id == targetScreen.id)
  }

  @Test("selectedScreen returns first when ID is nil")
  func testSelectedScreenNil() {
    let state = ProjectState()
    state.selectedScreenID = nil

    #expect(state.selectedScreen?.id == state.project.screens.first?.id)
  }

  @Test("selectedDevice returns correct device for index")
  func testSelectedDeviceComputed() {
    let state = ProjectState()
    state.selectedDeviceIndex = 0

    #expect(state.selectedDevice != nil)
    #expect(state.selectedDevice?.name == state.project.selectedDevices[0].name)
  }

  @Test("selectedDevice returns nil for out-of-bounds index")
  func testSelectedDeviceOutOfBounds() {
    let state = ProjectState()
    state.selectedDeviceIndex = 999

    #expect(state.selectedDevice == nil)
  }

  @Test("selectedLanguage returns correct language for index")
  func testSelectedLanguageComputed() {
    let state = ProjectState()
    state.selectedLanguageIndex = 0

    #expect(state.selectedLanguage != nil)
    #expect(state.selectedLanguage?.code == state.project.languages[0].code)
  }

  // MARK: - Undo/Redo Tests

  @Test("addScreen undo restores previous state")
  func testAddScreenUndo() {
    let state = ProjectState()
    let undoManager = UndoManager()
    state.undoManager = undoManager
    let initialCount = state.project.screens.count

    state.addScreen()
    #expect(state.project.screens.count == initialCount + 1)

    undoManager.undo()
    #expect(state.project.screens.count == initialCount)
  }

  @Test("deleteScreen undo restores deleted screen")
  func testDeleteScreenUndo() {
    let state = ProjectState()
    let undoManager = UndoManager()
    undoManager.groupsByEvent = false
    state.undoManager = undoManager

    undoManager.beginUndoGrouping()
    state.addScreen()
    undoManager.endUndoGrouping()

    let addedScreen = state.project.screens.last!
    let countBeforeDelete = state.project.screens.count

    undoManager.beginUndoGrouping()
    state.deleteScreen(addedScreen)
    undoManager.endUndoGrouping()
    #expect(state.project.screens.count == countBeforeDelete - 1)

    undoManager.undo()
    #expect(state.project.screens.count == countBeforeDelete)
    #expect(state.project.screens.contains(where: { $0.id == addedScreen.id }))
  }

  @Test("moveScreen undo restores original order")
  func testMoveScreenUndo() {
    let state = ProjectState()
    let undoManager = UndoManager()
    undoManager.groupsByEvent = false
    state.undoManager = undoManager

    undoManager.beginUndoGrouping()
    state.addScreen()
    undoManager.endUndoGrouping()

    undoManager.beginUndoGrouping()
    state.addScreen()
    undoManager.endUndoGrouping()

    let originalOrder = state.project.screens.map(\.id)

    undoManager.beginUndoGrouping()
    state.moveScreen(from: IndexSet(integer: 0), to: 2)
    undoManager.endUndoGrouping()
    #expect(state.project.screens[0].id != originalOrder[0])

    undoManager.undo()
    #expect(state.project.screens.map(\.id) == originalOrder)
  }

  @Test("updateScreen undo restores original screen")
  func testUpdateScreenUndo() {
    let state = ProjectState()
    let undoManager = UndoManager()
    state.undoManager = undoManager

    var screen = state.project.screens[0]
    let originalName = screen.name
    screen.name = "Updated Name"

    state.updateScreen(screen, actionName: "Rename")
    #expect(state.project.screens[0].name == "Updated Name")

    undoManager.undo()
    #expect(state.project.screens[0].name == originalName)
  }

  // MARK: - Duplicate Screen Tests (#032)

  @Test("duplicateScreen creates copy after original")
  func testDuplicateScreen() {
    let state = ProjectState()
    let original = state.project.screens[0]
    let countBefore = state.project.screens.count

    state.duplicateScreen(original)

    #expect(state.project.screens.count == countBefore + 1)
    let duplicated = state.project.screens[1]
    #expect(duplicated.id != original.id)
    #expect(duplicated.name == original.name + " Copy")
    #expect(duplicated.layoutPreset == original.layoutPreset)
    #expect(duplicated.background == original.background)
    #expect(duplicated.fontFamily == original.fontFamily)
    #expect(duplicated.fontSize == original.fontSize)
    #expect(duplicated.textColorHex == original.textColorHex)
    #expect(duplicated.showDeviceFrame == original.showDeviceFrame)
    #expect(duplicated.isLandscape == original.isLandscape)
    #expect(duplicated.deviceFrameConfig == original.deviceFrameConfig)
    #expect(duplicated.screenshotContentMode == original.screenshotContentMode)
    #expect(state.selectedScreenID == duplicated.id)
  }

  @Test("duplicateScreen inserts at correct position")
  func testDuplicateScreenPosition() {
    let state = ProjectState()
    state.addScreen()
    state.addScreen()
    // 3 screens: [0, 1, 2]
    let middle = state.project.screens[1]

    state.duplicateScreen(middle)

    // Should be [0, 1, 1-copy, 2]
    #expect(state.project.screens.count == 4)
    #expect(state.project.screens[2].name == middle.name + " Copy")
  }

  @Test("duplicateScreen preserves localized texts")
  func testDuplicateScreenLocalizedTexts() {
    let state = ProjectState()
    var screen = state.project.screens[0]
    screen.setText(LocalizedText(title: "Hello", subtitle: "World"), for: "en")
    screen.setText(LocalizedText(title: "こんにちは", subtitle: "世界"), for: "ja")
    state.updateScreen(screen)

    state.duplicateScreen(state.project.screens[0])

    let duplicated = state.project.screens[1]
    #expect(duplicated.text(for: "en").title == "Hello")
    #expect(duplicated.text(for: "ja").title == "こんにちは")
  }

  @Test("duplicateScreen undo removes duplicated screen")
  func testDuplicateScreenUndo() {
    let state = ProjectState()
    let undoManager = UndoManager()
    undoManager.groupsByEvent = false
    state.undoManager = undoManager

    let original = state.project.screens[0]
    let countBefore = state.project.screens.count

    undoManager.beginUndoGrouping()
    state.duplicateScreen(original)
    undoManager.endUndoGrouping()
    #expect(state.project.screens.count == countBefore + 1)

    undoManager.undo()
    #expect(state.project.screens.count == countBefore)
    #expect(state.selectedScreenID == original.id)
  }

  // MARK: - Copy/Paste Screen Tests (#032)

  @Test("copyScreen stores screen in copiedScreen")
  func testCopyScreen() {
    let state = ProjectState()
    let screen = state.project.screens[0]
    #expect(state.copiedScreen == nil)

    state.copyScreen(screen)

    #expect(state.copiedScreen != nil)
    #expect(state.copiedScreen?.id == screen.id)
  }

  @Test("pasteScreen creates new screen from copied screen")
  func testPasteScreen() {
    let state = ProjectState()
    var original = state.project.screens[0]
    original.setText(LocalizedText(title: "Test Title", subtitle: "Test Sub"), for: "en")
    state.updateScreen(original)

    state.copyScreen(state.project.screens[0])
    let countBefore = state.project.screens.count

    state.pasteScreen()

    #expect(state.project.screens.count == countBefore + 1)
    let pasted = state.project.screens.last!
    #expect(pasted.id != state.project.screens[0].id)
    #expect(pasted.name == state.project.screens[0].name + " Copy")
    #expect(pasted.text(for: "en").title == "Test Title")
    #expect(pasted.layoutPreset == state.project.screens[0].layoutPreset)
    #expect(pasted.background == state.project.screens[0].background)
    #expect(state.selectedScreenID == pasted.id)
  }

  @Test("pasteScreen does nothing when copiedScreen is nil")
  func testPasteScreenNoCopy() {
    let state = ProjectState()
    let countBefore = state.project.screens.count
    #expect(state.copiedScreen == nil)

    state.pasteScreen()

    #expect(state.project.screens.count == countBefore)
  }

  @Test("pasteScreen can be called multiple times")
  func testPasteScreenMultiple() {
    let state = ProjectState()
    state.copyScreen(state.project.screens[0])
    let countBefore = state.project.screens.count

    state.pasteScreen()
    state.pasteScreen()

    #expect(state.project.screens.count == countBefore + 2)
    let paste1 = state.project.screens[countBefore]
    let paste2 = state.project.screens[countBefore + 1]
    #expect(paste1.id != paste2.id)
  }

  @Test("pasteScreen undo removes pasted screen")
  func testPasteScreenUndo() {
    let state = ProjectState()
    let undoManager = UndoManager()
    undoManager.groupsByEvent = false
    state.undoManager = undoManager

    state.copyScreen(state.project.screens[0])
    let countBefore = state.project.screens.count

    undoManager.beginUndoGrouping()
    state.pasteScreen()
    undoManager.endUndoGrouping()
    #expect(state.project.screens.count == countBefore + 1)

    undoManager.undo()
    #expect(state.project.screens.count == countBefore)
  }

  // MARK: - Add Screen Copies Previous Style Tests (#033)

  @Test("addScreen copies style from selected screen")
  func testAddScreenCopiesPreviousStyle() {
    let state = ProjectState()
    var screen = state.project.screens[0]
    screen.layoutPreset = .textBottom
    screen.background = .solidColor(HexColor("#FF0000"))
    screen.fontFamily = "Helvetica"
    screen.fontSize = 40
    screen.textColorHex = "#000000"
    screen.showDeviceFrame = false
    screen.isLandscape = true
    screen.titleStyle = TextStyle(isBold: false, isItalic: true, alignment: .leading)
    screen.subtitleStyle = TextStyle(isBold: true, isItalic: false, alignment: .trailing)
    screen.screenshotContentMode = .fill
    screen.deviceFrameConfig = DeviceFrameConfig(
      frameColorHex: "#FFFFFF",
      bezelWidthRatio: 0.5,
      cornerRadiusRatio: 0.8,
      showDynamicIsland: false,
      dynamicIslandWidthRatio: 0.7,
      dynamicIslandHeightRatio: 0.6
    )
    state.updateScreen(screen)

    state.addScreen()

    let newScreen = state.project.screens.last!
    #expect(newScreen.layoutPreset == .textBottom)
    #expect(newScreen.fontFamily == "Helvetica")
    #expect(newScreen.fontSize == 40)
    #expect(newScreen.textColorHex == "#000000")
    #expect(newScreen.showDeviceFrame == false)
    #expect(newScreen.isLandscape == true)
    #expect(newScreen.titleStyle.isBold == false)
    #expect(newScreen.titleStyle.isItalic == true)
    #expect(newScreen.titleStyle.alignment == .leading)
    #expect(newScreen.subtitleStyle.isBold == true)
    #expect(newScreen.subtitleStyle.alignment == .trailing)
    #expect(newScreen.screenshotContentMode == .fill)
    #expect(newScreen.deviceFrameConfig.frameColorHex == "#FFFFFF")
    #expect(newScreen.deviceFrameConfig.bezelWidthRatio == 0.5)
    #expect(newScreen.deviceFrameConfig.showDynamicIsland == false)
  }

  @Test("addScreen does not copy text content")
  func testAddScreenDoesNotCopyText() {
    let state = ProjectState()
    var screen = state.project.screens[0]
    screen.setText(LocalizedText(title: "Original Title", subtitle: "Original Sub"), for: "en")
    screen.setText(LocalizedText(title: "日本語タイトル", subtitle: "日本語サブ"), for: "ja")
    state.updateScreen(screen)

    state.addScreen()

    let newScreen = state.project.screens.last!
    #expect(newScreen.title == "")
    #expect(newScreen.subtitle == "")
    #expect(newScreen.text(for: "ja").title == "")
  }

  @Test("addScreen does not copy screenshot image")
  func testAddScreenDoesNotCopyScreenshot() {
    let state = ProjectState()
    var screen = state.project.screens[0]
    screen.screenshotImageData = Data([0x89, 0x50, 0x4E, 0x47])
    state.updateScreen(screen)

    state.addScreen()

    let newScreen = state.project.screens.last!
    #expect(newScreen.screenshotImageData == nil)
  }

  @Test("addScreen with no existing screens uses defaults")
  func testAddScreenNoExistingScreens() {
    let project = ScreenShotProject(screens: [])
    let state = ProjectState(project: project)
    #expect(state.project.screens.isEmpty)

    state.addScreen()

    #expect(state.project.screens.count == 1)
    let screen = state.project.screens[0]
    #expect(screen.layoutPreset == .textTop)
    #expect(screen.fontFamily == "SF Pro Display")
    #expect(screen.fontSize == 96.0)
    #expect(screen.showDeviceFrame == true)
    #expect(screen.isLandscape == false)
    #expect(screen.screenshotContentMode == .fit)
  }

  @Test("addScreen copies background style correctly")
  func testAddScreenCopiesBackground() {
    let state = ProjectState()
    var screen = state.project.screens[0]
    screen.background = .gradient(startColor: HexColor("#FF0000"), endColor: HexColor("#0000FF"))
    state.updateScreen(screen)

    state.addScreen()

    let newScreen = state.project.screens.last!
    #expect(newScreen.background == screen.background)
  }
}
