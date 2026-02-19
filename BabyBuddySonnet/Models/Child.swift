import Foundation

nonisolated struct Child: Codable, Identifiable, Sendable {
    let id: Int
    let firstName: String
    let lastName: String
    let birthDate: String
    let slug: String
    let picture: String?

    var fullName: String {
        "\(firstName) \(lastName)".trimmingCharacters(in: .whitespaces)
    }

    var displayName: String {
        firstName
    }

    var age: String {
        guard let date = DateFormatting.parseDate(birthDate) else { return "" }
        let components = Calendar.current.dateComponents([.year, .month, .day], from: date, to: Date())
        let years = components.year ?? 0
        let months = components.month ?? 0
        let days = components.day ?? 0

        if years > 0 {
            return "\(years)y \(months)m"
        } else if months > 0 {
            return "\(months)m \(days)d"
        } else {
            return "\(days)d"
        }
    }

    var initials: String {
        let first = firstName.prefix(1).uppercased()
        let last = lastName.prefix(1).uppercased()
        return "\(first)\(last)"
    }
}
