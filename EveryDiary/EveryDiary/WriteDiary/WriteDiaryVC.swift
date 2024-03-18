//
//  WriteDiaryVC.swift
//  EveryDiary
//
//  Created by t2023-m0044 on 2/21/24.
//

import MapKit
import PhotosUI
import UIKit

import Firebase
import SnapKit

class WriteDiaryVC: UIViewController {
    
    weak var delegate: DiaryUpdateDelegate?
    
    private var diaryManager = DiaryManager()
    
    private var selectedEmotion = "happy"
    private var selectedWeather = "Vector"
    private var selectedDate = Date()
    private var selectedPhotoIdentifiers: [String] = []
    
    // 수정할 일기의 ID를 저장하는 변수
    var diaryID: String?
    // 중복저장을 방지하기 위한 변수(플래그)
    private var isSavingDiary = false
    
    // 기존 이미지 URL 저장할 변수
    private var existingImageUrl: String?
    
    private lazy var dateString: String = {
        // Date를 String으로 변환
        let dateString = DateFormatter.yyyyMMddE.string(from: selectedDate)
        return dateString
    }()
    
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
        hidden: false
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
    private lazy var photoButton = setButton(
        imageNamed: "image",
        titleText: "사진",
        textFont: "SFProDisplay-Regular",
        fontSize: 0,
        buttonSize: CGSize(width: 15, height: 15),
        for: #selector(phPhotoButtonTapped),
        hidden: false
    )
    private lazy var emotionButton = setButton(
        imageNamed: "happy",
        titleText: "감정",
        textFont: "SFProDisplay-Regular",
        fontSize: 0,
        buttonSize: CGSize(width: 15, height: 15),
        for: #selector(emotionButtonTapped),
        hidden: false
    )
    private lazy var weatherButton = setButton(
        imageNamed: "Vector",
        titleText: "날씨",
        textFont: "SFProDisplay-Regular",
        fontSize: 0,
        buttonSize: CGSize(width: 15, height: 15),
        for: #selector(weatherButtonTapped),
        hidden: false
    )
    
    private lazy var titleTextField : UITextField = {
        let textField = UITextField()
        textField.backgroundColor = .clear
        textField.placeholder = "제목을 입력하세요."
        textField.tintColor = .green
        textField.font = UIFont(name: "SFProDisplay-Bold", size: 26)
        textField.textColor = .black
        textField.delegate = self
        return textField
    }()
    
    private var newImage: UIImage?
    
    private lazy var imageView: UIImageView = {
        let view = UIImageView()
        view.layer.cornerRadius = 10
        view.backgroundColor = .red
        view.contentMode = .scaleAspectFill
        view.clipsToBounds = true
        return view
    }()
    
    private lazy var imagePicker: UIImagePickerController = {
        let picker = UIImagePickerController()
        picker.delegate = self
        picker.allowsEditing = true
        return picker
    }()
    
    private var imageViewHeightConstraint: NSLayoutConstraint?
    
    // 여러개의 이미지를 보여주기 위한 배열과 collectionView
    private var images: [UIImage] = []
    private lazy var imagesCollectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.itemSize = CGSize(width: self.view.bounds.width - 50, height: self.view.bounds.width - 50)
        layout.minimumLineSpacing = 50
        layout.sectionInset = UIEdgeInsets(top: 0, left: 25, bottom: 0, right: 25)
        layout.scrollDirection = .horizontal
        
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = .clear
        collectionView.showsHorizontalScrollIndicator = false
        
