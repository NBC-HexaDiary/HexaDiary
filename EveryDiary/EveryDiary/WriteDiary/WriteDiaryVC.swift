//
//  WriteDiaryVC.swift
//  EveryDiary
//
//  Created by t2023-m0044 on 2/21/24.
//

import UIKit

import Firebase

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
        for: #selector(datePickingButtonTapped)
    )
    private lazy var completeButton = setButton(
        imageNamed: "",
        titleText: "완료",
        textFont: "SFProDisplay-Bold",
        fontSize: 20, 
        buttonSize: CGSize(width: 15, height: 15),
        for: #selector(completeButtonTapped)
    )
    private lazy var updateButton = setButton(
        imageNamed: "",
        titleText: "수정",
        textFont: "SFProDisplay-Bold",
        fontSize: 20,
        buttonSize: CGSize(width: 15, height: 15),
        for: #selector(updateButtonTapped)
    )
    private lazy var photoButton = setButton(
        imageNamed: "image",
        titleText: "사진",
        textFont: "SFProDisplay-Regular",
        fontSize: 0,
        buttonSize: CGSize(width: 15, height: 15),
        for: #selector(photoButtonTapped)
    )
    private lazy var emotionButton = setButton(
        imageNamed: "happy",
        titleText: "감정",
        textFont: "SFProDisplay-Regular",
        fontSize: 0,
        buttonSize: CGSize(width: 15, height: 15),
        for: #selector(emotionButtonTapped)
    )
    private lazy var weatherButton = setButton(
            imageNamed: "Vector",
            titleText: "날씨",
            textFont: "SFProDisplay-Regular",
            fontSize: 0,
            buttonSize: CGSize(width: 15, height: 15),
            for: #selector(weatherButtonTapped)
        )
    
    private let titleTextField : UITextField = {
        let textField = UITextField()
        textField.backgroundColor = .clear
        textField.placeholder = "제목을 입력하세요."
        textField.tintColor = .green
        textField.font = UIFont(name: "SFProDisplay-Bold", size: 26)
        textField.textColor = .black
        return textField
    }()
    
    private var newImage: UIImage?
    
    private lazy var imageView: UIImageView = {
        let view = UIImageView()
        view.layer.cornerRadius = 10
        view.backgroundColor = .red
        return view
    }()
    
    private lazy var imagePicker: UIImagePickerController = {
        let picker = UIImagePickerController()
        picker.delegate = self
        return picker
    }()
    
    private var imageViewHeightConstraint: NSLayoutConstraint?
    
    private let contentTextView : UITextView = {
        let textView = UITextView()
        textView.backgroundColor = .clear
        textView.font = UIFont(name: "SFProDisplay-Regular", size: 18)
        textView.textColor = .black
//        textView.text = """
//Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.
//"""
        return textView
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        addSubView()
        setLayout()
        updateButton.isHidden = diaryID == nil
        view.backgroundColor = .mainBackground
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
    
    func activeEditMode(with diary: DiaryEntry) {
        // UI 내 일기 내용 반영
        self.diaryID = diary.id
        self.titleTextField.text = diary.title
        self.contentTextView.text = diary.content
        self.selectedEmotion = diary.emotion
        self.selectedWeather = diary.weather
        self.existingImageUrl = diary.imageURL
        
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
        
        // 완료 -> 수정 버튼 교체
        self.completeButton.isHidden = true
        self.updateButton.isHidden = false
        
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
            // 사진 선택하기 전에 이미지 뷰의 높이를 0으로 설정
            self.updateImageViewHeight(with: nil)
        }
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        
        if let selectedImage = info[UIImagePickerController.InfoKey.editedImage] {
            newImage = selectedImage as? UIImage
        } else if let selectedImage = info[UIImagePickerController.InfoKey.originalImage] as? UIImage {
            newImage = selectedImage
        }
        // 선택한 이미지를 newImage 변수에 할당하고, 이미지 뷰의 높이를 업데이트
        self.imageView.image = newImage
        updateImageViewHeight(with: newImage)
        
        // 이미지 선택기 컨트롤러 닫기
        dismiss(animated: true, completion: nil)
    }
    
    private func setupImageViewHeightConstraint() {
        imageViewHeightConstraint = imageView.heightAnchor.constraint(equalToConstant: 0)   // 초기 높이를 0으로 설정
        imageViewHeightConstraint?.isActive = true
    }
    private func updateImageViewHeight(with image: UIImage?) {
        // 이미지가 nil이면 높이를 0, 아니면 view의 너비와 동일하게 설정
        imageViewHeightConstraint?.constant = image == nil ? 0 : view.frame.width
        
        view.backgroundColor = .mainBackground

//        // 변경사항을 애니메이션과 함께 적용
//        UIView.animate(withDuration: 0.3, delay: 0.3, options: .transitionCurlDown) { [weak self] in
//            self?.view.layoutIfNeeded()
//        }

    }
}

// MARK: Date Condition(emotion, weather) Select (감정, 날씨 선택)
extension WriteDiaryVC: DateConditionSelectDelegate {
    @objc func emotionButtonTapped() {
        // 감정 선택 로직
        presentControllerSelect(with: .emotion)
        
    }
    @objc func weatherButtonTapped() {
        // 감정 선택 로직
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

// MARK: addSubViews, AutoLayout
extension WriteDiaryVC {
    private func addSubView() {
        self.view.addSubview(datePickingButton)
        self.view.addSubview(completeButton)
        self.view.addSubview(updateButton)
        self.view.addSubview(photoButton)
        self.view.addSubview(emotionButton)
        self.view.addSubview(weatherButton)
        self.view.addSubview(titleTextField)
        self.view.addSubview(contentTextView)
        self.view.addSubview(imageView)
    }
    private func setLayout() {
        datePickingButton.snp.makeConstraints { make in
            make.top.equalTo(self.view.safeAreaLayoutGuide.snp.top).offset(37)
            make.leading.equalTo(self.view.safeAreaLayoutGuide.snp.leading).offset(16)
        }
        
        completeButton.snp.makeConstraints { make in
            make.top.equalTo(self.view.safeAreaLayoutGuide.snp.top).offset(37)
            make.trailing.equalTo(self.view.safeAreaLayoutGuide.snp.trailing).offset(-16)
        }
        
        updateButton.snp.makeConstraints { make in
            make.top.equalTo(self.view.safeAreaLayoutGuide.snp.top).offset(37)
            make.trailing.equalTo(self.view.safeAreaLayoutGuide.snp.trailing).offset(-16)
        }
        
        titleTextField.snp.makeConstraints { make in
            make.top.equalTo(datePickingButton.snp.bottom).offset(20)
            make.leading.equalTo(self.view.snp.leading).offset(20)
            make.trailing.equalTo(self.view.snp.trailing).offset(-20)
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
        
        contentTextView.snp.makeConstraints { make in
            make.top.equalTo(imageView.snp.bottom).offset(10)
            make.leading.equalTo(titleTextField.snp.leading)
            make.trailing.equalTo(titleTextField.snp.trailing)
            make.bottom.equalTo(self.view.snp.bottom)
        }
        setupImageViewHeightConstraint()
    }
    
    // 버튼 이미지, 타이틀 설정 메서드
    private func setButton(imageNamed: String, titleText: String, textFont: String, fontSize: CGFloat, buttonSize: CGSize, for action: Selector) -> UIButton {
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
        
        return button
    }
}
