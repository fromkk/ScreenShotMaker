import SwiftUI

@main
struct ScreenShotMakerApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .frame(minWidth: 960, minHeight: 600)
        }
        .windowStyle(.titleBar)
        .defaultSize(width: 1280, height: 800)
    }
}
