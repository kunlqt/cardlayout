import UIKit
import RxSwift

class CollectionViewCell: UICollectionViewCell {
    
    @IBOutlet weak var viewOut: UIView!
    @IBOutlet weak var btnDelete: UIButton!
    @IBOutlet weak var btnEdit: UIButton!
    @IBOutlet weak var lblName: UILabel!
    @IBOutlet weak var lblDescription: UILabel!
    @IBOutlet weak var lblTimeAgo: UILabel!
    var delpos: IndexPath = []
    
    var disposeBag = DisposeBag()
    
    override func prepareForReuse() {
        super.prepareForReuse()
        disposeBag = DisposeBag()
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        
        viewOut.translatesAutoresizingMaskIntoConstraints = false
        viewOut.widthAnchor.constraint(equalToConstant: UIScreen.main.bounds.size.width - 50).isActive = true
    }
    
    func configCell(_ diary: Diary) {
        self.lblName.text = diary.title
        self.lblDescription.text = diary.content
        
        let date = Helper.stringToDate(strDate: diary.date)
        self.lblTimeAgo.text = (date?.timeAgo())! + " ago"
    }
}
