/// VideoExportService: Composites device frame, background, and text over each video frame
/// and writes the result to a new .mp4 file using AVFoundation (AVAssetReader/Writer pipeline).
@preconcurrency import AVFoundation
import CoreImage
import Foundation
import SwiftUI

enum VideoExportError: LocalizedError {
  case videoURLUnavailable
  case assetLoadFailed
  case noVideoTrack
  case writerSetupFailed
  case exportFailed(String?)

  var errorDescription: String? {
    switch self {
    case .videoURLUnavailable:
      return "Could not resolve the video file."
    case .assetLoadFailed:
      return "Failed to load the video asset."
    case .noVideoTrack:
      return "The video file contains no video track."
    case .writerSetupFailed:
      return "Failed to set up the video export pipeline."
    case .exportFailed(let msg):
      return "Export failed: \(msg ?? "unknown error")"
    }
  }
}

@MainActor
enum VideoExportService {

  // MARK: - Single screen export

  /// Composites `screen`'s overlay onto each video frame and writes to `outputURL`.
  static func exportVideoScreen(
    _ screen: Screen,
    device: DeviceSize,
    languageCode: String,
    outputURL: URL,
    onFrameProgress: (@Sendable (Int, Int) -> Void)? = nil
  ) async throws {
    guard let bookmarkData = screen.screenshotVideoBookmarkData(
      for: languageCode, category: device.category)
    else { throw VideoExportError.videoURLUnavailable }

    guard let videoURL = VideoLoader.resolveBookmark(bookmarkData) else {
      throw VideoExportError.videoURLUnavailable
    }

    let accessing = videoURL.startAccessingSecurityScopedResource()
    defer { if accessing { videoURL.stopAccessingSecurityScopedResource() } }

    try await exportVideo(
      from: videoURL,
      screen: screen,
      device: device,
      languageCode: languageCode,
      outputURL: outputURL,
      onFrameProgress: onFrameProgress
    )
  }

  /// Renders the screen overlay with the video's poster frame as a static image.
  /// Returns PNG/JPEG data (matching `format`) or nil on failure.
  @MainActor
  static func exportPosterFrame(
    screen: Screen,
    device: DeviceSize,
    languageCode: String,
    format: ExportFormat = .png
  ) async -> Data? {
    guard let bookmarkData = screen.screenshotVideoBookmarkData(
      for: languageCode, category: device.category),
      let videoURL = VideoLoader.resolveBookmark(bookmarkData)
    else { return nil }

    let posterTime = screen.videoPosterTime(for: languageCode, category: device.category)
    let accessing = videoURL.startAccessingSecurityScopedResource()
    defer { if accessing { videoURL.stopAccessingSecurityScopedResource() } }

    guard let thumbData = await VideoLoader.generateThumbnail(url: videoURL, at: posterTime)
    else { return nil }

    // Build a temporary Screen with the poster frame image substituted in
    var tempScreen = screen
    tempScreen.setScreenshotImageData(thumbData, for: languageCode, category: device.category)
    return ExportService.exportScreen(
      tempScreen, device: device, format: format, languageCode: languageCode)
  }

  // MARK: - Batch export

  static func batchVideoExport(
    project: ScreenShotProject,
    devices: [DeviceSize],
    languages: [Language],
    outputDirectory: URL,
    progressState: ExportProgressState
  ) async {
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

        for screen in project.screens {
          if progressState.isCancelled { break }
          guard screen.hasVideo(for: language.code, category: device.category) else { continue }

          progressState.currentItem =
            "\(screen.name) / \(device.name) / \(String(localized: language.displayName))"
          let outputURL = deviceDir.appendingPathComponent("\(screen.name).mp4")

          do {
            progressState.resetFrameProgress()
          try await exportVideoScreen(
              screen, device: device, languageCode: language.code, outputURL: outputURL,
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

          progressState.completed += 1
        }
        if progressState.isCancelled { break }
      }
      if progressState.isCancelled { break }
    }
  }

