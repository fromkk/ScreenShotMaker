import Foundation

struct LocalizedText: Codable, Hashable {
    var title: String
    var subtitle: String

    init(title: String = "", subtitle: String = "") {
        self.title = title
        self.subtitle = subtitle
    }
}

struct TextStyle: Codable, Hashable {
    var isBold: Bool
    var isItalic: Bool
    var alignment: TextStyleAlignment

    enum TextStyleAlignment: String, Codable, CaseIterable {
        case leading, center, trailing
    }

    init(isBold: Bool = true, isItalic: Bool = false, alignment: TextStyleAlignment = .center) {
        self.isBold = isBold
        self.isItalic = isItalic
        self.alignment = alignment
    }
}

struct Screen: Identifiable, Hashable {
    var id: UUID
    var name: String
    var layoutPreset: LayoutPreset
    var localizedTexts: [String: LocalizedText]
    var background: BackgroundStyle
    var screenshotImageData: Data?
    var showDeviceFrame: Bool
    var isLandscape: Bool
    var fontFamily: String
    var fontSize: Double
    var textColorHex: String
    var titleStyle: TextStyle
    var subtitleStyle: TextStyle

    // Convenience accessors for default language ("en")
    var title: String {
        get { localizedTexts["en"]?.title ?? "" }
        set {
            var text = localizedTexts["en"] ?? LocalizedText()
            text.title = newValue
            localizedTexts["en"] = text
        }
    }

    var subtitle: String {
        get { localizedTexts["en"]?.subtitle ?? "" }
        set {
            var text = localizedTexts["en"] ?? LocalizedText()
            text.subtitle = newValue
            localizedTexts["en"] = text
        }
    }

    func text(for languageCode: String) -> LocalizedText {
        localizedTexts[languageCode] ?? LocalizedText()
    }

    mutating func setText(_ localizedText: LocalizedText, for languageCode: String) {
        localizedTexts[languageCode] = localizedText
    }

    mutating func copyTextToAllLanguages(from languageCode: String, languages: [String]) {
        let source = text(for: languageCode)
        for lang in languages {
            localizedTexts[lang] = source
        }
    }

    init(
        id: UUID = UUID(),
        name: String = "New Screen",
        layoutPreset: LayoutPreset = .textTop,
        title: String = "",
        subtitle: String = "",
        background: BackgroundStyle = .gradient(startColor: HexColor("#667EEA"), endColor: HexColor("#764BA2")),
        screenshotImageData: Data? = nil,
        showDeviceFrame: Bool = true,
        isLandscape: Bool = false,
        fontFamily: String = "SF Pro Display",
        fontSize: Double = 28,
        textColorHex: String = "#FFFFFF",
        titleStyle: TextStyle = TextStyle(isBold: true),
        subtitleStyle: TextStyle = TextStyle(isBold: false)
    ) {
        self.id = id
        self.name = name
        self.layoutPreset = layoutPreset
        self.localizedTexts = ["en": LocalizedText(title: title, subtitle: subtitle)]
        self.background = background
        self.screenshotImageData = screenshotImageData
        self.showDeviceFrame = showDeviceFrame
        self.isLandscape = isLandscape
        self.fontFamily = fontFamily
        self.fontSize = fontSize
        self.textColorHex = textColorHex
        self.titleStyle = titleStyle
        self.subtitleStyle = subtitleStyle
    }
}

// MARK: - Codable with migration support

extension Screen: Codable {
    enum CodingKeys: String, CodingKey {
        case id, name, layoutPreset, localizedTexts, background, screenshotImageData
        case showDeviceFrame, isLandscape, fontFamily, fontSize, textColorHex
        case titleStyle, subtitleStyle
        // Legacy keys
        case title, subtitle
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        layoutPreset = try container.decode(LayoutPreset.self, forKey: .layoutPreset)
        background = try container.decode(BackgroundStyle.self, forKey: .background)
        screenshotImageData = try container.decodeIfPresent(Data.self, forKey: .screenshotImageData)
        showDeviceFrame = try container.decode(Bool.self, forKey: .showDeviceFrame)
        isLandscape = try container.decodeIfPresent(Bool.self, forKey: .isLandscape) ?? false
        fontFamily = try container.decode(String.self, forKey: .fontFamily)
        fontSize = try container.decode(Double.self, forKey: .fontSize)
        textColorHex = try container.decode(String.self, forKey: .textColorHex)
        titleStyle = try container.decodeIfPresent(TextStyle.self, forKey: .titleStyle) ?? TextStyle(isBold: true)
        subtitleStyle = try container.decodeIfPresent(TextStyle.self, forKey: .subtitleStyle) ?? TextStyle(isBold: false)

        // Try new format first, fall back to legacy
        if let texts = try? container.decode([String: LocalizedText].self, forKey: .localizedTexts) {
            localizedTexts = texts
        } else {
            let legacyTitle = try container.decodeIfPresent(String.self, forKey: .title) ?? ""
            let legacySubtitle = try container.decodeIfPresent(String.self, forKey: .subtitle) ?? ""
            localizedTexts = ["en": LocalizedText(title: legacyTitle, subtitle: legacySubtitle)]
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(layoutPreset, forKey: .layoutPreset)
        try container.encode(localizedTexts, forKey: .localizedTexts)
        try container.encode(background, forKey: .background)
        try container.encodeIfPresent(screenshotImageData, forKey: .screenshotImageData)
        try container.encode(showDeviceFrame, forKey: .showDeviceFrame)
        try container.encode(isLandscape, forKey: .isLandscape)
        try container.encode(fontFamily, forKey: .fontFamily)
        try container.encode(fontSize, forKey: .fontSize)
        try container.encode(textColorHex, forKey: .textColorHex)
        try container.encode(titleStyle, forKey: .titleStyle)
        try container.encode(subtitleStyle, forKey: .subtitleStyle)
    }
}