        collectionView.decelerationRate = .fast
        collectionView.isPagingEnabled = false
        
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.register(ImageCollectionViewCell.self, forCellWithReuseIdentifier: ImageCollectionViewCell.reuseIdentifier)
        collectionView.register(MapCollectionViewCell.self, forCellWithReuseIdentifier: MapCollectionViewCell.reuseIdentifier)
        return collectionView
    }()
    private var imageCollectionViewHeightConstraint: NSLayoutConstraint?
    
    let weatherService = WeatherService()
    
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
    
    private var imagesLocationInfo: [ImageLocationInfo] = []
    
    private let textViewPlaceHolder = "텍스트를 입력하세요."
    
    private lazy var contentTextView : UITextView = {
        let view = UITextView()
        view.backgroundColor = .clear
        view.font = UIFont(name: "SFProDisplay-Regular", size: 18)
        view.textColor = .lightGray
        view.isScrollEnabled = false
        view.text = textViewPlaceHolder
        view.delegate = self
        return view
    }()
    
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
        view.backgroundColor = .mainBackground
        addSubView()
        setLayout()
        registerKeyboardNotifications()
        imageViewFucntional()
        loadWeatherData()
        setupToolbar()
    }
    
    deinit {
        unregisterKeyboardNotifications()
    }
}

extension WriteDiaryVC {
    private func imageViewFucntional() {
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(imageTapped(_: )))
        imageView.addGestureRecognizer(tapGestureRecognizer)
        imageView.isUserInteractionEnabled = true
    }
    @objc func imageTapped(_ tapgGestureRecognizer: UITapGestureRecognizer) {
        guard let imageView = tapgGestureRecognizer.view as? UIImageView else { return }
        guard let imageToZoom = imageView.image else { return }
        showZoomedImage(imageToZoom)
    }
    private func showZoomedImage(_ image: UIImage) {
        let zoomVC = ImageZoomViewController(image: image)
        zoomVC.modalPresentationStyle = .fullScreen
        present(zoomVC, animated: true, completion: nil)
    }
}


extension WriteDiaryVC {
    // 완료버튼 호출 메서드
    @objc func completeButtonTapped() {
        guard !isSavingDiary else { return }    // 저장 중(=true)이면 실행되지 않음
        isSavingDiary = true
        
        let formattedDateString = DateFormatter.yyyyMMddHHmmss.string(from: selectedDate)
        
        // 이미지가 선택되었을 때 이미지 업로드 과정을 진행
        if let image = newImage {
            // FirebaseStorageManager를 사용해 이미지 업로드
            FirebaseStorageManager.uploadImage(image: [image], pathRoot: "diary_images") { [weak self] imageUrl in
                guard let imageUrl = imageUrl else {
                    self?.isSavingDiary = false // 저장 실패하면, 변수 초기화
                    print("Image upload failed")
                    return
                }
                print("Image uploaded successfully. URL: \(imageUrl.absoluteString)")
                
                // DiaryEntry 생성 및 업로드
                self?.createAndUploadDiaryEntry(
                    with: self?.titleTextField.text ?? "",
                    content: self?.contentTextView.text ?? "",
                    dateString: formattedDateString,
                    imageUrl: imageUrl.absoluteString
                )
            }
        } else {
            // 이미지가 없다면 바로 DiaryEntry 생성 및 업로드
            createAndUploadDiaryEntry(
                with: self.titleTextField.text ?? "",
                content: self.contentTextView.text ?? "",
                dateString: formattedDateString
            )
            print("No image selected, creating entry without an image.")
        }
    }
    
