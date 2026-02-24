import SwiftUI

struct QuickActionsGrid: View {
    @Binding var showFeedingForm: Bool
    @Binding var showPumpingForm: Bool
    @Binding var showSleepForm: Bool
    @Binding var showDiaperForm: Bool
    private let settings = SettingsService.shared
    private var theme: PetModeTheme { settings.theme }

    var body: some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible()),
        ], spacing: 12) {
            quickActionButton(
                title: theme.quickActionFeedingLabel,
                icon: theme.feedingTabIcon,
                color: .blue
            ) {
                showFeedingForm = true
            }

            quickActionButton(
                title: theme.quickActionPumpingLabel,
                icon: theme.pumpingTabIcon,
                color: .orange
            ) {
                showPumpingForm = true
            }

            quickActionButton(
                title: theme.quickActionSleepLabel,
                icon: theme.sleepTabIcon,
                color: .purple
            ) {
                showSleepForm = true
            }

            quickActionButton(
                title: theme.quickActionDiaperLabel,
                icon: theme.diaperTabIcon,
                color: .teal
            ) {
                showDiaperForm = true
            }
        }
    }

    private func quickActionButton(
        title: String,
        icon: String,
        color: Color,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title2)
                Text(title)
                    .font(.subheadline.weight(.medium))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(color.opacity(0.15))
            .foregroundStyle(color)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
    }
}
