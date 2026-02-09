import Testing

@testable import ScreenShotMaker

@Suite("Template Tests")
struct TemplateTests {

  @Test("Built-in templates has 5 or more templates")
  func testBuiltInCount() {
    #expect(Template.builtIn.count >= 5)
  }

  @Test("Each template has unique ID")
  func testUniqueIDs() {
    let ids = Template.builtIn.map(\.id)
    #expect(Set(ids).count == ids.count)
  }

  @Test("Each template has at least one screen")
  func testTemplatesHaveScreens() {
    for template in Template.builtIn {
      #expect(!template.screens.isEmpty, "Template '\(template.name)' has no screens")
    }
  }

  @Test("Each template has a name and description")
  func testTemplatesHaveMetadata() {
    for template in Template.builtIn {
      #expect(!template.name.isEmpty)
      #expect(!template.description.isEmpty)
    }
  }

  @Test("applyTo sets project screens from template")
  @MainActor func testApplyTo() {
    let state = ProjectState()
    let template = Template.builtIn[0]
    template.applyTo(state)
    #expect(state.project.screens.count == template.screens.count)
    #expect(state.selectedScreenID == template.screens.first?.id)
    #expect(state.currentFileURL == nil)
  }
}
