import Foundation
import Translation

enum TranslationService {
    static func sourceLanguage(from code: String) -> Locale.Language {
        Locale.Language(identifier: code)
    }

    static func targetLanguage(from code: String) -> Locale.Language {
        Locale.Language(identifier: code)
    }

    static func configuration(from sourceCode: String, to targetCode: String) -> TranslationSession.Configuration {
        TranslationSession.Configuration(
            source: sourceLanguage(from: sourceCode),
            target: targetLanguage(from: targetCode)
        )
    }
}
