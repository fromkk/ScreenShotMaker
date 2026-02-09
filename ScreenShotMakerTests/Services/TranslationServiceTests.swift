import Foundation
import Testing
@preconcurrency import Translation

@testable import ScreenShotMaker

@Suite("TranslationService Tests")
struct TranslationServiceTests {

  @Test("sourceLanguage creates correct Locale.Language")
  func testSourceLanguage() {
    let lang = TranslationService.sourceLanguage(from: "en")
    #expect(lang.minimalIdentifier == "en")
  }

  @Test("targetLanguage creates correct Locale.Language")
  func testTargetLanguage() {
    let lang = TranslationService.targetLanguage(from: "ja")
    #expect(lang.minimalIdentifier == "ja")
  }

  @Test("configuration creates valid TranslationSession.Configuration")
  func testConfiguration() {
    let config = TranslationService.configuration(from: "en", to: "ja")
    #expect(config.source?.minimalIdentifier == "en")
    #expect(config.target?.minimalIdentifier == "ja")
  }

  @Test("configuration with different language pairs produces different configs")
  func testDifferentConfigurations() {
    let config1 = TranslationService.configuration(from: "en", to: "ja")
    let config2 = TranslationService.configuration(from: "en", to: "fr")
    #expect(config1.target?.minimalIdentifier != config2.target?.minimalIdentifier)
  }

  @Test("configuration supports Chinese language codes")
  func testChineseLanguageCodes() {
    let zhHans = TranslationService.configuration(from: "en", to: "zh-Hans")
    let zhHant = TranslationService.configuration(from: "en", to: "zh-Hant")
    #expect(zhHans.target != nil)
    #expect(zhHant.target != nil)
  }
}
