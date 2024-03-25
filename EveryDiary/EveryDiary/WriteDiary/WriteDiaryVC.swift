//
//  WriteDiaryVC.swift
//  EveryDiary
//
//  Created by t2023-m0044 on 2/21/24.
//
import CoreLocation
import UIKit

import Firebase
import SnapKit

// WriteDiaryVC를 호출하는 목적에 따라 WriteDiaryVC의 UI컴포넌트 상태 구분
enum UIstatus {
    case writeNewDiary      // 새로운 일기 작성
    case editDiary          // 작성된 일기 수정
    case showDiary          // 작성된 일기 조회
}

class WriteDiaryVC: UIViewController, ImagePickerDelegate, UITextFieldDelegate {
    
    weak var delegate: DiaryUpdateDelegate?     // Delegate 프로토콜을 통한 데이터 업데이트 각 VC 통지
    private var diaryManager = DiaryManager()
    private var imagePickerManager = ImagePickerManager()
    private var mapManager = MapManager()
    private var keyboardManager: KeyboardManager?
    let weatherService = WeatherService()
    
    private var selectedEmotion = ""
    private var selectedWeather = ""
    private var selectedDate = Date()
    private var selectedPhotoIdentifiers: [String] = []
    private var useMetadataLocation: Bool = false
    private var currentLocationInfo: String?
    
    private var diaryID: String?        // 수정할 일기의 ID를 저장하는 변수
    private var isSavingDiary = false   // 중복저장을 방지하기 위한 변수(플래그)
    private lazy var dateString: String = {     // 날짜선택 버튼에 사용되는 String
        let dateString = DateFormatter.yyyyMMddE.string(from: selectedDate)
        return dateString
    }()
    
    // UI컴포넌트 초기화
    private lazy var datePickingButton = setButton(
        imageNamed: "",
        titleText: dateString,
        textFont: "SFProDisplay-Bold",
        fontSize: 20,
        buttonSize: CGSize(width: 15, height: 15),
        for: #selector(datePickingButtonTapped),
        hidden: false
    )
    private lazy var completeButton = setButton(
        imageNamed: "",
        titleText: "완료",
        textFont: "SFProDisplay-Bold",
        fontSize: 20,
        buttonSize: CGSize(width: 15, height: 15),
        for: #selector(completeButtonTapped),
        hidden: true
    )
    private lazy var updateButton = setButton(
        imageNamed: "",
        titleText: "저장",
        textFont: "SFProDisplay-Bold",
        fontSize: 20,
        buttonSize: CGSize(width: 15, height: 15),
        for: #selector(updateButtonTapped),
        hidden: true
    )
    private lazy var allowEditButton = setButton(
        imageNamed: "",
        titleText: "수정",
        textFont: "SFProDisplay-Bold",
        fontSize: 20,
        buttonSize: CGSize(width: 15, height: 15),
        for: #selector(allowEditButtonTapped),
        hidden: true
    )
    private lazy var emotionImageView: UIImageView = {
        let view = UIImageView()
        view.contentMode = .scaleAspectFit
        return view
    }()
    private lazy var weatherImageView: UIImageView = {
        let view = UIImageView()
        view.contentMode = .scaleAspectFit
        return view
    }()
    private lazy var titleTextField : UITextField = {
        let textField = UITextField()
        textField.backgroundColor = .clear
        textField.placeholder = "제목을 입력하세요."
        textField.tintColor = .subBackground
        textField.font = UIFont(name: "SFProDisplay-Bold", size: 26)
        textField.textColor = .black
        
        return textField
    }()
    private lazy var contentTextView : UITextView = {
        let view = UITextView()
        view.backgroundColor = .clear
        view.font = UIFont(name: "SFProDisplay-Regular", size: 18)
        view.tintColor = .subBackground
        view.textColor = .lightGray
        view.isScrollEnabled = false
        view.text = textViewPlaceHolder
        
        return view
    }()
    private let textViewPlaceHolder = "텍스트를 입력하세요."
    
    // 여러개의 이미지를 보여주기 위한 배열과 collectionView
    private lazy var imagesCollectionView: UICollectionView = {
        let carouselLayout = CarouselFlowLayout()
        
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: carouselLayout)
        collectionView.backgroundColor = .clear
        collectionView.showsHorizontalScrollIndicator = false
        
