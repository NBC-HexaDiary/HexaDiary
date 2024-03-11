//
//  WriteDiaryVC.swift
//  EveryDiary
//
//  Created by t2023-m0044 on 2/21/24.
//

import UIKit

import Firebase
import SnapKit

class WriteDiaryVC: UIViewController {
    
    
    private var diaryManager = DiaryManager()
    
    private var selectedEmotion = "happy"
    private var selectedWeather = "Vector"
    private var selectedDate = Date()
    
    // 수정할 일기의 ID를 저장하는 변수
    var diaryID: String?
    
    // 기존 이미지 URL 저장할 변수
    private var existingImageUrl: String?
    
    private lazy var dateString: String = {
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "ko_KR")
        dateFormatter.dateFormat = "yyyy. MM. dd(E)" // 원하는 날짜 및 시간 형식 지정
        
        // Date를 String으로 변환
        let dateString = dateFormatter.string(from: selectedDate)
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
        for: #selector(photoButtonTapped),
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
    }
    
    deinit {
        unregisterKeyboardNotifications()
    }
}


extension WriteDiaryVC {
    // 완료버튼 호출 메서드
    @objc func completeButtonTapped() {
        // 날짜 형식을 "yyyy-MM-dd HH:mm:ss Z"로 설정하여 dateString 생성
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss Z"
        dateFormatter.timeZone = TimeZone.current
        let formattedDateString = dateFormatter.string(from: selectedDate)
        
        // 이미지가 선택되었을 때 이미지 업로드 과정을 진행
        if let image = newImage {
            // FirebaseStorageManager를 사용해 이미지 업로드
            FirebaseStorageManager.uploadImage(image: image, pathRoot: "diary_images") { [weak self] imageUrl in
                guard let imageUrl = imageUrl else {
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
        diaryManager.addDiary(diary: newDiaryEntry) { error in
            if let error = error {
                // 에러처리
                print("Error saving diary to Firestore: \(error.localizedDescription)")
            } else {
                // 에러가 없다면, 화면 닫기
                self.dismiss(animated: true, completion: nil)
            }
        }
    }
    
    @objc func updateButtonTapped() {
        guard let diaryID = self.diaryID else { return }
        
        // 날짜 형식을 "yyyy-MM-dd HH:mm:ss Z"로 설정하여 dateString 생성
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss Z"
        dateFormatter.timeZone = TimeZone.current
        let formattedDateString = dateFormatter.string(from: selectedDate)
        
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
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "ko_KR")
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss Z"
        if let date = dateFormatter.date(from: diary.dateString) {
            self.selectedDate = date
            dateFormatter.dateFormat = "yyyy. MM. dd(E)"
            let dateString = dateFormatter.string(from: date)
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
    func formattedDateString(for date: Date) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss Z"  // Firestore 날짜저장 형식
        return dateFormatter.string(from: date)
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
        
        // 날짜 형식 설정
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "ko_KR")
        dateFormatter.dateFormat = "yyyy. MM. dd(E)"
        
        // 선택된 날짜로 문자열 변환
        let dateString = dateFormatter.string(from: date)
        
        datePickingButton.setTitle(dateString, for: .normal)
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
        
        // contentTextView의 최소 높이 설정
        contentTextView.snp.makeConstraints { make in
            make.top.equalTo(imageView.snp.bottom).offset(10)
            make.leading.trailing.equalTo(titleTextField)
            // 최소 높이 제약 조건 추가
            make.height.greaterThanOrEqualTo(self.view).multipliedBy(0.75).priority(.high)
            make.bottom.equalTo(contentView.snp.bottom)
        }
        setupImageViewHeightConstraint()
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
