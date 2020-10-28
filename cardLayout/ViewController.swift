import UIKit
import RxSwift
import RxCocoa

class ViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, CollectionViewCellDelegate {

    @IBOutlet weak var collectionView: UICollectionView!
    
    private let diaries = BehaviorRelay<[Diary]>(value: [])
    var groupSortedDiary = [[Diary]]()
    private let bag = DisposeBag()
    private let base_url = "https://private-ba0842-gary23.apiary-mock.com/notes"
    private let diaryFileURL = Helper.cachedFileURL("diaries.json")
    var diaryEditedIndexPath: IndexPath?
    
    let collectionViewHeaderFooterReuseIdentifier = "MyHeaderFooterClass"

    override func viewDidLoad() {
        super.viewDidLoad()
         collectionView.register(UINib(nibName: collectionViewHeaderFooterReuseIdentifier, bundle: nil), forSupplementaryViewOfKind: UICollectionElementKindSectionHeader, withReuseIdentifier:collectionViewHeaderFooterReuseIdentifier)
        
        if let flowLayout = collectionView?.collectionViewLayout as? UICollectionViewFlowLayout {
                flowLayout.estimatedItemSize = UICollectionViewFlowLayoutAutomaticSize
            }
        
        let decoder = JSONDecoder()
        if let diariesData = try? Data(contentsOf: diaryFileURL),
          let persistedDiaries = try? decoder.decode([Diary].self, from: diariesData) {
            diaries.accept(persistedDiaries)
            groupSortList()
        }
        
        let userDefaults = UserDefaults.standard
        let firstTime = userDefaults.bool(forKey: "FirstTime")
        
        if firstTime {
            refresh()
            userDefaults.set(false, forKey: "FirstTime")
            userDefaults.synchronize()
        }
      }
    
    func saveLocal() {
        let flattened = self.groupSortedDiary.flatMap { $0 }
        let encoder = JSONEncoder()
        if let eventsData = try? encoder.encode(flattened) {
          try? eventsData.write(to: diaryFileURL, options: .atomicWrite)
        }
    }
    
    func groupSortList() {
        groupSortedDiary = diaries.value.groupSort(ascending: false, byDate: {
            let date = Helper.stringToDate(strDate: $0.date)
            return date!
        })
    }
    @objc func refresh() {
      DispatchQueue.global(qos: .default).async { [weak self] in
        guard let self = self else { return }
        self.fetchDiaries(withUrl: self.base_url)
      }
    }

    func fetchDiaries(withUrl: String) {
      let response = Observable.from([withUrl])
        .map { urlString -> URL in
            return URL(string: urlString)!
        }
        .map { url -> URLRequest in
            let request = URLRequest(url: url)
          return request
        }
        .flatMap { request -> Observable<(response: HTTPURLResponse, data: Data)> in
          return URLSession.shared.rx.response(request: request)
        }
        .share(replay: 1)

      response
        .filter { response, _ in
          return 200..<300 ~= response.statusCode
        }
        .map { _, data -> [Diary] in
          let decoder = JSONDecoder()
          let diaries = try? decoder.decode([Diary].self, from: data)
          return diaries ?? []
        }
        .filter { objects in
          return !objects.isEmpty
        }
        .subscribe(onNext: { [weak self] newDiaries in
          self?.processDiaries(newDiaries)
        })
        .disposed(by: bag)

    }
    
    func processDiaries(_ newDiaries: [Diary]) {
      var updatedDiaries = newDiaries + diaries.value
      if updatedDiaries.count > 16 {
        updatedDiaries = [Diary](updatedDiaries.prefix(upTo: 16))
      }

      diaries.accept(updatedDiaries)
    
      groupSortList()
        
      DispatchQueue.main.async {
        self.collectionView.reloadData()
      }

      let encoder = JSONEncoder()
      if let diariesData = try? encoder.encode(updatedDiaries) {
        try? diariesData.write(to: diaryFileURL, options: .atomicWrite)
      }
    }
    
    // MARK: CollectionView Delegate
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return groupSortedDiary.count
    }

    func collectionView(_ collectionView: UICollectionView,
                        viewForSupplementaryElementOfKind kind: String,
                        at indexPath: IndexPath) -> UICollectionReusableView {

        switch kind {

        case UICollectionElementKindSectionHeader:
            let headerView = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: collectionViewHeaderFooterReuseIdentifier, for: indexPath) as! MyHeaderFooterClass
            
            if self.groupSortedDiary[indexPath.section].count > 0 {
                let cell_obj = self.groupSortedDiary[indexPath.section][indexPath.row]
                
                let stringDate = cell_obj.date //"2020-10-06T00:03:22.303Z"
                let locale = Locale(identifier: "en_US_POSIX")
                let formatter = DateFormatter()
                formatter.locale = locale
                formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
                let date = formatter.date(from: stringDate)
                
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
                    headerView.lblDate.text = customDateString
                } else {
//                    print("Use relative date \(relativeDateString)") // Today, Yesterday
                    headerView.lblDate.text = relativeDateString
                }

            }
            return headerView
                
        case UICollectionElementKindSectionFooter:
            let footerView = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: collectionViewHeaderFooterReuseIdentifier, for: indexPath)

            footerView.backgroundColor = UIColor.green
            return footerView

        default:
            assert(false, "Unexpected element kind")
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
            return CGSize(width: collectionView.frame.width, height: 60.0)
    }
        
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.groupSortedDiary[section].count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath) as! CollectionViewCell
        
        let cell_obj = self.groupSortedDiary[indexPath.section][indexPath.row]

        cell.lblName.text = cell_obj.title
        cell.lblDescription.text = cell_obj.content
        
        let date = Helper.stringToDate(strDate: cell_obj.date)
        cell.lblTimeAgo.text = (date?.timeAgo())! + " ago"
        cell.delpos = indexPath
        cell.delegate = self
        cell.btnDelete?.tag = indexPath.row

        return cell
    }
    
    //MARK:- Diary delegate
    func collectionViewCell(_ collectionViewCell: CollectionViewCell, btnDeleteTappedFor delpos: IndexPath) {
        if self.groupSortedDiary[delpos.section].count > 1{
            self.groupSortedDiary[delpos.section].remove(at: delpos.row)
            
        }else{
            self.groupSortedDiary[delpos.section].remove(at: delpos.row)
            self.groupSortedDiary.remove(at: delpos.section)
        }
        self.collectionView.reloadData()
        saveLocal()
    }
    
    func collectionViewCell(_ collectionViewCell: CollectionViewCell, btnEditTappedFor delpos: IndexPath) {        
        diaryEditedIndexPath = delpos
        performSegue(withIdentifier: "EditDiary", sender: delpos)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "EditDiary" {
            let controller = segue.destination as? DiaryDetailViewController
            if let indexPath = sender as? IndexPath {
                let section = groupSortedDiary[indexPath.section]
                let diary = section[indexPath.row]
                controller?.diary = diary
            }
            
            controller?.savedDiary
              .subscribe(
                onNext: { [weak self] editDiary in
                    if let indexPath = self?.diaryEditedIndexPath{
                        self?.groupSortedDiary[indexPath.section][indexPath.row] = editDiary
                        self?.collectionView.reloadData()
                        self?.saveLocal()
                    }
                    
                    self?.navigationController?.popViewController(animated: true)
                },
                onDisposed: {
                  print("completed diary")
                }
              )
              .disposed(by: bag)
        }
    }
}