        return collectionView
    }()
    private var imagesLocationInfo: [ImageLocationInfo] = []                // 이미지와 meta정보를 저장하는 배열
    private var imageCollectionViewHeightConstraint: NSLayoutConstraint?    // collectionView의 높이
    
    private lazy var photoBarButtonItem: UIBarButtonItem = {
        let originalImage = UIImage(named: "image")?.resizedImage(with: CGSize(width: 24, height: 24))
        return UIBarButtonItem(image: originalImage, style: .plain, target: self, action: #selector(photoButtonTapped))
    }()
    private lazy var emotionBarButtonItem: UIBarButtonItem = {
        let originalImage = UIImage(named: "happy")?.resizedImage(with: CGSize(width: 27, height: 27))
        return UIBarButtonItem(image: originalImage, style: .plain, target: self, action: #selector(emotionButtonTapped))
    }()
    private lazy var weatherBarButtonItem: UIBarButtonItem = {
        let originalImage = UIImage(named: "Vector")?.resizedImage(with: CGSize(width: 25, height: 25))
        return UIBarButtonItem(image: originalImage, style: .plain, target: self, action: #selector(weatherButtonTapped))
    }()
    
    private let weatherDescriptionLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.text = "날씨를 불러오는 중입니다.."
        label.font = .systemFont(ofSize: 13, weight: .light)
        label.textColor = .gray
        return label
    }()
    private let weatherTempLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.text = "날씨를 불러오는 중입니다."
        label.font = .systemFont(ofSize: 13, weight: .light)
        label.textColor = .gray
        return label
    }()
    
    // 스크롤 뷰 및 컨텐츠 뷰
    private lazy var scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        return scrollView
    }()
    private lazy var contentView: UIView = {
        let view = UIView()
        return view
    }()
    
    private var scrollViewBottomConstraint: Constraint?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureUI()
        setupInitialData()
        setupDelegates()
    }
    deinit {
        keyboardManager?.unregisterKeyboardNotifications()
    }
    
    private func setupDelegates() {
        titleTextField.delegate = self
        imagePickerManager.delegate = self
        contentTextView.delegate = self
        imagesCollectionView.delegate = self
        imagesCollectionView.dataSource = self
        imagesCollectionView.register(ImageCollectionViewCell.self, forCellWithReuseIdentifier: ImageCollectionViewCell.reuseIdentifier)
        imagesCollectionView.register(MapCollectionViewCell.self, forCellWithReuseIdentifier: MapCollectionViewCell.reuseIdentifier)
    }
}

// MARK: 이벤트 핸들링 메서드
extension WriteDiaryVC {
    // 일기 저장 로직
    @objc func completeButtonTapped() {
        guard !isSavingDiary else { return }    // 저장 중(=true)이면 실행되지 않음
        isSavingDiary = true                    // 저장 시작
        
        let formattedDateString = DateFormatter.yyyyMMddHHmmss.string(from: selectedDate)
        var contentText = contentTextView.text ?? ""
        
        // contentTextView의 텍스트가 placeHolder와 같다면 빈문자열로 처리
        if contentText == textViewPlaceHolder {
            contentText = ""
        }
        
        let dispatchGroup = DispatchGroup()
        var uploadedImageURLs = [String]()
        
        // 이미지와 메타데이터 업로드
        for imageLocationInfo in self.imagesLocationInfo {
            guard let assetIdentifier = imageLocationInfo.assetIdentifier else { continue }
            dispatchGroup.enter()
            // 촬영 시간과 위치 정보를 포함하여 업로드
            FirebaseStorageManager.uploadImage(
                image: [imageLocationInfo.image],
                pathRoot: "diary_images",
                assetIdentifier: assetIdentifier,
                captureTime: imageLocationInfo.captureTime,
                location: imageLocationInfo.location
            ) { urls in
                guard let urls = urls, !urls.isEmpty else {
                    dispatchGroup.leave()
                    return
                }
                uploadedImageURLs.append(contentsOf: urls.map { $0.absoluteString })
                dispatchGroup.leave()
            }
        }
        dispatchGroup.notify(queue: .main) { [weak self] in
            guard let self = self else { return }
            // DiaryEntry 생성 및 업로드
            self.createAndUploadDiaryEntry(
                with: self.titleTextField.text ?? "",
                content: contentText,
                dateString: formattedDateString,
                imageUrls: uploadedImageURLs,
                useMetadataLocation: self.useMetadataLocation,
                currentLocationInfo: self.currentLocationInfo
            )
        }
    }
    // 일기 업데이트 로직
    @objc func updateButtonTapped() {
        guard let diaryID = self.diaryID else { return }
        
        let formattedDateString =  DateFormatter.yyyyMMddHHmmss.string(from: selectedDate)
        var uploadedImageURLs = [String]()
        
        // 이미지 업로드 작업을 관리하기 위한 DispatchGroup
        let dispatchGroup = DispatchGroup()
        
        for imagesLocationInfo in self.imagesLocationInfo {
            guard let assetIdentifier = imagesLocationInfo.assetIdentifier else { continue }
            dispatchGroup.enter()
            
            FirebaseStorageManager.uploadImage(
                image: [imagesLocationInfo.image],
                pathRoot: "diary_images",
                assetIdentifier: assetIdentifier,
                captureTime: imagesLocationInfo.captureTime,
                location: imagesLocationInfo.location
            ) { urls in
                if let urls = urls, !urls.isEmpty {
                    uploadedImageURLs.append(contentsOf: urls.map { $0.absoluteString })
                }
                dispatchGroup.leave()
            }
        }
        dispatchGroup.notify(queue: .main) { [weak self] in
            guard let self = self else { return }
            // 이미지 URL 배열을 이용해 DiaryEntry 업데이트
            let updatedDiaryEntry = DiaryEntry(
                id: diaryID,
                title: self.titleTextField.text ?? "",
                content: self.contentTextView.text ?? "",
                dateString: formattedDateString,
                emotion: self.selectedEmotion,
                weather: self.selectedWeather,
                imageURL: uploadedImageURLs
            )
            self.updateDiaryInFirestore(diaryID: diaryID, diaryEntry: updatedDiaryEntry)
        }
    }
    // 일기 편집 가능 상태로 변경
    @objc func allowEditButtonTapped() {
        datePickingButton.isEnabled = true
        titleTextField.isEnabled = true
        contentTextView.isEditable = true
        completeButton.isHidden = true
        updateButton.isHidden = false
        allowEditButton.isHidden = true
        titleTextField.becomeFirstResponder()
    }
    
