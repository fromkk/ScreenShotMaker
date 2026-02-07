import SwiftUI

struct SidebarView: View {
    @Bindable var state: ProjectState

    var body: some View {
        VStack(spacing: 0) {
            header
            screenList
        }
        .background(Color(nsColor: .controlBackgroundColor))
        .overlay(alignment: .trailing) {
            Divider()
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
                ScreenRow(screen: screen, isSelected: state.selectedScreenID == screen.id)
                    .tag(screen.id)
                    .contextMenu {
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
}

private struct ScreenRow: View {
    let screen: Screen
    let isSelected: Bool

    var body: some View {
        HStack(spacing: 10) {
            RoundedRectangle(cornerRadius: 4)
                .fill(Color(nsColor: .separatorColor))
                .frame(width: 32, height: 56)

            VStack(alignment: .leading, spacing: 2) {
                Text(screen.name)
                    .font(.system(size: 12, weight: isSelected ? .semibold : .medium))
                    .foregroundStyle(isSelected ? Color.accentColor : .primary)

                Text(screen.title.isEmpty ? "No title" : screen.title)
                    .font(.system(size: 10))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
        }
        .padding(.vertical, 4)
    }
}
