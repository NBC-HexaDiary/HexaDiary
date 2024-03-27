//
//  WriteDiaryVC.swift
//  EveryDiary
//
//  Created by t2023-m0044 on 2/21/24.
//
import CoreLocation
import UIKit

import Firebase
import FirebaseAuth
import SnapKit

protocol WriteDiaryDelegate: AnyObject {
    func diaryUploadDidStart()
    func diaryUploadDidFinish()
}

// WriteDiaryVC를 호출하는 목적에 따라 WriteDiaryVC의 UI컴포넌트 상태 구분
enum UIstatus {
    case writeNewDiary      // 새로운 일기 작성
    case editDiary          // 작성된 일기 수정
    case showDiary          // 작성된 일기 조회
}

class WriteDiaryVC: UIViewController, ImagePickerDelegate, UITextFieldDelegate {
    
    weak var delegate: DiaryUpdateDelegate?     // Delegate 프로토콜을 통한 데이터 업데이트 각 VC 통지
    weak var loadingDiaryDelegate: WriteDiaryDelegate?  // 데이터 전송, 종료를 알리는 delegate
    
    private var diaryManager = DiaryManager()
    private var imagePickerManager = ImagePickerManager()
    private var mapManager = MapManager()
    private var keyboardManager: KeyboardManager?
    let weatherService = WeatherService()
    
    private var selectedEmotion = ""
    private var selectedWeather = ""
    private var selectedDate = Date()
    private var selectedPhotoIdentifiers: [String] = []
    private var tempImagesLocationInfo: [ImageLocationInfo?] = []   // 이미지와 메타데이터를 임시로 저장하는 배열
    private var useMetadataLocation: Bool = false
    private var currentLocationInfo: String?
    