    @objc func emotionButtonTapped() {
        presentControllerSelect(with: .emotion) // 감정 선택 로직
    }
    
    @objc func weatherButtonTapped() {
        presentControllerSelect(with: .weather)// 날씨 선택 로직
    }
    
    // 날짜 선택 로직
    @objc func datePickingButtonTapped() {
        let dateSelectVC = DateSelectVC()
        dateSelectVC.selectedDate = self.selectedDate
        dateSelectVC.delegate = self    // 델리게이트 설정
        dateSelectVC.modalPresentationStyle = .popover
        if let popoverController = dateSelectVC.popoverPresentationController {
            popoverController.sourceView = self.datePickingButton
            popoverController.sourceRect = self.datePickingButton.bounds
            popoverController.permittedArrowDirections = [.up, .down]
            popoverController.delegate = self
        }
        dateSelectVC.preferredContentSize = CGSize(width: 400, height: 400)
        self.present(dateSelectVC, animated: true, completion: nil)
    }
    
    // 사진 접근 권한 요청 로직
    @objc func photoButtonTapped() {
        print("preselected 된 identifier: \(self.selectedPhotoIdentifiers)")
        imagePickerManager.requestPhotoLibraryAccess(from: self)
    }
    
    @objc func dismissKeyboard() {
        view.endEditing(true)
    }
    
    @objc func collectionViewEdgeTapped(_ recognizer: UITapGestureRecognizer) {
        let tapLocation = recognizer.location(in: imagesCollectionView)
        
        // collectionView의 중앙 지점을 찾고 그 지점에 있는 cell의 indexPath를 찾는다.
        let centerPoint = CGPoint(x: imagesCollectionView.frame.size.width / 2 + imagesCollectionView.contentOffset.x, y: imagesCollectionView.frame.size.height / 2)
        guard let centerIndexPath = imagesCollectionView.indexPathForItem(at: centerPoint) else { return }
        
        // 중앙에 있는 cell의 frame을 구한다.
        if let centerCellFrame = imagesCollectionView.layoutAttributesForItem(at: centerIndexPath)?.frame {
            
            // cell의 frame과 비교해 각 조건에 맞는 메서드 호출
            if tapLocation.x < centerCellFrame.minX {
                // 왼쪽 영역을 탭했다면, 이전 셀로 스크롤
                let previousIndex = max(0, centerIndexPath.item - 1)
                scrollToItem(at: previousIndex, animated: true)
            } else if tapLocation.x > centerCellFrame.maxX {
                // 오른쪽 영역을 탭했다면, 다음 셀로 스크롤
                let nextIndex = min(imagesCollectionView.numberOfItems(inSection: 0) - 1, centerIndexPath.item + 1)
                scrollToItem(at: nextIndex, animated: true)
            } else {
                // 탭한 위치가 중앙 셀의 내부인 경우, didSelectItemAt을 호출.
                collectionView(imagesCollectionView, didSelectItemAt: centerIndexPath)
            }
        }
    }
    
    // 컬렉션 뷰 측면을 탭했을 때, indexPath + 1로 scroll시키는 메서드
    private func scrollToItem(at index: Int, animated: Bool) {
        print(#function)
        // 범위 확인을 통해 인덱스 유효성 테스트
        if index >= 0 && index < imagesCollectionView.numberOfItems(inSection: 0) {
            let indexPath = IndexPath(item: index, section: 0)
            imagesCollectionView.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: animated)
        }
    }
}

// MARK: 네트워크 요청
extension WriteDiaryVC {
    // DiaryEntry 생성 및 Firestore 저장
    private func createAndUploadDiaryEntry(with title: String, content: String, dateString: String, imageUrls: [String] = [], useMetadataLocation: Bool, currentLocationInfo: String? = nil) {
        var newDiaryEntry: DiaryEntry
        
        // currentLoactionInfo가 nil이 아닌 경우 전제 저장
        if let locationInfo = currentLocationInfo {
            newDiaryEntry = DiaryEntry(title: title, content: content, dateString: dateString, emotion: selectedEmotion, weather: selectedWeather, imageURL: imageUrls, useMetadataLocation: useMetadataLocation, currentLocationInfo: locationInfo
            )
        } else {
            // currentLocationInfo가 nil이라면 제외하고 저장
            newDiaryEntry = DiaryEntry(title: title, content: content, dateString: dateString, emotion: selectedEmotion, weather: selectedWeather, imageURL: imageUrls, useMetadataLocation: useMetadataLocation
            )
        }
        
        // DiaryManager를 사용해 FireStore에 저장
        diaryManager.addDiary(diary: newDiaryEntry) { [weak self] error in
            guard let self = self else { return }
            self.isSavingDiary = false  // 성공, 실패 여부를 떠나서 저장 시도가 완료되었으므로 변수 초기화
            if let error = error {
                // 에러처리
                print("Error saving diary to Firestore: \(error.localizedDescription)")
            } else {
                // 에러가 없다면, 화면 닫기
                self.dismiss(animated: true, completion: nil)
                self.delegate?.diaryDidUpdate()
            }
        }
    }
    
