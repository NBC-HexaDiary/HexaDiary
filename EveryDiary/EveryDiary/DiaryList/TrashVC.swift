//
//  TrashVC.swift
//  EveryDiary
//
//  Created by t2023-m0026 on 3/13/24.
//

import UIKit

import Firebase
import FirebaseFirestore
import SnapKit

class TrashVC: UIViewController {
    // fetchDiaries 관련 변수
    private var diaryManager = DiaryManager()
    private var monthlyDiaries: [String: [DiaryEntry]] = [:]
    private var months: [String] = []
    private var diaries: [DiaryEntry] = []

    // contextMenu 관련 변수
    private var currentLongPressedCell: TrashCollectionViewCell?
    private var selectedIndexPath: IndexPath?
    
    private let paginationManager = PaginationManager()
    private var isLoadingData: Bool = false
    
    // 화면 구성 요소
    private lazy var searchBar: UISearchBar = {
        let bounds = UIScreen.main.bounds
        let width = bounds.size.width - 145
        let searchBar = UISearchBar(frame: CGRect(x: 0, y: 0, width: width, height: 0))
        searchBar.placeholder = "찾고싶은 일기를 검색하세요."
        searchBar.delegate = self
        return searchBar
    }()
    
    private lazy var magnifyingButton = setNavigationItem(
        imageNamed: "search",
        titleText: "돋보기",
        for: #selector(magnifyingButtonTapped)
    )
    private lazy var seemMoreButton: UIBarButtonItem = {
        var config = UIButton.Configuration.plain()
        config.preferredSymbolConfigurationForImage = UIImage.SymbolConfiguration(pointSize: 18)
        config.image = UIImage(systemName: "ellipsis.circle")
        let button = UIButton(configuration: config)
        button.addTarget(self, action: #selector(seeMoreButtonTapped), for: .touchUpInside)
        return UIBarButtonItem(customView: button)
    }()
    
    private lazy var cancelButton = setNavigationItem(
        imageNamed: "",
        titleText: "취소",
        for: #selector(cancelButtonTapped)
    )
    
    private lazy var trashCollectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        layout.minimumLineSpacing = 12
        layout.sectionInset = UIEdgeInsets(top: 10, left: 0, bottom: 20, right: 0)
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.layer.cornerRadius = 0
        collectionView.backgroundColor = .clear
        collectionView.contentInset = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.register(TrashCollectionViewCell.self, forCellWithReuseIdentifier: TrashCollectionViewCell.reuseIdentifier)
        collectionView.register(HeaderView.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: HeaderView.reuseIdentifier)
        return collectionView
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .mainBackground
        addSubviews()
        setLayout()
        setNavigationBar()
//        loadDiaries()
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
}

// MARK: loadDiaries메서드, navigation관련
extension TrashVC {
    