    func createAndUploadDiaryEntry(with title: String, content: String, dateString: String, imageUrl: String? = nil) {
        let newDiaryEntry = DiaryEntry(
            title: title,
            content: content,
            dateString: dateString,
            emotion: selectedEmotion,
            weather: selectedWeather,
            imageURL: imageUrl
        )
        
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
    
    @objc func updateButtonTapped() {
        guard let diaryID = self.diaryID else { return }
        
        let formattedDateString =  DateFormatter.yyyyMMddHHmmss.string(from: selectedDate)
        
        let fetchedDiary = DiaryEntry(
            id: diaryID,
            title: titleTextField.text ?? "",
            content: contentTextView.text,
            dateString: formattedDateString,
            emotion: selectedEmotion,
            weather: selectedWeather,
            imageURL: self.existingImageUrl
        )
        
        // 새 이미지가 있고 기존 이미지 URL과 다른 경우에만 업데이트 진행
        if let newImage = newImage {
            // 기존 이미지가 있다면 삭제
            if let existingImageUrl = self.existingImageUrl {
                FirebaseStorageManager.deleteImage(urlString: existingImageUrl) { error in
                    if let error = error {
                        print("Error deleting existing image: \(error)")
                    }
                }
            }
            
            // 새로운 이미지 업로드
            FirebaseStorageManager.uploadImage(image: newImage, pathRoot: "diary_images") { [weak self] imageUrl in
                guard let imageUrl = imageUrl else {
                    print("Image upload failed")
                    return
                }
                // 업로드가 성공하면 imageURL을 업데이트하여 Firestore에 저장
                var updatedDiaryEntry = fetchedDiary
                updatedDiaryEntry.imageURL = imageUrl.absoluteString
                
                // Firestore에 업데이트
                self?.updateDiaryInFirestore(diaryID: diaryID, diaryEntry: updatedDiaryEntry)
            }
        } else {
            // 이미지가 선택되지 않았다면 기존 imageURL 사용
            updateDiaryInFirestore(diaryID: diaryID, diaryEntry: fetchedDiary)
        }
    }
    @objc func allowEditButtonTapped() {
        self.updateButton.isHidden = false
        self.allowEditButton.isHidden = true
        
        self.datePickingButton.isEnabled = true
        self.titleTextField.isEnabled = true
        self.contentTextView.isEditable = true
        self.photoButton.isEnabled = true
        self.emotionButton.isEnabled = true
        self.weatherButton.isEnabled = true
    }
    
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
    
    func showsDiary(with diary: DiaryEntry) {
        // UI 내 일기 내용 반영
        self.diaryID = diary.id
        self.titleTextField.text = diary.title
        self.contentTextView.text = diary.content
        self.contentTextView.textColor = .black
        self.selectedEmotion = diary.emotion
        self.selectedWeather = diary.weather
        self.existingImageUrl = diary.imageURL
        
        self.datePickingButton.isEnabled = false
        self.titleTextField.isEnabled = false
        self.contentTextView.isEditable = false
        self.photoButton.isEnabled = false
        self.emotionButton.isEnabled = false
        self.weatherButton.isEnabled = false
        
        // 날짜 형식 업데이트
        if let date = DateFormatter.yyyyMMddHHmmss.date(from: diary.dateString) {
            self.selectedDate = date
            let dateString = DateFormatter.yyyyMMddE.string(from: date)
            self.datePickingButton.setTitle(dateString, for: .normal)
        }
        
        // 이모티콘과 날씨 업데이트
        self.emotionButton.setImage(UIImage(named: diary.emotion)?.withRenderingMode(.alwaysOriginal), for: .normal)
        self.weatherButton.setImage(UIImage(named: diary.weather)?.withRenderingMode(.alwaysOriginal), for: .normal)
        
        // 완료, 저장 버튼 숨김, 수정 버튼 등장
        self.completeButton.isHidden = true
        self.updateButton.isHidden = true
        self.allowEditButton.isHidden = false
        
        // 이미지 URL이 있을 경우, 이미지를 다운로드하여 imageView에 설정
        if let imageUrlString = diary.imageURL, let imageUrl = URL(string: imageUrlString) {
            // FirebaseStorageManager를 사용해 이미지 다운로드
            FirebaseStorageManager.downloadImage(urlString: imageUrlString) { [weak self] downloadedImage in
                DispatchQueue.main.async {
                    if let image = downloadedImage {
                        self?.imageView.image = image
                        self?.updateImageViewHeight(with: image)
                    }
                }
            }
        }
    }
    func formattedDateString(for date: Date) -> String {  // Firestore 날짜저장 형식
        return DateFormatter.yyyyMMddHHmmss.string(from: date)
    }
}

// MARK: ImagePickerController (이미지 선택)
extension WriteDiaryVC: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    @objc func photoButtonTapped() {
        self.imagePicker.sourceType = .photoLibrary
        self.present(self.imagePicker, animated: true) {
        }
    }
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        // cancel시 "imagePickerController를 닫는다"만 명시적으로 수행
        dismiss(animated: true, completion: nil)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        
        if let selectedImage = info[UIImagePickerController.InfoKey.editedImage] as? UIImage {
            // 선택한 이미지를 newImage 변수에 할당하고, 이미지 뷰의 높이를 업데이트
            newImage = selectedImage
            self.imageView.image = newImage
            updateImageViewHeight(with: newImage)
        } else if let selectedImage = info[UIImagePickerController.InfoKey.originalImage] as? UIImage {
            // 선택한 이미지를 newImage 변수에 할당하고, 이미지 뷰의 높이를 업데이트
            newImage = selectedImage
            self.imageView.image = newImage
            updateImageViewHeight(with: newImage)
        }
        // 이미지 선택기 컨트롤러 닫기
        dismiss(animated: true, completion: nil)
    }
    
    private func setupImageViewHeightConstraint() {
        imageViewHeightConstraint = imageView.heightAnchor.constraint(equalToConstant: 0)   // 초기 높이를 0으로 설정
        imageViewHeightConstraint?.isActive = true
    }
    private func updateImageViewHeight(with image: UIImage?) {
        // 이미지가 nil이면 높이를 0, 아니면 view의 너비와 동일하게 설정
        imageViewHeightConstraint?.constant = image == nil ? 0 : imageView.frame.width
    }
}

