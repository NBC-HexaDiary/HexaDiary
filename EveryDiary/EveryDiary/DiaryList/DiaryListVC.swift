//
//  MainVC.swift
//  EveryDiary
//
//  Created by t2023-m0044 on 2/21/24.
//

import UIKit

import Firebase
import FirebaseFirestore
import SnapKit

class DiaryListVC: UIViewController {
    // fetchDiaries 관련 변수
    private var diaryManager = DiaryManager()
    private var monthlyDiaries: [String: [DiaryEntry]] = [:]
    private var months: [String] = []
    private var diaries: [DiaryEntry] = []
    private var isLoadingData: Bool = false // 데이터를 로드 중인지 여부를 나타내는 플래그

    // contextMenu 관련 변수
    private var currentLongPressedCell: JournalCollectionViewCell?
    private var selectedIndexPath: IndexPath?
    private let paginationManager = PaginationManager() // PaginationManager 추가

    // 화면 구성 요소
    private lazy var themeLabel : UILabel = {
        let label = UILabel()
        label.text = "하루일기"
        label.font = UIFont(name: "SFProDisplay-Bold", size: 25)
        label.textColor = .mainTheme
        return label
    }()
    
    private lazy var searchBar: UISearchBar = {
        let bounds = UIScreen.main.bounds
        let width = bounds.size.width - 130
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
    private lazy var settingButton = setNavigationItem(
        imageNamed: "setting",
        titleText: "세팅뷰 이동",
        for: #selector(tabSettingBTN)
    )
    private lazy var cancelButton = setNavigationItem(
        imageNamed: "",
        titleText: "취소",
        for: #selector(cancelButtonTapped)
    )
    
    private lazy var writeDiaryButton : UIButton = {
        var config = UIButton.Configuration.plain()
        let button = UIButton(configuration: config)
        button.layer.shadowRadius = 3
        button.layer.borderColor = UIColor(named: "mainCell")?.cgColor
        button.layer.shadowOpacity = 0.3
        button.layer.shadowOffset = CGSize(width: 0, height: 0)
        button.setImage(UIImage(named: "write"), for: .normal)
        button.addTarget(self, action: #selector(tabWriteDiaryBTN), for: .touchUpInside)
        return button
    }()
    
    private lazy var journalCollectionView: UICollectionView = {
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
        collectionView.register(JournalCollectionViewCell.self, forCellWithReuseIdentifier: JournalCollectionViewCell.reuseIdentifier)
        collectionView.register(HeaderView.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: HeaderView.reuseIdentifier)
        return collectionView
    }()
    
    
    // FIXME: 삭제예정(blurEffectView, editTableView)
    private var blurEffectView: UIVisualEffectView?
    private lazy var editTableView: UITableView = {
        let tableView = UITableView()
        return tableView
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .mainBackground
        addSubviews()
        setLayout()
        setNavigationBar()
//        loadDiaries()

        
        NotificationCenter.default.addObserver(self, selector: #selector(loginStatusChanged), name: .loginstatusChanged, object: nil)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}

// MARK: loadDiaries메서드, navigation관련
extension DiaryListVC {
    
    // searchBar 설정 및 searchButtonTapped 전까지 hidden처리.
    private func setNavigationBar() {
        searchBar.becomeFirstResponder()
//        self.navigationItem.leftBarButtonItem = UIBarButtonItem(customView: searchBar)
        self.navigationItem.leftBarButtonItem?.isHidden = true
        self.navigationItem.rightBarButtonItems = [settingButton, magnifyingButton]
        self.navigationController?.navigationBar.tintColor = .mainTheme
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(customView: themeLabel)
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
    
    private func loadDiaries() {
        diaryManager.fetchDiaries { [weak self] (diaries, error) in
            guard let self = self else { return }
            if let diaries = diaries {
                // 삭제하지 않은 일기만 필터링
                let activeDiaries = diaries.filter { !$0.isDeleted }
                // 월별로 데이터 분류
                self.organizeDiariesByMonth(diaries: activeDiaries)
                DispatchQueue.main.async {
                    self.journalCollectionView.reloadData()
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
    
    @objc private func magnifyingButtonTapped() {
        adjustSearchBarWidth()  // searchBar 크기 조절
        navigationItem.leftBarButtonItems = [UIBarButtonItem(customView: searchBar)]
        navigationItem.rightBarButtonItems = [settingButton, cancelButton]
        searchBar.becomeFirstResponder()
    }
    @objc private func tabSettingBTN() {
        let settingVC = SettingVC()
        settingVC.hidesBottomBarWhenPushed = true
        navigationController?.pushViewController(settingVC, animated: true)
    }
    @objc private func cancelButtonTapped() {
        themeLabel.isHidden = false
        navigationItem.leftBarButtonItems = [UIBarButtonItem(customView: themeLabel)]
        navigationItem.rightBarButtonItems = [settingButton, magnifyingButton]
        searchBar.text = ""
        searchBar.resignFirstResponder() // 키보드 숨김
//        loadDiaries() // 원래의 일기목록 로드
        refreshDiaryData()
    }
    @objc private func tabWriteDiaryBTN() {
        let writeDiaryVC = WriteDiaryVC()
        writeDiaryVC.delegate = self
        writeDiaryVC.modalPresentationStyle = .automatic
        self.present(writeDiaryVC, animated: true)
    }
    @objc private func tabLoadDiaryButton() {
//        loadDiaries()
        journalCollectionView.reloadData()
        print("Load Diaries")
    }
    @objc private func loginStatusChanged() {
        loadDiaries()
    }
}

// MARK: CollectionView 관련 extension
extension DiaryListVC: UICollectionViewDataSource {
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
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: JournalCollectionViewCell.reuseIdentifier, for: indexPath) as? JournalCollectionViewCell else {
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
                
                cell.setJournalCollectionViewCell(
                    title: diary.title,
                    content: diary.content,
                    weather: diary.weather,
                    emotion: diary.emotion,
                    date: formattedDateString   // 변경된 날짜 형식 사용
                )
                
                // 여러 이미지 중 첫번째 이미지로 셀 설정
                if let firstImageUrlString = diary.imageURL?.first, let imageUrl = URL(string: firstImageUrlString) {
                    
                    // ImageCacheManager를 사용하여 이미지 로드
                    ImageCacheManager.shared.loadImage(from: imageUrl) { image in
                        DispatchQueue.main.async {
                            // 셀이 재사용되며 이미지가 다른 항목에 들어갈 수 있으므로 다운로드가 완료된 시점의 indexPath가 동일한지 다시 확인.
                            if let currntIndexPath = collectionView.indexPath(for: cell), currntIndexPath == indexPath {
                                cell.setImage(image)
                            }
                        }
                    }
                } else {
                    // 이미지 URL이 없을 경우 imageView를 숨김
                    cell.hideImage()
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
extension DiaryListVC {
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
            // "휴지통" 액션 생성
            let deleteAction = UIAction(title: "휴지통", image: UIImage(systemName: "trash"), attributes: .destructive) { action in
                // "휴지통" 선택 시 실행할 코드
                let month = self.months[indexPath.section]
                if let diary = self.monthlyDiaries[month]?[indexPath.row], let diaryID = diary.id {
                    var updatedDiary = diary
                    updatedDiary.isDeleted = true
                    updatedDiary.deleteDate = Date() // 현재 날짜로 삭제날짜 설정
                    DiaryManager.shared.updateDiary(diaryID: diaryID, newDiary: updatedDiary) { error in
                        if let error = error {
                            print("Error moving diary to trash: \(error.localizedDescription)")
                        } else {
                            print("Diary moved to trash successfully.")
                            DispatchQueue.main.async {
                                self.refreshDiaryData()
                            }
                        }
                    }
                    let alert = UIAlertController(title: "휴지통으로 이동하였습니다.", message: nil, preferredStyle: .actionSheet)
//                    let alert = UIAlertController(title: "일기 삭제", message: "이 일기를 삭제하시겠습니까?", preferredStyle: .alert)
//                    alert.addAction(UIAlertAction(title: "삭제", style: .destructive, handler: { _ in
//                        self.diaryManager.deleteDiary(diaryID: diaryID, imageURL: diary.imageURL) { error in
//                            if let error = error {
//                                print("Error deleting diary: \(error.localizedDescription)")
//                            } else {
//                                DispatchQueue.main.async {
//                                    self.loadDiaries()
//                                }
//                            }
//                        }
//                    }))
//                    alert.addAction(UIAlertAction(title: "취소", style: .cancel, handler: nil))
                    // 임시
                    self.present(alert, animated: true, completion: nil)
                    Timer.scheduledTimer(withTimeInterval: 0.7, repeats: false, block: { _ in alert.dismiss(animated: true, completion: nil)})
                }
            }
            // "수정"과 "삭제" 액션을 포함하는 메뉴 생성
            return UIMenu(title: "", children: [editAction, deleteAction])
        }
    }
}

extension DiaryListVC: UICollectionViewDelegateFlowLayout {
    // 헤더의 크기 설정
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        return CGSize(width: collectionView.bounds.width, height: 15)
    }
    // 셀의 크기 설정
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width = journalCollectionView.bounds.width - 32.0
        let height = journalCollectionView.bounds.height / 4.2
        return CGSize(width: width, height: height)
    }
}

//MARK: SearchBar 관련 메서드
extension DiaryListVC: UISearchBarDelegate {
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
            journalCollectionView.reloadData()
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
    // searchBar의 적절한 사이즈 조절하는 메서드
    private func adjustSearchBarWidth() {
        let screenWidth = UIScreen.main.bounds.width
        var rightItemsWidth: CGFloat = 0
        let spaceBetweenItem: CGFloat = 16  // 버튼 사이의 여백
        let horizontalPadding:CGFloat = 32  // 화면 가장자리에서 searchBar까지의 여잭
        
        // rightNarButtonItems의 너비 계산
        if let rightItems = self.navigationItem.rightBarButtonItems {
            for item in rightItems {
                if let customView = item.customView {
                    rightItemsWidth += customView.frame.width
                } else {
                    // 커스텀 뷰가 없는 경우 기본 너비 추정치 추가
                    rightItemsWidth += 44   // UIBarButtonItem의 추정 평균 너비
                }
            }
            // 버튼 사이의 여백 추가
            rightItemsWidth += CGFloat(rightItems.count - 1) * spaceBetweenItem
        }
        // searchBar의 새로운 너비 계산
        let searchBarWidth = screenWidth - rightItemsWidth - horizontalPadding
        
        // searchBar의 frame 업데이트
        self.searchBar.frame = CGRect(x: 0, y: 0, width: searchBarWidth, height: 0)
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(customView: searchBar)
    }
}

// MARK: addSubViews, autoLayout
extension DiaryListVC {
    private func addSubviews() {
//        view.addSubview(themeLabel)
        view.addSubview(journalCollectionView)
        view.addSubview(writeDiaryButton)
    }
    
    private func setLayout() {
        journalCollectionView.snp.makeConstraints { make in
            make.top.equalTo(self.view.safeAreaLayoutGuide).offset(32)
            make.bottom.equalTo(self.view.safeAreaLayoutGuide).offset(0)
            make.leading.equalTo(self.view.safeAreaLayoutGuide).offset(0)
            make.trailing.equalTo(self.view.safeAreaLayoutGuide).offset(0)
        }
        writeDiaryButton.snp.makeConstraints { make in
            make.trailing.equalTo(view.safeAreaLayoutGuide.snp.trailing).offset(-10)
            make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom).offset(-32)
        }
//        themeLabel.snp.makeConstraints { make in
//            make.top.equalTo(view).offset(50)
//            make.left.equalTo(view).offset(16)
//            make.size.equalTo(CGSize(width:120, height: 50))
//        }
    }
}

// 문자열 배열에서 중복 제거를 위한 확장
extension Array where Element: Equatable {
    func unique() -> [Element] {
        var uniqueValues: [Element] = []
        for item in self {
            if !uniqueValues.contains(item) {
                uniqueValues.append(item)
            }
        }
        return uniqueValues
    }
}

//MARK: - 일기 작성, 수정 시 data reload
extension DiaryListVC : DiaryUpdateDelegate {
    func diaryDidUpdate() {
//        loadDiaries()
        print("Update Diary")
        refreshDiaryData()
    }
}
extension DiaryListVC: UICollectionViewDelegate {
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let offsetY = scrollView.contentOffset.y
        let contentHeight = scrollView.contentSize.height
        let height = scrollView.frame.size.height
        
        let triggerPoint = contentHeight - height
        
        if offsetY > triggerPoint {
            // 데이터를 로드 중이 아닌 경우에만 다음 페이지의 데이터를 요청
            guard !isLoadingData else { return }
            isLoadingData = true // 데이터 로드 중 플래그 설정
            getPage()
        }
    }
    
    func getPage() {
        paginationManager.getNextPage { [weak self] newDiaries in
            guard let self = self, let newDiaries = newDiaries else {
                self?.isLoadingData = false // 데이터 로드 완료 후 플래그 재설정
                return
            }
            
            // 중복된 데이터를 제거
            let uniqueNewDiaries = newDiaries.filter { newDiary in
                !self.diaries.contains { $0.id == newDiary.id }
            }
            
            guard !uniqueNewDiaries.isEmpty else {
                self.isLoadingData = false
                return
            }
            
            // 새로운 데이터를 기존 데이터에 추가
            self.diaries.append(contentsOf: uniqueNewDiaries)
            
            // 월별로 데이터 재구성
            self.organizeDiariesByMonth(diaries: self.diaries)
            
            // 컬렉션 뷰 리로드
            DispatchQueue.main.async {
                self.journalCollectionView.reloadData()
                self.isLoadingData = false // 데이터 로드 완료 후 플래그 재설정
            }
            print("scroll")
        }
    }
    
    func refreshDiaryData() {
        // PaginationManager의 query를 초기화하여 새로고침
        paginationManager.resetQuery()
        
        paginationManager.getNextPage { newDiaries in
            if let newDiaries = newDiaries {
                let filteredDiaries = newDiaries.filter { !$0.isDeleted }
                
                self.diaries = filteredDiaries
                self.organizeDiariesByMonth(diaries: self.diaries)
                DispatchQueue.main.async {
                    self.journalCollectionView.reloadData()
                }
                print("refresh")
            } else {
                print("Failed to fetch new diaries.")
            }
        }
    }
}