  // MARK: - Core compositor

  private static func exportVideo(
    from videoURL: URL,
    screen: Screen,
    device: DeviceSize,
    languageCode: String,
    outputURL: URL,
    onFrameProgress: (@Sendable (Int, Int) -> Void)? = nil
  ) async throws {
    let exportWidth = Int(device.effectiveWidth(isLandscape: screen.isLandscape))
    let exportHeight = Int(device.effectiveHeight(isLandscape: screen.isLandscape))
    let exportSize = CGSize(width: exportWidth, height: exportHeight)

    // Determine the video's display size (accounts for rotation transform)
    let videoDisplaySize = await loadVideoDisplaySize(from: videoURL)

    // Render overlay (background + text + device frame + white placeholder) on main actor
    let overlayImageData = renderOverlayImageData(
      screen: screen, device: device, languageCode: languageCode,
      exportSize: exportSize, videoNaturalSize: videoDisplaySize)

    // Rect (top-left coords) and corner radius inside the device frame where video goes
    let screenshotRect    = screenshotAreaRect(
      screen: screen, device: device, exportSize: exportSize, videoNaturalSize: videoDisplaySize)
    let videoCornerRadius = screenshotCornerRadius(
      screen: screen, device: device, exportSize: exportSize, videoNaturalSize: videoDisplaySize)
    let contentMode       = screen.screenshotContentMode

    try? FileManager.default.removeItem(at: outputURL)

    // Only Sendable types cross the actor boundary
    let url    = videoURL
    let outURL = outputURL
    let rect   = screenshotRect
    let cr     = videoCornerRadius
    let mode   = contentMode
    let w      = exportWidth
    let h      = exportHeight
    let overlay = overlayImageData

    let frameProgress = onFrameProgress
    try await Task.detached(priority: .userInitiated) {
      try await Self.runExportPipeline(
        videoURL: url,
        overlayImageData: overlay,
        screenshotRect: rect,
        cornerRadius: cr,
        contentMode: mode,
        exportWidth: w,
        exportHeight: h,
        outputURL: outURL,
        onFrameProgress: frameProgress
      )
    }.value
  }

  // MARK: - Export pipeline (nonisolated, AVAssetReader/Writer per-frame compositing)

  private nonisolated static func runExportPipeline(
    videoURL: URL,
    overlayImageData: Data?,
    screenshotRect: CGRect,
    cornerRadius: CGFloat,
    contentMode: ScreenshotContentMode,
    exportWidth: Int,
    exportHeight: Int,
    outputURL: URL,
    onFrameProgress: (@Sendable (Int, Int) -> Void)? = nil
  ) async throws {
    let asset = AVURLAsset(url: videoURL)

    let videoTrack: AVAssetTrack
    let audioTracks: [AVAssetTrack]
    let preferredTransform: CGAffineTransform
    if #available(iOS 16, macOS 13, *) {
      guard let vt = try await asset.loadTracks(withMediaType: .video).first else {
        throw VideoExportError.noVideoTrack
      }
      videoTrack       = vt
      audioTracks      = (try? await asset.loadTracks(withMediaType: .audio)) ?? []
      preferredTransform = (try? await vt.load(.preferredTransform)) ?? .identity
    } else {
      guard let vt = asset.tracks(withMediaType: .video).first else {
        throw VideoExportError.noVideoTrack
      }
      videoTrack         = vt
      audioTracks        = asset.tracks(withMediaType: .audio)
      preferredTransform = vt.preferredTransform
    }

    // Decode overlay image
    let overlayImage: CGImage?
    if let data = overlayImageData {
      #if canImport(AppKit)
      overlayImage = NSBitmapImageRep(data: data)?.cgImage
      #else
      overlayImage = UIImage(data: data)?.cgImage
      #endif
    } else {
      overlayImage = nil
    }

    let exportSize = CGSize(width: exportWidth, height: exportHeight)

