import OSLog
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
  var videoNaturalSize: CGSize? = nil

  private var sf: CGFloat {
    guard let ref = ScalingService.referenceDevice(for: device.category) else { return 1.0 }
    return ScalingService.scaleFactor(from: ref, to: device)
  }

  private var exportWidth: CGFloat {
    CGFloat(device.effectiveWidth(isLandscape: screen.isLandscape))
  }
  private var exportHeight: CGFloat {
    CGFloat(device.effectiveHeight(isLandscape: screen.isLandscape))
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
      if let image = PlatformImage(data: data) {
        Image(platformImage: image)
          .resizable()
          .scaledToFill()
      } else {
        Rectangle().fill(Color.gray.opacity(0.3))
      }
    }
  }

  @ViewBuilder
  private var layoutContent: some View {
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
            .background(
              .black.opacity(0.5),
              in: RoundedRectangle(cornerRadius: ScalingService.scaledCornerRadius(16, factor: sf))
            )
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
    let titleSize = ScalingService.scaledFontSize(screen.fontSize(for: device.category), factor: sf)
    let subtitleSize = ScalingService.scaledFontSize(screen.fontSize(for: device.category) * 0.6, factor: sf)
    return VStack(spacing: ScalingService.scaledPadding(12, factor: sf)) {
      if !localizedText.title.isEmpty {
        Text(localizedText.title)
          .font(
            .custom(screen.fontFamily, size: titleSize).weight(
              screen.titleStyle.isBold ? .bold : .regular)
          )
          .italic(screen.titleStyle.isItalic)
          .foregroundStyle(Color(hex: screen.textColorHex))
          .multilineTextAlignment(screen.titleStyle.alignment.textAlignment)
          .frame(maxWidth: .infinity, alignment: screen.titleStyle.alignment.alignment)
      }
      if !localizedText.subtitle.isEmpty {
        Text(localizedText.subtitle)
          .font(
            .custom(screen.fontFamily, size: subtitleSize).weight(
              screen.subtitleStyle.isBold ? .bold : .regular)
          )
          .italic(screen.subtitleStyle.isItalic)
          .foregroundStyle(Color(hex: screen.textColorHex).opacity(0.8))
          .multilineTextAlignment(screen.subtitleStyle.alignment.textAlignment)
          .frame(maxWidth: .infinity, alignment: screen.subtitleStyle.alignment.alignment)
      }
    }
  }

  /// Returns the fitted screen dimensions for the DeviceFrameView, honouring
  /// `fitFrameToImage` for both video (videoNaturalSize) and static image content.
  private func fittedScreenSize(
    baseWidth: CGFloat, baseHeight: CGFloat
  ) -> (width: CGFloat, height: CGFloat) {
    if let vs = videoNaturalSize {
      return ScalingService.frameFittingSize(
        nativeSize: vs, boxWidth: baseWidth, boxHeight: baseHeight,
        fitToImage: screen.fitFrameToImage)
    }
    let imageData = screen.screenshotImageData(for: languageCode, category: device.category)
    return ScalingService.frameFittingSize(
      imageData: imageData, boxWidth: baseWidth, boxHeight: baseHeight,
      fitToImage: screen.fitFrameToImage)
  }

  @ViewBuilder
  private var screenshotView: some View {
    let screenshotContent = RoundedRectangle(cornerRadius: 16)
      .fill(.white)
      .overlay {
        if let imageData = screen.screenshotImageData(for: languageCode, category: device.category),
          let image = PlatformImage(data: imageData)
        {
          Image(platformImage: image)
            .resizable()
            .aspectRatio(contentMode: screen.screenshotContentMode == .fill ? .fill : .fit)
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
      }

    if screen.showDeviceFrame {
      let baseScreenW = CGFloat(device.effectiveWidth(isLandscape: screen.isLandscape)) * 0.7
      let baseScreenH =
        CGFloat(device.effectiveHeight(isLandscape: screen.isLandscape)) * 0.7
      let fitted = fittedScreenSize(baseWidth: baseScreenW, baseHeight: baseScreenH)
      DeviceFrameView(
        category: device.category,
        screenWidth: fitted.width,
        screenHeight: fitted.height,
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
  static func exportScreen(
    _ screen: Screen, device: DeviceSize, format: ExportFormat, languageCode: String = "en"
  ) -> Data? {
    let view = ExportableScreenView(screen: screen, device: device, languageCode: languageCode)
    let renderer = ImageRenderer(content: view)
    renderer.scale = 1.0

    #if canImport(AppKit)
      guard let nsImage = renderer.nsImage,
        let tiffData = nsImage.tiffRepresentation,
        let bitmap = NSBitmapImageRep(data: tiffData)
      else {
        return nil
      }

      switch format {
      case .png:
        return bitmap.representation(using: .png, properties: [:])
      case .jpeg:
        return bitmap.representation(using: .jpeg, properties: [.compressionFactor: 0.9])
      }
    #elseif canImport(UIKit)
      guard let uiImage = renderer.uiImage else {
        return nil
      }

      switch format {
      case .png:
        return uiImage.pngData()
      case .jpeg:
        return uiImage.jpegData(compressionQuality: 0.9)
      }
    #endif
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

    // Pre-create output directories for all language/device combos
    for language in languages {
      for device in devices {
        let deviceDir = outputDirectory
          .appendingPathComponent(language.code)
          .appendingPathComponent(device.name)
        try? FileManager.default.createDirectory(at: deviceDir, withIntermediateDirectories: true)
      }
    }

    var completed = 0

    // ── Pass 1: video screens (export as .mp4) ─────────────────
    for language in languages {
      if progressState.isCancelled { break }
      for device in devices {
        if progressState.isCancelled { break }
        let deviceDir = outputDirectory
          .appendingPathComponent(language.code)
          .appendingPathComponent(device.name)
        for screen in screens {
          if progressState.isCancelled { break }
          guard screen.hasVideo(for: language.code, category: device.category) else {
            continue
          }
          let langName = String(localized: language.displayName)
          progressState.currentItem = "\(screen.name) / \(device.name) / \(langName)"
          let fileURL = deviceDir.appendingPathComponent("\(screen.name).mp4")
          progressState.resetFrameProgress()
          do {
            try await VideoExportService.exportVideoScreen(
              screen, device: device, languageCode: language.code, outputURL: fileURL,
              onFrameProgress: { done, total in
                DispatchQueue.main.async {
                  progressState.currentFrameCompleted = done
                  progressState.currentFrameTotal = total
                }
              })
          } catch {
            progressState.errors.append(
              "Video export failed: \(screen.name) / \(device.name) – \(error.localizedDescription)"
            )
          }
          progressState.resetFrameProgress()
          completed += 1
          progressState.completed = completed
        }
      }
    }

    // ── Pass 2: static image screens ───────────────────────────
    for language in languages {
      if progressState.isCancelled { break }
      for device in devices {
        if progressState.isCancelled { break }
        let deviceDir = outputDirectory
          .appendingPathComponent(language.code)
          .appendingPathComponent(device.name)
        for screen in screens {
          if progressState.isCancelled { break }
          guard !screen.hasVideo(for: language.code, category: device.category) else {
            continue
          }
          let langName = String(localized: language.displayName)
          progressState.currentItem = "\(screen.name) / \(device.name) / \(langName)"
          let data = exportScreen(screen, device: device, format: format, languageCode: language.code)
          if let data {
            let fileName = "\(screen.name).\(format.fileExtension)"
            let fileURL = deviceDir.appendingPathComponent(fileName)
            do {
              try data.write(to: fileURL, options: .atomic)
            } catch {
              progressState.errors.append(
                "Failed to write: \(fileName) - \(error.localizedDescription)")
            }
          } else {
            progressState.errors.append("Failed to render: \(screen.name) / \(device.name)")
          }
          completed += 1
          progressState.completed = completed
        }
      }
    }

    progressState.isExporting = false
  }

  /// Renders all screens to in-memory Data without writing to disk.
  /// Used on iOS for saving to Photos library.
  static func batchRender(
    project: ScreenShotProject,
    devices: [DeviceSize],
    languages: [Language],
    format: ExportFormat,
    progressState: ExportProgressState
  ) async -> [(data: Data, filename: String)] {
    let screens = project.screens
    let total = screens.count * devices.count * languages.count
    progressState.total = total
    progressState.completed = 0
    progressState.isExporting = true

    var results: [(data: Data, filename: String)] = []
    var completed = 0

    // ── Pass 1: video screens (render poster frame as static image) ──
    for language in languages {
      if progressState.isCancelled { break }
      for device in devices {
        if progressState.isCancelled { break }
        for screen in screens {
          if progressState.isCancelled { break }
          guard screen.hasVideo(for: language.code, category: device.category) else { continue }
          let langName = String(localized: language.displayName)
          progressState.currentItem = "\(screen.name) / \(device.name) / \(langName)"
          let posterTime = screen.videoPosterTime(for: language.code, category: device.category)
          if let bookmarkData = screen.screenshotVideoBookmarkData(
            for: language.code, category: device.category),
            let videoURL = VideoLoader.resolveBookmark(bookmarkData),
            let thumbData = await VideoLoader.generateThumbnail(url: videoURL, at: posterTime)
          {
            var tempScreen = screen
            tempScreen.setScreenshotImageData(thumbData, for: language.code, category: device.category)
            if let data = exportScreen(tempScreen, device: device, format: format, languageCode: language.code) {
              let filename = "\(language.code)_\(device.name)_\(screen.name).\(format.fileExtension)"
              results.append((data: data, filename: filename))
            }
          } else {
            progressState.errors.append(
              "Video poster frame unavailable: \(screen.name) / \(device.name)")
          }
          completed += 1
          progressState.completed = completed
        }
      }
    }

    // ── Pass 2: static image screens ───────────────────────────
    for language in languages {
      if progressState.isCancelled { break }
      for device in devices {
        if progressState.isCancelled { break }
        for screen in screens {
          if progressState.isCancelled { break }
          guard !screen.hasVideo(for: language.code, category: device.category) else { continue }
          let langName = String(localized: language.displayName)
          progressState.currentItem = "\(screen.name) / \(device.name) / \(langName)"
          if let data = exportScreen(screen, device: device, format: format, languageCode: language.code) {
            let filename = "\(language.code)_\(device.name)_\(screen.name).\(format.fileExtension)"
            results.append((data: data, filename: filename))
          } else {
            progressState.errors.append("Failed to render: \(screen.name) / \(device.name)")
          }
          completed += 1
          progressState.completed = completed
        }
      }
    }

    return results
  }
}
