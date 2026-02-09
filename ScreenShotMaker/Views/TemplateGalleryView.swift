import SwiftUI

struct TemplateGalleryView: View {
  let state: ProjectState
  @Environment(\.dismiss) private var dismiss
  @AppStorage("showTemplateOnLaunch") private var showTemplateOnLaunch = true

  var body: some View {
    VStack(spacing: 0) {
      header
      Divider()
      templateGrid
      Divider()
      footer
    }
    .frame(width: 680, height: 560)
  }

  private var header: some View {
    VStack(spacing: 4) {
      Text("Choose a Template")
        .font(.title2.bold())
      Text("Start with a pre-designed layout or build from scratch")
        .font(.callout)
        .foregroundStyle(.secondary)
    }
    .padding(.vertical, 20)
  }

  private var templateGrid: some View {
    ScrollView {
      LazyVGrid(
        columns: [
          GridItem(.flexible(), spacing: 16),
          GridItem(.flexible(), spacing: 16),
          GridItem(.flexible(), spacing: 16),
        ], spacing: 16
      ) {
        scratchCard
        ForEach(Template.builtIn) { template in
          templateCard(template)
        }
      }
      .padding(20)
    }
  }

  private var scratchCard: some View {
    Button {
      state.project = ScreenShotProject()
      state.selectedScreenID = state.project.screens.first?.id
      state.currentFileURL = nil
      state.hasUnsavedChanges = false
      dismiss()
    } label: {
      VStack(spacing: 8) {
        RoundedRectangle(cornerRadius: 8)
          .strokeBorder(style: StrokeStyle(lineWidth: 1.5, dash: [6, 4]))
          .foregroundStyle(.secondary)
          .frame(height: 120)
          .overlay {
            Image(systemName: "plus")
              .font(.title)
              .foregroundStyle(.secondary)
          }

        Text("Start from Scratch")
          .font(.system(size: 12, weight: .medium))
          .foregroundStyle(.primary)

        Text("Empty project")
          .font(.system(size: 10))
          .foregroundStyle(.secondary)
      }
    }
    .buttonStyle(.plain)
  }

  private func templateCard(_ template: Template) -> some View {
    Button {
      template.applyTo(state)
      dismiss()
    } label: {
      VStack(spacing: 8) {
        templatePreview(template)
          .frame(height: 120)
          .clipShape(RoundedRectangle(cornerRadius: 8))
          .overlay(
            RoundedRectangle(cornerRadius: 8)
              .strokeBorder(Color.platformSeparator)
          )

        Text(template.name)
          .font(.system(size: 12, weight: .medium))
          .foregroundStyle(.primary)

        Text(template.description)
          .font(.system(size: 10))
          .foregroundStyle(.secondary)
          .lineLimit(2)
          .multilineTextAlignment(.center)
      }
    }
    .buttonStyle(.plain)
  }

  @ViewBuilder
  private func templatePreview(_ template: Template) -> some View {
    if let screen = template.screens.first {
      previewBackground(screen.background)
        .overlay {
          VStack(spacing: 2) {
            if !screen.title.isEmpty {
              Text(screen.title)
                .font(.system(size: 9, weight: .bold))
                .foregroundStyle(Color(hex: screen.textColorHex))
            }
            if !screen.subtitle.isEmpty {
              Text(screen.subtitle)
                .font(.system(size: 7))
                .foregroundStyle(Color(hex: screen.textColorHex).opacity(0.7))
            }
          }
          .padding(8)
        }
    }
  }

  private var footer: some View {
    HStack {
      Toggle(
        "Don't show on launch",
        isOn: Binding(
          get: { !showTemplateOnLaunch },
          set: { showTemplateOnLaunch = !$0 }
        )
      )
      .font(.system(size: 12))
      .foregroundStyle(.secondary)

      Spacer()
    }
    .padding(.horizontal, 20)
    .padding(.vertical, 12)
  }

  @ViewBuilder
  private func previewBackground(_ bg: BackgroundStyle) -> some View {
    switch bg {
    case .solidColor(let hex):
      Rectangle().fill(hex.color)
    case .gradient(let start, let end):
      LinearGradient(colors: [start.color, end.color], startPoint: .top, endPoint: .bottom)
    case .image:
      Rectangle().fill(Color.gray.opacity(0.3))
    }
  }
}
