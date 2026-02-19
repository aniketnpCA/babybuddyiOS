import SwiftUI

struct ChildProfileCard: View {
    let child: Child

    var body: some View {
        HStack(spacing: 16) {
            // Avatar
            if let picture = child.picture, let url = URL(string: picture) {
                AsyncImage(url: url) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    initialsView
                }
                .frame(width: 60, height: 60)
                .clipShape(Circle())
            } else {
                initialsView
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(child.fullName)
                    .font(.title2.bold())
                Text(child.age)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding()
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private var initialsView: some View {
        ZStack {
            Circle()
                .fill(.pink.gradient)
                .frame(width: 60, height: 60)
            Text(child.initials)
                .font(.title2.bold())
                .foregroundStyle(.white)
        }
    }
}
