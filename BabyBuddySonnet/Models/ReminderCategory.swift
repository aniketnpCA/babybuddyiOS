import Foundation

nonisolated enum ReminderCategory: String, CaseIterable, Sendable {
    case feeding
    case diaper
    case sleep
    case pumping

    var displayName: String {
        switch self {
        case .feeding: return "Feeding"
        case .diaper: return "Diaper"
        case .sleep: return "Sleep"
        case .pumping: return "Pumping"
        }
    }

    var icon: String {
        switch self {
        case .feeding: return "drop.fill"
        case .diaper: return "circle.dotted"
        case .sleep: return "moon.fill"
        case .pumping: return "drop.triangle.fill"
        }
    }

    var defaultThresholdHours: Double {
        switch self {
        case .feeding: return 3.0
        case .diaper: return 3.0
        case .sleep: return 4.0
        case .pumping: return 4.0
        }
    }

    var defaultIntervalHours: Double {
        switch self {
        case .feeding: return 3.0
        case .diaper: return 3.0
        case .sleep: return 0 // sleep doesn't use interval
        case .pumping: return 4.0
        }
    }

    var notificationID: String {
        "reminder_\(rawValue)"
    }

    var notificationTitle: String {
        switch self {
        case .feeding: return "Feeding Reminder"
        case .diaper: return "Diaper Reminder"
        case .sleep: return "Sleep Reminder"
        case .pumping: return "Pumping Reminder"
        }
    }

    func notificationBody(thresholdHours: Double) -> String {
        let hoursText: String
        if thresholdHours == Double(Int(thresholdHours)) {
            hoursText = "\(Int(thresholdHours))"
        } else {
            hoursText = String(format: "%.1f", thresholdHours)
        }

        switch self {
        case .feeding:
            return "It's been over \(hoursText) hours since the last feeding."
        case .diaper:
            return "It's been over \(hoursText) hours since the last diaper change."
        case .sleep:
            return "It's been over \(hoursText) hours since the last sleep session ended."
        case .pumping:
            return "It's been over \(hoursText) hours since the last pumping session."
        }
    }
}
