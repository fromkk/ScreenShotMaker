import Foundation

enum ProjectFileService {
    static func save(_ project: ScreenShotProject, to url: URL) throws {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(project)
        try data.write(to: url, options: .atomic)
    }

    static func load(from url: URL) throws -> ScreenShotProject {
        let data = try Data(contentsOf: url)
        return try JSONDecoder().decode(ScreenShotProject.self, from: data)
    }
}
