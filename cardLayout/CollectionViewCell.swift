import UIKit

class CollectionViewCell: UICollectionViewCell {
    
    @IBOutlet weak var viewOut: UIView!
    @IBOutlet weak var btnDelete: UIButton!
    @IBOutlet weak var btnEdit: UIButton!
    @IBOutlet weak var lblName: UILabel!
    @IBOutlet weak var lblDescription: UILabel!
    @IBOutlet weak var lblTimeAgo: UILabel!
    weak var delegate : CollectionViewCellDelegate?
    var delpos: IndexPath = []
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        
        viewOut.translatesAutoresizingMaskIntoConstraints = false
        viewOut.widthAnchor.constraint(equalToConstant: UIScreen.main.bounds.size.width - 50).isActive = true
        

        // Add action to perform when the button is tapped
        self.btnDelete.addTarget(self, action: #selector(btnDeleteTapped(_:)), for: .touchUpInside)
        
        self.btnEdit.addTarget(self, action: #selector(btnEditTapped(_:)), for: .touchUpInside)
      }
    
    @IBAction func btnDeleteTapped(_ sender: UIButton){
        self.delegate?.collectionViewCell(self, btnDeleteTappedFor: delpos)
      }
    
    @IBAction func btnEditTapped(_ sender: UIButton){
        self.delegate?.collectionViewCell(self, btnEditTappedFor: delpos)
      }
}

protocol CollectionViewCellDelegate: AnyObject {
  func collectionViewCell(_ collectionViewCell: CollectionViewCell, btnDeleteTappedFor delpos: IndexPath)
    
    func collectionViewCell(_ collectionViewCell: CollectionViewCell, btnEditTappedFor delpos: IndexPath)
}
