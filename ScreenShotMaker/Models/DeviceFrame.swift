import SwiftUI

struct DeviceFrameSpec {
  let bezelRatio: CGFloat  // bezel width as fraction of screen width
  let cornerRadiusRatio: CGFloat  // outer corner radius as fraction of screen width
  let frameColor: Color
  let hasNotch: Bool
  let hasHomeIndicator: Bool

  var outerScale: CGSize {
    CGSize(width: 1 + bezelRatio * 2, height: 1 + bezelRatio * 2)
  }

  func applying(_ config: DeviceFrameConfig) -> DeviceFrameSpec {
    DeviceFrameSpec(
      bezelRatio: bezelRatio * config.bezelWidthRatio,
      cornerRadiusRatio: cornerRadiusRatio * config.cornerRadiusRatio,
      frameColor: Color(hex: config.frameColorHex),
      hasNotch: hasNotch,
      hasHomeIndicator: hasHomeIndicator
    )
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
    case .custom:
      // Custom devices get a simple, minimal frame
      return DeviceFrameSpec(
        bezelRatio: 0.05,
        cornerRadiusRatio: 0.05,
        frameColor: .black,
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
  var config: DeviceFrameConfig = .default
  @ViewBuilder let content: Content

  var body: some View {
    if let baseSpec = category.frameSpec {
      let spec = config == .default ? baseSpec : baseSpec.applying(config)
      framedContent(spec: spec)
    } else {
      content
        .frame(width: screenWidth, height: screenHeight)
    }
  }

  private func framedContent(spec: DeviceFrameSpec) -> some View {
    let bezel = screenWidth * spec.bezelRatio
    let outerWidth = screenWidth + bezel * 2
    let outerHeight = screenHeight + bezel * 2
    let outerCorner = screenWidth * spec.cornerRadiusRatio
    let innerCorner = max(outerCorner - bezel, 0)

    return ZStack {
      // Bottom: solid frame color fills the entire outer area (including corners).
      // This eliminates any transparent gap because there is no inner clipShape—
      // the donut on top paints over protruding content pixels at the corners.
      spec.frameColor

      // Middle: screen content, intentionally NOT clipped.
      // Corner areas that extend beyond innerCorner will be covered by the donut below.
      content
        .frame(width: screenWidth, height: screenHeight)

      // Top: donut covers bezel + bleeds over content corners with solid frame color.
      // Because content has no clip, there are no anti-aliased transparent pixels
      // for the background to leak through.
      Canvas { ctx, size in
        let outer = Path(
          roundedRect: CGRect(origin: .zero, size: size),
          cornerRadius: outerCorner,
          style: .circular
        )
        let inner = Path(
          roundedRect: CGRect(
            x: bezel, y: bezel,
            width: screenWidth, height: screenHeight
          ),
          cornerRadius: innerCorner,
          style: .circular
        )
        var donut = outer
        donut.addPath(inner)
        ctx.fill(donut, with: .color(spec.frameColor), style: FillStyle(eoFill: true))
      }
      .frame(width: outerWidth, height: outerHeight)

      // Dynamic Island (iPhone only)
      if spec.hasNotch && config.showDynamicIsland {
        VStack {
          Capsule()
            .fill(.black)
            .frame(
              width: screenWidth * 0.25 * config.dynamicIslandWidthRatio,
              height: screenWidth * 0.03 * config.dynamicIslandHeightRatio
            )
            .padding(.top, bezel + screenWidth * 0.015)
          Spacer()
        }
        .frame(width: outerWidth, height: outerHeight)
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
        .frame(width: outerWidth, height: outerHeight)
      }
    }
    .frame(width: outerWidth, height: outerHeight)
    // Clip the entire composite to the outer rounded rect so content cannot
    // bleed outside the device frame boundary.
    .clipShape(RoundedRectangle(cornerRadius: outerCorner, style: .circular))
  }
}
