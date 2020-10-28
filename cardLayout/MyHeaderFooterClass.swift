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
    
}
