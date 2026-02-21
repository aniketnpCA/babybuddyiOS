import Foundation

nonisolated enum APIEndpoints {
    static let children = "/api/children/"
    static func child(_ id: Int) -> String { "/api/children/\(id)/" }

    static let feedings = "/api/feedings/"
    static func feeding(_ id: Int) -> String { "/api/feedings/\(id)/" }

    static let pumping = "/api/pumping/"
    static func pumpingSession(_ id: Int) -> String { "/api/pumping/\(id)/" }

    static let sleep = "/api/sleep/"
    static func sleepSession(_ id: Int) -> String { "/api/sleep/\(id)/" }

    static let changes = "/api/changes/"
    static func change(_ id: Int) -> String { "/api/changes/\(id)/" }

    static let timers = "/api/timers/"
    static func timer(_ id: Int) -> String { "/api/timers/\(id)/" }

    // Growth measurements
    static let weight = "/api/weight/"
    static func weight(_ id: Int) -> String { "/api/weight/\(id)/" }

    static let height = "/api/height/"
    static func height(_ id: Int) -> String { "/api/height/\(id)/" }

    static let headCircumference = "/api/head-circumference/"
    static func headCircumference(_ id: Int) -> String { "/api/head-circumference/\(id)/" }

    static let bmi = "/api/bmi/"
    static func bmi(_ id: Int) -> String { "/api/bmi/\(id)/" }
}
