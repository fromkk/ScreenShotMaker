import SwiftUI
import UniformTypeIdentifiers

struct CanvasView: View {
    @Bindable var state: ProjectState
    @State private var zoomScale: Double = 0.5
    @State private var imageLoadError: String?
    @State private var showImageLoadError = false

    var body: some View {
        VStack(spacing: 12) {
            Spacer()

            if let screen = state.selectedScreen, let device = state.selectedDevice {
                screenshotPreview(screen: screen, device: device)
            } else {
                emptyState
            }

            Spacer()

            bottomBar
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(nsColor: .windowBackgroundColor).opacity(0.5))
        .alert("Image Load Error", isPresented: $showImageLoadError) {
            Button("OK") {}
        } message: {
            Text(imageLoadError ?? "Unknown error")
        }
    }

    private func screenshotPreview(screen: Screen, device: DeviceSize) -> some View {
        let w = screen.isLandscape ? device.landscapeWidth : device.portraitWidth
        let h = screen.isLandscape ? device.landscapeHeight : device.portraitHeight
        let previewWidth = Double(w) * zoomScale * 0.15
        let previewHeight = Double(h) * zoomScale * 0.15

        return VStack(spacing: 0) {
            backgroundView(for: screen)
                .frame(width: previewWidth, height: previewHeight)
                .overlay {
                    layoutContent(screen: screen)
                }
                .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .shadow(color: .black.opacity(0.1), radius: 20, y: 8)
    }

    @ViewBuilder
    private func backgroundView(for screen: Screen) -> some View {
        switch screen.background {
        case .solidColor(let hexColor):
            Rectangle().fill(hexColor.color)
        case .gradient(let start, let end):
            LinearGradient(
                colors: [start.color, end.color],
                startPoint: .top,
                endPoint: .bottom
            )
        case .image(let data):
            if let nsImage = NSImage(data: data) {
                Image(nsImage: nsImage)
                    .resizable()
                    .scaledToFill()
            } else {
                Rectangle().fill(Color.gray.opacity(0.3))
            }
        }
    }

    @ViewBuilder
    private func layoutContent(screen: Screen) -> some View {
        switch screen.layoutPreset {
        case .textTop:
            VStack(spacing: 12) {
                textContent(screen: screen)
                    .padding(.top, 30)
                screenshotPlaceholder(screen: screen)
                Spacer(minLength: 0)
            }
            .padding(16)

        case .textOverlay:
            ZStack {
                screenshotPlaceholder(screen: screen)
                    .padding(20)
                VStack {
                    Spacer()
                    textContent(screen: screen)
                        .padding()
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 8))
                        .padding()
                }
            }

        case .textBottom:
            VStack(spacing: 12) {
                Spacer(minLength: 0)
                screenshotPlaceholder(screen: screen)
                textContent(screen: screen)
                    .padding(.bottom, 30)
            }
            .padding(16)

        case .textOnly:
            VStack(spacing: 8) {
                Spacer()
                textContent(screen: screen)
                Spacer()
            }
            .padding(24)

        case .screenshotOnly:
            screenshotPlaceholder(screen: screen)
                .padding(20)
        }
    }

    private func textContent(screen: Screen) -> some View {
        let langCode = state.selectedLanguage?.code ?? "en"
        let localizedText = screen.text(for: langCode)
        let titleSize = screen.fontSize * zoomScale * 0.4
        let subtitleSize = screen.fontSize * zoomScale * 0.25
        return VStack(spacing: 6) {
            if !localizedText.title.isEmpty {
                Text(localizedText.title)
                    .font(.custom(screen.fontFamily, size: titleSize).bold())
                    .foregroundStyle(Color(hex: screen.textColorHex))
                    .multilineTextAlignment(.center)
            }
            if !localizedText.subtitle.isEmpty {
                Text(localizedText.subtitle)
                    .font(.custom(screen.fontFamily, size: subtitleSize))
                    .foregroundStyle(Color(hex: screen.textColorHex).opacity(0.8))
                    .multilineTextAlignment(.center)
            }
        }
    }

    @ViewBuilder
    private func screenshotPlaceholder(screen: Screen) -> some View {
        let screenshotContent = RoundedRectangle(cornerRadius: 8)
            .fill(.white)
            .overlay {
                if let imageData = screen.screenshotImageData,
                   let nsImage = NSImage(data: imageData) {
                    Image(nsImage: nsImage)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                } else {
                    VStack(spacing: 6) {
                        Image(systemName: "photo.badge.plus")
                            .font(.title2)
                            .foregroundStyle(.tertiary)
                        Text("Drop screenshot")
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                    }
                }
            }
            .onDrop(of: [.fileURL], isTargeted: nil) { providers in
                handleDrop(providers: providers)
            }

        if screen.showDeviceFrame, let device = state.selectedDevice {
            DeviceFrameView(
                category: device.category,
                screenWidth: Double(device.portraitWidth) * zoomScale * 0.15 * 0.7,
                screenHeight: Double(device.portraitHeight) * zoomScale * 0.15 * 0.7
            ) {
                screenshotContent
            }
        } else {
            screenshotContent
        }
    }

    private func handleDrop(providers: [NSItemProvider]) -> Bool {
        guard let provider = providers.first else { return false }
        provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier) { data, _ in
            guard let data = data as? Data,
                  let url = URL(dataRepresentation: data, relativeTo: nil) else { return }
            DispatchQueue.main.async {
                do {
                    let imageData = try ImageLoader.loadImage(from: url)
                    state.selectedScreen?.screenshotImageData = imageData
                } catch {
                    imageLoadError = error.localizedDescription
                    showImageLoadError = true
                }
            }
        }
        return true
    }

    private var emptyState: some View {
        VStack(spacing: 8) {
            Image(systemName: "rectangle.dashed")
                .font(.largeTitle)
                .foregroundStyle(.tertiary)
            Text("No screen selected")
                .font(.callout)
                .foregroundStyle(.secondary)
        }
    }

    private var bottomBar: some View {
        VStack(spacing: 4) {
            HStack(spacing: 8) {
                Button {
                    zoomScale = max(0.2, zoomScale - 0.1)
                } label: {
                    Image(systemName: "minus")
                        .font(.caption2)
                }
                .buttonStyle(.plain)

                Text("\(Int(zoomScale * 100))%")
                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                    .foregroundStyle(.secondary)
                    .frame(width: 40)

                Button {
                    zoomScale = min(2.0, zoomScale + 0.1)
                } label: {
                    Image(systemName: "plus")
                        .font(.caption2)
                }
                .buttonStyle(.plain)
            }

            if let device = state.selectedDevice, let screen = state.selectedScreen {
                let w = screen.isLandscape ? device.landscapeWidth : device.portraitWidth
                let h = screen.isLandscape ? device.landscapeHeight : device.portraitHeight
                Text("\(w) × \(h) px")
                    .font(.system(size: 10))
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(.bottom, 12)
    }
}