    // ── AVAssetWriter ────────────────────────────────────────────────────
    guard let writer = try? AVAssetWriter(url: outputURL, fileType: .mp4) else {
      throw VideoExportError.writerSetupFailed
    }
    let videoSettings: [String: Any] = [
      AVVideoCodecKey: AVVideoCodecType.h264,
      AVVideoWidthKey: exportWidth,
      AVVideoHeightKey: exportHeight,
    ]
    let writerVideoInput = AVAssetWriterInput(mediaType: .video, outputSettings: videoSettings)
    writerVideoInput.expectsMediaDataInRealTime = false
    let adaptor = AVAssetWriterInputPixelBufferAdaptor(
      assetWriterInput: writerVideoInput,
      sourcePixelBufferAttributes: [
        kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA,
        kCVPixelBufferWidthKey as String: exportWidth,
        kCVPixelBufferHeightKey as String: exportHeight,
      ]
    )
    guard writer.canAdd(writerVideoInput) else { throw VideoExportError.writerSetupFailed }
    writer.add(writerVideoInput)

    // Audio passthrough (nil outputSettings = copy encoded bytes unchanged)
    var writerAudioInput: AVAssetWriterInput?
    if audioTracks.first != nil {
      let ai = AVAssetWriterInput(mediaType: .audio, outputSettings: nil)
      ai.expectsMediaDataInRealTime = false
      if writer.canAdd(ai) {
        writer.add(ai)
        writerAudioInput = ai
      }
    }

    // ── AVAssetReader ────────────────────────────────────────────────────
    guard let reader = try? AVAssetReader(asset: asset) else {
      throw VideoExportError.writerSetupFailed
    }
    let videoOutput = AVAssetReaderTrackOutput(
      track: videoTrack,
      outputSettings: [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA]
    )
    videoOutput.alwaysCopiesSampleData = false
    guard reader.canAdd(videoOutput) else { throw VideoExportError.writerSetupFailed }
    reader.add(videoOutput)

    var audioReaderOutput: AVAssetReaderTrackOutput?
    if let srcAudio = audioTracks.first, writerAudioInput != nil {
      let ao = AVAssetReaderTrackOutput(track: srcAudio, outputSettings: nil)
      if reader.canAdd(ao) {
        reader.add(ao)
        audioReaderOutput = ao
      }
    }

