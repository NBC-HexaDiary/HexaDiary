//
//  WriteDiaryVC.swift
//  EveryDiary
//
//  Created by t2023-m0044 on 2/21/24.
//

import UIKit

class WriteDiaryVC: UIViewController {
    private let emotion = ["Smiling face with smiling eyes", "Grinning face", "Neutral face", "Disappointed but relieved face", "Persevering face", "Loudly crying face", "Pouting face", "Sleeping face", "Face screaming in fear", "Face vomiting", "Face with medical mask"]
    private let weather = ["u_sun", "u_cloud-sun", "u_clouds", "fi_wind", "u_cloud-showers-heavy", "u_moon", "u_cloud-moon", "u_rainbow", "u_snowflake", "u_thunderstorm"]
    
    private let date = Date()
    private lazy var dateString: String = {
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "ko_KR")
        dateFormatter.dateFormat = "yyyy. MM. dd(E)" // 원하는 날짜 및 시간 형식 지정

        // Date를 String으로 변환
        let dateString = dateFormatter.string(from: date)
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
            imageNamed: "vector",
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
        return textField
    }()
    
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
        textView.text = """
Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.
"""
        return textView
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        addSubView()
        setLayout()
        
        view.backgroundColor = .background
    }
}

// MARK: Functions
extension WriteDiaryVC: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    @objc func datePickingButtonTapped() {
        // 날짜 선택 로직
        let vc = DateSelectVC()
        vc.modalPresentationStyle = .overCurrentContext
        self.present(vc, animated: false)
    }
    
    @objc func completeButtonTapped() {
        self.dismiss(animated: true)
    }
    
    @objc func photoButtonTapped() {
        self.imagePicker.sourceType = .photoLibrary
        self.present(self.imagePicker, animated: true) {
            // 사진 선택하기 전에 이미지 뷰의 높이를 0으로 설정
            self.updateImageViewHeight(with: nil)
        }
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        var newImage: UIImage? = nil
        
        if let selectedImage = info[UIImagePickerController.InfoKey.editedImage] {
            newImage = selectedImage as? UIImage
        } else if let selectedImage = info[UIImagePickerController.InfoKey.originalImage] as? UIImage {
            newImage = selectedImage
        }
        self.imageView.image = newImage
        updateImageViewHeight(with: newImage)
        dismiss(animated: true, completion: nil)
    }
    
    @objc func emotionButtonTapped() {
        // 감정 선택 로직
    }
    @objc func weatherButtonTapped() {
        // 감정 선택 로직
    }
    
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
        button.setTitleColor(.main, for: .normal)
        button.backgroundColor = .clear
        button.tintColor = .main
        
        return button
    }
    
}

// MARK: addSubViews, AutoLayout
extension WriteDiaryVC {
    private func addSubView() {
        self.view.addSubview(datePickingButton)
        self.view.addSubview(completeButton)
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
    private func setupImageViewHeightConstraint() {
        imageViewHeightConstraint = imageView.heightAnchor.constraint(equalToConstant: 0)   // 초기 높이를 0으로 설정
        imageViewHeightConstraint?.isActive = true
    }
    private func updateImageViewHeight(with image: UIImage?) {
        // 이미지가 nil이면 높이를 0, 아니면 view의 너비와 동일하게 설정
        imageViewHeightConstraint?.constant = image == nil ? 0 : view.frame.width
        
        view.backgroundColor = UIColor(named: "mainBackground")

//        // 변경사항을 애니메이션과 함께 적용
//        UIView.animate(withDuration: 0.3, delay: 0.3, options: .transitionCurlDown) { [weak self] in
//            self?.view.layoutIfNeeded()
//        }

    }
}