    // DiaryEntry 수정 및 Firestore 업데이트
    private func updateDiaryInFirestore(diaryID: String, diaryEntry: DiaryEntry) {
        // Firestore 문서 업데이트
        DiaryManager.shared.updateDiary(diaryID: diaryID, newDiary: diaryEntry) { error in
            if let error = error {
                print("Error updating diary: \(error.localizedDescription)")
            } else {
                print("Dairy updated successfully")
                self.dismiss(animated: true, completion: nil)
                self.delegate?.diaryDidUpdate()
            }
        }
    }
}

// MARK: 임시
extension WriteDiaryVC {
    
    func showsDiary(with diary: DiaryEntry) {
        // UI 내 일기 내용 반영
        self.diaryID = diary.id
        self.titleTextField.text = diary.title
        self.contentTextView.text = diary.content
        self.contentTextView.textColor = .black
        self.selectedEmotion = diary.emotion
        self.selectedWeather = diary.weather
        
        // 날짜 형식 업데이트
        if let date = DateFormatter.yyyyMMddHHmmss.date(from: diary.dateString) {
            self.selectedDate = date
            let dateString = DateFormatter.yyyyMMddE.string(from: date)
            self.datePickingButton.setTitle(dateString, for: .normal)
        }
        
        // 이모티콘과 날씨 업데이트
        emotionImageView.image = UIImage(named: diary.emotion)
        weatherImageView.image = UIImage(named: diary.weather)
        
        // 기존 이미지 정보 초기화
        self.selectedPhotoIdentifiers.removeAll()
        self.imagesLocationInfo.removeAll()
        
        // 이미지 URL 배열에서 각 이미지와 메타데이터를 다운로드
        let group = DispatchGroup()
        diary.imageURL?.forEach { urlString in
            guard URL(string: urlString) != nil else { return }
            group.enter()
            FirebaseStorageManager.downloadImage(urlString: urlString) { [weak self] downloadedImage, metadata in
                defer { group.leave() }
                guard let self = self, let image = downloadedImage else { return }
                let captureTime = metadata?["captureTime"] ?? "Unknown"
                let locationInfoString = metadata?["location"] ?? "Unknown"
                let assetIdentifier = metadata?["assetIdentifier"]
                if let assetIdentifier = assetIdentifier {
                    self.imagePickerManager.selectedPhotoIdentifiers.append(assetIdentifier)
                }
                let locationInfo = self.locationInfoFromString(locationInfoString)
                // 메타데이터를 포함한 ImageLocationInfo 객체 생성
                let imageLocationInfo = ImageLocationInfo(image: image, locationInfo: locationInfo, assetIdentifier: assetIdentifier, captureTime: captureTime, location: locationInfoString)
                self.imagesLocationInfo.append(imageLocationInfo)
            }
        }
        
        group.notify(queue: .main) { [weak self] in
            self?.imagesCollectionView.reloadData()
            self?.updateImageCollectionViewHeight()
        }
    }
    // customMetaData로 저장된 하나의 String을 lat과 long으로 나눠주는 메서드
    func locationInfoFromString(_ locationString: String) -> LocationInfo? {
        let components = locationString.split(separator: ", ").map { String($0) }
        guard components.count == 2,
              let latitude = CLLocationDegrees(components[0]),
              let longitude = CLLocationDegrees(components[1]) else {
            return nil
        }
        return LocationInfo(latitude: latitude, longitude: longitude)
    }
}

// MARK: Date Condition(감정, 날씨 선택)
extension WriteDiaryVC: DateConditionSelectDelegate {
    
    func presentControllerSelect(with conditionType: ConditionType) {
        print(#function)
        let conditionSelectVC = DateConditionSelectVC()
        conditionSelectVC.conditionType = conditionType
        conditionSelectVC.modalPresentationStyle = .popover
        conditionSelectVC.preferredContentSize = CGSize(width: 400, height: 50)
        conditionSelectVC.delegate = self
        
        if let popoverController = conditionSelectVC.popoverPresentationController {
            if conditionType == .emotion {
                popoverController.barButtonItem = emotionBarButtonItem
            } else if conditionType == .weather {
                popoverController.barButtonItem = weatherBarButtonItem
            }
            popoverController.permittedArrowDirections = [.down]
            popoverController.delegate = self
            present(conditionSelectVC, animated: true, completion: nil)
        }
    }
    
    func didSelectCondition(_ condition: String, type: ConditionType) {
        // 선택한 condition과 같은 이름을 가진 Asset 이미지를 버튼에 적용
        switch type {
        case .emotion:
            selectedEmotion = condition
            emotionImageView.image = UIImage(named: condition)
        case .weather:
            selectedWeather = condition
            weatherImageView.image = UIImage(named: condition)
        }
    }
}

// MARK: Date Select Delegate(날짜 선택)
extension WriteDiaryVC: DateSelectDelegate, UIPopoverPresentationControllerDelegate {
    // DateSelectVC에서 선택한 날짜를 전달받는 로직
    func didSelectDate(_ date: Date) {
        // 선택한 날짜를 변수에 저장
        self.selectedDate = date
        // 선택된 날짜로 문자열 변환
        let dateString = DateFormatter.yyyyMMddE.string(from: date)
        datePickingButton.setTitle(dateString, for: .normal)
        
        // 현재 날짜와 비교
        let calendar = Calendar.current
        
        // 선택된 날짜가 오늘인지 확인
        if calendar.isDateInToday(selectedDate) {
            // 오늘 날짜를 선택한 경우, 날씨 정보 로드
            loadWeatherData()
            weatherDescriptionLabel.isHidden = false
            weatherTempLabel.isHidden = false
        } else {
            // 과거의 날짜를 선택한 경우, 날씨 정보 표시하지 않음
            weatherDescriptionLabel.isHidden = true
            weatherTempLabel.isHidden = true
        }
    }
    
