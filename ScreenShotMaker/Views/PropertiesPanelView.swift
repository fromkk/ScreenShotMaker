import SwiftUI

struct PropertiesPanelView: View {
    @Bindable var state: ProjectState

    private var selectedScreenBinding: Binding<Screen>? {
        guard let id = state.selectedScreenID,
              let index = state.project.screens.firstIndex(where: { $0.id == id }) else {
            return nil
        }
        return $state.project.screens[index]
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                if let screen = selectedScreenBinding {
                    layoutSection(screen: screen)
                    Divider()
                    textSection(screen: screen)
                    Divider()
                    backgroundSection(screen: screen)
                    Divider()
                    deviceFrameSection(screen: screen)
                    Divider()
                    screenshotImageSection(screen: screen)
                } else {
                    noSelectionView
                }
            }
        }
        .background(Color(nsColor: .controlBackgroundColor))
        .overlay(alignment: .leading) {
            Divider()
        }
    }

    // MARK: - Layout Section

    private func layoutSection(screen: Binding<Screen>) -> some View {
        PropertySection(title: "Layout") {
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                ForEach(LayoutPreset.allCases) { preset in
                    LayoutPresetButton(
                        preset: preset,
                        isSelected: screen.wrappedValue.layoutPreset == preset
                    ) {
                        screen.wrappedValue.layoutPreset = preset
                    }
                }
            }
        }
    }

    // MARK: - Text Section

    private func textSection(screen: Binding<Screen>) -> some View {
        PropertySection(title: "Text") {
            VStack(alignment: .leading, spacing: 10) {
                PropertyField(label: "Title") {
                    TextField("Enter title", text: screen.title)
                        .textFieldStyle(.roundedBorder)
                        .font(.system(size: 12))
                }

                PropertyField(label: "Subtitle") {
                    TextField("Enter subtitle", text: screen.subtitle)
                        .textFieldStyle(.roundedBorder)
                        .font(.system(size: 12))
                }

                HStack(spacing: 8) {
                    PropertyField(label: "Font") {
                        TextField("Font", text: screen.fontFamily)
                            .textFieldStyle(.roundedBorder)
                            .font(.system(size: 12))
                    }

                    PropertyField(label: "Size") {
                        TextField("Size", value: screen.fontSize, format: .number)
                            .textFieldStyle(.roundedBorder)
                            .font(.system(size: 12))
                            .frame(width: 60)
                    }
                }

                PropertyField(label: "Color") {
                    HStack(spacing: 6) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color(hex: screen.wrappedValue.textColorHex))
                            .frame(width: 24, height: 24)
                            .overlay(
                                RoundedRectangle(cornerRadius: 4)
                                    .strokeBorder(Color(nsColor: .separatorColor))
                            )
                        TextField("Hex", text: screen.textColorHex)
                            .textFieldStyle(.roundedBorder)
                            .font(.system(size: 11, design: .monospaced))
                    }
                }
            }
        }
    }

    // MARK: - Background Section

    private func backgroundSection(screen: Binding<Screen>) -> some View {
        PropertySection(title: "Background") {
            VStack(alignment: .leading, spacing: 10) {
                backgroundTypePicker(screen: screen)
                backgroundColorFields(screen: screen)
            }
        }
    }

    @ViewBuilder
    private func backgroundTypePicker(screen: Binding<Screen>) -> some View {
        Picker("Type", selection: Binding(
            get: { backgroundTypeIndex(screen.wrappedValue.background) },
            set: { newIndex in
                switch newIndex {
                case 0: screen.wrappedValue.background = .solidColor(HexColor("#667EEA"))
                case 1: screen.wrappedValue.background = .gradient(startColor: HexColor("#667EEA"), endColor: HexColor("#764BA2"))
                default: screen.wrappedValue.background = .image(path: "")
                }
            }
        )) {
            Text("Color").tag(0)
            Text("Gradient").tag(1)
            Text("Image").tag(2)
        }
        .pickerStyle(.segmented)
    }

    @ViewBuilder
    private func backgroundColorFields(screen: Binding<Screen>) -> some View {
        switch screen.wrappedValue.background {
        case .solidColor(let hexColor):
            colorField(label: "Color", hex: hexColor.hex) { newHex in
                screen.wrappedValue.background = .solidColor(HexColor(newHex))
            }

        case .gradient(let start, let end):
            HStack(spacing: 8) {
                colorField(label: "Start", hex: start.hex) { newHex in
                    screen.wrappedValue.background = .gradient(startColor: HexColor(newHex), endColor: end)
                }
                colorField(label: "End", hex: end.hex) { newHex in
                    screen.wrappedValue.background = .gradient(startColor: start, endColor: HexColor(newHex))
                }
            }

        case .image:
            Button {
                // TODO: Image picker
            } label: {
                Label("Choose Image", systemImage: "photo")
                    .frame(maxWidth: .infinity)
            }
        }
    }

    private func colorField(label: String, hex: String, onChange: @escaping (String) -> Void) -> some View {
        PropertyField(label: label) {
            HStack(spacing: 6) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color(hex: hex))
                    .frame(width: 18, height: 18)
                    .overlay(
                        RoundedRectangle(cornerRadius: 4)
                            .strokeBorder(Color(nsColor: .separatorColor))
                    )
                TextField("Hex", text: Binding(
                    get: { hex },
                    set: { onChange($0) }
                ))
                .textFieldStyle(.roundedBorder)
                .font(.system(size: 11, design: .monospaced))
            }
        }
    }

    private func backgroundTypeIndex(_ style: BackgroundStyle) -> Int {
        switch style {
        case .solidColor: 0
        case .gradient: 1
        case .image: 2
        }
    }

    // MARK: - Device Frame Section

    private func deviceFrameSection(screen: Binding<Screen>) -> some View {
        PropertySection(title: "Device Frame") {
            Toggle("Show Device Frame", isOn: screen.showDeviceFrame)
                .font(.system(size: 12))
        }
    }

    // MARK: - Screenshot Image Section

    private func screenshotImageSection(screen: Binding<Screen>) -> some View {
        PropertySection(title: "Screenshot Image") {
            VStack(spacing: 8) {
                RoundedRectangle(cornerRadius: 8)
                    .strokeBorder(style: StrokeStyle(lineWidth: 1, dash: [6, 4]))
                    .foregroundStyle(.secondary)
                    .frame(height: 80)
                    .overlay {
                        VStack(spacing: 6) {
                            Image(systemName: "arrow.up.doc")
                                .font(.title3)
                                .foregroundStyle(.secondary)
                            Text("Drop image or click to browse")
                                .font(.system(size: 11))
                                .foregroundStyle(.secondary)
                        }
                    }
                    .onTapGesture {
                        // TODO: File picker
                    }

                Text("PNG or JPEG, max 20MB")
                    .font(.system(size: 10))
                    .foregroundStyle(.tertiary)
            }
        }
    }

    // MARK: - No Selection

    private var noSelectionView: some View {
        VStack(spacing: 8) {
            Spacer()
            Image(systemName: "sidebar.right")
                .font(.largeTitle)
                .foregroundStyle(.tertiary)
            Text("Select a screen to edit")
                .font(.callout)
                .foregroundStyle(.secondary)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
}

// MARK: - Helper Views

private struct PropertySection<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.primary)
            content
        }
        .padding(16)
    }
}