// MARK: Date Condition(감정, 날씨 선택)
extension WriteDiaryVC: DateConditionSelectDelegate {
    @objc func emotionButtonTapped() {
        // 감정 선택 로직
        presentControllerSelect(with: .emotion)
    }
    @objc func weatherButtonTapped() {
        // 날씨 선택 로직
        presentControllerSelect(with: .weather)
    }
    
    func presentControllerSelect(with conditionType: ConditionType) {
        print(#function)
        let conditionSelectVC = DateConditionSelectVC()
        conditionSelectVC.conditionType = conditionType
        conditionSelectVC.modalPresentationStyle = .popover
        conditionSelectVC.preferredContentSize = CGSize(width: 400, height: 50)
        conditionSelectVC.delegate = self
        
        if let popoverController = conditionSelectVC.popoverPresentationController {
            let sourceView = conditionType == .emotion ? emotionButton : weatherButton
            popoverController.sourceView = sourceView
            popoverController.sourceRect = sourceView.bounds
            popoverController.permittedArrowDirections = [.up]
            popoverController.delegate = self
            present(conditionSelectVC, animated: true, completion: nil)
        }
    }
    
    func didSelectCondition(_ condition: String, type: ConditionType) {
        // 선택한 condition과 같은 이름을 가진 Asset 이미지를 버튼에 적용
        switch type {
        case .emotion:
            selectedEmotion = condition
            emotionButton.setImage(UIImage(named: condition)?.withRenderingMode(.alwaysOriginal), for: .normal)
        case .weather:
            selectedWeather = condition
            weatherButton.setImage(UIImage(named: condition)?.withRenderingMode(.alwaysOriginal), for: .normal)
        }
    }
}

// MARK: Date Select Delegate(날짜 선택)
extension WriteDiaryVC: DateSelectDelegate, UIPopoverPresentationControllerDelegate {
    @objc func datePickingButtonTapped() {
        // 날짜 선택 로직
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
    
    // iPhone에서도 popover 스타일 강제하는 메서드
    func adaptivePresentationStyle(for controller: UIPresentationController) -> UIModalPresentationStyle {
        return .none // iPhone에서도 popover 스타일을 강제합니다.
    }
    
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
}

// MARK: addSubViews, setLayout, setButton메서드
extension WriteDiaryVC {
    private func addSubView() {
        self.view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        contentView.addSubview(datePickingButton)
        contentView.addSubview(completeButton)
        contentView.addSubview(updateButton)
        contentView.addSubview(allowEditButton)
        contentView.addSubview(photoButton)
        contentView.addSubview(emotionButton)
        contentView.addSubview(weatherButton)
        contentView.addSubview(titleTextField)
        contentView.addSubview(contentTextView)
        contentView.addSubview(imageView)
        contentView.addSubview(imagesCollectionView)
    }
    private func setLayout() {
        scrollView.snp.makeConstraints { make in
            make.edges.equalTo(view.safeAreaLayoutGuide)
            self.scrollViewBottomConstraint = make.bottom.equalTo(view.safeAreaLayoutGuide).constraint
        }
        
        contentView.snp.makeConstraints { make in
            make.top.bottom.equalTo(scrollView)
            make.leading.trailing.equalTo(scrollView)
            make.width.equalTo(scrollView)
            // contentView의 높이는 최소 scrollView의 높이와 같거아 더 크도록 설정
            make.height.greaterThanOrEqualTo(scrollView).priority(.low)
        }
        
        datePickingButton.snp.makeConstraints { make in
            make.top.equalTo(contentView.snp.top).offset(37)
            make.leading.equalTo(contentView.snp.leading).offset(16)
        }
        
        completeButton.snp.makeConstraints { make in
            make.top.equalTo(contentView.snp.top).offset(37)
            make.trailing.equalTo(contentView.snp.trailing).offset(-16)
        }
        
        updateButton.snp.makeConstraints { make in
            make.top.equalTo(contentView.snp.top).offset(37)
            make.trailing.equalTo(contentView.snp.trailing).offset(-16)
        }
        
        allowEditButton.snp.makeConstraints { make in
            make.top.equalTo(contentView.snp.top).offset(37)
            make.trailing.equalTo(contentView.snp.trailing).offset(-16)
        }
        
        titleTextField.snp.makeConstraints { make in
            make.top.equalTo(datePickingButton.snp.bottom).offset(20)
            make.leading.equalTo(contentView.snp.leading).offset(20)
            make.trailing.equalTo(contentView.snp.trailing).offset(-20)
            make.height.equalTo(50)
        }
        
        photoButton.snp.makeConstraints { make in
            make.top.equalTo(titleTextField.snp.bottom).offset(10)
            make.leading.equalTo(titleTextField.snp.leading).offset(10)
            make.height.equalTo(25)
            make.width.equalTo(25)
        }
        
        emotionButton.snp.makeConstraints { make in
            make.top.equalTo(photoButton.snp.top).offset(0)
            make.leading.equalTo(photoButton.snp.trailing).offset(5)
            make.height.equalTo(25)
            make.width.equalTo(25)
        }
        
        weatherButton.snp.makeConstraints { make in
            make.top.equalTo(photoButton.snp.top).offset(0)
            make.leading.equalTo(emotionButton.snp.trailing).offset(5)
            make.height.equalTo(25)
            make.width.equalTo(25)
        }
        
        imageView.snp.makeConstraints { make in
            make.top.equalTo(photoButton.snp.bottom).offset(15)
            make.leading.equalToSuperview().offset(15)
            make.trailing.equalToSuperview().offset(-15)
        }
        
        imagesCollectionView.snp.makeConstraints { make in
            make.top.equalTo(photoButton.snp.bottom).offset(15)
            make.leading.equalToSuperview().offset(0)
            make.trailing.equalToSuperview().offset(0)
        }
        
        // contentTextView의 최소 높이 설정
        contentTextView.snp.makeConstraints { make in
            make.top.equalTo(imagesCollectionView.snp.bottom).offset(10)
            make.leading.trailing.equalTo(titleTextField)
            // 최소 높이 제약 조건 추가
            make.height.greaterThanOrEqualTo(self.view).multipliedBy(0.75).priority(.high)
            make.bottom.equalTo(contentView.snp.bottom)
        }
        setupImageViewHeightConstraint()
        setupImageCollectionViewHeightConstraint()
    }
    