    // iPhone에서도 popover 스타일 강제하는 메서드
    func adaptivePresentationStyle(for controller: UIPresentationController) -> UIModalPresentationStyle {
        return .none // iPhone에서도 popover 스타일을 강제합니다.
    }
}

// MARK: PHPickerControllerDelegate (사진 선택)
extension WriteDiaryVC {
    func didPickImages(_ imagesLocationInfo: [ImageLocationInfo], retainedIdentifiers: [String]) {
        print(#function)
        
        // 새롭게 선택된 사진 식별자
        let newIdentifiers = Set(retainedIdentifiers)
        print("새롭게 선택된 사진 식별자: \(newIdentifiers)")
        
        // 기존에 선택되었던 사진 식별자
        let existingIdentifiers = Set(self.imagesLocationInfo.map { $0.assetIdentifier ?? "" })
        print("기존에 선택되었던 사진 식별자: \(existingIdentifiers)")
        // 선택 해제된 사진 식별자 찾기
        let deselectedIdentifiers = existingIdentifiers.subtracting(newIdentifiers)
        print("선택 해제된 사진 식별자 찾기: \(deselectedIdentifiers)")
        // 선택 해제된 사진 정보 제거
        self.imagesLocationInfo.removeAll { deselectedIdentifiers.contains($0.assetIdentifier ?? "") }
        print("선택 해제된 사진 정보 제거: \(self.imagesLocationInfo.removeAll { deselectedIdentifiers.contains($0.assetIdentifier ?? "") })")
        // 새롭게 추가된 이미지의 식별자 찾기
        let addedIdentifiers = newIdentifiers.subtracting(existingIdentifiers)
        print("새롭게 추가된 이미지의 식별자 찾기: \(addedIdentifiers)")
        
        // 새롭게 선택한 이미지를 추가하는 로직
        for imageInfo in imagesLocationInfo {
            if let identifier = imageInfo.assetIdentifier, addedIdentifiers.contains(identifier) {
                self.imagesLocationInfo.append(imageInfo)
            }
        }
        print("새롭게 선택한 이미지를 추가하는 로직: \(self.imagesLocationInfo)")
        self.selectedPhotoIdentifiers = retainedIdentifiers
        self.imagesCollectionView.reloadData()
        self.updateImageCollectionViewHeight()
        print("imagesLocationInfo after didPickImages: \(self.imagesLocationInfo)")
        print("selectedPhotoIdentifiers: \(self.selectedPhotoIdentifiers)")
    }
    func timeAndLocationChoiceAlert(time: String, address: String, completion: @escaping (Bool) -> Void) {
        let alert = UIAlertController(title: "첨부파일의 날짜와 위치를 사용하시겠습니까?", message: "\(time)\n\(address)" , preferredStyle: .actionSheet)
        
        let useMetadataAction = UIAlertAction(title: "예", style: .default) { [weak self] _ in
            guard let self = self else { return }
            // 사진의 메타데이터 시간을 사용
            if let metadataDate = DateFormatter.yyyyMMddHHmmss.date(from: time) {
                self.selectedDate = metadataDate
                let dateString = DateFormatter.yyyyMMddE.string(from: metadataDate)
                self.datePickingButton.setTitle(dateString, for: .normal)
            }
            self.useMetadataLocation = true
            self.refreshMapCell()
            completion(true)    // 사진의 메타데이터로 시간&위치 저장
        }
        
        let useCurrentAction = UIAlertAction(title: "아니오", style: .default) { _ in
            self.useMetadataLocation = false
            self.refreshMapCell()
            completion(false)   // 현재 위치로 시간&위치 저장
        }
        
        alert.addAction(useMetadataAction)
        alert.addAction(useCurrentAction)
        
        self.present(alert, animated: true)
    }
}

// MARK: CollectioinView DataSource, Delegate, FlowLayout
extension WriteDiaryVC: UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return imagesLocationInfo.count + 1
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        // 마지막 셀에는 MapCollectionViewCell을 반환
        if indexPath.item < imagesLocationInfo.count {
            // 이미지 셀 구성
            guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: ImageCollectionViewCell.reuseIdentifier, for: indexPath) as? ImageCollectionViewCell else {
                fatalError("Unalble to dequeue ImageCollectionView Cell")
            }
            let info = imagesLocationInfo[indexPath.item]
            cell.configure(with: info.image)
            return cell
        } else {
            // 맵 셀 구성
            guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: MapCollectionViewCell.reuseIdentifier, for: indexPath) as? MapCollectionViewCell else {
                fatalError("Unable to dequeue MapCollectionViewCell")
            }
            if self.useMetadataLocation {
                // 사진에 설정된 위치로 맵 셀 구성
                let locationInfos = imagesLocationInfo.compactMap { $0.locationInfo }
                cell.configureMapWith(locationsInfo: locationInfos)
                print("imagesLocationInfo: \(locationInfos)")
            } else if !self.useMetadataLocation {
                // 현재 위치로 맵 셀 구성
                cell.currentLocationInfo = self.currentLocationInfo
                cell.configureMapCellWithCurrentLocation()
                print("currentLocationInfo: \(String(describing: self.currentLocationInfo))")
            }
            cell.delegate = self
            return cell
        }
    }
    private func refreshMapCell() {
        DispatchQueue.main.async {
            // 맵을 표시하는 셀만 새로고침
            let indexPath = IndexPath(item: self.imagesLocationInfo.count, section: 0)
            self.imagesCollectionView.reloadItems(at: [indexPath])
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if indexPath.item < imagesLocationInfo.count {
            let zoomVC = ImageZoomCollectionViewController()
            zoomVC.images = imagesLocationInfo.map { $0.image } // 모든 이미지 전달
            zoomVC.initialIndex = indexPath.item    // 탭한 이미지의 인덱스 전달
            zoomVC.modalPresentationStyle = .fullScreen
            present(zoomVC, animated: true)
        }
    }
    func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        // UICollectionViewFlowLayout 인스턴스
        guard let flowLayout = imagesCollectionView.collectionViewLayout as? UICollectionViewFlowLayout else { return }
        
        // 페이지 계산을 위해 현재 오프셋을 기준으로 한다.
        let currentOffset = scrollView.contentOffset.x
        
        // 한 페이지의 너비를 계산한다.
        let pageWidth = flowLayout.itemSize.width + flowLayout.minimumLineSpacing
        var newPageIndex = round(currentOffset / pageWidth)
        
        // 스와이프 방향을 기반으로 페이지 인덱스 조정
        if velocity.x > 0 {
            newPageIndex += 1
        } else if velocity.x < 0 {
            newPageIndex -= 1
        }
        
        // 새 페이지 인덱스가 유효한 범위 내에 있는지 확인
        newPageIndex = max(0, newPageIndex)
        newPageIndex = min(newPageIndex, CGFloat(imagesLocationInfo.count))
        
        // 새 오프셋 계산
        let newOffsetX = newPageIndex * pageWidth
        
        // 스크롤 애니메이션 실행
        scrollView.setContentOffset(CGPoint(x: newOffsetX, y: 0), animated: true)
        
        // targetContentOffset을 조정하여 scrollView가 자동으로 스크롤되지 않도록 함
        targetContentOffset.pointee = CGPoint(x: currentOffset, y: 0)
    }
}