private struct PropertyField<Content: View>: View {
    let label: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(.secondary)
            content
        }
    }
}

private struct LayoutPresetButton: View {
    let preset: LayoutPreset
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                presetIcon
                    .frame(height: 48)
                    .frame(maxWidth: .infinity)
                    .background(Color(nsColor: .controlBackgroundColor))
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .strokeBorder(isSelected ? Color.accentColor : Color(nsColor: .separatorColor), lineWidth: isSelected ? 2 : 1)
                    )

                Text(preset.displayName)
                    .font(.system(size: 9, weight: isSelected ? .medium : .regular))
                    .foregroundStyle(isSelected ? Color.accentColor : .secondary)
            }
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private var presetIcon: some View {
        VStack(spacing: 3) {
            switch preset {
            case .textTop:
                RoundedRectangle(cornerRadius: 2).fill(isSelected ? Color.accentColor : .secondary).frame(height: 6)
                RoundedRectangle(cornerRadius: 2).fill(Color(nsColor: .separatorColor)).frame(maxHeight: .infinity)

            case .textOverlay:
                ZStack {
                    RoundedRectangle(cornerRadius: 2).fill(Color(nsColor: .separatorColor))
                    RoundedRectangle(cornerRadius: 2).fill(isSelected ? Color.accentColor.opacity(0.6) : .secondary.opacity(0.5)).frame(width: 28, height: 6)
                }

            case .textBottom:
                RoundedRectangle(cornerRadius: 2).fill(Color(nsColor: .separatorColor)).frame(maxHeight: .infinity)
                RoundedRectangle(cornerRadius: 2).fill(isSelected ? Color.accentColor : .secondary).frame(height: 6)

            case .textOnly:
                Spacer()
                RoundedRectangle(cornerRadius: 2).fill(isSelected ? Color.accentColor : .secondary).frame(height: 6)
                RoundedRectangle(cornerRadius: 2).fill(isSelected ? Color.accentColor.opacity(0.5) : .secondary.opacity(0.5)).frame(width: 28, height: 4)
                Spacer()

            case .screenshotOnly:
                RoundedRectangle(cornerRadius: 2).fill(Color(nsColor: .separatorColor)).frame(maxHeight: .infinity)
            }
        }
        .padding(6)
    }
}
