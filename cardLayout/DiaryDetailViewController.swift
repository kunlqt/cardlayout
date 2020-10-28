import UIKit
import RxSwift

class DiaryDetailViewController: UIViewController {
    var diary : Diary?
    
    var savedDiary: Observable<Diary> {
      return savedDiarySubject.asObservable()
    }
    private let savedDiarySubject = PublishSubject<Diary>()
    
    @IBOutlet weak var textField: UITextField!
    
    @IBOutlet weak var textView: UITextView!
    override func viewDidLoad() {
        super.viewDidLoad()
        self.hideKeyboardWhenTappedAround()
        if let item = diary {
            title = item.title
            textField?.text = item.title
            textView?.text = item.content
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        textField?.becomeFirstResponder()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
      super.viewWillDisappear(animated)
        savedDiarySubject.onCompleted()
    }
    
    @IBAction func backButton(_ sender: UIBarButtonItem) {
        navigationController?.popViewController(animated: true)
    }
    
    @IBAction func save() {
        diary?.title = textField.text ?? ""
        diary?.content = textView.text
        self.savedDiarySubject.onNext(diary!)
    }
    

}
