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

    private var diaryManager = DiaryManager()
    private var monthlyDiaries: [String: [DiaryEntry]] = [:]
    private var months: [String] = []
    private var diaries: [DiaryEntry] = []
    
    private var currentLongPressedCell: JournalCollectionViewCell?
    private var selectedIndexPath: IndexPath?
    private var blurEffectView: UIVisualEffectView?
    
    private lazy var themeLabel : UILabel = {
        let label = UILabel()
        label.text = "하루일기"
        label.font = UIFont(name: "SFProDisplay-Bold", size: 33)
        label.textColor = .mainTheme
        return label
    }()
    
    private lazy var searchBar: UISearchBar = {
        let bounds = UIScreen.main.bounds
        let width = bounds.size.width - 130
        let searchBar = UISearchBar(frame: CGRect(x: 0, y: 0, width: width, height: 0))
        searchBar.placeholder = "찾고싶은 일기를 검색하세요."
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
        return collectionView
    }()
    
    private lazy var editTableView: UITableView = {
        let tableView = UITableView()
        return tableView
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .mainBackground
        addSubviewsDiaryListVC()
        autoLayoutDiaryListVC()
        setNavigationBar()
        journalCollectionView.dataSource = self
        journalCollectionView.delegate = self
        journalCollectionView.register(JournalCollectionViewCell.self, forCellWithReuseIdentifier: JournalCollectionViewCell.reuseIdentifier)
            journalCollectionView.register(HeaderView.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: HeaderView.reuseIdentifier)
        loadDiaries()
        
        // 삭제필요 : UILongPressGestureRecognizer 관련 메서드
//        setupLongGestureRecognizerOnCollectionView()
//        setupEditTableView()
        
        searchBar.delegate = self
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        loadDiaries()
    }
}

// MARK: Edit Table View(수정 및 삭제 선택지 제공)
extension DiaryListVC: UITableViewDelegate, UITableViewDataSource {
    private func setupEditTableView() {
        editTableView.delegate = self
        editTableView.dataSource = self
        editTableView.register(UITableViewCell.self, forCellReuseIdentifier: "EditTableViewCell")
        editTableView.isScrollEnabled = false
    }
    private func setLayoutEditTableView(basedOn cellFrame: CGRect) {
        let cellFrameInSuperview = journalCollectionView.convert(cellFrame, to: view)
        view.window?.addSubview(editTableView)
        editTableView.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.width.equalTo(200)
            make.height.equalTo(100)
            make.bottom.equalTo(cellFrameInSuperview.minY).offset(-10)
        }
        view.layoutIfNeeded()
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 2
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "EditTableViewCell", for: indexPath)
        switch indexPath.row {
        case 0: cell.textLabel?.text = "수정"
        case 1: cell.textLabel?.text = "삭제"
        default:
            break
        }
        return cell
    }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let selectedIndexPath = self.selectedIndexPath else { return }
        let month = months[selectedIndexPath.section]
        guard let diary = monthlyDiaries[month]?[selectedIndexPath.row] else { return }
        tableView.isHidden = true
        
//         삭제필요 : UILongPressGestureRecognizer 관련 메서드
//        removeBlurEffect()
        
        print("\(indexPath)")
        print("\(selectedIndexPath)")
        switch indexPath.row {
        case 0: // "수정" 선택 시
            print("Edit")
            let writeDiaryVC = WriteDiaryVC()
            writeDiaryVC.activeEditMode(with: diary)
            writeDiaryVC.modalPresentationStyle = .automatic
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                self.present(writeDiaryVC, animated: true, completion: nil)
            }
            
        case 1: // "삭제" 선택 시
            print("Delete")
            let alert = UIAlertController(
                title: "일기 삭제", message: "이 일기를 삭제하시겠습니까?", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "삭제", style: .destructive, handler: { [weak self] _ in
                guard let self = self else { return }
                // diary.id와 diary.imageURL을 올바르게 참조하여 삭제
                if let diaryID = diary.id {
                    let imageURL = diary.imageURL
                    self.diaryManager.deleteDiary(diaryID: diaryID, imageURL: imageURL) { error in
                        if let error = error {
                            print("Error deleting diary: \(error.localizedDescription)")
                        } else {
                        }
                    }
                }
            }))
            alert.addAction(UIAlertAction(title: "취소", style: .cancel, handler: nil))
            present(alert, animated: true, completion: nil)
        default:
            break
        }
        // 선택 처리 후 변수 초기화
        self.selectedIndexPath = nil
    }
}