    // 버튼 이미지, 타이틀 설정 메서드
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
}

// MARK: NotificationCenter(키보드 높이 조절) & 키보드 return 기능
extension WriteDiaryVC: UITextFieldDelegate {
    private func registerKeyboardNotifications() {
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    private func unregisterKeyboardNotifications() {
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    @objc func keyboardWillShow(notification: NSNotification) {
        if let keyboardSize = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue {
            let keyboardHeight = keyboardSize.height
            UIView.animate(withDuration: 0.3) {
                self.scrollViewBottomConstraint?.update(inset: keyboardHeight - self.view.safeAreaInsets.bottom)
                self.view.layoutIfNeeded()
            }
        }
    }
    @objc func keyboardWillHide(notification: NSNotification) {
        UIView.animate(withDuration: 0.3) {
            self.scrollViewBottomConstraint?.update(inset: 0)
            self.view.layoutIfNeeded()
        }
    }
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == self.titleTextField {
            self.contentTextView.becomeFirstResponder()
        }
        return true
    }
}

// MARK: textView placeHolder 생성
extension WriteDiaryVC: UITextViewDelegate {
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
}

// MARK: PHPickerControllerDelegate
extension WriteDiaryVC: PHPickerViewControllerDelegate {
    // PHPickerController를 불러오는 메서드(사진 접근 권한 요청)
    @objc func phPhotoButtonTapped() {
        // 사진첩에 대해 읽고 쓰기가 가능하도록 권한 확인 및 요청
        PHPhotoLibrary.requestAuthorization(for: .readWrite) { status in
            switch status {
            case .notDetermined:    // 사용자가 아직 권한을 부여하지 않은 상태
                DispatchQueue.main.async {
                    // FIXME: UIAlert로 수정(취소 or 설정으로 보내기)
                    print("갤러리를 불러올 수 없습니다. 핸드폰 설정에서 사진 접근 허용을 모든 사진으로 변경해주세요.")
                }
            case .denied, .restricted:  // 접근권한이 거부되었거나 제한된 상타
                DispatchQueue.main.async {
                    // FIXME: UIAlert로 수정(취소 or 설정으로 보내기)
                    print("갤러리를 불러올 수 없습니다. 핸드폰 설정에서 사진 접근 허용을 모든 사진으로 변경해주세요.")
                }
            case .authorized, .limited: // 모두 허용, 일부 허용
                // 허용된 상태라면 PHPickerController 호출
                self.loadPHPickerViewController()
            @unknown default:   // 알 수 없는 상태
                print("PHPhotoLibrary::execute - \"Unkown case\"")
            }
        }
    }
    // 접근 권한 획득 시, picker 호출하는 메서드
    private func loadPHPickerViewController() {
        var configuration = PHPickerConfiguration(photoLibrary: .shared())
        configuration.selectionLimit = 3    // 사용자가 선택할 수 있는 이미지의 최대 개수
        configuration.selection = .ordered  // 선택 순서 지정
        configuration.filter = .images  // 이미지만 선택할 수 있도록 필터링
        
        // 이미 선택한 이미지가 있을 경우, 이를 picker에서 사전 선택된 상태로 설정
        configuration.preselectedAssetIdentifiers = selectedPhotoIdentifiers
        
        DispatchQueue.main.async {
            let picker = PHPickerViewController(configuration: configuration)
            picker.delegate = self
            self.present(picker, animated: true)
        }
    }
    