extension WriteDiaryVC: UITextViewDelegate {
    
    // Firestore 날짜저장 형식
    func formattedDateString(for date: Date) -> String {
        return DateFormatter.yyyyMMddHHmmss.string(from: date)
    }
}
extension WriteDiaryVC: MapCollectionViewCellDelegate {
    func mapViewCell(_ cell: MapCollectionViewCell, didTapAnnotationWithLatitude latitude: CLLocationDegrees, longitude: CLLocationDegrees) {
        // 알림 컨트롤러 생성
        let alert = UIAlertController(title: "주소", message: nil, preferredStyle: .actionSheet)
        
        // 애플 맵 액션
        let openInAppleMaps = UIAlertAction(title: "Apple Maps에서 열기", style: .default) { [weak self] _ in
            self?.mapManager.getPlaceName(latitude: latitude, longitude: longitude) { placeName in
                DispatchQueue.main.async {
                    // `getPlaceName` 메서드를 통해 얻은 `placeName`을 사용하여 Apple Maps 열기
                    self?.mapManager.openAppleMaps(latitude: latitude, longitude: longitude, placeName: placeName)
                }
            }
        }
        // 구글 앱 액션
        let openInGoogleMaps = UIAlertAction(title: "Google Maps에서 열기", style: .default) { [weak self] _ in
            self?.mapManager.openGoogleMapsForPlace(latitude: latitude, longitude: longitude)
        }
        // 취소 액션
        let cancelAction = UIAlertAction(title: "취소", style: .cancel)
        
        // 알림 컨트롤러 표시
        alert.addAction(openInAppleMaps)
        alert.addAction(openInGoogleMaps)
        alert.addAction(cancelAction)
        present(alert, animated: true)
    }
}


// MARK: configureUI - addSubViews, setLayout, setButton메서드
extension WriteDiaryVC {
    private func configureUI() {
        view.backgroundColor = .mainBackground
        addSubView()
        updateImageViews()
        setLayout()
        setupKeyboardManager()
        setupToolbar()
        setTapGesture()
    }
    
    private func addSubView() {
        self.view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        contentView.addSubViews([datePickingButton, completeButton, updateButton, allowEditButton, emotionImageView, weatherImageView, titleTextField, contentTextView, imagesCollectionView])
    }
    
