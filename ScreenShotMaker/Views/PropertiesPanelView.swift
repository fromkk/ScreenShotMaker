import SwiftUI
import UniformTypeIdentifiers

struct PropertiesPanelView: View {
    @Bindable var state: ProjectState
    @State private var imageLoadError: String?
    @State private var showImageLoadError = false

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

    private var currentLanguageCode: String {
        state.selectedLanguage?.code ?? "en"
    }

    private func localizedTitleBinding(screen: Binding<Screen>) -> Binding<String> {
        Binding(
            get: { screen.wrappedValue.text(for: currentLanguageCode).title },
            set: { newValue in
                var text = screen.wrappedValue.text(for: currentLanguageCode)
                text.title = newValue
                screen.wrappedValue.setText(text, for: currentLanguageCode)
            }
        )
    }

    private func localizedSubtitleBinding(screen: Binding<Screen>) -> Binding<String> {
        Binding(
            get: { screen.wrappedValue.text(for: currentLanguageCode).subtitle },
            set: { newValue in
                var text = screen.wrappedValue.text(for: currentLanguageCode)
                text.subtitle = newValue
                screen.wrappedValue.setText(text, for: currentLanguageCode)
            }
        )
    }

    private func textSection(screen: Binding<Screen>) -> some View {
        PropertySection(title: "Text") {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text(state.selectedLanguage?.displayName ?? "English")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color(nsColor: .controlColor), in: RoundedRectangle(cornerRadius: 4))

                    Spacer()

                    Button {
                        screen.wrappedValue.copyTextToAllLanguages(
                            from: currentLanguageCode,
                            languages: state.project.languages.map(\.code)
                        )
                    } label: {
                        Label("Copy to All", systemImage: "doc.on.doc")
                            .font(.system(size: 10))
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(.secondary)
                }

                PropertyField(label: "Title") {
                    TextField("Enter title", text: localizedTitleBinding(screen: screen))
                        .textFieldStyle(.roundedBorder)
                        .font(.system(size: 12))
                }

                PropertyField(label: "Subtitle") {
                    TextField("Enter subtitle", text: localizedSubtitleBinding(screen: screen))
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
                default: screen.wrappedValue.background = .image(data: Data())
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

        case .image(let data):
            VStack(spacing: 8) {
                if let nsImage = NSImage(data: data) {
                    ZStack(alignment: .topTrailing) {
                        Image(nsImage: nsImage)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(maxHeight: 80)
                            .clipShape(RoundedRectangle(cornerRadius: 6))

                        Button {
                            screen.wrappedValue.background = .image(data: Data())
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 14))
                                .foregroundStyle(.white, .black.opacity(0.6))
                        }
                        .buttonStyle(.plain)
                        .padding(2)
                    }
                }

                Button {
                    openBackgroundImagePicker(screen: screen)
                } label: {
                    Label("Choose Image", systemImage: "photo")
                        .frame(maxWidth: .infinity)
                }
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
                if let imageData = screen.wrappedValue.screenshotImageData,
                   let nsImage = NSImage(data: imageData) {
                    ZStack(alignment: .topTrailing) {
                        Image(nsImage: nsImage)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(maxHeight: 120)
                            .clipShape(RoundedRectangle(cornerRadius: 8))

                        Button {
                            screen.wrappedValue.screenshotImageData = nil
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 16))
                                .foregroundStyle(.white, .black.opacity(0.6))
                        }
                        .buttonStyle(.plain)
                        .padding(4)
                    }
                    .onTapGesture {
                        openImagePicker(screen: screen)
                    }
                } else {
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
                            openImagePicker(screen: screen)
                        }
                }

                Text("PNG or JPEG, max 20MB")
                    .font(.system(size: 10))
                    .foregroundStyle(.tertiary)
            }
        }
        .alert("Image Load Error", isPresented: $showImageLoadError) {
            Button("OK") {}
        } message: {
            Text(imageLoadError ?? "Unknown error")
        }
    }

    private func openBackgroundImagePicker(screen: Binding<Screen>) {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.png, .jpeg]
        panel.allowsMultipleSelection = false
        if panel.runModal() == .OK, let url = panel.url {
            do {
                let data = try ImageLoader.loadImage(from: url)
                screen.wrappedValue.background = .image(data: data)
            } catch {
                imageLoadError = error.localizedDescription
                showImageLoadError = true
            }
        }
    }

    private func openImagePicker(screen: Binding<Screen>) {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.png, .jpeg]
        panel.allowsMultipleSelection = false
        if panel.runModal() == .OK, let url = panel.url {
            do {
                let data = try ImageLoader.loadImage(from: url)
                screen.wrappedValue.screenshotImageData = data
            } catch {
                imageLoadError = error.localizedDescription
                showImageLoadError = true
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
