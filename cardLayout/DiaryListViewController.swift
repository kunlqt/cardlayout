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
    private let path = "notes"
    private let diaryFileURL = Helper.cachedFileURL("diaries.json")
    let collectionViewHeaderFooterReuseIdentifier = "MyHeaderFooterClass"
    
    var dataSource: RxCollectionViewSectionedReloadDataSource<DiarySection>!
    var diariesSectionSubject: BehaviorSubject<[DiarySection]> = BehaviorSubject(value: [])
    
    func configureCollectionView(){
        collectionView.register(UINib(nibName: collectionViewHeaderFooterReuseIdentifier, bundle: nil), forSupplementaryViewOfKind: UICollectionElementKindSectionHeader, withReuseIdentifier:collectionViewHeaderFooterReuseIdentifier)
       
        if let flowLayout = collectionView?.collectionViewLayout as? UICollectionViewFlowLayout {
            flowLayout.estimatedItemSize = UICollectionViewFlowLayoutAutomaticSize
        }
    }
    
    func configureDatasource(){
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
                header.configHeader(dataSource[indexPath.section].firstDateDiary ?? "")
                    return header
          })
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        configureCollectionView()
        
        configureDatasource()
        
        let decoder = JSONDecoder()
        if let diariesData = try? Data(contentsOf: diaryFileURL),
          let persistedDiaries = try? decoder.decode([Diary].self, from: diariesData) {
            diaries.accept(persistedDiaries)
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
        guard var diariesSectionList = try? self.diariesSectionSubject.value() else { return }
        
        if diariesSectionList[indexPath.section].items.count > 1{
            diariesSectionList[indexPath.section].items.remove(at: indexPath.row)
            
        }else{
            diariesSectionList[indexPath.section].items.remove(at: indexPath.row)
            diariesSectionList.remove(at: indexPath.section)
        }
        self.diariesSectionSubject.onNext(diariesSectionList)
        saveDataLocal(diariesSectionList)
    }
    
    func showDetailDiary(_ indexPath: IndexPath) {
        guard let diaryDetailViewController = AppDelegate.storyBoard.instantiateViewController(withIdentifier: "DiaryDetailViewController") as? DiaryDetailViewController else {
            fatalError("No viewcontroller")
        }
        guard var diariesSectionList = try? self.diariesSectionSubject.value() else { return }
        let diary = diariesSectionList[indexPath.section].items[indexPath.row]
        diaryDetailViewController.diary = diary

        diaryDetailViewController.savedDiary
          .subscribe(
            onNext: { [weak self] editDiary in
                diariesSectionList[indexPath.section].items.remove(at: indexPath.row)
                diariesSectionList[indexPath.section].items.insert(editDiary, at: indexPath.row)
                self?.diariesSectionSubject.onNext(diariesSectionList)
                
                self?.saveDataLocal(diariesSectionList)
                
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
    
    func diaryToDiarySection(diaries: [Diary]) -> Observable<[DiarySection]> {
        return Observable<[DiarySection]>.create { observer in
            let dayUnique = Array(Set(diaries.compactMap { Helper.stringDateToDay($0.date) }))
            var diariesSectionList = dayUnique.compactMap { day -> DiarySection in
                let diariesDay = diaries.filter { Helper.stringDateToDay($0.date) == day }
                return DiarySection(items: diariesDay.sorted(by: { $0.date > $1.date }))
            }
            diariesSectionList.sort(by: {Helper.stringToDate(strDate: $0.firstDateDiary ?? "") ?? Date() > Helper.stringToDate(strDate: $1.firstDateDiary ?? "") ?? Date() })
            
            observer.onNext(diariesSectionList)
            
            return Disposables.create()
        }
    }
    
    func bindDatasourceToCollectionView(){
        let sections = self.diaryToDiarySection(diaries: self.diaries.value)
        
        sections.bind(to: self.diariesSectionSubject)
                .disposed(by: bag)
        
//        sections.bind(to: collectionView.rx.items(dataSource: self.dataSource))
//                .disposed(by: self.bag)
        
        self.diariesSectionSubject
            .bind(to: collectionView.rx.items(dataSource: self.dataSource))
            .disposed(by: self.bag)
    }
}

