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

// 사용자가 작성한 일기 리스트를 보여주는 ViewController
class DiaryListVC: UIViewController, UIAdaptivePresentationControllerDelegate {
    // 다이어리 관리를 위한 변수
    private var diaryManager = DiaryManager()
    private var monthlyDiaries: [String: [DiaryEntry]] = [:]    // 월별로 정렬된 DiaryEntry
    private var months: [String] = []                           // 일기의 월별 구분을 위한 배열
    private var diaries: [DiaryEntry] = []                      // 사용자의 모든 DiaryEntry

    // ContextMenu 관련 변수
    private var currentLongPressedCell: JournalCollectionViewCell?
    private var selectedIndexPath: IndexPath?
    
    // Pagenation을 위한 변수
    private let paginationManager = PaginationManager()         // 페이지네이션 관리
    private var isLoadingData: Bool = false                     // 데이터 로딩 중을 표시하는 플래그
    
    private var searchTimer: Timer? // 디바운싱을 위한 타이머
    private var isSearching: Bool = false
  
    private var isUploadingDiary: Bool = false                  // 데이터 전송 중을 표시하는 플래그
    
    private var searchDebounceTimer: Timer?
    
    // 화면 구성 요소 정의
    private lazy var themeLabel : UILabel = {
        let label = UILabel()
        label.text = "하루일기"
        label.font = UIFont(name: "SFProDisplay-Bold", size: 25)
        label.textColor = .mainTheme
        return label
    }()
    
    // 검색 바
    private lazy var searchBar: UISearchBar = {
        let bounds = UIScreen.main.bounds
        let width = bounds.size.width - 130
        let searchBar = UISearchBar(frame: CGRect(x: 0, y: 0, width: width, height: 0))
        searchBar.placeholder = "찾고싶은 일기를 검색하세요."
        searchBar.delegate = self
        return searchBar
    }()
    
    // NavigationBar Item 구성
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
    
    // 일기 작성 버튼 구성
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
    
