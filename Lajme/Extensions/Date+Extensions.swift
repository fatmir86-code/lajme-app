import Foundation

extension Date {
    private static let weekOldFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "d MMM yyyy"
        f.locale = Locale(identifier: "sq_AL")
        return f
    }()

    /// Returns a relative time string in Albanian (e.g., "5 min më parë", "2 orë më parë")
    var timeAgoAlbanian: String {
        let now = Date()
        let interval = now.timeIntervalSince(self)

        if interval < 60 {
            return "Tani"
        } else if interval < 3600 {
            let minutes = Int(interval / 60)
            return "\(minutes) min më parë"
        } else if interval < 86400 {
            let hours = Int(interval / 3600)
            return hours == 1 ? "1 orë më parë" : "\(hours) orë më parë"
        } else if interval < 604800 {
            let days = Int(interval / 86400)
            return days == 1 ? "1 ditë më parë" : "\(days) ditë më parë"
        } else {
            return Self.weekOldFormatter.string(from: self)
        }
    }
}
