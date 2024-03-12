//
//  JournalCollectionViewCell.swift
//  EveryDiary
//
//  Created by t2023-m0026 on 2/27/24.
//

import UIKit

import SnapKit

class JournalCollectionViewCell: UICollectionViewCell {
    static let reuseIdentifier = "JournalCollectionView"
    
    override var isSelected: Bool {
        didSet {
            if self.isSelected {
                self.contentView.backgroundColor = .subTheme
            } else {
                self.contentView.backgroundColor = .mainCell
            }
        }
    }
    
    private lazy var contentTitle: UILabel = {
        let label = UILabel()
        label.font = UIFont(name: "SFProDisplay-Bold", size: 20)
        return label
    }()
    private lazy var contentText: UILabel = {
        let label = UILabel()
        label.font = UIFont(name: "SFProDisplay-Regular", size: 16)
        return label
    }()
    
    private lazy var contentTextView: UITextView = {
        let view = UITextView()
        view.font = UIFont(name: "SFProDisplay-Regular", size: 16)
        view.isEditable = false
        view.backgroundColor = .clear
        view.isScrollEnabled = false
        view.isUserInteractionEnabled = false
        view.textContainerInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        view.contentInset = UIEdgeInsets(top: 0, left: -5, bottom: 0, right: 0)
        return view
    }()
    
    private lazy var weatherIcon = UIImageView()
    private lazy var emotionIcon = UIImageView()
    private lazy var dateOfWriting: UILabel = {
        let label = UILabel()
        label.font = UIFont(name: "SFProDisplay-Regular", size: 12)
        return label
    }()
    lazy var imageView: UIImageView = {
        let view = UIImageView()
        view.layer.cornerRadius = 10
        view.clipsToBounds = true
        return view
    }()
    
//    private lazy var deleteButton: UIButton = {
//        let button = UIButton(type: .system)
//        button.setImage(UIImage(systemName: "trash"), for: .normal)
//        button.tintColor = .red
//        button.isHidden = true
//        button.addTarget(self, action: #selector(deleteButtonTapped), for: .touchUpInside)
//        return button
//    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        addSubView()
        setLayout()
        contentView.backgroundColor = .mainCell
        contentView.layer.shadowOpacity = 0.1
        contentView.layer.shadowColor = UIColor(named: "mainTheme")?.cgColor
        contentView.layer.shadowRadius = 3
        contentView.layer.shadowOffset = CGSize(width: 0, height: 0)
        self.layer.cornerRadius = 20
        self.clipsToBounds = true
        
//        initializeSwipeGesture()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    func setJournalCollectionViewCell(title: String, content: String, weather: String, emotion: String, date: String, imageName: String? = nil) {
        contentTitle.text = title
        contentTextView.text = content
        weatherIcon.image = UIImage(named: weather)
        emotionIcon.image = UIImage(named: emotion)
        dateOfWriting.text = date
        if let imageName = imageName {
            imageView.image = UIImage(named: imageName)
        }
    }
}

// MARK: Cell Swipe(삭제 예정)
//extension JournalCollectionViewCell {
//    @objc private func deleteButtonTapped() {
//        
//    }
//    private func initializeSwipeGesture() {
//        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePanGesture(_:)))
//        self.contentView.addGestureRecognizer(panGesture)
//    }
//    @objc private func handlePanGesture(_ gesture: UIPanGestureRecognizer) {
//        switch gesture.state {
//        case .began, .changed:
//            handleSwipeChange(gesture)
//        case .ended:
//            handleSwipeEnd(gesture)
//        default:
//            break
//        }
//    }
//    private func handleSwipeChange(_ gesture: UIPanGestureRecognizer) {
//        let translation = gesture.translation(in: self)
//        // 사용자가 왼쪽으로 스와이프 했을 때, contentView를 이동
//        if translation.x < -50 {
//            UIView.animate(withDuration: 0.2, animations: {
//                self.contentView.transform = CGAffineTransform(translationX: -100, y: 0)
//                self.deleteButton.isHidden = false
//            })
//        } else {
//            resetContentViewPosition()
//        }
//    }
//    private func resetContentViewPosition() {
//        UIView.animate(withDuration: 0.2, animations: {
//            self.contentView.transform = .identity
//            self.deleteButton.isHidden = true
//        })
//    }
//    private func handleSwipeEnd(_ gesture: UIPanGestureRecognizer) {
//        // 스와이프가 끝났을 때, 애니메이션으로 원래대로 복귀
//        UIView.animate(withDuration: 0.3, animations: {
//            self.contentView.transform = .identity
//        })
//    }
//}

extension JournalCollectionViewCell {
    private func addSubView() {
        contentView.addSubview(contentTitle)
        contentView.addSubview(contentText)
        contentView.addSubview(weatherIcon)
        contentView.addSubview(emotionIcon)
        contentView.addSubview(dateOfWriting)
        contentView.addSubview(imageView)
        contentView.addSubview(contentTextView)
    }
    private func setLayout() {
        contentTitle.snp.makeConstraints { make in
            make.top.equalTo(contentView).offset(15)
            make.height.equalTo(24)
            make.leading.equalTo(contentView.snp.leading).offset(15)
            make.trailing.equalTo(imageView.snp.leading).offset(-5)
        }
        contentText.snp.makeConstraints { make in
            make.top.equalTo(contentTitle.snp.bottom).offset(4)
            make.bottom.equalTo(weatherIcon.snp.top).offset(-4)
            make.leading.equalTo(contentTitle.snp.leading).offset(0)
            make.trailing.equalTo(contentTitle.snp.trailing).offset(0)
        }
        contentTextView.snp.makeConstraints { make in
            make.top.equalTo(contentTitle.snp.bottom).offset(4)
            make.bottom.equalTo(weatherIcon.snp.top).offset(-4)
            make.leading.equalTo(contentTitle.snp.leading).offset(0)
            make.trailing.equalTo(contentTitle.snp.trailing).offset(0)
        }
        weatherIcon.snp.makeConstraints { make in
            make.bottom.equalTo(contentView.snp.bottom).offset(-17)
            make.leading.equalTo(emotionIcon.snp.trailing).offset(5)
            make.height.equalTo(15)
            make.width.equalTo(15)
        }
        emotionIcon.snp.makeConstraints { make in
            make.bottom.equalTo(weatherIcon.snp.bottom)
            make.leading.equalTo(dateOfWriting.snp.trailing).offset(5)
            make.height.equalTo(15)
            make.width.equalTo(15)
        }
        dateOfWriting.snp.makeConstraints { make in
            make.bottom.equalTo(weatherIcon.snp.bottom).offset(0)
            make.leading.equalTo(contentTitle.snp.leading).offset(0)
        }
        imageView.snp.makeConstraints { make in
            make.top.equalTo(contentView).offset(11)
            make.bottom.equalTo(contentView).offset(-11)
            make.trailing.equalTo(contentView).offset(-11)
            make.width.equalTo(imageView.snp.height)
        }
//        deleteButton.snp.makeConstraints { make in
//            make.trailing.equalTo(contentView.snp.trailing).offset(-10)
//            make.centerY.equalToSuperview()
//            make.width.height.equalTo(30)
//        }
    }
}
