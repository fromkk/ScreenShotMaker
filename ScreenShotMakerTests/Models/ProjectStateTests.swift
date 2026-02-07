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
}
