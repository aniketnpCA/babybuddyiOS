import SwiftUI

struct FloatingActionButton: View {
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: "plus")
                .font(.title2.weight(.semibold))
                .foregroundStyle(.white)
                .frame(width: 56, height: 56)
                .background(color, in: Circle())
                .shadow(color: color.opacity(0.4), radius: 8, x: 0, y: 4)
        }
        .padding(.trailing, 20)
        .padding(.bottom, 20)
    }
}

// MARK: - Expandable FAB with fan-out menu

nonisolated struct FABItem: Sendable {
    let label: String
    let icon: String
    let color: Color
    let action: @Sendable @MainActor () -> Void
}

struct ExpandableFloatingActionButton: View {
    let items: [FABItem]
    @State private var isExpanded = false

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            // Dimming backdrop
            if isExpanded {
                Color.black.opacity(0.3)
                    .ignoresSafeArea()
                    .onTapGesture { withAnimation(.spring(duration: 0.3)) { isExpanded = false } }
                    .transition(.opacity)
            }

            // Fan-out items + main button
            VStack(alignment: .trailing, spacing: 12) {
                if isExpanded {
                    ForEach(Array(items.enumerated()), id: \.offset) { index, item in
                        fabMenuItem(item: item, index: index)
                    }
                }

                // Main button
                Button {
                    withAnimation(.spring(duration: 0.35, bounce: 0.25)) {
                        isExpanded.toggle()
                    }
                } label: {
                    Image(systemName: "plus")
                        .font(.title2.weight(.semibold))
                        .foregroundStyle(.white)
                        .frame(width: 56, height: 56)
                        .background(.blue, in: Circle())
                        .rotationEffect(.degrees(isExpanded ? 45 : 0))
                        .shadow(color: .blue.opacity(0.4), radius: 8, x: 0, y: 4)
                }
            }
            .padding(.trailing, 20)
            .padding(.bottom, 20)
        }
    }

    private func fabMenuItem(item: FABItem, index: Int) -> some View {
        Button {
            withAnimation(.spring(duration: 0.3)) { isExpanded = false }
            item.action()
        } label: {
            HStack(spacing: 10) {
                Text(item.label)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.primary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(.regularMaterial, in: Capsule())

                Image(systemName: item.icon)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(.white)
                    .frame(width: 44, height: 44)
                    .background(item.color, in: Circle())
                    .shadow(color: item.color.opacity(0.3), radius: 4, x: 0, y: 2)
            }
        }
        .transition(
            .asymmetric(
                insertion: .scale(scale: 0.4, anchor: .bottomTrailing)
                    .combined(with: .opacity)
                    .animation(.spring(duration: 0.35, bounce: 0.2).delay(Double(items.count - 1 - index) * 0.04)),
                removal: .scale(scale: 0.4, anchor: .bottomTrailing)
                    .combined(with: .opacity)
                    .animation(.spring(duration: 0.2))
            )
        )
    }
}
