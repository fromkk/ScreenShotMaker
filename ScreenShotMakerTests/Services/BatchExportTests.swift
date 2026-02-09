import Foundation
import Testing

@testable import ScreenShotMaker

@Suite("BatchExport Tests")
struct BatchExportTests {

  @Test("ExportProgressState initializes with defaults")
  func testProgressStateDefaults() {
    let state = ExportProgressState()
    #expect(state.isExporting == false)
    #expect(state.completed == 0)
    #expect(state.total == 0)
    #expect(state.currentItem == "")
    #expect(state.errors.isEmpty)
    #expect(state.isCancelled == false)
  }

  @Test("ExportProgressState progress calculation")
  func testProgressCalculation() {
    let state = ExportProgressState()
    state.total = 10
    state.completed = 5
    #expect(abs(state.progress - 0.5) < 0.001)
  }

  @Test("ExportProgressState progress is 0 when total is 0")
  func testProgressZeroTotal() {
    let state = ExportProgressState()
    #expect(state.progress == 0)
  }

  @Test("ExportProgressState isFinished")
  func testIsFinished() {
    let state = ExportProgressState()
    #expect(state.isFinished == false)

    state.isExporting = true
    state.total = 5
    #expect(state.isFinished == false)

    state.isExporting = false
    #expect(state.isFinished == true)
  }

  @Test("ExportProgressState reset clears all fields")
  func testReset() {
    let state = ExportProgressState()
    state.isExporting = true
    state.completed = 5
    state.total = 10
    state.currentItem = "Test"
    state.errors = ["error1"]
    state.isCancelled = true

    state.reset()

    #expect(state.isExporting == false)
    #expect(state.completed == 0)
    #expect(state.total == 0)
    #expect(state.currentItem == "")
    #expect(state.errors.isEmpty)
    #expect(state.isCancelled == false)
  }

  @Test("BatchExportProgress stores correct values")
  func testBatchExportProgress() {
    let progress = BatchExportProgress(
      completed: 3,
      total: 10,
      currentScreen: "Screen 1",
      currentDevice: "iPhone 6.9",
      currentLanguage: "English"
    )
    #expect(progress.completed == 3)
    #expect(progress.total == 10)
    #expect(progress.currentScreen == "Screen 1")
    #expect(progress.currentDevice == "iPhone 6.9")
    #expect(progress.currentLanguage == "English")
  }
}
