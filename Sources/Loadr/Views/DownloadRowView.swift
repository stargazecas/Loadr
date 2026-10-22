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
                Text(task.videoInfo?.title ?? task.url)
                    .font(.headline)
                    .lineLimit(2)

                HStack {
                    statusText
                    if let duration = task.videoInfo?.duration, duration > 0 {
                        Text("·")
                        Text(formatDuration(duration))
                    }
                    if task.status == .downloading {
                        Spacer()
                        Text("\(task.speed) · ETA \(task.eta)")
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

            if task.status == .downloading || task.status == .fetchingInfo || task.status == .queued {
                Button(action: onCancel) {
                    Image(systemName: "xmark.circle.fill")
                        .imageScale(.large)
                }
                .buttonStyle(.plain)
                .foregroundStyle(.secondary)
                .help("Cancelar descarga")
            } else if task.status == .completed {
                Button(action: onReveal) {
                    Image(systemName: "folder.fill")
                        .imageScale(.large)
                }
                .buttonStyle(.plain)
                .foregroundStyle(.secondary)
                .help("Ver archivo")
            } else if case .failed = task.status {
                Button(action: onRetry) {
                    Image(systemName: "arrow.clockwise.circle.fill")
                        .imageScale(.large)
                }
                .buttonStyle(.plain)
                .foregroundStyle(.secondary)
                .help("Reintentar")
            }
        }
        .padding(.vertical, 4)
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
            Text("En cola")
        case .fetchingInfo:
            Text("Obteniendo información…")
        case .downloading:
            Text(String(format: "%.1f%%", task.percent))
                .monospacedDigit()
        case .completed:
            Label("Completado", systemImage: "checkmark.circle.fill")
                .foregroundStyle(.green)
        case .failed(let message):
            Label(message, systemImage: "exclamationmark.triangle.fill")
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
