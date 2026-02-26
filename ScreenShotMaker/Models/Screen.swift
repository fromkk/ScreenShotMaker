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

enum ScreenshotContentMode: String, Codable, CaseIterable {
  case fit
  case fill
}

struct DeviceFrameConfig: Codable, Hashable {
  var frameColorHex: String
  var bezelWidthRatio: Double
  var cornerRadiusRatio: Double
  var showDynamicIsland: Bool
  var dynamicIslandWidthRatio: Double
  var dynamicIslandHeightRatio: Double

  init(
    frameColorHex: String = "#1F1F1F",
    bezelWidthRatio: Double = 1.0,
    cornerRadiusRatio: Double = 1.0,
    showDynamicIsland: Bool = true,
    dynamicIslandWidthRatio: Double = 1.0,
    dynamicIslandHeightRatio: Double = 1.0
  ) {
    self.frameColorHex = frameColorHex
    self.bezelWidthRatio = bezelWidthRatio
    self.cornerRadiusRatio = cornerRadiusRatio
    self.showDynamicIsland = showDynamicIsland
    self.dynamicIslandWidthRatio = dynamicIslandWidthRatio
    self.dynamicIslandHeightRatio = dynamicIslandHeightRatio
  }

  static let `default` = DeviceFrameConfig()
}

struct Screen: Identifiable, Hashable {
  var id: UUID
  var name: String
  var layoutPreset: LayoutPreset
  var localizedTexts: [String: LocalizedText]
  var background: BackgroundStyle
  var screenshotImages: [String: Data]
  /// セキュリティスコープ付き URL ブックマーク Data。キーは "lang-DeviceCategory"。
  var screenshotVideoBookmarks: [String: Data]
  /// ポスターフレームの秒数。キーは "lang-DeviceCategory"。
  var screenshotVideoPosterTimes: [String: Double]

  var showDeviceFrame: Bool
  var isLandscape: Bool
  var fontFamily: String
  var fontSizes: [String: Double]
  var textColorHex: String

  static let defaultFontSize: Double = 96

  /// Get font size for a specific device category
  /// For custom devices, falls back to iPhone font size if not set
  func fontSize(for category: DeviceCategory) -> Double {
    // Try to get the font size for this category first
    if let size = fontSizes[category.rawValue] {
      return size
    }
    
    // If custom category doesn't have a font size set, fall back to iPhone
    if category == .custom {
      return fontSizes["iPhone"] ?? Screen.defaultFontSize
    }
    
    // Default fallback
    return Screen.defaultFontSize
  }

  /// Set font size for a specific device category
  mutating func setFontSize(_ size: Double, for category: DeviceCategory) {
    fontSizes[category.rawValue] = size
  }
  var titleStyle: TextStyle
  var subtitleStyle: TextStyle
  var deviceFrameConfig: DeviceFrameConfig
  var screenshotContentMode: ScreenshotContentMode
  var textToImageSpacing: CGFloat
  var fitFrameToImage: Bool

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

  // MARK: - Per-language, per-device screenshot image

  /// Generate composite key: "languageCode-deviceCategory"
  private func imageKey(language: String, category: DeviceCategory) -> String {
    "\(language)-\(category.rawValue)"
  }

  /// Get screenshot image for specific language and device category
  func screenshotImageData(for language: String, category: DeviceCategory) -> Data? {
    let key = imageKey(language: language, category: category)
    return screenshotImages[key]
  }

  /// Set screenshot image for specific language and device category
  /// Setting an image clears any video assigned to the same key.
  mutating func setScreenshotImageData(
    _ data: Data?, for language: String, category: DeviceCategory
  ) {
    let key = imageKey(language: language, category: category)
    if let data {
      screenshotImages[key] = data
      // Clear video entries for the same key (exclusive)
      screenshotVideoBookmarks.removeValue(forKey: key)
      screenshotVideoPosterTimes.removeValue(forKey: key)
    } else {
      screenshotImages.removeValue(forKey: key)
    }
  }

  // MARK: - Per-language, per-device video

  /// Get video bookmark data for specific language and device category.
  func screenshotVideoBookmarkData(for language: String, category: DeviceCategory) -> Data? {
    let key = imageKey(language: language, category: category)
    return screenshotVideoBookmarks[key]
  }

  /// Returns true if a video is assigned for the given language and device category.
  func hasVideo(for language: String, category: DeviceCategory) -> Bool {
    screenshotVideoBookmarkData(for: language, category: category) != nil
  }

