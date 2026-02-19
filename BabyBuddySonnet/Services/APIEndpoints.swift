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
}