    // navigationBar 초기화
    private func setNavigationBar() {
        // 뒤로가기 버튼 활성화
        navigationItem.leftBarButtonItem = nil
        
        self.navigationItem.rightBarButtonItems = [seemMoreButton, magnifyingButton]
        self.navigationItem.title = "휴지통"
        self.navigationController?.navigationBar.tintColor = .mainTheme
    }
    @objc private func magnifyingButtonTapped() {
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(customView: searchBar)
        navigationItem.title = nil
        navigationItem.rightBarButtonItems = [seemMoreButton, cancelButton]
        searchBar.becomeFirstResponder()
    }
    @objc private func cancelButtonTapped() {
        // 검색바 텍스트를 초기화하고 포커스를 해제
        searchBar.text = ""
        searchBar.resignFirstResponder()
        searchBar.removeFromSuperview()
        
        setNavigationBar()  // navigationBar 초기화
//        loadDiaries() // 원래의 일기목록 로드
        refreshDiaryData()
    }
    @objc private func seeMoreButtonTapped() {
        // 액션 시트 생성
        let seeMoreActionSheet = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        // "모두 복원" 액션
        let restoreAction = UIAlertAction(title: "모두 복원", style: .default) { [weak self] _ in
            guard let self = self else { return }
            // 모든 휴지통 일기를 복원하는 로직
            let deletedDiaries = self.monthlyDiaries.flatMap { $0.value }.filter { $0.isDeleted }
            deletedDiaries.forEach { diary in
                guard let diaryID = diary.id else { return }
                var updatedDiary = diary
                updatedDiary.isDeleted = false
                updatedDiary.deleteDate = nil
                self.diaryManager.updateDiary(diaryID: diaryID, newDiary: updatedDiary) { error in
                    if let error = error {
                        print("Error restoring diary: \(error.localizedDescription)")
                    }
                }
            }
            self.loadDiaries()
        }
        
        // "비우기" 액션
        let deleteAction = UIAlertAction(title: "비우기", style: .destructive) { [weak self] _ in
            guard let self = self else { return }
            // 모든 휴지통 일기를 삭제하는 로직
            let deletedDiaries = self.monthlyDiaries.flatMap { $0.value }.filter { $0.isDeleted }
            let dispatchGroup = DispatchGroup()
            
            for diary in deletedDiaries {
                guard let diaryID = diary.id else { continue }
                dispatchGroup.enter()
                
                // 각 일기에 대해 deleteDiary 호출
                self.diaryManager.deleteDiary(diaryID: diaryID, imageURL: diary.imageURL ?? []) { error in
                    if let error = error {
                        print("Error deleting diary: \(error.localizedDescription)")
                    }
                    dispatchGroup.leave()
                }
            }
            dispatchGroup.notify(queue: .main) {
                self.loadDiaries()
                let alert = UIAlertController(title: "휴지통이 비워졌습니다.", message: nil, preferredStyle: .actionSheet)
                self.present(alert, animated: true, completion: nil)
                Timer.scheduledTimer(withTimeInterval: 0.7, repeats: false, block: { _ in alert.dismiss(animated: true, completion: nil)})
            }
        }
        
        
        // 취소
        let cancelAction = UIAlertAction(title: "취소", style: .cancel)
        
        // 액션 시트에 액션 추가 및 표시
        seeMoreActionSheet.addAction(restoreAction)
        seeMoreActionSheet.addAction(deleteAction)
        seeMoreActionSheet.addAction(cancelAction)
        present(seeMoreActionSheet, animated: true)
    }
    private func setNavigationItem(imageNamed name: String, titleText: String, for action: Selector) -> UIBarButtonItem {
        var config = UIButton.Configuration.plain()
        if name == "" {
            config.title = titleText
        } else {
            config.preferredSymbolConfigurationForImage = UIImage.SymbolConfiguration(pointSize: 15)
            config.image = UIImage(named: name)
        }
        let button = UIButton(configuration: config)
        button.addTarget(self, action: action, for: .touchUpInside)
        button.titleLabel?.font = UIFont(name: "SFProDisplay-Bold", size: 20)
        return UIBarButtonItem(customView: button)
    }
    
