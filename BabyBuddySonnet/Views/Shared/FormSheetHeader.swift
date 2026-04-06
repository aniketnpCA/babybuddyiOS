import SwiftUI

/// A colored header band for form sheets, inspired by Structured's detail view.
/// Shows a gradient background with the activity icon prominently displayed.
struct FormSheetHeader: View {
    let icon: String
    let color: Color
    let title: String

    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(.white.opacity(0.2))
                    .frame(width: 56, height: 56)
                Image(systemName: icon)
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundStyle(.white)
            }

            Text(title)
                .font(.headline.weight(.bold))
                .foregroundStyle(.white)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(
            LinearGradient(
                colors: [color, color.opacity(0.75)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .listRowInsets(EdgeInsets())
        .listRowBackground(Color.clear)
    }
}
