import SwiftUI

@Observable
final class ExportProgressState {
    var isExporting: Bool = false
    var completed: Int = 0
    var total: Int = 0
    var currentItem: String = ""
    var errors: [String] = []
    var isCancelled: Bool = false

    var isFinished: Bool {
        !isExporting && total > 0
    }

    var progress: Double {
        guard total > 0 else { return 0 }
        return Double(completed) / Double(total)
    }

    func reset() {
        isExporting = false
        completed = 0
        total = 0
        currentItem = ""
        errors = []
        isCancelled = false
    }
}

struct ExportProgressView: View {
    let progressState: ExportProgressState
    let outputDirectory: URL?
    let onDismiss: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            if progressState.isExporting {
                exportingView
            } else if progressState.isFinished {
                completedView
            }
        }
        .padding(24)
        .frame(width: 400)
    }

    private var exportingView: some View {
        VStack(spacing: 12) {
            Text("Exporting Screenshots...")
                .font(.headline)

            ProgressView(value: progressState.progress)
                .progressViewStyle(.linear)

            Text("\(progressState.completed) / \(progressState.total)")
                .font(.system(size: 12, design: .monospaced))
                .foregroundStyle(.secondary)

            if !progressState.currentItem.isEmpty {
                Text(progressState.currentItem)
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }

            Button("Cancel") {
                progressState.isCancelled = true
            }
            .buttonStyle(.bordered)
        }
    }

    private var completedView: some View {
        VStack(spacing: 12) {
            if progressState.isCancelled {
                Image(systemName: "exclamationmark.circle")
                    .font(.largeTitle)
                    .foregroundStyle(.orange)
                Text("Export Cancelled")
                    .font(.headline)
                Text("\(progressState.completed) of \(progressState.total) exported")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            } else if progressState.errors.isEmpty {
                Image(systemName: "checkmark.circle")
                    .font(.largeTitle)
                    .foregroundStyle(.green)
                Text("Export Complete")
                    .font(.headline)
                Text("\(progressState.completed) screenshots exported")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            } else {
                Image(systemName: "exclamationmark.triangle")
                    .font(.largeTitle)
                    .foregroundStyle(.orange)
                Text("Export Completed with Errors")
                    .font(.headline)
                Text("\(progressState.completed - progressState.errors.count) succeeded, \(progressState.errors.count) failed")
                    .font(.callout)
                    .foregroundStyle(.secondary)

                ScrollView {
                    VStack(alignment: .leading, spacing: 4) {
                        ForEach(progressState.errors, id: \.self) { error in
                            Text(error)
                                .font(.system(size: 10))
                                .foregroundStyle(.red)
                        }
                    }
                }
                .frame(maxHeight: 100)
            }

            HStack(spacing: 12) {
                if let outputDirectory {
                    Button("Open Folder") {
                        NSWorkspace.shared.open(outputDirectory)
                    }
                    .buttonStyle(.borderedProminent)
                }

                Button("Done") {
                    onDismiss()
                }
                .buttonStyle(.bordered)
            }
        }
    }
}
