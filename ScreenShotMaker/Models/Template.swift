import Foundation

struct Template: Identifiable {
    let id: String
    let name: String
    let description: String
    let screens: [Screen]

    @MainActor func applyTo(_ state: ProjectState) {
        state.project.screens = screens
        state.selectedScreenID = screens.first?.id
        state.hasUnsavedChanges = false
        state.currentFileURL = nil
    }
}

extension Template {
    static let builtIn: [Template] = [
        Template(
            id: "minimal",
            name: "Minimal",
            description: "Clean white background with black text",
            screens: [
                Screen(
                    name: "Screen 1",
                    title: "Your App Title",
                    subtitle: "A brief description of your app",
                    background: .solidColor(HexColor("#FFFFFF")),
                    fontFamily: "SF Pro Display",
                    fontSize: 28,
                    textColorHex: "#000000"
                ),
                Screen(
                    name: "Screen 2",
                    title: "Key Feature",
                    subtitle: "Explain what makes it great",
                    background: .solidColor(HexColor("#FFFFFF")),
                    fontFamily: "SF Pro Display",
                    fontSize: 28,
                    textColorHex: "#000000"
                ),
                Screen(
                    name: "Screen 3",
                    title: "Another Feature",
                    subtitle: "More details here",
                    background: .solidColor(HexColor("#FFFFFF")),
                    fontFamily: "SF Pro Display",
                    fontSize: 28,
                    textColorHex: "#000000"
                ),
            ]
        ),
        Template(
            id: "bold-gradient",
            name: "Bold Gradient",
            description: "Vivid gradient backgrounds with large white text",
            screens: [
                Screen(
                    name: "Screen 1",
                    layoutPreset: .textTop,
                    title: "Your App Title",
                    subtitle: "A brief description",
                    background: .gradient(startColor: HexColor("#667EEA"), endColor: HexColor("#764BA2")),
                    fontSize: 36,
                    textColorHex: "#FFFFFF"
                ),
                Screen(
                    name: "Screen 2",
                    layoutPreset: .textBottom,
                    title: "Key Feature",
                    subtitle: "What makes it special",
                    background: .gradient(startColor: HexColor("#F093FB"), endColor: HexColor("#F5576C")),
                    fontSize: 36,
                    textColorHex: "#FFFFFF"
                ),
                Screen(
                    name: "Screen 3",
                    layoutPreset: .textTop,
                    title: "More Features",
                    subtitle: "Discover the possibilities",
                    background: .gradient(startColor: HexColor("#4FACFE"), endColor: HexColor("#00F2FE")),
                    fontSize: 36,
                    textColorHex: "#FFFFFF"
                ),
            ]
        ),
        Template(
            id: "dark-mode",
            name: "Dark Mode",
            description: "Dark backgrounds with bright text",
            screens: [
                Screen(
                    name: "Screen 1",
                    title: "Your App Title",
                    subtitle: "Designed for the dark side",
                    background: .solidColor(HexColor("#1A1A2E")),
                    fontSize: 28,
                    textColorHex: "#E0E0FF"
                ),
                Screen(
                    name: "Screen 2",
                    title: "Feature Highlight",
                    subtitle: "Beautiful in the dark",
                    background: .solidColor(HexColor("#16213E")),
                    fontSize: 28,
                    textColorHex: "#E0E0FF"
                ),
                Screen(
                    name: "Screen 3",
                    title: "One More Thing",
                    subtitle: "You'll love it",
                    background: .solidColor(HexColor("#0F3460")),
                    fontSize: 28,
                    textColorHex: "#E0E0FF"
                ),
            ]
        ),
        Template(
            id: "screenshot-focus",
            name: "Screenshot Focus",
            description: "Maximizes screenshot area with minimal UI",
            screens: [
                Screen(
                    name: "Screen 1",
                    layoutPreset: .screenshotOnly,
                    background: .solidColor(HexColor("#F5F5F7")),
                    showDeviceFrame: true
                ),
                Screen(
                    name: "Screen 2",
                    layoutPreset: .screenshotOnly,
                    background: .solidColor(HexColor("#F5F5F7")),
                    showDeviceFrame: true
                ),
                Screen(
                    name: "Screen 3",
                    layoutPreset: .screenshotOnly,
                    background: .solidColor(HexColor("#F5F5F7")),
                    showDeviceFrame: true
                ),
            ]
        ),
        Template(
            id: "professional",
            name: "Professional",
            description: "Elegant gray gradients with bottom text",
            screens: [
                Screen(
                    name: "Screen 1",
                    layoutPreset: .textBottom,
                    title: "Your App Title",
                    subtitle: "Professional grade solution",
                    background: .gradient(startColor: HexColor("#E8E8E8"), endColor: HexColor("#C0C0C0")),
                    fontSize: 28,
                    textColorHex: "#333333"
                ),
                Screen(
                    name: "Screen 2",
                    layoutPreset: .textBottom,
                    title: "Enterprise Ready",
                    subtitle: "Built for teams",
                    background: .gradient(startColor: HexColor("#D4D4D4"), endColor: HexColor("#A8A8A8")),
                    fontSize: 28,
                    textColorHex: "#333333"
                ),
                Screen(
                    name: "Screen 3",
                    layoutPreset: .textBottom,
                    title: "Get Started",
                    subtitle: "Try it free today",
                    background: .gradient(startColor: HexColor("#E0E0E0"), endColor: HexColor("#B0B0B0")),
                    fontSize: 28,
                    textColorHex: "#333333"
                ),
            ]
        ),
    ]
}