    // Estimate total frame count (nominalFrameRate × duration)
    let nominalFPS: Float
    let assetDuration: Double
    if #available(iOS 16, macOS 13, *) {
      nominalFPS = (try? await videoTrack.load(.nominalFrameRate)) ?? 30
      let dur = try? await asset.load(.duration)
      assetDuration = dur.map { CMTimeGetSeconds($0) } ?? 0
    } else {
      nominalFPS = videoTrack.nominalFrameRate
      assetDuration = CMTimeGetSeconds(asset.duration)
    }
    let totalFrames = max(1, Int((Double(nominalFPS) * assetDuration).rounded()))

    guard reader.startReading() else {
      throw VideoExportError.exportFailed(
        reader.error?.localizedDescription ?? "AVAssetReader failed to start")
    }
    writer.startWriting()
    writer.startSession(atSourceTime: .zero)

    let ciContext  = CIContext(options: [.useSoftwareRenderer: false])
    let videoQueue = DispatchQueue(label: "com.shotcraft.export.video")
    let audioQueue = DispatchQueue(label: "com.shotcraft.export.audio")

    // Audio: pump samples on audioQueue (fire-and-forget; finishes independently)
    if let awi = writerAudioInput, let aro = audioReaderOutput {
      awi.requestMediaDataWhenReady(on: audioQueue) {
        while awi.isReadyForMoreMediaData {
          if let buf = aro.copyNextSampleBuffer() {
            awi.append(buf)
          } else {
            awi.markAsFinished()
            return
          }
        }
      }
    }

    // Video: suspend (not block) until all frames are composited and written
    try await withCheckedThrowingContinuation { (cont: CheckedContinuation<Void, Error>) in
      var frameCount = 0
      writerVideoInput.requestMediaDataWhenReady(on: videoQueue) {
        while writerVideoInput.isReadyForMoreMediaData {
          if let sampleBuffer = videoOutput.copyNextSampleBuffer() {
            guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { continue }
            let pts = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)
            if let composited = Self.composite(
              videoFrame: pixelBuffer,
              overlayImage: overlayImage,
              screenshotRect: screenshotRect,
              cornerRadius: cornerRadius,
              contentMode: contentMode,
              preferredTransform: preferredTransform,
              exportSize: exportSize,
              ciContext: ciContext
            ) {
              adaptor.append(composited, withPresentationTime: pts)
            }
            frameCount += 1
            onFrameProgress?(frameCount, totalFrames)
            // If composite() returned nil, skip the frame (don't write a wrong-sized buffer)
          } else {
            // No more frames
            writerVideoInput.markAsFinished()
            writer.finishWriting {
              if writer.status == .failed {
                cont.resume(throwing: VideoExportError.exportFailed(
                  writer.error?.localizedDescription))
              } else {
                cont.resume()
              }
            }
            return
          }
        }
      }
    }
  }

  // MARK: - Per-frame compositing

  /// Draw the static overlay, then draw the video frame into `screenshotRect` on top.
  private nonisolated static func composite(
    videoFrame: CVPixelBuffer,
    overlayImage: CGImage?,
    screenshotRect: CGRect,
    cornerRadius: CGFloat,
    contentMode: ScreenshotContentMode,
    preferredTransform: CGAffineTransform,
    exportSize: CGSize,
    ciContext: CIContext
  ) -> CVPixelBuffer? {
    let width  = Int(exportSize.width)
    let height = Int(exportSize.height)

    var outputBuffer: CVPixelBuffer?
    let attrs: CFDictionary = [
      kCVPixelBufferCGImageCompatibilityKey: true,
      kCVPixelBufferCGBitmapContextCompatibilityKey: true,
    ] as CFDictionary
    guard CVPixelBufferCreate(
      kCFAllocatorDefault, width, height,
      kCVPixelFormatType_32BGRA, attrs, &outputBuffer
    ) == kCVReturnSuccess, let outBuffer = outputBuffer else { return nil }

    CVPixelBufferLockBaseAddress(outBuffer, [])
    defer { CVPixelBufferUnlockBaseAddress(outBuffer, []) }

    guard let ctx = CGContext(
      data: CVPixelBufferGetBaseAddress(outBuffer),
      width: width, height: height,
      bitsPerComponent: 8,
      bytesPerRow: CVPixelBufferGetBytesPerRow(outBuffer),
      space: CGColorSpaceCreateDeviceRGB(),
      bitmapInfo: CGImageAlphaInfo.premultipliedFirst.rawValue
        | CGBitmapInfo.byteOrder32Little.rawValue
    ) else { return nil }

    // ── Coordinate system note ──────────────────────────────────────────
    // Both CGImage sources here have row 0 = visual BOTTOM (macOS / CG native):
    //   • NSBitmapImageRep.cgImage : macOS y-up bitmap, row 0 at visual bottom
    //   • CIContext.createCGImage  : CIImage y=0 at bottom, mapped to row 0
    // In an *unflipped* CGContext (origin: bottom-left, y increasing upward)
    // ctx.draw(image, in: rect) places row 0 at rect.minY (visual bottom) → correct.
    // No global flip is applied.
    // screenshotRect uses top-left coords and must be converted to CG bottom-left.

    // Step 1: static overlay (background + text + device frame + white placeholder)
    if let overlay = overlayImage {
      ctx.draw(overlay, in: CGRect(origin: .zero, size: exportSize))
    }

    // Step 2: video frame drawn on top of the white placeholder.
    if !screenshotRect.isEmpty {
      CVPixelBufferLockBaseAddress(videoFrame, .readOnly)
      defer { CVPixelBufferUnlockBaseAddress(videoFrame, .readOnly) }

      // Apply preferredTransform (handles portrait iPhone video stored rotated),
      // then normalize origin to (0,0).
      let rawCI = CIImage(cvPixelBuffer: videoFrame)
      let rotatedCI = rawCI.transformed(by: preferredTransform)
      let normalized = rotatedCI.transformed(
        by: CGAffineTransform(
          translationX: -rotatedCI.extent.minX,
          y: -rotatedCI.extent.minY))

      if let videoImage = ciContext.createCGImage(normalized, from: normalized.extent) {
        // Convert screenshotRect from top-left coords → CG bottom-left coords
        let destRect = CGRect(
          x: screenshotRect.minX,
          y: exportSize.height - screenshotRect.maxY,
          width: screenshotRect.width,
          height: screenshotRect.height)

        // Compute draw rect respecting aspect ratio
        let vidW  = CGFloat(videoImage.width)
        let vidH  = CGFloat(videoImage.height)
        let scaleX = destRect.width  / vidW
        let scaleY = destRect.height / vidH
        let drawRect: CGRect
        switch contentMode {
        case .fit:
          // Aspect-fit: scale so entire video is visible (letterbox)
          let scale = min(scaleX, scaleY)
          let dw = vidW * scale
          let dh = vidH * scale
          drawRect = CGRect(
            x: destRect.midX - dw / 2,
            y: destRect.midY - dh / 2,
            width: dw,
            height: dh)
        case .fill:
          // Aspect-fill: scale so video fills the rect (crop)
          let scale = max(scaleX, scaleY)
          let dw = vidW * scale
          let dh = vidH * scale
          drawRect = CGRect(
            x: destRect.midX - dw / 2,
            y: destRect.midY - dh / 2,
            width: dw,
            height: dh)
        }

        // Clip to rounded rect then draw
        ctx.saveGState()
        if cornerRadius > 0 {
          let path = CGPath(
            roundedRect: destRect,
            cornerWidth: cornerRadius,
            cornerHeight: cornerRadius,
            transform: nil)
          ctx.addPath(path)
          ctx.clip()
        }
        ctx.draw(videoImage, in: drawRect)
        ctx.restoreGState()
      }
    }

    return outBuffer
  }

  // MARK: - Overlay rendering (must be called on main actor)

  private static func renderOverlayImageData(
    screen: Screen,
    device: DeviceSize,
    languageCode: String,
    exportSize: CGSize,
    videoNaturalSize: CGSize? = nil
  ) -> Data? {
    var view = ExportableScreenView(
      screen: screen, device: device, languageCode: languageCode)
    view.videoNaturalSize = videoNaturalSize
    let renderer = ImageRenderer(content: view)
    renderer.scale = 1.0
    #if canImport(AppKit)
    return renderer.nsImage?.tiffRepresentation
    #else
    return renderer.uiImage?.pngData()
    #endif
  }

  // MARK: - Screenshot placeholder rect & corner radius

  /// Returns the CGRect (top-left coordinate space) of the inner screen area within the
  /// export canvas.  Mirrors the layout computed by ExportableScreenView exactly,
  /// accounting for the device-frame bezel and the sf-scaled outer padding.
  static func screenshotAreaRect(
    screen: Screen, device: DeviceSize, exportSize: CGSize, videoNaturalSize: CGSize? = nil
  ) -> CGRect {
    guard screen.layoutPreset != .textOnly else { return .zero }

    let exportW     = exportSize.width
    let exportH     = exportSize.height
    let baseScreenW = exportW * 0.7
    let baseScreenH = exportH * 0.7

    // Scale factor used by ExportableScreenView for padding
    let sf: CGFloat
    if let ref = ScalingService.referenceDevice(for: device.category) {
      sf = ScalingService.scaleFactor(from: ref, to: device)
    } else {
      sf = 1.0
    }

    // Apply fitFrameToImage if needed (video uses nativeSize, image uses imageData)
    let imageData = screen.screenshotImageData(for: screen.localizedTexts.keys.first ?? "en", category: device.category)
    let fittedDims: (width: CGFloat, height: CGFloat)
    if let vs = videoNaturalSize {
      fittedDims = ScalingService.frameFittingSize(
        nativeSize: vs, boxWidth: baseScreenW, boxHeight: baseScreenH,
        fitToImage: screen.fitFrameToImage)
    } else {
      fittedDims = ScalingService.frameFittingSize(
        imageData: imageData, boxWidth: baseScreenW, boxHeight: baseScreenH,
        fitToImage: screen.fitFrameToImage)
    }
    let fittedW = fittedDims.width
    let fittedH = fittedDims.height

    // Bezel from device frame (shifts the inner screen inward)
    let bezel: CGFloat
    if screen.showDeviceFrame, let spec = device.category.frameSpec?.applying(screen.deviceFrameConfig) {
      bezel = fittedW * spec.bezelRatio
    } else {
      bezel = 0
    }

    let outerPad = CGFloat(ScalingService.scaledPadding(32, factor: sf))
    let x = (exportW - fittedW) / 2.0
    let y: CGFloat

    switch screen.layoutPreset {
    case .textTop:
      // Device frame bottom at exportH - outerPad; inner screen top = frame top + bezel
      y = exportH - outerPad - fittedH - bezel
    case .textBottom:
      // Device frame top at outerPad; inner screen top = outerPad + bezel
      y = outerPad + bezel
    case .screenshotOnly, .textOverlay:
      // Device frame is centered in the canvas
      y = (exportH - fittedH) / 2.0
    case .textOnly:
      return .zero
    }
    return CGRect(x: x, y: y, width: fittedW, height: fittedH)
  }

  /// Corner radius of the inner screen area (= DeviceFrameView's innerCorner).
  /// Used to clip each video frame to match the device frame's rounded corners.
  static func screenshotCornerRadius(
    screen: Screen, device: DeviceSize, exportSize: CGSize, videoNaturalSize: CGSize? = nil
  ) -> CGFloat {
    let baseScreenW = exportSize.width * 0.7
    let baseScreenH = exportSize.height * 0.7

    // Compute fitted width (accounts for fitFrameToImage)
    let fittedW: CGFloat
    if let vs = videoNaturalSize {
      fittedW = ScalingService.frameFittingSize(
        nativeSize: vs, boxWidth: baseScreenW, boxHeight: baseScreenH,
        fitToImage: screen.fitFrameToImage).width
    } else {
      let imageData = screen.screenshotImageData(for: screen.localizedTexts.keys.first ?? "en", category: device.category)
      fittedW = ScalingService.frameFittingSize(
        imageData: imageData, boxWidth: baseScreenW, boxHeight: baseScreenH,
        fitToImage: screen.fitFrameToImage).width
    }

    if screen.showDeviceFrame,
       let spec = device.category.frameSpec?.applying(screen.deviceFrameConfig)
    {
      let bezel       = fittedW * spec.bezelRatio
      let outerCorner = fittedW * spec.cornerRadiusRatio
      return max(outerCorner - bezel, 0)
    }
    // No device frame → match RoundedRectangle(cornerRadius: 16) in screenshotContent
    return 16
  }

  /// Returns the display size of the video at `url`, applying the preferred track
  /// transform so that rotated videos (e.g. portrait iPhone recordings) report
  /// the correct width × height as they appear on screen.
  private static func loadVideoDisplaySize(from url: URL) async -> CGSize? {
    let asset = AVURLAsset(url: url)
    guard let track = try? await asset.loadTracks(withMediaType: .video).first else { return nil }
    guard let naturalSize = try? await track.load(.naturalSize),
          let t = try? await track.load(.preferredTransform) else { return nil }
    let transformed = naturalSize.applying(t)
    let w = abs(transformed.width)
    let h = abs(transformed.height)
    guard w > 0, h > 0 else { return nil }
    return CGSize(width: w, height: h)
  }
}