// MARK: Functions in DiaryListVC
    extension DiaryListVC {
    
    // searchBar 설정 및 searchButtonTapped 전까지 hidden처리.
    private func setNavigationBar() {
        searchBar.becomeFirstResponder()
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(customView: searchBar)
        self.navigationItem.leftBarButtonItem?.isHidden = true
        self.navigationItem.rightBarButtonItems = [settingButton, magnifyingButton]
        self.navigationController?.navigationBar.tintColor = .mainTheme
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
                // 월별로 데이터 분류
                self.organizeDiariesByMonth(diaries: diaries)
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
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss Z"
            dateFormatter.locale = Locale(identifier: "ko_KR")

            for diary in diaries {
                guard let diaryDate = dateFormatter.date(from: diary.dateString) else { continue }
                let monthKey = diaryDate.toString(dateFormat: "yyyy.MM") // 월별 키 생성
                
                var diariesForMonth = organizedDiaries[monthKey, default: []]
                diariesForMonth.append(diary)
                organizedDiaries[monthKey] = diariesForMonth
            }

            // 각 월별로 시간 순서대로 정렬
            for (month, diariesInMonth) in organizedDiaries {
                organizedDiaries[month] = diariesInMonth.sorted(by: {
                    guard let date1 = dateFormatter.date(from: $0.dateString),
                          let date2 = dateFormatter.date(from: $1.dateString) else { return false }
                    return date1 > date2
                })
            }
        self.monthlyDiaries = organizedDiaries
        self.months = organizedDiaries.keys.sorted().reversed() // reversed 내림차순 정렬
    }
    
    @objc private func magnifyingButtonTapped() {
        themeLabel.isHidden = true
        self.navigationItem.leftBarButtonItem?.isHidden = false
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
        self.navigationItem.leftBarButtonItem?.isHidden = true
        navigationItem.rightBarButtonItems = [settingButton, magnifyingButton]
        searchBar.text = ""
        searchBar.resignFirstResponder() // 키보드 숨김
        loadDiaries() // 원래의 일기목록 로드
    }
    @objc private func tabWriteDiaryBTN() {
        let writeDiaryVC = WriteDiaryVC()
        writeDiaryVC.modalPresentationStyle = .automatic
        self.present(writeDiaryVC, animated: true)
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
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss Z"  // 원본 날짜 형식
            if let date = dateFormatter.date(from: diary.dateString) {
                dateFormatter.dateFormat = "yyyy.MM.dd" // 새로운 날짜 형식
                let formattedDateString = dateFormatter.string(from: date)
                
                cell.setJournalCollectionViewCell(
                    title: diary.title,
                    content: diary.content,
                    weather: diary.weather,
                    emotion: diary.emotion,
                    date: formattedDateString   // 변경된 날짜 형식 사용
                )
                
                // 이미지 URL이 있는 경우 이미지 다운로드 및 설정
                if let imageUrlString = diary.imageURL, let imageUrl = URL(string: imageUrlString) {
                    cell.imageView.isHidden = false
                    cell.imageView.image = nil  // cell 재사용 전 초기화
                    let cellID = diary.id   // 셀 식별자
                    
                    URLSession.shared.dataTask(with: imageUrl) { data, response, error in
                        guard let data = data, error == nil else { return }
                        DispatchQueue.main.async {
                            // 이미지 다운로드 완료 후 셀의 식별자 확인
                            if cellID == diary.id {
                                cell.imageView.image = UIImage(data: data)
                            }
                        }
                    }.resume()
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
        writeDiaryVC.activeEditMode(with: diary)
        
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
    
//    // 선택 시 cell을 0.98배 작게 만드는 애니메이션
//    func collectionView(_ collectionView: UICollectionView, didHighlightItemAt indexPath: IndexPath) {
//        UIView.animate(withDuration: 0.2, animations: {
//            if let cell = collectionView.cellForItem(at: indexPath) as? JournalCollectionViewCell {
//                cell.transform = CGAffineTransform(scaleX: 0.95, y: 0.95) // 셀을 약간 축소
//                cell.contentView.backgroundColor = UIColor.gray.withAlphaComponent(0.5) // 배경색 변경 (선택적)
//            }
//        })
//    }
//    // 선택 해제 시 cell을 다시 1배로 돌리는 애니메이션
//    func collectionView(_ collectionView: UICollectionView, didUnhighlightItemAt indexPath: IndexPath) {
//        UIView.animate(withDuration: 0.2, animations: {
//            if let cell = collectionView.cellForItem(at: indexPath) as? JournalCollectionViewCell {
//                cell.transform = CGAffineTransform.identity // 셀 크기를 원래대로 복원
//                cell.contentView.backgroundColor = .mainCell // 배경색을 원래대로 복원
//            }
//        })
//    }
}

// 스와이프 구현
//extension DiaryListVC: UICollectionViewDelegate {
//    func collectionView(_ collectionView: UICollectionView, trailingSwipeActionConfigurationForItemAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
//        print("swipe")
//        // listCell 삭제 액션
//        let deleteAction = UIContextualAction(style: .destructive, title: "Delete") {
//            [weak self] (action, view, completionHandler) in
//            self?.deleteItem(at: indexPath)
//            completionHandler(true)
//        }
//        
//        // 스와이프 액션 구성
//        let configuration = UISwipeActionsConfiguration(actions: [deleteAction])
//        return configuration
//    }
//    
//    func deleteItem(at indexPath: IndexPath) {
//        // 아이템 삭제 처리
//        let month = months[indexPath.section]
//        guard let diary = monthlyDiaries[month]?[indexPath.item] else {
//            print("항목을 찾을 수 없습니다.")
//            return
//        }
//        guard let diaryID = diary.id else {
//            print("유효한 DiaryID가 없습니다.")
//            return
//        }
//        
//        // DiaryManager를 통해 항목을 삭제한다.
//        diaryManager.deleteDiary(diaryID: diaryID) {
//            [weak self] error in
//            if error == nil {   // 에러가 없으면 성공
//                print("\(diaryID)가 성공적으로 삭제되었습니다.")
//                
//                // 해당 월에서 항목을 삭제.
//                self?.monthlyDiaries[month]?.remove(at: indexPath.item)
//                
//                // 컬렉션 뷰에서 해당 항목을 삭제.
//                DispatchQueue.main.async {
//                    self?.journalCollectionView.deleteItems(at: [indexPath])
//                }
//            } else {
//                // 에러가 있으면 실패
//                print("\(diaryID) 삭제에 실패했습니다.")
//            }
//        }
//    }
//    
//    // Compositional Layout 생성 메서드
//    private func createCompositionalLayout() -> UICollectionViewCompositionalLayout {
//        // 섹션당 하나의 아이템을 가지는 단순한 레이아웃
//        let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .fractionalHeight(1.0))
//        let item = NSCollectionLayoutItem(layoutSize: itemSize)
//        
//        let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .absolute(100))
//        let group = NSCollectionLayoutGroup.vertical(layoutSize: groupSize, subitems: [item])
//        
//        let section = NSCollectionLayoutSection(group: group)
//        let layout = UICollectionViewCompositionalLayout(section: section)
//        return layout
//    }
//}

// longPressEvent(cell 삭제 및 수정 기능)
//extension DiaryListVC: UIGestureRecognizerDelegate {
//    // long press 이벤트 부여
//    private func setupLongGestureRecognizerOnCollectionView() {
//        let longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress))
//        longPressGesture.delegate = self
//        longPressGesture.minimumPressDuration = 0.2     // 최소단위(초) 설정
//        longPressGesture.delaysTouchesBegan = true      // 기존 터치작업과의 분리
//        journalCollectionView.addGestureRecognizer(longPressGesture)    // 컬렉션뷰에 gesture 추가
//    }
//    @objc func handleLongPress(gestureRecognizer: UILongPressGestureRecognizer) {
//        let location = gestureRecognizer.location(in: journalCollectionView)
//        switch gestureRecognizer.state {
//        case .began:
//            guard let indexPath = journalCollectionView.indexPathForItem(at: location),
//                  let cell = journalCollectionView.cellForItem(at: indexPath) else { return }
//            
//            // longPress한 셀의 indexPath를 저장
//            self.selectedIndexPath = indexPath
//
//            // 블러 효과를 추가.
//            addBlurEffect(excludeCell: cell)
//            
//            setLayoutEditTableView(basedOn: cell.frame)
//            
//            editTableView.isHidden = false
//            editTableView.reloadData()
//            
//            // 애니메이션 추가
////            UIView.animate(withDuration: 0.2) {
////                cell.transform = CGAffineTransform(scaleX: 1.03, y: 1.03)
////                cell.layer.shadowOpacity = 0.5
////                cell.layer.shadowRadius = 10
////                cell.layer.shadowOffset = CGSize(width: 0, height: 4)
////                cell.layer.shadowColor = UIColor.black.cgColor
////            }
//        case .ended, .cancelled:
//            break
//        default:
//            break
//        }
//    }
//
//    private func addBlurEffect(excludeCell cell: UICollectionViewCell) {
//        // 전체 화면 크기의 블러 효과 뷰 생성
//        let blurEffect = UIBlurEffect(style: .light)
//        blurEffectView = UIVisualEffectView(effect: blurEffect)
//        
//        // 현재 view와 동일한 크기를 지정
//        blurEffectView?.frame = view.bounds
//        blurEffectView?.autoresizingMask = [.flexibleWidth, .flexibleHeight]
//        blurEffectView?.alpha = 0 // 초기 투명도 0
//        blurEffectView?.tag = 6 // 임의의 태그로 블러 뷰를 식별.
//
//        // 셀 위에 블러 효과를 적용하지 않기 위해 셀의 프레임을 이용하여 블러 뷰에서 셀의 영역을 제외.
//        let cellFrameInCollectionView = cell.convert(cell.bounds, to: view)
//        blurEffectView?.layer.mask = createMaskLayer(excludeFrame: cellFrameInCollectionView, in: view.bounds)
//        
//        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(blurViewTapped))
//        blurEffectView?.addGestureRecognizer(tapGesture)
//        
//        if let effectView = blurEffectView {
//            // 최상위 뷰에 추가하여 navigationBar, tabBar까지 커버한다.
//            view.window?.addSubview(effectView)
//        }
//        
//        // 0.3초간 투명도를 1로 만들어준다.
//        UIView.animate(withDuration: 0.2) {
//            self.blurEffectView?.alpha = 1
//        }
//    }
//    @objc private func blurViewTapped() {
//        UIView.animate(withDuration: 0.2, animations: {
//            self.blurEffectView?.alpha = 0
//        }) { _ in
//            self.removeBlurEffect()
//        }
//    }
//
//    private func removeBlurEffect() {
//        view.window?.viewWithTag(6)?.removeFromSuperview()
//        editTableView.removeFromSuperview()
//    }
//
//    private func createMaskLayer(excludeFrame frame: CGRect, in bounds: CGRect) -> CALayer {
//        let maskLayer = CAShapeLayer()
//        let path = UIBezierPath(rect: bounds)
//        
//        // 선택된 셀의 프레임 주위에 cornerRadius를 적용.
//        let excludedRextPath = UIBezierPath(roundedRect: frame, cornerRadius: 20)
//        
//        // 두 개의 경로를 결합하여 "evenOdd" 규칙을 적용.
//        path.append(excludedRextPath)
//        
//        maskLayer.path = path.cgPath
//        maskLayer.fillRule = .evenOdd
//
//        return maskLayer
//    }
//}

// Context Menu 관련
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
                    writeDiaryVC.activeEditMode(with: diary)
                    writeDiaryVC.modalPresentationStyle = .automatic
                    DispatchQueue.main.async {
                        self.present(writeDiaryVC, animated: true, completion: nil)
                    }
                }
            }
            // "삭제" 액션 생성
            let deleteAction = UIAction(title: "삭제", image: UIImage(systemName: "trash"), attributes: .destructive) { action in
                // "삭제" 선택 시 실행할 코드
                let month = self.months[indexPath.section]
                if let diary = self.monthlyDiaries[month]?[indexPath.row], let diaryID = diary.id {
                    let alert = UIAlertController(title: "일기 삭제", message: "이 일기를 삭제하시겠습니까?", preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "삭제", style: .destructive, handler: { _ in
                        self.diaryManager.deleteDiary(diaryID: diaryID, imageURL: diary.imageURL) { error in
                            if let error = error {
                                print("Error deleting diary: \(error.localizedDescription)")
                            } else {
                                DispatchQueue.main.async {
                                    self.loadDiaries()
                                }
                            }
                        }
                    }))
                    alert.addAction(UIAlertAction(title: "취소", style: .cancel, handler: nil))
                    self.present(alert, animated: true, completion: nil)
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
            loadDiaries()
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
        loadDiaries() // 원래의 일기목록 로드
    }
}

