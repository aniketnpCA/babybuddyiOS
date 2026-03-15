import SwiftUI

struct DashboardCustomizeSheet: View {
    @Environment(\.dismiss) private var dismiss
    private let settings = SettingsService.shared

    var body: some View {
        NavigationStack {
            List {
                Section {
                    ForEach(DashboardWidget.allCases) { widget in
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
                } header: {
                    Text("Charts & Widgets")
                } footer: {
                    Text("Selected charts will appear on your dashboard below the default cards.")
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