    private func setLayout() {
        scrollView.snp.makeConstraints { make in
            make.edges.equalTo(view.safeAreaLayoutGuide)
            self.scrollViewBottomConstraint = make.bottom.equalTo(view.safeAreaLayoutGuide).constraint
        }
        
        contentView.snp.makeConstraints { make in
            make.edges.width.equalTo(scrollView)
            // contentView의 높이는 최소 scrollView의 높이와 같거아 더 크도록 설정
            make.height.greaterThanOrEqualTo(scrollView).priority(.low)
        }
        
        datePickingButton.snp.makeConstraints { make in
            make.top.equalTo(contentView.snp.top).offset(30)
            make.leading.equalTo(contentView.snp.leading).offset(16)
        }
        
        completeButton.snp.makeConstraints { make in
            make.centerY.equalTo(datePickingButton)
            make.trailing.equalTo(contentView.snp.trailing).offset(-16)
        }
        
        updateButton.snp.makeConstraints { make in
            make.top.equalTo(completeButton)
            make.trailing.equalTo(completeButton)
        }
        
        allowEditButton.snp.makeConstraints { make in
            make.top.equalTo(completeButton)
            make.trailing.equalTo(completeButton)
        }
        
        titleTextField.snp.makeConstraints { make in
            make.top.equalTo(datePickingButton.snp.bottom).offset(20)
            make.leading.equalTo(contentView.snp.leading).offset(20)
            make.trailing.equalTo(contentView.snp.trailing).offset(-20)
            make.height.equalTo(50)
        }
                
        emotionImageView.snp.makeConstraints { make in
            make.centerY.equalTo(datePickingButton)
            make.leading.equalTo(datePickingButton.snp.trailing).offset(5)
            make.height.equalTo(25)
            make.width.equalTo(25)
        }
        
        weatherImageView.snp.makeConstraints { make in
            make.centerY.equalTo(emotionImageView).offset(0)
            make.leading.equalTo(emotionImageView.snp.trailing).offset(5)
            make.height.equalTo(25)
            make.width.equalTo(25)
        }
        
        imagesCollectionView.snp.makeConstraints { make in
            make.top.equalTo(titleTextField.snp.bottom).offset(15)
            make.leading.equalToSuperview().offset(0)
            make.trailing.equalToSuperview().offset(0)
        }
        
        // contentTextView의 최소 높이 설정
        contentTextView.snp.makeConstraints { make in
            make.top.equalTo(imagesCollectionView.snp.bottom).offset(5)
            make.leading.trailing.equalTo(titleTextField)
            // 최소 높이 제약 조건 추가
            make.height.greaterThanOrEqualTo(self.view).multipliedBy(0.75).priority(.high)
            make.bottom.equalTo(contentView.snp.bottom)
        }
        setupImageCollectionViewHeightConstraint()
    }
    
    private func setupImageCollectionViewHeightConstraint() {
        imageCollectionViewHeightConstraint = imagesCollectionView.heightAnchor.constraint(equalToConstant: 0)   // 초기 높이를 0으로 설정
        imageCollectionViewHeightConstraint?.isActive = true
    }
    
    // collectionView 높이 조절 로직
    private func updateImageCollectionViewHeight() {
        // 이미지가 없을 경우 높이를 0으로 설정
        if imagesLocationInfo.isEmpty {
            imageCollectionViewHeightConstraint?.constant = 0
        } else {
            // 이미지가 있을 경우, 높이를 조정
            imageCollectionViewHeightConstraint?.constant = imagesCollectionView.frame.width
        }
        UIView.animate(withDuration: 0.3) {
            self.view.layoutIfNeeded()
        }
    }
    