    // didFinishPicking 메서드(사진 선택 완료시 호출되는 메서드). 선택한 이미지를 처리.
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true)  // 선택완료 -> picker dimiss
        
        var newImagesLocationInfo: [ImageLocationInfo] = []
        
        // 새로운 결과에 가빈한 identifier 목록을 생성합니다.
        let newResultsIdentifiers = results.compactMap { $0.assetIdentifier}
        
        // 기존에 선택된 이미지 중에서 새로운 결과에 포함되지 않은 항목을 제외합니다.
        let retainedImages = imagesLocationInfo.filter { newResultsIdentifiers.contains($0.assetIdentifier ?? "") }
        
        // 선택한 사진의 identifier를 저장할 배열
        //        var newSelecedIdentifiers: [String] = []
        
        // 신규 선택된 사진 식별자를 기반으로 새로운 ImageLocationInfo 배열을 구성
        newImagesLocationInfo.append(contentsOf: retainedImages)
        
        let group = DispatchGroup() // 모든 비동기작업을 추적하기 위한 DispatchGroup
        
        for result in results {
            // 새로 선택된 이미지의 assetIdentifier 저장
            guard let assetIdentifier = result.assetIdentifier, !retainedImages.contains(where: { $0.assetIdentifier == assetIdentifier}) else { continue }
            let itemProvider = result.itemProvider
            
            // itemProver를 통해 선택한 이미지에 대한 처리 시작
            if itemProvider.canLoadObject(ofClass: UIImage.self) {  // itemProvider가 UIImage 객체를 로드할 수 있는지 확인
                group.enter()   // 그룹에 작업 추가
                itemProvider.loadObject(ofClass: UIImage.self) { [weak self] (image, error) in
                    guard let self = self, let image = image as? UIImage else {
                        group.leave()   // 이미지 로드에 실패한 경우 작업그룹에서 제거
                        return
                    }
                    
                    // UTType.image.identifier를 사용해 itemProvider가 이미지 파일을 가지고 있는지 확인
                    if itemProvider.hasItemConformingToTypeIdentifier(UTType.image.identifier) {
                        // 이미지 파일의 실제 데이터를 로드
                        itemProvider.loadFileRepresentation(forTypeIdentifier: UTType.image.identifier) { url, error in
                            defer { group.leave() }
                            var locationInfo: LocationInfo? = nil
                            if let url = url, error == nil {
                                locationInfo = self.extractMetadata(from: url)  // 메타 데이터에서 위치정보 추출
                            }
                            
                            DispatchQueue.main.async {
                            // ImageLocationInfo 객체 생성 및 임시 배열에 추가
                            let imageLocationInfo = ImageLocationInfo(image: image, locationInfo: locationInfo, assetIdentifier: assetIdentifier)
                                newImagesLocationInfo.append(imageLocationInfo)
                            }
                        }
                    } else {
                        // 메타데이터 없이 이미지만 처리
                        let imageLocationInfo = ImageLocationInfo(image: image, locationInfo: nil, assetIdentifier: assetIdentifier)
                        DispatchQueue.main.async {
                            newImagesLocationInfo.append(imageLocationInfo)
                        }
                        group.leave()
                    }
                }
            }
        }
        // 모든 선택된 사진에 대한 처리 수행 후 변수 및 UI 업데이트 실행
        group.notify(queue: .main) { [weak self] in
            guard let self = self else { return }
            // imagesLocationInfo 배열을 새로운 정보로 업데이트
            self.imagesLocationInfo = newImagesLocationInfo
            // 선택된 사진 identifier 배열 업데이트
            self.selectedPhotoIdentifiers = newResultsIdentifiers
            // UI 업데이트
            self.imagesCollectionView.reloadData()
            self.updateImageCollectionViewHeight()
            print("newImagesLocationInfo: \(newImagesLocationInfo)")
            print("newSelectedIdentifiers: \(newResultsIdentifiers)")
        }
    }
    
        
    // 이미지 파일의 URL로부터 위치 정보를 추출하는 메서드
    private func extractMetadata(from url: URL) -> LocationInfo? {
        guard let source = CGImageSourceCreateWithURL(url as CFURL, nil),
                   let metadata = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as Dictionary? else { return nil}
        
        if let gpsDict = metadata[kCGImagePropertyGPSDictionary] as? Dictionary<String, Any> {
            if let latitude = gpsDict[kCGImagePropertyGPSLatitude as String] as? Double,
               let longitude = gpsDict[kCGImagePropertyGPSLongitude as String] as? Double {
                // 위도와 경도를 사용해 LocationInfo 객체를 생성
                return LocationInfo(latitude: latitude, longitude: longitude)
            }
        }
        return nil  // 위치정보 없으면 nil
    }
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
}

extension WriteDiaryVC: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
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
            guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: MapCollectionViewCell.reuseIdentifier, for: indexPath) as? MapCollectionViewCell else {
                fatalError("Unable to dequeue MapCollectionViewCell")
            }
            let lastLocation = imagesLocationInfo.last?.locationInfo
            let latitude = lastLocation?.latitude ?? 37.7749
            let longitude = lastLocation?.longitude ?? -122.4194
            cell.configureMapWith(latitude: latitude, longitude: longitude)
            return cell
        }
    }
    //    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
    //        let height = collectionView.frame.height - 50
    //        let width = height
    //        return CGSize(width: width, height: height)
    //    }
    private func setupImageCollectionViewHeightConstraint() {
        imageCollectionViewHeightConstraint = imagesCollectionView.heightAnchor.constraint(equalToConstant: 0)   // 초기 높이를 0으로 설정
        imageCollectionViewHeightConstraint?.isActive = true
    }
}

