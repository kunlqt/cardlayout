
import UIKit

class Helper{
    //MARK:- Date helper functions
    static func buildFormatter(locale: Locale, hasRelativeDate: Bool = false, dateFormat: String? = nil) -> DateFormatter {
        let formatter = DateFormatter()
        formatter.timeStyle = .none
        formatter.dateStyle = .medium
        if let dateFormat = dateFormat { formatter.dateFormat = dateFormat }
        formatter.doesRelativeDateFormatting = hasRelativeDate
        formatter.locale = locale
        return formatter
    }

    static func dateFormatterToString(_ formatter: DateFormatter, _ date: Date) -> String {
        return formatter.string(from: date)
    }
    
    static func stringDateToDay(_ strDate: String) -> String {
//        let dateString = "2020-05-28T00:03:23.303Z"
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
        guard let date = formatter.date(from: strDate) else { return "" }

        formatter.dateFormat = "yyyy-MM-dd"
        let day = formatter.string(from: date)
        return day
    }
    
    static func stringToDate(strDate: String) -> Date? {
        let locale = Locale(identifier: "en_US_POSIX")
        let formatter = DateFormatter()
        formatter.locale = locale
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
        let date = formatter.date(from: strDate)
        return date
    }
    
    //MARK:- Files helper functions
    static func cachedFileURL(_ fileName: String) -> URL {
      return FileManager.default
        .urls(for: .cachesDirectory, in: .allDomainsMask)
        .first!
        .appendingPathComponent(fileName)
    }
}