    private lazy var refreshControl: UIRefreshControl = {
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(handleRefresh(_:)), for: .valueChanged)
        return refreshControl
    }()
    
    // 컬렉션 뷰 구성
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
        collectionView.register(LoadingIndicatorCell.self, forCellWithReuseIdentifier: LoadingIndicatorCell.reuseIdentifier)
        collectionView.refreshControl = refreshControl
        return collectionView
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .mainBackground
        addSubviews()
        setLayout()
        setNavigationBar()
        loadDiaries()
        
        NotificationCenter.default.addObserver(self, selector: #selector(loginStatusChanged), name: .loginstatusChanged, object: nil)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}
extension DiaryListVC {
    @objc private func handleRefresh(_ refreshControl: UIRefreshControl) {
        // 데이터 로딩 로직
        getPage()
        refreshControl.endRefreshing()
    }
}

// MARK: loadDiaries메서드, navigation관련
extension DiaryListVC {
    
    // NavigationBar 아이템 및 색상 설정
    private func setNavigationBar() {
        self.navigationController?.navigationBar.tintColor = .mainTheme
        self.navigationController?.navigationBar.shadowImage = UIImage()
        self.navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .default)
        self.navigationItem.rightBarButtonItems = [settingButton, magnifyingButton]
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(customView: themeLabel)
    }
    // NavigationBar Item 생성 메서드
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
    
    // Firebase에서 일기데이터를 불러오는 메서드
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
    
    // 월별로 다이어리 항목을 정리하는 메서드
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
    @objc private func cancelButtonTapped() {
        navigationItem.leftBarButtonItems = [UIBarButtonItem(customView: themeLabel)]
        navigationItem.rightBarButtonItems = [settingButton, magnifyingButton]
        searchBar.text = ""
        searchBar.resignFirstResponder() // 키보드 숨김
        refreshDiaryData()
        isSearching = false
    }
    @objc private func tabWriteDiaryBTN() {
        let writeDiaryVC = WriteDiaryVC()
        writeDiaryVC.enterDiary(to: .writeNewDiary)
        writeDiaryVC.delegate = self
        writeDiaryVC.loadingDiaryDelegate = self
        writeDiaryVC.modalPresentationStyle = .automatic
        writeDiaryVC.presentationController?.delegate = self
        self.present(writeDiaryVC, animated: true)
    }
    // 설정 화면(SettingVC)으로 이동
    @objc private func tabSettingBTN() {
        let settingVC = SettingVC()
        settingVC.hidesBottomBarWhenPushed = true
        navigationController?.pushViewController(settingVC, animated: true)
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
        
        return months.count
    }
    // 각 섹션 별 아이템 수 반환
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        let month = months[section]
        let count = monthlyDiaries[month]?.count ?? 0
        // 데이터를 전송 중이면, LoadingIndicatorCell을 위해 numberOfItem + 1
        return count + (isUploadingDiary ? 1 : 0)
    }
    // 셀 구성
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let month = months[indexPath.section]
        guard let diariesForMonth = monthlyDiaries[month] else {
            fatalError("No diaries found for month: \(month)")
        }
        
        if isUploadingDiary && indexPath.row == 0 {
            // 로딩 인디케이터 셀 반환
            guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: LoadingIndicatorCell.reuseIdentifier, for: indexPath) as? LoadingIndicatorCell else {
                fatalError("Unable to dequeue LoadingIndicatorCell")
            }
            return cell
        } else {
            guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: JournalCollectionViewCell.reuseIdentifier, for: indexPath) as? JournalCollectionViewCell else {
                fatalError("Unable to dequeue JournalCollectionViewCell")
            }
            
            // isLoadingData에 따라 index를 조절하는 변수
            let adjustedIndex = isUploadingDiary ? indexPath.row - 1 : indexPath.row
            // 현재 셀에 해당하는 일기 찾기. isLoadingData = true일 때,
            let diary = diariesForMonth[adjustedIndex]
            
            // 날짜 포맷 변경
            if let date = DateFormatter.yyyyMMddHHmmss.date(from: diary.dateString) {
                let formattedDateString = DateFormatter.yyyyMMDD.string(from: date)
                
                cell.setJournalCollectionViewCell(
                    title: diary.title,
                    content: diary.content,
                    weather: diary.weather,
                    emotion: diary.emotion,
                    date: formattedDateString   // 변경된 날짜 형식 사용
                )
                
                // 여러 이미지 중 첫번째 이미지로 셀 설정
                if let firstImageUrlString = diary.imageURL?.first, let imageUrl = URL(string: firstImageUrlString) {
                    
                    // ImageCacheManager를 사용하는 loadImageAsync를 사용하여 비동기 이미지 다운로드
                    cell.loadImageAsync(url: imageUrl) { image in
                        // setImage로 이미지와 URL을 함께 전달하여 잘못된 indexPath에 이미지가 전달되는 현상 방지
                        cell.setImage(image, for: imageUrl)
                    }
                } else {
                    // 이미지 URL이 없을 경우 imageView를 숨김
                    cell.hideImage()
                }
            }
            return cell
        }
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
        
        // 로딩 인디케이터 셀을 체크하여, 로딩 인디케이터 셀을 선택하면 임시 메세지를 띄워주도록 처리
        if isUploadingDiary && indexPath.section == months.count - 1 && indexPath.row == (monthlyDiaries[month]?.count ?? 0) {
            // 로딩 인디케이터 셀 선택 시 로직
            TemporaryAlert.presentTemporaryMessage(with: "저장 중", message: "일기를 저장 중입니다.\n잠시만 기다려주세요.", interval: 1.0, for: self)
            return
        }
        
        guard let diariesForMonth = monthlyDiaries[month], indexPath.row < diariesForMonth.count else { return }
        let diary = diariesForMonth[indexPath.row]
        
        let writeDiaryVC = WriteDiaryVC()
        
        // 선택된 일기 정보를 전달하고, 수정 버튼을 활성화
        writeDiaryVC.enterDiary(to: .showDiary, with: diary)
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
                    writeDiaryVC.enterDiary(to: .editDiary, with: diary)
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
    //FIXME: 기존 검색 메서드
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if searchText.isEmpty {
            refreshDiaryData() // 검색어가 비워지면 전체 일기 데이터를 다시 표시
            isSearching = false // 검색 중 플래그 해제

        } else {
            isSearching = true // 검색 중 플래그 설정
            searchTimer?.invalidate() // 이전 타이머가 있으면 무효화합니다.
            searchTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false) { _ in
                self.searchDiaries(with: searchText) // 입력이 멈추면 검색을 실행합니다.
            }
        }
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchTimer?.invalidate() // 검색 버튼을 누르면 현재 진행 중인 검색을 중지합니다.
        guard let searchText = searchBar.text, !searchText.isEmpty else {
            return
        }
        searchDiaries(with: searchText) // 검색을 수행합니다.
    }
    
    private func searchDiaries(with searchText: String) {
        diaryManager.fetchDiaries { [weak self] (diaries, error) in
            guard let self = self else { return }
            if let diaries = diaries {
                let filteredDiaries = diaries.filter { diary in
                    let isMatch = diary.title.localizedCaseInsensitiveContains(searchText) ||
                    diary.content.localizedCaseInsensitiveContains(searchText)
                    return isMatch && !diary.isDeleted
                }
                self.diaries = filteredDiaries
                self.organizeDiariesByMonth(diaries: self.diaries)
                DispatchQueue.main.async {
                    self.journalCollectionView.reloadData()
                }
            } else if let error = error {
                print("Error searching diaries: \(error)")
            }
        }
    }
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchBar.text = ""
        searchBar.resignFirstResponder() // 키보드 숨김
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
        view.addSubview(journalCollectionView)
        view.addSubview(writeDiaryButton)
    }
    
    private func setLayout() {
        journalCollectionView.snp.makeConstraints { make in
            make.top.equalTo(self.view.safeAreaLayoutGuide).offset(0)
            make.bottom.equalTo(self.view.safeAreaLayoutGuide).offset(0)
            make.leading.equalTo(self.view.safeAreaLayoutGuide).offset(0)
            make.trailing.equalTo(self.view.safeAreaLayoutGuide).offset(0)
        }
        writeDiaryButton.snp.makeConstraints { make in
            make.trailing.equalTo(view.safeAreaLayoutGuide.snp.trailing).offset(-10)
            make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom).offset(-32)
        }
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
        refreshDiaryData()
    }
}
extension DiaryListVC: UICollectionViewDelegate {
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard !isSearching else { return } // 검색 중일 때는 페이지네이션 비활성화

