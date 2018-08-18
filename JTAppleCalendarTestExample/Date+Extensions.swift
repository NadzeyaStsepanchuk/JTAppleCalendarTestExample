import UIKit

extension Date {

    static var today: Date {
        return Calendar.current.startOfDay(for: Date())
    }

    func append(years: Int) -> Date? {
        var dateComponents = DateComponents()
        dateComponents.year = years
        let date = Calendar.current.date(byAdding: dateComponents, to: self)
        return date
    }
    
}
