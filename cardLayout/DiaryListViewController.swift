import UIKit
import RxSwift
import RxCocoa
import RxDataSources

class DiaryListViewController: UIViewController{

    @IBOutlet weak var collectionView: UICollectionView!
    
    private let bag = DisposeBag()
    private let diaries = BehaviorRelay<[Diary]>(value: [])
    var deleteDiarySubject = PublishSubject<IndexPath>()
    
    private let base_url = "https://private-ba0842-gary23.apiary-mock.com/notes"
    private let diaryFileURL = Helper.cachedFileURL("diaries.json")
    let collectionViewHeaderFooterReuseIdentifier = "MyHeaderFooterClass"
    var groupSortedDiary = [[Diary]]()
    
    var dataSource: RxCollectionViewSectionedReloadDataSource<DiarySection>!
    var diariesSection: BehaviorSubject<[DiarySection]> = BehaviorSubject(value: [])
    
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
                    
      DispatchQueue.main.async {
        self.bindDatasourceToCollectionView()
        self.collectionView.reloadData()
      }

      let encoder = JSONEncoder()
      if let diariesData = try? encoder.encode(updatedDiaries) {
        try? diariesData.write(to: diaryFileURL, options: .atomicWrite)
      }
    }
    
    // MARK: delete diary, show detail diary and helper
    private func deleteDiary(at indexPath: IndexPath) {
        guard var diariesSection = try? self.diariesSection.value() else { return }
        
        if diariesSection[indexPath.section].items.count > 1{
            diariesSection[indexPath.section].items.remove(at: indexPath.row)
            
        }else{
            diariesSection[indexPath.section].items.remove(at: indexPath.row)
            diariesSection.remove(at: indexPath.section)
        }
        self.diariesSection.onNext(diariesSection)
        saveDataLocal(diariesSection)
    }
    
    func showDetailDiary(_ indexPath: IndexPath) {
        guard let diaryDetailViewController = AppDelegate.storyBoard.instantiateViewController(withIdentifier: "DiaryDetailViewController") as? DiaryDetailViewController else {
            fatalError("No viewcontroller")
        }
        guard var diariesSection = try? self.diariesSection.value() else { return }
        let diary = diariesSection[indexPath.section].items[indexPath.row]
        diaryDetailViewController.diary = diary

        diaryDetailViewController.savedDiary
          .subscribe(
            onNext: { [weak self] editDiary in
                print("diariesSection sections=\(diariesSection.count)")
                diariesSection[indexPath.section].items.remove(at: indexPath.row)
                diariesSection[indexPath.section].items.insert(editDiary, at: indexPath.row)
                self?.diariesSection.onNext(diariesSection)
                
                self?.saveDataLocal(diariesSection)
                
                self?.navigationController?.popViewController(animated: true)
            },
            onDisposed: {
              print("completed diary")
            }
          )
          .disposed(by: bag)
        
        navigationController?.pushViewController(diaryDetailViewController, animated: true)
    }
    
    func saveDataLocal(_ diariesSection: Array<DiarySection>) {
        var diarylist = [Diary]()
        let flattened = diariesSection.compactMap { $0 }
        for diarysection in flattened{
            for diary_obj in diarysection.items{
                diarylist.append(diary_obj)
            }
        }
        let encoder = JSONEncoder()
        if let diariesData = try? encoder.encode(diarylist) {
            try? diariesData.write(to: diaryFileURL, options: .atomicWrite)
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
        
        sections.bind(to: self.diariesSection)
                .disposed(by: bag)
        
        self.diariesSection
            .debug()
            .asDriver(onErrorJustReturn: [])
            .drive(collectionView.rx.items(dataSource: self.dataSource))
            .disposed(by: self.bag)
    }
}

