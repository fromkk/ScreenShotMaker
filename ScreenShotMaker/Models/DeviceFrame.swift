import SwiftUI

struct DeviceFrameSpec {
    let bezelRatio: CGFloat        // bezel width as fraction of screen width
    let cornerRadiusRatio: CGFloat // outer corner radius as fraction of screen width
    let frameColor: Color
    let hasNotch: Bool
    let hasHomeIndicator: Bool

    var outerScale: CGSize {
        CGSize(width: 1 + bezelRatio * 2, height: 1 + bezelRatio * 2)
    }
}

extension DeviceCategory {
    var frameSpec: DeviceFrameSpec? {
        switch self {
        case .iPhone:
            return DeviceFrameSpec(
                bezelRatio: 0.03,
                cornerRadiusRatio: 0.08,
                frameColor: Color(white: 0.12),
                hasNotch: true,
                hasHomeIndicator: true
            )
        case .iPad:
            return DeviceFrameSpec(
                bezelRatio: 0.035,
                cornerRadiusRatio: 0.05,
                frameColor: Color(white: 0.15),
                hasNotch: false,
                hasHomeIndicator: true
            )
        case .mac:
            return DeviceFrameSpec(
                bezelRatio: 0.025,
                cornerRadiusRatio: 0.02,
                frameColor: Color(white: 0.15),
                hasNotch: false,
                hasHomeIndicator: false
            )
        default:
            return nil
        }
    }
}

struct DeviceFrameView<Content: View>: View {
    let category: DeviceCategory
    let screenWidth: CGFloat
    let screenHeight: CGFloat
    @ViewBuilder let content: Content

    var body: some View {
        if let spec = category.frameSpec {
            framedContent(spec: spec)
        } else {
            content
                .frame(width: screenWidth, height: screenHeight)
        }
    }

    private func framedContent(spec: DeviceFrameSpec) -> some View {
        let bezel = screenWidth * spec.bezelRatio
        let outerWidth = screenWidth + bezel * 2
        let outerCorner = screenWidth * spec.cornerRadiusRatio
        let innerCorner = max(outerCorner - bezel, 0)

        return ZStack {
            // Outer frame
            RoundedRectangle(cornerRadius: outerCorner)
                .fill(spec.frameColor)
                .frame(width: outerWidth, height: screenHeight + bezel * 2)

            // Screen content
            content
                .frame(width: screenWidth, height: screenHeight)
                .clipShape(RoundedRectangle(cornerRadius: innerCorner))

            // Dynamic Island (iPhone only)
            if spec.hasNotch {
                VStack {
                    Capsule()
                        .fill(.black)
                        .frame(width: screenWidth * 0.25, height: screenWidth * 0.03)
                        .padding(.top, bezel + screenWidth * 0.015)
                    Spacer()
                }
                .frame(width: outerWidth, height: screenHeight + bezel * 2)
            }

            // Home indicator
            if spec.hasHomeIndicator {
                VStack {
                    Spacer()
                    Capsule()
                        .fill(.white.opacity(0.3))
                        .frame(width: screenWidth * 0.3, height: screenWidth * 0.005)
                        .padding(.bottom, bezel + screenWidth * 0.01)
                }
                .frame(width: outerWidth, height: screenHeight + bezel * 2)
            }
        }
        .frame(width: outerWidth, height: screenHeight + bezel * 2)
    }
}
