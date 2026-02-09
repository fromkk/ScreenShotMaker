import SwiftUI

struct SidebarView: View {
  @Bindable var state: ProjectState
  @State private var editingScreenID: UUID?
  @State private var editingName: String = ""

  var body: some View {
    VStack(spacing: 0) {
      header
      screenList
    }
  }

  private var header: some View {
    HStack {
      Text("SCREENS")
        .font(.caption2)
        .fontWeight(.semibold)
        .foregroundStyle(.secondary)
        .tracking(0.5)

      Spacer()

      Button {
        state.addScreen()
      } label: {
        Image(systemName: "plus")
          .font(.caption)
          .foregroundStyle(.secondary)
      }
      .buttonStyle(.plain)
    }
    .padding(.horizontal, 16)
    .padding(.vertical, 10)
  }

  private var screenList: some View {
    List(selection: $state.selectedScreenID) {
      ForEach(state.project.screens) { screen in
        ScreenRow(
          screen: screen,
          isSelected: state.selectedScreenID == screen.id,
          isEditing: editingScreenID == screen.id,
          editingName: editingScreenID == screen.id ? $editingName : .constant("")
        ) {
          commitRename(for: screen)
        }
        .tag(screen.id)
        .onTapGesture(count: 2) {
          startRename(screen: screen)
        }
        .contextMenu {
          Button("Rename") {
            startRename(screen: screen)
          }
          Button("Duplicate") {
            state.duplicateScreen(screen)
          }
          Divider()
          Button("Copy") {
            state.copyScreen(screen)
          }
          Button("Paste") {
            state.pasteScreen()
          }
          .disabled(state.copiedScreen == nil)
          Divider()
          Button("Delete", role: .destructive) {
            state.deleteScreen(screen)
          }
        }
      }
      .onMove { source, destination in
        state.moveScreen(from: source, to: destination)
      }
    }
    .listStyle(.sidebar)
  }

  private func startRename(screen: Screen) {
    editingName = screen.name
    editingScreenID = screen.id
  }

  private func commitRename(for screen: Screen) {
    guard editingScreenID == screen.id else { return }
    let newName = editingName.trimmingCharacters(in: .whitespacesAndNewlines)
    if !newName.isEmpty && newName != screen.name {
      var updated = screen
      updated.name = newName
      state.updateScreen(updated, actionName: "Rename Screen")
    }
    editingScreenID = nil
    editingName = ""
  }
}

private struct ScreenRow: View {
  let screen: Screen
  let isSelected: Bool
  let isEditing: Bool
  @Binding var editingName: String
  var onCommit: () -> Void

  var body: some View {
    HStack(spacing: 10) {
      RoundedRectangle(cornerRadius: 4)
        .fill(Color.platformSeparator)
        .frame(width: 32, height: 56)

      VStack(alignment: .leading, spacing: 2) {
        if isEditing {
          TextField("Screen name", text: $editingName, onCommit: onCommit)
            .font(.system(size: 12, weight: .medium))
            .textFieldStyle(.roundedBorder)
        } else {
          Text(screen.name)
            .font(.system(size: 12, weight: isSelected ? .semibold : .medium))
            .foregroundStyle(isSelected ? Color.accentColor : .primary)
        }

        Text(screen.title.isEmpty ? "No title" : screen.title)
          .font(.system(size: 10))
          .foregroundStyle(.secondary)
          .lineLimit(1)
      }
    }
    .padding(.vertical, 4)
  }
}
