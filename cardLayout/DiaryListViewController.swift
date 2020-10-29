import UIKit
import RxSwift
import RxCocoa
import RxDataSources

class DiaryListViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource {

    @IBOutlet weak var collectionView: UICollectionView!
    
    private let bag = DisposeBag()
    private let diaries = BehaviorRelay<[Diary]>(value: [])
    var deleteDiarySubject = PublishSubject<IndexPath>()
    
    private let base_url = "https://private-ba0842-gary23.apiary-mock.com/notes"
    private let diaryFileURL = Helper.cachedFileURL("diaries.json")
    let collectionViewHeaderFooterReuseIdentifier = "MyHeaderFooterClass"
    var groupSortedDiary = [[Diary]]()
    
    var dataSource: RxCollectionViewSectionedReloadDataSource<DiarySection>!
    
    func transformToDiarySection(diaries: [Diary]) -> Observable<[DiarySection]> {
        return Observable<[DiarySection]>.create { observer in
            let dayDiaries = Array(Set(diaries.compactMap { $0.dayDate }))
            var diariesManage = dayDiaries.compactMap { day -> DiarySection in
                let diariesDay = diaries.filter { $0.dayDate == day }
                return DiarySection(items: diariesDay)
            }
            
            diariesManage.sort(by: { Helper.stringToDate(strDate: $0.diaryDate ?? "") ?? Date() > Helper.stringToDate(strDate: $1.diaryDate ?? "") ?? Date() })
            
            observer.onNext(diariesManage)
            
            return Disposables.create()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
         collectionView.register(UINib(nibName: collectionViewHeaderFooterReuseIdentifier, bundle: nil), forSupplementaryViewOfKind: UICollectionElementKindSectionHeader, withReuseIdentifier:collectionViewHeaderFooterReuseIdentifier)
        
        if let flowLayout = collectionView?.collectionViewLayout as? UICollectionViewFlowLayout {
                flowLayout.estimatedItemSize = UICollectionViewFlowLayoutAutomaticSize
            }
        
//        collectionView
//            .rx
//            .setDelegate(self)
//            .disposed(by: bag)
        
        dataSource = RxCollectionViewSectionedReloadDataSource<DiarySection>(
          configureCell: { dataSource, tableView, indexPath, item in
            let cell = tableView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath) as! CollectionViewCell
            cell.configCell(item)
            cell.btnDelete
                .rx
                .tap
                .map { indexPath }
                .bind(to: self.deleteDiarySubject)
                .disposed(by: cell.disposeBag)

            cell.btnEdit
                .rx
                .tap
                .subscribe(onNext: { [weak self] in
                    self?.showDetailDiary(indexPath)
                })
                .disposed(by: cell.disposeBag)
            return cell
          },
            configureSupplementaryView: {(dataSource, collectionView, kind, indexPath) -> UICollectionReusableView in
                let header = collectionView.dequeueReusableSupplementaryView(ofKind: UICollectionElementKindSectionHeader, withReuseIdentifier: self.collectionViewHeaderFooterReuseIdentifier, for: indexPath) as! MyHeaderFooterClass
                header.configHeader(dataSource[indexPath.section].diaryDate ?? "")
                    return header
                })
        
        let decoder = JSONDecoder()
        if let diariesData = try? Data(contentsOf: diaryFileURL),
          let persistedDiaries = try? decoder.decode([Diary].self, from: diariesData) {
            diaries.accept(persistedDiaries)
            groupSortList()
            bindDatasourceToCollectionView()
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
                self?.deleteDiary(at: indexPath)
            })
            .disposed(by: bag)
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
        self.bindDatasourceToCollectionView()
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
        print("dataSource[indexPath.section].diaryDate==")
        switch kind {

        case UICollectionElementKindSectionHeader:
            let headerView = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: collectionViewHeaderFooterReuseIdentifier, for: indexPath) as! MyHeaderFooterClass
            
            if self.groupSortedDiary[indexPath.section].count > 0 {
                let cell_obj = self.groupSortedDiary[indexPath.section][indexPath.row]
                headerView.configHeader(cell_obj.date)
//                print("dataSource[indexPath.section].diaryDate==\(dataSource[indexPath.section].diaryDate)")
//                headerView.configHeader(dataSource[indexPath.section].diaryDate ?? "")
            }
            return headerView
            
        default:
            assert(false, "Unexpected element kind")
        }
    }
        
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.groupSortedDiary[section].count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath) as! CollectionViewCell
        
        let cell_obj = self.groupSortedDiary[indexPath.section][indexPath.row]

        cell.configCell(cell_obj)
        
        cell.btnDelete
            .rx
            .tap
            .map { indexPath }
            .bind(to: deleteDiarySubject)
            .disposed(by: cell.disposeBag)

        cell.btnEdit
            .rx
            .tap
            .subscribe(onNext: { [weak self] in
                self?.showDetailDiary(indexPath)
            })
            .disposed(by: cell.disposeBag)
        
        return cell
    }
    
    // MARK: delete diary, show detail diary and helper
    private func deleteDiary(at indexPath: IndexPath) {
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
            fatalError("No viewcontroller")
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
    
    func bindDatasourceToCollectionView(){
        let sections = self.transformToDiarySection(diaries: self.diaries.value)
        print(sections)
        sections
            .bind(to: self.collectionView.rx.items(dataSource: self.dataSource))
            .disposed(by: self.bag)
    }
}

