import Foundation

struct Screen: Codable, Identifiable, Hashable {
    var id: UUID
    var name: String
    var layoutPreset: LayoutPreset
    var title: String
    var subtitle: String
    var background: BackgroundStyle
    var screenshotImageData: Data?
    var showDeviceFrame: Bool
    var fontFamily: String
    var fontSize: Double
    var textColorHex: String

    init(
        id: UUID = UUID(),
        name: String = "New Screen",
        layoutPreset: LayoutPreset = .textTop,
        title: String = "",
        subtitle: String = "",
        background: BackgroundStyle = .gradient(startColor: HexColor("#667EEA"), endColor: HexColor("#764BA2")),
        screenshotImageData: Data? = nil,
        showDeviceFrame: Bool = true,
        fontFamily: String = "SF Pro Display",
        fontSize: Double = 28,
        textColorHex: String = "#FFFFFF"
    ) {
        self.id = id
        self.name = name
        self.layoutPreset = layoutPreset
        self.title = title
        self.subtitle = subtitle
        self.background = background
        self.screenshotImageData = screenshotImageData
        self.showDeviceFrame = showDeviceFrame
        self.fontFamily = fontFamily
        self.fontSize = fontSize
        self.textColorHex = textColorHex
    }
}