// MARK: addSubViews, autoLayout
extension DiaryListVC {
    private func addSubviewsDiaryListVC() {
        view.addSubview(themeLabel)
        view.addSubview(journalCollectionView)
        view.addSubview(writeDiaryButton)
    }
    
    private func autoLayoutDiaryListVC() {
        journalCollectionView.snp.makeConstraints { make in
            make.top.equalTo(self.view.safeAreaLayoutGuide).offset(50)
            make.bottom.equalTo(self.view.safeAreaLayoutGuide).offset(0)
            make.leading.equalTo(self.view.safeAreaLayoutGuide).offset(0)
            make.trailing.equalTo(self.view.safeAreaLayoutGuide).offset(0)
        }
        writeDiaryButton.snp.makeConstraints { make in
            make.trailing.equalTo(view.safeAreaLayoutGuide.snp.trailing).offset(-10)
            make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom).offset(-32)
        }
        themeLabel.snp.makeConstraints { make in
            make.top.equalTo(view).offset(50)
            make.left.equalTo(view).offset(16)
            make.size.equalTo(CGSize(width:120, height: 50))
        }
    }
}

// Date를 확장하여 문자열 변환 메서드 추가
extension Date {
    func toString(dateFormat format: String) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = format
        return dateFormatter.string(from: self)
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

// DateFormatter를 확장하여 문자열에서 Date로 변환하는 메서드 추가
extension DateFormatter {
    func date(from string: String, withFormat format: String) -> Date? {
        self.dateFormat = format
        return self.date(from: string)
    }
    func date(from date: Date, withFormat format: String) -> String? {
        self.dateFormat = format
        return self.string(from: date)
    }
}