    // 휴지통으로 이동된 diaries 중 만료된 일기를 삭제 후 불러오기
    private func loadDiaries() {
        diaryManager.getDiary { [weak self] (diaries, error) in
            guard let self = self else { return }
            if let diaries = diaries {
                // 현재 시간으로부터 (시간 * 분 * 초)이전의 시간을 계산.
                let thresholdDate = Date().addingTimeInterval(-72 * 60 * 60)
                
                // 시간이 만료된 일기들을 식별
                let expiredDiaries = diaries.filter { diary in
                    guard let deleteDate = diary.deleteDate, diary.isDeleted else { return false }
                    return deleteDate < thresholdDate
                }
                
                // 만료된 일기들을 삭제
                let dispatchGroup = DispatchGroup()
                for diary in expiredDiaries {
                    guard let diaryID = diary.id else { continue }
                    dispatchGroup.enter()
                    self.diaryManager.deleteDiary(diaryID: diaryID, imageURL: diary.imageURL ?? []) {_ in
                        dispatchGroup.leave()
                    }
                }
                
                // 삭제작업 완료 후 UI업데이트
                dispatchGroup.notify(queue: .main) {
                    // 삭제되지 않은 일기들만 필터링하여 표시
                    let remainDiaries = diaries.filter { $0.isDeleted }
                    // 월별로 데이터 분류
                    self.organizeDiariesByMonth(diaries: remainDiaries)
                    self.trashCollectionView.reloadData()
                }
            } else if let error = error {
                print("Error loading diaries: \(error)")
            }
        }
    }
    private func organizeDiariesByMonth(diaries: [DiaryEntry]) {
        var organizedDiaries: [String: [DiaryEntry]] = [:]
        
        for diary in diaries {
            guard let diaryDate = DateFormatter.yyyyMMddHHmmss.date(from: diary.dateString) else { continue }
            let monthKey = DateFormatter.yyyyMM.string(from: diaryDate) // 월별 키 생성
            
            var diariesForMonth = organizedDiaries[monthKey, default: []]
            diariesForMonth.append(diary)
            organizedDiaries[monthKey] = diariesForMonth
        }
        
        // 각 월별로 시간 순서대로 정렬
        for (month, diariesInMonth) in organizedDiaries {
            organizedDiaries[month] = diariesInMonth.sorted(by: {
                guard let date1 = DateFormatter.yyyyMMddHHmmss.date(from: $0.dateString),
                      let date2 = DateFormatter.yyyyMMddHHmmss.date(from: $1.dateString) else { return false }
                return date1 > date2
            })
        }
        self.monthlyDiaries = organizedDiaries
        self.months = organizedDiaries.keys.sorted().reversed() // reversed 내림차순 정렬
    }
}

// MARK: CollectionView 관련 extension
extension TrashVC: UICollectionViewDataSource {
    // 섹션 수 반환(월별로 구분)
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        // DiaryEntry 배열을 사용하여 월별로 구분된 섹션의 수를 계산
        print("numberOfSections : \(months.count)")
        
        return months.count
    }
    // 각 섹션 별 아이템 수 반환
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        let month = months[section]
        let count = monthlyDiaries[month]?.count ?? 0
        print("numberOfItemsInSection : \(count)")
        return count
    }
    // 셀 구성
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: TrashCollectionViewCell.reuseIdentifier, for: indexPath) as? TrashCollectionViewCell else {
            fatalError("Unable to dequeue JournalCollectionViewCell")
        }
        // 섹션에 해당하는 월 찾기
        let month = months[indexPath.section]
        // 해당 월에 해당하는 일기 찾기
        if let diariesForMonth = monthlyDiaries[month] {
            // 현재 셀에 해당하는 일기 찾기
            let diary = diariesForMonth[indexPath.row]
            
            // 날짜 포맷 변경
            if let date = DateFormatter.yyyyMMddHHmmss.date(from: diary.dateString) {
                let formattedDateString = DateFormatter.yyyyMMdd.string(from: date)
                
                cell.setTrashCollectionViewCell(
                    title: diary.title,
                    content: diary.content,
                    weather: diary.weather,
                    emotion: diary.emotion,
                    date: formattedDateString   // 변경된 날짜 형식 사용
                )
                
                // 이미지 URL이 있는 경우 이미지 다운로드 및 설정
                if let firstImageUrlString = diary.imageURL?.first, let imageUrl = URL(string: firstImageUrlString) {
                    cell.imageView.isHidden = false
                    // ImageCacheManager를 사용하여 이미지 로드
                    ImageCacheManager.shared.loadImage(from: imageUrl) { image in
                        DispatchQueue.main.async {
                            // 셀이 재사용되며 이미지가 다른 항목에 들어갈 수 있으므로 다운로드가 완료된 시점의 indexPath가 동일한지 다시 확인.
                            if let currntIndexPath = collectionView.indexPath(for: cell), currntIndexPath == indexPath {
                                cell.imageView.image = image
                            }
                        }
                    }
                } else {
                    // 이미지 URL이 없을 경우 imageView를 숨김
                    cell.imageView.isHidden = true
                }
            }
        } else {
            fatalError("No diaries found for month : \(month)")
        }
        return cell
    }
    
    // 헤더뷰 구성
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        guard let headerView = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: HeaderView.reuseIdentifier, for: indexPath) as? HeaderView else {
            fatalError("Invalid view type")
        }
        let month = months[indexPath.section]
        headerView.titleLabel.text = month
        return headerView
    }
    
    // cell 선택시
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let month = months[indexPath.section]
        guard let diary = monthlyDiaries[month]?[indexPath.row] else { return }
        
        let writeDiaryVC = WriteDiaryVC()
        
        // 선택된 일기 정보를 전달하고, 수정 버튼을 활성화
        writeDiaryVC.showsDiary(with: diary)
        writeDiaryVC.delegate = self
        
        // 일기 수정 화면으로 전환
        writeDiaryVC.modalPresentationStyle = .automatic
        // 0.2초 후에 일기 수정 화면으로 전환
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            self.present(writeDiaryVC, animated: true, completion: nil)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            collectionView.deselectItem(at: indexPath, animated: true)
        }
    }
}