  /// Assign a video (bookmark + poster time) for a specific language and device category.
  /// This clears any image assigned to the same key.
  mutating func setScreenshotVideo(
    bookmarkData: Data, posterTime: Double, for language: String, category: DeviceCategory
  ) {
    let key = imageKey(language: language, category: category)
    screenshotVideoBookmarks[key] = bookmarkData
    screenshotVideoPosterTimes[key] = posterTime
    // Clear image entry for the same key (exclusive)
    screenshotImages.removeValue(forKey: key)
  }

  /// Update poster frame time for a video.
  mutating func setVideoPosterTime(_ time: Double, for language: String, category: DeviceCategory) {
    let key = imageKey(language: language, category: category)
    screenshotVideoPosterTimes[key] = time
  }

  /// Get poster frame time for a video (defaults to 0 if not set).
  func videoPosterTime(for language: String, category: DeviceCategory) -> Double {
    let key = imageKey(language: language, category: category)
    return screenshotVideoPosterTimes[key] ?? 0
  }

  /// Clear both image and video for a specific language and device category.
  mutating func clearScreenshotMedia(for language: String, category: DeviceCategory) {
    let key = imageKey(language: language, category: category)
    screenshotImages.removeValue(forKey: key)
    screenshotVideoBookmarks.removeValue(forKey: key)
    screenshotVideoPosterTimes.removeValue(forKey: key)
  }

  /// Legacy method for backward compatibility (device only)
  @available(*, deprecated, message: "Use screenshotImageData(for:category:) with language code")
  func screenshotImageData(for category: DeviceCategory) -> Data? {
    screenshotImageData(for: "en", category: category)
  }

  /// Legacy method for backward compatibility (device only)
  @available(
    *, deprecated, message: "Use setScreenshotImageData(_:for:category:) with language code"
  )
  mutating func setScreenshotImageData(_ data: Data?, for category: DeviceCategory) {
    setScreenshotImageData(data, for: "en", category: category)
  }

  // Legacy convenience accessor (defaults to iPhone)
  var screenshotImageData: Data? {
    get { screenshotImages["iPhone"] }
    set {
      if let newValue {
        screenshotImages["iPhone"] = newValue
      } else {
        screenshotImages.removeValue(forKey: "iPhone")
      }
    }
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
    background: BackgroundStyle = .gradient(
      startColor: HexColor("#667EEA"), endColor: HexColor("#764BA2")),
    screenshotImages: [String: Data] = [:],
    screenshotVideoBookmarks: [String: Data] = [:],
    screenshotVideoPosterTimes: [String: Double] = [:],
    showDeviceFrame: Bool = true,
    isLandscape: Bool = false,
    fontFamily: String = FontHelper.defaultFontFamily,
    fontSize: Double = Screen.defaultFontSize,
    textColorHex: String = "#FFFFFF",
    titleStyle: TextStyle = TextStyle(isBold: true),
    subtitleStyle: TextStyle = TextStyle(isBold: false),
    deviceFrameConfig: DeviceFrameConfig = .default,
    screenshotContentMode: ScreenshotContentMode = .fit,
    textToImageSpacing: CGFloat = 20.0,
    fitFrameToImage: Bool = false
  ) {
    self.id = id
    self.name = name
    self.layoutPreset = layoutPreset
    self.localizedTexts = ["en": LocalizedText(title: title, subtitle: subtitle)]
    self.background = background
    self.screenshotImages = screenshotImages
    self.screenshotVideoBookmarks = screenshotVideoBookmarks
    self.screenshotVideoPosterTimes = screenshotVideoPosterTimes
    self.showDeviceFrame = showDeviceFrame
    self.isLandscape = isLandscape
    self.fontFamily = fontFamily
    self.fontSizes = fontSize != Screen.defaultFontSize ? DeviceCategory.allCases.reduce(into: [String: Double]()) { $0[$1.rawValue] = fontSize } : [:]
    self.textColorHex = textColorHex
    self.titleStyle = titleStyle
    self.subtitleStyle = subtitleStyle
    self.deviceFrameConfig = deviceFrameConfig
    self.screenshotContentMode = screenshotContentMode
    self.textToImageSpacing = textToImageSpacing
    self.fitFrameToImage = fitFrameToImage
  }
}

// MARK: - Codable with migration support

extension Screen: Codable {
  enum CodingKeys: String, CodingKey {
    case id, name, layoutPreset, localizedTexts, background, screenshotImages
    case showDeviceFrame, isLandscape, fontFamily, fontSize, fontSizes, textColorHex
    case titleStyle, subtitleStyle, deviceFrameConfig, screenshotContentMode
    case textToImageSpacing, fitFrameToImage
    case screenshotVideoBookmarks, screenshotVideoPosterTimes
    // Legacy keys
    case title, subtitle, screenshotImageData
  }