    private var diaryID: String?                                // 수정할 일기의 ID를 저장하는 변수
    private var currentUIStatus: UIstatus = .writeNewDiary      // 현재의 diary의 상태
    private var existingImageURLs: [String] = []                // 이미지 목록을 저장할 변수
    private var isSavingDiary = false                           // 중복저장을 방지하기 위한 변수(플래그)
    private lazy var dateString: String = {                     // 날짜선택 버튼에 사용되는 String
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
        for: #selector(completeButtonTapped1),
        hidden: true
    )
    private lazy var updateButton = setButton(
        imageNamed: "",
        titleText: "저장",
        textFont: "SFProDisplay-Bold",
        fontSize: 20,
        buttonSize: CGSize(width: 15, height: 15),
        for: #selector(updateButtonTapped1),
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
        label.text = ""
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
        print(#function)
        guard !isSavingDiary, validateInput() else { return }    // 저장 중(=true)이면 실행되지 않음
        isSavingDiary = true                    // 저장 시작
        //        uploadImagesAndSaveDiary()
        createAnonymousAccount { [weak self] in
            self?.uploadImagesAndSaveDiary()
        }
    }
    // 일기 저장 로직
    @objc func completeButtonTapped1() {
        print(#function)
        guard !isSavingDiary, validateInput() else { return }    // 저장 중(=true)이면 실행되지 않음
        isSavingDiary = true                    // 저장 시작
        self.loadingDiaryDelegate?.diaryUploadDidStart()
        
        // DiaryUploadManager를 사용하여 self를 유지
        DiaryUploadManager.shared.retain(self)
        
        // WriteDiaryVC dismiss 및 업로드 작업 시작
        self.dismiss(animated: true) { [weak self] in
            guard let self = self else { return }
            
            self.uploadImagesAndSaveDiary1 { success in
                // 이미지 업로드 및 일기 저장을 비동기적으로 시작
                DispatchQueue.main.async {
                    if success {
                        self.delegate?.diaryDidUpdate()
                        self.loadingDiaryDelegate?.diaryUploadDidFinish()
                    } else {
                        TemporaryAlert.presentTemporaryMessage(with: "업로드 실패", message: "일기를 업로드하지 못했습니다.", interval: 2.0, for: DiaryListVC())
                        self.isSavingDiary = false
                        self.loadingDiaryDelegate?.diaryUploadDidFinish()
                        DiaryUploadManager.shared.release(self)
                    }
                }
            }
        }
    }
    // 이미지 업로드 및 일기 저장
    private func uploadImagesAndSaveDiary() {
        let titleText = self.titleTextField.text
        let formattedDateString = DateFormatter.yyyyMMddHHmmss.string(from: selectedDate)
        let contentText = contentTextView.text == textViewPlaceHolder ? "" : contentTextView.text ?? ""
        let selectedEmotion = self.selectedEmotion
        let selectedWeather = self.selectedWeather
        let useMetadataLocation = self.useMetadataLocation
        let currentLocationInfo = self.currentLocationInfo
        
        self.uploadImages { uploadImageURLs in
            print("DiaryEntry Upload Start")
            self.createAndUploadDiaryEntry(with: titleText ?? "", content: contentText, dateString: formattedDateString, emotion: selectedEmotion, weather: selectedWeather, useMetadataLocation: useMetadataLocation, currentLocationInfo: currentLocationInfo ?? "", imageUrls: uploadImageURLs)
            print("DiaryEntry Upload Finish")
        }
    }
    
    // 이미지 업로드 및 일기 저장2
    private func uploadImagesAndSaveDiary1(completion: @escaping (Bool) -> Void) {
        let titleText = self.titleTextField.text
        let formattedDateString = DateFormatter.yyyyMMddHHmmss.string(from: selectedDate)
        let contentText = contentTextView.text == textViewPlaceHolder ? "" : contentTextView.text ?? ""
        let selectedEmotion = self.selectedEmotion
        let selectedWeather = self.selectedWeather
        let useMetadataLocation = self.useMetadataLocation
        let currentLocationInfo = self.currentLocationInfo
        
        self.uploadImages { uploadImageURLs in
            print("DiaryEntry Upload Start")
            self.createAndUploadDiaryEntry(with: titleText ?? "", content: contentText, dateString: formattedDateString, emotion: selectedEmotion, weather: selectedWeather, useMetadataLocation: useMetadataLocation, currentLocationInfo: currentLocationInfo ?? "", imageUrls: uploadImageURLs)
            print("DiaryEntry Upload Finish")
        }
    }
    
    // 익명 계정 생성
    private func createAnonymousAccount(completion: @escaping () -> Void) {
        DiaryManager.shared.authenticateAnonymouslyIfNeeded { error in
            if let error = error {
                print("Error creating anonymous account: \(error.localizedDescription)")
            } else {
                print("Anonymous account created successfully.")
                completion()
            }
        }
    }
    
    private func uploadImages(completion: @escaping ([String]) -> Void) {
        let dispatchGroup = DispatchGroup()
        var uploadedImageURLs = Array(repeating: String?.none, count: imagesLocationInfo.count) // URL 배열을 nil로 초기화
        
        // 이미지와 메타데이터 업로드
        print("before enter")
        for (index ,imageLocationInfo) in imagesLocationInfo.enumerated() {
            guard let assetIdentifier = imageLocationInfo.assetIdentifier else { continue }
            dispatchGroup.enter()
            print("dispatchGroup entered")
            // 촬영 시간과 위치 정보를 포함하여 업로드
            FirebaseStorageManager.uploadImage(
                image: [imageLocationInfo.image],
//                pathRoot: "diary_images",
                pathRoot: Auth.auth().currentUser?.uid ?? "UnknownUser",
                assetIdentifier: assetIdentifier,
                captureTime: imageLocationInfo.captureTime,
                location: imageLocationInfo.location
            ) { urls in
                defer { dispatchGroup.leave() }
                print("Image Uploaded")
                if let url = urls?.first?.absoluteString {
                    uploadedImageURLs[index] = url              // 원본 배열의 순서에 따라 URL 저장
                    return
                }
            }
        }
        dispatchGroup.notify(queue: .main) {
            print("dispatchGroup notify")
            let orderedUploadImageURLs = uploadedImageURLs.compactMap { $0 }     // nil 값을 제거하고 URL 순서대로 정렬
            print("completion 콜백 호출 전: \(orderedUploadImageURLs)")
            completion(Array(orderedUploadImageURLs))     // 순서대로 정렬된 URL 배열로 완료 콜백 호출
        }
    }
    
    // DiaryEntry 생성 및 Firestore 저장
    private func createAndUploadDiaryEntry(with title: String, content: String, dateString: String, emotion: String, weather: String, useMetadataLocation: Bool, currentLocationInfo: String, imageUrls: [String] = []) {
        print("Start Creating DiaryEntry")
        let newDiaryEntry = DiaryEntry(
            title: title,
            content: content,
            dateString: dateString,
            emotion: emotion,
            weather: weather,
            imageURL: imageUrls,
            useMetadataLocation: useMetadataLocation,
            currentLocationInfo: currentLocationInfo
            )
        
        // DiaryManager를 사용해 FireStore에 저장
        print("Adding DiaryEntry Start")
        diaryManager.addDiary(diary: newDiaryEntry) { [weak self] error in
            print("Adding DiaryEntry Finish")
            guard let self = self else { return }
            self.isSavingDiary = false  // 성공, 실패 여부를 떠나서 저장 시도가 완료되었으므로 변수 초기화
            if let error = error {
                // 에러처리
                print("Error saving diary to Firestore: \(error.localizedDescription)")
            } else {
                // 에러가 없다면, 화면 닫기
                print("Saved Diary Successfully.")
//                self.dismiss(animated: true, completion: nil)
                print("dismiss WriteDiaryVC")
                self.delegate?.diaryDidUpdate()
            }
            // 작업종료를 DiaryListVC에 전달
            self.loadingDiaryDelegate?.diaryUploadDidFinish()
        }
    }
    
    
    // 입력 값 검증
    private func validateInput() -> Bool {
        // title이 비어있는 경우, alert와 함께 제목 작성할 것을 요청
        guard let titleText = titleTextField.text, !titleText.isEmpty else {
            TemporaryAlert.presentTemporaryMessage(with: "빈 제목", message: "제목이 비어있습니다. 제목을 입력해주세요.", interval: 2.0, for: self)
            isSavingDiary = false   // 저장 시도 중지
            return false
        }
        return true
    }
    
    // 일기 업데이트 로직(업로드 완료 후 dismiss)
    @objc func updateButtonTapped() {
        guard !isSavingDiary, let diaryID = self.diaryID, validateInput() else { return }
        
        isSavingDiary = true    // 업로드 플래그
        
        // 1단계: 이미지 삭제
        deleteExistingImages { [weak self] in
            guard let self = self else { return }
            
            // 2단계: 이미지 업로드
            self.uploadImages { [weak self] uploadImageURLs in
                guard let self = self else { return }
                
                // 3단계: 일기 엔트리 업데이트
                let formattedDateString = DateFormatter.yyyyMMddHHmmss.string(from: self.selectedDate)
                let contentText = contentTextView.text == textViewPlaceHolder ? "" : contentTextView.text ?? ""
                let titleText = titleTextField.text ?? ""
                
                self.finalizeDiaryUpdate(diaryID: diaryID, title: titleText, content: contentText, dateString: formattedDateString, imageUrls: uploadImageURLs)
            }
        }
    }
    // 일기 업데이트 로직(업로드 완료 전 dismiss)
    @objc func updateButtonTapped1() {
        guard !isSavingDiary, let diaryID = self.diaryID, validateInput() else { return }
        // 업로드 플래그 및 업로드 시작 알림
        isSavingDiary = true
        self.loadingDiaryDelegate?.diaryUploadDidStart()
        
        DiaryUploadManager.shared.retain(self)
        
        self.dismiss(animated: true) { [weak self] in
            guard let self = self else { return }
            
            
            // 현재 입력된 일기 내용을 기반으로 DiaryEntry 객체 생성
            let updatedDiaryEntry = DiaryEntry(
                id: diaryID,
                title: titleTextField.text ?? "",
                content: contentTextView.text == self.textViewPlaceHolder ? "" : self.contentTextView.text ?? "",
                dateString: DateFormatter.yyyyMMddHHmmss.string(from: self.selectedDate),
                emotion: selectedEmotion,
                weather: selectedWeather,
                imageURL: existingImageURLs,
                useMetadataLocation: useMetadataLocation,
                currentLocationInfo: currentLocationInfo
            )
            
            DiaryUploadManager.shared.updateDiary(diaryID: diaryID, diaryEntry: updatedDiaryEntry, imagesLocationInfo: imagesLocationInfo, existingImageURLs: existingImageURLs) { success in
                DispatchQueue.main.async {
                    if success {
                        self.delegate?.diaryDidUpdate()
                    } else {
                        TemporaryAlert.presentTemporaryMessage(with: "업데이트 실패", message: "일기를 수정하지 못했습니다.\n일기를 다시 한 번 확인해주세요.", interval: 2.0, for: DiaryListVC())
                    }
                    self.isSavingDiary = false
                    self.loadingDiaryDelegate?.diaryUploadDidFinish()
                    DiaryUploadManager.shared.release(self)
                }
            }
        }
    }
    private func deleteExistingImages(completion: @escaping () -> Void) {
        let dispatchGroup = DispatchGroup()
        
        for urlString in self.existingImageURLs {
            dispatchGroup.enter()
            FirebaseStorageManager.deleteImage(urlString: urlString) { error in
                dispatchGroup.leave()
            }
        }
        dispatchGroup.notify(queue: .main) {
            completion()
        }
    }

    private func finalizeDiaryUpdate(diaryID: String, title: String, content: String, dateString: String, imageUrls: [String]) {
        let updatedDiaryEntry = DiaryEntry(
            id: diaryID,
            title: title,
            content: content,
            dateString: dateString,
            emotion: selectedEmotion,
            weather: selectedWeather,
            imageURL: imageUrls,
            useMetadataLocation: useMetadataLocation,
            currentLocationInfo: currentLocationInfo
        )
        // Firestore 문서 업데이트
        DiaryManager.shared.updateDiary(diaryID: diaryID, newDiary: updatedDiaryEntry) { [weak self] error in
            guard let self = self else { return }
            
            self.isSavingDiary = false
            if let error = error {
                print("Error updating diary: \(error.localizedDescription)")
            } else {
                print("Dairy updated successfully")
                self.dismiss(animated: true, completion: nil)
                self.delegate?.diaryDidUpdate()
            }
        }
    }
    // 일기 편집 가능 상태로 변경
    @objc func allowEditButtonTapped() {
        currentUIStatus = .editDiary
        datePickingButton.isEnabled = true
        titleTextField.isEnabled = true
        contentTextView.isEditable = true
        completeButton.isHidden = true
        updateButton.isHidden = false
        allowEditButton.isHidden = true
        titleTextField.becomeFirstResponder()
        imagesCollectionView.reloadData()
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
    
    // contentTextView 'Done' 클릭 시 호출.
    @objc func dismissKeyboard() {
        // 키보드를 내리고
        view.endEditing(true)
        
        // scrollView를 최상단으로 스크롤
        scrollView.setContentOffset(.zero, animated: true)
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
//    // DiaryEntry 생성 및 Firestore 저장
//    private func createAndUploadDiaryEntry(with title: String, content: String, dateString: String, emotion: String, weather: String, useMetadataLocation: Bool, currentLocationInfo: String, imageUrls: [String] = []) {
//        print("Start Creating DiaryEntry")
//        let newDiaryEntry = DiaryEntry(
//            title: title,
//            content: content,
//            dateString: dateString,
//            emotion: emotion,
//            weather: weather,
//            imageURL: imageUrls,
//            useMetadataLocation: useMetadataLocation,
//            currentLocationInfo: currentLocationInfo
//            )
//        
//        // DiaryManager를 사용해 FireStore에 저장
//        diaryManager.addDiary(diary: newDiaryEntry) { [weak self] error in
//            guard let self = self else { return }
//            self.isSavingDiary = false  // 성공, 실패 여부를 떠나서 저장 시도가 완료되었으므로 변수 초기화
//            if let error = error {
//                // 에러처리
//                print("Error saving diary to Firestore: \(error.localizedDescription)")
//            } else {
//                // 에러가 없다면, 화면 닫기
//                print("Saved Diary Successfully.")
////                self.dismiss(animated: true, completion: nil)
//                print("dismiss WriteDiaryVC")
//                self.delegate?.diaryDidUpdate()
//            }
//            // 작업종료를 DiaryListVC에 전달
//            self.loadingDiaryDelegate?.diaryUploadDidFinish()
//        }
//    }
    
    // DiaryEntry 수정 및 Firestore 업데이트
    private func updateDiaryInFirestore(diaryID: String, diaryEntry: DiaryEntry) {

    }
}

// MARK: 임시
extension WriteDiaryVC {
    func showsDiary(with diary: DiaryEntry) {
        updateUIWithDiaryEntry(diary)
        loadDisplayImages(with: diary)
        self.existingImageURLs = diary.imageURL ?? []
    }
    private func updateUIWithDiaryEntry(_ diary: DiaryEntry) {
        print("Loaded Diary: \(diary)")
        // UI 내 일기 내용 반영
        self.diaryID = diary.id
        self.titleTextField.text = diary.title
        self.contentTextView.text = diary.content
        self.selectedEmotion = diary.emotion
        self.selectedWeather = diary.weather
        self.useMetadataLocation = diary.useMetadataLocation
        self.currentLocationInfo = diary.currentLocationInfo
        updateDateAndEmotionWeatherImages(diary: diary)
    }
    
    private func updateDateAndEmotionWeatherImages(diary: DiaryEntry) {
        // 날짜 형식 업데이트
        if let date = DateFormatter.yyyyMMddHHmmss.date(from: diary.dateString) {
            self.selectedDate = date
            let dateString = DateFormatter.yyyyMMddE.string(from: date)
            self.datePickingButton.setTitle(dateString, for: .normal)
        }
        
        // 이모티콘과 날씨 업데이트
        emotionImageView.image = UIImage(named: diary.emotion)
        weatherImageView.image = UIImage(named: diary.weather)
    }
    private func loadDisplayImages(with diary: DiaryEntry) {
        // 기존 이미지 정보 초기화
        self.selectedPhotoIdentifiers.removeAll()
        self.imagesLocationInfo.removeAll()
        self.tempImagesLocationInfo = Array(repeating: nil, count: diary.imageURL?.count ?? 0)
        
        guard let imageURLs = diary.imageURL, !imageURLs.isEmpty else {
            self.imagesCollectionView.reloadData()
            return
        }
        
        imageURLs.enumerated().forEach { index, urlString in
            FirebaseStorageManager.downloadImage(urlString: urlString) { [weak self] downloadedImage, metadata in
                self?.handleDownloadedImage(downloadedImage, metadata: metadata, index: index, totalImages: imageURLs.count)
            }
        }
    }
    
    private func handleDownloadedImage(_ downloadedImage: UIImage?, metadata: [String: String]?, index: Int, totalImages: Int) {
        guard let image = downloadedImage else { return }
        let captureTime = metadata?["captureTime"] ?? "Unknown"
        let locationInfoString = metadata?["location"] ?? "Unknown"
        let assetIdentifier = metadata?["assetIdentifier"]
        let locationInfo = self.locationInfoFromString(locationInfoString)
        
        // 메타데이터를 포함한 ImageLocationInfo 객체 생성 및 배열에 할당
        if let assetIdentifier = assetIdentifier {
            self.imagePickerManager.selectedPhotoIdentifiers.append(assetIdentifier)
        }
        // 메타데이터를 포함한 ImageLocationInfo 객체 생성
        let imageLocationInfo = ImageLocationInfo(image: image, locationInfo: locationInfo, assetIdentifier: assetIdentifier, captureTime: captureTime, location: locationInfoString)
        self.tempImagesLocationInfo[index] = imageLocationInfo
        
        if tempImagesLocationInfo.compactMap({ $0 }).count == totalImages {
            DispatchQueue.main.async {
                // 다운로드된 이미지를 순서대로 배열에 저장
                self.imagesLocationInfo = self.tempImagesLocationInfo.compactMap { $0 }
                self.imagePickerManager.selectedPhotoIdentifiers = self.imagesLocationInfo.compactMap { $0.assetIdentifier }
                self.imagesCollectionView.reloadData()
                self.updateImageCollectionViewHeight()
            }
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
    
    // 선택한 condition과 같은 이름을 가진 Asset 이미지를 버튼에 적용
    func didSelectCondition(_ condition: String, type: ConditionType) {
        // 해당하는 condition(emotion, weather)의 이미지로 변경해주면서, 사용자가 인식할 수 있도록 변화가 있는 뷰로 scroll
        switch type {
        case .emotion:
            selectedEmotion = condition
            UIView.transition(
                with: emotionImageView,
                duration: 0.2,
                options: .transitionFlipFromTop,
                animations: { self.emotionImageView.image = UIImage(named: condition) }
            ) { _ in
                self.scroll(to: self.emotionImageView)
            }
        case .weather:
            selectedWeather = condition
            UIView.transition(
                with: weatherImageView,
                duration: 0.2,
                options: .transitionFlipFromTop,
                animations: { self.weatherImageView.image = UIImage(named: condition) }
            ) { _ in
                self.scroll(to: self.weatherImageView)
            }
        }
    }
    
    // 파라미터로 전달한 컴포넌트로 view를 scroll하는 메서드
    private func scroll(to view: UIView, animated: Bool = true, padding: CGFloat = 20) {
        
        // scrolleView가 현재보여주는 영역과 보여줄 대상 뷰의 위치가 같은 좌표계 상에서 비교될 수 있도록
        // scrollView가 현재 보여주고 있는 영역(scrollView.bounds)을 view의 superview 좌표계로 변환(convert)
        let scrollViewRect = scrollView.convert(scrollView.bounds, to: view.superview)
        
        // 주변에 여유공간을 추가하기 위해서 view.frame.inset에 padding을 부여
        let paddedFrame = view.frame.insetBy(dx: -padding, dy: -padding)
        
        // scrollViewRect가 보여주고자하는 view의 시작점을 포함하는지 확인.
        if !scrollViewRect.contains(paddedFrame.origin) {
            // 포함하고있지 않다면(안보인다면), 해당 뷰가 보이도록 스크롤을 수행(scrollRectToVisible)
            scrollView.scrollRectToVisible(paddedFrame, animated: true)
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
            // 현재 UIstatus에 따라 삭제 버튼의 표시 여부 결정
            let shouldHideDeleteButton = currentUIStatus == .showDiary
            cell.configureDeleteButton(hidden: shouldHideDeleteButton)
            
//            if !shouldHideDeleteButton {
//                cell.startJiggling()
//            } else {
//                cell.stopJiggling()
//            }
            
            let info = imagesLocationInfo[indexPath.item]
            cell.configure(with: info.image)
            // cell 내의 삭제버튼을 트리거로 하는 closer를 정의
            cell.onDeleteButtonTapped = { [weak self] in
                guard let self = self else { return }
                // 현재 셀의 assetIdentifier를 가져온다.
                guard let assetIdentifier = self.imagesLocationInfo[indexPath.item].assetIdentifier else { return }
                
                // assetIdentifier를 기반으로 imagesLocationInfo 배열에서 해당 이미지 정보를 삭제한다.
                if let assetIdentifier = self.imagesLocationInfo[indexPath.item].assetIdentifier {
                    // indexPath.item이 imagesLocation 배열의 범위 내에 있는지 확인 후, 범위 내라면 해당 항목을 배열에서 삭제
                    if indexPath.item < self.imagesLocationInfo.count {
                        self.imagesLocationInfo.remove(at: indexPath.item)
                    }
                    // 해당 assetIdentifier를, selectedPhotoIdentifier에서도 삭제
                    // firstIndex(of:)메서드로 assetIdentifier와 일치하는 첫번째 인덱스를 찾고, 해당 인덱스를 가진 항목을 selectedPhotoIdentifier에서 삭제
                    if let index = self.selectedPhotoIdentifiers.firstIndex(of: assetIdentifier) {
                        self.selectedPhotoIdentifiers.remove(at: index)
                        // ImagePickerManager로 변경된 selectedPhotoIdentifier 업데이트
                        imagePickerManager.updateSelectedPhotoIdentifier(selectedPhotoIdentifiers)
                    }
                }
                // collectionView 업데이트(performBatchUpdates는 여러 UI 변경사항을 그룹화하여 하나의 애니메이션으로 표현)
                self.imagesCollectionView.performBatchUpdates({
                    // deleteItems 메서드를 사용해 지정된 indexPath의 셀을 삭제
                    self.imagesCollectionView.deleteItems(at: [indexPath])
                }) { complted in
                    // UI 업데이트 완료 후, reloadData를 통해서 잠재적인 UI불일치를 방지.
                    self.imagesCollectionView.reloadData()
                }
            }
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
            make.leading.trailing.equalTo(contentView).offset(0)
            make.height.equalTo(0).priority(.high)  // 초기 상태 높이 0
        }
        
        // contentTextView의 최소 높이 설정
        contentTextView.snp.makeConstraints { make in
            make.top.equalTo(imagesCollectionView.snp.bottom).offset(5)
            make.leading.trailing.equalTo(titleTextField)
            // 최소 높이 제약 조건 추가
            make.bottom.equalTo(contentView.snp.bottom).offset(-20)
            make.height.greaterThanOrEqualTo(200).priority(.low)
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
    
    // WriteDiaryVC를 호출한 목적에 맞게 UI상태 업데이트
    func enterDiary(to status: UIstatus, with diary: DiaryEntry? = nil, reloadImages: Bool = true) {
        self.currentUIStatus = status
        switch status {
        case .writeNewDiary:
            print(currentUIStatus)
            datePickingButton.isEnabled = true
            titleTextField.isEnabled = true
            contentTextView.isEditable = true
            completeButton.isHidden = false
            updateButton.isHidden = true
            allowEditButton.isHidden = true
            titleTextField.becomeFirstResponder()
        case .editDiary:
            print(currentUIStatus)
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
            print(currentUIStatus)
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
                    self?.weatherDescriptionLabel.text = ""
                    self?.weatherTempLabel.text = ""
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
