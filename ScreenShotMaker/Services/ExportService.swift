import SwiftUI

enum ExportFormat: String, CaseIterable {
    case png
    case jpeg

    var fileExtension: String { rawValue }
}

struct ExportableScreenView: View {
    let screen: Screen
    let device: DeviceSize

    var body: some View {
        backgroundView
            .frame(width: CGFloat(device.portraitWidth), height: CGFloat(device.portraitHeight))
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
        case .image:
            Rectangle().fill(Color.gray.opacity(0.3))
        }
    }

    @ViewBuilder
    private var layoutContent: some View {
        switch screen.layoutPreset {
        case .textTop:
            VStack(spacing: 24) {
                textContent
                    .padding(.top, 60)
                screenshotView
                Spacer(minLength: 0)
            }
            .padding(32)

        case .textOverlay:
            ZStack {
                screenshotView
                    .padding(40)
                VStack {
                    Spacer()
                    textContent
                        .padding()
                        .background(.black.opacity(0.5), in: RoundedRectangle(cornerRadius: 16))
                        .padding()
                }
            }

        case .textBottom:
            VStack(spacing: 24) {
                Spacer(minLength: 0)
                screenshotView
                textContent
                    .padding(.bottom, 60)
            }
            .padding(32)

        case .textOnly:
            VStack(spacing: 16) {
                Spacer()
                textContent
                Spacer()
            }
            .padding(48)

        case .screenshotOnly:
            screenshotView
                .padding(40)
        }
    }

    private var textContent: some View {
        VStack(spacing: 12) {
            if !screen.title.isEmpty {
                Text(screen.title)
                    .font(.system(size: screen.fontSize, weight: .bold))
                    .foregroundStyle(Color(hex: screen.textColorHex))
                    .multilineTextAlignment(.center)
            }
            if !screen.subtitle.isEmpty {
                Text(screen.subtitle)
                    .font(.system(size: screen.fontSize * 0.6, weight: .regular))
                    .foregroundStyle(Color(hex: screen.textColorHex).opacity(0.8))
                    .multilineTextAlignment(.center)
            }
        }
    }

    private var screenshotView: some View {
        RoundedRectangle(cornerRadius: 16)
            .fill(.white)
            .overlay {
                if let imageData = screen.screenshotImageData,
                   let nsImage = NSImage(data: imageData) {
                    Image(nsImage: nsImage)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                }
            }
    }
}

@MainActor
enum ExportService {
    static func exportScreen(_ screen: Screen, device: DeviceSize, format: ExportFormat) -> Data? {
        let view = ExportableScreenView(screen: screen, device: device)
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
}