        let offsetY = scrollView.contentOffset.y
        let contentHeight = scrollView.contentSize.height
        let height = scrollView.frame.size.height
        
        let triggerPoint = contentHeight - height
        
        if offsetY > triggerPoint {
            guard !isLoadingData else { return }
            isLoadingData = true //
            getPage()
        }
    }
    
    func getPage() {
        guard !isSearching else { return } // 검색 중일 때는 페이지네이션 비활성화

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
                self.journalCollectionView.reloadData()
                self.isLoadingData = false
            }
        }
    }
    
    func refreshDiaryData() {
        guard !isSearching else { return } // 검색 중일 때는 페이지네이션 비활성화

        paginationManager.resetQuery()
        
        paginationManager.getNextPage { newDiaries in
            if let newDiaries = newDiaries {
                let filteredDiaries = newDiaries.filter { !$0.isDeleted }
                
                self.diaries = filteredDiaries
                self.organizeDiariesByMonth(diaries: self.diaries)
                DispatchQueue.main.async {
                    self.journalCollectionView.reloadData()
                }
            } else {
//                print("Failed to fetch new diaries.")
                return
            }
        }
    }
}

extension DiaryListVC: WriteDiaryDelegate {
    func diaryUploadDidStart() {
        print("diaryUploadDidStart")
        isUploadingDiary = true
        print("isUploadingDiary: \(isUploadingDiary)")
        DispatchQueue.main.async {
            // 로딩 인디케이터 셀 표시를 위해 컬렉션 뷰 새로고침
            self.journalCollectionView.reloadData()
        }
    }
    
    func diaryUploadDidFinish() {
        print("diaryUploadDidFinish")
        isUploadingDiary = false
        print("isUploadingDiary: \(isUploadingDiary)")
        print("Finish Uploading Diary..")
        DispatchQueue.main.async {
            // 로딩 인디케이터 셀 제거를 위해 컬렉션 뷰 새로고침
            self.journalCollectionView.reloadData()
        }
        getPage()
    }
}
