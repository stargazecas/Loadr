import SwiftUI

struct DownloadRowView: View {
    let task: DownloadTask
    let onCancel: () -> Void
    let onReveal: () -> Void
    let onRetry: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            thumbnail

            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(.headline)
                    .lineLimit(2)

                HStack {
                    statusText
                    if let duration = task.videoInfo?.duration, duration > 0 {
                        Text(verbatim: "·")
                        Text(formatDuration(duration))
                    }
                    if task.status == .downloading {
                        Spacer()
                        Text(verbatim: "\(speed) · \(L10n.timeRemaining(task.eta))")
                            .monospacedDigit()
                    }
                }
                .font(.caption)
                .foregroundStyle(.secondary)

                if task.status == .downloading {
                    ProgressView(value: min(task.percent, 100), total: 100)
                }
            }

            Spacer()

            actionButton
        }
        .padding(.vertical, 4)
    }

    private var title: String {
        guard let info = task.videoInfo else { return task.url }
        return info.title ?? L10n.untitled
    }

    private var speed: String {
        task.speed == "Unknown B/s" ? "—" : task.speed
    }

    @ViewBuilder
    private var actionButton: some View {
        switch task.status {
        case .queued, .fetchingInfo, .downloading:
            rowButton(systemImage: "xmark.circle.fill", help: L10n.cancelDownload, action: onCancel)
        case .completed:
            rowButton(systemImage: "folder.fill", help: L10n.showInFinder, action: onReveal)
        case .failed, .cancelled:
            rowButton(systemImage: "arrow.clockwise.circle.fill", help: L10n.retry, action: onRetry)
        }
    }

    private func rowButton(systemImage: String, help: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .imageScale(.large)
        }
        .buttonStyle(.plain)
        .foregroundStyle(.secondary)
        .help(help)
    }

    @ViewBuilder
    private var thumbnail: some View {
        if let url = task.videoInfo?.thumbnailURL {
            AsyncImage(url: url) { image in
                image.resizable().scaledToFill()
            } placeholder: {
                Color.secondary.opacity(0.2)
            }
            .frame(width: 120, height: 68)
            .clipShape(RoundedRectangle(cornerRadius: 6))
        } else {
            RoundedRectangle(cornerRadius: 6)
                .fill(.secondary.opacity(0.2))
                .frame(width: 120, height: 68)
                .overlay { Image(systemName: "film").foregroundStyle(.secondary) }
        }
    }

    @ViewBuilder
    private var statusText: some View {
        switch task.status {
        case .queued:
            Text(L10n.queued)
        case .fetchingInfo:
            Text(L10n.fetchingInfo)
        case .downloading:
            Text(String(format: "%.1f%%", task.percent))
                .monospacedDigit()
        case .completed:
            Label(L10n.completed, systemImage: "checkmark.circle.fill")
                .foregroundStyle(.green)
        case .cancelled:
            Label(L10n.canceled, systemImage: "xmark.circle")
        case .failed(let error):
            Label(error.message, systemImage: "exclamationmark.triangle.fill")
                .foregroundStyle(.red)
                .lineLimit(3)
        }
    }

    private func formatDuration(_ seconds: Double) -> String {
        let total = Int(seconds)
        let h = total / 3600, m = (total % 3600) / 60, s = total % 60
        return h > 0 ? String(format: "%d:%02d:%02d", h, m, s) : String(format: "%d:%02d", m, s)
    }
}