extension WriteDiaryVC: UICollectionViewDelegate {
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

// MARK: 날씨 정보 로드(getWeather)
extension WriteDiaryVC {
    private func loadWeatherData() {
        weatherService.getWeather { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let weatherResponce):
                    // 날씨 설명과 온도를 표시. 온도는 소수점 아래를 반올림하여 표시
                    let weatherDescription = weatherResponce.weather.first?.description ?? "날씨정보 없음"
                    let temperature = weatherResponce.main.temp
                    self?.weatherDescriptionLabel.text = "\(weatherDescription)"
                    self?.weatherTempLabel.text = "\(String(format: "%.1f", temperature))℃"
                case .failure(let error):
                    print("Load weather failed: \(error)")
                    self?.weatherDescriptionLabel.text = "일기를 불러오지 못했습니다."
                    self?.weatherTempLabel.text = "일기를 불러오지 못했습니다."
                }
            }
        }
    }
}

// MARK: 키보드 위 버튼 세팅(UIToolBarItem)
extension WriteDiaryVC {
    func setupToolbar() {
        let toolbar = UIToolbar()
        toolbar.sizeToFit()
        toolbar.tintColor = .mainTheme
        
        // 툴바 아이템 생성
        let photoBarButton = UIBarButtonItem(image: UIImage(named: "image"), style: .plain, target: self, action: #selector(phPhotoButtonTapped))
        let emotionBarButton = UIBarButtonItem(image: UIImage(named: "happy"), style: .plain, target: self, action: #selector(emotionButtonTapped))
        let weatherBarButton = UIBarButtonItem(image: UIImage(named: "Vector"), style: .plain, target: self, action: #selector(weatherButtonTapped))
        let space = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let doneBarButton = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(dismissKeyboard))
        
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
        
        let weatherBarDescription = UIBarButtonItem(customView: weatherInfoView)
        
        toolbar.setItems([photoBarButton, emotionBarButton, weatherBarButton, weatherBarDescription, space, doneBarButton], animated: false)
        
        // Assign toolbar as inputAccessoryView for textfield and textview
        titleTextField.inputAccessoryView = toolbar
        contentTextView.inputAccessoryView = toolbar
    }
    @objc func dismissKeyboard() {
        view.endEditing(true)
    }
}