    // NotificationCenter(키보드 높이 조절) & 키보드 return 기능
    private func setupKeyboardManager() {
        guard let scrollViewBottomConstraint = scrollViewBottomConstraint else { return }
        keyboardManager = KeyboardManager(scrollView: scrollView, bottomConstraint: scrollViewBottomConstraint, viewController: self)
        keyboardManager?.registerKeyboardNotifications()
    }
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == self.titleTextField {
            self.contentTextView.becomeFirstResponder()
        }
        return true
    }
    
    // Navigation Bar Item 초기 세팅
    func setupToolbar() {
        let toolbar = UIToolbar()
        toolbar.sizeToFit()
        toolbar.tintColor = .mainTheme
        
        // weatherDescriptionLabel, weatherTempLabel을 넣기 위한 커스텀 뷰
        let weatherInfoView = UIView(frame: CGRect(x: 0, y: 0, width: 200, height: 30))
        
        // addSubView 및 layout
        weatherInfoView.addSubview(weatherDescriptionLabel)
        weatherInfoView.addSubview(weatherTempLabel)
        weatherDescriptionLabel.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.leading.equalToSuperview().offset(5)
        }
        weatherTempLabel.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.leading.equalTo(weatherDescriptionLabel.snp.trailing).offset(5)
        }
        
        // 날씨 아이템 생성
        let weatherBarDescription = UIBarButtonItem(customView: weatherInfoView)
                
        // 툴바 아이템 생성
        let items = [photoBarButtonItem, emotionBarButtonItem, weatherBarButtonItem, weatherBarDescription, UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil), UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(dismissKeyboard))]
        // 툴바 할당
        toolbar.setItems(items, animated: false)
        titleTextField.inputAccessoryView = toolbar
        contentTextView.inputAccessoryView = toolbar
    }
    
    // 컬렉션 뷰 측면을 탭했을 때 다음으로 넘어가는 Gesture 세팅
    private func setTapGesture() {
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(collectionViewEdgeTapped(_:)))
        imagesCollectionView.addGestureRecognizer(tapGestureRecognizer)
    }
    
    // 버튼 이미지, 버튼 타이틀 설정 메서드
    private func setButton(imageNamed: String, titleText: String, textFont: String, fontSize: CGFloat, buttonSize: CGSize, for action: Selector, hidden: Bool) -> UIButton {
        let button = UIButton(type: .system)
        button.frame = CGRect(origin: .zero, size: buttonSize) // 버튼 크기 설정
        
        if !imageNamed.isEmpty {
            // 이미지가 있을 경우, 이미지 설정
            button.setImage(UIImage(named: imageNamed), for: .normal)
            button.imageView?.contentMode = .scaleAspectFit
        }
        
        // 버튼 타이틀 및 폰트 설정
        button.setTitle(titleText, for: .normal)
        button.titleLabel?.font = UIFont(name: textFont, size: fontSize)
        
        // 버튼 액션 추가
        button.addTarget(self, action: action, for: .touchUpInside)
        
        // 추가적인 속성 설정 (예: 타이틀 색상, 배경색, 이미지 틴트색상)
        button.setTitleColor(.mainTheme, for: .normal)
        button.backgroundColor = .clear
        button.tintColor = .mainTheme
        
        // isHidden 초기값
        button.isHidden = hidden
        
        return button
    }
    
    private func updateImageViews() {
        if !selectedEmotion.isEmpty {
            emotionImageView.image = UIImage(named: selectedEmotion)
        } else {
            emotionImageView.image = nil
        }
        
        if !selectedWeather.isEmpty {
            weatherImageView.image = UIImage(named: selectedWeather)
        } else {
            weatherImageView.image = nil
        }
    }
    // textView placeHolder 설정 메서드
    func textViewDidBeginEditing(_ textView: UITextView) {
        if contentTextView.text == textViewPlaceHolder {
            textView.text = nil
            textView.textColor = .black
        }
    }
    func textViewDidEndEditing(_ textView: UITextView) {
        if contentTextView.text.isEmpty {
            textView.text = textViewPlaceHolder
            textView.textColor = .lightGray
        }
    }
    
    func enterDiary(to status: UIstatus, with diary: DiaryEntry? = nil) {
        switch status {
        case .writeNewDiary:
            datePickingButton.isEnabled = true
            titleTextField.isEnabled = true
            contentTextView.isEditable = true
            completeButton.isHidden = false
            updateButton.isHidden = true
            allowEditButton.isHidden = true
            titleTextField.becomeFirstResponder()
        case .editDiary:
            guard let diary = diary else { return }
            datePickingButton.isEnabled = true
            titleTextField.isEnabled = true
            contentTextView.isEditable = true
            completeButton.isHidden = true
            updateButton.isHidden = false
            allowEditButton.isHidden = true
            titleTextField.becomeFirstResponder()
            showsDiary(with: diary)
        case .showDiary:
            guard let diary = diary else { return }
            datePickingButton.isEnabled = false
            titleTextField.isEnabled = false
            contentTextView.isEditable = false
            completeButton.isHidden = true
            updateButton.isHidden = true
            allowEditButton.isHidden = false
            showsDiary(with: diary)
        }
    }
}

// MARK: Setup Initial Data
extension WriteDiaryVC {
    private func setupInitialData() {
        loadWeatherData()
        getCurrentLocation()
    }
    
    // OpenWeather의 날씨 데이터를 받아오는 메서드
    private func loadWeatherData() {
        weatherService.getWeather { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let weatherResponce):
                    // 날씨 설명과 온도를 표시. 온도는 소수점 아래를 반올림하여 표시
                    let weatherDescription = weatherResponce.weather.first?.description ?? "날씨정보 없음"
                    let temperature = weatherResponce.main.temp
                    self?.weatherDescriptionLabel.text = "\(weatherDescription)"
                    self?.weatherTempLabel.text = "\(Int(round(temperature)))℃"
                case .failure(let error):
                    print("Load weather failed: \(error)")
                    self?.weatherDescriptionLabel.text = "일기를 불러오지 못했습니다."
                    self?.weatherTempLabel.text = "일기를 불러오지 못했습니다."
                }
            }
        }
    }
    
    // 사용자의 현재 위치를 지속적으로 업데이트하는 메서드
    private func getCurrentLocation() {
        mapManager.onLocationUpdate = { [weak self] latitude, longitude in
            guard let self = self else { return }
            self.currentLocationInfo = "\(latitude), \(longitude)"
            print("Updated Location: \(self.currentLocationInfo ?? "Unknown"))")
        }
        mapManager.locationManager.startUpdatingLocation()
    }
}

extension UIImage {
    func resizedImage(with size: CGSize) -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(size, false, 0.0)
        self.draw(in: CGRect(origin: .zero, size: size))
        let resizedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return resizedImage
    }
}

extension UIView{
    func addSubViews(_ views : [UIView]){
        _ = views.map{self.addSubview($0)}
    }
}
