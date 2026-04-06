import SwiftUI

struct OfflineStatusBanner: View {
    private let offlineQueue = OfflineQueueService.shared

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: offlineQueue.isOnline ? "arrow.triangle.2.circlepath" : "wifi.slash")
                .font(.subheadline)
                .foregroundStyle(offlineQueue.isOnline ? .orange : .red)

            VStack(alignment: .leading, spacing: 2) {
                if !offlineQueue.isOnline {
                    Text("Offline Mode")
                        .font(.subheadline.weight(.medium))
                    Text("Changes will sync when back online")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else if offlineQueue.hasPendingOperations {
                    Text("\(offlineQueue.pendingCount) pending sync")
                        .font(.subheadline.weight(.medium))
                    if offlineQueue.failedCount > 0 {
                        Text("\(offlineQueue.failedCount) failed \u{2014} check Settings")
                            .font(.caption)
                            .foregroundStyle(.red)
                    }
                }
            }

            Spacer()

            if offlineQueue.isOnline && offlineQueue.hasPendingOperations {
                Button {
                    Task {
                        await offlineQueue.processQueue()
                    }
                } label: {
                    Text("Sync")
                        .font(.caption.weight(.medium))
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }
        }
        .padding(12)
        .background(offlineQueue.isOnline ? Color.orange.opacity(0.1) : Color.red.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}