  init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    id = try container.decode(UUID.self, forKey: .id)
    name = try container.decode(String.self, forKey: .name)
    layoutPreset = try container.decode(LayoutPreset.self, forKey: .layoutPreset)
    background = try container.decode(BackgroundStyle.self, forKey: .background)

    // Migration path for screenshot images:
    // 1. Try new format (language-device keys)
    // 2. Fall back to device-only keys (migrate to "en-device")
    // 3. Fall back to legacy single image (migrate to "en-iPhone")
    if let images = try container.decodeIfPresent([String: Data].self, forKey: .screenshotImages) {
      screenshotImages = [:]
      for (key, value) in images {
        if key.contains("-") {
          // Already in new format: "en-iPhone"
          screenshotImages[key] = value
        } else {
          // Old format (device only): "iPhone" → "en-iPhone"
          screenshotImages["en-\(key)"] = value
        }
      }
    } else if let legacyData = try container.decodeIfPresent(
      Data.self, forKey: .screenshotImageData)
    {
      // Very old format (single image) → "en-iPhone"
      screenshotImages = ["en-iPhone": legacyData]
    } else {
      screenshotImages = [:]
    }
    showDeviceFrame = try container.decode(Bool.self, forKey: .showDeviceFrame)
    isLandscape = try container.decodeIfPresent(Bool.self, forKey: .isLandscape) ?? false
    fontFamily = try container.decode(String.self, forKey: .fontFamily)
    // Migration: try new fontSizes dict first, fall back to legacy single fontSize
    if let sizes = try container.decodeIfPresent([String: Double].self, forKey: .fontSizes) {
      fontSizes = sizes
    } else if let legacySize = try container.decodeIfPresent(Double.self, forKey: .fontSize) {
      // Migrate single fontSize to per-device dictionary with value for all categories
      fontSizes = DeviceCategory.allCases.reduce(into: [String: Double]()) { $0[$1.rawValue] = legacySize }
    } else {
      fontSizes = [:]
    }
    textColorHex = try container.decode(String.self, forKey: .textColorHex)
    titleStyle =
      try container.decodeIfPresent(TextStyle.self, forKey: .titleStyle) ?? TextStyle(isBold: true)
    subtitleStyle =
      try container.decodeIfPresent(TextStyle.self, forKey: .subtitleStyle)
      ?? TextStyle(isBold: false)
    deviceFrameConfig =
      try container.decodeIfPresent(DeviceFrameConfig.self, forKey: .deviceFrameConfig) ?? .default
    screenshotContentMode =
      try container.decodeIfPresent(ScreenshotContentMode.self, forKey: .screenshotContentMode)
      ?? .fit
    textToImageSpacing =
      try container.decodeIfPresent(CGFloat.self, forKey: .textToImageSpacing) ?? 20.0
    fitFrameToImage =
      try container.decodeIfPresent(Bool.self, forKey: .fitFrameToImage) ?? false
    screenshotVideoBookmarks =
      try container.decodeIfPresent([String: Data].self, forKey: .screenshotVideoBookmarks) ?? [:]
    screenshotVideoPosterTimes =
      try container.decodeIfPresent([String: Double].self, forKey: .screenshotVideoPosterTimes)
      ?? [:]

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
    if !screenshotImages.isEmpty {
      try container.encode(screenshotImages, forKey: .screenshotImages)
    }
    if !screenshotVideoBookmarks.isEmpty {
      try container.encode(screenshotVideoBookmarks, forKey: .screenshotVideoBookmarks)
    }
    if !screenshotVideoPosterTimes.isEmpty {
      try container.encode(screenshotVideoPosterTimes, forKey: .screenshotVideoPosterTimes)
    }
    try container.encode(showDeviceFrame, forKey: .showDeviceFrame)
    try container.encode(isLandscape, forKey: .isLandscape)
    try container.encode(fontFamily, forKey: .fontFamily)
    try container.encode(fontSizes, forKey: .fontSizes)
    try container.encode(textColorHex, forKey: .textColorHex)
    try container.encode(titleStyle, forKey: .titleStyle)
    try container.encode(subtitleStyle, forKey: .subtitleStyle)
    try container.encode(deviceFrameConfig, forKey: .deviceFrameConfig)
    try container.encode(screenshotContentMode, forKey: .screenshotContentMode)
    try container.encode(textToImageSpacing, forKey: .textToImageSpacing)
    try container.encode(fitFrameToImage, forKey: .fitFrameToImage)
  }
}
