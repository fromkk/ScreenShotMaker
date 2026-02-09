import Foundation

enum ProjectFileService {
  static func save(_ project: ScreenShotProject, to url: URL) throws {
    let data = try encode(project)
    try data.write(to: url, options: .atomic)
  }

  static func encode(_ project: ScreenShotProject) throws -> Data {
    let encoder = JSONEncoder()
    encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
    return try encoder.encode(project)
  }

  static func load(from url: URL) throws -> ScreenShotProject {
    let data = try Data(contentsOf: url)
    return try JSONDecoder().decode(ScreenShotProject.self, from: data)
  }
}