// MARK: Context Menu 관련
extension TrashVC {
    // preview가 없는 메서드
    func collectionView(_ collectionView: UICollectionView, contextMenuConfigurationForItemAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
        return UIContextMenuConfiguration(identifier: nil, previewProvider: nil) { suggestedActions -> UIMenu? in
            // "수정" 액션 생성
            let editAction = UIAction(title: "수정", image: UIImage(systemName: "pencil")) { action in
                // "수정" 선택 시 실행할 코드
                let month = self.months[indexPath.section]
                if let diary = self.monthlyDiaries[month]?[indexPath.row] {
                    let writeDiaryVC = WriteDiaryVC()
                    writeDiaryVC.showsDiary(with: diary)
                    writeDiaryVC.delegate = self
                    writeDiaryVC.modalPresentationStyle = .automatic
                    DispatchQueue.main.async {
                        self.present(writeDiaryVC, animated: true, completion: nil)
                    }
                }
            }
            // "복원" 액션 생성
            let restoreAction = UIAction(title: "복원", image: UIImage(systemName: "arrow.circlepath")) { action in
                // "복원" 선택 시 실행할 코드
                let month = self.months[indexPath.section]
                if let diary = self.monthlyDiaries[month]?[indexPath.row], let diaryID = diary.id {
                    var updatedDiary = diary
                    updatedDiary.isDeleted = false
                    updatedDiary.deleteDate = nil   // deleteDate 초기화
                    DiaryManager.shared.updateDiary(diaryID: diaryID, newDiary: updatedDiary) { error in
                        if let error = error {
                            print("Error restoring diary: \(error.localizedDescription)")
                        } else {
                            print("Diary restored successfully.")
                            DispatchQueue.main.async {
//                                self.loadDiaries()
                                self.refreshDiaryData()
                            }
                        }
                    }
                    let alert = UIAlertController(title: "일기가 복원되었습니다.", message: nil, preferredStyle: .actionSheet)
                    self.present(alert, animated: true, completion: nil)
                    Timer.scheduledTimer(withTimeInterval: 0.7, repeats: false, block: { _ in alert.dismiss(animated: true, completion: nil)})
                }
            }
            // "삭제" 액션 생성
            let deleteAction = UIAction(title: "삭제", image: UIImage(systemName: "trash"), attributes: .destructive) { action in
                // "삭제" 선택 시 실행할 코드
                let month = self.months[indexPath.section]
                if let diary = self.monthlyDiaries[month]?[indexPath.row], let diaryID = diary.id {
                    self.diaryManager.deleteDiary(diaryID: diaryID, imageURL: diary.imageURL ?? []) { error in
                        if let error = error {
                            print("Error deleting diary: \(error.localizedDescription)")
                        } else {
                            DispatchQueue.main.async {
//                                self.loadDiaries()
                                self.refreshDiaryData()
                            }
                        }
                    }
                    let alert = UIAlertController(title: "일기가 영구적으로 삭제되었습니다.", message: nil, preferredStyle: .actionSheet)
                    self.present(alert, animated: true, completion: nil)
                    Timer.scheduledTimer(withTimeInterval: 0.7, repeats: false, block: { _ in alert.dismiss(animated: true, completion: nil)})
                }
            }
            // "수정"과 "삭제" 액션을 포함하는 메뉴 생성
            return UIMenu(title: "", children: [editAction, restoreAction, deleteAction])
        }
    }
}

