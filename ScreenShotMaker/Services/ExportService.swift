import SwiftUI

enum ExportFormat: String, CaseIterable {
    case png
    case jpeg

    var fileExtension: String { rawValue }
}

struct ExportableScreenView: View {
    let screen: Screen
    let device: DeviceSize
    var languageCode: String = "en"

  
    private var sf: CGFloat {
        guard let ref = ScalingService.referenceDevice(for: device.category) else { return 1.0 }
        return ScalingService.scaleFactor(from: ref, to: device)
    }

    private var exportWidth: CGFloat {
        CGFloat(screen.isLandscape ? device.landscapeWidth : device.portraitWidth)
    }
    private var exportHeight: CGFloat {
        CGFloat(screen.isLandscape ? device.landscapeHeight : device.portraitHeight)
    }

    var body: some View {
        backgroundView
            .frame(width: exportWidth, height: exportHeight)
            .overlay {
                layoutContent
            }
            .clipped()
    }

    @ViewBuilder
    private var backgroundView: some View {
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
    private var layoutContent: some View {
        let sp = ScalingService.scaledPadding(24, factor: sf)
        let outerPad = ScalingService.scaledPadding(32, factor: sf)
        let textImageSpacing = screen.textToImageSpacing * sf
        switch screen.layoutPreset {
        case .textTop:
            VStack(spacing: 0) {
                Spacer(minLength: 0)
                VStack(spacing: textImageSpacing) {
                    textContent
                    screenshotView
                }
            }
            .padding(outerPad)

        case .textOverlay:
            ZStack {
                screenshotView
                    .padding(ScalingService.scaledPadding(40, factor: sf))
                VStack {
                    Spacer()
                    textContent
                        .padding()
                        .background(.black.opacity(0.5), in: RoundedRectangle(cornerRadius: ScalingService.scaledCornerRadius(16, factor: sf)))
                        .padding()
                }
            }

        case .textBottom:
            VStack(spacing: 0) {
                VStack(spacing: textImageSpacing) {
                    screenshotView
                    textContent
                }
                Spacer(minLength: 0)
            }
            .padding(outerPad)

        case .textOnly:
            VStack(spacing: ScalingService.scaledPadding(16, factor: sf)) {
                Spacer()
                textContent
                Spacer()
            }
            .padding(ScalingService.scaledPadding(48, factor: sf))

        case .screenshotOnly:
            screenshotView
                .padding(ScalingService.scaledPadding(40, factor: sf))
        }
    }

    private var textContent: some View {
        let localizedText = screen.text(for: languageCode)
        let titleSize = ScalingService.scaledFontSize(screen.fontSize, factor: sf)
        let subtitleSize = ScalingService.scaledFontSize(screen.fontSize * 0.6, factor: sf)
        return VStack(spacing: ScalingService.scaledPadding(12, factor: sf)) {
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
    private var screenshotView: some View {
        let screenshotContent = RoundedRectangle(cornerRadius: 16)
            .fill(.white)
            .overlay {
                if let imageData = screen.screenshotImageData(for: languageCode, category: device.category),
                   let nsImage = NSImage(data: imageData) {
                    Image(nsImage: nsImage)
                        .resizable()
                        .aspectRatio(contentMode: screen.screenshotContentMode == .fill ? .fill : .fit)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                }
            }

        if screen.showDeviceFrame {
            let screenW = CGFloat(screen.isLandscape ? device.landscapeWidth : device.portraitWidth) * 0.7
            let screenH = CGFloat(screen.isLandscape ? device.landscapeHeight : device.portraitHeight) * 0.7
            DeviceFrameView(
                category: device.category,
                screenWidth: screenW,
                screenHeight: screenH,
                config: screen.deviceFrameConfig
            ) {
                screenshotContent
            }
        } else {
            screenshotContent
        }
    }
}

struct BatchExportProgress: Sendable {
    let completed: Int
    let total: Int
    let currentScreen: String
    let currentDevice: String
    let currentLanguage: String
}

@MainActor
enum ExportService {
    static func exportScreen(_ screen: Screen, device: DeviceSize, format: ExportFormat, languageCode: String = "en") -> Data? {
        let view = ExportableScreenView(screen: screen, device: device, languageCode: languageCode)
        let renderer = ImageRenderer(content: view)
        renderer.scale = 1.0

        guard let nsImage = renderer.nsImage,
              let tiffData = nsImage.tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: tiffData) else {
            return nil
        }

        switch format {
        case .png:
            return bitmap.representation(using: .png, properties: [:])
        case .jpeg:
            return bitmap.representation(using: .jpeg, properties: [.compressionFactor: 0.9])
        }
    }

    static func batchExport(
        project: ScreenShotProject,
        devices: [DeviceSize],
        languages: [Language],
        format: ExportFormat,
        outputDirectory: URL,
        progressState: ExportProgressState
    ) async {
        let screens = project.screens
        let total = screens.count * devices.count * languages.count
        progressState.total = total
        progressState.completed = 0
        progressState.isExporting = true

        var completed = 0
        for language in languages {
            for device in devices {
                let langDir = outputDirectory.appendingPathComponent(language.code)
                let deviceDir = langDir.appendingPathComponent(device.name)
                do {
                    try FileManager.default.createDirectory(at: deviceDir, withIntermediateDirectories: true)
                } catch {
                    progressState.errors.append("Failed to create directory: \(deviceDir.path)")
                    continue
                }

                for screen in screens {
                    if progressState.isCancelled { break }

                    progressState.currentItem = "\(screen.name) / \(device.name) / \(language.displayName)"

                    let data = exportScreen(screen, device: device, format: format, languageCode: language.code)
                    if let data {
                        let fileName = "\(screen.name).\(format.fileExtension)"
                        let fileURL = deviceDir.appendingPathComponent(fileName)
                        do {
                            try data.write(to: fileURL, options: .atomic)
                        } catch {
                            progressState.errors.append("Failed to write: \(fileName) - \(error.localizedDescription)")
                        }
                    } else {
                        progressState.errors.append("Failed to render: \(screen.name) / \(device.name)")
                    }

                    completed += 1
                    progressState.completed = completed
                }
                if progressState.isCancelled { break }
            }
            if progressState.isCancelled { break }
        }

        progressState.isExporting = false
    }
}
