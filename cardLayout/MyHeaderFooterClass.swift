import UIKit

class MyHeaderFooterClass: UICollectionReusableView {

    @IBOutlet weak var lblDate: UILabel!
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.backgroundColor = UIColor.purple

        // Customize here

     }

     required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)

     }
    
    func configHeader(_ date: String) {
        //"2020-10-06T00:03:22.303Z"
        let locale = Locale(identifier: "en_US_POSIX")
        let formatter = DateFormatter()
        formatter.locale = locale
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
        let date = formatter.date(from: date)
        
        // "Jan 18, 2018 at 5:29 PM"
        let relativeFormatter = Helper.buildFormatter(locale: locale, hasRelativeDate: true)
        let relativeDateString = Helper.dateFormatterToString(relativeFormatter, date!)
//                print(relativeDateString)
        // "Jan 18, 2018"

        let nonRelativeFormatter = Helper.buildFormatter(locale: locale)
        let normalDateString = Helper.dateFormatterToString(nonRelativeFormatter, date!)
//                print(normalDateString)
        // "Jan 18, 2018"

        let customFormatter = Helper.buildFormatter(locale: locale, dateFormat: "dd MMM")
        let customDateString = Helper.dateFormatterToString(customFormatter, date!)
        // "18 January"

        if relativeDateString == normalDateString {
//                    print("Use custom date \(customDateString)") // Jan 18
            self.lblDate.text = customDateString
        } else {
//                    print("Use relative date \(relativeDateString)") // Today, Yesterday
            self.lblDate.text = relativeDateString
        }
    }
    
}
