import SwiftUI

struct ChildProfileCard: View {
    let child: Child
    var latestWeight: WeightMeasurement?
    var latestHeight: HeightMeasurement?
    var latestHeadCircumference: HeadCircumferenceMeasurement?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
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

            // Growth measurements
            if latestWeight != nil || latestHeight != nil || latestHeadCircumference != nil {
                HStack(spacing: 16) {
                    if let weight = latestWeight {
                        measurementBadge(
                            icon: "scalemass",
                            value: String(format: "%.1f", weight.weightInLbs),
                            unit: "lbs"
                        )
                    }
                    if let height = latestHeight {
                        measurementBadge(
                            icon: "ruler",
                            value: String(format: "%.1f", height.heightInInches),
                            unit: "in"
                        )
                    }
                    if let head = latestHeadCircumference {
                        measurementBadge(
                            icon: "circle.dashed",
                            value: String(format: "%.1f", head.headCircumferenceInInches),
                            unit: "in"
                        )
                    }
                }
            }

            // Monthly birthday message
            if let message = monthlyBirthdayMessage {
                Text(message)
                    .font(.subheadline)
                    .foregroundStyle(.pink)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .frame(maxWidth: .infinity)
                    .background(.pink.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }
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

    private func measurementBadge(icon: String, value: String, unit: String) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text("\(value) \(unit)")
                .font(.caption)
                .fontWeight(.medium)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(.ultraThinMaterial)
        .clipShape(Capsule())
    }

    private var monthlyBirthdayMessage: String? {
        guard let birthDate = DateFormatting.parseDate(child.birthDate) else { return nil }
        let cal = Calendar.current
        let birthDay = cal.component(.day, from: birthDate)
        let todayDay = cal.component(.day, from: Date())

        guard birthDay == todayDay else { return nil }

        let components = cal.dateComponents([.year, .month], from: birthDate, to: Date())
        let years = components.year ?? 0
        let months = components.month ?? 0
        let totalMonths = years * 12 + months

        guard totalMonths > 0 else { return nil }

        if totalMonths == 12 {
            return "Happy 1st Birthday, \(child.displayName)! What an incredible year!"
        } else if totalMonths % 12 == 0 {
            let yearCount = totalMonths / 12
            return "Happy Birthday, \(child.displayName)! \(yearCount) amazing years!"
        }

        let messages = [
            "Happy \(totalMonths)-month birthday, \(child.displayName)! Growing so fast!",
            "\(totalMonths) months of joy with \(child.displayName)! Time flies!",
            "Happy \(totalMonths) months, little \(child.displayName)! What a journey!",
            "\(child.displayName) is \(totalMonths) months old today! So proud!",
            "\(totalMonths) months of love and laughter with \(child.displayName)!",
            "Happy \(totalMonths)-month milestone, \(child.displayName)! Keep shining!",
        ]

        let index = totalMonths % messages.count
        return messages[index]
    }
}