extension TrashVC: UICollectionViewDelegateFlowLayout {
    // 헤더의 크기 설정
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        return CGSize(width: collectionView.bounds.width, height: 15)
    }
    // 셀의 크기 설정
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width = trashCollectionView.bounds.width - 32.0
        let height = trashCollectionView.bounds.height / 4.2
        return CGSize(width: width, height: height)
    }
}

//MARK: SearchBar 관련 메서드
extension TrashVC: UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if searchText.isEmpty {
//            loadDiaries()
            refreshDiaryData()
        } else {
            var filteredDiaries: [String: [DiaryEntry]] = [:]
            
            for (month, diaries) in monthlyDiaries {
                let filtered = diaries.filter { diary in
                    diary.title.range(of: searchText, options: .caseInsensitive) != nil || diary.content.range(of: searchText, options: .caseInsensitive) != nil
                }
                if !filtered.isEmpty {
                    filteredDiaries[month] = filtered
                }
            }
            monthlyDiaries = filteredDiaries
            months = monthlyDiaries.keys.sorted().reversed()
            trashCollectionView.reloadData()
        }
    }
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()    // 키보드 숨김
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchBar.text = ""
        searchBar.resignFirstResponder() // 키보드 숨김
//        loadDiaries() // 원래의 일기목록 로드
        refreshDiaryData()
    }
}

// MARK: addSubViews, autoLayout
extension TrashVC {
    private func addSubviews() {
        view.addSubview(trashCollectionView)
    }
    
    private func setLayout() {
        trashCollectionView.snp.makeConstraints { make in
            make.top.equalTo(self.view.safeAreaLayoutGuide).offset(0)
            make.bottom.equalTo(self.view.safeAreaLayoutGuide).offset(0)
            make.leading.equalTo(self.view.safeAreaLayoutGuide).offset(0)
            make.trailing.equalTo(self.view.safeAreaLayoutGuide).offset(0)
        }
    }
}

extension TrashVC : DiaryUpdateDelegate {
    func diaryDidUpdate() {
        loadDiaries()
    }
}
extension TrashVC: UICollectionViewDelegate {
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let offsetY = scrollView.contentOffset.y
        let contentHeight = scrollView.contentSize.height
        let height = scrollView.frame.size.height
        
        let triggerPoint = contentHeight - height
        
        if offsetY > triggerPoint {
            guard !isLoadingData else { return }
            isLoadingData = true
            getPage()
        }
    }
    
    func getPage() {
        paginationManager.isDeleted = true

        paginationManager.getNextPage { [weak self] newDiaries in
            guard let self = self, let newDiaries = newDiaries else {
                self?.isLoadingData = false
                return
            }

            let uniqueNewDiaries = newDiaries.filter { newDiary in
                !self.diaries.contains { $0.id == newDiary.id }
            }
            
            guard !uniqueNewDiaries.isEmpty else {
                self.isLoadingData = false
                return
            }
            
            self.diaries.append(contentsOf: uniqueNewDiaries)
            
            self.organizeDiariesByMonth(diaries: self.diaries)
            
            DispatchQueue.main.async {
                self.trashCollectionView.reloadData()
                self.isLoadingData = false
            }
            print("scroll")
        }
    }
    
    func refreshDiaryData() {
        paginationManager.resetQuery()
        self.paginationManager.isDeleted = true
        
        paginationManager.getNextPage { newDiaries in
            if let newDiaries = newDiaries {

                let filteredDiaries = newDiaries.filter { $0.isDeleted }
                
                self.diaries = filteredDiaries
                self.organizeDiariesByMonth(diaries: self.diaries)
                DispatchQueue.main.async {
                    self.trashCollectionView.reloadData()
                }
                print("refresh")
            } else {
                print("Failed to fetch new diaries.")
            }
        }
    }
}
