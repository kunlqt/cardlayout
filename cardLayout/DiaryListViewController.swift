import UIKit
import RxSwift
import RxCocoa

class DiaryListViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource {

    @IBOutlet weak var collectionView: UICollectionView!
    
    private let diaries = BehaviorRelay<[Diary]>(value: [])
    var groupSortedDiary = [[Diary]]()
    private let bag = DisposeBag()
    private let base_url = "https://private-ba0842-gary23.apiary-mock.com/notes"
    private let diaryFileURL = Helper.cachedFileURL("diaries.json")
    var diaryEditedIndexPath: IndexPath?
    
    let collectionViewHeaderFooterReuseIdentifier = "MyHeaderFooterClass"

    var deleteDiarySubject = PublishSubject<IndexPath>()
    
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
        
        deleteDiarySubject
            .subscribe(onNext: { [weak self] indexPath in
                self?.removeDiary(at: indexPath)
            })
            .disposed(by: bag)
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
      if updatedDiaries.count > 50 {
        updatedDiaries = [Diary](updatedDiaries.prefix(upTo: 50))
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
                headerView.configHeader(cell_obj)
            }
            return headerView
            
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

        cell.configCell(cell_obj)
        
        cell
            .btnDelete
            .rx
            .tap
            .map { indexPath }
            .bind(to: deleteDiarySubject)
            .disposed(by: cell.disposeBag)

        cell
            .btnEdit
            .rx
            .tap
            .subscribe(onNext: { [weak self] in
                self?.showDetailDiary(indexPath)
            })
            .disposed(by: cell.disposeBag)
        
        return cell
    }
    
    private func removeDiary(at indexPath: IndexPath) {
        if self.groupSortedDiary[indexPath.section].count > 1{
            self.groupSortedDiary[indexPath.section].remove(at: indexPath.row)
            
        }else{
            self.groupSortedDiary[indexPath.section].remove(at: indexPath.row)
            self.groupSortedDiary.remove(at: indexPath.section)
        }
        self.collectionView.reloadData()
        saveLocal()
    }
    
    func showDetailDiary(_ indexPath: IndexPath) {
        guard let diaryDetailViewController = AppDelegate.storyBoard.instantiateViewController(withIdentifier: "DiaryDetailViewController") as? DiaryDetailViewController else {
            fatalError("These is no controller")
        }
                
        let diary = groupSortedDiary[indexPath.section][indexPath.row]
        diaryDetailViewController.diary = diary

        diaryDetailViewController.savedDiary
          .subscribe(
            onNext: { [weak self] editDiary in
                self?.groupSortedDiary[indexPath.section][indexPath.row] = editDiary
                self?.collectionView.reloadData()
                self?.saveLocal()
                
                self?.navigationController?.popViewController(animated: true)
            },
            onDisposed: {
              print("completed diary")
            }
          )
          .disposed(by: bag)
        
        navigationController?.pushViewController(diaryDetailViewController, animated: true)
    }
}

