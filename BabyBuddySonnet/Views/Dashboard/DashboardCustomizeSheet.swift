import SwiftUI

struct DashboardCustomizeSheet: View {
    @Environment(\.dismiss) private var dismiss
    private let settings = SettingsService.shared

    var body: some View {
        NavigationStack {
            List {
                ForEach(DashboardWidget.groupedByCategory, id: \.category) { group in
                    Section(group.category.rawValue) {
                        ForEach(group.widgets) { widget in
                            Button {
                                withAnimation {
                                    settings.toggleDashboardWidget(widget)
                                }
                            } label: {
                                HStack(spacing: 12) {
                                    Image(systemName: widget.icon)
                                        .font(.body)
                                        .foregroundStyle(settings.isDashboardWidgetEnabled(widget) ? .blue : .secondary)
                                        .frame(width: 28)

                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(widget.displayName)
                                            .font(.body)
                                            .foregroundStyle(.primary)
                                        Text(widget.description)
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }

                                    Spacer()

                                    Image(systemName: settings.isDashboardWidgetEnabled(widget)
                                        ? "checkmark.circle.fill"
                                        : "circle"
                                    )
                                    .foregroundStyle(
                                        settings.isDashboardWidgetEnabled(widget) ? .blue : .secondary
                                    )
                                    .font(.title3)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Customize Dashboard")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}
