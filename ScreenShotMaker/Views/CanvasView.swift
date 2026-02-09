import SwiftUI
import UniformTypeIdentifiers

struct CanvasView: View {
    @Bindable var state: ProjectState
    @State private var imageLoadError: String?
    @State private var showImageLoadError = false
    @GestureState private var magnification: CGFloat = 1.0

    private var effectiveZoom: Double {
        min(3.0, max(0.1, state.zoomScale * magnification))
    }

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
        .background(Color.platformBackground.opacity(0.5))
        .gesture(
            MagnifyGesture()
                .updating($magnification) { value, gestureState, _ in
                    gestureState = value.magnification
                }
                .onEnded { value in
                    state.zoomScale = min(3.0, max(0.1, state.zoomScale * value.magnification))
                }
        )
        .alert("Image Load Error", isPresented: $showImageLoadError) {
            Button("OK") {}
        } message: {
            Text(imageLoadError ?? "Unknown error")
        }
    }

    private var previewScale: Double {
        effectiveZoom * 0.15
    }

    private func scaleFactor(for device: DeviceSize) -> CGFloat {
        guard let ref = ScalingService.referenceDevice(for: device.category) else { return 1.0 }
        return ScalingService.scaleFactor(from: ref, to: device)
    }

    private func screenshotPreview(screen: Screen, device: DeviceSize) -> some View {
        let w = screen.isLandscape ? device.landscapeWidth : device.portraitWidth
        let h = screen.isLandscape ? device.landscapeHeight : device.portraitHeight
        let previewWidth = Double(w) * previewScale
        let previewHeight = Double(h) * previewScale

        return VStack(spacing: 0) {
            backgroundView(for: screen)
                .frame(width: previewWidth, height: previewHeight)
                .overlay {
                    layoutContent(screen: screen, device: device)
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
            if let platformImage = PlatformImage(data: data) {
                Image(platformImage: platformImage)
                    .resizable()
                    .scaledToFill()
            } else {
                Rectangle().fill(Color.gray.opacity(0.3))
            }
        }
    }

    @ViewBuilder
    private func layoutContent(screen: Screen, device: DeviceSize) -> some View {
        let sf = scaleFactor(for: device)
        let ps = previewScale
        let sp = ScalingService.scaledPadding(24, factor: sf) * ps
        let outerPad = ScalingService.scaledPadding(32, factor: sf) * ps
        let textImageSpacing = screen.textToImageSpacing * sf * ps

        switch screen.layoutPreset {
        case .textTop:
            VStack(spacing: 0) {
                Spacer(minLength: 0)
                VStack(spacing: textImageSpacing) {
                    textContent(screen: screen, device: device)
                    screenshotPlaceholder(screen: screen)
                }
            }
            .padding(outerPad)

        case .textOverlay:
            ZStack {
                screenshotPlaceholder(screen: screen)
                    .padding(ScalingService.scaledPadding(40, factor: sf) * ps)
                VStack {
                    Spacer()
                    textContent(screen: screen, device: device)
                        .padding(ScalingService.scaledPadding(16, factor: sf) * ps)
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: ScalingService.scaledCornerRadius(16, factor: sf) * ps))
                        .padding(ScalingService.scaledPadding(16, factor: sf) * ps)
                }
            }

        case .textBottom:
            VStack(spacing: 0) {
                VStack(spacing: textImageSpacing) {
                    screenshotPlaceholder(screen: screen)
                    textContent(screen: screen, device: device)
                }
                Spacer(minLength: 0)
            }
            .padding(outerPad)

        case .textOnly:
            VStack(spacing: ScalingService.scaledPadding(16, factor: sf) * ps) {
                Spacer()
                textContent(screen: screen, device: device)
                Spacer()
            }
            .padding(ScalingService.scaledPadding(48, factor: sf) * ps)

        case .screenshotOnly:
            screenshotPlaceholder(screen: screen)
                .padding(ScalingService.scaledPadding(40, factor: sf) * ps)
        }
    }

    private func textContent(screen: Screen, device: DeviceSize) -> some View {
        let langCode = state.selectedLanguage?.code ?? "en"
        let localizedText = screen.text(for: langCode)
        let sf = scaleFactor(for: device)
        let ps = previewScale
        let titleSize = ScalingService.scaledFontSize(screen.fontSize, factor: sf) * ps
        let subtitleSize = ScalingService.scaledFontSize(screen.fontSize * 0.6, factor: sf) * ps
        return VStack(spacing: ScalingService.scaledPadding(12, factor: sf) * ps) {
            if !localizedText.title.isEmpty {
                Text(localizedText.title)
                    .font(.custom(screen.fontFamily, size: titleSize).weight(screen.titleStyle.isBold ? .bold : .regular))
                    .italic(screen.titleStyle.isItalic)
                    .foregroundStyle(Color(hex: screen.textColorHex))
                    .multilineTextAlignment(screen.titleStyle.alignment.textAlignment)
                    .frame(maxWidth: .infinity, alignment: screen.titleStyle.alignment.alignment)
            }
            if !localizedText.subtitle.isEmpty {
                Text(localizedText.subtitle)
                    .font(.custom(screen.fontFamily, size: subtitleSize).weight(screen.subtitleStyle.isBold ? .bold : .regular))
                    .italic(screen.subtitleStyle.isItalic)
                    .foregroundStyle(Color(hex: screen.textColorHex).opacity(0.8))
                    .multilineTextAlignment(screen.subtitleStyle.alignment.textAlignment)
                    .frame(maxWidth: .infinity, alignment: screen.subtitleStyle.alignment.alignment)
            }
        }
    }

    @ViewBuilder
    private func screenshotPlaceholder(screen: Screen) -> some View {
        let languageCode = state.selectedLanguage?.code ?? "en"
        let screenshotContent = RoundedRectangle(cornerRadius: 8)
            .fill(.white)
            .overlay {
                if let device = state.selectedDevice,
                   let imageData = screen.screenshotImageData(for: languageCode, category: device.category),
                   let platformImage = PlatformImage(data: imageData) {
                    Image(platformImage: platformImage)
                        .resizable()
                        .aspectRatio(contentMode: screen.screenshotContentMode == .fill ? .fill : .fit)
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
            let frameW = Double(screen.isLandscape ? device.landscapeWidth : device.portraitWidth) * effectiveZoom * 0.15 * 0.7
            let frameH = Double(screen.isLandscape ? device.landscapeHeight : device.portraitHeight) * effectiveZoom * 0.15 * 0.7
            DeviceFrameView(
                category: device.category,
                screenWidth: frameW,
                screenHeight: frameH,
                config: screen.deviceFrameConfig
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
                    if let category = state.selectedDevice?.category {
                        let languageCode = state.selectedLanguage?.code ?? "en"
                        state.selectedScreen?.setScreenshotImageData(imageData, for: languageCode, category: category)
                    }
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
                    state.zoomOut()
                } label: {
                    Image(systemName: "minus")
                        .font(.caption2)
                }
                .buttonStyle(.plain)

                Button {
                    state.zoomReset()
                } label: {
                    Text("\(Int(effectiveZoom * 100))%")
                        .font(.system(size: 11, weight: .medium, design: .monospaced))
                        .foregroundStyle(.secondary)
                        .frame(width: 40)
                }
                .buttonStyle(.plain)
                .help("Click to reset to 100%")

                Button {
                    state.zoomIn()
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
